# NekoBox for Android - 完整构建指南

## 📋 前置要求

### 必需软件
1. **Android Studio** (Arctic Fox 或更高版本)
2. **JDK 11** 或更高版本
3. **Go 1.21+** (用于编译 libcore)
4. **Android NDK** r26d
5. **Git**

### 环境变量
```bash
export ANDROID_HOME=/path/to/android-sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/26.x.xxxx
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
```

## 🔧 完整构建步骤

### 步骤 1: 初始化 libcore

```bash
cd /Users/apple/Downloads/NekoBoxForAndroid

# 初始化 libcore 环境
./buildScript/lib/core/init.sh

# 获取 libcore 源代码
./buildScript/lib/core/get_source.sh

# 编译 libcore
./buildScript/lib/core/build.sh
```

**注意**: libcore 编译可能需要 15-30 分钟，取决于你的机器性能。

### 步骤 2: 清理项目

```bash
./gradlew clean
```

### 步骤 3: 构建 APK

#### 构建 Debug 版本
```bash
# Play 版本（推荐）
./gradlew app:assemblePlayDebug

# 或者 OSS 版本
./gradlew app:assembleOssDebug
```

#### 构建 Release 版本
```bash
# 需要先配置签名
# 创建 release.keystore 文件

./gradlew app:assemblePlayRelease
```

### 步骤 4: 查找 APK

```bash
# Debug APK 位置
ls -lh app/build/outputs/apk/play/debug/

# Release APK 位置
ls -lh app/build/outputs/apk/play/release/
```

## 🚀 快速构建（如果 libcore 已编译）

如果你之前已经成功编译过 libcore，可以直接：

```bash
cd /Users/apple/Downloads/NekoBoxForAndroid
./gradlew app:assemblePlayDebug
```

## 📱 安装到设备

### 通过 ADB 安装
```bash
# 连接设备
adb devices

# 安装 APK
adb install app/build/outputs/apk/play/debug/app-play-debug.apk
```

### 通过 Gradle 安装
```bash
./gradlew app:installPlayDebug
```

## 🐛 常见问题

### 问题 1: libcore 编译失败

**原因**: Go 环境未正确配置或 NDK 版本不匹配

**解决方案**:
```bash
# 检查 Go 版本
go version  # 应该是 1.21 或更高

# 检查 NDK 路径
echo $ANDROID_NDK_HOME

# 重新初始化
./buildScript/lib/core/init.sh
```

### 问题 2: Unresolved reference 'libcore'

**原因**: libcore 未编译或编译失败

**解决方案**:
```bash
# 重新编译 libcore
./buildScript/lib/core/build.sh

# 检查输出
ls -lh app/libs/
```

### 问题 3: Gradle 构建失败

**原因**: Gradle 缓存问题

**解决方案**:
```bash
# 清理 Gradle 缓存
./gradlew clean --no-daemon

# 重新构建
./gradlew app:assemblePlayDebug --refresh-dependencies
```

### 问题 4: 签名配置缺失

**原因**: Release 构建需要签名配置

**解决方案**:
```bash
# 使用项目自带的 release.keystore（仅用于测试）
# 或者创建自己的签名文件

keytool -genkey -v -keystore release.keystore \
  -alias mykey -keyalg RSA -keysize 2048 -validity 10000
```

## 🔍 验证构建

### 检查 APK 信息
```bash
# 查看 APK 信息
aapt dump badging app/build/outputs/apk/play/debug/app-play-debug.apk | grep package

# 查看 APK 大小
ls -lh app/build/outputs/apk/play/debug/app-play-debug.apk
```

### 运行 Lint 检查
```bash
./gradlew app:lintPlayDebug
```

## 📦 构建变体说明

NekoBox 有多个构建变体：

| 变体 | 说明 | 推荐 |
|------|------|------|
| **play** | Google Play 版本 | ✅ 推荐 |
| **oss** | 开源版本 | ✅ 推荐 |
| **fdroid** | F-Droid 版本 | - |
| **preview** | 预览版本 | - |

每个变体都有 Debug 和 Release 两个版本。

## 🎯 推荐的开发流程

### 1. 首次构建
```bash
# 完整构建流程
./buildScript/lib/core/init.sh
./buildScript/lib/core/get_source.sh
./buildScript/lib/core/build.sh
./gradlew app:assemblePlayDebug
```

### 2. 日常开发
```bash
# 只需要重新构建 APK
./gradlew app:assemblePlayDebug

# 或者直接安装到设备
./gradlew app:installPlayDebug
```

### 3. 修改 libcore 后
```bash
# 重新编译 libcore
./buildScript/lib/core/build.sh

# 清理并重新构建
./gradlew clean
./gradlew app:assemblePlayDebug
```

## 📊 构建时间参考

| 步骤 | 预计时间 | 说明 |
|------|---------|------|
| libcore 初始化 | 2-5 分钟 | 首次需要下载依赖 |
| libcore 编译 | 15-30 分钟 | 取决于机器性能 |
| Gradle 构建 | 3-5 分钟 | 首次构建较慢 |
| 增量构建 | 30-60 秒 | 修改代码后 |

## 🔐 签名配置（Release 构建）

### 创建签名文件
```bash
keytool -genkey -v -keystore release.keystore \
  -alias nekobox -keyalg RSA -keysize 2048 -validity 10000
```

### 配置 Gradle
在 `gradle.properties` 中添加：
```properties
KEYSTORE_PATH=./release.keystore
KEYSTORE_PASSWORD=your_password
KEY_ALIAS=nekobox
KEY_PASSWORD=your_key_password
```

## 📝 注意事项

1. **首次构建**: 需要下载大量依赖，确保网络畅通
2. **磁盘空间**: 至少需要 5GB 可用空间
3. **内存要求**: 建议 8GB RAM 以上
4. **NDK 版本**: 必须使用 r26d，其他版本可能不兼容
5. **Go 版本**: 必须 1.21 或更高版本

## 🆘 获取帮助

如果遇到问题：

1. 查看 NekoBox 官方文档: https://matsuridayo.github.io
2. 查看 GitHub Issues: https://github.com/MatsuriDayo/NekoBoxForAndroid/issues
3. 加入 Telegram 群组: https://t.me/Matsuridayo

## ✅ 构建成功标志

构建成功后，你应该看到：

```
BUILD SUCCESSFUL in Xm Xs
XX actionable tasks: XX executed

APK 位置:
app/build/outputs/apk/play/debug/app-play-debug.apk
```

APK 大小约 50-80 MB（Debug 版本）。

---

**最后更新**: 2025-12-31
**适用版本**: NekoBox for Android (修改版)

