# NekoBox for Android - 认证系统和自动订阅修改说明

## 📋 修改概述

本次修改为 NekoBox for Android 添加了完整的认证系统和自动订阅管理功能，参考了 Hiddify 项目的实现。

## 🎯 新增功能

### 1. 认证系统

#### 后端 API 集成
- **API 地址**: `https://dy.moneyfly.top`
- **认证方式**: JWT Token
- **支持功能**:
  - ✅ 用户登录（邮箱 + 密码）
  - ✅ 用户注册（用户名 + 邮箱 + 密码 + 验证码）
  - ✅ 邮箱验证码发送
  - ✅ Token 持久化存储

#### 前端实现
- **LoginActivity**: 登录页面
  - Material Design 3 UI
  - 表单验证
  - Loading 状态管理
  - 自动跳转
  
- **RegisterActivity**: 注册页面
  - 用户名/邮箱/密码输入
  - 验证码发送（60秒倒计时）
  - 实时表单验证

- **AuthRepository**: 认证数据仓库
  - 所有 API 调用封装
  - Token 管理
  - SharedPreferences 持久化

### 2. 自动订阅管理

#### 登录后自动获取订阅
- 用户登录成功后自动调用订阅 API
- 获取用户的 universal_url 和到期时间
- 保存到 SharedPreferences

#### 订阅自动添加
- MainActivity 启动时检查是否有订阅
- 自动创建订阅组（名称显示到期时间）
- 自动更新订阅内容
- 避免重复添加

### 3. UI 改进

#### 启动流程
1. 应用启动
2. 检查认证状态
3. 未登录 → 跳转登录页
4. 已登录 → 进入主页 → 自动添加订阅

#### 侧边菜单
- 新增"退出登录"菜单项
- 点击后弹出确认对话框
- 清除所有认证和订阅信息
- 返回登录页

## 📁 修改的文件

### 新增文件

1. **认证模型**
   - `app/src/main/java/io/nekohasekai/sagernet/auth/AuthModels.kt`
   - 数据类定义（LoginRequest, RegisterRequest, AuthState 等）

2. **认证仓库**
   - `app/src/main/java/io/nekohasekai/sagernet/auth/AuthRepository.kt`
   - API 调用、Token 管理、持久化

3. **登录页面**
   - `app/src/main/java/io/nekohasekai/sagernet/ui/LoginActivity.kt`
   - `app/src/main/res/layout/activity_login.xml`

4. **注册页面**
   - `app/src/main/java/io/nekohasekai/sagernet/ui/RegisterActivity.kt`
   - `app/src/main/res/layout/activity_register.xml`

### 修改文件

1. **AndroidManifest.xml**
   - 添加 LoginActivity 和 RegisterActivity 声明

2. **MainActivity.kt**
   - 添加启动时认证检查
   - 添加自动订阅管理功能
   - 添加退出登录处理

3. **main_drawer_menu.xml**
   - 添加"退出登录"菜单项

## 🔧 技术实现细节

### 认证流程

```kotlin
// 1. 用户登录
authRepository.login(email, password)
  ↓
// 2. 保存 Token
saveToken(token)
  ↓
// 3. 获取订阅
authRepository.getUserSubscription()
  ↓
// 4. 保存订阅信息
SharedPreferences.edit().putString("subscription_url", url)
  ↓
// 5. 跳转主页
navigateToMain()
```

### 订阅自动添加流程

```kotlin
// MainActivity.onCreate()
if (!authRepository.isAuthenticated()) {
    // 跳转登录页
    startActivity(Intent(this, LoginActivity::class.java))
} else {
    // 检查并添加订阅
    checkAndAddSubscription()
}

// checkAndAddSubscription()
val subscriptionUrl = prefs.getString("subscription_url", null)
if (!subscriptionUrl.isNullOrEmpty()) {
    val subscription = SubscriptionBean().apply {
        name = "到期: $expireTime"
        link = subscriptionUrl
    }
    GroupManager.createGroup(subscription)
    GroupUpdater.startUpdate(subscription, true)
}
```

### 数据持久化

#### auth_prefs (SharedPreferences)
- `auth_token`: JWT Token
- `user_email`: 用户邮箱
- `user_username`: 用户名

#### subscription_prefs (SharedPreferences)
- `has_subscription`: 是否有订阅
- `subscription_url`: 订阅 URL
- `expire_time`: 到期时间

## 🚀 构建说明

### 环境要求
- Android Studio Arctic Fox 或更高版本
- JDK 11 或更高版本
- Android SDK 21+
- Kotlin 1.8+

### 构建步骤

```bash
cd /Users/apple/Downloads/NekoBoxForAndroid

# 1. 清理项目
./gradlew clean

# 2. 构建 Debug APK
./gradlew assembleDebug

# 3. 构建 Release APK（需要签名配置）
./gradlew assembleRelease
```

### 输出位置
- Debug APK: `app/build/outputs/apk/debug/app-debug.apk`
- Release APK: `app/build/outputs/apk/release/app-release.apk`

## ✅ 功能测试清单

### 登录功能
- [ ] 打开应用显示登录页
- [ ] 输入邮箱密码登录
- [ ] 登录成功自动获取订阅
- [ ] 登录成功跳转主页

### 注册功能
- [ ] 点击"立即注册"进入注册页
- [ ] 发送验证码（60秒倒计时）
- [ ] 注册成功返回登录页

### 订阅管理
- [ ] 登录后自动添加订阅
- [ ] 订阅名称显示到期时间
- [ ] 订阅自动更新

### 退出登录
- [ ] 侧边菜单显示"退出登录"
- [ ] 点击弹出确认对话框
- [ ] 确认后清除数据并返回登录页

## 🎨 UI 截图位置

登录页面: `activity_login.xml`
- Logo 居中
- 邮箱输入框
- 密码输入框
- 登录按钮
- 注册链接

注册页面: `activity_register.xml`
- 用户名输入框
- 邮箱输入框
- 密码输入框
- 验证码输入框 + 发送按钮
- 注册按钮

## 📝 注意事项

1. **网络权限**: 已在 AndroidManifest.xml 中声明
2. **API 地址**: 硬编码为 `https://dy.moneyfly.top`，可根据需要修改
3. **Token 过期**: 当前未实现自动刷新，需要重新登录
4. **订阅更新**: 使用 NekoBox 原有的 GroupUpdater 机制
5. **错误处理**: 所有 API 调用都有 try-catch 和错误提示

## 🔄 与原版的区别

| 功能 | 原版 NekoBox | 修改版 |
|------|-------------|--------|
| 启动流程 | 直接进入主页 | 先检查登录状态 |
| 订阅管理 | 手动添加 | 登录后自动添加 |
| 用户系统 | 无 | 完整的认证系统 |
| 订阅命名 | 手动输入 | 自动显示到期时间 |

## 🎯 后续改进建议

1. **Token 自动刷新**: 实现 Token 过期自动刷新机制
2. **忘记密码**: 添加忘记密码功能
3. **订阅定时更新**: 实现订阅自动定时更新
4. **多账号支持**: 支持切换多个账号
5. **订阅详情**: 显示流量使用情况
6. **生物识别**: 添加指纹/面部识别登录

## 📞 技术支持

如有问题，请查看：
- NekoBox 原项目: https://github.com/MatsuriDayo/NekoBoxForAndroid
- Hiddify 参考项目: https://github.com/hiddify/hiddify-next

---

**修改完成时间**: 2025-12-31
**修改版本**: v1.0.0
**基于版本**: NekoBox for Android latest

