# JinGo VPN - Build Guide

[中文文档](02_BUILD_GUIDE_zh.md)

## Quick Start

Building JinGo is straightforward:

1. **Install Qt 6.10.0+** (recommended 6.10.0 or higher)
2. **Configure Qt path in build scripts** (or use auto-detection)
3. **Run the build script**

All dependencies (JinDoCore, OpenSSL, SuperRay, etc.) are pre-compiled and included in the `third_party/` directory.

> **Note**: Windows build scripts support automatic environment detection, no manual path configuration required.

## Dependencies

```
JinGo (Qt Application)
├── JinDoCore (Static Library)  → third_party/jindo/
│   └── Core business logic, API client, VPN management
│   └── SuperRay merged (VPN core engine/Xray)
├── SuperRay (Dynamic Library)  → Android only, JNI dynamic linking
├── OpenSSL (Static Library)    → third_party/*_openssl/
│   └── Encryption support
└── WinTun (Windows)            → third_party/wintun/
    └── Windows TUN driver
```

**All dependencies are pre-compiled. No manual compilation required.**

## Directory Structure

```
JinGo/
├── third_party/
│   ├── jindo/                    # JinDoCore static library (core)
│   │   ├── android/              # Android architectures
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
│   └── build-windows.sh          # MSYS2/MinGW bash script
├── white-labeling/                # White-label brand resources
│   ├── 1/                         # Default brand
│   ├── 2/                         # Custom brand
│   └── .../
└── src/                           # Source code
```

## Application Configuration

Configuration file is located at `resources/bundle_config.json`, defining app information and service endpoints.

### Configuration Options

```json
{
    "config": {
        "panelUrl": "https://cp.jingo.cfd",        // Control panel URL (user subscription)
        "appName": "JinGo",                         // Application name
        "supportEmail": "support@jingo.cfd",        // Support email
        "privacyPolicyUrl": "https://...",          // Privacy policy link
        "termsOfServiceUrl": "https://...",         // Terms of service link
        "telegramUrl": "https://t.me/...",          // Telegram group
        "discordUrl": "https://discord.gg/...",     // Discord server
        "docsUrl": "https://docs.opine.work",       // Documentation link
        "issuesUrl": "https://opine.work/issues",   // Issue tracking link
        "latencyTestUrl": "https://www.google.com/generate_204",  // Latency test
        "ipInfoUrl": "https://ipinfo.io/json",      // IP info query
        "speedTestBaseUrl": "https://speed.cloudflare.com/__down?bytes=",  // Speed test
        "hideSubscriptionBlock": true,              // Hide subscription block
        "updateCheckUrl": "https://..."             // Update check
    }
}
```

### Main Configuration Items

| Option | Description |
|--------|-------------|
| `panelUrl` | User subscription panel address for node configuration |
| `appName` | Application display name |
| `supportEmail` | User support email |
| `hideSubscriptionBlock` | Whether to hide subscription block in UI |
| `latencyTestUrl` | URL for node latency testing |
| `ipInfoUrl` | API for current IP info |
| `speedTestBaseUrl` | Speed test download base URL |

### License Verification

License verification can be enabled via the `JINDO_ENABLE_LICENSE_CHECK` environment variable at build time. It is **disabled by default** in local development and **enabled in CI builds**.

The license public key (`license_public_key.pem`) is loaded at runtime from the application resources directory. It is automatically copied from `white-labeling/{brand}/` during the build process via CMake POST_BUILD rules, deployed alongside `bundle_config.json`.

---

## Environment Setup

### Step 1: Install Qt

**Version requirement: Qt 6.10.0+** (recommended Qt 6.10.0 or higher)

1. Download Qt Online Installer: https://www.qt.io/download-qt-installer
2. Run installer, select Qt 6.10.0 or higher
3. Select components based on target platform:

| Target Platform | Required Qt Components |
|----------------|------------------------|
| macOS | Qt 6.10.0+ → macOS |
| iOS | Qt 6.10.0+ → iOS |
| Android | Qt 6.10.0+ → Android (arm64-v8a, armeabi-v7a) |
| Linux | Qt 6.10.0+ → Desktop gcc 64-bit |
| Windows | Qt 6.10.0+ → MinGW 64-bit |

> **Note**: Project uses Qt 6.10.0/6.10.1. Windows build scripts support automatic Qt and MinGW environment detection.

### Step 2: Platform-Specific Tools

| Platform | Additional Requirements |
|----------|------------------------|
| macOS | Xcode (install from App Store) |
| iOS | Xcode + Apple Developer Account |
| Android | Android Studio (SDK + NDK) |
| Linux | GCC: `sudo apt install build-essential cmake` |
| Windows | MSYS2 (https://www.msys2.org) |

## macOS Build

### 1. Configure Qt Path

Set environment variable or edit `scripts/build/build-macos.sh`:

```bash
export QT_MACOS_PATH="/your/path/to/Qt/6.10.0/macos"
```

### 2. Build

```bash
# Build (no signing by default, for development)
./scripts/build/build-macos.sh

# Clean and rebuild
./scripts/build/build-macos.sh --clean

# Release version
./scripts/build/build-macos.sh --release

# Release with DMG
./scripts/build/build-macos.sh --release --dmg

# With code signing
./scripts/build/build-macos.sh --release --sign --team-id YOUR_TEAM_ID
```

### 3. Build Options

| Option | Description |
|--------|-------------|
| `-c, --clean` | Clean rebuild |
| `-d, --debug` | Debug mode (default) |
| `-r, --release` | Release mode |
| `--sign` | Enable code signing (disabled by default) |
| `--skip-sign` | Explicitly skip signing |
| `--dmg` | Create DMG installer |
| `--team-id ID` | Apple Development Team ID |
| `--sign-identity ID` | Code signing identity |
| `-b, --brand ID` | White-label brand ID (numeric) |
| `--bundle-id ID` | Custom Bundle ID |
| `-x, --xcode` | Generate Xcode project only |
| `-o, --open` | Auto-open after build |
| `-t, --translate` | Update translations |
| `-v, --verbose` | Verbose output |

### 4. Run

```bash
# Run with root privileges (required for TUN device)
sudo open build-macos/bin/Debug/JinGo.app
```

## iOS Build

### 1. Configure

Set environment variable or edit `scripts/build/build-ios.sh`:

```bash
export QT_IOS_PATH="/your/path/to/Qt/6.10.0/ios"
```

### 2. Build

```bash
# Skip signing (compile verification only)
./scripts/build/build-ios.sh --skip-sign

# Generate Xcode project and build in Xcode
./scripts/build/build-ios.sh --xcode --team-id YOUR_TEAM_ID
open build-ios/JinGo.xcodeproj

# Command line build with signing
./scripts/build/build-ios.sh --release --team-id YOUR_TEAM_ID
```

### 3. Build Options

| Option | Description |
|--------|-------------|
| `-c, --clean` | Clean rebuild |
| `-d, --debug` | Debug mode (default) |
| `-r, --release` | Release mode |
| `-x, --xcode` | Generate Xcode project |
| `--skip-sign` | Skip signing (no Team ID needed) |
| `--team-id ID` | Apple Development Team ID |
| `--sign-identity ID` | Code signing identity |
| `--profile-main NAME` | Main app provisioning profile |
| `--profile-tunnel NAME` | PacketTunnel provisioning profile |
| `-b, --brand ID` | White-label brand ID (numeric) |
| `--bundle-id ID` | Custom Bundle ID |
| `-i, --install` | Install to device |
| `-s, --simulator` | Simulator build |
| `--device UDID` | Specify device UDID |

> **Note**: iOS builds require Apple Developer Team ID for signing. Use `--skip-sign` for compile-only verification.

## Android Build

### 1. Install Android SDK/NDK

Install via Android Studio:
- SDK Platform: Android 14 (API 34)
- NDK: 27.2.12479018

### 2. Configure

Set environment variables or edit `scripts/build/build-android.sh`:

```bash
export QT_BASE_PATH="/your/path/to/Qt/6.10.0"
export ANDROID_SDK_ROOT="/path/to/Android/sdk"
```

### 3. Build

```bash
# Default build (arm64-v8a, Debug)
./scripts/build/build-android.sh

# Release build
./scripts/build/build-android.sh --release

# Clean and rebuild
./scripts/build/build-android.sh --clean --release

# Specific ABI
./scripts/build/build-android.sh --abi arm64-v8a

# Install to connected device
./scripts/build/build-android.sh --install
```

### 4. Build Options

| Option | Description |
|--------|-------------|
| `-c, --clean` | Clean rebuild |
| `-d, --debug` | Debug mode (default) |
| `-r, --release` | Release mode |
| `-a, --abi ABI` | Target ABI: `arm64-v8a` (default), `armeabi-v7a`, `x86`, `x86_64`, `all` |
| `-i, --install` | Install APK to device |
| `-s, --sign` | Sign APK (Release only) |

## Linux Build

### 1. Install Dependencies

```bash
sudo apt install -y build-essential cmake ninja-build \
    libgl1-mesa-dev libxcb1-dev libxcb-*-dev \
    libxkbcommon-dev libxkbcommon-x11-dev \
    libglib2.0-dev libsecret-1-dev
```

### 2. Configure Qt Path

#### Method 1: Environment Variable (Recommended)

```bash
export QT_DIR="/mnt/dev/Qt/6.10.0/gcc_64"
# or
export Qt6_DIR="/mnt/dev/Qt/6.10.0/gcc_64"
```

#### Method 2: Edit Build Script

Edit `scripts/build/build-linux.sh`:

```bash
QT_DIR="/mnt/dev/Qt/6.10.0/gcc_64"
```

### 3. Build

```bash
# Debug mode (default)
./scripts/build/build-linux.sh

# Release mode
./scripts/build/build-linux.sh --release

# Clean and rebuild
./scripts/build/build-linux.sh --clean --release

# Deploy Qt dependencies
./scripts/build/build-linux.sh --release --deploy

# Create installation package (DEB/RPM/TGZ)
./scripts/build/build-linux.sh --release --package

# Full release pipeline
./scripts/build/build-linux.sh --clean --release --deploy --package
```

### 4. Build Options

| Option | Description |
|--------|-------------|
| `-c, --clean` | Clean build directory before building |
| `-d, --debug` | Debug mode build (default) |
| `-r, --release` | Release mode build |
| `-p, --package` | Package DEB/RPM/TGZ |
| `--deploy` | Deploy Qt dependencies and plugins |
| `-t, --translate` | Update translations |
| `-b, --brand ID` | White-label brand ID (numeric) |
| `-v, --verbose` | Show detailed output |

### 5. Build Output

```
build-linux/
├── bin/
│   ├── JinGo                    # Main executable
│   └── lib/                     # OpenSSL dependencies
│       ├── libssl.so.3
│       └── libcrypto.so.3
└── build.log                    # Build log
```

Release mode generates:

```
release/
└── jingo-{brand}-{version}-{date}-linux.tar.gz
```

### 6. Set TUN Permissions

Linux requires network admin permission to create TUN devices:

```bash
# Method 1: Set capability (recommended, no root required to run)
sudo setcap cap_net_admin+eip ./build-linux/bin/JinGo

# Method 2: Run with root privileges
sudo ./build-linux/bin/JinGo
```

## Windows Build

### 1. Requirements

- **MSYS2**: https://www.msys2.org (required)
- **Qt**: 6.10.0 or higher (MinGW 64-bit)
- **MinGW**: 13.1.0 or higher (usually installed with Qt)
- **CMake**: 3.21+ (optional, script uses Qt's bundled CMake)

### 2. Auto Environment Detection

The build script automatically detects these paths (by priority):

**Qt Installation Path**:
- `D:\Qt\6.10.1\mingw_64`
- `D:\Qt\6.10.0\mingw_64`
- `C:\Qt\6.10.1\mingw_64`
- `C:\Qt\6.10.0\mingw_64`

**MinGW Compiler Path**:
- `D:\Qt\Tools\mingw1310_64`
- `D:\Qt\Tools\mingw1120_64`
- `D:\msys64\mingw64`

**CMake Path**:
- `D:\Qt\Tools\CMake_64\bin`
- `C:\Qt\Tools\CMake_64\bin`

### 3. Build

The Windows build uses a MSYS2/MinGW bash script:

```bash
# In MSYS2 MinGW64 terminal:

# Release build (default)
./scripts/build/build-windows.sh

# Clean and rebuild
./scripts/build/build-windows.sh clean

# Debug build
./scripts/build/build-windows.sh debug

# Clean + debug
./scripts/build/build-windows.sh clean debug
```

> **Note**: The script uses low-memory mode by default (`-O1` + single-threaded) to avoid memory overflow during QRC compilation.

### 4. Build Output

| Type | Path |
|------|------|
| Executable | `build-windows/bin/JinGo.exe` |
| Deploy directory | `pkg/JinGo-1.0.0/` |
| ZIP package | `pkg/jingo-{brand}-{version}-{date}-windows.zip` |
| Release copy | `release/jingo-{brand}-{version}-{date}-windows.zip` |

## Build Options Quick Reference

| Option | macOS | iOS | Android | Linux | Windows |
|--------|-------|-----|---------|-------|---------|
| Clean rebuild | `--clean` | `--clean` | `--clean` | `--clean` | `clean` |
| Release mode | `--release` | `--release` | `--release` | `--release` | (default) |
| Debug mode | `--debug` | `--debug` | `--debug` | `--debug` | `debug` |
| Skip signing | `--skip-sign` | `--skip-sign` | - | - | - |
| Code signing | `--sign` | `--team-id` | `--sign` | - | - |
| Create package | `--dmg` | - | - | `--package` | (auto) |
| Install | `--open` | `--install` | `--install` | - | - |
| Xcode project | `--xcode` | `--xcode` | - | - | - |
| Target arch | - | - | `--abi` | - | - |
| Brand ID | `--brand` / env `BRAND` | `--brand` / env `BRAND` | env `BRAND` | `--brand` / env `BRAND` | env `BRAND` |

## Output Locations

| Platform | Debug | Release | Release Package |
|----------|-------|---------|-----------------|
| macOS | `build-macos/bin/Debug/JinGo.app` | `build-macos/bin/Release/JinGo.app` | `release/*.dmg` |
| iOS | `build-ios/bin/Debug/JinGo.app` | `build-ios/bin/Release/JinGo.app` | `release/*.ipa` |
| Android | `build-android/.../debug/*.apk` | `build-android/.../release/*.apk` | `release/*.apk` |
| Linux | `build-linux/bin/JinGo` | Same | `release/*.tar.gz` |
| Windows | `build-windows/bin/JinGo.exe` | Same | `release/*.zip` |

All release artifacts are placed in the `release/` directory.

## FAQ

### Q: Qt not found?

Ensure the Qt path in build script or environment variable is correct and the directory exists.

### Q: macOS app crashes on launch?

Root privileges required: `sudo open build-macos/bin/Debug/JinGo.app`

### Q: iOS build fails without Team ID?

Use `--skip-sign` to skip signing for compile-only verification:
```bash
./scripts/build/build-ios.sh --skip-sign
```

### Q: Linux network not working?

Root privileges or capabilities required:
```bash
sudo setcap cap_net_admin+eip build-linux/bin/JinGo
```

### Q: Android NDK error?

Ensure `ANDROID_NDK_VERSION` matches the actually installed NDK version.

### Q: Windows build runs out of memory?

The script already uses low-memory mode (`-O1` + single-threaded). Ensure at least 4GB RAM available.

---

## OneDev CI/CD Auto Build

Project uses OneDev CI/CD for multi-platform automated builds. Config file: `.onedev-buildspec.yml`.

### Brand Parameter

All CI jobs accept a `brand` parameter (numeric ID). Passed via `BRAND=<id>` environment variable. Build scripts automatically load resources from `white-labeling/<id>/`.

Each platform has its own default brand ID in the build script:

| Platform | Default Brand ID |
|----------|-----------------|
| Windows | 1 |
| macOS | 2 |
| Android | 3 |
| Linux | 4 |
| iOS | 5 |

### JinDoCore Dependency

JinGo depends on pre-compiled JinDoCore static libraries (not compiled in CI). SuperRay is merged into JinDoCore (except Android which needs libsuperray.so for JNI).

### CI Build Flow

All platforms follow a unified flow:

1. **Checkout** - Clone repository with submodules
2. **Verify Dependencies** - Check JinDoCore libraries and white-label resources exist
3. **Build Release** - Clean build with `--clean --release` and platform-specific flags
4. **Publish Artifacts** - Publish from `release/` directory

Platform-specific build commands:

| Platform | Executor | Build Command |
|----------|----------|---------------|
| macOS | macos-builder | `build-macos.sh --clean --release --dmg --skip-sign` |
| iOS | macos-builder | `build-ios.sh --clean --release --skip-sign` |
| Android | linux-builder | `build-android.sh --clean --release` |
| Linux | linux-builder | `build-linux.sh --clean --release --deploy --package` |
| Windows | windows-builder | `build-windows.sh clean` (via MSYS2) |

> **Note**: macOS and iOS CI builds use `--skip-sign` to skip code signing. macOS defaults to no signing even without this flag, but CI specifies it explicitly for clarity.

### CI Environment

| Platform | Key Environment |
|----------|----------------|
| macOS/iOS | Xcode: `/Volumes/mindata/Xcode.app`, Qt: `/Volumes/mindata/Qt/6.10.1/{macos,ios}` |
| Android | Qt: `/mnt/dev/Qt/6.10.1`, SDK: `/mnt/dev/Android/Sdk`, NDK: `29.0.14206865`, Java 21 |
| Linux | Qt: `/mnt/dev/Qt/6.10.1/gcc_64` |
| Windows | MSYS2: `D:\msys64` |

All CI builds set `JINDO_ENABLE_LICENSE_CHECK=ON` to enable license verification in release artifacts.

### Build Artifacts

All platforms publish artifacts to the `release/` directory:

| Platform | Output | Notes |
|----------|--------|-------|
| macOS | `release/*.dmg` | Self-signed, right-click to open |
| iOS | `release/*.ipa` | Unsigned, use AltStore/Sideloadly |
| Android | `release/*.apk` | Debug-signed |
| Linux | `release/*.tar.gz` / `*.deb` | Needs setcap or sudo |
| Windows | `release/*.zip` | May trigger SmartScreen |

### CI Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `undefined reference: SuperRay_*` | libJinDoCore.a missing SuperRay symbols | Rebuild JinDo with ar/libtool merge step |
| `superray.h: No such file` | JinDo build didn't export header | Check JinDo build script copy paths |
| `cannot find -lsuperray` | Stale CMake dynamic library reference | Remove SuperRay DLL references from CMakeLists.txt |
| CMake compiler not found | MSYS2/MinGW misconfigured | Check toolchain installation |
| Windows out of memory | QRC compilation memory usage | Already configured: low-memory mode (O1 + single-threaded) |
| iOS fails without Team ID | Missing `--skip-sign` | Add `--skip-sign` to CI build args |

---

## Next Steps

- [Development Guide](03_DEVELOPMENT.md)
- [White-labeling](04_WHITE_LABELING.md)
- [Troubleshooting](05_TROUBLESHOOTING.md)
