# JinGo VPN

[中文](README_zh.md)

Cross-platform VPN client built with Qt 6 and Xray core.

**Official Demo**: [https://jingoo.biz](https://jingoo.biz)

## Notice

The GitHub repository provides a **basic feature version**, with the open-source edition updated **once every six months** and the commercial edition receiving **weekly bug fixes**. We do **not** offer free customization or update services. This project is intended as a **technical reference** for developers who have the ability to build, modify, and use it themselves — it is a form of **technical exchange**.

**Open-source does not mean free.** We do offer official customization services — you provide detailed requirements, and we quote accordingly. Pricing starts at **$500 USD** and will not be low, so please consider your budget.

For details, visit our [online build service](https://opine.work) (commercial edition, with better protocol support and UI customization).

- Telegram Channel: [@OpineWorkPublish](https://t.me/OpineWorkPublish)
- Telegram Group: [@OpineWorkOfficial](https://t.me/OpineWorkOfficial)

## Features

- **Cross-platform**: Android, iOS, macOS, Windows, Linux
- **Modern UI**: Smooth user interface built with Qt 6 QML
- **Multi-protocol**: Based on Xray core, supports VMess, VLESS, Trojan, Shadowsocks, etc.
- **Multi-language**: Supports 8 languages (English, Chinese, Vietnamese, Khmer, Burmese, Russian, Persian, etc.)
- **White-labeling**: Supports brand customization and multi-tenant deployment

## Screenshots

<p align="center">
  <img src="images/macos.png" width="280" alt="macOS" />
</p>

<p align="center">
  <img src="images/ios.jpg" width="280" alt="iOS" />
  <img src="images/android.jpg" width="280" alt="Android" />
</p>

<p align="center">
  <img src="images/servers.png" width="280" alt="Server List" />
  <img src="images/subscription.png" width="280" alt="Subscription" />
</p>

<p align="center">
  <img src="images/setting.png" width="280" alt="Settings" />
  <img src="images/profile.png" width="280" alt="Profile" />
</p>

## Table of Contents

- [Notice](#notice)
- [Features](#features)
- [Screenshots](#screenshots)
- [Quick Start](#quick-start)
- [Platform Support](#platform-support)
- [Platform Distribution](#platform-distribution)
- [Documentation](#documentation)
- [Language Support](#language-support)
- [Tech Stack](#tech-stack)
- [Build Options](#build-options)
- [Development](#development)
- [Subscription Format](#subscription-format)
- [License Verification](#license-verification)
- [Compliance](#compliance)
- [License](#license)

## Quick Start

### Prerequisites

- **Qt**: 6.10.0+ (recommended 6.10.0 or higher)
- **CMake**: 3.21+
- **Compiler**:
  - macOS/iOS: Xcode 15+
  - Android: NDK 27.2+
  - Windows: MinGW 13+ (included with Qt)
  - Linux: GCC 11+ or Clang 14+

### Build Steps

#### 1. Fork and Configure White-label

```bash
# 1. Fork this repository to your GitHub account

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/JinGo.git
cd JinGo

# 3. Create your white-label config
cp -r white-labeling/1 white-labeling/YOUR_BRAND

# 4. Edit white-labeling/YOUR_BRAND/bundle_config.json
{
    "panel_url": "https://your-api-server.com",
    "app_name": "YourApp",
    "support_email": "support@your-domain.com",
    ...
}

# 5. Replace app icons in white-labeling/YOUR_BRAND/icons/
```

#### 2. Build Application

All build scripts are in `scripts/build/`:

```bash
# Android APK
./scripts/build/build-android.sh --release --abi arm64-v8a

# macOS App (Universal Binary: arm64 + x86_64)
./scripts/build/build-macos.sh --release

# iOS App (requires Apple Developer Team ID)
./scripts/build/build-ios.sh --release --team-id YOUR_TEAM_ID

# Linux
./scripts/build/build-linux.sh --release

# Windows (PowerShell)
./scripts/build/build-windows.sh
```

#### 3. Build with White-label Brand

```bash
./scripts/build/build-macos.sh --release --brand YOUR_BRAND
./scripts/build/build-android.sh --release --brand YOUR_BRAND
./scripts/build/build-ios.sh --release --brand YOUR_BRAND --team-id YOUR_TEAM_ID
```

### Output Locations

| Platform | Output | Location |
|----------|--------|----------|
| Android | APK | `release/jingo-*-android.apk` |
| macOS | DMG | `release/jingo-*-macos.dmg` |
| iOS | IPA | `release/jingo-*-ios.ipa` |
| Windows | EXE/MSI | `release/jingo-*-windows.exe` |
| Linux | tar.gz | `release/jingo-*-linux.tar.gz` |

## Platform Support

| Platform | Architecture | Minimum Version | Status |
|----------|--------------|-----------------|--------|
| Android | arm64-v8a, armeabi-v7a, x86_64 | API 28 (Android 9) | ✅ |
| iOS | arm64 | iOS 15.0 | ✅ |
| macOS | arm64, x86_64 | macOS 12.0 | ✅ |
| Windows | x64 | Windows 10 | ✅ |
| Linux | x64 | Ubuntu 20.04+ | ✅ |

## Platform Distribution

### Distribution Formats

| Platform | Format | Signing | Installer |
|----------|--------|---------|-----------|
| Android | `.apk` | Keystore (apksigner) | Direct install / Google Play |
| iOS | `.ipa` | Apple Developer Certificate | TestFlight / App Store / Sideload |
| macOS | `.dmg` | Developer ID (optional) | Drag-to-Applications |
| Windows | `.exe` | No code signing (UAC manifest) | NSIS installer |
| Linux | `.tar.gz` / `.deb` / `.rpm` | None | CPack |

### VPN Mode Support

| Feature | Android | iOS | macOS | Windows | Linux |
|---------|---------|-----|-------|---------|-------|
| TUN Mode | VpnService | Network Extension | Root (direct TUN) | WinTUN | TUN device |
| Local Proxy (SOCKS/HTTP) | Yes | No (sandbox) | Yes | Yes | Yes |
| System-wide VPN | Yes | Yes | Yes | Yes | Yes |
| Split Tunneling | Yes | Limited | Yes | Yes | Yes |

### iOS Signing & Distribution

iOS requires code signing for all distribution methods. The app uses Network Extension (PacketTunnelProvider) which requires special entitlements.

**Required Apple Developer Resources:**

| Resource | Description |
|----------|-------------|
| Developer Certificate | `Apple Development` (debug) or `Apple Distribution` (release) |
| App ID | Main app + PacketTunnelProvider extension (2 App IDs) |
| Provisioning Profile | One for main app, one for extension |
| Entitlements | Network Extension, VPN API, App Groups, Keychain |

**Distribution Methods:**

| Method | Certificate | Profile Type | Notes |
|--------|-------------|--------------|-------|
| Development (USB) | Apple Development | Development | `get-task-allow = true`, max 100 devices |
| Ad Hoc | Apple Distribution | Ad Hoc | Max 100 registered devices |
| TestFlight | Apple Distribution | App Store | Up to 10,000 testers, Apple review required |
| App Store | Apple Distribution | App Store | Has third-party payment, not supported out-of-box, requires custom development |
| Enterprise | Enterprise cert | In-House | $299/year program, no device limit |

**Bundle ID Configuration:**

```
Main App:       <your.bundle.id>
Extension:      <your.bundle.id>.PacketTunnelProvider
App Group:      group.<your.bundle.id>
```

When using `--bundle-id`, the build script automatically derives the extension Bundle ID and App Group. Entitlements files in `platform/ios/` may need manual update if the Team ID changes.

**Build & Sign:**

```bash
# Development build (auto-sign + install to device)
./scripts/build/build-ios.sh --debug --bundle-id com.example.vpn --team-id YOUR_TEAM_ID --install

# Release build (unsigned .app, sign separately)
./scripts/build/build-ios.sh --release --bundle-id com.example.vpn --skip-sign

# Sign and create IPA
./scripts/signing/post_build_ios.sh
```

> **Note**: The Network Extension entitlement (`com.apple.developer.networking.networkextension`) requires explicit approval from Apple. You must enable this capability in your App ID configuration on the Apple Developer Portal.

### macOS Distribution

macOS does not use Network Extension. Instead, it runs the JinGoCore helper with setuid root to directly create and manage the TUN device.

```bash
# Build DMG
./scripts/build/build-macos.sh --release --dmg

# Signed (Developer ID, optional)
./scripts/build/build-macos.sh --release --dmg --sign --team-id YOUR_TEAM_ID
```

> **Note**: The macOS JinGoCore helper requires setuid root to operate the TUN device, which is configured automatically during installation. Code signing is optional but recommended for distribution (avoids Gatekeeper warnings).

### Android Distribution

Android uses standard VpnService API. No special signing requirements beyond a release keystore.

```bash
# Debug APK (auto-signed)
./scripts/build/build-android.sh --debug

# Release APK (signed with keystore)
./scripts/build/build-android.sh --release --sign

# Multi-ABI build
./scripts/build/build-android.sh --release --abi all
```

### Windows Distribution

Windows uses WinTUN driver for TUN mode. The installer requires Administrator privileges.

```bash
# Build + package
./scripts/build/build-windows.sh

# Output: release/jingo-*-windows-setup.exe (NSIS installer)
```

### Key Notes

1. **iOS sandbox restriction**: iOS does not support local SOCKS/HTTP proxy mode. All traffic goes through the TUN device via Network Extension.
2. **iOS entitlements**: Changing the Bundle ID requires updating `platform/ios/JinGo.entitlements` and `platform/ios/PacketTunnelProvider.entitlements` with the correct `application-identifier` and `com.apple.security.application-groups`.
3. **macOS notarization**: For distribution outside the App Store, macOS apps should be notarized with `xcrun notarytool` to avoid Gatekeeper warnings.
4. **Android multi-ABI**: Use `--abi all` to build for arm64-v8a, armeabi-v7a, and x86_64 in a single APK.
5. **White-label Bundle ID**: Each white-label brand can specify its own Bundle ID in `bundle_config.json`. The OneDev CI reads this and passes it via `--bundle-id` to the build script.

## Documentation

- [Architecture](docs/01_ARCHITECTURE.md)
- [Build Guide](docs/02_BUILD_GUIDE.md)
- [Development Guide](docs/03_DEVELOPMENT.md)
- [White-labeling](docs/04_WHITE_LABELING.md)
- [Troubleshooting](docs/05_TROUBLESHOOTING.md)
- [Platform Guide](docs/06_PLATFORMS.md)
- [Panel Extension](docs/07_PANEL_EXTENSION.md)

## Language Support

| Language | Code | Status |
|----------|------|--------|
| English | en_US | ✅ |
| Simplified Chinese | zh_CN | ✅ |
| Traditional Chinese | zh_TW | ✅ |
| Vietnamese | vi_VN | ✅ |
| Khmer | km_KH | ✅ |
| Burmese | my_MM | ✅ |
| Russian | ru_RU | ✅ |
| Persian | fa_IR | ✅ |

## Tech Stack

- **UI Framework**: Qt 6.10.0+ (QML/Quick)
- **VPN Core**: Xray-core (via SuperRay wrapper)
- **Network**: Qt Network + OpenSSL
- **Storage**: SQLite (Qt SQL)
- **Secure Storage**:
  - macOS/iOS: Keychain
  - Android: EncryptedSharedPreferences
  - Windows: DPAPI
  - Linux: libsecret

## Build Options

### CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `USE_JINDO_LIB` | ON | Use JinDoCore static library |
| `JINDO_ROOT` | `../JinDo` | JinDo project path |
| `CMAKE_BUILD_TYPE` | Debug | Build type (Debug/Release) |

### Build Script Options

```bash
# Common options
--clean          # Clean build directory
--release        # Release mode
--debug          # Debug mode

# Android specific
--abi <ABI>      # Architecture (arm64-v8a/armeabi-v7a/x86_64/all)
--sign           # Sign APK

# macOS specific
--sign           # Enable code signing (requires Team ID)
--team-id ID     # Apple Development Team ID

# iOS specific (signing required)
--team-id ID     # Apple Development Team ID (required)

# Linux specific
--deploy         # Deploy Qt dependencies
--package        # Create installation package
```

## Development

### Code Style

- C++17 standard
- Qt coding conventions
- Use `clang-format` for formatting

### Debugging

```bash
# Enable verbose logging
QT_LOGGING_RULES="*.debug=true" ./JinGo

# Android logcat
adb logcat -s JinGo:V SuperRay-JNI:V
```

## Subscription Format

The default subscription format is **sing-box** (JSON). The application requests `flag=sing-box` when fetching subscription data from the panel, which returns a standard JSON configuration that is more reliable to parse across all platforms.

Clash (YAML) format is also supported as a fallback when the server returns YAML content.

## License Verification

Official release builds (from CI/CD) have **license verification enabled** (`JINDO_ENABLE_LICENSE_CHECK=ON`). These builds validate the application license at runtime with restrictions.

For the open-source version, you should **build locally** using the build scripts. Local builds have license verification **disabled by default**.

> **Note**: GitHub Actions CI is not supported. Please use local build scripts or the project's OneDev CI/CD for automated builds.

## Compliance

This software is designed to protect user privacy and secure network communications. It is **strictly prohibited** to use this software for:

- Circumventing government network regulations or censorship
- Any activities that violate local laws and regulations
- Unauthorized access to restricted networks or services

Users must comply with all applicable laws and regulations of their country or region. The developers assume no liability for any misuse of this software.

## License

MIT License

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=opinework/JinGo&type=Date)](https://star-history.com/#opinework/JinGo&Date)

---

**Version**: 1.0.0
**Qt Version**: 6.10.0+
**Last Updated**: 2026-02
