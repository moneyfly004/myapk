import 'dart:async';
import 'package:flutter/foundation.dart';
import 'logger.dart';

/// 错误处理器
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<ErrorCallback> _callbacks = [];

  /// 注册错误回调
  void registerCallback(ErrorCallback callback) {
    _callbacks.add(callback);
  }

  /// 移除错误回调
  void unregisterCallback(ErrorCallback callback) {
    _callbacks.remove(callback);
  }

  /// 处理错误
  Future<void> handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    final errorInfo = ErrorInfo(
      error: error,
      stackTrace: stackTrace,
      context: context,
      fatal: fatal,
      timestamp: DateTime.now(),
    );

    // 通知所有回调
    for (final callback in _callbacks) {
      try {
        await callback(errorInfo);
      } catch (e) {
        // 避免回调中的错误导致循环
        Logger.error('错误回调执行失败', e);
      }
    }
  }

  /// 安全执行（带重试）
  Future<T?> safeExecute<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    Duration? retryDelay,
    String? context,
    T? defaultValue,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await action();
      } catch (e, stackTrace) {
        attempts++;
        await handleError(
          e,
          stackTrace,
          context: context ?? 'safeExecute',
        );

        if (attempts >= maxRetries) {
          return defaultValue;
        }

        if (retryDelay != null) {
          await Future.delayed(retryDelay);
        }
      }
    }
    return defaultValue;
  }
}

typedef ErrorCallback = Future<void> Function(ErrorInfo errorInfo);

class ErrorInfo {
  final dynamic error;
  final StackTrace? stackTrace;
  final String? context;
  final bool fatal;
  final DateTime timestamp;

  ErrorInfo({
    required this.error,
    this.stackTrace,
    this.context,
    this.fatal = false,
    required this.timestamp,
  });

  String get message => error.toString();
  String get contextMessage => context != null ? '[$context] $message' : message;
}

/// 全局错误处理
void setupGlobalErrorHandling() {
  // Flutter 错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler().handleError(
      details.exception,
      details.stack,
      context: 'Flutter',
      fatal: false,
    );
  };

  // 异步错误处理
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler().handleError(
      error,
      stack,
      context: 'Async',
      fatal: true,
    );
    return true;
  };
}
