# NekoBox for Windows

基于 Flutter Desktop 的 Windows 版本 NekoBox 代理工具。

## 项目结构

```
windows_app/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── core/                        # 核心功能
│   │   ├── config/                  # 配置管理
│   │   ├── constants/               # 常量定义
│   │   └── utils/                   # 工具函数
│   ├── features/                    # 功能模块
│   │   ├── auth/                   # 认证模块
│   │   ├── connection/              # 连接管理
│   │   ├── node/                    # 节点管理
│   │   ├── subscription/            # 订阅管理
│   │   ├── settings/                # 设置
│   │   └── package/                 # 套餐购买
│   ├── widgets/                     # 通用组件
│   └── services/                    # 服务层
└── windows/                         # Windows 平台特定代码
```

## 开发环境要求

1. **Flutter SDK** (3.1.0+)
   ```bash
   flutter --version
   ```

2. **Windows 开发环境** (在 Windows 机器上)
   - Visual Studio 2019/2022
   - Windows 10/11 SDK
   - C++ 构建工具

3. **Go 语言** (用于编译 libcore)
   ```bash
   go version
   ```

## 构建步骤

### 1. 安装依赖

```bash
cd windows_app
flutter pub get
```

### 2. 运行开发版本

```bash
# 在 Windows 机器上运行
flutter run -d windows
```

### 3. 构建 Windows 应用

```bash
# 构建 Debug 版本
flutter build windows

# 构建 Release 版本
flutter build windows --release
```

构建产物位于：`build/windows/runner/Release/`

## 功能迁移进度

- [x] 项目初始化
- [x] 基础 UI 框架
- [x] 主界面布局
- [ ] 状态管理 (Riverpod)
- [ ] 数据存储 (SQLite)
- [ ] 网络请求 (Dio)
- [ ] libcore 集成 (Go FFI)
- [ ] VPN/代理连接
- [ ] 节点管理
- [ ] 订阅管理
- [ ] 系统托盘
- [ ] 开机自启动

## 下一步工作

1. **集成 libcore**
   - 编译 Go 代码为 Windows DLL
   - 通过 FFI 调用 Go 函数
   - 实现 VPN 连接功能

2. **实现状态管理**
   - 使用 Riverpod 管理应用状态
   - 连接状态、节点列表、用户信息等

3. **数据存储**
   - SQLite 数据库
   - 配置文件管理

4. **系统集成**
   - 系统托盘
   - 开机自启动
   - 系统通知

## 注意事项

- 当前项目在 macOS 上创建，需要在 Windows 机器上编译和运行
- libcore 需要编译为 Windows DLL
- VPN 功能需要管理员权限
- 某些 Windows 特定功能需要在 Windows 环境下测试

## 参考项目

- [Orange-custom](https://github.com/...) - Flutter Desktop VPN 客户端
- [Hiddify App](https://github.com/hiddify/hiddify-next) - 跨平台代理客户端
