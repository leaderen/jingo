#!/bin/bash
# ============================================================================
# JinGo VPN - Android 签名和发布脚本
# ============================================================================
# 功能：APK/AAB 签名、上传到 Google Play
#
# 用法：
#   ./post_build_android.sh --sign <apk路径>           # 签名 APK
#   ./post_build_android.sh --sign-aab <aab路径>       # 签名 AAB
#   ./post_build_android.sh --upload <aab路径>         # 上传到 Google Play
#   ./post_build_android.sh --create-keystore          # 创建签名密钥
#
# 版本：1.0.0
# ============================================================================

set -e

# ============================================================================
# ██████╗  ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
# ██╔══██╗ ██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
# ██████╔╝ ██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
# ██╔═══╝  ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
# ██║      ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
# ╚═╝      ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
#                    平台配置 - 修改这里的值来调整签名设置
# ============================================================================

# --------------------- 签名密钥配置 ---------------------
# Keystore 文件路径 (可通过环境变量 ANDROID_KEYSTORE 覆盖)
KEYSTORE_PATH="${ANDROID_KEYSTORE:-}"

# Keystore 密码 (可通过环境变量 ANDROID_KEYSTORE_PASSWORD 覆盖)
KEYSTORE_PASSWORD="${ANDROID_KEYSTORE_PASSWORD:-}"

# Key 别名 (可通过环境变量 ANDROID_KEY_ALIAS 覆盖)
KEY_ALIAS="${ANDROID_KEY_ALIAS:-jingo}"

# Key 密码 (可通过环境变量 ANDROID_KEY_PASSWORD 覆盖)
KEY_PASSWORD="${ANDROID_KEY_PASSWORD:-}"

# --------------------- Google Play 配置 ---------------------
# 服务账号 JSON 文件路径 (用于上传到 Google Play)
# 在 Google Play Console -> API 访问 -> 服务账号 中创建
GOOGLE_SERVICE_ACCOUNT="${GOOGLE_SERVICE_ACCOUNT_JSON:-}"

# 应用包名
PACKAGE_NAME="cfd.jingo.acc"

# 上传轨道: internal, alpha, beta, production
DEFAULT_TRACK="internal"

# --------------------- Android SDK 配置 ---------------------
# Android SDK 路径 (用于 apksigner 等工具)
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-}"
ANDROID_BUILD_TOOLS_VERSION="34.0.0"

# --------------------- 应用信息 ---------------------
APP_NAME="JinGo"

# ============================================================================
# 脚本内部变量
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
    echo ""
    echo "============================================"
    echo "  $1"
    echo "============================================"
}

# ============================================================================
# 查找工具路径
# ============================================================================
find_build_tools() {
    if [ -n "$ANDROID_SDK_ROOT" ]; then
        BUILD_TOOLS_DIR="$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION"
        if [ -d "$BUILD_TOOLS_DIR" ]; then
            APKSIGNER="$BUILD_TOOLS_DIR/apksigner"
            ZIPALIGN="$BUILD_TOOLS_DIR/zipalign"
            return 0
        fi
    fi

    # 尝试在 PATH 中查找
    if command -v apksigner &> /dev/null; then
        APKSIGNER="apksigner"
        ZIPALIGN="zipalign"
        return 0
    fi

    print_error "未找到 Android Build Tools"
    print_info "请设置 ANDROID_SDK_ROOT 环境变量"
    return 1
}

# ============================================================================
# 创建签名密钥
# ============================================================================
create_keystore() {
    print_header "创建 Android 签名密钥"

    local output_path="${1:-$PROJECT_ROOT/android/keystore.jks}"
    local alias="${2:-$KEY_ALIAS}"

    print_info "输出路径: $output_path"
    print_info "Key 别名: $alias"

    # 创建目录
    mkdir -p "$(dirname "$output_path")"

    # 生成密钥
    keytool -genkey -v \
        -keystore "$output_path" \
        -alias "$alias" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000

    if [ -f "$output_path" ]; then
        print_success "✓ Keystore 创建成功: $output_path"
        print_warning "请妥善保管密钥和密码！"
        print_info "建议将以下环境变量添加到你的 shell 配置文件："
        echo ""
        echo "export ANDROID_KEYSTORE=\"$output_path\""
        echo "export ANDROID_KEY_ALIAS=\"$alias\""
        echo "export ANDROID_KEYSTORE_PASSWORD=\"your-keystore-password\""
        echo "export ANDROID_KEY_PASSWORD=\"your-key-password\""
    else
        print_error "Keystore 创建失败"
        exit 1
    fi
}

# ============================================================================
# 签名 APK
# ============================================================================
sign_apk() {
    local apk_path="$1"
    local output_path="${2:-}"

    print_header "签名 APK"

    if [ -z "$apk_path" ] || [ ! -f "$apk_path" ]; then
        print_error "请提供有效的 APK 文件路径"
        exit 1
    fi

    # 检查密钥配置
    if [ -z "$KEYSTORE_PATH" ] || [ ! -f "$KEYSTORE_PATH" ]; then
        print_error "请设置 ANDROID_KEYSTORE 环境变量指向有效的 keystore 文件"
        exit 1
    fi

    if [ -z "$KEYSTORE_PASSWORD" ]; then
        print_error "请设置 ANDROID_KEYSTORE_PASSWORD 环境变量"
        exit 1
    fi

    find_build_tools || exit 1

    # 设置输出路径
    if [ -z "$output_path" ]; then
        output_path="${apk_path%.apk}-signed.apk"
    fi

    print_info "输入: $apk_path"
    print_info "输出: $output_path"
    print_info "Keystore: $KEYSTORE_PATH"
    print_info "Key 别名: $KEY_ALIAS"

    # 对齐 APK (如果需要)
    local aligned_apk="/tmp/aligned.apk"
    "$ZIPALIGN" -v -p 4 "$apk_path" "$aligned_apk"

    # 签名
    "$APKSIGNER" sign \
        --ks "$KEYSTORE_PATH" \
        --ks-pass "pass:$KEYSTORE_PASSWORD" \
        --ks-key-alias "$KEY_ALIAS" \
        --key-pass "pass:${KEY_PASSWORD:-$KEYSTORE_PASSWORD}" \
        --out "$output_path" \
        "$aligned_apk"

    # 清理临时文件
    rm -f "$aligned_apk"

    # 验证签名
    if "$APKSIGNER" verify "$output_path"; then
        print_success "✓ APK 签名成功: $output_path"
    else
        print_error "APK 签名验证失败"
        exit 1
    fi
}

# ============================================================================
# 签名 AAB
# ============================================================================
sign_aab() {
    local aab_path="$1"
    local output_path="${2:-}"

    print_header "签名 AAB"

    if [ -z "$aab_path" ] || [ ! -f "$aab_path" ]; then
        print_error "请提供有效的 AAB 文件路径"
        exit 1
    fi

    # 检查密钥配置
    if [ -z "$KEYSTORE_PATH" ] || [ ! -f "$KEYSTORE_PATH" ]; then
        print_error "请设置 ANDROID_KEYSTORE 环境变量指向有效的 keystore 文件"
        exit 1
    fi

    if [ -z "$KEYSTORE_PASSWORD" ]; then
        print_error "请设置 ANDROID_KEYSTORE_PASSWORD 环境变量"
        exit 1
    fi

    # 设置输出路径
    if [ -z "$output_path" ]; then
        output_path="${aab_path%.aab}-signed.aab"
    fi

    print_info "输入: $aab_path"
    print_info "输出: $output_path"

    # 使用 jarsigner 签名 AAB
    cp "$aab_path" "$output_path"
    jarsigner -verbose \
        -keystore "$KEYSTORE_PATH" \
        -storepass "$KEYSTORE_PASSWORD" \
        -keypass "${KEY_PASSWORD:-$KEYSTORE_PASSWORD}" \
        "$output_path" \
        "$KEY_ALIAS"

    # 验证签名
    if jarsigner -verify "$output_path"; then
        print_success "✓ AAB 签名成功: $output_path"
    else
        print_error "AAB 签名验证失败"
        exit 1
    fi
}

# ============================================================================
# 上传到 Google Play
# ============================================================================
upload_to_playstore() {
    local file_path="$1"
    local track="${2:-$DEFAULT_TRACK}"

    print_header "上传到 Google Play"

    if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
        print_error "请提供有效的 APK 或 AAB 文件路径"
        exit 1
    fi

    # 检查服务账号配置
    if [ -z "$GOOGLE_SERVICE_ACCOUNT" ] || [ ! -f "$GOOGLE_SERVICE_ACCOUNT" ]; then
        print_error "请设置 GOOGLE_SERVICE_ACCOUNT_JSON 环境变量"
        print_info "在 Google Play Console -> API 访问 -> 服务账号 中创建服务账号"
        print_info "下载 JSON 密钥文件并设置环境变量"
        exit 1
    fi

    print_info "文件: $file_path"
    print_info "包名: $PACKAGE_NAME"
    print_info "轨道: $track"

    # 检查是否安装了 fastlane
    if command -v fastlane &> /dev/null; then
        print_info "使用 fastlane 上传..."

        # 确定文件类型
        local file_type="apk"
        if [[ "$file_path" == *.aab ]]; then
            file_type="aab"
        fi

        fastlane supply \
            --json_key "$GOOGLE_SERVICE_ACCOUNT" \
            --package_name "$PACKAGE_NAME" \
            --track "$track" \
            --$file_type "$file_path"

        print_success "✓ 上传成功！"
        print_info "请在 Google Play Console 中查看"
        print_info "URL: https://play.google.com/console"
    else
        print_warning "fastlane 未安装"
        print_info "请安装 fastlane: gem install fastlane"
        print_info "或者手动在 Google Play Console 上传"
        exit 1
    fi
}

# ============================================================================
# 检查签名配置
# ============================================================================
check_config() {
    print_header "检查 Android 签名配置"

    local has_errors=0

    # 检查 Keystore
    echo ""
    print_info "检查签名密钥..."
    if [ -n "$KEYSTORE_PATH" ] && [ -f "$KEYSTORE_PATH" ]; then
        print_success "  ✓ Keystore: $KEYSTORE_PATH"
        # 显示密钥信息
        keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "${KEYSTORE_PASSWORD:-changeit}" 2>/dev/null | head -20 || true
    else
        print_warning "  ⚠ Keystore 未配置或不存在"
        has_errors=1
    fi

    # 检查 Android SDK
    echo ""
    print_info "检查 Android SDK..."
    if [ -n "$ANDROID_SDK_ROOT" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
        print_success "  ✓ Android SDK: $ANDROID_SDK_ROOT"

        # 检查 build-tools
        if [ -d "$ANDROID_SDK_ROOT/build-tools" ]; then
            local latest_tools=$(ls -1 "$ANDROID_SDK_ROOT/build-tools" | sort -V | tail -1)
            print_success "  ✓ Build Tools: $latest_tools"
        fi
    else
        print_warning "  ⚠ ANDROID_SDK_ROOT 未设置"
        has_errors=1
    fi

    # 检查 Google Play 服务账号
    echo ""
    print_info "检查 Google Play 配置..."
    if [ -n "$GOOGLE_SERVICE_ACCOUNT" ] && [ -f "$GOOGLE_SERVICE_ACCOUNT" ]; then
        print_success "  ✓ 服务账号: $GOOGLE_SERVICE_ACCOUNT"
    else
        print_warning "  ⚠ Google Play 服务账号未配置 (上传功能不可用)"
    fi

    # 检查 fastlane
    echo ""
    print_info "检查工具..."
    if command -v fastlane &> /dev/null; then
        print_success "  ✓ fastlane: $(fastlane --version | head -1)"
    else
        print_warning "  ⚠ fastlane 未安装 (上传功能需要)"
    fi

    if command -v keytool &> /dev/null; then
        print_success "  ✓ keytool: 可用"
    else
        print_warning "  ⚠ keytool 未找到"
        has_errors=1
    fi

    echo ""
    if [ $has_errors -eq 0 ]; then
        print_success "配置检查通过！"
    else
        print_warning "部分配置缺失，请检查上述警告"
    fi
}

# ============================================================================
# 显示帮助
# ============================================================================
show_help() {
    cat << EOF
JinGo VPN Android 签名和发布脚本 v1.0.0

用法: $0 [选项]

签名:
  --sign <apk>               签名 APK 文件
  --sign-aab <aab>           签名 AAB 文件 (App Bundle)
  --create-keystore [path]   创建新的签名密钥

发布:
  --upload <apk|aab> [track] 上传到 Google Play
                             track: internal, alpha, beta, production

检查:
  --check                    检查签名配置

帮助:
  --help                     显示此帮助信息

环境变量:
  ANDROID_KEYSTORE             Keystore 文件路径
  ANDROID_KEYSTORE_PASSWORD    Keystore 密码
  ANDROID_KEY_ALIAS            Key 别名 (默认: jingo)
  ANDROID_KEY_PASSWORD         Key 密码
  GOOGLE_SERVICE_ACCOUNT_JSON  Google Play 服务账号 JSON 文件
  ANDROID_SDK_ROOT             Android SDK 路径

示例:
  # 检查配置
  $0 --check

  # 创建签名密钥
  $0 --create-keystore

  # 签名 APK
  export ANDROID_KEYSTORE="/path/to/keystore.jks"
  export ANDROID_KEYSTORE_PASSWORD="your-password"
  $0 --sign build/android/app-release-unsigned.apk

  # 签名 AAB
  $0 --sign-aab build/android/app-release.aab

  # 上传到 Google Play 内部测试
  export GOOGLE_SERVICE_ACCOUNT_JSON="/path/to/service-account.json"
  $0 --upload app-release-signed.aab internal

  # 上传到生产环境
  $0 --upload app-release-signed.aab production

完整发布流程:
  1. 创建签名密钥 (首次)
     $0 --create-keystore

  2. 编译 Release AAB
     ./scripts/build/build-android.sh --release

  3. 签名 AAB
     $0 --sign-aab build/android/app-release.aab

  4. 上传到 Google Play
     $0 --upload app-release-signed.aab internal

EOF
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    case "${1:-}" in
        --sign)
            shift
            sign_apk "$@"
            ;;
        --sign-aab)
            shift
            sign_aab "$@"
            ;;
        --create-keystore)
            shift
            create_keystore "$@"
            ;;
        --upload)
            shift
            upload_to_playstore "$@"
            ;;
        --check)
            check_config
            ;;
        --help|"")
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
