import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'providers/app_provider.dart';
import 'services/version_check_service.dart';
import 'services/user_service.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase 초기화 (옵션 포함)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
    
    // 사용자 등록 (앱 최초 실행 시)
    final userService = UserService();
    await userService.registerUser();
    await userService.updateLastActive();
    
    debugPrint('✅ 사용자 서비스 초기화 완료');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }
  
  runApp(const MyApp());
}

/// 앱 버전 체크 (앱 시작 시)
Future<void> checkAppVersion(BuildContext context) async {
  try {
    final versionService = VersionCheckService();
    final updateInfo = await versionService.checkForUpdate();

    if (updateInfo != null && updateInfo.isUpdateAvailable) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: !updateInfo.forceUpdate,
          builder: (context) => UpdateDialog(updateInfo: updateInfo),
        );
      }
    }
  } catch (e) {
    debugPrint('버전 체크 실패: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'JoU 문자 홍보 자동 발송',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
