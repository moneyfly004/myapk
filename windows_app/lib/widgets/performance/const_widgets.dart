import 'package:flutter/material.dart';
import '../../core/theme/cyberpunk_theme.dart';

/// 常量化的常用组件（性能优化）
class ConstWidgets {
  // 常量分隔线
  static const Widget separator = SizedBox(height: 16);
  static const Widget smallSeparator = SizedBox(height: 8);
  static const Widget largeSeparator = SizedBox(height: 32);

  // 常量图标
  static Widget icon(IconData data, {Color? color, double size = 24}) {
    return Icon(
      data,
      color: color ?? CyberpunkTheme.primaryNeon,
      size: size,
    );
  }

  // 常量加载指示器
  static Widget loadingIndicator({Color? color}) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? CyberpunkTheme.primaryNeon,
      ),
    );
  }

  // 常量占位符
  static Widget placeholder({double? width, double? height}) {
    return SizedBox(
      width: width,
      height: height,
    );
  }
}

/// 优化的列表项构建器（使用 const）
class OptimizedListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const OptimizedListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

