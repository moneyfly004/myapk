import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/cyberpunk_theme.dart';
import 'features/connection/pages/main_page.dart';
import 'services/system_tray_service.dart';
import 'core/utils/error_handler.dart';
import 'core/cache/memory_cache.dart';
import 'core/config/version_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化版本配置（参考 Android 端）
  await VersionConfig.instance.initialize();
  
  // 设置全局错误处理
  setupGlobalErrorHandling();
  
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  
  const windowOptions = WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(700, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化系统托盘
  final trayService = SystemTrayService();
  await trayService.initialize();

  // 定期清理过期缓存
  _startCacheCleanup();
  
  runApp(const ProviderScope(child: MyApp()));
}

// 定期清理过期缓存
void _startCacheCleanup() {
  Future.delayed(const Duration(minutes: 5), () {
    AppCache().evictExpired();
    _startCacheCleanup(); // 递归调用
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NekoBox for Windows',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const MainPage(),
    );
  }
}
