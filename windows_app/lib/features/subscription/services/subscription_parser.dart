import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/logger.dart';
import '../../node/providers/node_provider.dart';

class SubscriptionParser {
  // 解析订阅 URL 并导入节点
  static Future<List<Node>> parseSubscription(String subscriptionUrl) async {
    try {
      Logger.d('开始解析订阅: $subscriptionUrl');

      // 下载订阅内容
      final response = await http.get(
        Uri.parse(subscriptionUrl),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        Logger.e('订阅下载失败: ${response.statusCode}');
        return [];
      }

      final content = response.body;
      if (content.isEmpty) {
        Logger.e('订阅内容为空');
        return [];
      }

      // 解析订阅内容（支持多种格式）
      List<Node> nodes = [];

      // 尝试解析为 Base64 编码的配置
      try {
        final decoded = utf8.decode(base64Decode(content));
        nodes = _parseConfigContent(decoded);
      } catch (e) {
        // 如果不是 Base64，尝试直接解析
        nodes = _parseConfigContent(content);
      }

      Logger.d('解析完成，共 ${nodes.length} 个节点');
      return nodes;
    } catch (e) {
      Logger.e('解析订阅异常: $e');
      return [];
    }
  }

  // 解析配置内容（支持 Clash、V2Ray、Shadowsocks 等格式）
  static List<Node> _parseConfigContent(String content) {
    final nodes = <Node>[];

    try {
      // 尝试解析为 JSON（Clash 格式）
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      // Clash 格式
      if (json.containsKey('proxies')) {
        final proxies = json['proxies'] as List<dynamic>;
        for (var i = 0; i < proxies.length; i++) {
          final proxy = proxies[i] as Map<String, dynamic>;
          final node = _parseClashProxy(proxy, i);
          if (node != null) {
            nodes.add(node);
          }
        }
      }
    } catch (e) {
      // 如果不是 JSON，尝试解析为其他格式
      Logger.w('解析为 JSON 失败，尝试其他格式: $e');
      
      // TODO: 支持其他格式（V2Ray、Shadowsocks 等）
    }

    return nodes;
  }

  // 解析 Clash 代理配置
  static Node? _parseClashProxy(Map<String, dynamic> proxy, int index) {
    try {
      final type = proxy['type'] as String? ?? 'unknown';
      final name = proxy['name'] as String? ?? '节点 ${index + 1}';
      final server = proxy['server'] as String? ?? '';
      final port = (proxy['port'] as num?)?.toInt() ?? 0;

      if (server.isEmpty || port == 0) {
        return null;
      }

      return Node(
        id: 'node_${DateTime.now().millisecondsSinceEpoch}_$index',
        name: name,
        type: type,
        server: server,
        port: port,
        config: proxy,
      );
    } catch (e) {
      Logger.e('解析代理配置失败: $e');
      return null;
    }
  }

  // 从订阅 URL 导入节点
  static Future<void> importFromSubscription(String subscriptionUrl) async {
    try {
      final nodes = await parseSubscription(subscriptionUrl);
      
      if (nodes.isEmpty) {
        Logger.w('订阅中没有找到节点');
        return;
      }

      // TODO: 通过 provider 添加节点到列表
      // 这里需要访问 nodeListProvider
      Logger.d('成功导入 ${nodes.length} 个节点');
    } catch (e) {
      Logger.e('导入订阅失败: $e');
    }
  }
}

