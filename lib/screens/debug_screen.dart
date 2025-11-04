import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = '로딩 중...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final buffer = StringBuffer();
      buffer.writeln('=== JoU SMS 디버그 정보 ===\n');
      buffer.writeln('📅 시간: ${DateTime.now()}\n');
      
      // SharedPreferences 모든 키 출력
      buffer.writeln('--- SharedPreferences 전체 데이터 ---');
      final keys = prefs.getKeys();
      if (keys.isEmpty) {
        buffer.writeln('❌ 저장된 데이터 없음!\n');
      } else {
        for (var key in keys) {
          final value = prefs.get(key);
          buffer.writeln('$key: $value');
        }
      }
      buffer.writeln('');
      
      // 중요 설정값 체크
      buffer.writeln('--- 중요 설정값 ---');
      buffer.writeln('자동발송: ${prefs.getBool("flutter.auto_send_enabled") ?? false}');
      buffer.writeln('발송간격: ${prefs.getInt("flutter.send_interval") ?? 0}일');
      
      final message = prefs.getString("flutter.promo_message");
      if (message != null && message.isNotEmpty) {
        buffer.writeln('활성메시지: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
      } else {
        buffer.writeln('❌ 활성메시지: 없음!');
      }
      
      final lastSendTimes = prefs.getString("flutter.last_send_times");
      buffer.writeln('발송기록: ${lastSendTimes ?? "없음"}');
      buffer.writeln('');
      
      // 템플릿 정보
      buffer.writeln('--- 템플릿 정보 ---');
      final templatesJson = prefs.getString("flutter.templates");
      if (templatesJson != null && templatesJson.isNotEmpty) {
        try {
          final decoded = templatesJson;
          buffer.writeln('템플릿 데이터: ${decoded.substring(0, decoded.length > 200 ? 200 : decoded.length)}...');
        } catch (e) {
          buffer.writeln('❌ 템플릿 파싱 오류: $e');
        }
      } else {
        buffer.writeln('❌ 템플릿 없음!');
      }
      buffer.writeln('');
      
      // 발송 기록
      buffer.writeln('--- 발송 기록 ---');
      final historyJson = prefs.getString("flutter.history");
      if (historyJson != null && historyJson.isNotEmpty) {
        try {
          final decoded = historyJson;
          buffer.writeln('발송 기록 데이터: ${decoded.substring(0, decoded.length > 200 ? 200 : decoded.length)}...');
        } catch (e) {
          buffer.writeln('❌ 발송 기록 파싱 오류: $e');
        }
      } else {
        buffer.writeln('발송 기록 없음');
      }
      buffer.writeln('');
      
      buffer.writeln('=== 디버그 정보 끝 ===');
      
      setState(() {
        _debugInfo = buffer.toString();
      });
    } catch (e) {
      setState(() {
        _debugInfo = '오류 발생: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 디버그 로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _debugInfo));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그가 클립보드에 복사되었습니다!')),
              );
            },
            tooltip: '복사',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '이 정보를 복사해서 개발자에게 전달하세요',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _debugInfo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
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
