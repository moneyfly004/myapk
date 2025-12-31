# NekoBox for Android

[![API](https://img.shields.io/badge/API-21%2B-brightgreen.svg?style=flat)](https://android-arsenal.com/api?level=21)
[![Releases](https://img.shields.io/github/v/release/moneyfly004/myapk)](https://github.com/moneyfly004/myapk/releases)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-orange.svg)](https://www.gnu.org/licenses/gpl-3.0)

sing-box / universal proxy toolchain for Android.

A universal proxy tool for Android using sing-box.

## Downloads

[![GitHub All Releases](https://img.shields.io/github/downloads/moneyfly004/myapk/total?label=downloads-total&logo=github&style=flat-square)](https://github.com/moneyfly004/myapk/releases)

[GitHub Releases](https://github.com/moneyfly004/myapk/releases)

**⚠️ Warning: The Google Play version has been controlled by a third party since May 2024 and is a non-open source version. Please do not download it.**

## Changelog & Telegram Channel

https://t.me/Matsuridayo

## Homepage & Documents

https://matsuridayo.github.io

## Supported Proxy Protocols

* SOCKS (4/4a/5)
* HTTP(S)
* SSH
* Shadowsocks
* VMess
* Trojan
* VLESS
* AnyTLS
* ShadowTLS
* TUIC
* Hysteria 1/2
* WireGuard
* Trojan-Go (trojan-go-plugin)
* NaïveProxy (naive-plugin)
* Mieru (mieru-plugin)

Please visit [here](https://matsuridayo.github.io/nb4a-plugin/) to download plugins for full proxy supports.

## Supported Subscription Format

* Some widely used formats (like Shadowsocks, ClashMeta and v2rayN)
* sing-box outbound

Only resolving outbound, i.e. nodes, is supported. Information such as diversion rules are ignored.

## Key Modifications

This fork includes the following enhancements:

### User Authentication System
- **Login/Register/Forgot Password**: Complete user authentication flow with email verification
- **Token Management**: Secure token storage and automatic refresh
- **Backend Integration**: Full integration with RESTful API backend

### Subscription Management
- **Automatic Subscription**: Auto-add and manage user subscriptions
- **Subscription Info Display**: Show subscription expiration and device limits
- **Node Management**: Automatic node selection based on latency, with manual selection option

### UI/UX Improvements
- **Improved Text Sizing**: Better readability on mobile devices
- **Material Design**: Consistent Material Design 3 theming
- **Navigation Fixes**: Resolved navigation loops and share intent issues

### Build & CI/CD
- **GitHub Actions**: Automated release builds on tag push
- **Auto Release**: Automatic GitHub Releases creation with APK artifacts
- **Manual Build**: Support for manual workflow dispatch

### Bug Fixes
- Fixed layout inflation crashes on Android 10
- Resolved Intent handling issues preventing share dialog
- Fixed color compatibility issues
- Improved node selection and click handling

## Building

### Prerequisites
- Android SDK (API 21+)
- Android NDK (r25.0.8775105 or compatible)
- Go 1.25+ (for libcore)
- Java Development Kit

### Build Steps

1. **Build libcore**:
   ```bash
   cd libcore
   ./build.sh
   ```

2. **Build APK**:
   ```bash
   ./gradlew app:assembleOssRelease
   ```

For detailed build instructions, refer to the original repository documentation.

## Release Build

### Automatic Release (Recommended)
Push a tag starting with `v` to trigger automatic build and release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Manual Release
1. Go to GitHub Actions
2. Select "Release Build" workflow
3. Click "Run workflow"
4. Enter release tag (e.g., `v1.0.0`)

The workflow will automatically:
- Build the APK
- Create a GitHub Release
- Upload all APK files

### GitHub Token Setup (Optional)
If you encounter permission issues, you can add a custom token:
1. Create a Personal Access Token with `repo` permissions
2. Add it as a repository secret named `RELEASE_TOKEN`
3. The workflow will use it automatically

## Donate

<details>

If this project is helpful to you, you can help us maintain it through donations.

Donations of 50 USD or more can display your avatar on the [Donation List](https://mtrdnt.pages.dev/donation_list). If you are not added here, please contact us to add it.

**USDT TRC20**
```
TRhnA7SXE5Sap5gSG3ijxRmdYFiD4KRhPs
```

**XMR**
```
49bwESYQjoRL3xmvTcjZKHEKaiGywjLYVQJMUv79bXonGiyDCs8AzE3KiGW2ytTybBCpWJUvov8SjZZEGg66a4e59GXa6k5
```

</details>

## Similar Projects (sing-box based)

### Open Source Projects with Simple UI & Big Connect Button

**Recommended for easy modification:**

1. **Hiddify App** ⭐ (Most Similar)
   - GitHub: [hiddify/hiddify-next](https://github.com/hiddify/hiddify-next)
   - **Open Source**: ✅ Yes
   - **UI**: Simple, clean interface with prominent connect button
   - **Platforms**: Windows, Android, iOS, macOS, Linux
   - **Features**: Cross-platform, Clash subscription support, easy to customize
   - **Best for**: Projects requiring simple UI and easy modification

2. **SagerNet**
   - GitHub: [SagerNet/SagerNet](https://github.com/SagerNet/SagerNet)
   - **Open Source**: ✅ Yes
   - **UI**: Full-featured with advanced configuration options
   - **Platforms**: Android
   - **Features**: Comprehensive proxy management, highly customizable

3. **NekoRay** (Desktop)
   - GitHub: [MatsuriDayo/nekoray](https://github.com/MatsuriDayo/nekoray)
   - **Open Source**: ✅ Yes
   - **UI**: User-friendly GUI with simple interface
   - **Platforms**: Windows, Linux, macOS
   - **Features**: Cross-platform desktop client (formerly NekoBox for PC)

### Other Open Source Projects

4. **Karing / KaringX** ⭐ (Highly Recommended)
   - **Open Source**: ✅ Yes
   - **UI**: Simple, clean interface with prominent connect button
   - **Platforms**: Windows, macOS, Android, iOS, Apple TV
   - **Features**: Compatible with Clash and sing-box, supports multiple protocols (Shadowsocks, VMess, Trojan, Hysteria, etc.)
   - **Best for**: Cross-platform projects with simple UI requirements
   - **Note**: Flutter-based, easy to modify and customize

5. **OneBox** ⭐ (Highly Recommended)
   - **Open Source**: ✅ Yes
   - **UI**: Minimalist design with "simplicity first" philosophy
   - **Platforms**: Windows, macOS, Ubuntu
   - **Features**: Focus on core functionality, instant usability, reduced learning curve
   - **Best for**: Desktop projects requiring minimal UI

6. **SFA (Sing-box For Android)**
   - **Open Source**: ✅ Yes
   - **UI**: Clean UI with multi-protocol support
   - **Platforms**: Android
   - **Features**: Multi-protocol support, lightweight

7. **GUI for SingBox** (Windows)
   - **Open Source**: ✅ Yes (check repository)
   - **UI**: Simple graphical interface
   - **Platforms**: Windows
   - **Features**: Supports most proxy protocols (Shadowsocks, VMess, VLESS, Reality, Trojan, Hysteria2, etc.)

### Comparison Table

| Project | Open Source | Simple UI | Big Connect Button | Easy to Modify | Android Support | Cross-Platform | Language/Framework |
|---------|------------|-----------|-------------------|----------------|-----------------|----------------|-------------------|
| **Hiddify App** ⭐ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (All) | Flutter + Go |
| **Karing/KaringX** ⭐ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (All) | Flutter |
| **OneBox** ⭐ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ (Desktop) | - |
| **NekoRay** | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ (Desktop) | Qt/C++ |
| **SagerNet** | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | ❌ | Kotlin/Java |
| **SFA** | ✅ | ✅ | ⚠️ | ✅ | ✅ | ❌ | Kotlin/Java |
| **GUI for SingBox** | ✅ | ✅ | ✅ | ⚠️ | ❌ | ❌ (Windows) | - |

### GitHub Repository Links

**Verified Open Source Repositories:**

1. **Hiddify App**: [hiddify/hiddify-next](https://github.com/hiddify/hiddify-next)
2. **SagerNet**: [SagerNet/SagerNet](https://github.com/SagerNet/SagerNet)
3. **NekoRay**: [MatsuriDayo/nekoray](https://github.com/MatsuriDayo/nekoray)
4. **sing-box Core**: [SagerNet/sing-box](https://github.com/SagerNet/sing-box)

**Note**: 
- **Hiddify App** and **Karing/KaringX** are the most similar to your requirements with simple UI, prominent connect button, and easy modification capabilities (both Flutter-based).
- **OneBox** is excellent for desktop projects with minimalist design philosophy.
- For Android-specific projects, **Hiddify App** and **Karing** are the best choices.

## Credits

**Core:**
- [SagerNet/sing-box](https://github.com/SagerNet/sing-box)

**Android GUI:**
- [shadowsocks/shadowsocks-android](https://github.com/shadowsocks/shadowsocks-android)
- [SagerNet/SagerNet](https://github.com/SagerNet/SagerNet)

**Web Dashboard:**
- [Yacd-meta](https://github.com/MetaCubeX/Yacd-meta)

## License

GPL-3.0
