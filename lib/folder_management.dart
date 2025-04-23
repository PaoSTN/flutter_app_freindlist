import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FolderPage extends StatefulWidget {
  final Map<String, dynamic> user;
  
  const FolderPage({super.key, required this.user});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<Map<String, dynamic>> folders = [];
  bool isLoading = true;
  String errorMessage = '';
  final String apiBaseUrl = 'http://localhost:3000';
  
  // Controllers สำหรับฟอร์มสร้างและแก้ไขโฟลเดอร์
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    fetchFolders();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }
  
  // ฟังก์ชันสำหรับดึงข้อมูลโฟลเดอร์
  Future<void> fetchFolders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
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
          errorMessage = 'ไม่สามารถดึงข้อมูลโฟลเดอร์ได้';
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
  
  // ฟังก์ชันสำหรับเพิ่มโฟลเดอร์ใหม่
  Future<void> addFolder() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อโฟลเดอร์'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/folders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.user['id'],
          'name': _nameController.text.trim(),
          'detail': _detailController.text.trim(),
        }),
      );
      
      if (response.statusCode == 200) {
        // รีเซ็ตฟอร์ม
        _nameController.clear();
        _detailController.clear();
        
        // ดึงข้อมูลโฟลเดอร์ใหม่
        fetchFolders();
        
        // แสดงข้อความแจ้งเตือน
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างโฟลเดอร์สำเร็จ'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'] ?? 'ไม่สามารถสร้างโฟลเดอร์ได้';
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
  
  // ฟังก์ชันสำหรับแก้ไขโฟลเดอร์
  Future<void> editFolder(int folderId) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อโฟลเดอร์'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/folders/$folderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'detail': _detailController.text.trim(),
        }),
      );
      
      if (response.statusCode == 200) {
        // รีเซ็ตฟอร์ม
        _nameController.clear();
        _detailController.clear();
        
        // ดึงข้อมูลโฟลเดอร์ใหม่
        fetchFolders();
        
        // แสดงข้อความแจ้งเตือน
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขโฟลเดอร์สำเร็จ'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'] ?? 'ไม่สามารถแก้ไขโฟลเดอร์ได้';
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
  
  // ฟังก์ชันสำหรับลบโฟลเดอร์
  Future<void> deleteFolder(int folderId) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/folders/$folderId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        // ดึงข้อมูลโฟลเดอร์ใหม่
        fetchFolders();
        
        // แสดงข้อความแจ้งเตือน
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบโฟลเดอร์สำเร็จ'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'] ?? 'ไม่สามารถลบโฟลเดอร์ได้';
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
  
  // แสดงไดอะล็อกสำหรับเพิ่มโฟลเดอร์
  void _showAddFolderDialog() {
    // รีเซ็ตฟอร์ม
    _nameController.clear();
    _detailController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สร้างโฟลเดอร์ใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโฟลเดอร์',
                  hintText: 'เช่น ครอบครัว, เพื่อน, ที่ทำงาน',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด (ไม่บังคับ)',
                  hintText: 'เพิ่มรายละเอียดเกี่ยวกับโฟลเดอร์นี้',
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
            onPressed: () {
              Navigator.pop(context);
              addFolder();
            },
            child: const Text('สร้าง'),
          ),
        ],
      ),
    );
  }
  
  // แสดงไดอะล็อกสำหรับแก้ไขโฟลเดอร์
  void _showEditFolderDialog(Map<String, dynamic> folder) {
    // กำหนดค่าเริ่มต้นให้กับฟอร์ม
    _nameController.text = folder['name'] ?? '';
    _detailController.text = folder['detail'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขโฟลเดอร์'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโฟลเดอร์',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด (ไม่บังคับ)',
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
            onPressed: () {
              Navigator.pop(context);
              editFolder(folder['id']);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
  
  // แสดงไดอะล็อกยืนยันการลบโฟลเดอร์
  void _showDeleteConfirmationDialog(Map<String, dynamic> folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบโฟลเดอร์'),
        content: Text('คุณต้องการลบโฟลเดอร์ "${folder['name']}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteFolder(folder['id']);
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
        title: const Text('จัดการโฟลเดอร์'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchFolders,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            )
          : folders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_outlined, color: Colors.blue.shade200, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีโฟลเดอร์',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'คลิกปุ่ม + ด้านล่างเพื่อสร้างโฟลเดอร์ใหม่',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      leading: Icon(Icons.folder, color: Colors.blue.shade400, size: 32),
                      title: Text(
                        folder['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: folder['detail'] != null && folder['detail'].toString().isNotEmpty
                        ? Text(folder['detail'])
                        : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade700),
                            onPressed: () => _showEditFolderDialog(folder),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmationDialog(folder),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add),
      ),
    );
  }
}