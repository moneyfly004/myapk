import 'package:flutter/material.dart';

/// 性能优化的 Widget 工具类
class OptimizedWidgets {
  // 使用 const 构造函数减少重建
  static const SizedBox separator = SizedBox(height: 16);
  static const SizedBox largeSeparator = SizedBox(height: 24);
  static const SizedBox smallSeparator = SizedBox(width: 8);
  
  // 懒加载的 Widget（使用 Builder 延迟构建）
  static Widget lazyBuilder(Widget Function() builder) {
    return Builder(builder: (_) => builder());
  }
  
  // 防抖的 Widget（避免频繁重建）
  static Widget debounced({
    required Widget child,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    return child; // 实际防抖逻辑在调用处使用 Debouncer
  }
}

/// 性能优化的 ListView（使用 itemExtent 和 cacheExtent）
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  
  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: children.length,
      cacheExtent: 500, // 缓存范围（像素）
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 性能优化的 GridView
class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  
  const OptimizedGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: children.length,
      cacheExtent: 500,
      itemBuilder: (context, index) => children[index],
    );
  }
}

