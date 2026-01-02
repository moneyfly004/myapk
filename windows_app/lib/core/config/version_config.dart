import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

/// 版本配置管理
/// 参考 Android 端的版本管理方式
class VersionConfig {
  static VersionConfig? _instance;
  static VersionConfig get instance => _instance ??= VersionConfig._();
  
  VersionConfig._();
  
  PackageInfo? _packageInfo;
  String? _versionName;
  int? _versionCode;
  String? _packageName;
  
  /// 初始化版本信息
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _versionName = _packageInfo?.version;
      _versionCode = int.tryParse(_packageInfo?.buildNumber ?? '1');
      _packageName = _packageInfo?.packageName;
    } catch (e) {
      // 如果无法获取，使用默认值
      _versionName = '1.0.0';
      _versionCode = 1;
      _packageName = 'io.nekohasekai.sagernet.windows';
    }
  }
  
  /// 版本名称（显示给用户）
  String get versionName => _versionName ?? '1.0.0';
  
  /// 版本代码（内部版本号）
  int get versionCode => _versionCode ?? 1;
  
  /// 包名
  String get packageName => _packageName ?? 'io.nekohasekai.sagernet.windows';
  
  /// 完整版本信息（用于显示）
  String get versionNameForDisplay {
    final preVersion = _getPreVersion();
    if (preVersion != null && preVersion.isNotEmpty) {
      return '$versionName pre-$preVersion';
    }
    return versionName;
  }
  
  /// 获取预览版本名称
  String? _getPreVersion() {
    // 从环境变量或配置文件读取
    return Platform.environment['PRE_VERSION_NAME'];
  }
  
  /// 检查是否为预览版本
  bool get isPreviewVersion {
    final preVersion = _getPreVersion();
    return preVersion != null && preVersion.isNotEmpty;
  }
  
  /// GitHub 仓库信息
  static const String githubRepo = 'moneyfly004/myapk';
  static const String githubReleasesUrl = 'https://api.github.com/repos/moneyfly004/myapk/releases';
  
  /// 获取版本信息字符串（用于日志等）
  String getVersionInfo() {
    return 'NekoBox for Windows $versionNameForDisplay ($versionCode)';
  }
}

