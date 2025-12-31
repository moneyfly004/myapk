# 导航循环问题修复总结

## ✅ 已修复的问题

### 1. 统一认证检查逻辑
- **问题**：两个 Activity 的认证检查可能不一致
- **修复**：统一使用 `token != null && token.isNotBlank()` 检查
- **位置**：
  - `SimpleHomeActivity.onCreate()`
  - `LoginActivity.onCreate()`

### 2. 添加防重复跳转机制
- **问题**：Activity 生命周期可能导致重复跳转
- **修复**：添加 `isNavigating` 标志防止重复跳转
- **位置**：
  - `SimpleHomeActivity` 和 `LoginActivity` 都添加了标志

### 3. 优化跳转时机
- **问题**：在 UI 加载后才检查认证，导致闪烁
- **修复**：在 `setContentView` 之前检查认证状态
- **效果**：避免 UI 闪烁，提升用户体验

### 4. 添加详细日志
- **问题**：无法追踪跳转流程
- **修复**：在关键位置添加 Log 输出
- **日志标签**：
  - `SimpleHomeActivity`
  - `LoginActivity`
  - `AuthRepository`

### 5. 添加异常处理
- **问题**：跳转失败时可能导致状态异常
- **修复**：添加 try-catch 处理跳转异常
- **效果**：确保状态标志正确重置

### 6. 生命周期保护
- **问题**：在 onStart/onResume 中可能重复检查
- **修复**：
  - `onStart` 中再次检查认证（防止后台 Token 被清除）
  - `onResume` 中重置跳转标志

## 🔍 调试方法

### 查看日志
```bash
# 查看认证和跳转相关日志
adb logcat | grep -E "SimpleHomeActivity|LoginActivity|AuthRepository"

# 查看所有日志并保存
adb logcat > navigation_logs.txt
```

### 关键日志信息
查找以下日志来诊断问题：
1. `SimpleHomeActivity onCreate: token存在=...`
2. `LoginActivity onCreate: token存在=...`
3. `isAuthenticated 检查: ...`
4. `navigateToMain: 准备跳转到主页`
5. `正在跳转中，忽略本次 onCreate`

## 📋 预期行为

### 场景 1：首次打开（未登录）
```
1. 启动应用
2. SimpleHomeActivity.onCreate()
3. 检查认证 → 未认证
4. 跳转到 LoginActivity
5. LoginActivity 显示登录界面 ✅
```

### 场景 2：已登录状态
```
1. 启动应用
2. SimpleHomeActivity.onCreate()
3. 检查认证 → 已认证
4. 显示主页界面 ✅
```

### 场景 3：登录成功后
```
1. LoginActivity 中登录成功
2. navigateToMain()
3. SimpleHomeActivity.onCreate()
4. 检查认证 → 已认证
5. 显示主页界面 ✅
```

## ⚠️ 如果问题仍然存在

### 检查点 1：清除应用数据
```bash
adb shell pm clear io.nekohasekai.sagernet
```

### 检查点 2：检查 Token 状态
在日志中查找：
- Token 是否存在
- Token 是否为空字符串
- Token 长度

### 检查点 3：检查 Activity 启动模式
- `SimpleHomeActivity` 使用 `singleTask` 模式
- 确保不会创建多个实例

### 检查点 4：检查 Intent Flags
- 使用 `FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_CLEAR_TASK`
- 确保清除任务栈

## 🎯 测试步骤

1. **清除应用数据**
   ```bash
   adb shell pm clear io.nekohasekai.sagernet
   ```

2. **安装新 APK**
   ```bash
   adb install -r app/build/outputs/apk/play/debug/NekoBox-1.4.1-play-arm64-v8a-debug.apk
   ```

3. **启动应用并查看日志**
   ```bash
   adb logcat -c  # 清除日志
   adb logcat | grep -E "SimpleHomeActivity|LoginActivity"
   ```

4. **测试登录流程**
   - 输入邮箱和密码
   - 点击登录
   - 观察是否成功跳转到主页

5. **测试重新打开**
   - 关闭应用
   - 重新打开
   - 应该直接进入主页（如果已登录）

## 📝 修改的文件

1. `SimpleHomeActivity.kt`
   - 添加防重复跳转机制
   - 优化认证检查逻辑
   - 添加详细日志
   - 添加生命周期保护

2. `LoginActivity.kt`
   - 添加防重复跳转机制
   - 优化认证检查逻辑
   - 添加详细日志
   - 优化跳转方法

3. `AuthRepository.kt`
   - 增强 `isAuthenticated()` 方法的日志

## ✅ 构建状态

- ✅ 代码编译通过
- ✅ APK 构建成功
- ✅ 所有修改已应用

## 🚀 下一步

1. 安装 APK 到设备
2. 测试登录流程
3. 查看日志确认跳转流程
4. 如果仍有问题，根据日志进一步调试

