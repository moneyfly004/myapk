import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../core/utils/logger.dart';

/// Windows 系统代理服务
/// 用于设置和清除系统代理
class SystemProxyService {
  static const String _proxyKey = r'Software\Microsoft\Windows\CurrentVersion\Internet Settings';
  static const String _enableKey = 'ProxyEnable';
  static const String _serverKey = 'ProxyServer';
  static const String _overrideKey = 'ProxyOverride';

  /// 设置系统代理
  /// [host] 代理服务器地址
  /// [port] 代理服务器端口
  /// [bypass] 绕过列表（用分号分隔，如 "localhost;127.0.0.1;*.local"）
  static Future<bool> setSystemProxy({
    required String host,
    required int port,
    String? bypass,
  }) async {
    try {
      final proxyServer = '$host:$port';
      final bypassList = bypass ?? 'localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>';

      // 打开注册表
      final hKey = HKEY_CURRENT_USER;
      Pointer<HKEY> phkResult = calloc<HKEY>();
      
      var result = RegOpenKeyEx(
        hKey,
        _proxyKey.toNativeUtf16(),
        0,
        KEY_WRITE,
        phkResult,
      );

      if (result != ERROR_SUCCESS) {
        Logger.e('打开注册表失败: $result');
        calloc.free(phkResult);
        return false;
      }

      try {
        // 设置代理服务器
        final serverValue = proxyServer.toNativeUtf16();
        result = RegSetValueEx(
          phkResult.value,
          _serverKey.toNativeUtf16(),
          0,
          REG_SZ,
          serverValue,
          (serverValue.length * 2).toUnsigned(),
        );

        if (result != ERROR_SUCCESS) {
          Logger.e('设置代理服务器失败: $result');
          return false;
        }

        // 设置绕过列表
        final bypassValue = bypassList.toNativeUtf16();
        result = RegSetValueEx(
          phkResult.value,
          _overrideKey.toNativeUtf16(),
          0,
          REG_SZ,
          bypassValue,
          (bypassValue.length * 2).toUnsigned(),
        );

        if (result != ERROR_SUCCESS) {
          Logger.e('设置绕过列表失败: $result');
          return false;
        }

        // 启用代理
        final enableValue = calloc<DWORD>();
        enableValue.value = 1;
        result = RegSetValueEx(
          phkResult.value,
          _enableKey.toNativeUtf16(),
          0,
          REG_DWORD,
          enableValue.cast(),
          sizeOf<DWORD>(),
        );

        calloc.free(enableValue);

        if (result != ERROR_SUCCESS) {
          Logger.e('启用代理失败: $result');
          return false;
        }

        // 通知系统代理设置已更改
        InternetSetOption(
          nullptr,
          INTERNET_OPTION_SETTINGS_CHANGED,
          nullptr,
          0,
        );
        InternetSetOption(
          nullptr,
          INTERNET_OPTION_REFRESH,
          nullptr,
          0,
        );

        Logger.d('系统代理设置成功: $proxyServer');
        return true;
      } finally {
        RegCloseKey(phkResult.value);
        calloc.free(phkResult);
      }
    } catch (e) {
      Logger.e('设置系统代理异常: $e');
      return false;
    }
  }

  /// 清除系统代理
  static Future<bool> clearSystemProxy() async {
    try {
      final hKey = HKEY_CURRENT_USER;
      Pointer<HKEY> phkResult = calloc<HKEY>();
      
      var result = RegOpenKeyEx(
        hKey,
        _proxyKey.toNativeUtf16(),
        0,
        KEY_WRITE,
        phkResult,
      );

      if (result != ERROR_SUCCESS) {
        Logger.e('打开注册表失败: $result');
        calloc.free(phkResult);
        return false;
      }

      try {
        // 禁用代理
        final enableValue = calloc<DWORD>();
        enableValue.value = 0;
        result = RegSetValueEx(
          phkResult.value,
          _enableKey.toNativeUtf16(),
          0,
          REG_DWORD,
          enableValue.cast(),
          sizeOf<DWORD>(),
        );

        calloc.free(enableValue);

        if (result != ERROR_SUCCESS) {
          Logger.e('禁用代理失败: $result');
          return false;
        }

        // 通知系统代理设置已更改
        InternetSetOption(
          nullptr,
          INTERNET_OPTION_SETTINGS_CHANGED,
          nullptr,
          0,
        );
        InternetSetOption(
          nullptr,
          INTERNET_OPTION_REFRESH,
          nullptr,
          0,
        );

        Logger.d('系统代理已清除');
        return true;
      } finally {
        RegCloseKey(phkResult.value);
        calloc.free(phkResult);
      }
    } catch (e) {
      Logger.e('清除系统代理异常: $e');
      return false;
    }
  }

  /// 获取当前系统代理设置
  static Future<Map<String, dynamic>?> getSystemProxy() async {
    try {
      final hKey = HKEY_CURRENT_USER;
      Pointer<HKEY> phkResult = calloc<HKEY>();
      
      var result = RegOpenKeyEx(
        hKey,
        _proxyKey.toNativeUtf16(),
        0,
        KEY_READ,
        phkResult,
      );

      if (result != ERROR_SUCCESS) {
        calloc.free(phkResult);
        return null;
      }

      try {
        final resultMap = <String, dynamic>{};

        // 读取代理启用状态
        final enableValue = calloc<DWORD>();
        final enableSize = calloc<DWORD>();
        enableSize.value = sizeOf<DWORD>();

        result = RegQueryValueEx(
          phkResult.value,
          _enableKey.toNativeUtf16(),
          nullptr,
          nullptr,
          enableValue.cast(),
          enableSize,
        );

        if (result == ERROR_SUCCESS) {
          resultMap['enabled'] = enableValue.value == 1;
        }

        calloc.free(enableValue);
        calloc.free(enableSize);

        // 读取代理服务器
        final serverSize = calloc<DWORD>();
        serverSize.value = 1024;
        final serverBuffer = calloc<Uint16>(1024);

        result = RegQueryValueEx(
          phkResult.value,
          _serverKey.toNativeUtf16(),
          nullptr,
          nullptr,
          serverBuffer.cast(),
          serverSize,
        );

        if (result == ERROR_SUCCESS) {
          resultMap['server'] = serverBuffer.toDartString();
        }

        calloc.free(serverBuffer);
        calloc.free(serverSize);

        return resultMap;
      } finally {
        RegCloseKey(phkResult.value);
        calloc.free(phkResult);
      }
    } catch (e) {
      Logger.e('获取系统代理异常: $e');
      return null;
    }
  }
}

