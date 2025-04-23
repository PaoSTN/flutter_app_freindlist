import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final fnameController = TextEditingController();
  final lnameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // ตรวจสอบว่ารหัสผ่านและยืนยันรหัสผ่านตรงกัน
      if (passwordController.text != confirmPasswordController.text) {
        setState(() {
          errorMessage = 'รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน';
        });
        return;
      }

      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      try {
        // ส่งคำขอไปยัง API
        final response = await http.post(
          Uri.parse('http://localhost:3000/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': usernameController.text,
            'fname': fnameController.text,
            'lname': lnameController.text,
            'phone': phoneController.text,
            'password': passwordController.text,
          }),
        );

        // ตรวจสอบการตอบกลับจาก API
        if (response.statusCode == 200) {
          // ลงทะเบียนสำเร็จ
          if (!mounted) return;
          
          // แสดงข้อความแจ้งเตือนและกลับไปหน้าล็อกอิน
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลงทะเบียนสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context); // กลับไปหน้าล็อกอิน
        } else {
          // ลงทะเบียนไม่สำเร็จ
          Map<String, dynamic> responseData = jsonDecode(response.body);
          setState(() {
            errorMessage = responseData['error'] ?? 'ลงทะเบียนไม่สำเร็จ';
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.indigo.shade50,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.person_add_outlined,
                    size: 48,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'สร้างบัญชีใหม่',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'กรุณากรอกข้อมูลเพื่อลงทะเบียน',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Personal Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลส่วนตัว',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // ชื่อผู้ใช้
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกชื่อผู้ใช้';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Row for First Name and Last Name
                      Row(
                        children: [
                          // ชื่อจริง
                          Expanded(
                            child: TextFormField(
                              controller: fnameController,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อจริง',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกชื่อจริง';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // นามสกุล
                          Expanded(
                            child: TextFormField(
                              controller: lnameController,
                              decoration: const InputDecoration(
                                labelText: 'นามสกุล',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกนามสกุล';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // เบอร์โทรศัพท์
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '0123456789',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,  // อนุญาตให้ป้อนได้เฉพาะตัวเลขเท่านั้น
                        ],
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                          return Text(
                            '$currentLength/$maxLength',
                            style: TextStyle(
                              color: currentLength == 10 ? Colors.green : Colors.grey.shade600,
                            ),
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกเบอร์โทรศัพท์';
                          }
                          if (value.length != 10) {
                            return 'เบอร์โทรศัพท์ต้องมี 10 หลักเท่านั้น';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Security Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ความปลอดภัย',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // รหัสผ่าน
                      // รหัสผ่าน
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          if (value.length < 6) {
                            return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // ยืนยันรหัสผ่าน
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'ยืนยันรหัสผ่าน',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณายืนยันรหัสผ่าน';
                          }
                          if (value != passwordController.text) {
                            return 'รหัสผ่านไม่ตรงกัน';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                
                // แสดงข้อความแจ้งเตือนความผิดพลาด
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // ปุ่มลงทะเบียน
                ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ลงทะเบียน',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // ลิงก์กลับไปหน้าล็อกอิน
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'มีบัญชีอยู่แล้ว?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('เข้าสู่ระบบที่นี่'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    fnameController.dispose();
    lnameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}