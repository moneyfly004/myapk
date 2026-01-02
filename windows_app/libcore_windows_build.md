# libcore Windows DLL 构建指南

## 概述

需要将 Go 语言编写的 libcore 编译为 Windows DLL，以便 Flutter 通过 FFI 调用。

## 构建步骤

### 1. 准备 Go 环境

```bash
# 检查 Go 版本（需要 1.21+）
go version

# 设置 Windows 交叉编译环境变量（如果在 Linux/macOS 上构建）
export GOOS=windows
export GOARCH=amd64
```

### 2. 创建 CGO 导出文件

在 `libcore` 目录下创建 `libcore_export.go`:

```go
package main

import "C"

//export libcore_init
func libcore_init() {
    // 初始化 libcore
}

//export libcore_start
func libcore_start(config *C.char) C.int {
    // 启动代理
    configStr := C.GoString(config)
    // 解析配置并启动
    return 0
}

//export libcore_stop
func libcore_stop() {
    // 停止代理
}

//export libcore_get_status
func libcore_get_status() C.int {
    // 返回状态
    return 0
}

func main() {
    // DLL 不需要 main 函数
}
```

### 3. 构建 DLL

```bash
cd libcore

# 构建 Windows DLL
go build -buildmode=c-shared -o libcore.dll libcore_export.go

# 或者使用 gcc 链接
CGO_ENABLED=1 GOOS=windows GOARCH=amd64 go build -buildmode=c-shared -o libcore.dll
```

### 4. 复制 DLL 到 Flutter 项目

```bash
# 复制 DLL 到 windows_app 目录
cp libcore.dll ../windows_app/
```

### 5. 更新 FFI 绑定

确保 `libcore_bridge.dart` 中的函数签名与 Go 代码中的导出函数匹配。

## 依赖项

libcore 需要以下依赖：
- sing-box
- sing-tun (Windows TUN 支持)
- 其他代理协议库

## 注意事项

1. **CGO 要求**: 需要启用 CGO (`CGO_ENABLED=1`)
2. **Windows SDK**: 需要 Windows SDK 和 MinGW 或 MSVC
3. **TAP 驱动**: VPN 功能需要 TAP-Windows 驱动
4. **管理员权限**: VPN 功能需要管理员权限运行

## 替代方案

如果直接编译 DLL 有困难，可以考虑：

1. **使用 HTTP API**: 将 libcore 作为独立服务运行，通过 HTTP API 通信
2. **使用 gRPC**: 通过 gRPC 与 libcore 通信
3. **使用命名管道**: Windows 命名管道通信

## 测试

构建完成后，可以在 Flutter 中测试：

```dart
// 初始化
await LibcoreBridge.initialize();

// 启动
final config = '{"outbounds": [...]}';
final result = LibcoreBridge.start(config);

// 检查状态
final status = LibcoreBridge.getStatus();

// 停止
LibcoreBridge.stop();
```

