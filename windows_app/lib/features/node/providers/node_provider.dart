import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../core/cache/memory_cache.dart';
import '../../../core/utils/performance_monitor.dart';
import '../../../core/config/database.dart';
import '../services/url_test_service.dart';

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
      config: map['config'] != null ? _parseConfig(map['config'] as String) : null,
    );
  }

  // 解析配置字符串
  static Map<String, dynamic>? _parseConfig(String configStr) {
    try {
      // 如果配置是 JSON 字符串，尝试解析
      if (configStr.startsWith('{')) {
        return jsonDecode(configStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': int.tryParse(id),
      'group_id': 0, // 默认分组
      'name': name,
      'type': type,
      'server': server,
      'port': port,
      'ping': ping,
      'is_selected': isSelected ? 1 : 0,
      'status': 0, // 0=未测试, 1=可用, 2=不可用
      'config': config != null ? jsonEncode(config) : null,
      'user_order': 0,
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
  final bool autoSelectEnabled;

  const NodeListState({
    this.nodes = const [],
    this.selectedNodeId,
    this.isLoading = false,
    this.error,
    this.autoSelectEnabled = false,
  });

  NodeListState copyWith({
    List<Node>? nodes,
    String? selectedNodeId,
    bool? isLoading,
    String? error,
    bool? autoSelectEnabled,
  }) {
    return NodeListState(
      nodes: nodes ?? this.nodes,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      autoSelectEnabled: autoSelectEnabled ?? this.autoSelectEnabled,
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
      final node = state.nodes.firstWhere(
        (n) => n.id == nodeId,
        orElse: () => state.nodes.first,
      );

      if (node.id == 'auto' || node.type == 'auto') {
        return; // 跳过自动选择节点
      }

      // 使用 URL 测试服务
      final urlTestService = UrlTestService();
      final ping = await urlTestService.testNodePing(node);

      if (ping != null) {
        final updatedNodes = state.nodes.map((n) {
          if (n.id == nodeId) {
            return n.copyWith(ping: ping);
          }
          return n;
        }).toList();

        // 按延迟排序
        updatedNodes.sort((a, b) {
          final aPing = a.ping ?? 9999;
          final bPing = b.ping ?? 9999;
          return aPing.compareTo(bPing);
        });

        state = state.copyWith(nodes: updatedNodes);
      }
    });
  }

  Future<void> testAllNodes() async {
    await measurePerformance('test_all_nodes', () async {
      final urlTestService = UrlTestService();
      
      // 并发测试所有节点（不等待全部完成）
      final testFutures = state.nodes.map((node) async {
        if (node.id == 'auto' || node.type == 'auto') {
          return; // 跳过自动选择节点
        }

        final ping = await urlTestService.testNodePing(node);
        if (ping != null) {
          // 立即更新并排序
          final updatedNodes = state.nodes.map((n) {
            if (n.id == node.id) {
              return n.copyWith(ping: ping);
            }
            return n;
          }).toList();

          // 按延迟排序（延迟低的在前）
          updatedNodes.sort((a, b) {
            // 自动选择节点始终在最前面
            if (a.id == 'auto' || a.type == 'auto') return -1;
            if (b.id == 'auto' || b.type == 'auto') return 1;
            
            final aPing = a.ping ?? 9999;
            final bPing = b.ping ?? 9999;
            return aPing.compareTo(bPing);
          });

          state = state.copyWith(nodes: updatedNodes);

          // 如果启用自动选择，选择延迟最低的节点
          if (state.autoSelectEnabled && updatedNodes.isNotEmpty) {
            final bestNode = updatedNodes.firstWhere(
              (n) => n.id != 'auto' && n.type != 'auto' && n.ping != null,
              orElse: () => updatedNodes.first,
            );
            if (bestNode.id != state.selectedNodeId) {
              selectNode(bestNode.id);
            }
          }
        }
      });

      // 不等待所有测试完成，让它们并发执行
      await Future.wait(testFutures, eagerError: false);
    });
  }

  // 自动 URL 测试（登录后或展开节点列表时调用）
  Future<void> autoUrlTest() async {
    if (state.nodes.isEmpty) return;
    
    // 自动选择最优节点
    state = state.copyWith(autoSelectEnabled: true);
    
    // 开始测试所有节点
    await testAllNodes();
  }

  // 添加节点
  Future<void> addNode(Node node, {int groupId = 0}) async {
    try {
      final nodeMap = node.toMap();
      nodeMap['group_id'] = groupId;
            // 清除缓存并重新加载
      _cache.clear();
      await _loadNodes();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 批量添加节点
  Future<void> addNodes(List<Node> nodes, {int groupId = 0}) async {
    try {
      final nodeMaps = nodes.map((node) {
        final map = node.toMap();
        map['group_id'] = groupId;
        return map;
      }).toList();
      
      await _db.batchInsertNodes(nodeMaps);
      
      // 清除缓存并重新加载
      _cache.clear();
      await _loadNodes();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 更新节点
  Future<void> updateNode(Node node) async {
    try {
      final nodeId = int.tryParse(node.id);
      if (nodeId == null) return;
      
      final nodeMap = node.toMap();
      await _db.updateNode(nodeId, nodeMap);
      
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
      final id = int.tryParse(nodeId);
      if (id == null) return;
      
      await _db.deleteNode(id);
      
      // 清除缓存并重新加载
      _cache.clear();
      await _loadNodes();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
