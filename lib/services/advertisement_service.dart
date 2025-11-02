import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase Firestore에서 광고 문구를 가져오는 서비스
class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 활성화된 광고 문구 가져오기
  Future<String?> getActiveAdvertisement() async {
    try {
      debugPrint('🔍 Fetching active advertisement from Firestore...');
      
      final querySnapshot = await _firestore
          .collection('advertisements')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ No active advertisement found');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final adText = data['text'] as String?;
      
      if (adText != null) {
        debugPrint('✅ Advertisement loaded: $adText');
        
        // 조회수 증가
        await _incrementViewCount(doc.id);
      }
      
      return adText;
      
    } catch (e) {
      debugPrint('❌ Error fetching advertisement: $e');
      return null;
    }
  }
  
  /// 광고 조회수 증가
  Future<void> _incrementViewCount(String adId) async {
    try {
      await _firestore.collection('advertisements').doc(adId).update({
        'viewCount': FieldValue.increment(1),
      });
      debugPrint('📊 Advertisement view count incremented');
    } catch (e) {
      debugPrint('❌ Error incrementing view count: $e');
    }
  }
  
  /// SMS 발송 통계 전송
  Future<void> sendSmsStatistics({
    required String deviceId,
    required String phoneNumber,
    required bool success,
  }) async {
    try {
      debugPrint('📊 Sending SMS statistics to Firestore...');
      
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // 통계 문서 참조
      final statDoc = _firestore.collection('statistics').doc(dateKey);
      
      // 통계 업데이트
      await statDoc.set({
        'date': dateKey,
        'totalSends': FieldValue.increment(1),
        'successSends': success ? FieldValue.increment(1) : 0,
        'failedSends': !success ? FieldValue.increment(1) : 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // 사용자 통계 업데이트
      final userDoc = _firestore.collection('users').doc(deviceId);
      await userDoc.set({
        'deviceId': deviceId,
        'totalSends': FieldValue.increment(1),
        'lastSendTime': FieldValue.serverTimestamp(),
        'lastPhoneNumber': phoneNumber,
      }, SetOptions(merge: true));
      
      debugPrint('✅ Statistics sent successfully');
      
    } catch (e) {
      debugPrint('❌ Error sending statistics: $e');
    }
  }
  
  /// 고유 기기 ID 생성 (간단한 버전)
  String generateDeviceId() {
    // 실제 구현에서는 device_info_plus 패키지 사용 권장
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
