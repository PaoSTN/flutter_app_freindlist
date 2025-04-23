import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  // ตั้งค่าพื้นฐานให้กับแอป
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SC-PeopleHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6BFF),
          primary: const Color(0xFF4F6BFF),
          secondary: const Color(0xFF30D6B0),
          background: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFF4F6BFF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F6BFF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4F6BFF),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  bool _obscurePassword = true;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
    
    // สร้าง slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    // สร้าง scale animation
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // เริ่ม animation เมื่อสร้าง page
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Function สำหรับจัดการ login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      try {
        // แสดง loading indicator ด้วย animation
        await Future.delayed(const Duration(milliseconds: 300)); // เพิ่ม delay เล็กน้อยเพื่อให้เห็น animation

        final response = await http.post(
          Uri.parse('http://localhost:3000/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': usernameController.text,
            'password': passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          // ล็อกอินสำเร็จ
          if (!mounted) return;
          
          // แปลงข้อมูลจาก JSON
          final responseData = jsonDecode(response.body);
          final user = responseData['user'];
          
          // แสดง animation การ transition ไปหน้าหลัก
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => HomePage(user: user),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          // ล็อกอินไม่สำเร็จ
          Map<String, dynamic> responseData = jsonDecode(response.body);
          setState(() {
            errorMessage = responseData['error'] ?? 'ล็อกอินไม่สำเร็จ กรุณาลองอีกครั้ง';
          });
          
          // Animation สำหรับแสดง error message
          _animationController.reset();
          _animationController.forward();
        }
      } catch (e) {
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        });
        
        // Animation สำหรับแสดง error message
        _animationController.reset();
        _animationController.forward();
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // พื้นหลังพร้อม decoration
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
              ),
            ),
            // Bubble decoration ด้านบน
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F6BFF).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Bubble decoration ด้านล่าง
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F6BFF).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Bubble decoration ด้านขวา
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              right: -40,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF30D6B0).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Bubble decoration ด้านซ้าย
            Positioned(
              top: MediaQuery.of(context).size.height * 0.5,
              left: -25,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF30D6B0).withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App logo/icon
                        Center(
                          child: Container(
                            height: 110,
                            width: 110,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Hero(
                              tag: 'app_logo',
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4F6BFF),
                                      const Color(0xFF30D6B0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F6BFF).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.white,
                                  size: 45,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Header text
                        const Text(
                          'SC-PeopleHub',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F6BFF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ยินดีต้อนรับ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                       
                        const SizedBox(height: 40),
                        
                        // ช่อง Username
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อผู้ใช้',
                              hintText: 'กรอกชื่อผู้ใช้ของคุณ',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: const Color(0xFF4F6BFF).withOpacity(0.7),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontSize: 16),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อผู้ใช้';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // ช่อง Password
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน',
                              hintText: 'กรอกรหัสผ่านของคุณ',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: const Color(0xFF4F6BFF).withOpacity(0.7),
                              ),
                              suffixIcon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: IconButton(
                                  key: ValueKey<bool>(_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            style: const TextStyle(fontSize: 16),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        // "ลืมรหัสผ่าน" link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // ฟังก์ชันลืมรหัสผ่าน
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ฟีเจอร์นี้จะเปิดให้ใช้งานเร็ว ๆ นี้'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF4F6BFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                        // Error message (ถ้ามี)
                        if (errorMessage.isNotEmpty)
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  margin: const EdgeInsets.only(bottom: 20, top: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.red.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade100.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // ปุ่ม Login
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.95, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4F6BFF).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4F6BFF),
                                      const Color(0xFF4F6BFF).withBlue(255),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'เข้าสู่ระบบ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // สมัครสมาชิกใหม่
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ยังไม่มีบัญชี?',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // นำทางไปหน้าลงทะเบียนพร้อม animation
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const SignupPage(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      var begin = const Offset(1.0, 0.0);
                                      var end = Offset.zero;
                                      var curve = Curves.easeInOutCubic;
                                      
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      var offsetAnimation = animation.drive(tween);
                                      
                                      return SlideTransition(
                                        position: offsetAnimation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 500),
                                  ),
                                );
                              },
                              child: Text(
                                'ลงทะเบียนที่นี่',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4F6BFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}