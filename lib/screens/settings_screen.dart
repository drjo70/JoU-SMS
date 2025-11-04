import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'debug_screen.dart';
import 'realtime_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '로딩 중...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '버전 ${packageInfo.version} (빌드 ${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = '버전 정보 없음';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            return ListView(
              children: [
                // 권한 섹션
                _buildSectionHeader('권한 관리'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: provider.permissionsGranted
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            provider.permissionsGranted
                                ? Icons.check_circle
                                : Icons.error,
                            color: provider.permissionsGranted
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: const Text('권한 상태'),
                        subtitle: Text(
                          provider.permissionsGranted
                              ? '모든 권한이 허용되었습니다'
                              : '일부 권한이 거부되었습니다',
                        ),
                        trailing: !provider.permissionsGranted
                            ? TextButton(
                                onPressed: () async {
                                  final granted =
                                      await provider.requestPermissions();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          granted
                                              ? '권한이 허용되었습니다'
                                              : '권한 허용이 필요합니다',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('권한 요청'),
                              )
                            : null,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('전화 상태 읽기'),
                        subtitle: const Text('전화 수신을 감지하기 위해 필요합니다'),
                        trailing: Icon(
                          provider.permissionsGranted
                              ? Icons.check
                              : Icons.close,
                          color: provider.permissionsGranted
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.sms),
                        title: const Text('SMS 발송'),
                        subtitle: const Text('문자를 자동으로 발송하기 위해 필요합니다'),
                        trailing: Icon(
                          provider.permissionsGranted
                              ? Icons.check
                              : Icons.close,
                          color: provider.permissionsGranted
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // 발송 간격 설정 섹션
                _buildSectionHeader('발송 간격 설정'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.schedule, color: Colors.purple),
                        ),
                        title: const Text('동일 번호 재발송 간격'),
                        subtitle: Text(
                          '현재 설정: ${provider.getSendIntervalText()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showIntervalDialog(context, provider),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '같은 번호로 다시 문자를 보내기까지의 최소 간격을 설정합니다.\n고객이 불편하지 않도록 적절한 간격을 선택하세요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 앱 정보 섹션
                _buildSectionHeader('앱 정보'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info, color: Colors.blue),
                        ),
                        title: const Text('자동 홍보문자'),
                        subtitle: Text(_appVersion),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('앱 설명'),
                        subtitle: const Text(
                          '전화가 올 때 자동으로 홍보 문자를 발송하는\n소상공인 마케팅 앱',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bug_report, color: Colors.red),
                        ),
                        title: const Text('디버그 로그'),
                        subtitle: const Text('문제 해결을 위한 상세 로그'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebugScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.terminal, color: Colors.orange),
                        ),
                        title: const Text('실시간 로그 뷰어'),
                        subtitle: const Text('앱 실행 중 발생하는 로그를 실시간으로 확인'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RealtimeLogScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 시스템 설정 섹션
                _buildSectionHeader('시스템 설정'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.settings, color: Colors.orange),
                    ),
                    title: const Text('앱 설정 열기'),
                    subtitle: const Text('시스템 설정에서 권한을 변경할 수 있습니다'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await openAppSettings();
                    },
                  ),
                ),

                // 사용 안내
                _buildSectionHeader('사용 안내'),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuideItem(
                          '1',
                          '홍보 문구 작성',
                          '발송할 홍보 문구를 미리 작성해두세요',
                        ),
                        const SizedBox(height: 12),
                        _buildGuideItem(
                          '2',
                          '자동 발송 활성화',
                          '홈 화면에서 자동 발송을 켜주세요',
                        ),
                        const SizedBox(height: 12),
                        _buildGuideItem(
                          '3',
                          '전화 수신 시 자동 발송',
                          '전화가 오면 선택한 문구가 자동으로 발송됩니다',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 개발자 정보
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '(주)조유',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '소상공인을 위한 스마트 마케팅 솔루션',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildGuideItem(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIntervalDialog(BuildContext context, AppProvider provider) {
    final intervals = [
      {'days': 0, 'label': '매번', 'desc': '전화올 때마다 발송'},
      {'days': 7, 'label': '1주일', 'desc': '최소 7일 간격'},
      {'days': 30, 'label': '1개월', 'desc': '최소 30일 간격'},
      {'days': 90, 'label': '3개월', 'desc': '최소 90일 간격'},
      {'days': 180, 'label': '6개월', 'desc': '최소 180일 간격'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('발송 간격 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            final isSelected = provider.sendInterval == interval['days'];
            return RadioListTile<int>(
              value: interval['days'] as int,
              groupValue: provider.sendInterval,
              onChanged: (value) {
                if (value != null) {
                  provider.setSendInterval(value);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('발송 간격이 "${interval['label']}"(으)로 설정되었습니다'),
                    ),
                  );
                }
              },
              title: Text(
                interval['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                interval['desc'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              activeColor: Colors.purple,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
