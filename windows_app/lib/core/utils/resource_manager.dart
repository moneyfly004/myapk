import 'dart:async';

/// 资源管理器（优化资源加载和内存管理）
class ResourceManager {
  static final ResourceManager _instance = ResourceManager._internal();
  factory ResourceManager() => _instance;
  ResourceManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheTTL = const Duration(minutes: 30);

  /// 预加载资源
  Future<void> preloadResources(List<String> paths) async {
    for (final path in paths) {
      try {
        await loadResource(path);
      } catch (e) {
        // 静默失败，继续加载其他资源
      }
    }
  }

  /// 加载资源
  Future<dynamic> loadResource(String path) async {
    // 检查缓存
    if (_cache.containsKey(path)) {
      final timestamp = _cacheTimestamps[path];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheTTL) {
        return _cache[path];
      }
    }

    // 加载资源
    final resource = await _doLoadResource(path);
    
    // 缓存资源
    _cache[path] = resource;
    _cacheTimestamps[path] = DateTime.now();

    return resource;
  }

  Future<dynamic> _doLoadResource(String path) async {
    // 根据路径类型加载资源
    if (path.endsWith('.json')) {
      // 加载 JSON
      // return await rootBundle.loadString(path);
    } else if (path.endsWith('.png') || path.endsWith('.jpg')) {
      // 加载图片
      // return await rootBundle.load(path);
    }
    
    throw Exception('不支持的资源类型: $path');
  }

  /// 清理过期缓存
  void evictExpiredCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheTTL) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// 清理所有缓存
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// 获取缓存大小
  int get cacheSize => _cache.length;
}

