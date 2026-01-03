import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

// AuthRepository 单例
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// 认证状态
class AuthState {
  final bool isAuthenticated;
  final String? email;
  final String? username;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.email,
    this.username,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? username,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 认证状态 Provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      final userInfo = await _repository.getUserInfo();
      state = state.copyWith(
        isAuthenticated: true,
        email: userInfo['email'],
        username: userInfo['username'],
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.login(email, password);
      return result.when(
        success: (response) async {
          // 获取订阅信息
          await _repository.getUserSubscription();
          state = state.copyWith(
            isAuthenticated: true,
            email: response.email,
            username: response.username,
            isLoading: false,
          );
          return true;
        },
        failure: (error) {
          state = state.copyWith(isLoading: false);
          return false;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password, {
    String? verificationCode,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _repository.register(
        username,
        email,
        password,
        verificationCode: verificationCode,
      );
      return result.when(
        success: (_) {
          state = state.copyWith(isLoading: false);
          return true;
        },
        failure: (_) {
          state = state.copyWith(isLoading: false);
          return false;
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }

  Future<void> refreshUserInfo() async {
    await _checkAuthStatus();
  }
}

