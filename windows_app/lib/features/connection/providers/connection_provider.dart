import 'package:flutter_riverpod/flutter_riverpod.dart';

// 连接状态
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

// 连接状态提供者
class ConnectionState {
  final ConnectionStatus status;
  final String? errorMessage;
  final String? selectedNodeId;

  ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.errorMessage,
    this.selectedNodeId,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? errorMessage,
    String? selectedNodeId,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
    );
  }
}

// 连接状态提供者
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>(
  (ref) => ConnectionNotifier(),
);

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  ConnectionNotifier() : super(ConnectionState());

  Future<void> connect(String? nodeId) async {
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      selectedNodeId: nodeId,
    );

    try {
      // TODO: 实现实际的连接逻辑
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(
        status: ConnectionStatus.connected,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(
      status: ConnectionStatus.disconnecting,
    );

    try {
      // TODO: 实现实际的断开逻辑
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

