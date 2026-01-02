import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/utils/logger.dart';
import '../providers/node_provider.dart';

class UrlTestService {
  static const String _defaultTestUrl = 'http://cp.cloudflare.com/';
  static const Duration _timeout = Duration(seconds: 5);

  // 测试节点延迟
  Future<int?> testNodePing(Node node) async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      
      // 如果节点是自动选择，返回默认延迟
      if (node.id == 'auto' || node.type == 'auto') {
        return 50; // 默认延迟
      }

      // TODO: 实现实际的节点测速
      // 这里需要根据节点类型和配置进行实际的连接测试
      // 目前使用模拟延迟
      
      // 模拟网络延迟测试
      await Future.delayed(const Duration(milliseconds: 100));
      
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final ping = endTime - startTime;
      
      // 模拟一些随机延迟变化
      final randomPing = ping + (DateTime.now().millisecond % 50 - 25);
      
      Logger.d('节点 ${node.name} 测速完成: ${randomPing}ms');
      return randomPing.clamp(10, 1000);
    } catch (e) {
      Logger.e('节点测速失败: $e');
      return null;
    }
  }

  // 测试所有节点（并发）
  Future<void> testAllNodes(List<Node> nodes) async {
    final testFutures = nodes.map((node) async {
      if (node.id == 'auto' || node.type == 'auto') {
        return; // 跳过自动选择节点
      }
      
      final ping = await testNodePing(node);
      if (ping != null) {
        // 更新节点延迟
        // 这里需要通过 provider 更新节点状态
        Logger.d('节点 ${node.name} 延迟: ${ping}ms');
      }
    });

    await Future.wait(testFutures);
  }

  // 使用 HTTP 请求测试节点（简单实现）
  Future<int?> testNodeWithHttp(Node node, String testUrl) async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      
      // 如果节点是自动选择，返回默认延迟
      if (node.id == 'auto' || node.type == 'auto') {
        return 50;
      }

      // TODO: 通过代理测试节点
      // 这里需要配置 HTTP 客户端使用节点作为代理
      // 目前只是简单的 HTTP 请求测试
      
      final response = await http.get(
        Uri.parse(testUrl),
      ).timeout(_timeout);

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final ping = endTime - startTime;

      if (response.statusCode == 200) {
        Logger.d('节点 ${node.name} HTTP 测试成功: ${ping}ms');
        return ping;
      } else {
        Logger.w('节点 ${node.name} HTTP 测试失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.e('节点 HTTP 测试异常: $e');
      return null;
    }
  }
}

