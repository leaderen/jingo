# JinGo VPN

跨平台 VPN 客户端，基于 Qt 6 和 Xray 核心构建。

## 特性

- **跨平台支持**: Android、iOS、macOS、Windows、Linux
- **现代化界面**: Qt 6 QML 构建的流畅用户界面
- **多协议支持**: 基于 Xray 核心，支持 VMess、VLESS、Trojan、Shadowsocks 等
- **多语言**: 支持 8 种语言（中文、英文、越南语、高棉语、缅甸语、俄语、波斯语等）
- **白标定制**: 支持品牌定制和多租户部署

## 项目架构

```
JinGo/
├── CMakeLists.txt              # 主 CMake 配置
├── cmake/                      # CMake 模块
│   ├── Platform-Android.cmake  # Android 平台配置
│   ├── Platform-iOS.cmake      # iOS 平台配置
│   ├── Platform-macOS.cmake    # macOS 平台配置
│   ├── Platform-Linux.cmake    # Linux 平台配置
│   └── Platform-Windows.cmake  # Windows 平台配置
│
├── src/                        # C++ 源代码
│   ├── main.cpp               # 应用入口
│   ├── platform/              # 平台适配层
│   │   ├── android/           # Android 特定实现
│   │   ├── linux/             # Linux 特定实现
│   │   └── windows/           # Windows 特定实现
│   ├── extensions/            # 系统扩展
│   │   └── PacketTunnelProvider/  # iOS/macOS 网络扩展
│   └── utils/                 # 工具类
│
├── resources/                  # 资源文件
│   ├── qml/                   # QML 界面
│   │   ├── Main.qml           # 主界面
│   │   ├── pages/             # 页面组件
│   │   ├── components/        # 通用组件
│   │   └── dialogs/           # 对话框组件
│   ├── translations/          # 多语言翻译文件 (*.ts)
│   ├── icons/                 # 应用图标
│   ├── images/                # 图片资源
│   ├── fonts/                 # 字体文件
│   ├── flags/                 # 国旗图标
│   └── geoip/                 # GeoIP 数据库
│
├── platform/                   # 平台特定配置
│   ├── android/               # Android 配置
│   │   ├── AndroidManifest.xml
│   │   ├── src/               # Java/Kotlin 代码
│   │   ├── res/               # Android 资源
│   │   └── keystore/          # 签名密钥
│   ├── ios/                   # iOS 配置
│   │   ├── Info.plist
│   │   ├── Assets.xcassets/   # iOS 资源目录
│   │   └── cert/              # 证书文件
│   ├── macos/                 # macOS 配置
│   │   └── cert/              # 证书文件
│   ├── linux/                 # Linux 配置
│   │   ├── debian/            # Debian 打包配置
│   │   └── icons/             # 桌面图标
│   └── windows/               # Windows 配置
│
├── third_party/               # 第三方依赖
│   ├── jindo/                 # JinDo 核心库
│   │   ├── android/           # Android 静态库
│   │   ├── apple/             # iOS/macOS xcframework
│   │   ├── linux/             # Linux 静态库
│   │   └── windows/           # Windows 静态库
│   ├── superray/              # SuperRay (Xray 封装库)
│   │   ├── android/
│   │   ├── apple/
│   │   ├── linux/
│   │   └── windows/
│   ├── android_openssl/       # Android OpenSSL 库
│   ├── apple_openssl/         # iOS/macOS OpenSSL 库
│   ├── linux_openssl/         # Linux OpenSSL 库
│   ├── windows_openssl/       # Windows OpenSSL 库
│   └── wintun/                # Windows TUN 驱动
│
├── scripts/                   # 脚本工具
│   ├── build/                 # 构建脚本
│   │   ├── build-android.sh
│   │   ├── build-ios.sh
│   │   ├── build-macos.sh
│   │   ├── build-linux.sh
│   │   └── build-windows.ps1
│   └── signing/               # 签名脚本
│
├── white-labeling/            # 白标品牌配置
│   ├── 1/                     # 品牌 1
│   │   ├── bundle_config.json # 品牌配置
│   │   └── icons/             # 品牌图标
│   ├── 2/                     # 品牌 2
│   └── .../
│
├── docs/                      # 文档
└── release/                   # 构建输出目录
```

## 快速开始

### 前置条件

- **Qt**: 6.5+ (推荐 6.8.1 LTS 或 6.10.0)
- **CMake**: 3.21+
- **编译器**:
  - macOS/iOS: Xcode 15+
  - Android: NDK 27.2+
  - Windows: MinGW 13+ 或 Visual Studio 2022
  - Linux: GCC 11+ 或 Clang 14+

### 编译步骤

#### 1. Fork 仓库并配置白标

```bash
# 1. Fork 本仓库到自己的 GitHub 账号

# 2. Clone 你的 fork
git clone https://github.com/YOUR_USERNAME/JinGo.git
cd JinGo

# 3. 创建你的白标配置
# 复制模板到新的品牌目录
cp -r white-labeling/1 white-labeling/YOUR_BRAND

# 4. 修改白标配置文件
# 编辑 white-labeling/YOUR_BRAND/bundle_config.json
{
    "panel_url": "https://your-api-server.com",
    "app_name": "YourApp",
    "support_email": "support@your-domain.com",
    ...
}

# 5. 替换应用图标
# 将你的图标放入 white-labeling/YOUR_BRAND/icons/
#   - app.png (1024x1024, 通用图标)
#   - app.icns (macOS 图标)
#   - app.ico (Windows 图标)
#   - ios/ (iOS 各尺寸图标)
#   - android/ (Android 各密度图标)
```

#### 2. 编译应用

所有构建脚本都在 `scripts/build/` 目录下：

```bash
# Android APK
./scripts/build/build-android.sh --release --abi arm64-v8a
# 或编译全架构
./scripts/build/build-android.sh --release --abi all

# macOS App (Universal Binary: arm64 + x86_64)
./scripts/build/build-macos.sh --release

# iOS App (生成 IPA)
./scripts/build/build-ios.sh --release

# Linux
./scripts/build/build-linux.sh --release

# Windows (PowerShell)
.\scripts\build\build-windows.ps1
```

#### 3. 指定白标品牌编译

```bash
# 使用 --brand 参数指定品牌目录
./scripts/build/build-macos.sh --release --brand YOUR_BRAND
./scripts/build/build-android.sh --release --brand YOUR_BRAND
./scripts/build/build-ios.sh --release --brand YOUR_BRAND
```

#### 4. GitHub Actions 自动构建

项目包含 GitHub Actions 工作流 (`.github/workflows/build.yml`)：

1. 进入你的 GitHub 仓库 → Actions → Build All Platforms
2. 点击 "Run workflow"
3. 选择品牌 ID 和构建类型
4. 等待构建完成，下载 Artifacts

### 输出位置

| 平台 | 输出文件 | 位置 |
|------|---------|------|
| Android | APK | `release/jingo-*-android.apk` |
| macOS | DMG | `release/jingo-*-macos.dmg` |
| iOS | IPA | `release/jingo-*-ios.ipa` |
| Windows | EXE/MSI | `release/jingo-*-windows.exe` |
| Linux | tar.gz | `release/jingo-*-linux.tar.gz` |

## 平台支持

| 平台 | 架构 | 最低版本 | 状态 |
|------|------|---------|------|
| Android | arm64-v8a, armeabi-v7a, x86_64 | API 28 (Android 9) | ✅ |
| iOS | arm64 | iOS 15.0 | ✅ |
| macOS | arm64, x86_64 | macOS 12.0 | ✅ |
| Windows | x64 | Windows 10 | ✅ |
| Linux | x64 | Ubuntu 20.04+ | ✅ |

## 文档

详细文档请查看 [docs/](docs/) 目录：

- [架构说明](docs/01_ARCHITECTURE.md)
- [构建指南](docs/02_BUILD_GUIDE.md)
- [开发指南](docs/03_DEVELOPMENT.md)
- [白标定制](docs/04_WHITE_LABELING.md)
- [故障排除](docs/05_TROUBLESHOOTING.md)

- [平台指南](docs/06_PLATFORMS.md) - Android、iOS、macOS、Windows、Linux 构建指南

## 多语言支持

| 语言 | 代码 | 状态 |
|------|------|------|
| English | en_US | ✅ |
| 简体中文 | zh_CN | ✅ |
| 繁體中文 | zh_TW | ✅ |
| Tiếng Việt | vi_VN | ✅ |
| ភាសាខ្មែរ | km_KH | ✅ |
| မြန်မာဘာသာ | my_MM | ✅ |
| Русский | ru_RU | ✅ |
| فارسی | fa_IR | ✅ |

## 技术栈

- **UI 框架**: Qt 6.10.0+ (QML/Quick)
- **VPN 核心**: Xray-core (通过 SuperRay 封装)
- **网络**: Qt Network + OpenSSL
- **存储**: SQLite (Qt SQL)
- **安全存储**:
  - macOS/iOS: Keychain
  - Android: EncryptedSharedPreferences
  - Windows: DPAPI
  - Linux: libsecret

## 构建选项

### CMake 选项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `USE_JINDO_LIB` | ON | 使用 JinDoCore 静态库 |
| `JINDO_ROOT` | `../JinDo` | JinDo 项目路径 |
| `CMAKE_BUILD_TYPE` | Debug | 构建类型 (Debug/Release) |

### 构建脚本选项

```bash
# 通用选项
--clean          # 清理构建目录
--release        # Release 模式
--debug          # Debug 模式

# Android 特定
--abi <ABI>      # 指定架构 (arm64-v8a/armeabi-v7a/x86_64/all)
--sign           # 签名 APK

# macOS/iOS 特定
--notarize       # 公证应用

# Linux 特定
--deploy         # 部署 Qt 依赖
--package        # 创建安装包
```

## 开发

### 代码风格

- C++17 标准
- Qt 编码规范
- 使用 `clang-format` 格式化

### 调试

```bash
# 启用详细日志
QT_LOGGING_RULES="*.debug=true" ./JinGo

# Android logcat
adb logcat -s JinGo:V SuperRay-JNI:V
```

## 许可证

MIT License

---

**版本**: 1.0.0
**Qt 版本**: 6.5+ (推荐 6.8.1 LTS)
**最后更新**: 2026-01
