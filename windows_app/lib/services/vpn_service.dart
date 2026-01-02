import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ffi/libcore_bridge.dart';
import '../core/utils/logger.dart';
import 'system_proxy_service.dart';

// VPN 状态
enum VpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

// VPN 服务状态
class VpnServiceState {
  final VpnStatus status;
  final String? errorMessage;
  final String? currentConfig;

  VpnServiceState({
    this.status = VpnStatus.disconnected,
    this.errorMessage,
    this.currentConfig,
  });

  VpnServiceState copyWith({
    VpnStatus? status,
    String? errorMessage,
    String? currentConfig,
  }) {
    return VpnServiceState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentConfig: currentConfig ?? this.currentConfig,
    );
  }
}

// VPN 服务提供者
final vpnServiceProvider = StateNotifierProvider<VpnServiceNotifier, VpnServiceState>(
  (ref) => VpnServiceNotifier(),
);

class VpnServiceNotifier extends StateNotifier<VpnServiceState> {
  VpnServiceNotifier() : super(VpnServiceState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始化 libcore
    final initialized = await LibcoreBridge.initialize();
    if (initialized) {
      LibcoreBridge.init();
    } else {
      state = state.copyWith(
        status: VpnStatus.error,
        errorMessage: 'libcore 初始化失败',
      );
    }
  }

  // 连接 VPN
  /// [configJson] sing-box 配置 JSON
  /// [isGlobalMode] 是否为全局模式（true=全局模式，false=规则模式）
  Future<void> connect(String configJson, {bool isGlobalMode = false}) async {
    if (state.status == VpnStatus.connected ||
                                                     state.status == VpnStatus.connecting) {
      return;
    }

    // 检查 libcore 是否已初始化
    if (!LibcoreBridge.isInitialized) {
      state = state.copyWith(
        status: VpnStatus.error,
        errorMessage: 'libcore 未初始化，VPN 功能不可用',
      );
      return;
    }

    state = state.copyWith(
      status: VpnStatus.connecting,
      errorMessage: null,
    );

    try {
      // 调用 libcore 启动代理（监听在 127.0.0.1:7890）
      final result = LibcoreBridge.start(configJson);
      
      if (result == 0) {
        // 设置系统代理
        // 规则模式：设置代理，但根据路由规则决定哪些流量走代理
        // 全局模式：所有流量都走代理
        final proxySet = await SystemProxyService.setSystemProxy(
          host: '127.0.0.1',
          port: 7890,
          bypass: isGlobalMode 
              ? null  // 全局模式：不设置绕过列表，所有流量都走代理
              : 'localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*;<local>', // 规则模式：绕过本地网络
        );

        if (!proxySet) {
          Logger.w('设置系统代理失败，但代理服务已启动');
        }

        state = state.copyWith(
          status: VpnStatus.connected,
          currentConfig: configJson,
          errorMessage: null,
        );

        Logger.d('VPN 连接成功，模式: ${isGlobalMode ? "全局" : "规则"}');
      } else {
        state = state.copyWith(
          status: VpnStatus.error,
          errorMessage: '连接失败，错误代码: $result',
        );
      }
    } catch (e) {
      Logger.e('连接 VPN 异常: $e');
      state = state.copyWith(
        status: VpnStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 断开 VPN
  Future<void> disconnect() async {
    if (state.status == VpnStatus.disconnected ||
        state.status == VpnStatus.disconnecting) {
      return;
    }

    state = state.copyWith(
      status: VpnStatus.disconnecting,
    );

    try {
      // 先清除系统代理
      await SystemProxyService.clearSystemProxy();
      
      // 然后停止 libcore
      if (LibcoreBridge.isInitialized) {
        LibcoreBridge.stop();
      }
      
      state = state.copyWith(
        status: VpnStatus.disconnected,
        currentConfig: null,
        errorMessage: null,
      );

      Logger.d('VPN 已断开，系统代理已清除');
    } catch (e) {
      Logger.e('断开 VPN 异常: $e');
      state = state.copyWith(
        status: VpnStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // 获取当前状态
  int getStatus() {
    try {
      if (!LibcoreBridge.isInitialized) {
        return -1;
      }
      return LibcoreBridge.getStatus();
    } catch (e) {
      return -1;
    }
  }

  @override
  void dispose() {
    if (state.status == VpnStatus.connected) {
      disconnect();
    }
    LibcoreBridge.dispose();
    super.dispose();
  }
}

// 生成 sing-box 配置 JSON
/// [server] 代理服务器地址
/// [port] 代理服务器端口
/// [type] 代理类型（vmess, trojan, shadowsocks 等）
/// [additionalConfig] 额外配置
/// [isGlobalMode] 是否为全局模式
/// [rules] 路由规则列表（规则模式时使用）
String generateSingBoxConfig({
  required String server,
  required int port,
  required String type,
  Map<String, dynamic>? additionalConfig,
  bool isGlobalMode = false,
  List<Map<String, dynamic>>? rules,
}) {
  final config = <String, dynamic>{
    'log': {
      'level': 'info',
    },
    'dns': {
      'servers': [
        {'address': '8.8.8.8'},
        {'address': '1.1.1.1'},
      ],
    },
    'inbounds': [
      {
        'type': 'mixed',
        'listen': '127.0.0.1',
        'listen_port': 7890,
      },
    ],
    'outbounds': [
      {
        'type': type,
        'server': server,
        'server_port': port,
        ...?additionalConfig,
      },
      {
        'type': 'direct',
        'tag': 'direct',
      },
      {
        'type': 'block',
        'tag': 'block',
      },
    ],
  };

  // 规则模式：添加路由规则
  if (!isGlobalMode && rules != null && rules.isNotEmpty) {
    final routeRules = <Map<String, dynamic>>[];
    
    for (final rule in rules) {
      if (rule['enabled'] != true) continue;
      
      final ruleConfig = <String, dynamic>{};
      
      // 域名规则
      if (rule['domains'] != null && rule['domains'].toString().isNotEmpty) {
        ruleConfig['domain'] = rule['domains'].toString().split(',');
      }
      
      // IP 规则
      if (rule['ip'] != null && rule['ip'].toString().isNotEmpty) {
        ruleConfig['ip'] = rule['ip'].toString().split(',');
      }
      
      // 出站动作
      final outbound = rule['outbound'] as int? ?? 0;
      String outboundTag;
      if (outbound == 0) {
        outboundTag = 'proxy'; // 代理
      } else if (outbound == -1) {
        outboundTag = 'direct'; // 直连
      } else if (outbound == -2) {
        outboundTag = 'block'; // 阻止
      } else {
        outboundTag = 'proxy'; // 默认代理
      }
      
      ruleConfig['outbound'] = outboundTag;
      routeRules.add(ruleConfig);
    }
    
    // 默认规则：所有流量走代理
    routeRules.add({
      'outbound': 'proxy',
    });
    
    config['route'] = {
      'rules': routeRules,
    };
  } else if (isGlobalMode) {
    // 全局模式：所有流量都走代理，不需要路由规则
    config['route'] = {
      'rules': [
        {
          'outbound': 'proxy',
        },
      ],
    };
  }

  // 转换为 JSON 字符串
  return jsonEncode(config);
}

