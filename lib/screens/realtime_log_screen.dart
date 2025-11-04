import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class RealtimeLogScreen extends StatefulWidget {
  const RealtimeLogScreen({super.key});

  @override
  State<RealtimeLogScreen> createState() => _RealtimeLogScreenState();
}

class _RealtimeLogScreenState extends State<RealtimeLogScreen> {
  static const platform = MethodChannel('com.joyou.autopromosms/logs');
  final List<String> _logs = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLogMonitoring();
  }

  void _startLogMonitoring() {
    // 1초마다 로그 체크
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final String logs = await platform.invokeMethod('getRecentLogs');
        if (logs.isNotEmpty && mounted) {
          setState(() {
            _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $logs');
            if (_logs.length > 100) {
              _logs.removeRange(100, _logs.length);
            }
          });
        }
      } catch (e) {
        debugPrint('로그 가져오기 실패: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copyLogs() {
    final allLogs = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그가 클립보드에 복사되었습니다')),
    );
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('실시간 로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: '로그 복사',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: '로그 삭제',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade100,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📞 전화 수신 감지 로그',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '지금 이 화면을 켜둔 상태에서\n다른 폰으로 전화를 걸어보세요!',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_in_talk, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '전화를 기다리는 중...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color bgColor = Colors.white;
                      if (log.contains('📞')) bgColor = Colors.blue.shade50;
                      if (log.contains('✅')) bgColor = Colors.green.shade50;
                      if (log.contains('❌')) bgColor = Colors.red.shade50;
                      if (log.contains('🚀')) bgColor = Colors.orange.shade50;

                      return Container(
                        color: bgColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          log,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
