import 'dart:collection';

/// 内存缓存管理器
class MemoryCache<K, V> {
  final int maxSize;
  final Duration? ttl;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  MemoryCache({
    this.maxSize = 100,
    this.ttl,
  });

  /// 获取缓存值
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // 检查是否过期
    if (ttl != null && entry.expiresAt != null) {
      if (DateTime.now().isAfter(entry.expiresAt!)) {
        _cache.remove(key);
        return null;
      }
    }

    // 移动到末尾（LRU）
    _cache.remove(key);
    _cache[key] = entry;

    return entry.value;
  }

  /// 设置缓存值
  void put(K key, V value) {
    // 如果已存在，先移除
    _cache.remove(key);

    // 检查容量
    if (_cache.length >= maxSize && _cache.isNotEmpty) {
      // 移除最旧的项（LRU）
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }

    // 添加新项
    final expiresAt = ttl != null
        ? DateTime.now().add(ttl!)
        : null;

    _cache[key] = _CacheEntry(value, expiresAt);
  }

  /// 移除缓存
  void remove(K key) {
    _cache.remove(key);
  }

  /// 清空缓存
  void clear() {
    _cache.clear();
  }

  /// 获取缓存大小
  int get size => _cache.length;

  /// 检查是否包含key
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    // 检查是否过期
    if (ttl != null && entry.expiresAt != null) {
      if (DateTime.now().isAfter(entry.expiresAt!)) {
        _cache.remove(key);
        return false;
      }
    }

    return true;
  }

  /// 清理过期项
  void evictExpired() {
    if (ttl == null) return;

    final now = DateTime.now();
    final keysToRemove = <K>[];

    _cache.forEach((key, entry) {
      if (entry.expiresAt != null && now.isAfter(entry.expiresAt!)) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime? expiresAt;

  _CacheEntry(this.value, this.expiresAt);
}

/// 全局缓存实例
class AppCache {
  static final AppCache _instance = AppCache._internal();
  factory AppCache() => _instance;
  AppCache._internal();

  // 节点列表缓存（5分钟TTL）
  final nodeListCache = MemoryCache<String, dynamic>(
    maxSize: 50,
    ttl: const Duration(minutes: 5),
  );

  // 用户信息缓存（10分钟TTL）
  final userInfoCache = MemoryCache<String, dynamic>(
    maxSize: 10,
    ttl: const Duration(minutes: 10),
  );

  // 配置缓存（30分钟TTL）
  final configCache = MemoryCache<String, dynamic>(
    maxSize: 20,
    ttl: const Duration(minutes: 30),
  );

  // 清理所有过期缓存
  void evictExpired() {
    nodeListCache.evictExpired();
    userInfoCache.evictExpired();
    configCache.evictExpired();
  }

  // 清空所有缓存
  void clearAll() {
    nodeListCache.clear();
    userInfoCache.clear();
    configCache.clear();
  }
}

