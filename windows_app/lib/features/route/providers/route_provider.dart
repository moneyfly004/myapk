import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/database.dart';

import '../models/rule_model.dart';

// 路由规则列表状态
class RuleListState {
  final List<RuleEntity> rules;
  final bool isLoading;
  final String? error;

  const RuleListState({
    this.rules = const [],
    this.isLoading = false,
    this.error,
  });

  RuleListState copyWith({
    List<RuleEntity>? rules,
    bool? isLoading,
    String? error,
  }) {
    return RuleListState(
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 路由规则列表提供者
final ruleListProvider = StateNotifierProvider<RuleListNotifier, RuleListState>(
  (ref) => RuleListNotifier(),
);

class RuleListNotifier extends StateNotifier<RuleListState> {
  final _db = AppDatabase();

  RuleListNotifier() : super(const RuleListState()) {
    loadRules();
  }

  // 加载所有路由规则
  Future<void> loadRules({bool enabledOnly = false}) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final rulesData = await _db.queryRules(
        where: enabledOnly ? 'enabled = 1' : null,
        orderBy: 'user_order ASC',
      );
      final rules = rulesData.map((map) => RuleEntity.fromMap(map)).toList();
      
      state = state.copyWith(
        rules: rules,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 创建路由规则
  Future<int> createRule({
    required String name,
    String config = '',
    String domains = '',
    String ip = '',
    String port = '',
    String sourcePort = '',
    String network = '',
    String source = '',
    String protocol = '',
    int outbound = 0,
    List<String> packages = const [],
    bool enabled = true,
  }) async {
    try {
      final ruleMap = {
        'name': name,
        'config': config,
        'domains': domains,
        'ip': ip,
        'port': port,
        'source_port': sourcePort,
        'network': network,
        'source': source,
        'protocol': protocol,
        'outbound': outbound,
        'packages': packages.join(','),
        'enabled': enabled ? 1 : 0,
      };
      
      final id = await _db.insertRule(ruleMap);
      await loadRules();
      return id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  // 更新路由规则
  Future<bool> updateRule(RuleEntity rule) async {
    try {
      final ruleMap = rule.toMap();
      ruleMap.remove('id'); // 移除 id
      ruleMap.remove('created_at'); // 保留创建时间
      
      await _db.updateRule(rule.id, ruleMap);
      await loadRules();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // 删除路由规则
  Future<bool> deleteRule(int id) async {
    try {
      await _db.deleteRule(id);
      await loadRules();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // 获取路由规则
  Future<RuleEntity?> getRule(int id) async {
    try {
      final ruleData = await _db.getRule(id);
      return ruleData != null ? RuleEntity.fromMap(ruleData) : null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // 更新规则排序
  Future<void> updateRuleOrders(List<RuleEntity> rules) async {
    try {
      final orders = rules.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'order': entry.key + 1,
        };
      }).toList();
      
      await _db.updateRuleOrders(orders);
      await loadRules();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // 切换规则启用状态
  Future<bool> toggleRule(int id, bool enabled) async {
    try {
      await _db.updateRule(id, {'enabled': enabled ? 1 : 0});
      await loadRules();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

