import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/log_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LogService _logService = LogService();
  List<String> _logs = [];
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    
    // 1초마다 로그 새로고침
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _loadLogs();
        return true;
      }
      return false;
    });
  }

  void _loadLogs() {
    setState(() {
      _logs = _logService.getMemoryLogs();
    });
  }

  Future<void> _copyAllLogs() async {
    final allLogs = await _logService.getAllLogs();
    await Clipboard.setData(ClipboardData(text: allLogs));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그 복사 완료! ✅')),
      );
    }
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그 삭제'),
        content: const Text('모든 로그를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logService.clearLogs();
      _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그 삭제 완료!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그 뷰어'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllLogs,
            tooltip: '로그 복사',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: '로그 삭제',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 표시
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 총 로그: ${_logs.length}개',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '💡 1초마다 자동 새로고침',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // 로그 리스트
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      '로그가 없습니다\n앱을 사용하면 로그가 표시됩니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    reverse: false,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color bgColor = Colors.white;
                      
                      // 로그 레벨에 따른 색상
                      if (log.contains('❌') || log.contains('ERROR')) {
                        bgColor = Colors.red.shade50;
                      } else if (log.contains('⚠️') || log.contains('WARN')) {
                        bgColor = Colors.orange.shade50;
                      } else if (log.contains('✅') || log.contains('SUCCESS')) {
                        bgColor = Colors.green.shade50;
                      } else if (log.contains('📞') || log.contains('☎️') || log.contains('📲')) {
                        bgColor = Colors.blue.shade50;
                      } else if (log.contains('🚀')) {
                        bgColor = Colors.purple.shade50;
                      }

                      return Container(
                        color: bgColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: SelectableText(
                          log,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadLogs,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
