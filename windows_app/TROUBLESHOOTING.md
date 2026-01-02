# 🔧 GitHub Actions 构建问题排查指南

## 🚨 常见问题和解决方案

### 问题 1: 工作流未触发

**症状**: GitHub Actions 中没有新的运行记录

**可能原因**:
- 路径限制配置错误
- 分支名称不匹配
- 工作流文件语法错误

**解决方案**:
1. 检查 `.github/workflows/build_windows.yml` 文件是否存在
2. 确认分支名称为 `main` 或 `master`
3. 检查 YAML 语法是否正确
4. 手动触发工作流（如果配置了 `workflow_dispatch`）

**已修复**: ✅ 已移除路径限制，现在所有推送都会触发

---

### 问题 2: Flutter 环境设置失败

**症状**: `Setup Flutter` 步骤失败

**错误信息示例**:
```
Error: Flutter version '3.24.0' not found
```

**解决方案**:
1. 检查 Flutter 版本是否可用
2. 尝试使用其他 Flutter 版本（如 `3.22.0`）
3. 检查 `subosito/flutter-action` 是否支持该版本

**修复代码**:
```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.22.0'  # 如果 3.24.0 不可用，使用稳定版本
    channel: 'stable'
    cache: true
```

---

### 问题 3: 依赖安装失败

**症状**: `flutter pub get` 失败

**错误信息示例**:
```
Error: Could not find a version of package 'xxx' that satisfies the requirements
```

**解决方案**:
1. 检查 `pubspec.yaml` 中的依赖版本
2. 确保所有依赖都兼容 Flutter 3.24.0
3. 检查依赖是否支持 Windows 平台

**修复步骤**:
```bash
cd windows_app
flutter pub get
# 查看错误信息
# 修复 pubspec.yaml
# 重新推送
```

---

### 问题 4: 代码分析失败

**症状**: `flutter analyze` 失败

**错误信息示例**:
```
error • Undefined class 'XXX'
```

**解决方案**:
1. 本地运行 `flutter analyze` 检查错误
2. 修复所有 error 和 warning
3. 确保代码可以正常编译

**修复命令**:
```bash
cd windows_app
flutter analyze --no-fatal-infos
# 修复所有错误
# 重新推送
```

---

### 问题 5: Windows 构建失败

**症状**: `flutter build windows --release` 失败

**错误信息示例**:
```
Error: Unable to find Windows SDK
```

**解决方案**:
1. 检查 Windows 构建工具是否安装
2. 确保 CMake 配置正确
3. 检查 Windows 特定依赖

**可能原因**:
- Windows SDK 未安装
- CMake 配置错误
- 缺少 Windows 特定依赖

---

### 问题 6: 压缩文件失败

**症状**: `Compress-Archive` 失败

**错误信息示例**:
```
Compress-Archive: Access denied
```

**解决方案**:
1. 检查文件路径是否正确
2. 确保有写入权限
3. 检查 PowerShell 版本

**修复代码**:
```yaml
- name: Create Release Archive
  working-directory: windows_app/build/windows/x64/runner/Release
  run: |
    if (Test-Path "${{ github.workspace }}/nekobox-windows-release.zip") {
      Remove-Item "${{ github.workspace }}/nekobox-windows-release.zip"
    }
    Compress-Archive -Path "." -DestinationPath "${{ github.workspace }}/nekobox-windows-release.zip" -CompressionLevel Optimal
```

---

## 🔍 调试步骤

### 1. 本地测试构建

在推送之前，先在本地测试：

```bash
cd windows_app
flutter clean
flutter pub get
flutter analyze --no-fatal-infos
flutter build windows --release
```

### 2. 检查工作流配置

```bash
cat .github/workflows/build_windows.yml
```

### 3. 查看 GitHub Actions 日志

1. 访问: https://github.com/moneyfly004/myapk/actions
2. 点击失败的工作流运行
3. 查看每个步骤的详细日志
4. 查找红色错误标记

### 4. 修复并重新推送

```bash
# 修复问题
# ...

# 提交并推送
git add .
git commit -m "Fix build issues"
git push myrepo main
```

---

## 📋 构建检查清单

在推送代码之前，确保：

- [ ] 本地可以成功构建 (`flutter build windows --release`)
- [ ] 代码分析通过 (`flutter analyze --no-fatal-infos`)
- [ ] 所有依赖已正确配置
- [ ] 工作流文件语法正确
- [ ] 路径配置正确

---

## 🎯 快速修复命令

### 如果构建失败，快速修复：

```bash
# 1. 检查本地构建
cd windows_app
flutter clean
flutter pub get
flutter analyze
flutter build windows --release

# 2. 修复问题后重新推送
cd ..
git add .
git commit -m "Fix build issues"
git push myrepo main
```

---

## 📞 获取帮助

如果遇到无法解决的问题：

1. 查看 GitHub Actions 详细日志
2. 检查 Flutter 官方文档
3. 查看 GitHub Actions 文档
4. 检查依赖包的文档

---

**当前状态**: ⏳ 等待构建完成...

**如果构建失败，请按照上述步骤排查和修复问题。**

