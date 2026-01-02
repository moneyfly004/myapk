# Android 到 Windows 桌面应用迁移指南

## 概述
将 NekoBoxForAndroid 迁移到 Windows 桌面应用需要大量的架构调整。本文档详细说明了需要做的所有调整。

---

## 一、技术栈选择

### 推荐方案对比

#### 方案1：Electron + React/Vue（推荐）
**优点：**
- 跨平台，代码复用率高
- 丰富的UI库和生态系统
- 易于维护和更新
- 可以使用现有的Web技术栈

**缺点：**
- 应用体积较大（~100MB+）
- 内存占用较高
- 需要重新实现VPN功能

**技术栈：**
- Electron
- React + TypeScript
- Node.js 后端服务（处理VPN）
- SQLite（替代Room数据库）

#### 方案2：Flutter Desktop
**优点：**
- 跨平台，一套代码多端运行
- 性能较好
- 可以使用Dart语言

**缺点：**
- Windows VPN实现较复杂
- 生态系统相对较小
- 需要学习Dart

**技术栈：**
- Flutter Desktop
- Dart
- Windows VPN API（通过FFI调用）

#### 方案3：.NET MAUI / WPF
**优点：**
- 原生Windows体验
- 性能优秀
- 完整的Windows API支持

**缺点：**
- 需要学习C#
- 跨平台能力有限
- 需要重写大部分代码

**技术栈：**
- .NET 6/7/8
- C#
- WPF 或 MAUI
- Windows VPN API

#### 方案4：Qt + C++/QML
**优点：**
- 性能优秀
- 跨平台
- 原生体验

**缺点：**
- 开发复杂度高
- 需要C++知识
- 许可证问题（商业使用需付费）

---

## 二、核心功能迁移清单

### 1. VPN功能实现（最关键）

#### Android实现：
```kotlin
// 使用 Android VpnService API
class VpnService : BaseVpnService() {
    var conn: ParcelFileDescriptor? = null
    // 创建TUN接口
}
```

#### Windows实现选项：

**选项A：使用TAP-Windows驱动**
```csharp
// C# 示例
using OpenVPN.Net;
// 或使用 TAP-Windows Adapter
// 需要安装TAP驱动，创建虚拟网卡
```

**选项B：使用Windows VPN API（Windows 10+）**
```csharp
// 使用 Windows.Networking.Vpn 命名空间
using Windows.Networking.Vpn;
// 需要管理员权限
```

**选项C：使用第三方库**
- OpenVPN客户端库
- WireGuard Windows实现
- 自定义TUN/TAP实现

**推荐实现：**
- 使用Go语言编写的libcore（项目已有）
- 通过CGO编译为Windows DLL
- 在Electron/Node.js中通过FFI调用
- 或使用TAP-Windows驱动创建虚拟网卡

### 2. 网络代理核心（libcore）

#### 当前实现：
- Go语言编写的libcore
- 已支持Android（通过gomobile）
- 包含代理协议实现（V2Ray、Trojan、Shadowsocks等）

#### Windows调整：
```go
// libcore/platform_windows.go
// 需要添加Windows平台特定实现
// 1. 网络接口管理
// 2. 路由表操作
// 3. DNS配置
// 4. 系统代理设置
```

**需要实现的功能：**
- Windows网络接口枚举和管理
- 路由表操作（route add/delete）
- DNS服务器配置（netsh或注册表）
- 系统代理设置（注册表或WinHTTP API）
- 防火墙规则管理

### 3. UI框架迁移

#### Android UI组件 → Windows UI组件

| Android组件 | Windows替代方案 |
|------------|----------------|
| Activity | Window/Page |
| Fragment | UserControl/Component |
| RecyclerView | ListView/DataGrid |
| MaterialButton | Button |
| MaterialCardView | Card/Panel |
| ViewPager2 | TabControl |
| NavigationView | MenuBar/Sidebar |
| Snackbar | Toast/Notification |
| AlertDialog | MessageBox/Dialog |

#### 布局系统迁移

**Android XML布局：**
```xml
<LinearLayout>
    <TextView />
    <Button />
</LinearLayout>
```

**Electron/React：**
```jsx
<div>
    <p>Text</p>
    <button>Button</button>
</div>
```

**Flutter：**
```dart
Column(
  children: [
    Text('Text'),
    ElevatedButton(...),
  ],
)
```

### 4. 数据存储迁移

#### Android Room数据库 → Windows数据库

**选项A：SQLite（推荐）**
```javascript
// Electron中使用better-sqlite3
const Database = require('better-sqlite3');
const db = new Database('app.db');
```

**选项B：IndexedDB（Electron）**
```javascript
// 浏览器API，Electron支持
const db = indexedDB.open('appDB');
```

**选项C：SQL Server LocalDB（.NET）**
```csharp
// .NET中使用Entity Framework
using Microsoft.EntityFrameworkCore;
```

**数据迁移步骤：**
1. 导出Android Room数据库（SQLite格式）
2. 转换表结构（如有差异）
3. 导入到Windows数据库
4. 更新数据访问层代码

### 5. 文件系统访问

#### Android：
```kotlin
// Context.getFilesDir()
val file = File(context.filesDir, "config.json")
```

#### Windows：
```javascript
// Electron
const { app } = require('electron');
const path = require('path');
const userDataPath = app.getPath('userData');
const configPath = path.join(userDataPath, 'config.json');
```

```csharp
// .NET
string appDataPath = Environment.GetFolderPath(
    Environment.SpecialFolder.ApplicationData);
string configPath = Path.Combine(appDataPath, "AppName", "config.json");
```

### 6. 系统集成功能

#### 6.1 系统托盘
**Android：** 通知栏
**Windows：**
```javascript
// Electron
const { Tray, Menu } = require('electron');
const tray = new Tray('icon.ico');
tray.setContextMenu(Menu.buildFromTemplate([...]));
```

#### 6.2 开机自启动
**Android：** BroadcastReceiver监听开机
**Windows：**
```javascript
// Electron使用auto-launch
const AutoLaunch = require('auto-launch');
const autoLauncher = new AutoLaunch({
    name: 'AppName',
    path: app.getPath('exe'),
});
```

#### 6.3 系统通知
**Android：** NotificationManager
**Windows：**
```javascript
// Electron
const { Notification } = require('electron');
new Notification({ title: 'Title', body: 'Message' }).show();
```

#### 6.4 权限管理
**Android：** 运行时权限请求
**Windows：** 
- 管理员权限（UAC提示）
- 网络权限（防火墙）
- VPN权限（需要管理员）

### 7. 网络请求库

#### Android：
```kotlin
// OkHttp / Retrofit
val client = OkHttpClient()
```

#### Windows：
```javascript
// Electron/Node.js
const axios = require('axios');
// 或使用fetch API
```

```csharp
// .NET
using System.Net.Http;
var client = new HttpClient();
```

### 8. 二维码生成/扫描

#### Android：
```kotlin
// ZXing库
MultiFormatWriter().encode(url, BarcodeFormat.QR_CODE, ...)
```

#### Windows：
```javascript
// Electron
const QRCode = require('qrcode');
QRCode.toDataURL(url, (err, url) => { ... });
```

### 9. WebView功能

#### Android：
```kotlin
// WebView组件
webView.loadUrl(url)
```

#### Windows：
```javascript
// Electron
const { BrowserView } = require('electron');
const view = new BrowserView();
view.webContents.loadURL(url);
```

---

## 三、详细迁移步骤

### 阶段1：项目初始化（1-2周）

1. **选择技术栈**
   - 推荐：Electron + React + TypeScript
   - 或：Flutter Desktop

2. **创建新项目结构**
   ```
   windows-app/
   ├── src/
   │   ├── main/          # 主进程（Electron）
   │   ├── renderer/      # 渲染进程（UI）
   │   └── shared/        # 共享代码
   ├── libcore/           # Go核心库（复用）
   ├── resources/         # 资源文件
   └── build/            # 构建配置
   ```

3. **设置构建系统**
   - Electron: electron-builder
   - Flutter: flutter build windows
   - .NET: MSBuild / dotnet publish

### 阶段2：核心功能迁移（4-6周）

1. **libcore Windows适配**
   - 编译Go代码为Windows DLL
   - 实现Windows平台特定功能
   - 网络接口管理
   - 路由和DNS配置

2. **VPN功能实现**
   - 集成TAP-Windows驱动
   - 实现虚拟网卡创建
   - 实现流量转发
   - 实现路由规则

3. **数据层迁移**
   - 数据库迁移（Room → SQLite）
   - 数据访问层重写
   - 配置文件格式统一

### 阶段3：UI迁移（3-4周）

1. **页面迁移**
   - 主界面
   - 配置页面
   - 节点列表
   - 设置页面
   - 关于页面
   - 套餐购买页面

2. **组件迁移**
   - 按钮、输入框、列表等基础组件
   - 对话框、菜单等交互组件
   - 主题和样式系统

3. **导航系统**
   - 路由系统
   - 页面切换动画
   - 状态管理

### 阶段4：功能完善（2-3周）

1. **系统集成**
   - 系统托盘
   - 开机自启动
   - 系统通知
   - 右键菜单

2. **用户体验优化**
   - 启动速度优化
   - 内存占用优化
   - 错误处理
   - 日志系统

3. **测试和调试**
   - 单元测试
   - 集成测试
   - 性能测试
   - 兼容性测试

### 阶段5：打包和发布（1周）

1. **应用打包**
   - 代码签名
   - 安装程序制作
   - 自动更新机制

2. **发布准备**
   - 应用图标和资源
   - 用户文档
   - 更新日志

---

## 四、关键技术实现细节

### 1. Windows VPN实现（使用TAP驱动）

```go
// libcore/platform_windows.go
package libcore

/*
#include <windows.h>
#include <winioctl.h>
*/
import "C"
import (
    "unsafe"
    "syscall"
)

// 创建TAP接口
func CreateTAPInterface() (*TAPInterface, error) {
    // 1. 打开TAP设备
    // 2. 设置IP地址
    // 3. 启用接口
    // 4. 配置路由
}

// 配置路由
func ConfigureRoute(interfaceName string, routes []string) error {
    // 使用Windows route命令或WinAPI
}
```

### 2. Electron主进程VPN服务

```javascript
// main/vpn-service.js
const { exec } = require('child_process');
const ffi = require('ffi-napi');
const ref = require('ref-napi');

// 加载libcore DLL
const libcore = ffi.Library('./libcore.dll', {
    'CreateTAPInterface': ['int', []],
    'StartVPN': ['int', ['string']],
    'StopVPN': ['void', []],
});

class VPNService {
    async start(config) {
        // 1. 创建TAP接口
        // 2. 启动代理服务
        // 3. 配置路由
        // 4. 设置系统代理
    }
    
    async stop() {
        // 清理资源
    }
}
```

### 3. 系统代理设置

```javascript
// main/proxy-service.js
const { exec } = require('child_process');
const Registry = require('winreg');

class ProxyService {
    async setSystemProxy(host, port) {
        // 方法1：使用注册表
        const regKey = new Registry({
            hive: Registry.HKCU,
            key: '\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings'
        });
        
        regKey.set('ProxyEnable', Registry.REG_DWORD, 1, (err) => {
            regKey.set('ProxyServer', Registry.REG_SZ, `${host}:${port}`, () => {
                // 通知系统刷新
                this.refreshSystemProxy();
            });
        });
        
        // 方法2：使用netsh命令
        exec(`netsh winhttp set proxy ${host}:${port}`, (error) => {
            if (error) console.error(error);
        });
    }
    
    refreshSystemProxy() {
        // 发送WM_SETTINGCHANGE消息
        exec('rundll32.exe url.dll,FileProtocolHandler', () => {});
    }
}
```

### 4. 数据库迁移脚本

```javascript
// scripts/migrate-database.js
const Database = require('better-sqlite3');
const fs = require('fs');

function migrateFromAndroid(androidDbPath, windowsDbPath) {
    // 1. 读取Android SQLite数据库
    const androidDb = new Database(androidDbPath, { readonly: true });
    
    // 2. 创建Windows数据库
    const windowsDb = new Database(windowsDbPath);
    
    // 3. 创建表结构
    windowsDb.exec(`
        CREATE TABLE IF NOT EXISTS profiles (
            id INTEGER PRIMARY KEY,
            name TEXT,
            type TEXT,
            config TEXT
        );
        -- 其他表...
    `);
    
    // 4. 迁移数据
    const profiles = androidDb.prepare('SELECT * FROM profiles').all();
    const insert = windowsDb.prepare('INSERT INTO profiles VALUES (?, ?, ?, ?)');
    
    const transaction = windowsDb.transaction((profiles) => {
        for (const profile of profiles) {
            insert.run(profile.id, profile.name, profile.type, profile.config);
        }
    });
    
    transaction(profiles);
    
    androidDb.close();
    windowsDb.close();
}
```

---

## 五、项目结构建议

### Electron项目结构：
```
windows-app/
├── package.json
├── electron-builder.yml
├── src/
│   ├── main/
│   │   ├── main.js              # 主进程入口
│   │   ├── vpn-service.js       # VPN服务
│   │   ├── proxy-service.js      # 代理服务
│   │   ├── database.js          # 数据库
│   │   └── system-integration.js # 系统集成
│   ├── renderer/
│   │   ├── index.html
│   │   ├── main.jsx             # React入口
│   │   ├── components/          # React组件
│   │   ├── pages/               # 页面
│   │   ├── store/               # 状态管理
│   │   └── utils/               # 工具函数
│   └── shared/
│       ├── types.ts             # TypeScript类型
│       └── constants.ts         # 常量
├── libcore/
│   ├── go.mod
│   ├── platform_windows.go      # Windows平台实现
│   └── ...                      # 其他Go代码
├── resources/
│   ├── icons/
│   └── assets/
└── build/
    ├── windows/
    └── scripts/
```

---

## 六、依赖和工具

### Electron项目依赖：
```json
{
  "dependencies": {
    "electron": "^27.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "better-sqlite3": "^9.0.0",
    "axios": "^1.6.0",
    "qrcode": "^1.5.3",
    "auto-launch": "^5.0.5",
    "electron-updater": "^6.1.0"
  },
  "devDependencies": {
    "electron-builder": "^24.6.4",
    "typescript": "^5.3.0",
    "@types/node": "^20.10.0",
    "webpack": "^5.89.0",
    "react-scripts": "^5.0.1"
  }
}
```

### 需要安装的Windows组件：
1. **TAP-Windows驱动**
   - OpenVPN TAP驱动
   - 或 WireGuard TUN驱动

2. **Visual C++ Redistributable**
   - 用于运行Go编译的DLL

3. **.NET Runtime**（如果使用.NET方案）
   - .NET 6/7/8 Runtime

---

## 七、开发环境设置

### 1. 安装Node.js和npm
```bash
# 下载并安装Node.js LTS版本
# https://nodejs.org/
```

### 2. 安装Electron开发工具
```bash
npm install -g electron
npm install -g electron-builder
```

### 3. 安装Go语言（用于libcore）
```bash
# 下载并安装Go
# https://golang.org/dl/
```

### 4. 安装Windows SDK
- Visual Studio 2019/2022
- Windows 10/11 SDK
- C++ 构建工具

### 5. 安装TAP驱动
- 下载OpenVPN或WireGuard
- 安装时选择TAP驱动

---

## 八、构建和打包

### Electron构建配置：
```yaml
# electron-builder.yml
appId: com.yourcompany.appname
productName: AppName
directories:
  output: dist
files:
  - src/**/*
  - libcore/**/*
  - resources/**/*
win:
  target:
    - target: nsis
      arch:
        - x64
  icon: resources/icons/icon.ico
nsis:
  oneClick: false
  allowToChangeInstallationDirectory: true
```

### 构建命令：
```bash
# 开发模式
npm run dev

# 构建Windows安装包
npm run build:win

# 打包并签名
npm run build:win:sign
```

---

## 九、测试清单

### 功能测试：
- [ ] VPN连接/断开
- [ ] 节点切换
- [ ] 规则模式/全局模式
- [ ] 节点测速
- [ ] 订阅更新
- [ ] 套餐购买
- [ ] 支付流程
- [ ] 系统代理设置
- [ ] 开机自启动
- [ ] 系统托盘
- [ ] 通知功能

### 兼容性测试：
- [ ] Windows 10 (不同版本)
- [ ] Windows 11
- [ ] 不同分辨率
- [ ] 不同DPI设置
- [ ] 不同语言环境

### 性能测试：
- [ ] 启动时间
- [ ] 内存占用
- [ ] CPU占用
- [ ] 网络性能
- [ ] UI响应速度

---

## 十、常见问题和解决方案

### 1. 权限问题
**问题：** Windows需要管理员权限来创建VPN接口
**解决：** 
- 使用manifest文件请求管理员权限
- 或提示用户以管理员身份运行

### 2. 防火墙拦截
**问题：** Windows防火墙可能拦截应用
**解决：**
- 自动添加防火墙规则
- 或提示用户手动允许

### 3. 杀毒软件误报
**问题：** 某些杀毒软件可能误报VPN应用
**解决：**
- 代码签名
- 提交到杀毒软件厂商白名单

### 4. TAP驱动兼容性
**问题：** 不同版本的TAP驱动可能不兼容
**解决：**
- 使用稳定的TAP驱动版本
- 提供驱动安装指南

---

## 十一、时间估算

| 阶段 | 时间 | 说明 |
|------|------|------|
| 项目初始化 | 1-2周 | 技术选型、项目搭建 |
| 核心功能迁移 | 4-6周 | VPN、代理、数据库 |
| UI迁移 | 3-4周 | 界面、交互、样式 |
| 功能完善 | 2-3周 | 系统集成、优化 |
| 测试和修复 | 2-3周 | 测试、调试、修复 |
| 打包发布 | 1周 | 打包、签名、发布 |
| **总计** | **13-19周** | **约3-5个月** |

---

## 十二、推荐实施路径

### 快速原型（1-2周）
1. 使用Electron创建基础框架
2. 实现简单的UI界面
3. 集成libcore（基础功能）
4. 验证可行性

### 最小可行产品（MVP）（6-8周）
1. 核心VPN功能
2. 基本UI界面
3. 节点管理
4. 连接/断开功能

### 完整功能（12-16周）
1. 所有Android功能
2. 系统集成
3. 用户体验优化
4. 完整测试

---

## 总结

迁移到Windows桌面应用是一个大型项目，需要：
1. **技术选型**：推荐Electron + React
2. **核心功能**：VPN实现是关键，需要TAP驱动
3. **时间投入**：预计3-5个月
4. **团队配置**：至少需要前端、后端、测试各1人

建议先做快速原型验证可行性，再逐步完善功能。

