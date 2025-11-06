import 'package:flutter/material.dart';
import 'package:phone_state/phone_state.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
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
  static const platform = MethodChannel('com.joyou.sms/sms');
  
  String? _lastPhoneNumber;
  PhoneState _lastPhoneState = PhoneState.nothing();
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _requestPermissions();
    await _startPhoneStateListener();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSendEnabled = prefs.getBool('auto_send_enabled') ?? false;
      _message = prefs.getString('message') ?? _message;
      _messageController.text = _message;
    });
    _addLog('✅ 설정 불러오기 완료');
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_send_enabled', _autoSendEnabled);
    await prefs.setString('message', _message);
    _addLog('💾 설정 저장 완료');
  }

  Future<void> _requestPermissions() async {
    _addLog('🔐 권한 요청 시작...');
    
    final permissions = await [
      Permission.sms,
      Permission.phone,
      Permission.contacts,
    ].request();

    if (permissions[Permission.sms]!.isGranted &&
        permissions[Permission.phone]!.isGranted &&
        permissions[Permission.contacts]!.isGranted) {
      _addLog('✅ 모든 권한 허용됨!');
    } else {
      _addLog('❌ 권한이 거부되었습니다');
    }
  }

  Future<void> _startPhoneStateListener() async {
    _addLog('📞 전화 감지 시작...');
    
    try {
      _phoneStateSubscription = PhoneState.stream.listen((PhoneState state) {
        _addLog('📱 전화 상태 변경: ${state.status}');
        
        // 전화번호 저장
        if (state.number != null && state.number!.isNotEmpty) {
          _lastPhoneNumber = state.number;
          _addLog('📲 전화번호: $_lastPhoneNumber');
        }
        
        // 통화 종료 시 SMS 발송
        if (_lastPhoneState.status == PhoneStateStatus.CALL_STARTED &&
            state.status == PhoneStateStatus.CALL_ENDED) {
          _addLog('🔚 통화 종료 감지!');
          
          if (_autoSendEnabled && _lastPhoneNumber != null) {
            _sendSMS(_lastPhoneNumber!);
          } else {
            _addLog('⏸️ 자동발송이 꺼져있거나 전화번호 없음');
          }
        }
        
        _lastPhoneState = state;
      });
      
      _addLog('✅ 전화 감지 리스너 등록 완료!');
    } catch (e) {
      _addLog('❌ 전화 감지 실패: $e');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    _addLog('🚀 SMS 발송 시작...');
    _addLog('  - 받는 사람: $phoneNumber');
    _addLog('  - 메시지: $_message');
    
    try {
      final bool result = await platform.invokeMethod('sendSMS', {
        'phoneNumber': phoneNumber,
        'message': _message,
      });
      
      if (result) {
        _addLog('✅✅✅ SMS 발송 완료!');
      } else {
        _addLog('❌ SMS 발송 실패');
      }
    } catch (e) {
      _addLog('❌ SMS 발송 실패: $e');
    }
  }

  void _addLog(String log) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $log');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  @override
  void dispose() {
    _phoneStateSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JoU 문자발송 v0.0.1'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 자동발송 토글
            Card(
              child: SwitchListTile(
                title: const Text(
                  '자동발송',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(_autoSendEnabled ? '켜짐 ✅' : '꺼짐 ⏸️'),
                value: _autoSendEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoSendEnabled = value;
                  });
                  _saveSettings();
                  _addLog(_autoSendEnabled ? '✅ 자동발송 ON' : '⏸️ 자동발송 OFF');
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 메시지 입력
            const Text('보낼 메시지:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '메시지를 입력하세요',
              ),
              onChanged: (value) {
                _message = value;
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _saveSettings();
              },
              child: const Text('메시지 저장'),
            ),
            
            const SizedBox(height: 16),
            
            // 로그
            const Text('로그:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
