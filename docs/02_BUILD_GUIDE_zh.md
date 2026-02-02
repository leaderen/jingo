# JinGo VPN - 构建指南

[English](02_BUILD_GUIDE.md)

## 快速开始

JinGo 的构建非常简单，只需要：

1. **安装 Qt 6.10+**（推荐 6.10.0 或更高版本）
2. **修改构建脚本中的 Qt 路径**（或使用自动检测）
3. **运行构建脚本**

所有依赖库（JinDoCore、OpenSSL、SuperRay 等）已预编译并包含在 `third_party/` 目录中。

> **注意**：Windows 平台的构建脚本已支持自动环境检测，无需手动配置路径。

## 依赖关系

```
JinGo (Qt 应用)
├── JinDoCore (静态库)      → third_party/jindo/
│   └── 核心业务逻辑、API 客户端、VPN 管理
│   └── 已合并 SuperRay (VPN 核心引擎/Xray)
├── SuperRay (动态库)       → Android 专用，JNI 动态链接
├── OpenSSL (静态库)        → third_party/*_openssl/
│   └── 加密支持
└── WinTun (Windows)        → third_party/wintun/
    └── Windows TUN 驱动
```

**所有依赖库已预编译，无需手动编译。**

## 目录结构

```
JinGo/
├── third_party/
│   ├── jindo/                    # JinDoCore 静态库 (核心)
│   │   ├── android/              # Android 各架构
│   │   ├── apple/                # macOS/iOS (XCFramework)
│   │   ├── linux/
│   │   └── windows/
│   ├── android_openssl/
│   ├── apple_openssl/
│   ├── linux_openssl/
│   ├── windows_openssl/
│   └── wintun/
├── scripts/build/
│   ├── build-macos.sh
│   ├── build-ios.sh
│   ├── build-android.sh
│   ├── build-linux.sh
│   └── build-windows.sh          # MSYS2/MinGW bash 脚本
├── white-labeling/                # 白标品牌资源
│   ├── 1/                         # 默认品牌
│   ├── 2/                         # 自定义品牌
│   └── .../
└── src/                           # 源代码
```

## 应用配置

配置文件位于 `resources/bundle_config.json`，用于定义应用的基本信息和服务端点。

### 配置项说明

```json
{
    "config": {
        "panelUrl": "https://cp.jingo.cfd",        // 控制面板 URL（用户订阅）
        "appName": "JinGo",                         // 应用名称
        "supportEmail": "support@jingo.cfd",        // 支持邮箱
        "privacyPolicyUrl": "https://...",          // 隐私政策链接
        "termsOfServiceUrl": "https://...",         // 服务条款链接
        "telegramUrl": "https://t.me/...",          // Telegram 群组
        "discordUrl": "https://discord.gg/...",     // Discord 服务器
        "docsUrl": "https://docs.opine.work",       // 文档链接
        "issuesUrl": "https://opine.work/issues",   // 问题反馈链接
        "latencyTestUrl": "https://www.google.com/generate_204",  // 延迟测试
        "ipInfoUrl": "https://ipinfo.io/json",      // IP 信息查询
        "speedTestBaseUrl": "https://speed.cloudflare.com/__down?bytes=",  // 测速
        "hideSubscriptionBlock": true,              // 隐藏订阅区块
        "updateCheckUrl": "https://..."             // 更新检查
    }
}
```

### 主要配置项

| 配置项 | 说明 |
|--------|------|
| `panelUrl` | 用户订阅面板地址，用于获取节点配置 |
| `appName` | 应用显示名称 |
| `supportEmail` | 用户支持邮箱 |
| `hideSubscriptionBlock` | 是否隐藏界面中的订阅区块 |
| `latencyTestUrl` | 节点延迟测试使用的 URL |
| `ipInfoUrl` | 获取当前 IP 信息的 API |
| `speedTestBaseUrl` | 测速下载基础 URL |

### 授权验证

授权验证可通过构建时的 `JINDO_ENABLE_LICENSE_CHECK` 环境变量启用。本地开发**默认禁用**，CI 构建中**默认启用**。

授权公钥文件（`license_public_key.pem`）在运行时从应用资源目录加载，构建过程中通过 CMake POST_BUILD 规则自动从 `white-labeling/{brand}/` 复制，与 `bundle_config.json` 部署在同一目录。

---

## 环境搭建

### 第一步：安装 Qt

**版本要求：Qt 6.10+**（推荐 Qt 6.10.0 或更高版本）

1. 下载 Qt 在线安装器：https://www.qt.io/download-qt-installer
2. 运行安装器，选择 Qt 6.10 或更高版本
3. 根据目标平台选择组件：

| 目标平台 | 需要安装的 Qt 组件 |
|---------|-------------------|
| macOS | Qt 6.10+ → macOS |
| iOS | Qt 6.10+ → iOS |
| Android | Qt 6.10+ → Android (arm64-v8a, armeabi-v7a) |
| Linux | Qt 6.10+ → Desktop gcc 64-bit |
| Windows | Qt 6.10+ → MinGW 64-bit |

> **注意**：项目使用 Qt 6.10.0/6.10.1。Windows 平台构建脚本支持自动检测 Qt 和 MinGW 环境。

### 第二步：平台特定工具

| 平台 | 额外需要 |
|------|---------|
| macOS | Xcode (App Store 安装) |
| iOS | Xcode + Apple Developer 账号 |
| Android | Android Studio (SDK + NDK) |
| Linux | GCC: `sudo apt install build-essential cmake` |
| Windows | MSYS2 (https://www.msys2.org) |

## macOS 构建

### 1. 配置 Qt 路径

设置环境变量或编辑 `scripts/build/build-macos.sh`：

```bash
export QT_MACOS_PATH="/your/path/to/Qt/6.10.0/macos"
```

### 2. 构建

```bash
# 构建（默认不签名，用于开发测试）
./scripts/build/build-macos.sh

# 清理后重新构建
./scripts/build/build-macos.sh --clean

# Release 版本
./scripts/build/build-macos.sh --release

# Release + DMG
./scripts/build/build-macos.sh --release --dmg

# 启用代码签名
./scripts/build/build-macos.sh --release --sign --team-id YOUR_TEAM_ID
```

### 3. 构建选项

| 选项 | 说明 |
|------|------|
| `-c, --clean` | 清理后重新构建 |
| `-d, --debug` | Debug 模式（默认） |
| `-r, --release` | Release 模式 |
| `--sign` | 启用代码签名（默认禁用） |
| `--skip-sign` | 显式跳过签名 |
| `--dmg` | 创建 DMG 安装包 |
| `--team-id ID` | Apple 开发团队 ID |
| `--sign-identity ID` | 代码签名身份 |
| `-b, --brand ID` | 白标品牌 ID（数字） |
| `--bundle-id ID` | 自定义 Bundle ID |
| `-x, --xcode` | 仅生成 Xcode 项目 |
| `-o, --open` | 构建后自动打开 |
| `-t, --translate` | 更新翻译 |
| `-v, --verbose` | 详细输出 |

### 4. 运行

```bash
# 以 root 权限运行（TUN 设备需要）
sudo open build-macos/bin/Debug/JinGo.app
```

## iOS 构建

### 1. 配置

设置环境变量或编辑 `scripts/build/build-ios.sh`：

```bash
export QT_IOS_PATH="/your/path/to/Qt/6.10.0/ios"
```

### 2. 构建

```bash
# 跳过签名（仅编译验证）
./scripts/build/build-ios.sh --skip-sign

# 生成 Xcode 项目后在 Xcode 中构建
./scripts/build/build-ios.sh --xcode --team-id YOUR_TEAM_ID
open build-ios/JinGo.xcodeproj

# 命令行构建（需要 Team ID）
./scripts/build/build-ios.sh --release --team-id YOUR_TEAM_ID
```

### 3. 构建选项

| 选项 | 说明 |
|------|------|
| `-c, --clean` | 清理后重新构建 |
| `-d, --debug` | Debug 模式（默认） |
| `-r, --release` | Release 模式 |
| `-x, --xcode` | 生成 Xcode 项目 |
| `--skip-sign` | 跳过签名（无需 Team ID） |
| `--team-id ID` | Apple 开发团队 ID |
| `--sign-identity ID` | 代码签名身份 |
| `--profile-main NAME` | 主应用 Provisioning Profile |
| `--profile-tunnel NAME` | PacketTunnel Provisioning Profile |
| `-b, --brand ID` | 白标品牌 ID（数字） |
| `--bundle-id ID` | 自定义 Bundle ID |
| `-i, --install` | 安装到设备 |
| `-s, --simulator` | 模拟器构建 |
| `--device UDID` | 指定设备 UDID |

> **注意**：iOS 构建需要 Apple 开发团队 ID 才能签名。使用 `--skip-sign` 可跳过签名仅做编译验证。

## Android 构建

### 1. 安装 Android SDK/NDK

通过 Android Studio 安装：
- SDK Platform: Android 14 (API 34)
- NDK: 27.2.12479018

### 2. 配置

设置环境变量或编辑 `scripts/build/build-android.sh`：

```bash
export QT_BASE_PATH="/your/path/to/Qt/6.10.0"
export ANDROID_SDK_ROOT="/path/to/Android/sdk"
```

### 3. 构建

```bash
# 默认构建（arm64-v8a, Debug）
./scripts/build/build-android.sh

# Release 构建
./scripts/build/build-android.sh --release

# 清理后重新构建
./scripts/build/build-android.sh --clean --release

# 指定架构
./scripts/build/build-android.sh --abi arm64-v8a

# 安装到连接的设备
./scripts/build/build-android.sh --install
```

### 4. 构建选项

| 选项 | 说明 |
|------|------|
| `-c, --clean` | 清理后重新构建 |
| `-d, --debug` | Debug 模式（默认） |
| `-r, --release` | Release 模式 |
| `-a, --abi ABI` | 目标架构：`arm64-v8a`（默认）、`armeabi-v7a`、`x86`、`x86_64`、`all` |
| `-i, --install` | 安装 APK 到设备 |
| `-s, --sign` | 签名 APK（仅 Release） |

## Linux 构建

### 1. 安装依赖

```bash
sudo apt install -y build-essential cmake ninja-build \
    libgl1-mesa-dev libxcb1-dev libxcb-*-dev \
    libxkbcommon-dev libxkbcommon-x11-dev \
    libglib2.0-dev libsecret-1-dev
```

### 2. 配置 Qt 路径

#### 方法一：设置环境变量（推荐）

```bash
export QT_DIR="/mnt/dev/Qt/6.10.1/gcc_64"
# 或
export Qt6_DIR="/mnt/dev/Qt/6.10.1/gcc_64"
```

#### 方法二：修改构建脚本

编辑 `scripts/build/build-linux.sh`：

```bash
QT_DIR="/mnt/dev/Qt/6.10.1/gcc_64"
```

### 3. 构建

```bash
# Debug 模式构建（默认）
./scripts/build/build-linux.sh

# Release 模式构建
./scripts/build/build-linux.sh --release

# 清理后重新构建
./scripts/build/build-linux.sh --clean --release

# 部署 Qt 依赖库
./scripts/build/build-linux.sh --release --deploy

# 创建安装包（DEB/RPM/TGZ）
./scripts/build/build-linux.sh --release --package

# 完整发布流程
./scripts/build/build-linux.sh --clean --release --deploy --package
```

### 4. 构建选项

| 选项 | 说明 |
|------|------|
| `-c, --clean` | 清理构建目录后重新构建 |
| `-d, --debug` | Debug 模式构建（默认） |
| `-r, --release` | Release 模式构建 |
| `-p, --package` | 打包 DEB/RPM/TGZ |
| `--deploy` | 部署 Qt 依赖库和插件 |
| `-t, --translate` | 更新翻译 |
| `-b, --brand ID` | 白标品牌 ID（数字） |
| `-v, --verbose` | 显示详细输出 |

### 5. 构建输出

```
build-linux/
├── bin/
│   ├── JinGo                    # 主可执行文件
│   └── lib/                     # OpenSSL 依赖库
│       ├── libssl.so.3
│       └── libcrypto.so.3
└── build.log                    # 构建日志
```

Release 模式会额外生成：

```
release/
└── jingo-{brand}-{version}-{date}-linux.tar.gz
```

### 6. 设置 TUN 权限

Linux 需要网络管理权限才能创建 TUN 设备：

```bash
# 方式一：设置 capability（推荐，无需 root 运行）
sudo setcap cap_net_admin+eip ./build-linux/bin/JinGo

# 方式二：使用 root 权限运行
sudo ./build-linux/bin/JinGo
```

## Windows 构建

### 1. 环境要求

- **MSYS2**: https://www.msys2.org（必需）
- **Qt**: 6.10.0 或更高版本（MinGW 64-bit）
- **MinGW**: 13.1.0 或更高版本（通常随 Qt 安装）
- **CMake**: 3.21+（可选，脚本会自动使用 Qt 自带的 CMake）

### 2. 自动环境检测

构建脚本会自动检测以下路径（按优先级）：

**Qt 安装路径**：
- `D:\Qt\6.10.1\mingw_64`
- `D:\Qt\6.10.0\mingw_64`
- `C:\Qt\6.10.1\mingw_64`
- `C:\Qt\6.10.0\mingw_64`

**MinGW 编译器路径**：
- `D:\Qt\Tools\mingw1310_64`
- `D:\Qt\Tools\mingw1120_64`
- `D:\msys64\mingw64`

**CMake 路径**：
- `D:\Qt\Tools\CMake_64\bin`
- `C:\Qt\Tools\CMake_64\bin`

### 3. 构建

Windows 使用 MSYS2/MinGW bash 脚本构建：

```bash
# 在 MSYS2 MinGW64 终端中：

# Release 构建（默认）
./scripts/build/build-windows.sh

# 清理后重新构建
./scripts/build/build-windows.sh clean

# Debug 构建
./scripts/build/build-windows.sh debug

# 清理 + Debug
./scripts/build/build-windows.sh clean debug
```

> **注意**：脚本默认使用低内存模式（`-O1` + 单线程编译），以避免 QRC 编译时内存溢出。

### 4. 构建输出

| 类型 | 路径 |
|------|------|
| 可执行文件 | `build-windows/bin/JinGo.exe` |
| 部署目录 | `pkg/JinGo-1.0.0/` |
| ZIP 便携版 | `pkg/jingo-{brand}-{version}-{date}-windows.zip` |
| Release 目录 | `release/jingo-{brand}-{version}-{date}-windows.zip` |

## 构建选项速查

| 选项 | macOS | iOS | Android | Linux | Windows |
|------|-------|-----|---------|-------|---------|
| 清理重建 | `--clean` | `--clean` | `--clean` | `--clean` | `clean` |
| Release 模式 | `--release` | `--release` | `--release` | `--release` | (默认) |
| Debug 模式 | `--debug` | `--debug` | `--debug` | `--debug` | `debug` |
| 跳过签名 | `--skip-sign` | `--skip-sign` | - | - | - |
| 代码签名 | `--sign` | `--team-id` | `--sign` | - | - |
| 创建安装包 | `--dmg` | - | - | `--package` | (自动) |
| 安装到设备 | `--open` | `--install` | `--install` | - | - |
| Xcode 项目 | `--xcode` | `--xcode` | - | - | - |
| 目标架构 | - | - | `--abi` | - | - |
| 白标品牌 ID | `--brand` / 环境变量 `BRAND` | `--brand` / 环境变量 `BRAND` | 环境变量 `BRAND` | `--brand` / 环境变量 `BRAND` | 环境变量 `BRAND` |

## 输出位置

| 平台 | Debug | Release | 发布包 |
|------|-------|---------|--------|
| macOS | `build-macos/bin/Debug/JinGo.app` | `build-macos/bin/Release/JinGo.app` | `release/*.dmg` |
| iOS | `build-ios/bin/Debug/JinGo.app` | `build-ios/bin/Release/JinGo.app` | `release/*.ipa` |
| Android | `build-android/.../debug/*.apk` | `build-android/.../release/*.apk` | `release/*.apk` |
| Linux | `build-linux/bin/JinGo` | 同左 | `release/*.tar.gz` |
| Windows | `build-windows/bin/JinGo.exe` | 同左 | `release/*.zip` |

所有发布产物统一输出到 `release/` 目录。

## 常见问题

### Q: Qt 找不到？

确保构建脚本或环境变量中的 Qt 路径正确，并且该目录存在。

### Q: macOS 运行闪退？

需要 root 权限运行：`sudo open build-macos/bin/Debug/JinGo.app`

### Q: iOS 构建缺少 Team ID？

使用 `--skip-sign` 跳过签名，仅做编译验证：
```bash
./scripts/build/build-ios.sh --skip-sign
```

### Q: Linux 网络不工作？

需要 root 权限或设置 capabilities：
```bash
sudo setcap cap_net_admin+eip build-linux/bin/JinGo
```

### Q: Android NDK 错误？

确保 `ANDROID_NDK_VERSION` 与实际安装的 NDK 版本一致。

### Q: Windows 构建内存不足？

脚本已默认启用低内存模式（`-O1` + 单线程编译），确保至少 4GB 可用内存。

---

## OneDev CI/CD 自动构建

项目使用 OneDev CI/CD 进行多平台自动化构建，配置文件为 `.onedev-buildspec.yml`。

### 白标品牌 (Brand ID)

所有 CI 构建任务接受 `brand` 参数（数字 ID）。CI 通过环境变量 `BRAND=<id>` 传递品牌 ID，构建脚本会自动从 `white-labeling/<id>/` 读取品牌配置和图标。

各平台在构建脚本中有独立的默认 Brand ID：

| 平台 | 默认 Brand ID |
|------|-------------|
| Windows | 1 |
| macOS | 2 |
| Android | 3 |
| Linux | 4 |
| iOS | 5 |

### JinDoCore 静态库依赖

**JinGo 依赖预编译的 JinDoCore 静态库，不在 CI 中编译 JinDo。**

- 静态库已包含在 `third_party/jindo/<platform>/` 目录中
- SuperRay 已合并到 JinDoCore 静态库中（Android 除外，仍需 libsuperray.so）
- CI 构建前会验证静态库是否存在

#### 预编译库位置

| 平台 | 静态库 | 头文件 |
|------|--------|--------|
| Windows | `third_party/jindo/windows/mingw64/libJinDoCore.a` | `third_party/jindo/windows/mingw64/include/` |
| Linux | `third_party/jindo/linux/x64/libJinDoCore.a` | `third_party/jindo/linux/x64/include/` |
| macOS/iOS | `third_party/jindo/apple/JinDoCore.xcframework/` | 同左 |
| Android | `third_party/jindo/android/<abi>/libJinDoCore.a` | `third_party/jindo/android/<abi>/include/` |

### CI 构建流程

所有平台遵循统一流程：

1. **Checkout** - 克隆仓库（含子模块）
2. **Verify Dependencies** - 检查 JinDoCore 库和白标资源是否存在
3. **Build Release** - 使用 `--clean --release` 和平台特定参数进行干净构建
4. **Publish Artifacts** - 从 `release/` 目录发布

各平台构建命令：

| 平台 | Executor | 构建命令 |
|------|----------|---------|
| macOS | macos-builder | `build-macos.sh --clean --release --dmg --skip-sign` |
| iOS | macos-builder | `build-ios.sh --clean --release --skip-sign` |
| Android | linux-builder | `build-android.sh --clean --release` |
| Linux | linux-builder | `build-linux.sh --clean --release --deploy --package` |
| Windows | windows-builder | `build-windows.sh clean`（通过 MSYS2） |

> **说明**：macOS 和 iOS 的 CI 构建使用 `--skip-sign` 跳过代码签名。macOS 即使不加此参数也默认不签名，但 CI 中显式指定以保持清晰。

### CI 环境配置

| 平台 | 关键环境 |
|------|---------|
| macOS/iOS | Xcode: `/Volumes/mindata/Xcode.app`, Qt: `/Volumes/mindata/Qt/6.10.1/{macos,ios}` |
| Android | Qt: `/mnt/dev/Qt/6.10.1`, SDK: `/mnt/dev/Android/Sdk`, NDK: `29.0.14206865`, Java 21 |
| Linux | Qt: `/mnt/dev/Qt/6.10.1/gcc_64` |
| Windows | MSYS2: `D:\msys64` |

所有 CI 构建均设置 `JINDO_ENABLE_LICENSE_CHECK=ON` 以在发布产物中启用授权验证。

### 构建产物

所有平台的产物统一发布到 `release/` 目录：

| 平台 | 产物 | 说明 |
|------|------|------|
| macOS | `release/*.dmg` | 自签名，首次运行需右键打开 |
| iOS | `release/*.ipa` | 未签名，需 AltStore/Sideloadly 安装 |
| Android | `release/*.apk` | debug 签名 |
| Linux | `release/*.tar.gz` / `*.deb` | 需 `setcap` 或 sudo 运行 |
| Windows | `release/*.zip` | 便携版，可能触发 SmartScreen |

### 更新预编译库

当 JinDo 代码更新后，需重新编译并更新静态库：

```bash
# 1. 编译 JinDo（各平台）
cd JinDo && bash scripts/build-<platform>.sh

# 2. JinDo 脚本会自动复制产物到 JinGo/third_party/jindo/

# 3. 提交到仓库
cd JinGo
git add third_party/jindo/
git commit -m "Update JinDoCore precompiled libraries"
git push
```

### CI 故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| `undefined reference: SuperRay_*` | libJinDoCore.a 未合并 SuperRay | 重新编译 JinDo，确认 ar/libtool 合并步骤 |
| `superray.h: No such file` | JinDo 脚本未导出 superray.h | 检查 JinDo 编译脚本中 superray.h 复制路径 |
| `cannot find -lsuperray` | CMakeLists.txt 残留旧的动态库链接 | 确认已删除 SuperRay DLL 相关段落 |
| CMake 找不到编译器 | MSYS2/MinGW 配置不正确 | 检查工具链安装 |
| Windows 内存不足 | QRC 编译占用大量内存 | 已配置低内存模式（O1 + 单线程） |
| iOS 缺少 Team ID | 缺少 `--skip-sign` | CI 构建参数添加 `--skip-sign` |

---

## 下一步

- [开发指南](03_DEVELOPMENT_zh.md)
- [白标定制](04_WHITE_LABELING_zh.md)
- [故障排除](05_TROUBLESHOOTING_zh.md)
