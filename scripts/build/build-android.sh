#!/bin/bash
# ============================================================================
# JinGo VPN - Android 构建脚本
# ============================================================================
# 描述：编译 Android 应用 (支持 macOS 和 Linux)
#
# 功能：编译 APK、签名、安装到设备
# 依赖：macOS/Linux, Android SDK, Android NDK, Qt for Android, CMake 3.21+
# 版本：1.3.0
# ============================================================================

set -e  # 遇到错误立即退出

# ============================================================================
# ██████╗  ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
# ██╔══██╗ ██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
# ██████╔╝ ██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
# ██╔═══╝  ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
# ██║      ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
# ╚═╝      ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
#              用户配置 - 修改下面的路径以匹配您的环境
# ============================================================================

# --------------------- Qt 路径配置 ---------------------
# Qt 基础路径（包含 android_arm64_v8a 等子目录）
# 优先使用环境变量 QT_BASE_PATH 或从 Qt6_DIR 推导，否则使用默认值
# 本地开发请修改下面的默认路径，或设置环境变量
# macOS 示例: "/Users/yourname/Qt/6.8.0"
# Linux 示例: "/opt/Qt/6.8.0"
if [[ -n "${QT_BASE_PATH:-}" ]]; then
    : # 使用已设置的 QT_BASE_PATH
elif [[ -n "${Qt6_DIR:-}" ]]; then
    # Qt6_DIR 指向 android_arm64_v8a/lib/cmake/Qt6，取其父目录的父目录的父目录的父目录
    QT_BASE_PATH="$(dirname "$(dirname "$(dirname "$(dirname "$Qt6_DIR")")")")"
else
    # 需要在后面调用 auto_detect_qt_base()，此处先不设置
    QT_BASE_PATH=""
fi

# --------------------- 脚本初始化 ---------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载白标资源复制脚本
if [[ -f "$SCRIPT_DIR/copy-brand-assets.sh" ]]; then
    source "$SCRIPT_DIR/copy-brand-assets.sh"
fi

# 检测当前操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

CURRENT_OS="$(detect_os)"

# 自动检测 Qt 路径
auto_detect_qt_base() {
    # 常见路径（包括 macOS 和 Linux）
    local COMMON_PATHS=(
        "/mnt/dev/Qt"
        "$HOME/Qt"
        "/opt/Qt"
        "/usr/local/Qt"
        "$HOME/Applications/Qt"
        "/Volumes/mindata/Applications/Qt"
        "/Applications/Qt"
    )

    for base in "${COMMON_PATHS[@]}"; do
        if [ -d "$base" ]; then
            # 查找最新版本
            local latest=$(ls -1 "$base" 2>/dev/null | grep -E '^[0-9]+\.' | sort -V | tail -1)
            if [ -n "$latest" ] && [ -d "$base/$latest" ]; then
                echo "$base/$latest"
                return 0
            fi
        fi
    done

    # 回退到默认值
    echo "/Volumes/mindata/Applications/Qt/6.10.0"
}

# 获取 Qt 版本号
get_qt_version() {
    if [[ -n "$QT_BASE_PATH" ]]; then
        basename "$QT_BASE_PATH"
    else
        echo "6.10.0"
    fi
}

# 获取 Qt Host 路径 (用于交叉编译时的宿主工具)
get_qt_host_path() {
    local qt_base="$1"
    case "$CURRENT_OS" in
        macos)
            echo "${qt_base}/macos"
            ;;
        linux)
            echo "${qt_base}/gcc_64"
            ;;
        *)
            echo "${qt_base}/macos"  # fallback
            ;;
    esac
}

QT_VERSION="$(get_qt_version)"
QT_BASE_PATH="${QT_BASE_PATH:-$(auto_detect_qt_base)}"
# 优先使用环境变量中的 QT_HOST_PATH
QT_HOST_PATH="${QT_HOST_PATH:-$(get_qt_host_path "$QT_BASE_PATH")}"

# Qt Android 各架构路径
QT_ANDROID_ARM64="${QT_BASE_PATH}/android_arm64_v8a"
QT_ANDROID_ARMV7="${QT_BASE_PATH}/android_armv7"
QT_ANDROID_X86="${QT_BASE_PATH}/android_x86"
QT_ANDROID_X86_64="${QT_BASE_PATH}/android_x86_64"

# --------------------- Android SDK/NDK 配置 ---------------------
# 自动检测 Android SDK 路径
auto_detect_android_sdk() {
    # 优先使用环境变量
    if [[ -n "$ANDROID_SDK_ROOT" ]] && [[ -d "$ANDROID_SDK_ROOT" ]]; then
        echo "$ANDROID_SDK_ROOT"
        return 0
    fi
    if [[ -n "$ANDROID_HOME" ]] && [[ -d "$ANDROID_HOME" ]]; then
        echo "$ANDROID_HOME"
        return 0
    fi

    # 根据操作系统选择搜索路径
    local search_paths=()
    if [[ "$CURRENT_OS" == "macos" ]]; then
        search_paths=(
            "/Volumes/mindata/Library/Android/aarch64/sdk"
            "/Volumes/mindata/Library/Android/sdk"
            "$HOME/Library/Android/sdk"
        )
    elif [[ "$CURRENT_OS" == "linux" ]]; then
        search_paths=(
            "/mnt/develop/Android/Sdk"
            "/mnt/dev/Android/Sdk"
            "$HOME/Android/Sdk"
            "/opt/android-sdk"
        )
    fi

    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# Android SDK 路径 (可通过环境变量 ANDROID_SDK_ROOT 覆盖)
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$(auto_detect_android_sdk)}"

# Android NDK 版本和路径 (根据平台选择默认版本)
if [[ "$CURRENT_OS" == "linux" ]]; then
    ANDROID_NDK_VERSION="${ANDROID_NDK_VERSION:-29.0.14206865}"
else
    ANDROID_NDK_VERSION="${ANDROID_NDK_VERSION:-27.2.12479018}"
fi
ANDROID_NDK="${ANDROID_NDK:-$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK_VERSION}"

# --------------------- Android 构建配置 ---------------------
# 最低 SDK 版本
ANDROID_MIN_SDK=28

# 目标 SDK 版本
ANDROID_TARGET_SDK=34

# 默认 ABI: armeabi-v7a, arm64-v8a, x86, x86_64
DEFAULT_ABI="arm64-v8a"

# --------------------- OpenSSL 配置 ---------------------
# Android OpenSSL 路径 (留空则不使用)
ANDROID_OPENSSL="${ANDROID_OPENSSL:-}"

# --------------------- 签名配置 ---------------------
# APK 签名密钥库路径 (留空则不签名)
ANDROID_KEYSTORE="${ANDROID_KEYSTORE:-}"
# 密钥库密码 (建议使用环境变量)
ANDROID_KEYSTORE_PASSWORD="${ANDROID_KEYSTORE_PASSWORD:-}"
# 密钥别名
ANDROID_KEY_ALIAS="${ANDROID_KEY_ALIAS:-}"

# --------------------- 应用信息 ---------------------
APP_NAME="JinGo"

# ============================================================================
# 脚本内部变量 (一般不需要修改)
# ============================================================================
# SCRIPT_DIR 已在上面定义
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-android"
RELEASE_DIR="$PROJECT_ROOT/release"
CONFIGURATION="Debug"
CLEAN_BUILD=false
INSTALL_APP=false
SIGN_APK=false
ANDROID_ABI="$DEFAULT_ABI"
QT_ANDROID_PATH="$QT_ANDROID_ARM64"
BRAND_NAME=""
MULTI_ABI_BUILD=false
EXTRA_ABIS=""

# --------------------- 输出命名 ---------------------
# 获取构建日期 (YYYYMMDD 格式)
BUILD_DATE=$(date +%Y%m%d)

# 生成输出文件名: {brand}-{version}-{date}-{platform}.{ext}
generate_output_name() {
    local version="${1:-1.0.0}"
    local ext="${2:-}"
    local brand="${BRAND_NAME:-${BRAND:-jingo}}"
    local platform="android"

    if [[ -n "$ext" ]]; then
        echo "jingo-${brand}-${version}-${BUILD_DATE}-${platform}.${ext}"
    else
        echo "jingo-${brand}-${version}-${BUILD_DATE}-${platform}"
    fi
}

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${CYAN}[STEP]${NC} $1\n"
}

# 显示帮助信息
show_help() {
    cat << EOF
JinGoVPN Android 构建脚本

用法: $0 [选项]

选项:
    -c, --clean          清理构建目录
    -d, --debug          Debug 模式（默认）
    -r, --release        Release 模式
    -a, --abi ABI        指定 ABI (armeabi-v7a, arm64-v8a, x86, x86_64, all)
    -i, --install        安装到连接的 Android 设备
    -s, --sign           签名 APK (仅 Release 模式)
    -h, --help           显示帮助信息

环境变量:
    ANDROID_SDK_ROOT     Android SDK 路径
    ANDROID_NDK          Android NDK 路径
    Qt6_DIR             Qt 6 安装路径

支持的 ABI:
    armeabi-v7a         32位 ARM
    arm64-v8a           64位 ARM（默认）
    x86                 32位 x86（模拟器）
    x86_64              64位 x86（模拟器）
    all                 构建所有 ABI

示例:
    # 清理并编译 Debug 版本
    $0 --clean --debug

    # 编译 Release 版本并签名
    $0 --release --sign

    # 编译并安装到设备
    $0 --install

    # 编译所有 ABI
    $0 --abi all

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -d|--debug)
                CONFIGURATION="Debug"
                shift
                ;;
            -r|--release)
                CONFIGURATION="Release"
                shift
                ;;
            -a|--abi)
                if [[ "$2" == "all" ]]; then
                    # 多ABI构建：使用arm64-v8a作为主ABI，其他通过QT_ANDROID_ABIS指定
                    ANDROID_ABI="arm64-v8a"
                    MULTI_ABI_BUILD=true
                    EXTRA_ABIS="armeabi-v7a;x86_64"
                else
                    ANDROID_ABI="$2"
                    MULTI_ABI_BUILD=false
                fi
                shift 2
                ;;
            -i|--install)
                INSTALL_APP=true
                shift
                ;;
            -s|--sign)
                SIGN_APK=true
                shift
                ;;
            -b|--brand)
                if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                    print_error "--brand 需要指定品牌名称"
                    exit 1
                fi
                BRAND_NAME="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# 应用白标定制
# ============================================================================
apply_brand_customization() {
    # Android 平台默认使用品牌 3
    local brand_id="${BRAND_NAME:-${BRAND:-3}}"

    print_step "复制白标资源 (品牌: $brand_id)"

    # 使用 copy-brand-assets.sh 中的函数复制资源
    if type copy_brand_assets &> /dev/null; then
        if ! copy_brand_assets "$brand_id"; then
            print_warning "白标资源复制失败，使用默认资源继续"
        fi
    else
        print_warning "copy_brand_assets 函数未加载，跳过白标资源复制"
    fi
}

# 检查必要工具
check_requirements() {
    print_info "检查构建环境..."
    print_info "当前平台: $CURRENT_OS"

    # 检查 CMake
    if ! command -v cmake &> /dev/null; then
        if [[ "$CURRENT_OS" == "linux" ]]; then
            print_error "CMake 未安装。请安装: sudo apt install cmake"
        else
            print_error "CMake 未安装。请安装: brew install cmake"
        fi
        exit 1
    fi
    print_success "CMake: $(cmake --version | head -n1)"

    # 检查 Android SDK
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        print_error "未找到 Android SDK: $ANDROID_SDK_ROOT"
        print_info "请设置 ANDROID_SDK_ROOT 环境变量"
        exit 1
    fi
    print_success "Android SDK: $ANDROID_SDK_ROOT"

    # 检查 Android NDK
    if [ ! -d "$ANDROID_NDK" ]; then
        print_error "未找到 Android NDK: $ANDROID_NDK"
        print_info "请设置 ANDROID_NDK 环境变量"
        exit 1
    fi
    NDK_VERSION=$(basename "$ANDROID_NDK")
    print_success "Android NDK: $NDK_VERSION"

    # 检查 Qt for Android
    if [ ! -d "$QT_ANDROID_PATH" ]; then
        print_error "未找到 Qt Android 路径: $QT_ANDROID_PATH"
        print_info "请确保已安装 Qt ${QT_VERSION} for Android"
        exit 1
    fi
    print_success "Qt Android: $QT_ANDROID_PATH"

    # 检查 Qt Host 路径 (交叉编译需要)
    if [ ! -d "$QT_HOST_PATH" ]; then
        print_error "未找到 Qt Host 路径: $QT_HOST_PATH"
        print_info "Qt Host 路径用于交叉编译时的宿主工具"
        exit 1
    fi
    print_success "Qt Host: $QT_HOST_PATH"

    # 检查 OpenSSL
    if [ -d "$ANDROID_OPENSSL" ]; then
        print_success "OpenSSL: $ANDROID_OPENSSL"
    else
        print_warning "未找到 Android OpenSSL: $ANDROID_OPENSSL"
    fi

    # 检查 Java
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1)
        print_success "Java: $JAVA_VERSION"

        # Linux 上检查 JAVA_HOME
        if [[ "$CURRENT_OS" == "linux" ]]; then
            if [[ -z "$JAVA_HOME" ]]; then
                # 尝试自动检测 JAVA_HOME (按版本优先级排序)
                if [[ -d "/usr/lib/jvm/default-java" ]]; then
                    export JAVA_HOME="/usr/lib/jvm/default-java"
                elif [[ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]]; then
                    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
                elif [[ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]]; then
                    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
                elif [[ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]]; then
                    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
                fi
            fi
            if [[ -n "$JAVA_HOME" ]]; then
                print_success "JAVA_HOME: $JAVA_HOME"
            else
                print_warning "JAVA_HOME 未设置，Gradle 构建可能会失败"
            fi
        fi
    else
        print_warning "未找到 Java，APK 签名可能无法工作"
        if [[ "$CURRENT_OS" == "linux" ]]; then
            print_info "安装 Java: sudo apt install openjdk-21-jdk"
        fi
    fi

    print_success "构建环境检查完成"
}

# 清理构建目录
clean_build_dir() {
    if [ "$CLEAN_BUILD" = true ]; then
        print_info "清理构建目录: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
        print_success "构建目录已清理"
    fi
}

# 根据 ABI 获取正确的 Qt 路径
get_qt_path_for_abi() {
    local abi="$1"
    case "$abi" in
        armeabi-v7a)
            echo "${QT_BASE_PATH}/android_armv7"
            ;;
        arm64-v8a)
            echo "${QT_BASE_PATH}/android_arm64_v8a"
            ;;
        x86)
            echo "${QT_BASE_PATH}/android_x86"
            ;;
        x86_64)
            echo "${QT_BASE_PATH}/android_x86_64"
            ;;
        *)
            echo "${QT_BASE_PATH}/android_arm64_v8a"
            ;;
    esac
}

# 配置 CMake
configure_cmake() {
    print_info "配置 CMake..."
    print_info "  项目目录: $PROJECT_ROOT"
    print_info "  构建目录: $BUILD_DIR"
    print_info "  ABI: $ANDROID_ABI"
    print_info "  配置: $CONFIGURATION"
    print_info "  平台: $CURRENT_OS"

    # 根据 ABI 获取 Qt 路径
    QT_ANDROID_PATH=$(get_qt_path_for_abi "$ANDROID_ABI")
    print_info "  Qt Android: $QT_ANDROID_PATH"
    print_info "  Qt Host: $QT_HOST_PATH"

    mkdir -p "$BUILD_DIR"

    # CMake 参数
    CMAKE_ARGS=(
        -S "$PROJECT_ROOT"
        -B "$BUILD_DIR"
        -DCMAKE_TOOLCHAIN_FILE="$QT_ANDROID_PATH/lib/cmake/Qt6/qt.toolchain.cmake"
        -DCMAKE_PREFIX_PATH="$QT_ANDROID_PATH"
        -DQT_HOST_PATH="$QT_HOST_PATH"
        -DANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
        -DANDROID_NDK_ROOT="$ANDROID_NDK"
        -DANDROID_ABI="$ANDROID_ABI"
        -DANDROID_PLATFORM=android-28
        -DCMAKE_BUILD_TYPE="$CONFIGURATION"
        -DANDROID_STL=c++_shared
    )

    # 添加 OpenSSL 路径
    if [ -d "$ANDROID_OPENSSL" ]; then
        CMAKE_ARGS+=(
            -DANDROID_OPENSSL_ROOT="$ANDROID_OPENSSL"
            -DOPENSSL_ROOT_DIR="$ANDROID_OPENSSL"
            -DOPENSSL_INCLUDE_DIR="$ANDROID_OPENSSL/include"
        )
        print_info "  OpenSSL: $ANDROID_OPENSSL"
    fi

    # 多ABI构建支持
    if [[ "$MULTI_ABI_BUILD" == "true" ]] && [[ -n "$EXTRA_ABIS" ]]; then
        CMAKE_ARGS+=(
            -DQT_ANDROID_BUILD_ALL_ABIS=ON
            -DQT_ANDROID_ABIS="$ANDROID_ABI;$EXTRA_ABIS"
        )
        print_info "  多ABI构建: $ANDROID_ABI;$EXTRA_ABIS"
    fi

    # 授权验证开关
    if [[ "${JINDO_ENABLE_LICENSE_CHECK:-}" == "ON" ]]; then
        CMAKE_ARGS+=(-DJINDO_ENABLE_LICENSE_CHECK=ON)
        print_info "  启用授权验证 (JINDO_ENABLE_LICENSE_CHECK=ON)"
    fi

    cmake "${CMAKE_ARGS[@]}"

    print_success "CMake 配置成功"
}

# 编译项目
build_project() {
    print_info "开始编译 Android 应用..."
    print_info "  配置: $CONFIGURATION"

    cd "$BUILD_DIR"

    # 获取 CPU 核心数 (根据平台选择合适的命令)
    if [[ "$CURRENT_OS" == "linux" ]]; then
        NPROC=$(nproc 2>/dev/null || echo 4)
    else
        NPROC=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    fi

    # 构建项目
    cmake --build . --config "$CONFIGURATION" -j"$NPROC" 2>&1 | \
        grep -E "Building|Compiling|Linking|error:|warning:|BUILD|===" || true

    # 检查是否需要创建 APK
    if [ -f "$BUILD_DIR/android-build/build.gradle" ]; then
        print_info "构建 Android APK..."
        cd "$BUILD_DIR/android-build"

        if [ "$CONFIGURATION" = "Release" ]; then
            ./gradlew assembleRelease
        else
            ./gradlew assembleDebug
        fi
    fi

    # 查找生成的 APK
    APK_PATH=$(find "$BUILD_DIR" -name "*.apk" -type f 2>/dev/null | grep -v "unsigned" | head -1)

    if [ -n "$APK_PATH" ]; then
        print_success "编译成功！"
        print_info "APK 位置: $APK_PATH"

        # 显示 APK 信息
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        print_info "APK 大小: $APK_SIZE"
    else
        # 尝试查找其他 APK
        APK_PATH=$(find "$BUILD_DIR" -name "*.apk" -type f 2>/dev/null | head -1)
        if [ -n "$APK_PATH" ]; then
            print_success "编译成功！"
            print_info "APK 位置: $APK_PATH"
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            print_info "APK 大小: $APK_SIZE"
        else
            print_warning "未找到 APK，请检查构建输出"
            print_info "可能需要在 Qt Creator 中完成 Android 部署配置"
        fi
    fi
}

# 签名 APK
sign_apk() {
    if [ "$SIGN_APK" = false ] || [ "$CONFIGURATION" != "Release" ]; then
        return
    fi

    print_info "准备签名 APK..."

    KEYSTORE="$PROJECT_ROOT/android/keystore.jks"
    if [ ! -f "$KEYSTORE" ]; then
        print_warning "未找到 keystore 文件: $KEYSTORE"
        print_info "跳过签名步骤"
        return
    fi

    APK_PATH=$(find "$BUILD_DIR" -name "*-release-unsigned.apk" -type f | head -1)
    if [ -z "$APK_PATH" ]; then
        print_warning "未找到未签名的 APK"
        return
    fi

    SIGNED_APK="${APK_PATH%-unsigned.apk}-signed.apk"

    # 使用 apksigner 签名
    if command -v apksigner &> /dev/null; then
        apksigner sign --ks "$KEYSTORE" \
            --out "$SIGNED_APK" \
            "$APK_PATH"
        print_success "APK 签名成功: $SIGNED_APK"
    else
        print_warning "未找到 apksigner 工具，跳过签名"
    fi
}

# 安装到设备
install_to_device() {
    if [ "$INSTALL_APP" = false ]; then
        return
    fi

    print_info "准备安装应用到 Android 设备..."

    # 检查 adb
    if ! command -v adb &> /dev/null; then
        print_error "未找到 adb 工具"
        exit 1
    fi

    # 检查设备连接
    DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        print_error "未找到已连接的 Android 设备"
        print_info "请确保已连接设备并启用了 USB 调试"
        exit 1
    fi

    # 查找 APK
    if [ "$SIGN_APK" = true ]; then
        APK_PATH=$(find "$BUILD_DIR" -name "*-signed.apk" -type f | head -1)
    fi

    if [ -z "$APK_PATH" ]; then
        APK_PATH=$(find "$BUILD_DIR" -name "*.apk" -type f | grep -i "$CONFIGURATION" | head -1)
    fi

    if [ -z "$APK_PATH" ]; then
        print_error "未找到 APK 文件"
        exit 1
    fi

    print_info "安装 APK: $APK_PATH"
    adb install -r "$APK_PATH"

    print_success "应用安装成功！"
}

# ============================================================================
# 复制到 release 目录
# ============================================================================
copy_to_release() {
    if [[ "$CONFIGURATION" != "Release" ]]; then
        return
    fi

    print_info "复制构建产物到 release 目录..."

    # 创建 release 目录
    mkdir -p "$RELEASE_DIR"

    # 查找 APK 文件
    APK_PATH=$(find "$BUILD_DIR" -name "*.apk" -type f 2>/dev/null | grep -v "unsigned" | head -1)

    if [[ -n "$APK_PATH" ]] && [[ -f "$APK_PATH" ]]; then
        # 获取版本号 (从文件名或使用默认)
        local version="1.0.0"
        # 使用统一命名: {brand}-{version}-{date}-{platform}.{ext}
        local apk_name=$(generate_output_name "$version" "apk")

        cp "$APK_PATH" "$RELEASE_DIR/$apk_name"

        if [[ -f "$RELEASE_DIR/$apk_name" ]]; then
            print_success "已复制: $RELEASE_DIR/$apk_name"
        fi
    fi

    print_success "构建产物已复制到: $RELEASE_DIR"
}

# 主函数
main() {
    echo ""
    echo "=================================================="
    echo "      JinGoVPN Android 构建脚本"
    echo "=================================================="
    echo ""

    parse_args "$@"
    apply_brand_customization
    check_requirements
    clean_build_dir
    configure_cmake
    build_project
    sign_apk
    copy_to_release
    install_to_device

    echo ""
    print_success "=================================================="
    print_success "                全部完成！"
    print_success "=================================================="
    echo ""

    # 显示后续步骤提示
    APK_PATH=$(find "$BUILD_DIR" -name "*.apk" -type f 2>/dev/null | grep -v "unsigned" | head -1)
    if [ -n "$APK_PATH" ]; then
        print_info "下一步:"
        echo "  1. 安装 APK 到设备:"
        echo "     adb install -r $APK_PATH"
        echo "  2. 或通过 WiFi 安装:"
        echo "     将 APK 文件传输到设备并安装"
        echo ""
    fi
}

# 执行主函数
main "$@"
