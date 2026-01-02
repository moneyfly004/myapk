import 'dart:async';

/// 防抖器（用于优化频繁触发的操作）
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// 节流器（限制函数执行频率）
class Throttler {
  final Duration delay;
  DateTime? _lastRun;
  Timer? _timer;

  Throttler({this.delay = const Duration(milliseconds: 300)});

  void call(void Function() action) {
    final now = DateTime.now();
    
    if (_lastRun == null || 
        now.difference(_lastRun!) >= delay) {
      action();
      _lastRun = now;
    } else {
      // 如果还在节流期内，安排延迟执行
      _timer?.cancel();
      _timer = Timer(
        delay - now.difference(_lastRun!),
        action,
      );
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

