import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'profile.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'folder_management.dart';
import 'folder_detail.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String phoneNumber = '-';
  List<Map<String, dynamic>> folders = [];
  bool isLoading = true;
  final String apiBaseUrl = 'http://localhost:3000';
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Colors
  final primaryColor = const Color(0xFF4F6BFF);
  final secondaryColor = const Color(0xFF30D6B0);
  final backgroundColor = Colors.white;
  
  @override
  void initState() {
    super.initState();
    
    // กำหนดค่า animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // สร้าง fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // สร้าง scale animation
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    // เริ่ม animation
    _animationController.forward();
    
    // กำหนดค่า phoneNumber ตามข้อมูลที่ได้รับ
    setState(() {
      if (widget.user['phone'] != null) {
        final phone = widget.user['phone'].toString().trim();
        phoneNumber = phone.isNotEmpty ? phone : '-';
      } else {
        phoneNumber = '-';
      }
    });
    
    // เรียกดึงข้อมูล folder
    fetchFolders();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับดึงข้อมูล folder จาก API
  Future<void> fetchFolders() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/folders/user/${widget.user['id']}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['folders'] != null && data['folders'] is List) {
            folders = List<Map<String, dynamic>>.from(data['folders']);
          } else {
            folders = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          folders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        folders = [];
        isLoading = false;
      });
    }
  }
  
  // แสดง Dialog ยืนยันการออกจากระบบ
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ยืนยันการออกจากระบบ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'คุณต้องการออกจากระบบใช่หรือไม่?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withBlue(255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                child: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Perform logout with animation
                  _performLogout();
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  // ฟังก์ชันสำหรับออกจากระบบพร้อม animation
  void _performLogout() {
    // Reverse animation before logout
    _animationController.reverse().then((_) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ตั้งค่า status bar ให้โปร่งใส
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Friend Connect',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        toolbarHeight: 70,
        actions: [
          // Profile button with circular avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                    ProfilePage(user: widget.user),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var begin = const Offset(0.0, 1.0);
                    var end = Offset.zero;
                    var curve = Curves.easeOutCubic;
                    
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ).then((_) {
                // Refresh data when returning from profile
                fetchFolders();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  widget.user['fname'][0].toUpperCase(),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Background decorations
              Positioned(
                top: -80,
                right: -40,
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -30,
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              // Main Content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Main Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          
                          // User Welcome Card with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 30),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.9),
                                    primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Decorative elements
                                  Positioned(
                                    right: -15,
                                    top: -15,
                                    child: Container(
                                      height: 90,
                                      width: 90,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    bottom: -20,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          height: 60,
                                          width: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              widget.user['fname'][0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        
                                        // Welcome text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ยินดีต้อนรับ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${widget.user['fname']} ${widget.user['lname']}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.alternate_email,
                                                    size: 14,
                                                    color: Colors.white70,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '@${widget.user['username']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // My Folders Section
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Title with updated manage button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.folder_rounded,
                                          color: primaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'โฟลเดอร์ของฉัน',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Improved Manage Folders Button
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => 
                                              FolderPage(user: widget.user),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              var begin = const Offset(1.0, 0.0);
                                              var end = Offset.zero;
                                              var curve = Curves.easeOutCubic;
                                              
                                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                              var offsetAnimation = animation.drive(tween);
                                              
                                              return SlideTransition(
                                                position: offsetAnimation,
                                                child: child,
                                              );
                                            },
                                            transitionDuration: const Duration(milliseconds: 500),
                                          ),
                                        ).then((_) {
                                          fetchFolders();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.settings,
                                        size: 18,
                                        color: primaryColor,
                                      ),
                                      label: Text(
                                        'จัดการ',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(color: primaryColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                
                                // Improved Folders grid with better design
                                isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : folders.isEmpty
                                    ? SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 120,
                                              width: 120,
                                              margin: const EdgeInsets.only(bottom: 16, top: 30),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.folder_off_outlined,
                                                size: 40,
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                            Text(
                                              'ยังไม่มีโฟลเดอร์',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'คลิกปุ่ม "จัดการ" เพื่อสร้างโฟลเดอร์ใหม่',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 20),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) => 
                                                      FolderPage(user: widget.user),
                                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                      return FadeTransition(opacity: animation, child: child);
                                                    },
                                                    transitionDuration: const Duration(milliseconds: 500),
                                                  ),
                                                ).then((_) {
                                                  fetchFolders();
                                                });
                                              },
                                              icon: const Icon(Icons.add_rounded, size: 20),
                                              label: const Text('สร้างโฟลเดอร์'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.0,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: folders.length,
                                        itemBuilder: (context, index) {
                                          final folder = folders[index];
                                          // Improved folder card design
                                          return AnimatedBuilder(
                                            animation: _animationController,
                                            builder: (context, child) {
                                              // Calculate delay based on index
                                              final delay = index * 0.2;
                                              final start = 0.3 + delay;
                                              final end = start + 0.4;
                                              
                                              // Create animation for each item
                                              final Animation<double> itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                                CurvedAnimation(
                                                  parent: _animationController,
                                                  curve: Interval(start < 1.0 ? start : 1.0, end < 1.0 ? end : 1.0, curve: Curves.easeOutCubic),
                                                ),
                                              );
                                              
                                              return Transform.translate(
                                                offset: Offset(0, 40 * (1 - itemAnimation.value)),
                                                child: Opacity(
                                                  opacity: itemAnimation.value,
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              elevation: 4,
                                              shadowColor: Colors.blue.withOpacity(0.2),
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(20),
                                                onTap: () {
                                                  // Navigate to folder detail
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                                        FolderDetailPage(user: widget.user, folder: folder),
                                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                        var begin = const Offset(0.0, 0.1);
                                                        var end = Offset.zero;
                                                        var curve = Curves.easeOutCubic;
                                                        
                                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                                        var offsetAnimation = animation.drive(tween);
                                                        
                                                        return SlideTransition(
                                                          position: offsetAnimation,
                                                          child: FadeTransition(
                                                            opacity: animation,
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                      transitionDuration: const Duration(milliseconds: 500),
                                                    ),
                                                  ).then((_) {
                                                    fetchFolders();
                                                  });
                                                },
                                                splashColor: primaryColor.withOpacity(0.1),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    // Folder icon
                                                    Container(
                                                      padding: const EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        color: primaryColor.withOpacity(0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.folder_rounded,
                                                        size: 44,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    // Folder name
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      child: Text(
                                                        folder['name'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    // Folder details (if available)
                                                    if (folder['detail'] != null && folder['detail'].toString().isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                        child: Text(
                                                          folder['detail'],
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                          
                          // Bottom space
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Floating Action Button for adding new folder
              Positioned(
                bottom: 20,
                right: 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => 
                                FolderPage(user: widget.user),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          ).then((_) {
                            fetchFolders();
                          });
                        },
                        borderRadius: BorderRadius.circular(30),
                        splashColor: Colors.white.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}