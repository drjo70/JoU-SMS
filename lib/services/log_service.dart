import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  File? _logFile;
  final List<String> _memoryLogs = [];
  static const int maxMemoryLogs = 500;

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logsDir.path}/log_$today.txt');
      
      await log('📱 [LOG] 로그 시스템 초기화 완료');
    } catch (e) {
      print('❌ 로그 파일 초기화 실패: $e');
    }
  }

  Future<void> log(String message) async {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] $message';
    
    // 콘솔 출력
    print(logMessage);
    
    // 메모리에 저장
    _memoryLogs.add(logMessage);
    if (_memoryLogs.length > maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }
    
    // 파일에 저장
    try {
      if (_logFile != null) {
        await _logFile!.writeAsString(
          '$logMessage\n',
          mode: FileMode.append,
          encoding: utf8,
          flush: true,
        );
      }
    } catch (e) {
      print('❌ 로그 파일 쓰기 실패: $e');
    }
  }

  List<String> getMemoryLogs() {
    return List.from(_memoryLogs.reversed);
  }

  Future<String> getLogFilePath() async {
    return _logFile?.path ?? '로그 파일 없음';
  }

  Future<String> getAllLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        final contents = await _logFile!.readAsString(encoding: utf8);
        return contents;
      }
    } catch (e) {
      // 파일 읽기 실패 시 메모리 로그 반환
      return '파일 읽기 실패 (메모리 로그 표시):\n\n${_memoryLogs.reversed.join('\n')}';
    }
    return '로그가 없습니다';
  }

  Future<void> clearLogs() async {
    _memoryLogs.clear();
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.delete();
        await init();
      }
    } catch (e) {
      print('❌ 로그 삭제 실패: $e');
    }
  }
}
