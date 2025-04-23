import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // เพิ่ม import นี้สำหรับ FilteringTextInputFormatter

class FolderDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> folder;
  
  const FolderDetailPage({super.key, required this.user, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;
  String errorMessage = '';
  final String apiBaseUrl = 'http://localhost:3000';
  
  // Controllers สำหรับฟอร์มเพิ่มและแก้ไขสมาชิก
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // สถานะการตรวจสอบข้อมูล
  bool _isPhoneValid = true;
  bool _isEmailValid = true;
  String _phoneErrorText = '';
  String _emailErrorText = '';
  
  @override
  void initState() {
    super.initState();
    fetchFriends();
  }
  
  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _photoUrlController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  // ฟังก์ชันตรวจสอบเบอร์โทรศัพท์
  bool validatePhone(String phone, {int? excludeId}) {
    // ถ้าว่างเปล่า ถือว่าผ่าน
    if (phone.isEmpty) {
      setState(() {
        _isPhoneValid = true;
        _phoneErrorText = '';
      });
      return true;
    }
    
    // ตรวจสอบรูปแบบเบอร์โทร (10 หลัก, ตัวเลขเท่านั้น)
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      setState(() {
        _isPhoneValid = false;
        _phoneErrorText = 'เบอร์โทรต้องเป็นตัวเลข 10 หลักเท่านั้น';
      });
      return false;
    }
    
    // ตรวจสอบเบอร์โทรซ้ำ (ต้องเพิ่ม API endpoint ใหม่สำหรับตรวจสอบ)
    // ในที่นี้สมมติว่ามีฟังก์ชันเช็คในข้อมูล friends ที่ดึงมาแล้ว
    if (excludeId == null) {
      // กรณีเพิ่มใหม่ เช็คทั้งหมด
      bool isDuplicate = friends.any((friend) => 
        friend['phone'] != null && friend['phone'] == phone
      );
      
      if (isDuplicate) {
        setState(() {
          _isPhoneValid = false;
          _phoneErrorText = 'เบอร์โทรนี้มีในระบบแล้ว';
        });
        return false;
      }
    } else {
      // กรณีแก้ไข เช็คเฉพาะที่ไม่ใช่ ID เดิม
      bool isDuplicate = friends.any((friend) => 
        friend['phone'] != null && friend['phone'] == phone && friend['id'] != excludeId
      );
      
      if (isDuplicate) {
        setState(() {
          _isPhoneValid = false;
          _phoneErrorText = 'เบอร์โทรนี้มีในระบบแล้ว';
        });
        return false;
      }
    }
    
    setState(() {
      _isPhoneValid = true;
      _phoneErrorText = '';
    });
    return true;
  }
  
  // ฟังก์ชันตรวจสอบอีเมล
  bool validateEmail(String email, {int? excludeId}) {
    // ถ้าว่างเปล่า ถือว่าผ่าน
    if (email.isEmpty) {
      setState(() {
        _isEmailValid = true;
        _emailErrorText = '';
      });
      return true;
    }
    
    // ตรวจสอบรูปแบบอีเมล
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _isEmailValid = false;
        _emailErrorText = 'รูปแบบอีเมลไม่ถูกต้อง';
      });
      return false;
    }
    
    // ตรวจสอบอีเมลซ้ำ
    if (excludeId == null) {
      // กรณีเพิ่มใหม่ เช็คทั้งหมด
      bool isDuplicate = friends.any((friend) => 
        friend['email'] != null && friend['email'] == email
      );
      
      if (isDuplicate) {
        setState(() {
          _isEmailValid = false;
          _emailErrorText = 'อีเมลนี้มีในระบบแล้ว';
        });
        return false;
      }
    } else {
      // กรณีแก้ไข เช็คเฉพาะที่ไม่ใช่ ID เดิม
      bool isDuplicate = friends.any((friend) => 
        friend['email'] != null && friend['email'] == email && friend['id'] != excludeId
      );
      
      if (isDuplicate) {
        setState(() {
          _isEmailValid = false;
          _emailErrorText = 'อีเมลนี้มีในระบบแล้ว';
        });
        return false;
      }
    }
    
    setState(() {
      _isEmailValid = true;
      _emailErrorText = '';
    });
    return true;
  }
  
  // ฟังก์ชันตรวจสอบข้อมูลที่ต้องกรอกอย่างน้อยหนึ่งอย่าง (ชื่อหรือชื่อเล่น)
  bool validateRequiredFields() {
    return _fnameController.text.trim().isNotEmpty || _nicknameController.text.trim().isNotEmpty;
  }
  
  // ฟังก์ชันสำหรับดึงข้อมูลสมาชิกในโฟลเดอร์
  Future<void> fetchFriends() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/friends/folder/${widget.folder['id']}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['friends'] != null && data['friends'] is List) {
            friends = List<Map<String, dynamic>>.from(data['friends']);
          } else {
            friends = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'ไม่สามารถดึงข้อมูลสมาชิกได้';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        isLoading = false;
      });
    }
  }
  
  // ฟังก์ชันสำหรับเพิ่มสมาชิกใหม่ (แก้ไขแล้ว)
  Future<void> addFriend() async {
    // ตรวจสอบว่ามีการกรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง
    if (!validateRequiredFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // ตรวจสอบเบอร์โทรศัพท์ (ถ้ามีการกรอก)
    if (_phoneController.text.isNotEmpty && !validatePhone(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_phoneErrorText), backgroundColor: Colors.red),
      );
      return;
    }
    
    // ตรวจสอบอีเมล (ถ้ามีการกรอก)
    if (_emailController.text.isNotEmpty && !validateEmail(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_emailErrorText), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      print('กำลังส่งข้อมูลไปยัง API...');
      print('URL: $apiBaseUrl/friends');
      
      // สร้าง Map ข้อมูลที่ต้องการส่ง
      final Map<String, dynamic> requestData = {
        'user_id': widget.user['id'],
        'folder_id': widget.folder['id'],
        'fname': _fnameController.text.trim().isEmpty ? null : _fnameController.text.trim(),
        'lname': _lnameController.text.trim().isEmpty ? null : _lnameController.text.trim(),
        'nickname': _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'photo_url': _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      };
      
      print('ข้อมูลที่จะส่ง: ${jsonEncode(requestData)}');
      
      final response = await http.post(
        Uri.parse('$apiBaseUrl/friends'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        // รีเซ็ตฟอร์ม
        _resetForm();
        
        // ดึงข้อมูลสมาชิกใหม่
        await fetchFriends();
        
        // แสดงข้อความแจ้งเตือน
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มสมาชิกสำเร็จ'), backgroundColor: Colors.green),
        );
      } else {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            errorMessage = errorData['error'] ?? 'ไม่สามารถเพิ่มสมาชิกได้ (สถานะโค้ด: ${response.statusCode})';
            isLoading = false;
          });
          
          // แสดง error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        } catch (jsonError) {
          setState(() {
            errorMessage = 'ไม่สามารถแปลงข้อมูลตอบกลับ: ${response.body}';
            isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      
      if (!mounted) return;
      
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        isLoading = false;
      });
      
      // แสดง error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  // ฟังก์ชันสำหรับแก้ไขสมาชิก (แก้ไขแล้ว)
  Future<void> editFriend(int friendId) async {
    // ตรวจสอบว่ามีการกรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง
    if (!validateRequiredFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // ตรวจสอบเบอร์โทรศัพท์ (ถ้ามีการกรอก)
    if (_phoneController.text.isNotEmpty && !validatePhone(_phoneController.text, excludeId: friendId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_phoneErrorText), backgroundColor: Colors.red),
      );
      return;
    }
    
    // ตรวจสอบอีเมล (ถ้ามีการกรอก)
    if (_emailController.text.isNotEmpty && !validateEmail(_emailController.text, excludeId: friendId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_emailErrorText), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final Map<String, dynamic> requestData = {
        'fname': _fnameController.text.trim().isEmpty ? null : _fnameController.text.trim(),
        'lname': _lnameController.text.trim().isEmpty ? null : _lnameController.text.trim(),
        'nickname': _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'photo_url': _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
        'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      };
      
      print('URL: $apiBaseUrl/friends/$friendId');
      print('ข้อมูลที่จะส่ง: $requestData');
      
      final response = await http.put(
        Uri.parse('$apiBaseUrl/friends/$friendId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // รีเซ็ตฟอร์ม
        _resetForm();
        
        // ดึงข้อมูลสมาชิกใหม่
        await fetchFriends();
        
        if (mounted) {
          // แสดงข้อความแจ้งเตือน
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขสมาชิกสำเร็จ'), backgroundColor: Colors.green),
          );
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            errorMessage = errorData['error'] ?? 'ไม่สามารถแก้ไขสมาชิกได้ (สถานะโค้ด: ${response.statusCode})';
            isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        } catch (e) {
          setState(() {
            errorMessage = 'ไม่สามารถแปลงข้อมูลตอบกลับ: ${response.body}';
            isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  // ฟังก์ชันสำหรับลบสมาชิก
  Future<void> deleteFriend(int friendId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/friends/$friendId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        // ดึงข้อมูลสมาชิกใหม่
        await fetchFriends();
        
        if (mounted) {
          // แสดงข้อความแจ้งเตือน
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบสมาชิกสำเร็จ'), backgroundColor: Colors.green),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'] ?? 'ไม่สามารถลบสมาชิกได้';
          isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  // รีเซ็ตค่าในฟอร์ม
  void _resetForm() {
    _fnameController.clear();
    _lnameController.clear();
    _nicknameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _photoUrlController.clear();
    _noteController.clear();
    
    setState(() {
      _isPhoneValid = true;
      _isEmailValid = true;
      _phoneErrorText = '';
      _emailErrorText = '';
    });
  }
  
  // แสดงไดอะล็อกสำหรับเพิ่มสมาชิก
  void _showAddFriendDialog() {
    // รีเซ็ตฟอร์ม
    _resetForm();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('เพิ่มสมาชิกใหม่'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _fnameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ',
                      hintText: 'กรุณากรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง',
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // อัพเดทสถานะปุ่ม
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lnameController,
                    decoration: const InputDecoration(
                      labelText: 'นามสกุล',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเล่น',
                      hintText: 'กรุณากรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง',
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // อัพเดทสถานะปุ่ม
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'เบอร์โทรศัพท์',
                      errorText: !_isPhoneValid ? _phoneErrorText : null,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // รับเฉพาะตัวเลข
                      LengthLimitingTextInputFormatter(10), // จำกัดความยาว 10 ตัว
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        validatePhone(value); // ตรวจสอบเบอร์โทรแบบ real-time
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'อีเมล',
                      errorText: !_isEmailValid ? _emailErrorText : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setDialogState(() {
                        validateEmail(value); // ตรวจสอบอีเมลแบบ real-time
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _photoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL รูปภาพ',
                      hintText: 'https://example.com/photo.jpg',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'บันทึกเพิ่มเติม',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                // ปุ่มจะเปิดใช้งานได้เฉพาะเมื่อมีชื่อหรือชื่อเล่น และข้อมูลอื่นผ่านการตรวจสอบ
                onPressed: (validateRequiredFields() && _isPhoneValid && _isEmailValid)
                  ? () {
                      Navigator.pop(context);
                      addFriend();
                    }
                  : null,
                child: const Text('เพิ่ม'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // แสดงไดอะล็อกสำหรับแก้ไขสมาชิก
  void _showEditFriendDialog(Map<String, dynamic> friend) {
    // กำหนดค่าเริ่มต้นให้กับฟอร์ม
    _fnameController.text = friend['fname'] ?? '';
    _lnameController.text = friend['lname'] ?? '';
    _nicknameController.text = friend['nickname'] ?? '';
    _phoneController.text = friend['phone'] ?? '';
    _emailController.text = friend['email'] ?? '';
    _photoUrlController.text = friend['photo_url'] ?? '';
    _noteController.text = friend['note'] ?? '';
    
    // รีเซ็ตสถานะการตรวจสอบ
    _isPhoneValid = true;
    _isEmailValid = true;
    _phoneErrorText = '';
    _emailErrorText = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('แก้ไขข้อมูลสมาชิก'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _fnameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ',
                      hintText: 'กรุณากรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง',
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // อัพเดทสถานะปุ่ม
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lnameController,
                    decoration: const InputDecoration(
                      labelText: 'นามสกุล',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อเล่น',
                      hintText: 'กรุณากรอกชื่อหรือชื่อเล่นอย่างน้อยหนึ่งอย่าง',
                    ),
                    onChanged: (value) {
                      setDialogState(() {}); // อัพเดทสถานะปุ่ม
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'เบอร์โทรศัพท์',
                      errorText: !_isPhoneValid ? _phoneErrorText : null,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // รับเฉพาะตัวเลข
                      LengthLimitingTextInputFormatter(10), // จำกัดความยาว 10 ตัว
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        validatePhone(value, excludeId: friend['id']); // ตรวจสอบเบอร์โทรแบบ real-time พร้อมยกเว้น ID เดิม
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'อีเมล',
                      errorText: !_isEmailValid ? _emailErrorText : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setDialogState(() {
                        validateEmail(value, excludeId: friend['id']); // ตรวจสอบอีเมลแบบ real-time พร้อมยกเว้น ID เดิม
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _photoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL รูปภาพ',
                      hintText: 'https://example.com/photo.jpg',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'บันทึกเพิ่มเติม',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                // ปุ่มจะเปิดใช้งานได้เฉพาะเมื่อมีชื่อหรือชื่อเล่น และข้อมูลอื่นผ่านการตรวจสอบ
                onPressed: (validateRequiredFields() && _isPhoneValid && _isEmailValid)
                  ? () {
                      Navigator.pop(context);
                      editFriend(friend['id']);
                    }
                  : null,
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // แสดงไดอะล็อกยืนยันการลบสมาชิก
  void _showDeleteConfirmationDialog(Map<String, dynamic> friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบสมาชิก'),
        content: Text('คุณต้องการลบ "${friend['fname'] ?? ''} ${friend['lname'] ?? ''}" ออกจากโฟลเดอร์นี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteFriend(friend['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder['name'] ?? 'รายละเอียดโฟลเดอร์'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: isLoading && friends.isEmpty
          ? const Center(child: CircularProgressIndicator())  // แสดงการโหลดเฉพาะเมื่อยังไม่มีข้อมูล
          : Column(
              children: [
                // ส่วนแสดงข้อมูลโฟลเดอร์
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder,
                            size: 72,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.folder['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.folder['detail'] != null && widget.folder['detail'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      widget.folder['detail'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 24,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'จำนวนสมาชิก: ${friends.length} คน',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _showAddFriendDialog,
                              icon: Icon(Icons.person_add, color: Colors.blue.shade600),
                              label: Text(
                                'เพิ่มสมาชิก',
                                style: TextStyle(color: Colors.blue.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // หัวข้อรายชื่อสมาชิก
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.people, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'รายชื่อสมาชิก',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // รายชื่อสมาชิก
                Expanded(
                  child: friends.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, color: Colors.grey.shade400, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'ยังไม่มีสมาชิกในโฟลเดอร์นี้',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showAddFriendDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('เพิ่มสมาชิกใหม่'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  backgroundColor: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: friends.length,
                              itemBuilder: (context, index) {
                                final friend = friends[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      backgroundImage: friend['photo_url'] != null && friend['photo_url'].toString().isNotEmpty
                                        ? NetworkImage(friend['photo_url'])
                                        : null,
                                      child: friend['photo_url'] == null || friend['photo_url'].toString().isEmpty
                                        ? Text(
                                            (friend['nickname'] != null && friend['nickname'].toString().isNotEmpty)
                                              ? friend['nickname'].toString()[0].toUpperCase()
                                              : (friend['fname'] != null && friend['fname'].toString().isNotEmpty)
                                                ? friend['fname'].toString()[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                    ),
                                    title: Text(
                                      [
                                        friend['fname'] ?? '',
                                        friend['lname'] ?? ''
                                      ].where((part) => part.isNotEmpty).join(' '),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (friend['nickname'] != null && friend['nickname'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text('ชื่อเล่น: ${friend['nickname']}'),
                                          ),
                                        if (friend['phone'] != null && friend['phone'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text('เบอร์โทร: ${friend['phone']}'),
                                          ),
                                        if (friend['email'] != null && friend['email'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text('อีเมล: ${friend['email']}'),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue.shade600),
                                          onPressed: () => _showEditFriendDialog(friend),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteConfirmationDialog(friend),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                            // แสดง Indicator การโหลดที่มุมขวาบน
                            if (isLoading)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
      // เพิ่มปุ่ม FAB สำหรับเพิ่มสมาชิก
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.person_add),
        tooltip: 'เพิ่มสมาชิกใหม่',
      ),
    );
  }
}