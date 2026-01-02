import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';
import '../../auth/repositories/auth_repository.dart';
import 'subscription_parser.dart';

class SubscriptionService {
  static const String _subscriptionUrlKey = 'subscription_url';
  static const String _hasSubscriptionKey = 'has_subscription';

  final AuthRepository _authRepository;

  SubscriptionService(this._authRepository);

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
      Logger.e('解析订阅 URL 失败: $e');
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
        Logger.d('没有订阅信息，跳过自动添加');
        return;
      }

      Logger.d('开始自动添加订阅: $subscriptionUrl');

      // 获取基础 URL
      final baseUrl = getBaseSubscriptionUrl(subscriptionUrl);

      // 解析订阅并导入节点
      try {
        final nodes = await SubscriptionParser.parseSubscription(subscriptionUrl);
        
        if (nodes.isNotEmpty) {
          // TODO: 通过 provider 添加节点
          // 这里需要访问 nodeListProvider，但由于是静态方法，暂时只记录日志
          Logger.d('成功解析 ${nodes.length} 个节点，需要添加到节点列表');
        }
      } catch (e) {
        Logger.e('解析订阅失败: $e');
      }

      Logger.d('订阅自动添加完成');
    } catch (e) {
      Logger.e('自动添加订阅失败: $e');
    }
  }

  // 更新订阅
  Future<void> updateSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSubscription = prefs.getBool(_hasSubscriptionKey) ?? false;
      
      if (!hasSubscription) {
        Logger.d('没有订阅信息，跳过更新');
        return;
      }

      // 从服务器获取最新订阅信息
      final result = await _authRepository.getUserSubscription();
      
      result.when(
        success: (subscription) {
          Logger.d('订阅更新成功');
          // 订阅信息已保存在 AuthRepository 中
        },
        failure: (error) {
          Logger.e('订阅更新失败: $error');
        },
      );
    } catch (e) {
      Logger.e('更新订阅异常: $e');
    }
  }
}

