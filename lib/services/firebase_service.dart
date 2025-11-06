import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'device_service.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 앱 접속자 정보 업데이트
  static Future<void> updateUserAccess() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final installDate = await DeviceService.getInstallDate();
      final platform = DeviceService.getPlatform();
      
      await _firestore.collection('users').doc(deviceId).set({
        'device_id': deviceId,
        'platform': platform,
        'install_date': installDate != null 
            ? Timestamp.fromDate(installDate) 
            : FieldValue.serverTimestamp(),
        'last_access': FieldValue.serverTimestamp(),
        'last_access_timestamp': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('✅ Firebase: 접속자 정보 업데이트 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase: 접속자 정보 업데이트 실패: $e');
      }
    }
  }
  
  /// SMS 발송 기록 저장
  static Future<void> saveSmsRecord({
    required String phoneNumber,
    required String message,
    required bool success,
    required int intervalDays,
  }) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      
      await _firestore.collection('sms_records').add({
        'device_id': deviceId,
        'phone_number': phoneNumber,
        'message': message,
        'success': success,
        'interval_days': intervalDays,
        'sent_at': FieldValue.serverTimestamp(),
        'sent_timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (kDebugMode) {
        print('✅ Firebase: SMS 발송 기록 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase: SMS 발송 기록 저장 실패: $e');
      }
    }
  }
  
  /// 버전 체크 (24시간마다 1회)
  static Future<Map<String, dynamic>?> checkAppVersion(String currentVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_version_check') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 24시간 체크
      if (now - lastCheck < 24 * 60 * 60 * 1000) {
        if (kDebugMode) {
          print('⏱️ 버전 체크: 24시간 이내 확인함 (스킵)');
        }
        return null;
      }
      
      // Firestore에서 최신 버전 정보 가져오기
      final doc = await _firestore
          .collection('app_config')
          .doc('version_info')
          .get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ 버전 체크: version_info 문서 없음');
        }
        return null;
      }
      
      final data = doc.data()!;
      final latestVersion = data['latest_version'] as String?;
      
      // 마지막 체크 시간 저장
      await prefs.setInt('last_version_check', now);
      
      // 버전 비교
      if (latestVersion != null && latestVersion != currentVersion) {
        if (kDebugMode) {
          print('🎉 새로운 버전 발견: $latestVersion (현재: $currentVersion)');
        }
        return data;
      }
      
      if (kDebugMode) {
        print('✅ 최신 버전 사용 중: $currentVersion');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 버전 체크 실패: $e');
      }
      return null;
    }
  }
}
