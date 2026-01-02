import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../cache/memory_cache.dart';
import '../utils/performance_monitor.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;
  static final _cache = MemoryCache<String, dynamic>(
    maxSize: 100,
    ttl: const Duration(minutes: 5),
  );

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await measurePerformanceSync('database_init', () async {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'nekobox.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }) as Future<Database>;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        token TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE nodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        server TEXT NOT NULL,
        port INTEGER NOT NULL,
        config TEXT,
        ping INTEGER,
        is_selected INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        last_update INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建索引以优化查询性能
    await db.execute('CREATE INDEX idx_nodes_type ON nodes(type)');
    await db.execute('CREATE INDEX idx_nodes_selected ON nodes(is_selected)');
    await db.execute('CREATE INDEX idx_subscriptions_url ON subscriptions(url)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
  }

  // 优化的查询方法（带缓存）
  Future<List<Map<String, dynamic>>> queryNodes({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final cacheKey = 'nodes_${where}_${orderBy}_$limit';
    
    // 检查缓存
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached as List<Map<String, dynamic>>;
    }

    final db = await database;
    final result = await measurePerformance('query_nodes', () async {
      return await db.query(
        'nodes',
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
    });

    // 缓存结果
    _cache.put(cacheKey, result);
    return result;
  }

  // 批量插入（性能优化）
  Future<void> batchInsertNodes(List<Map<String, dynamic>> nodes) async {
    final db = await database;
    final batch = db.batch();

    for (final node in nodes) {
      batch.insert('nodes', node);
    }

    await measurePerformance('batch_insert_nodes', () async {
      await batch.commit(noResult: true);
    });

    // 清除相关缓存
    _cache.clear();
  }

  // 事务执行（性能优化）
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return await measurePerformance('database_transaction', () async {
      return await db.transaction(action);
    });
  }

  // 关闭数据库
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _cache.clear();
  }
}
