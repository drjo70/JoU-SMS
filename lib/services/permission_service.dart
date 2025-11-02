import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  // 필요한 모든 권한 요청
  Future<bool> requestAllPermissions() async {
    final phoneStatus = await Permission.phone.request();
    final smsStatus = await Permission.sms.request();
    
    if (kDebugMode) {
      debugPrint('전화 권한: $phoneStatus');
      debugPrint('SMS 권한: $smsStatus');
    }
    
    return phoneStatus.isGranted && smsStatus.isGranted;
  }

  // 권한 상태 확인
  Future<bool> checkPermissions() async {
    final phoneStatus = await Permission.phone.status;
    final smsStatus = await Permission.sms.status;
    
    return phoneStatus.isGranted && smsStatus.isGranted;
  }

  // 개별 권한 요청
  Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // 설정 앱으로 이동
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
