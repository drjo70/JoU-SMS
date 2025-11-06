import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static const String _installDateKey = 'install_date';
  
  /// 디바이스 고유 ID 가져오기 (없으면 생성)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      // 새로운 UUID 생성
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      
      // 설치 날짜 저장
      await prefs.setInt(_installDateKey, DateTime.now().millisecondsSinceEpoch);
    }
    
    return deviceId;
  }
  
  /// 앱 설치 날짜 가져오기
  static Future<DateTime?> getInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_installDateKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }
  
  /// 플랫폼 이름 가져오기
  static String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
