import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/log_service.dart';
import 'screens/log_viewer_screen.dart';

// MethodChannel for native communication
const platform = MethodChannel('com.joyou.sms/phone');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogService().init();
  await LogService().log('🚀 [v0.2.4] 앱 시작!');
  
  // BroadcastReceiver 등록 확인
  try {
    final bool? result = await platform.invokeMethod('registerReceiver');
    await LogService().log('📡 [v0.2.4] BroadcastReceiver 등록: $result');
  } catch (e) {
    await LogService().log('❌ [v0.2.4] BroadcastReceiver 등록 실패: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JoU 문자발송',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _autoSendEnabled = false;
  String _message = '안녕하세요! (주)조유입니다.\n전화 주셔서 감사합니다.';
  final TextEditingController _messageController = TextEditingController();
  
  final LogService _logService = LogService();
  String _currentVersion = '0.2.0';
  String _latestVersion = '';
  bool _hasUpdate = false;
  
  // 권한 상태
  bool _permissionsGranted = false;
  String _permissionStatus = '권한 확인 중...';

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // 앱 시작 시 즉시 권한 요청
    _loadSettings();
    _checkForUpdates();
  }

  // 앱 시작 시 권한 요청
  Future<void> _requestPermissions() async {
    _logService.log('🔐 [v0.2.0] 권한 요청 시작...');
    
    try {
      // SMS 권한
      final smsStatus = await Permission.sms.request();
      _logService.log('📱 [v0.2.0] SMS 권한: $smsStatus');
      
      // 전화 권한
      final phoneStatus = await Permission.phone.request();
      _logService.log('☎️ [v0.2.0] 전화 권한: $phoneStatus');
      
      // 연락처 권한
      final contactsStatus = await Permission.contacts.request();
      _logService.log('👥 [v0.2.0] 연락처 권한: $contactsStatus');
      
      final allGranted = smsStatus.isGranted && 
                         phoneStatus.isGranted && 
                         contactsStatus.isGranted;
      
      setState(() {
        _permissionsGranted = allGranted;
        _permissionStatus = allGranted ? '모든 권한 허용됨 ✅' : '일부 권한 거부됨 ❌';
      });
      
      if (allGranted) {
        _logService.log('✅ [v0.2.0] 모든 권한 허용됨!');
      } else {
        _logService.log('❌ [v0.2.0] 일부 권한 거부됨!');
        _showPermissionDialog();
      }
    } catch (e) {
      _logService.log('❌ [v0.2.0] 권한 요청 오류: $e');
      setState(() {
        _permissionStatus = '권한 요청 실패';
      });
    }
  }

  // 권한 거부 시 안내 다이얼로그
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 권한 필요'),
        content: const Text(
          '자동문자 발송을 위해서는\nSMS, 전화, 연락처 권한이\n모두 필요합니다.\n\n설정에서 권한을 허용해주세요.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    _logService.log('📂 [v0.2.0] 설정 불러오기 시작...');
    final prefs = await SharedPreferences.getInstance();
    
    final enabled = prefs.getBool('auto_send_enabled') ?? false;
    final msg = prefs.getString('message') ?? _message;
    
    setState(() {
      _autoSendEnabled = enabled;
      _message = msg;
      _messageController.text = msg;
    });
    
    _logService.log('✅ [v0.2.0] 설정 불러오기 완료');
    _logService.log('  - 자동발송: $_autoSendEnabled');
    _logService.log('  - 메시지: $_message');
    _logService.log('  - 메시지 길이: ${_message.length}자');
  }

  // 업데이트 체크
  Future<void> _checkForUpdates() async {
    try {
      _logService.log('🔍 [v0.2.0] 업데이트 체크 시작...');
      
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/drjo70/JoU-SMS/releases/latest'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        
        _logService.log('✅ [v0.2.0] 버전 확인 완료');
        _logService.log('  - 현재: $_currentVersion');
        _logService.log('  - 최신: $_latestVersion');
        
        setState(() {
          _hasUpdate = _compareVersions(_currentVersion, _latestVersion) < 0;
        });
        
        if (_hasUpdate) {
          _logService.log('🎉 [v0.2.0] 새 버전 발견!');
          _showUpdateDialog(data['html_url']);
        } else {
          _logService.log('✅ [v0.2.0] 최신 버전 사용 중');
        }
      }
    } catch (e) {
      _logService.log('⚠️ [v0.2.0] 업데이트 체크 실패: $e');
    }
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }
    return 0;
  }

  void _showUpdateDialog(String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 새 버전 발견!'),
        content: Text('v$_latestVersion 버전이 출시되었습니다.\n지금 업데이트하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logService.log('📥 다운로드 URL: $downloadUrl');
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  // 자동발송 토글
  Future<void> _toggleAutoSend() async {
    _logService.log('🔄🔄🔄 [v0.2.0] 자동발송 토글 호출!');
    _logService.log('  - 현재 상태: $_autoSendEnabled');
    _logService.log('  - 권한 상태: $_permissionsGranted');
    
    // 권한 재확인
    if (!_permissionsGranted) {
      _logService.log('❌ [v0.2.0] 권한 없음 - 재요청');
      await _requestPermissions();
      if (!_permissionsGranted) {
        return;
      }
    }
    
    // 메시지 확인
    if (_message.trim().isEmpty) {
      _logService.log('❌ [v0.2.0] 메시지 없음!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 메시지를 입력하고 저장해주세요!')),
      );
      return;
    }
    
    // 상태 변경
    final newValue = !_autoSendEnabled;
    _logService.log('📝 [v0.2.0] SharedPreferences 저장 시작...');
    _logService.log('  - 키: auto_send_enabled');
    _logService.log('  - 값: $newValue');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_send_enabled', newValue);
    
    // 즉시 검증
    final saved = prefs.getBool('auto_send_enabled');
    _logService.log('🔍 [v0.2.0] 저장 후 즉시 확인: $saved');
    
    if (saved == newValue) {
      _logService.log('✅ [v0.2.0] SharedPreferences 저장 성공!');
    } else {
      _logService.log('❌❌❌ [v0.2.0] SharedPreferences 저장 실패!');
    }
    
    setState(() {
      _autoSendEnabled = newValue;
    });
    
    _logService.log('🎉 [v0.2.0] 자동발송 토글 완료! 최종 상태: $_autoSendEnabled');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_autoSendEnabled ? '자동발송 켜짐! ✅' : '자동발송 꺼짐'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 메시지 저장
  Future<void> _saveMessage() async {
    final newMessage = _messageController.text.trim();
    
    if (newMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지를 입력해주세요!')),
      );
      return;
    }
    
    _logService.log('💾 [v0.2.0] 메시지 저장 시작...');
    _logService.log('  - 메시지: $newMessage');
    _logService.log('  - 길이: ${newMessage.length}자');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('message', newMessage);
    
    // 즉시 검증
    final saved = prefs.getString('message');
    _logService.log('🔍 [v0.2.0] 저장 후 확인: $saved');
    
    setState(() {
      _message = newMessage;
    });
    
    print('✅ [v0.1] 메시지 저장 완료!');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 완료! ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JoU 문자발송'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 로그 뷰어 버튼
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogViewerScreen(),
                ),
              );
            },
            tooltip: '로그 보기',
          ),
          if (_hasUpdate)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '업데이트',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 버전 + 권한 상태
              Text(
                'v$_currentVersion',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _permissionStatus,
                style: TextStyle(
                  fontSize: 12,
                  color: _permissionsGranted ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // 자동발송 토글
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '자동발송',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _autoSendEnabled ? '켜짐 ✅' : '꺼짐',
                            style: TextStyle(
                              color: _autoSendEnabled ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _autoSendEnabled,
                        onChanged: (_) => _toggleAutoSend(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 메시지 입력
              Text(
                '발송할 메시지',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                maxLines: 8,
                maxLength: 90,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '여기에 메시지를 입력하세요...',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 저장 버튼
              ElevatedButton(
                onPressed: _saveMessage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('저장', style: TextStyle(fontSize: 16)),
              ),
              
              const SizedBox(height: 32),
              
              // 사용 방법
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 사용 방법',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('1. 권한 모두 허용 ⚠️'),
                      const Text('2. 메시지를 입력하고 저장'),
                      const Text('3. 자동발송을 켬'),
                      const Text('4. 전화가 오면 자동으로 문자 발송!'),
                      const SizedBox(height: 12),
                      Text(
                        '💡 로그 뷰어로 작동 확인 가능',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
