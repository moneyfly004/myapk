import 'package:flutter/foundation.dart';

/// 日志管理器（性能优化：使用 debugPrint 替代 print）
class Logger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
      if (error != null) {
        debugPrint('Error: $error');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
      }
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // 错误总是记录（使用 debugPrint 避免生产环境性能问题）
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void performance(String operation, Duration duration) {
    if (kDebugMode) {
      debugPrint('[PERF] $operation: ${duration.inMilliseconds}ms');
    }
  }
}

