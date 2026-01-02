import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  bool _isMinimized = false;

  // 显示窗口
  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
    _isMinimized = false;
  }

  // 隐藏窗口（最小化到托盘）
  Future<void> hide() async {
    await windowManager.hide();
    _isMinimized = true;
  }

  // 切换显示/隐藏
  Future<void> toggle() async {
    if (_isMinimized) {
      await show();
    } else {
      await hide();
    }
  }

  // 最小化窗口
  Future<void> minimize() async {
    await windowManager.minimize();
  }

  // 最大化窗口
  Future<void> maximize() async {
    await windowManager.maximize();
  }

  // 关闭窗口（但不退出应用）
  Future<void> close() async {
    await hide();
  }

  // 退出应用
  Future<void> exit() async {
    await windowManager.destroy();
  }

  // 检查窗口是否可见
  Future<bool> isVisible() async {
    return await windowManager.isVisible();
  }

  // 设置窗口始终置顶
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    await windowManager.setAlwaysOnTop(alwaysOnTop);
  }

  // 设置窗口大小
  Future<void> setSize(Size size) async {
    await windowManager.setSize(size);
  }

  // 设置窗口位置
  Future<void> setPosition(Offset position) async {
    await windowManager.setPosition(position);
  }

  // 居中窗口
  Future<void> center() async {
    await windowManager.center();
  }
}

