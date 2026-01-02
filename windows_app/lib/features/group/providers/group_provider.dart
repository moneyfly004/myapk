import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/database.dart';
import '../../../core/utils/performance_monitor.dart';
import '../models/group_model.dart';

// 分组列表状态
class GroupListState {
  final List<ProxyGroup> groups;
  final bool isLoading;
  final String? error;

  const GroupListState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupListState copyWith({
    List<ProxyGroup>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 分组列表提供者
final groupListProvider = StateNotifierProvider<GroupListNotifier, GroupListState>(
  (ref) => GroupListNotifier(),
);

class GroupListNotifier extends StateNotifier<GroupListState> {
  final _db = AppDatabase();

  GroupListNotifier() : super(const GroupListState()) {
    loadGroups();
  }

  // 加载所有分组
  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final groupsData = await _db.queryGroups(orderBy: 'user_order ASC');
      final groups = groupsData.map((map) => ProxyGroup.fromMap(map)).toList();
      
      state = state.copyWith(
        groups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 创建分组
  Future<int> createGroup({
    String? name,
    int type = GroupType.basic,
    String? subscriptionUrl,
    String? subscriptionName,
    bool ungrouped = false,
  }) async {
    try {
      final now = DateTime.now();
      final groupMap = {
        'name': name,
        'type': type,
        'subscription_url': subscriptionUrl,
        'subscription_name': subscriptionName,
        'ungrouped': ungrouped ? 1 : 0,
        'order_type': GroupOrder.origin,
        'is_selector': 0,
        'front_proxy': -1,
        'landing_proxy': -1,
      };
      
      final id = await _db.insertGroup(groupMap);
      await loadGroups();
      return id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  // 更新分组
  Future<bool> updateGroup(ProxyGroup group) async {
    try {
      final groupMap = group.toMap();
      groupMap.remove('id'); // 移除 id，因为 update 不需要
      groupMap.remove('created_at'); // 保留创建时间
      
      await _db.updateGroup(group.id, groupMap);
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // 删除分组
  Future<bool> deleteGroup(int id) async {
    try {
      await _db.deleteGroup(id);
      await loadGroups();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // 获取分组
  Future<ProxyGroup?> getGroup(int id) async {
    try {
      final groupData = await _db.getGroup(id);
      return groupData != null ? ProxyGroup.fromMap(groupData) : null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // 更新分组排序
  Future<void> updateGroupOrders(List<ProxyGroup> groups) async {
    try {
      final orders = groups.asMap().entries.map((entry) {
        return {
          'id': entry.value.id,
          'order': entry.key + 1,
        };
      }).toList();
      
      await _db.updateGroupOrders(orders);
      await loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

