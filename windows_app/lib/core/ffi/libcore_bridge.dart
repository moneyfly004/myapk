import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// libcore 函数签名定义
typedef NativeInit = Void Function();
typedef NativeInitDart = void Function();

typedef NativeStart = Int32 Function(Pointer<Utf8>);
typedef NativeStartDart = int Function(Pointer<Utf8>);

typedef NativeStop = Void Function();
typedef NativeStopDart = void Function();

typedef NativeGetStatus = Int32 Function();
typedef NativeGetStatusDart = int Function();

class LibcoreBridge {
  static DynamicLibrary? _dylib;
  static bool _isInitialized = false;
  
  // 公开 isInitialized 以便外部检查
  static bool get isInitialized => _isInitialized;

  // 初始化 libcore
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 尝试加载 libcore.dll
      // 注意：需要先编译 Go 代码为 Windows DLL
      final dllPath = _getDllPath();
      
      if (!File(dllPath).existsSync()) {
        // 警告: libcore.dll 不存在，请先编译 Go 代码
        return false;
      }

      _dylib = DynamicLibrary.open(dllPath);
      _isInitialized = true;
      return true;
    } catch (e) {
      // 加载 libcore.dll 失败: $e
      return false;
    }
  }

  // 获取 DLL 路径
  static String _getDllPath() {
    if (Platform.isWindows) {
      // Windows 上，DLL 应该在应用目录或系统路径中
      final appDir = Platform.resolvedExecutable;
      final appPath = appDir.substring(0, appDir.lastIndexOf('\\'));
      return '$appPath\\libcore.dll';
    }
    return 'libcore.dll';
  }

  // 初始化 libcore
  static void init() {
    if (!_isInitialized) {
      throw Exception('libcore 未初始化，请先调用 initialize()');
    }

    final initFunc = _dylib!
        .lookup<NativeFunction<NativeInit>>('libcore_init')
        .asFunction<NativeInitDart>();
    initFunc();
  }

  // 启动代理
  static int start(String configJson) {
    if (!_isInitialized) {
      throw Exception('libcore 未初始化');
    }

    final startFunc = _dylib!
        .lookup<NativeFunction<NativeStart>>('libcore_start')
        .asFunction<NativeStartDart>();

    final configPtr = configJson.toNativeUtf8();
    try {
      return startFunc(configPtr);
    } finally {
      malloc.free(configPtr);
    }
  }

  // 停止代理
  static void stop() {
    if (!_isInitialized) {
      throw Exception('libcore 未初始化');
    }

    final stopFunc = _dylib!
        .lookup<NativeFunction<NativeStop>>('libcore_stop')
        .asFunction<NativeStopDart>();
    stopFunc();
  }

  // 获取状态
  static int getStatus() {
    if (!_isInitialized) {
      throw Exception('libcore 未初始化');
    }

    final statusFunc = _dylib!
        .lookup<NativeFunction<NativeGetStatus>>('libcore_get_status')
        .asFunction<NativeGetStatusDart>();
    return statusFunc();
  }

  // 清理资源
  static void dispose() {
    if (_isInitialized) {
      try {
        stop();
      } catch (e) {
        // 忽略停止错误，继续清理
      }
      _isInitialized = false;
      _dylib = null;
    }
  }
}

