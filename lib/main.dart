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
  int _sendIntervalDays = 0; // 0=매번, 7=1주일, 14=2주일, 30=1개월
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
      _sendIntervalDays = prefs.getInt('send_interval_days') ?? 0;
      _messageController.text = _message;
    });
    _addLog('✅ 설정 불러오기 완료');
    _addLog('  - 발송 간격: ${_getIntervalText()}');
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_send_enabled', _autoSendEnabled);
    await prefs.setString('message', _message);
    await prefs.setInt('send_interval_days', _sendIntervalDays);
    _addLog('💾 설정 저장 완료');
  }

  String _getIntervalText() {
    switch (_sendIntervalDays) {
      case 0:
        return '매번';
      case 7:
        return '1주일';
      case 14:
        return '2주일';
      case 30:
        return '1개월';
      default:
        return '매번';
    }
  }

  Future<bool> _canSendToNumber(String phoneNumber) async {
    if (_sendIntervalDays == 0) {
      _addLog('⏱️ 발송 간격: 매번 (체크 안 함)');
      return true; // 매번 발송
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'last_sent_$phoneNumber';
    final lastSentTime = prefs.getInt(key);

    if (lastSentTime == null) {
      _addLog('📝 $phoneNumber: 첫 발송');
      return true; // 처음 발송
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final daysPassed = (now - lastSentTime) / (1000 * 60 * 60 * 24);

    _addLog('⏱️ $phoneNumber: ${daysPassed.toStringAsFixed(1)}일 경과');
    _addLog('  - 설정 간격: $_sendIntervalDays일');

    if (daysPassed >= _sendIntervalDays) {
      _addLog('✅ 발송 가능! (${daysPassed.toStringAsFixed(1)}일 >= $_sendIntervalDays일)');
      return true;
    } else {
      final remainingDays = (_sendIntervalDays - daysPassed).ceil();
      _addLog('⏸️ 발송 스킵! ($remainingDays일 후 가능)');
      return false;
    }
  }

  Future<void> _recordSentTime(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'last_sent_$phoneNumber';
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(key, now);
    _addLog('📝 발송 기록 저장: $phoneNumber');
  }

  Future<void> _requestPermissions() async {
    _addLog('🔐 권한 요청 시작...');
    
    final permissions = await [
      Permission.sms,
      Permission.phone,
    ].request();

    _addLog('📱 SMS 권한: ${permissions[Permission.sms]}');
    _addLog('☎️ 전화 권한: ${permissions[Permission.phone]}');

    if (permissions[Permission.sms]!.isGranted &&
        permissions[Permission.phone]!.isGranted) {
      _addLog('✅ 모든 권한 허용됨!');
    } else {
      _addLog('❌ 일부 권한이 거부되었습니다');
    }
  }

  Future<void> _startPhoneStateListener() async {
    _addLog('📞 전화 감지 시작...');
    _addLog('🎯 발신/수신 전화 모두 감지합니다!');
    
    try {
      _phoneStateSubscription = PhoneState.stream.listen(
        (PhoneState state) async {
        _addLog('🔔 전화 이벤트 수신!');
        _addLog('📱 전화 상태: ${state.status}');
        _addLog('📱 이전 상태: ${_lastPhoneState.status}');
        
        // 수신 전화: state.number에서 번호 읽기
        if (state.number != null && state.number!.isNotEmpty) {
          _lastPhoneNumber = state.number;
          _addLog('📲 수신 전화번호 감지: $_lastPhoneNumber');
        }
        
        // 통화 종료 시 SMS 발송
        if (_lastPhoneState.status == PhoneStateStatus.CALL_STARTED &&
            state.status == PhoneStateStatus.CALL_ENDED) {
          _addLog('🔚 통화 종료 감지!');
          
          if (!_autoSendEnabled) {
            _addLog('⏸️ 자동발송이 꺼져있음');
          } else {
            // 발신 전화일 경우 CallLog에서 번호 가져오기
            if (_lastPhoneNumber == null) {
              _addLog('🔍 발신 전화로 추정 - CallLog에서 번호 확인 중...');
              await _getLastOutgoingNumber();
            }
            
            if (_lastPhoneNumber != null) {
              _addLog('🚀 SMS 자동발송 시작!');
              _sendSMS(_lastPhoneNumber!);
            } else {
              _addLog('❌ 전화번호를 찾을 수 없습니다');
            }
          }
        }
        
        // 새로운 통화 시작 시 번호 초기화
        if (state.status == PhoneStateStatus.CALL_STARTED) {
          _lastPhoneNumber = state.number; // 수신 전화면 여기서 번호 저장
        }
        
        _lastPhoneState = state;
      },
      onError: (error) {
        _addLog('❌ 리스너 에러: $error');
      },
      onDone: () {
        _addLog('⚠️ 리스너 종료됨');
      },
      cancelOnError: false,
      );
      
      _addLog('✅ 전화 감지 리스너 등록 완료!');
    } catch (e) {
      _addLog('❌ 전화 감지 실패: $e');
    }
  }

  Future<void> _getLastOutgoingNumber() async {
    try {
      final String? phoneNumber = await platform.invokeMethod('getLastOutgoingCall');
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        _lastPhoneNumber = phoneNumber;
        _addLog('📞 발신 전화번호 확보: $_lastPhoneNumber');
      } else {
        _addLog('⚠️ CallLog에서 번호를 찾을 수 없음');
      }
    } catch (e) {
      _addLog('❌ CallLog 읽기 실패: $e');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    _addLog('🚀 SMS 발송 체크 시작...');
    _addLog('  - 받는 사람: $phoneNumber');
    _addLog('  - 발송 간격 설정: ${_getIntervalText()}');
    
    // 발송 간격 체크
    final canSend = await _canSendToNumber(phoneNumber);
    if (!canSend) {
      _addLog('⏸️ 발송 간격 조건 미충족 - SMS 스킵');
      return;
    }
    
    _addLog('  - 메시지: $_message');
    
    try {
      final bool result = await platform.invokeMethod('sendSMS', {
        'phoneNumber': phoneNumber,
        'message': _message,
      });
      
      if (result) {
        _addLog('✅✅✅ SMS 발송 완료!');
        await _recordSentTime(phoneNumber); // 발송 시간 기록
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

  void _showTestSMSDialog() {
    final TextEditingController phoneController = TextEditingController(
      text: _lastPhoneNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테스트 SMS 발송'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _lastPhoneNumber != null
                  ? '마지막 전화번호: $_lastPhoneNumber'
                  : '⚠️ 저장된 전화번호 없음',
              style: TextStyle(
                color: _lastPhoneNumber != null ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '전화번호',
                hintText: '010-1234-5678',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final phoneNumber = phoneController.text.trim();
              if (phoneNumber.isNotEmpty) {
                Navigator.pop(context);
                _addLog('🧪 테스트 SMS 발송: $phoneNumber');
                _sendSMS(phoneNumber);
              } else {
                _addLog('❌ 전화번호를 입력하세요');
              }
            },
            child: const Text('발송'),
          ),
        ],
      ),
    );
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
        title: const Text('JoU 문자발송 v0.3.0'),
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
            
            // 발송 간격 선택
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '발송 간격',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _sendIntervalDays,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('매번')),
                        DropdownMenuItem(value: 7, child: Text('1주일')),
                        DropdownMenuItem(value: 14, child: Text('2주일')),
                        DropdownMenuItem(value: 30, child: Text('1개월')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sendIntervalDays = value!;
                        });
                        _saveSettings();
                        _addLog('⏱️ 발송 간격 변경: ${_getIntervalText()}');
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '동일 번호에 ${_getIntervalText()} 발송',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _saveSettings();
                    },
                    child: const Text('메시지 저장'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _showTestSMSDialog();
                    },
                    child: const Text('테스트 발송'),
                  ),
                ),
              ],
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
