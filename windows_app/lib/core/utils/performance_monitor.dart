import 'dart:async';
import 'dart:collection';

/// 性能监控器
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _metrics = {};
  final Queue<String> _recentEvents = Queue();

  /// 开始计时
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// 结束计时并记录
  Duration? endTimer(String name) {
    final timer = _timers.remove(name);
    if (timer == null) return null;

    timer.stop();
    final duration = timer.elapsed;

    // 记录指标
    _metrics.putIfAbsent(name, () => []).add(duration);
    if (_metrics[name]!.length > 100) {
      _metrics[name]!.removeAt(0);
    }

    // 记录最近事件
    _recentEvents.add('$name: ${duration.inMilliseconds}ms');
    if (_recentEvents.length > 50) {
      _recentEvents.removeFirst();
    }

    return duration;
  }

  /// 获取平均耗时
  Duration? getAverageTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    final total = times.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: total ~/ times.length);
  }

  /// 获取最大耗时
  Duration? getMaxTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a > b ? a : b);
  }

  /// 获取最小耗时
  Duration? getMinTime(String name) {
    final times = _metrics[name];
    if (times == null || times.isEmpty) return null;

    return times.reduce((a, b) => a < b ? a : b);
  }

  /// 获取所有指标
  Map<String, Map<String, Duration?>> getAllMetrics() {
    final result = <String, Map<String, Duration?>>{};
    for (final name in _metrics.keys) {
      result[name] = {
        'average': getAverageTime(name),
        'max': getMaxTime(name),
        'min': getMinTime(name),
        'count': Duration(milliseconds: _metrics[name]!.length),
      };
    }
    return result;
  }

  /// 获取最近事件
  List<String> getRecentEvents() {
    return _recentEvents.toList().reversed.toList();
  }

  /// 清理指标
  void clearMetrics() {
    _metrics.clear();
    _recentEvents.clear();
  }

  /// 清理特定指标
  void clearMetric(String name) {
    _metrics.remove(name);
  }
}

/// 性能监控装饰器
Future<T> measurePerformance<T>(
  String name,
  Future<T> Function() action,
) async {
  final monitor = PerformanceMonitor();
  monitor.startTimer(name);
  try {
    return await action();
  } finally {
    monitor.endTimer(name);
  }
}

T measurePerformanceSync<T>(
  String name,
  T Function() action,
) {
  final monitor = PerformanceMonitor();
  monitor.startTimer(name);
  try {
    return action();
  } finally {
    monitor.endTimer(name);
  }
}

