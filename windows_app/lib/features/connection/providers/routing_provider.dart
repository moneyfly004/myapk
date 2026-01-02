import 'package:flutter_riverpod/flutter_riverpod.dart';

// 路由模式
enum RoutingMode {
  rules,  // 规则模式
  global, // 全局模式
}

// 路由模式状态提供者
final routingModeProvider = StateProvider<RoutingMode>(
  (ref) => RoutingMode.rules,
);

// 切换路由模式
void toggleRoutingMode(WidgetRef ref) {
  final currentMode = ref.read(routingModeProvider);
  ref.read(routingModeProvider.notifier).state = 
    currentMode == RoutingMode.rules 
      ? RoutingMode.global 
      : RoutingMode.rules;
}

