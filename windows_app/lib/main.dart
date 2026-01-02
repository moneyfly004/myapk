import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/cyberpunk_theme.dart';
import 'features/connection/pages/main_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'services/system_tray_service.dart';
import 'core/utils/error_handler.dart';
import 'core/utils/memory_manager.dart';
import 'core/cache/memory_cache.dart';
import 'core/config/version_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化版本配置（参考 Android 端）
  await VersionConfig.instance.initialize();
  
  // 设置全局错误处理
  setupGlobalErrorHandling();
  
  // 初始化内存管理器
  MemoryManager().initialize();
  
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

  // 系统托盘将在 MyApp 中初始化（需要 WidgetRef）

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

// 路由配置
final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) {
        // 双重检查：确保已登录才能进入主界面
        final authState = ProviderScope.containerOf(context).read(authStateProvider);
        if (!authState.isAuthenticated) {
          // 如果未登录，重定向到登录页
          return const LoginPage();
        }
        return const MainPage();
      },
    ),
  ],
  redirect: (context, state) {
    // 检查登录状态
    final authState = ProviderScope.containerOf(context).read(authStateProvider);
    final isLoginPage = state.matchedLocation == '/login';
    
    if (!authState.isAuthenticated && !isLoginPage) {
      return '/login';
    }
    if (authState.isAuthenticated && isLoginPage) {
      return '/main';
    }
    return null;
  },
  refreshListenable: null, // 需要手动处理状态变化
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化系统托盘（需要 ref）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemTrayService().initialize(ref);
    });

    // 监听认证状态变化，自动重定向
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated) {
          _router.go('/main');
        } else {
          _router.go('/login');
        }
      }
    });

    return MaterialApp.router(
      title: 'NekoBox for Windows',
      debugShowCheckedModeBanner: false,
      theme: CyberpunkTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}
