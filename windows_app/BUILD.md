# Windows 构建指南

## 前置要求

### 1. Flutter SDK
- 下载并安装 Flutter SDK: https://flutter.dev/docs/get-started/install/windows
- 确保 Flutter 已添加到系统 PATH
- 验证安装：
  ```bash
  flutter doctor
  ```

### 2. Visual Studio
- 安装 Visual Studio 2019 或 2022
- 选择 "Desktop development with C++" 工作负载
- 包含以下组件：
  - Windows 10/11 SDK
  - MSVC v142 或更高版本的 C++ 构建工具
  - CMake 工具

### 3. Git
- 安装 Git for Windows: https://git-scm.com/download/win

## 快速构建

### 方法1：使用构建脚本（推荐）

1. 双击运行 `build_windows.bat`
2. 按照提示选择构建类型（Debug 或 Release）
3. 等待构建完成

### 方法2：手动构建

```bash
# 1. 进入项目目录
cd windows_app

# 2. 清理之前的构建
flutter clean

# 3. 获取依赖
flutter pub get

# 4. 分析代码（可选）
flutter analyze

# 5. 构建 Debug 版本
flutter build windows --debug

# 或构建 Release 版本
flutter build windows --release
```

## 构建产物

构建完成后，可执行文件位于：

- **Debug 版本**: `build\windows\x64\debug\runner\nekobox_windows.exe`
- **Release 版本**: `build\windows\x64\runner\Release\nekobox_windows.exe`

## 运行应用

### 方法1：直接运行
双击 `nekobox_windows.exe` 运行

### 方法2：使用 Flutter 运行
```bash
flutter run -d windows
```

### 方法3：开发模式（热重载）
```bash
flutter run -d windows
# 按 'r' 热重载
# 按 'R' 热重启
```

## 常见问题

### 1. "build windows" only supported on Windows hosts
- **原因**: 在非 Windows 系统上尝试构建
- **解决**: 必须在 Windows 机器上构建

### 2. Visual Studio 未找到
- **原因**: 未安装 Visual Studio 或未正确配置
- **解决**: 
  - 安装 Visual Studio 2019/2022
  - 确保安装了 "Desktop development with C++" 工作负载
  - 运行 `flutter doctor` 检查配置

### 3. Windows SDK 未找到
- **原因**: 未安装 Windows 10/11 SDK
- **解决**: 
  - 在 Visual Studio Installer 中安装 Windows 10/11 SDK
  - 或单独下载安装 Windows SDK

### 4. CMake 错误
- **原因**: CMake 未安装或版本过低
- **解决**: 
  - 安装 CMake 3.14 或更高版本
  - 或通过 Visual Studio Installer 安装 CMake 工具

### 5. 依赖获取失败
- **原因**: 网络问题或 pub.dev 访问问题
- **解决**: 
  - 检查网络连接
  - 配置 Flutter 国内镜像（如在中国）
  - 使用代理

## 构建优化

### Release 构建优化

Release 版本会自动进行以下优化：
- 代码压缩和混淆
- 移除调试信息
- 优化性能

### 减小应用体积

1. 移除未使用的资源
2. 使用 `flutter build windows --release --split-debug-info=<directory>` 分离调试信息
3. 压缩资源文件

## 代码签名（可选）

如果需要发布应用，建议进行代码签名：

```bash
# 使用 signtool 签名
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com nekobox_windows.exe
```

## 打包分发

### 方法1：直接分发文件夹
将整个 `Release` 文件夹打包分发

### 方法2：创建安装程序
使用以下工具创建安装程序：
- Inno Setup
- NSIS
- WiX Toolset

### 方法3：使用 Flutter 打包工具
```bash
# 安装 flutter_distributor
dart pub global activate flutter_distributor

# 创建分发配置
flutter_distributor package --platform windows
```

## 持续集成（CI）

### GitHub Actions 示例

在 `.github/workflows/build_windows.yml` 中配置：

```yaml
name: Build Windows

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.3'
      - run: cd windows_app && flutter pub get
      - run: cd windows_app && flutter build windows --release
      - uses: actions/upload-artifact@v3
        with:
          name: windows-build
          path: windows_app/build/windows/x64/runner/Release/
```

## 下一步

构建成功后，可以：
1. 测试应用功能
2. 集成 libcore（Go 核心库）
3. 实现 VPN 连接功能
4. 添加系统托盘和开机自启动

