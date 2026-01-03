import 'dart:async';

import '../cache/memory_cache.dart';
import 'logger.dart';

/// 内存管理器（优化内存占用）
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// 初始化内存管理器
  void initialize() {
    if (_isInitialized) return;
    
    // 每 2 分钟清理一次过期缓存
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performCleanup();
    });
    
    // 每 10 分钟强制垃圾回收（仅调试模式）
    Timer.periodic(const Duration(minutes: 10), (_) {
      _forceGarbageCollection();
    });
    
    _isInitialized = true;
    Logger.info('内存管理器已初始化');
  }

  /// 执行清理
  void _performCleanup() {
    try {
      // 清理过期缓存
      AppCache().evictExpired();
      
      // 记录内存使用情况（仅调试模式）
      _logMemoryUsage();
    } catch (e) {
      Logger.error('清理缓存失败', e);
    }
  }

  /// 强制垃圾回收（仅 Windows，调试模式）
  void _forceGarbageCollection() {
    // Flutter 会自动进行垃圾回收，这里只是记录
    Logger.debug('执行内存清理检查');
  }

  /// 记录内存使用情况
  void _logMemoryUsage() {
    try {
      // 获取缓存大小
      final cache = AppCache();
      final nodeCacheSize = cache.nodeListCache.size;
      final userCacheSize = cache.userInfoCache.size;
      final configCacheSize = cache.configCache.size;
      
      Logger.debug(
        '缓存使用情况: 节点=$nodeCacheSize, 用户=$userCacheSize, 配置=$configCacheSize',
      );
    } catch (e) {
      // 静默失败
    }
  }

  /// 清理所有缓存
  void clearAllCache() {
    AppCache().clearAll();
    Logger.info('已清理所有缓存');
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    clearAllCache();
    _isInitialized = false;
    Logger.info('内存管理器已释放');
  }
}

