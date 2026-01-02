# 🚀 Windows Release 构建指南

参考 Android 端的 release 构建配置，为 Windows 桌面应用配置 release 构建。

## 📋 构建配置说明

### 版本管理

版本信息从 `version.properties` 文件读取（参考 Android 端的 `nb4a.properties`）：

```properties
PACKAGE_NAME=io.nekohasekai.sagernet.windows
VERSION_NAME=1.0.0
VERSION_CODE=1
PRE_VERSION_NAME=
GITHUB_REPO=moneyfly004/myapk
GITHUB_RELEASES_URL=https://api.github.com/repos/moneyfly004/myapk/releases
```

### 版本信息同步

版本信息在 `pubspec.yaml` 中定义：

```yaml
version: 1.0.0+1
```

格式：`VERSION_NAME+VERSION_CODE`

- `VERSION_NAME`: 显示给用户的版本号（如 `1.0.0`）
- `VERSION_CODE`: 内部版本号，用于更新判断（如 `1`）

### 代码中获取版本信息

使用 `VersionConfig` 类：

```dart
import 'package:nekobox_windows/core/config/version_config.dart';

// 初始化
await VersionConfig.instance.initialize();

// 获取版本信息
String versionName = VersionConfig.instance.versionName;
int versionCode = VersionConfig.instance.versionCode;
String displayVersion = VersionConfig.instance.versionNameForDisplay;
```

## 🔨 构建步骤

### 方法 1: 使用构建脚本（推荐）

#### Windows 系统
```bash
# 双击运行或在命令行执行
build_release.bat
```

#### Linux/Mac (使用 Git Bash 或 WSL)
```bash
chmod +x build_release.sh
./build_release.sh
```

### 方法 2: 手动构建

```bash
# 1. 清理之前的构建
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 分析代码（可选）
flutter analyze --no-fatal-infos

# 4. 构建 Release 版本
flutter build windows --release
```

## 📦 构建输出

Release 构建完成后，输出文件位于：

```
build/windows/x64/runner/Release/
```

包含以下文件：
- `nekobox_windows.exe` - 主程序
- `data/` - 数据文件
- `flutter_windows.dll` - Flutter 运行时
- 其他依赖 DLL 文件

## 🎯 Release 构建特性

### 1. 代码优化
- **Tree Shaking**: 自动移除未使用的代码
- **代码压缩**: 减小应用体积
- **性能优化**: 启用所有优化选项

### 2. 资源优化
- **资源压缩**: 压缩图片和资源文件
- **移除调试信息**: 移除调试符号和日志

### 3. 性能提升
- **AOT 编译**: Ahead-of-Time 编译，提升启动速度
- **优化渲染**: 启用所有渲染优化

## 🔐 代码签名（可选）

如果需要代码签名（类似 Android 的签名配置），可以使用：

### 使用 signtool（Windows SDK）

```bash
# 签名 EXE 文件
signtool sign /f certificate.pfx /p password /t http://timestamp.digicert.com nekobox_windows.exe
```

### 使用 Inno Setup 打包并签名

创建安装包时可以同时签名：

```inno
[Setup]
SignTool=signtool
SignedUninstaller=yes
```

## 📝 版本更新流程

### 1. 更新版本号

编辑 `pubspec.yaml`：
```yaml
version: 1.0.1+2  # 版本名称 + 版本代码
```

同步更新 `version.properties`：
```properties
VERSION_NAME=1.0.1
VERSION_CODE=2
```

### 2. 构建 Release

```bash
flutter build windows --release
```

### 3. 创建 GitHub Release

1. 在 GitHub 上创建新的 Release
2. 上传构建的 EXE 文件
3. 添加 Release 说明

### 4. 自动更新检查

应用会自动从 GitHub Releases 检查更新（参考 Android 端的实现）。

## 🐛 调试 Release 版本

如果需要调试 Release 版本：

```bash
# 构建带调试信息的 Release
flutter build windows --release --debug
```

或者使用 Profile 模式：

```bash
flutter build windows --profile
```

## 📊 构建对比

| 特性 | Debug | Profile | Release |
|------|-------|---------|---------|
| 代码优化 | ❌ | ✅ | ✅✅ |
| 性能优化 | ❌ | ✅ | ✅✅ |
| 调试信息 | ✅ | ✅ | ❌ |
| 体积大小 | 大 | 中 | 小 |
| 启动速度 | 慢 | 中 | 快 |

## 🔄 与 Android 端对比

### Android Release 配置
- ✅ 代码混淆（ProGuard）
- ✅ 资源压缩（shrinkResources）
- ✅ 签名配置（从 local.properties 读取）
- ✅ 版本管理（从 nb4a.properties 读取）
- ✅ 多架构支持（ARM, x86）

### Windows Release 配置
- ✅ 代码优化（Tree Shaking）
- ✅ 资源压缩（自动）
- ✅ 代码签名（可选，使用 signtool）
- ✅ 版本管理（从 version.properties 读取）
- ✅ 单架构支持（x64）

## 📚 相关文件

- `version.properties` - 版本配置文件
- `pubspec.yaml` - Flutter 项目配置（包含版本信息）
- `build_release.bat` - Windows 构建脚本
- `build_release.sh` - Linux/Mac 构建脚本
- `lib/core/config/version_config.dart` - 版本配置管理类

## ⚠️ 注意事项

1. **构建环境**: 必须在 Windows 系统上构建 Windows 应用
2. **Flutter 版本**: 确保使用兼容的 Flutter 版本
3. **依赖检查**: 构建前确保所有依赖都已正确安装
4. **版本同步**: 确保 `pubspec.yaml` 和 `version.properties` 中的版本信息一致
5. **测试**: 构建后务必测试应用功能是否正常

## 🚀 快速开始

```bash
# 1. 确保版本信息正确
# 编辑 pubspec.yaml 和 version.properties

# 2. 运行构建脚本
build_release.bat

# 3. 检查输出
# 查看 build/windows/x64/runner/Release/
```

---

参考 Android 端的构建配置，确保 Windows 端也有类似的 release 构建流程和版本管理机制。

