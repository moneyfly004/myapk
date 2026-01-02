import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ffi/libcore_bridge.dart';

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
  Future<void> connect(String configJson) async {
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
      // 调用 libcore 启动代理
      final result = LibcoreBridge.start(configJson);
      
      if (result == 0) {
        state = state.copyWith(
          status: VpnStatus.connected,
          currentConfig: configJson,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: VpnStatus.error,
          errorMessage: '连接失败，错误代码: $result',
        );
      }
    } catch (e) {
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
      // 检查 libcore 是否已初始化
      if (LibcoreBridge.isInitialized) {
        LibcoreBridge.stop();
      }
      
      state = state.copyWith(
        status: VpnStatus.disconnected,
        currentConfig: null,
        errorMessage: null,
      );
    } catch (e) {
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
String generateSingBoxConfig({
  required String server,
  required int port,
  required String type,
  Map<String, dynamic>? additionalConfig,
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
    ],
  };

  // 转换为 JSON 字符串
  return jsonEncode(config);
}

