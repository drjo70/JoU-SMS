import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  Map<Permission, PermissionStatus> _permissions = {};
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);
    
    final permissions = {
      Permission.phone: await Permission.phone.status,
      Permission.sms: await Permission.sms.status,
      Permission.contacts: await Permission.contacts.status,
    };
    
    setState(() {
      _permissions = permissions;
      _isChecking = false;
    });
  }

  Future<void> _requestAllPermissions() async {
    final results = await [
      Permission.phone,
      Permission.sms,
      Permission.contacts,
    ].request();
    
    await _checkPermissions();
    
    if (results.values.every((status) => status.isGranted)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 모든 권한이 허용되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _permissions.values.every((status) => status.isGranted);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 권한 설정'),
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 설명 카드
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 48, color: Colors.blue.shade700),
                          const SizedBox(height: 12),
                          const Text(
                            '자동 문자 발송을 위해\n다음 권한이 필요합니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 권한 목록
                  _buildPermissionTile(
                    icon: Icons.phone,
                    title: '전화',
                    description: '전화 수신을 감지합니다',
                    permission: Permission.phone,
                  ),
                  _buildPermissionTile(
                    icon: Icons.sms,
                    title: 'SMS',
                    description: '자동으로 문자를 발송합니다',
                    permission: Permission.sms,
                  ),
                  _buildPermissionTile(
                    icon: Icons.contacts,
                    title: '연락처',
                    description: '전화번호 정보를 읽습니다',
                    permission: Permission.contacts,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 권한 요청 버튼
                  if (!allGranted)
                    ElevatedButton.icon(
                      onPressed: _requestAllPermissions,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('권한 허용하기'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  
                  // 모든 권한 허용됨
                  if (allGranted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '모든 권한이 허용되었습니다!\n앱을 정상적으로 사용할 수 있습니다.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 경고 메시지
                  if (!allGranted)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '권한을 허용하지 않으면 자동 문자 발송이 작동하지 않습니다.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String description,
    required Permission permission,
  }) {
    final status = _permissions[permission] ?? PermissionStatus.denied;
    final isGranted = status.isGranted;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGranted ? Colors.green.shade100 : Colors.grey.shade100,
          child: Icon(
            icon,
            color: isGranted ? Colors.green.shade700 : Colors.grey.shade700,
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: isGranted ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
