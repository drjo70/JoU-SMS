import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 앱 버전 체크 서비스
class VersionCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 앱 업데이트 확인
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      debugPrint('🔍 앱 업데이트 확인 중...');

      // 현재 앱 버전 정보 가져오기
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      debugPrint('📱 현재 버전: $currentVersion ($currentVersionCode)');

      // Firestore에서 최신 버전 정보 가져오기
      final versionDoc = await _firestore
          .collection('app_config')
          .doc('version')
          .get();

      if (!versionDoc.exists) {
        debugPrint('⚠️ 버전 정보를 찾을 수 없습니다');
        return null;
      }

      final data = versionDoc.data()!;
      final latestVersion = data['latestVersion'] as String;
      final latestVersionCode = data['latestVersionCode'] as int;
      final minVersionCode = data['minVersionCode'] as int;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      final apkUrl = data['apkUrl'] as String;
      final releaseNotes = data['releaseNotes'] as String? ?? '';
      final updateUrl = data['updateUrl'] as String? ?? '';

      debugPrint('🆕 최신 버전: $latestVersion ($latestVersionCode)');

      // 업데이트 필요 여부 확인
      if (currentVersionCode < latestVersionCode) {
        // 강제 업데이트 확인
        final isCritical = currentVersionCode < minVersionCode;

        debugPrint('📢 업데이트 가능: $currentVersion → $latestVersion');
        debugPrint('⚠️ 강제 업데이트: ${isCritical || forceUpdate}');

        return UpdateInfo(
          currentVersion: currentVersion,
          currentVersionCode: currentVersionCode,
          latestVersion: latestVersion,
          latestVersionCode: latestVersionCode,
          apkUrl: apkUrl,
          releaseNotes: releaseNotes,
          updateUrl: updateUrl,
          isUpdateAvailable: true,
          forceUpdate: isCritical || forceUpdate,
        );
      }

      debugPrint('✅ 최신 버전 사용 중');
      return null;

    } catch (e) {
      debugPrint('❌ 버전 체크 실패: $e');
      return null;
    }
  }
}

/// 업데이트 정보 클래스
class UpdateInfo {
  final String currentVersion;
  final int currentVersionCode;
  final String latestVersion;
  final int latestVersionCode;
  final String apkUrl;
  final String releaseNotes;
  final String updateUrl;
  final bool isUpdateAvailable;
  final bool forceUpdate;

  UpdateInfo({
    required this.currentVersion,
    required this.currentVersionCode,
    required this.latestVersion,
    required this.latestVersionCode,
    required this.apkUrl,
    required this.releaseNotes,
    required this.updateUrl,
    required this.isUpdateAvailable,
    required this.forceUpdate,
  });
}
