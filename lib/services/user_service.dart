import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userIdKey = 'flutter.user_id';
  static const String _userRegisteredKey = 'flutter.user_registered';

  /// 사용자 등록 (앱 최초 실행 시)
  Future<void> registerUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRegistered = prefs.getBool(_userRegisteredKey) ?? false;

      if (isRegistered) {
        debugPrint('✅ 이미 등록된 사용자입니다');
        return;
      }

      // 고유 사용자 ID 생성
      String userId = prefs.getString(_userIdKey) ?? '';
      if (userId.isEmpty) {
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_userIdKey, userId);
      }

      // Firestore에 사용자 정보 저장
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'installedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'appVersion': '1.6.0',
        'totalSends': 0,
        'successSends': 0,
        'failedSends': 0,
      }, SetOptions(merge: true));

      await prefs.setBool(_userRegisteredKey, true);
      debugPrint('✅ 사용자 등록 완료: $userId');
    } catch (e) {
      debugPrint('❌ 사용자 등록 실패: $e');
    }
  }

  /// 사용자 활동 업데이트 (앱 실행 시)
  Future<void> updateLastActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ 사용자 ID가 없습니다. 등록을 먼저 실행하세요.');
        return;
      }

      await _firestore.collection('users').doc(userId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ 사용자 활동 업데이트: $userId');
    } catch (e) {
      debugPrint('❌ 활동 업데이트 실패: $e');
    }
  }

  /// SMS 발송 통계 업데이트
  Future<void> updateSendStatistics(bool success) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);

      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ 사용자 ID가 없습니다');
        return;
      }

      // 사용자별 통계 업데이트
      await _firestore.collection('users').doc(userId).update({
        'totalSends': FieldValue.increment(1),
        if (success) 'successSends': FieldValue.increment(1),
        if (!success) 'failedSends': FieldValue.increment(1),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // 전체 통계 업데이트 (날짜별)
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('statistics').doc(dateKey).set({
        'date': dateKey,
        'totalSends': FieldValue.increment(1),
        if (success) 'successSends': FieldValue.increment(1),
        if (!success) 'failedSends': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ 통계 업데이트 완료: ${success ? "성공" : "실패"}');
    } catch (e) {
      debugPrint('❌ 통계 업데이트 실패: $e');
    }
  }

  /// 사용자 ID 가져오기
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
}
