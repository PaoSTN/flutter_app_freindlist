import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String phoneNumber = '-';
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  
  // API Base URL - ปรับให้ตรงกับ URL ของเซิร์ฟเวอร์ของคุณ
  final String apiBaseUrl = 'http://localhost:3000'; // หรือ URL ของเซิร์ฟเวอร์จริง
  
  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.user['phone'] != null) {
        final phone = widget.user['phone'].toString().trim();
        phoneNumber = phone.isNotEmpty ? phone : '-';
      } else {
        phoneNumber = '-';
      }
      
      // Initialize the controllers with current user data
      usernameController.text = widget.user['username'] ?? '';
      fnameController.text = widget.user['fname'] ?? '';
      lnameController.text = widget.user['lname'] ?? '';
      phoneController.text = phoneNumber != '-' ? phoneNumber : '';
    });
  }
  
  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    usernameController.dispose();
    fnameController.dispose();
    lnameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.blue.shade50,
        toolbarHeight: 70,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.blue.shade700, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // ส่วนโปรไฟล์ด้านบน
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        widget.user['fname'][0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.user['fname']} ${widget.user['lname']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${widget.user['username']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'ยืนยันแล้ว',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // หัวข้อส่วนข้อมูลผู้ใช้
              const Text(
                'ข้อมูลผู้ใช้',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // รายการข้อมูลผู้ใช้แบบเรียบง่าย
              _buildUserInfoRow('ชื่อผู้ใช้', widget.user['username']),
              const Divider(height: 1, thickness: 0.5),
              _buildUserInfoRow('ชื่อจริง', widget.user['fname']),
              const Divider(height: 1, thickness: 0.5),
              _buildUserInfoRow('นามสกุล', widget.user['lname']),
              const Divider(height: 1, thickness: 0.5),
              _buildUserInfoRow('เบอร์โทรศัพท์', phoneNumber),
              
              const SizedBox(height: 32),
              
              // ปุ่มแก้ไขโปรไฟล์
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showEditProfileDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'แก้ไขโปรไฟล์',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show the edit profile dialog
  void _showEditProfileDialog() {
    // Reset error message
    errorMessage = '';
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'แก้ไขข้อมูลส่วนตัว',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField('ชื่อผู้ใช้', usernameController),
                    const SizedBox(height: 16),
                    _buildTextField('ชื่อจริง', fnameController),
                    const SizedBox(height: 16),
                    _buildTextField('นามสกุล', lnameController),
                    const SizedBox(height: 16),
                    _buildTextField('เบอร์โทรศัพท์', phoneController, keyboardType: TextInputType.phone),
                    
                    // แสดงข้อความผิดพลาด (ถ้ามี)
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading 
                      ? null 
                      : () => _updateProfile(dialogContext, setDialogState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // Function to build text fields
  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Function to update the profile
  Future<void> _updateProfile(BuildContext dialogContext, Function setDialogState) async {
    // Set loading state
    setState(() {
      isLoading = true;
    });
    
    setDialogState(() {
      errorMessage = '';
      isLoading = true;
    });

    try {
      // ส่งข้อมูลไปยัง API
      final response = await http.put(
        Uri.parse('$apiBaseUrl/users/${widget.user['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': usernameController.text,
          'fname': fnameController.text,
          'lname': lnameController.text,
          'phone': phoneController.text,
        }),
      );
      
      // ตรวจสอบสถานะการตอบกลับ
      if (response.statusCode == 200) {
        // อัปเดตสำเร็จ
        final responseData = json.decode(response.body);
        
        // อัปเดตข้อมูลในแอป
        setState(() {
          widget.user['username'] = usernameController.text;
          widget.user['fname'] = fnameController.text;
          widget.user['lname'] = lnameController.text;
          phoneNumber = phoneController.text;
          widget.user['phone'] = phoneController.text;
          isLoading = false;
        });
        
        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ปิดไดอะล็อก
        Navigator.of(dialogContext).pop();
      } else {
        // เกิดข้อผิดพลาด
        final errorData = json.decode(response.body);
        setDialogState(() {
          errorMessage = errorData['error'] ?? 'เกิดข้อผิดพลาดในการอัปเดตข้อมูล';
          isLoading = false;
        });
        
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // จัดการกับข้อผิดพลาดจากการเชื่อมต่อ
      setDialogState(() {
        errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาลองใหม่ภายหลัง';
        isLoading = false;
      });
      
      setState(() {
        isLoading = false;
      });
      
      print('Error updating profile: $e');
    }
  }
}