import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../core/config/database.dart';
import '../../auth/repositories/auth_repository.dart';
import 'subscription_parser.dart';
import '../../group/providers/group_provider.dart';
import '../../group/models/group_model.dart';
import '../../node/providers/node_provider.dart';

class SubscriptionService {
  static const String _subscriptionUrlKey = 'subscription_url';
  static const String _hasSubscriptionKey = 'has_subscription';

  final AuthRepository _authRepository;
  final Ref _ref;

  SubscriptionService(this._authRepository, this._ref);

  // 获取基础订阅 URL（去掉时间戳参数）
  String getBaseSubscriptionUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final scheme = uri.scheme;
      final authority = uri.authority;
      final path = uri.path;
      final baseUrl = '$scheme://$authority$path';
      
      // 过滤掉时间戳参数
      final queryParams = uri.queryParameters.entries
          .where((entry) => 
              entry.key != 't' && 
              entry.key != 'timestamp' && 
              entry.key != 'time')
          .map((entry) => '${entry.key}=${entry.value}')
          .toList();
      
      if (queryParams.isNotEmpty) {
        return '$baseUrl?${queryParams.join('&')}';
      }
      return baseUrl;
    } catch (e) {
      Logger.error('解析订阅 URL 失败: $e');
      // 简单处理：去掉 ?t= 或 &t= 后面的部分
      return url.split('?').first.split('&t=').first;
    }
  }

  // 检查并自动添加订阅
  Future<void> checkAndAddSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSubscription = prefs.getBool(_hasSubscriptionKey) ?? false;
      final subscriptionUrl = prefs.getString(_subscriptionUrlKey);

      if (!hasSubscription || subscriptionUrl == null || subscriptionUrl.isEmpty) {
        Logger.debug('没有订阅信息，跳过自动添加');
        return;
      }

      Logger.debug('开始自动添加订阅: $subscriptionUrl');

      // 获取基础 URL（用于查找现有订阅）
      final baseUrl = getBaseSubscriptionUrl(subscriptionUrl);

      // 解析订阅并导入节点
      try {
        final nodes = await SubscriptionParser.parseSubscription(subscriptionUrl);
        
        if (nodes.isNotEmpty) {
          // 查找或创建订阅分组
          final groupNotifier = _ref.read(groupListProvider.notifier);
          final nodeNotifier = _ref.read(nodeListProvider.notifier);
          
          ProxyGroup? subscriptionGroup;
          try {
            subscriptionGroup = groupNotifier.state.groups.firstWhere(
              (g) => g.type == GroupType.subscription && 
                     getBaseSubscriptionUrl(g.subscriptionUrl ?? '') == baseUrl,
            );
          } catch (e) {
            // 未找到现有分组，将创建新分组
            subscriptionGroup = null;
          }
          
          if (subscriptionGroup == null) {
            // 创建新分组
            final newGroupId = await groupNotifier.createGroup(
              name: '订阅: ${Uri.parse(baseUrl).host}',
              type: GroupType.subscription,
              subscriptionUrl: subscriptionUrl,
            );
            // 重新加载以获取新分组的完整信息
            await groupNotifier.loadGroups();
            subscriptionGroup = groupNotifier.state.groups.firstWhere(
              (g) => g.id == newGroupId,
            );
          } else {
            // 更新现有分组的订阅 URL
            final updatedGroup = subscriptionGroup.copyWith(
              subscriptionUrl: subscriptionUrl,
            );
            await groupNotifier.updateGroup(updatedGroup);
          }
          
          // 删除旧节点（通过数据库查询该分组下的所有节点）
          final db = AppDatabase();
          final oldNodes = await db.queryNodes(where: 'group_id = ?', whereArgs: [subscriptionGroup!.id]);
          for (final oldNodeMap in oldNodes) {
            final oldNodeId = oldNodeMap['id'] as int;
            await db.deleteNode(oldNodeId);
          }
          
          // 添加新节点
          final now = DateTime.now().millisecondsSinceEpoch;
          for (final node in nodes) {
            final nodeMap = node.toMap();
            nodeMap['group_id'] = subscriptionGroup!.id;
            nodeMap['created_at'] = now;
            nodeMap['updated_at'] = now;
            await db.insertNode(nodeMap);
          }
          
          // 节点列表会在下次访问时自动重新加载（通过清除缓存触发）
          
          Logger.debug('成功解析并导入 ${nodes.length} 个节点到分组: ${subscriptionGroup.name}');
        }
      } catch (e) {
        Logger.error('解析订阅失败: $e');
      }

      Logger.debug('订阅自动添加完成');
    } catch (e) {
      Logger.error('自动添加订阅失败: $e');
    }
  }

  // 更新订阅
  Future<void> updateSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSubscription = prefs.getBool(_hasSubscriptionKey) ?? false;
      
      if (!hasSubscription) {
        Logger.debug('没有订阅信息，跳过更新');
        return;
      }

      // 从服务器获取最新订阅信息
      final result = await _authRepository.getUserSubscription();
      
      result.when(
        success: (subscription) {
          Logger.debug('订阅更新成功');
          // 订阅信息已保存在 AuthRepository 中
        },
        failure: (error) {
          Logger.error('订阅更新失败: $error');
        },
      );
    } catch (e) {
      Logger.error('更新订阅异常: $e');
    }
  }
}

