#!/bin/bash
# ============================================================================
# JinGo VPN - iOS 签名和发布脚本
# ============================================================================
# 功能：设备管理、应用签名、上传到 TestFlight/App Store
#
# 用法：
#   ./post_build_ios.sh --get-udid              # 获取设备 UDID
#   ./post_build_ios.sh --sign <app路径>        # 签名应用
#   ./post_build_ios.sh --upload <ipa路径>      # 上传到 App Store Connect
#   ./post_build_ios.sh --testflight <ipa路径>  # 上传到 TestFlight
#
# 版本：1.2.0
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

# --------------------- Apple 开发者配置 ---------------------
# 开发团队 ID
TEAM_ID="${APPLE_DEVELOPMENT_TEAM:-P6H5GHKRFU}"

# Bundle ID (从 Info.plist 读取，避免脚本内硬编码)
BUNDLE_ID=""

# --------------------- 签名身份配置 ---------------------
# 开发签名 (本地测试)
DEV_IDENTITY="${APPLE_CODE_SIGN_IDENTITY:-Apple Development}"

# 发布签名 - App Store
DIST_IDENTITY="iPhone Distribution"

# --------------------- Provisioning Profile 名称 ---------------------
# 主应用 Profile
PROFILE_MAIN="JinGo Accelerator iOS"
# PacketTunnelProvider Extension Profile
PROFILE_PACKET_TUNNEL="JinGo PacketTunnel iOS"

# --------------------- App Store Connect 配置 ---------------------
# Apple ID (可通过环境变量 APPLE_ID 覆盖)
APPLE_ID="${APPLE_ID:-}"

# App-specific password (可通过环境变量 APPLE_ID_PASSWORD 覆盖)
APPLE_ID_PASSWORD="${APPLE_ID_PASSWORD:-}"

# App Store Connect API Key (推荐用于 CI/CD)
ASC_API_KEY="${ASC_API_KEY:-}"
ASC_API_ISSUER="${ASC_API_ISSUER:-}"

# --------------------- 测试设备配置 ---------------------
# 默认测试设备 UDID
DEFAULT_DEVICE_UDID="00008030-001238903A90802E"

# --------------------- 应用信息 ---------------------
APP_NAME="JinGo"

# ============================================================================
# 脚本内部变量
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 从 Info.plist 读取 Bundle ID (避免脚本内硬编码)
read_bundle_id_from_plist() {
    local plist="$1"
    local value=""
    if [[ -f "$plist" ]]; then
        value=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null || true)
        if [[ -n "$value" && "$value" != *"\$("* && "$value" != *"PRODUCT_BUNDLE_IDENTIFIER"* ]]; then
            echo "$value"
            return 0
        fi
    fi
    return 1
}

DEFAULT_BUNDLE_ID="$(read_bundle_id_from_plist "$PROJECT_ROOT/platform/ios/Info.plist" || true)"
BUNDLE_ID="${BUNDLE_ID:-$DEFAULT_BUNDLE_ID}"
IDENTITY="$DEV_IDENTITY"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "============================================"
    echo "$1"
    echo "============================================"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================================================
# 获取连接的 iOS 设备 UDID
# ============================================================================
get_udid() {
    print_header "获取 iOS 设备 UDID"

    # 使用 xcrun devicectl (Xcode 15+)
    if command -v xcrun &> /dev/null; then
        print_success "使用 xcrun devicectl 查询设备..."
        echo ""

        # 尝试使用新版本的 devicectl
        if xcrun devicectl list devices 2>/dev/null | grep -E "iPhone|iPad"; then
            echo ""
            print_success "设备列表已显示"
        else
            # 回退到旧方法
            print_warning "xcrun devicectl 不可用，尝试其他方法..."

            # 检查是否安装了 idevice_id (libimobiledevice)
            if ! command -v idevice_id &> /dev/null; then
                print_warning "idevice_id 未安装，尝试使用 system_profiler..."

                # 使用 system_profiler (仅 macOS)
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    system_profiler SPUSBDataType | grep -A 11 "iPad\|iPhone" | grep "Serial Number" | awk '{print $3}'
                else
                    print_error "请安装 libimobiledevice: brew install libimobiledevice"
                    exit 1
                fi
            else
                # 使用 idevice_id
                echo "连接的 iOS 设备:"
                idevice_id -l

                # 获取设备详细信息
                for udid in $(idevice_id -l); do
                    echo ""
                    echo "UDID: $udid"
                    if command -v ideviceinfo &> /dev/null; then
                        device_name=$(ideviceinfo -u "$udid" -k DeviceName 2>/dev/null || echo "Unknown")
                        device_version=$(ideviceinfo -u "$udid" -k ProductVersion 2>/dev/null || echo "Unknown")
                        echo "设备名称: $device_name"
                        echo "iOS 版本: $device_version"
                    fi
                done
            fi
        fi
    fi

    echo ""
    print_success "请复制上面的 UDID，然后："
    echo "1. 访问 https://developer.apple.com/account/resources/devices"
    echo "2. 登录你的 Apple Developer 账号"
    echo "3. 点击 '+' 添加新设备"
    echo "4. 粘贴 UDID 并给设备命名"
    echo "5. 运行: ./scripts/signing/post_build_ios.sh --refresh-profile"
}

# ============================================================================
# 刷新 Provisioning Profile
# ============================================================================
refresh_profile() {
    print_header "刷新 Provisioning Profile"

    print_warning "这个操作需要在 Xcode 中完成:"
    echo ""
    echo "方法 1: 使用 Xcode GUI"
    echo "  1. 用 Xcode 打开项目的 .xcodeproj 文件"
    echo "  2. 选择 JinGo target"
    echo "  3. 进入 'Signing & Capabilities' 标签"
    echo "  4. 确保 'Automatically manage signing' 已勾选"
    echo "  5. 选择你的 Team: $TEAM_ID"
    echo "  6. 连接你的 iOS 设备"
    echo "  7. 点击 'Download Manual Profiles' 或等待自动刷新"
    echo ""
    echo "方法 2: 使用命令行"
    echo "  # 删除旧的 Provisioning Profiles"
    echo "  rm -rf ~/Library/MobileDevice/Provisioning\\ Profiles/*"
    echo ""
    echo "  # 重新下载 (需要 Xcode)"
    echo "  # 在 Xcode 中: Preferences -> Accounts -> [你的账号] -> Download Manual Profiles"
}

# ============================================================================
# 签名 iOS 应用
# ============================================================================
sign_ios_app() {
    print_header "签名 iOS 应用"

    local app_path="$1"
    local provisioning_profile="$2"
    local identity="${3:-Apple Development}"

    # 验证参数
    if [ -z "$app_path" ]; then
        print_error "用法: $0 --sign <app路径> [provisioning_profile] [identity]"
        print_error "示例: $0 --sign build/ios/JinGo.app"
        exit 1
    fi

    if [ ! -d "$app_path" ]; then
        print_error "应用包不存在: $app_path"
        exit 1
    fi

    print_success "应用路径: $app_path"
    print_success "身份: $identity"
    echo ""

    # 获取项目根目录和 entitlements 路径
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

    MAIN_ENTITLEMENTS="$PROJECT_ROOT/platform/ios/JinGo.entitlements"
    PACKET_TUNNEL_ENTITLEMENTS="$PROJECT_ROOT/platform/ios/PacketTunnelProvider.entitlements"

    # 检查 entitlements 文件
    if [ ! -f "$MAIN_ENTITLEMENTS" ]; then
        # 尝试在 app 路径附近查找
        if [ -f "$app_path/../../../platform/ios/JinGo.entitlements" ]; then
            MAIN_ENTITLEMENTS="$app_path/../../../platform/ios/JinGo.entitlements"
        else
            print_warning "主应用 entitlements 未找到，将不使用 entitlements"
            MAIN_ENTITLEMENTS=""
        fi
    fi

    # 查找可用的签名身份
    print_header "可用的签名身份"
    security find-identity -v -p codesigning | grep "iPhone Developer\\|Apple Development\\|iPhone Distribution" || print_warning "未找到 iOS 开发证书"
    echo ""

    # 如果提供了 provisioning profile，安装它
    if [ -n "$provisioning_profile" ] && [ -f "$provisioning_profile" ]; then
        print_success "安装 Provisioning Profile: $provisioning_profile"

        # 确保目标目录存在
        PROFILE_DIR=~/Library/MobileDevice/Provisioning\ Profiles
        mkdir -p "$PROFILE_DIR"

        # 复制 provisioning profile
        cp "$provisioning_profile" "$PROFILE_DIR/"
        print_success "Profile 已安装"
        echo ""
    fi

    # 签名函数
    sign_component() {
        local target="$1"
        local entitlements="$2"
        local name=$(basename "$target")

        print_success "签名: $name"

        local cmd=(codesign --force --sign "$identity")

        if [ -n "$entitlements" ] && [ -f "$entitlements" ]; then
            cmd+=(--entitlements "$entitlements")
            print_success "  使用 entitlements: $(basename "$entitlements")"
        fi

        cmd+=(--timestamp=none)
        cmd+=("$target")

        if "${cmd[@]}" 2>&1; then
            print_success "  ✓ 签名成功"
            return 0
        else
            print_error "  ✗ 签名失败"
            return 1
        fi
    }

    # 移除现有签名
    print_header "移除现有签名"
    find "$app_path" -type f \( -name "*.dylib" -o -name "*.so" -o -name "*.framework" \) -exec codesign --remove-signature {} \; 2>/dev/null || true
    print_success "  ✓ 已移除"
    echo ""

    # 签名顺序（从内到外）：

    # 1. 签名所有 .dylib 和 .so 文件
    print_header "Step 1: 签名动态库"
    find "$app_path" -type f \( -name "*.dylib" -o -name "*.so" \) | while read -r lib; do
        sign_component "$lib" ""
    done
    echo ""

    # 2. 签名所有 frameworks
    print_header "Step 2: 签名 Frameworks"
    if [ -d "$app_path/Frameworks" ]; then
        find "$app_path/Frameworks" -name "*.framework" -type d | while read -r framework; do
            sign_component "$framework" ""
        done
    fi
    echo ""

    # 3. 签名 App Extensions (PacketTunnelProvider)
    print_header "Step 3: 签名 App Extensions"
    if [ -d "$app_path/PlugIns" ]; then
        find "$app_path/PlugIns" -name "*.appex" -type d | while read -r appex; do
            appex_name=$(basename "$appex" .appex)
            print_success "发现扩展: $appex_name"

            # 选择对应的 entitlements
            local ext_entitlements=""
            if [ "$appex_name" = "PacketTunnelProvider" ] && [ -f "$PACKET_TUNNEL_ENTITLEMENTS" ]; then
                ext_entitlements="$PACKET_TUNNEL_ENTITLEMENTS"
            fi

            # 签名扩展的可执行文件
            appex_binary="$appex/$appex_name"
            if [ -f "$appex_binary" ]; then
                sign_component "$appex_binary" "$ext_entitlements"
            fi

            # 签名整个 appex bundle
            sign_component "$appex" "$ext_entitlements"
        done
    fi
    echo ""

    # 4. 签名主可执行文件
    print_header "Step 4: 签名主可执行文件"
    MAIN_EXECUTABLE="$app_path/$(basename "$app_path" .app)"
    if [ -f "$MAIN_EXECUTABLE" ]; then
        sign_component "$MAIN_EXECUTABLE" "$MAIN_ENTITLEMENTS"
    else
        # 尝试在常见位置查找
        if [ -f "$app_path/JinGo" ]; then
            MAIN_EXECUTABLE="$app_path/JinGo"
            sign_component "$MAIN_EXECUTABLE" "$MAIN_ENTITLEMENTS"
        else
            print_error "主可执行文件未找到: $MAIN_EXECUTABLE"
            exit 1
        fi
    fi
    echo ""

    # 5. 签名整个应用包
    print_header "Step 5: 签名应用包"
    sign_component "$app_path" ""
    echo ""

    # 验证签名
    print_header "验证签名"

    print_success "验证 Extensions..."
    if [ -d "$app_path/PlugIns" ]; then
        find "$app_path/PlugIns" -name "*.appex" -type d | while read -r appex; do
            if codesign --verify --strict --verbose=2 "$appex" 2>&1; then
                print_success "  ✓ $(basename "$appex") 验证通过"
            else
                print_error "  ✗ $(basename "$appex") 验证失败"
            fi
        done
    fi

    print_success "验证主可执行文件..."
    if codesign --verify --strict --verbose=2 "$MAIN_EXECUTABLE" 2>&1; then
        print_success "  ✓ 主可执行文件验证通过"
    else
        print_warning "  ⚠ 主可执行文件验证失败"
    fi

    print_success "验证应用包..."
    if codesign --verify --strict --verbose=2 "$app_path" 2>&1; then
        print_success "  ✓ 应用包验证通过"
    else
        print_warning "  ⚠ 应用包验证失败（可能是正常的，取决于构建方式）"
    fi
    echo ""

    # 显示签名信息
    print_header "签名信息"
    codesign -dvvv "$app_path" 2>&1 | head -20
    echo ""

    print_header "签名完成！"
    print_success "你现在可以将应用部署到设备："
    print_success "  xcrun devicectl device install app --device <device-id> $app_path"
}

# ============================================================================
# 检查签名配置
# ============================================================================
check_signing() {
    print_header "检查 iOS 签名配置"

    # 检查 Team ID
    echo "Team ID: $TEAM_ID"

    # 检查证书
    echo ""
    echo "可用的开发证书:"
    security find-identity -v -p codesigning | grep "Apple Development\|iPhone Development" || print_warning "未找到开发证书"

    # 检查 Provisioning Profiles
    echo ""
    echo "已安装的 Provisioning Profiles:"
    if [ -d ~/Library/MobileDevice/Provisioning\ Profiles ]; then
        PROFILE_COUNT=$(ls -1 ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision 2>/dev/null | wc -l || echo "0")
        if [ "$PROFILE_COUNT" -gt 0 ]; then
            print_success "找到 $PROFILE_COUNT 个 Provisioning Profile"
            ls -la ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | head -5
        else
            print_warning "未找到 Provisioning Profiles"
        fi
    else
        print_warning "Provisioning Profiles 目录不存在"
    fi

    # 检查 Xcode
    echo ""
    if command -v xcodebuild &> /dev/null; then
        xcode_version=$(xcodebuild -version | head -n 1)
        print_success "Xcode: $xcode_version"
    else
        print_error "Xcode 未安装或未在 PATH 中"
    fi
}

# ============================================================================
# 生成 CMake 配置命令
# ============================================================================
generate_cmake_command() {
    print_header "CMake 配置命令"

    echo "对于 iOS 构建，使用以下 CMake 命令:"
    echo ""
    echo "cmake -S . -B build/ios \\"
    echo "  -G Xcode \\"
    echo "  -DCMAKE_SYSTEM_NAME=iOS \\"
    echo "  -DCMAKE_OSX_SYSROOT=iphoneos \\"
    echo "  -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=$TEAM_ID \\"
    echo "  -DCMAKE_PREFIX_PATH=/Volumes/mindata/Applications/Qt/6.10.0/ios \\"
    echo "  -DCMAKE_TOOLCHAIN_FILE=/Volumes/mindata/Applications/Qt/6.10.0/ios/lib/cmake/Qt6/qt.toolchain.cmake"
    echo ""
    print_success "然后在 Xcode 中打开 build/ios/JinGo.xcodeproj"
}

# ============================================================================
# 打开 Apple Developer Portal
# ============================================================================
open_developer_portal() {
    print_header "打开 Apple Developer Portal"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "https://developer.apple.com/account/resources/devices/list"
        print_success "已在浏览器中打开 Apple Developer 设备管理页面"
    else
        echo "请访问: https://developer.apple.com/account/resources/devices/list"
    fi
}

# ============================================================================
# 创建 IPA
# ============================================================================
create_ipa() {
    local app_path="$1"
    local output_dir="${2:-$(dirname "$app_path")}"

    print_header "创建 IPA"

    if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
        print_error "请提供有效的应用路径"
        exit 1
    fi

    # 获取版本号
    local version=$(defaults read "$app_path/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
    local ipa_name="${APP_NAME}-${version}.ipa"
    local ipa_path="$output_dir/$ipa_name"

    print_success "应用: $app_path"
    print_success "版本: $version"
    print_success "输出: $ipa_path"

    # 创建 Payload 目录
    local temp_dir=$(mktemp -d)
    local payload_dir="$temp_dir/Payload"
    mkdir -p "$payload_dir"

    # 复制 app
    cp -R "$app_path" "$payload_dir/"

    # 创建 IPA
    cd "$temp_dir"
    zip -r "$ipa_path" Payload
    cd - > /dev/null

    # 清理
    rm -rf "$temp_dir"

    if [ -f "$ipa_path" ]; then
        print_success "✓ IPA 创建成功: $ipa_path"
    else
        print_error "IPA 创建失败"
        exit 1
    fi
}

# ============================================================================
# 上传到 TestFlight
# ============================================================================
upload_testflight() {
    local ipa_path="$1"

    print_header "上传到 TestFlight"

    if [ -z "$ipa_path" ] || [ ! -f "$ipa_path" ]; then
        print_error "请提供有效的 IPA 文件路径"
        exit 1
    fi

    # 检查凭据
    if [ -n "$ASC_API_KEY" ] && [ -n "$ASC_API_ISSUER" ]; then
        print_success "使用 App Store Connect API Key 上传..."
        xcrun altool --upload-app \
            --type ios \
            --file "$ipa_path" \
            --apiKey "$ASC_API_KEY" \
            --apiIssuer "$ASC_API_ISSUER"
    elif [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ]; then
        print_success "使用 Apple ID 上传..."
        xcrun altool --upload-app \
            --type ios \
            --file "$ipa_path" \
            --username "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD"
    else
        print_error "请设置凭据环境变量："
        print_success "  方法 1 (推荐): ASC_API_KEY 和 ASC_API_ISSUER"
        print_success "  方法 2: APPLE_ID 和 APPLE_ID_PASSWORD"
        exit 1
    fi

    print_header "上传完成！"
    print_success "请在 App Store Connect -> TestFlight 中查看"
    print_success "URL: https://appstoreconnect.apple.com/apps"
}

# ============================================================================
# 上传到 App Store
# ============================================================================
upload_appstore() {
    local ipa_path="$1"

    print_header "上传到 App Store Connect"

    if [ -z "$ipa_path" ] || [ ! -f "$ipa_path" ]; then
        print_error "请提供有效的 IPA 文件路径"
        exit 1
    fi

    # 检查凭据
    if [ -n "$ASC_API_KEY" ] && [ -n "$ASC_API_ISSUER" ]; then
        print_success "使用 App Store Connect API Key 上传..."
        xcrun altool --upload-app \
            --type ios \
            --file "$ipa_path" \
            --apiKey "$ASC_API_KEY" \
            --apiIssuer "$ASC_API_ISSUER"
    elif [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ]; then
        print_success "使用 Apple ID 上传..."
        xcrun altool --upload-app \
            --type ios \
            --file "$ipa_path" \
            --username "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD"
    else
        print_error "请设置凭据环境变量："
        print_success "  方法 1 (推荐): ASC_API_KEY 和 ASC_API_ISSUER"
        print_success "  方法 2: APPLE_ID 和 APPLE_ID_PASSWORD"
        exit 1
    fi

    print_header "上传完成！"
    print_success "请在 App Store Connect 中提交审核"
    print_success "URL: https://appstoreconnect.apple.com/apps"
}

# ============================================================================
# 显示帮助
# ============================================================================
show_help() {
    cat << EOF
JinGo VPN iOS 签名和发布脚本 v1.2.0

用法: $0 [选项]

设备管理:
  --get-udid                     获取连接的 iOS 设备 UDID
  --open-portal                  打开 Apple Developer Portal

签名:
  --sign <app> [profile] [id]    签名 iOS 应用
  --check                        检查签名配置状态
  --refresh-profile              刷新 Provisioning Profile 的说明

打包:
  --create-ipa <app>             创建 IPA 文件

发布:
  --testflight <ipa>             上传到 TestFlight
  --appstore <ipa>               上传到 App Store Connect

其他:
  --cmake                        显示 CMake 配置命令
  --help                         显示此帮助信息

环境变量:
  APPLE_DEVELOPMENT_TEAM    开发团队 ID (默认: $TEAM_ID)
  APPLE_ID                  Apple ID 邮箱
  APPLE_ID_PASSWORD         App-specific password
  ASC_API_KEY               App Store Connect API Key
  ASC_API_ISSUER            App Store Connect API Issuer

完整发布流程:
  1. 编译 Release 版本
     ./scripts/build/build-ios.sh --release

  2. 签名应用 (发布签名)
     $0 --sign build/ios/JinGo.app "" "iPhone Distribution"

  3. 创建 IPA
     $0 --create-ipa build/ios/JinGo.app

  4. 上传到 TestFlight
     export APPLE_ID="your@email.com"
     export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
     $0 --testflight build/ios/JinGo-1.0.0.ipa

  5. 或上传到 App Store
     $0 --appstore build/ios/JinGo-1.0.0.ipa

EOF
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    case "${1:-}" in
        --get-udid)
            get_udid
            ;;
        --refresh-profile)
            refresh_profile
            ;;
        --check)
            check_signing
            ;;
        --cmake)
            generate_cmake_command
            ;;
        --open-portal)
            open_developer_portal
            ;;
        --sign)
            shift
            sign_ios_app "$@"
            ;;
        --create-ipa)
            shift
            create_ipa "$@"
            ;;
        --testflight)
            shift
            upload_testflight "$@"
            ;;
        --appstore)
            shift
            upload_appstore "$@"
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
