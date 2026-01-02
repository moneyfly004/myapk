import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AutoStartService {
  static final AutoStartService _instance = AutoStartService._internal();
  factory AutoStartService() => _instance;
  AutoStartService._internal();

  static const String _autoStartKey = 'auto_start_enabled';

  // 检查是否已启用开机自启动
  Future<bool> isEnabled() async {
    if (!Platform.isWindows) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoStartKey) ?? false;
  }

  // 启用开机自启动
  Future<bool> enable() async {
    if (!Platform.isWindows) return false;

    try {
      // 获取应用路径
      final appPath = Platform.resolvedExecutable;
      
      // 创建启动项注册表项
      // 注意：这需要管理员权限
      final result = await Process.run(
        'reg',
        [
          'add',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
          '/v',
          'NekoBox',
          '/t',
          'REG_SZ',
          '/d',
          '"$appPath"',
          '/f',
        ],
      );

      if (result.exitCode == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_autoStartKey, true);
        return true;
      }
      
      return false;
    } catch (e) {
      // Logger 会在需要时记录
      return false;
    }
  }

  // 禁用开机自启动
  Future<bool> disable() async {
    if (!Platform.isWindows) return false;

    try {
      final result = await Process.run(
        'reg',
        [
          'delete',
          'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
          '/v',
          'NekoBox',
          '/f',
        ],
      );

      if (result.exitCode == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_autoStartKey, false);
        return true;
      }
      
      return false;
    } catch (e) {
      // Logger 会在需要时记录
      return false;
    }
  }

  // 切换自启动状态
  Future<bool> toggle() async {
    final isEnabled = await this.isEnabled();
    if (isEnabled) {
      return await disable();
    } else {
      return await enable();
    }
  }
}

