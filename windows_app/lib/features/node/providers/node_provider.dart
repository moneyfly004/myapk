import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/memory_cache.dart';
import '../../../core/utils/performance_monitor.dart';
import '../../../core/config/database.dart';

// 节点模型
class Node {
  final String id;
  final String name;
  final String type;
  final String server;
  final int port;
  final int? ping;
  final bool isSelected;
  final Map<String, dynamic>? config;

  const Node({
    required this.id,
    required this.name,
    required this.type,
    required this.server,
    required this.port,
    this.ping,
    this.isSelected = false,
    this.config,
  });

  Node copyWith({
    String? id,
    String? name,
    String? type,
    String? server,
    int? port,
    int? ping,
    bool? isSelected,
    Map<String, dynamic>? config,
  }) {
    return Node(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      server: server ?? this.server,
      port: port ?? this.port,
      ping: ping ?? this.ping,
      isSelected: isSelected ?? this.isSelected,
      config: config ?? this.config,
    );
  }

  // 从数据库 Map 创建
  factory Node.fromMap(Map<String, dynamic> map) {
    return Node(
      id: map['id'].toString(),
      name: map['name'] as String,
      type: map['type'] as String,
      server: map['server'] as String,
      port: map['port'] as int,
      ping: map['ping'] as int?,
      isSelected: (map['is_selected'] as int?) == 1,
    );
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(id),
      'name': name,
      'type': type,
      'server': server,
      'port': port,
      'ping': ping,
      'is_selected': isSelected ? 1 : 0,
      'config': config?.toString(),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

// 节点列表状态
class NodeListState {
  final List<Node> nodes;
  final String? selectedNodeId;
  final bool isLoading;
  final String? error;

  const NodeListState({
    this.nodes = const [],
    this.selectedNodeId,
    this.isLoading = false,
    this.error,
  });

  NodeListState copyWith({
    List<Node>? nodes,
    String? selectedNodeId,
    bool? isLoading,
    String? error,
  }) {
    return NodeListState(
      nodes: nodes ?? this.nodes,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 节点列表提供者
final nodeListProvider = StateNotifierProvider<NodeListNotifier, NodeListState>(
  (ref) => NodeListNotifier(),
);

class NodeListNotifier extends StateNotifier<NodeListState> {
  final _cache = AppCache().nodeListCache;
  final _db = AppDatabase();

  NodeListNotifier() : super(const NodeListState()) {
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // 检查缓存
      const cacheKey = 'nodes_all';
      final cached = _cache.get(cacheKey);
      
      if (cached != null) {
        final nodes = (cached as List).map((e) => Node.fromMap(e as Map<String, dynamic>)).toList();
        state = state.copyWith(
          nodes: nodes,
          selectedNodeId: nodes.isNotEmpty 
              ? nodes.firstWhere((n) => n.isSelected, orElse: () => nodes.first).id
              : null,
          isLoading: false,
        );
        return;
      }

      // 从数据库加载
      final dbNodes = await _db.queryNodes(
        orderBy: 'ping ASC, created_at DESC',
      );

      if (dbNodes.isEmpty) {
        // 如果没有数据，使用模拟数据
        await _loadMockNodes();
        return;
      }

      final nodes = dbNodes.map((map) => Node.fromMap(map)).toList();
      
      // 缓存结果
      _cache.put(cacheKey, dbNodes);
      
      state = state.copyWith(
        nodes: nodes,
        selectedNodeId: nodes.isNotEmpty 
            ? nodes.firstWhere((n) => n.isSelected, orElse: () => nodes.first).id
            : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadMockNodes() async {
    // 模拟数据
    final nodes = [
      const Node(
        id: 'auto',
        name: '自动选择 (Auto)',
        type: 'auto',
        server: 'auto',
        port: 0,
        ping: 50,
        isSelected: true,
      ),
      const Node(
        id: 'node1',
        name: '节点 1 - 香港',
        type: 'vmess',
        server: 'hk.example.com',
        port: 443,
        ping: 50,
      ),
      const Node(
        id: 'node2',
        name: '节点 2 - 日本',
        type: 'trojan',
        server: 'jp.example.com',
        port: 443,
        ping: 80,
      ),
      const Node(
        id: 'node3',
        name: '节点 3 - 美国',
        type: 'shadowsocks',
        server: 'us.example.com',
        port: 8388,
        ping: 120,
      ),
    ];
    
    state = state.copyWith(
      nodes: nodes,
      selectedNodeId: 'auto',
      isLoading: false,
    );
  }

  void selectNode(String nodeId) {
    final updatedNodes = state.nodes.map((node) {
      return node.copyWith(isSelected: node.id == nodeId);
    }).toList();
    
    state = state.copyWith(
      nodes: updatedNodes,
      selectedNodeId: nodeId,
    );

    // 更新数据库
    _updateNodeSelection(nodeId);
  }

  Future<void> _updateNodeSelection(String nodeId) async {
    try {
      await _db.transaction((txn) async {
        // 清除所有选中状态
        await txn.update('nodes', {'is_selected': 0});
        // 设置新的选中状态
        await txn.update('nodes', {'is_selected': 1}, where: 'id = ?', whereArgs: [nodeId]);
      });
      
      // 清除缓存
      _cache.clear();
    } catch (e) {
      // 静默失败，不影响 UI
    }
  }

  Future<void> testNodePing(String nodeId) async {
    await measurePerformance('test_node_ping', () async {
      // TODO: 实现节点测速
      final updatedNodes = state.nodes.map((node) {
        if (node.id == nodeId) {
          // 模拟测速结果
          final newPing = (node.ping ?? 100) + (DateTime.now().millisecond % 50 - 25);
          return node.copyWith(ping: newPing);
        }
        return node;
      }).toList();
      
      state = state.copyWith(nodes: updatedNodes);
    });
  }

  Future<void> testAllNodes() async {
    await measurePerformance('test_all_nodes', () async {
      for (final node in state.nodes) {
        await testNodePing(node.id);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    });
  }

  // 添加节点
  Future<void> addNode(Node node) async {
    try {
      await _db.transaction((txn) async {
        await txn.insert('nodes', node.toMap());
      });
      
      // 清除缓存并重新加载
      _cache.clear();
      await _loadNodes();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 删除节点
  Future<void> deleteNode(String nodeId) async {
    try {
      await _db.transaction((txn) async {
        await txn.delete('nodes', where: 'id = ?', whereArgs: [nodeId]);
      });
      
      // 清除缓存并重新加载
      _cache.clear();
      await _loadNodes();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
