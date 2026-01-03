import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../cache/memory_cache.dart';
import '../utils/performance_monitor.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;
  static final _cache = MemoryCache<String, dynamic>(
    maxSize: 50, // 从 100 减少到 50，降低内存占用
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
        version: 2, // 升级到版本 2，添加分组和路由表
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

    // 分组表
    await db.execute('''
      CREATE TABLE proxy_groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_order INTEGER NOT NULL DEFAULT 0,
        ungrouped INTEGER NOT NULL DEFAULT 0,
        name TEXT,
        type INTEGER NOT NULL DEFAULT 0,
        subscription_url TEXT,
        subscription_name TEXT,
        subscription_info TEXT,
        order_type INTEGER NOT NULL DEFAULT 0,
        is_selector INTEGER NOT NULL DEFAULT 0,
        front_proxy INTEGER DEFAULT -1,
        landing_proxy INTEGER DEFAULT -1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 节点表（增加 group_id 字段）
    await db.execute('''
      CREATE TABLE nodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        server TEXT NOT NULL,
        port INTEGER NOT NULL,
        config TEXT,
        ping INTEGER,
        status INTEGER DEFAULT 0,
        error TEXT,
        user_order INTEGER NOT NULL DEFAULT 0,
        is_selected INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (group_id) REFERENCES proxy_groups(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        base_url TEXT NOT NULL,
        last_update INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 路由规则表
    await db.execute('''
      CREATE TABLE rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        config TEXT DEFAULT '',
        user_order INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 0,
        domains TEXT DEFAULT '',
        ip TEXT DEFAULT '',
        port TEXT DEFAULT '',
        source_port TEXT DEFAULT '',
        network TEXT DEFAULT '',
        source TEXT DEFAULT '',
        protocol TEXT DEFAULT '',
        outbound INTEGER DEFAULT 0,
        packages TEXT DEFAULT '',
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
    await db.execute('CREATE INDEX idx_groups_type ON proxy_groups(type)');
    await db.execute('CREATE INDEX idx_groups_order ON proxy_groups(user_order)');
    await db.execute('CREATE INDEX idx_nodes_group_id ON nodes(group_id)');
    await db.execute('CREATE INDEX idx_nodes_type ON nodes(type)');
    await db.execute('CREATE INDEX idx_nodes_selected ON nodes(is_selected)');
    await db.execute('CREATE INDEX idx_nodes_order ON nodes(user_order)');
    await db.execute('CREATE INDEX idx_subscriptions_url ON subscriptions(url)');
    await db.execute('CREATE INDEX idx_subscriptions_base_url ON subscriptions(base_url)');
    await db.execute('CREATE INDEX idx_rules_order ON rules(user_order)');
    await db.execute('CREATE INDEX idx_rules_enabled ON rules(enabled)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
    if (oldVersion < 2) {
      // 添加分组表和路由规则表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS proxy_groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_order INTEGER NOT NULL DEFAULT 0,
          ungrouped INTEGER NOT NULL DEFAULT 0,
          name TEXT,
          type INTEGER NOT NULL DEFAULT 0,
          subscription_url TEXT,
          subscription_name TEXT,
          subscription_info TEXT,
          order_type INTEGER NOT NULL DEFAULT 0,
          is_selector INTEGER NOT NULL DEFAULT 0,
          front_proxy INTEGER DEFAULT -1,
          landing_proxy INTEGER DEFAULT -1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          config TEXT DEFAULT '',
          user_order INTEGER NOT NULL DEFAULT 0,
          enabled INTEGER NOT NULL DEFAULT 0,
          domains TEXT DEFAULT '',
          ip TEXT DEFAULT '',
          port TEXT DEFAULT '',
          source_port TEXT DEFAULT '',
          network TEXT DEFAULT '',
          source TEXT DEFAULT '',
          protocol TEXT DEFAULT '',
          outbound INTEGER DEFAULT 0,
          packages TEXT DEFAULT '',
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      
      // 为现有节点表添加 group_id 字段
      try {
        await db.execute('ALTER TABLE nodes ADD COLUMN group_id INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE nodes ADD COLUMN user_order INTEGER NOT NULL DEFAULT 0');
        await db.execute('ALTER TABLE nodes ADD COLUMN status INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE nodes ADD COLUMN error TEXT');
      } catch (e) {
        // 如果字段已存在，忽略错误
      }
      
      // 为订阅表添加 base_url 字段
      try {
        await db.execute('ALTER TABLE subscriptions ADD COLUMN base_url TEXT NOT NULL DEFAULT ""');
      } catch (e) {
        // 如果字段已存在，忽略错误
      }
      
      // 创建索引
      await db.execute('CREATE INDEX IF NOT EXISTS idx_groups_type ON proxy_groups(type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_groups_order ON proxy_groups(user_order)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_nodes_group_id ON nodes(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_nodes_order ON nodes(user_order)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_subscriptions_base_url ON subscriptions(base_url)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_rules_order ON rules(user_order)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_rules_enabled ON rules(enabled)');
    }
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

  // 事务执行（性能优化）
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return await measurePerformance('database_transaction', () async {
      return await db.transaction(action);
    });
  }

  // ========== 分组操作 ==========
  
  // 查询所有分组
  Future<List<Map<String, dynamic>>> queryGroups({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final cacheKey = 'groups_${where ?? ''}_${orderBy ?? ''}';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached as List<Map<String, dynamic>>;
    }

    final db = await database;
    final result = await measurePerformance('query_groups', () async {
      return await db.query(
        'proxy_groups',
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy ?? 'user_order ASC',
      );
    });

    _cache.put(cacheKey, result);
    return result;
  }

  // 获取下一个排序值
  Future<int> getNextGroupOrder() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(user_order) + 1 as next_order FROM proxy_groups',
    );
    return (result.first['next_order'] as int?) ?? 1;
  }

  // 插入分组
  Future<int> insertGroup(Map<String, dynamic> group) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    group['created_at'] = now;
    group['updated_at'] = now;
    
    if (!group.containsKey('user_order')) {
      group['user_order'] = await getNextGroupOrder();
    }
    
    final id = await measurePerformance('insert_group', () async {
      return await db.insert('proxy_groups', group);
    });
    
    _cache.clear();
    return id;
  }

  // 更新分组
  Future<int> updateGroup(int id, Map<String, dynamic> group) async {
    final db = await database;
    group['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    
    final count = await measurePerformance('update_group', () async {
      return await db.update(
        'proxy_groups',
        group,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    
    _cache.clear();
    return count;
  }

  // 删除分组
  Future<int> deleteGroup(int id) async {
    final db = await database;
    final count = await measurePerformance('delete_group', () async {
      // 先删除该分组下的所有节点
      await db.delete('nodes', where: 'group_id = ?', whereArgs: [id]);
      // 然后删除分组
      return await db.delete('proxy_groups', where: 'id = ?', whereArgs: [id]);
    });
    
    _cache.clear();
    return count;
  }

  // 获取分组
  Future<Map<String, dynamic>?> getGroup(int id) async {
    final db = await database;
    final result = await db.query(
      'proxy_groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ========== 节点操作 ==========
  
  // 获取下一个节点排序值
  Future<int> getNextNodeOrder(int groupId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(user_order) + 1 as next_order FROM nodes WHERE group_id = ?',
      [groupId],
    );
    return (result.first['next_order'] as int?) ?? 1;
  }

  // 插入节点
  Future<int> insertNode(Map<String, dynamic> node) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    node['created_at'] = now;
    node['updated_at'] = now;
    
    final groupId = node['group_id'] as int? ?? 0;
    if (!node.containsKey('user_order')) {
      node['user_order'] = await getNextNodeOrder(groupId);
    }
    
    final id = await measurePerformance('insert_node', () async {
      return await db.insert('nodes', node);
    });
    
    _cache.clear();
    return id;
  }

  // 批量插入节点
  Future<void> batchInsertNodes(List<Map<String, dynamic>> nodes) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final node in nodes) {
      node['created_at'] = now;
      node['updated_at'] = now;
      final groupId = node['group_id'] as int? ?? 0;
      if (!node.containsKey('user_order')) {
        node['user_order'] = await getNextNodeOrder(groupId);
      }
      batch.insert('nodes', node);
    }

    await measurePerformance('batch_insert_nodes', () async {
      await batch.commit(noResult: true);
    });

    _cache.clear();
  }

  // 更新节点
  Future<int> updateNode(int id, Map<String, dynamic> node) async {
    final db = await database;
    node['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    
    final count = await measurePerformance('update_node', () async {
      return await db.update(
        'nodes',
        node,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    
    _cache.clear();
    return count;
  }

  // 删除节点
  Future<int> deleteNode(int id) async {
    final db = await database;
    final count = await measurePerformance('delete_node', () async {
      return await db.delete('nodes', where: 'id = ?', whereArgs: [id]);
    });
    
    _cache.clear();
    return count;
  }

  // 根据分组删除节点
  Future<int> deleteNodesByGroup(int groupId) async {
    final db = await database;
    final count = await measurePerformance('delete_nodes_by_group', () async {
      return await db.delete('nodes', where: 'group_id = ?', whereArgs: [groupId]);
    });
    
    _cache.clear();
    return count;
  }

  // 获取节点
  Future<Map<String, dynamic>?> getNode(int id) async {
    final db = await database;
    final result = await db.query(
      'nodes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // 根据分组查询节点
  Future<List<Map<String, dynamic>>> queryNodesByGroup(
    int groupId, {
    String? orderBy,
  }) async {
    return await queryNodes(
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: orderBy ?? 'ping ASC, user_order ASC',
    );
  }

  // ========== 路由规则操作 ==========
  
  // 查询所有路由规则
  Future<List<Map<String, dynamic>>> queryRules({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final cacheKey = 'rules_${where ?? ''}_${orderBy ?? ''}';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached as List<Map<String, dynamic>>;
    }

    final db = await database;
    final result = await measurePerformance('query_rules', () async {
      return await db.query(
        'rules',
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy ?? 'user_order ASC',
      );
    });

    _cache.put(cacheKey, result);
    return result;
  }

  // 获取下一个规则排序值
  Future<int> getNextRuleOrder() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(user_order) + 1 as next_order FROM rules',
    );
    return (result.first['next_order'] as int?) ?? 1;
  }

  // 插入路由规则
  Future<int> insertRule(Map<String, dynamic> rule) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    rule['created_at'] = now;
    rule['updated_at'] = now;
    
    if (!rule.containsKey('user_order')) {
      rule['user_order'] = await getNextRuleOrder();
    }
    
    final id = await measurePerformance('insert_rule', () async {
      return await db.insert('rules', rule);
    });
    
    _cache.clear();
    return id;
  }

  // 更新路由规则
  Future<int> updateRule(int id, Map<String, dynamic> rule) async {
    final db = await database;
    rule['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    
    final count = await measurePerformance('update_rule', () async {
      return await db.update(
        'rules',
        rule,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    
    _cache.clear();
    return count;
  }

  // 删除路由规则
  Future<int> deleteRule(int id) async {
    final db = await database;
    final count = await measurePerformance('delete_rule', () async {
      return await db.delete('rules', where: 'id = ?', whereArgs: [id]);
    });
    
    _cache.clear();
    return count;
  }

  // 获取路由规则
  Future<Map<String, dynamic>?> getRule(int id) async {
    final db = await database;
    final result = await db.query(
      'rules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // 批量更新规则排序
  Future<void> updateRuleOrders(List<Map<String, int>> orders) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final order in orders) {
      batch.update(
        'rules',
        {
          'user_order': order['order'],
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [order['id']],
      );
    }

    await measurePerformance('update_rule_orders', () async {
      await batch.commit(noResult: true);
    });

    _cache.clear();
  }

  // 批量更新节点排序
  Future<void> updateNodeOrders(List<Map<String, int>> orders) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final order in orders) {
      batch.update(
        'nodes',
        {
          'user_order': order['order'],
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [order['id']],
      );
    }

    await measurePerformance('update_node_orders', () async {
      await batch.commit(noResult: true);
    });

    _cache.clear();
  }

  // 批量更新分组排序
  Future<void> updateGroupOrders(List<Map<String, int>> orders) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final order in orders) {
      batch.update(
        'proxy_groups',
        {
          'user_order': order['order'],
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [order['id']],
      );
    }

    await measurePerformance('update_group_orders', () async {
      await batch.commit(noResult: true);
    });

    _cache.clear();
  }

  // 关闭数据库
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _cache.clear();
  }
}
