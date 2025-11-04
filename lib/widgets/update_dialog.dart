import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/version_check_service.dart';

/// 앱 업데이트 다이얼로그
class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.forceUpdate, // 강제 업데이트 시 뒤로가기 막기
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Text(updateInfo.forceUpdate ? '필수 업데이트' : '업데이트 가능'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 버전 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '현재 버전',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          updateInfo.currentVersion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '최신 버전',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          updateInfo.latestVersion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 릴리즈 노트
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                const Text(
                  '업데이트 내용',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    updateInfo.releaseNotes,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 강제 업데이트 경고
              if (updateInfo.forceUpdate)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '이 업데이트는 필수입니다.\n계속하려면 앱을 업데이트하세요.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          // 나중에 버튼 (강제 업데이트가 아닐 때만)
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),

          // 업데이트 버튼
          ElevatedButton(
            onPressed: () async {
              // APK 다운로드 URL 열기
              final uri = Uri.parse(updateInfo.apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                // URL 열기 실패 시 업데이트 페이지로 이동
                final fallbackUri = Uri.parse(updateInfo.updateUrl);
                if (await canLaunchUrl(fallbackUri)) {
                  await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                }
              }

              if (!updateInfo.forceUpdate && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('지금 업데이트'),
          ),
        ],
      ),
    );
  }
}
