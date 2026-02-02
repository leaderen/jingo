#!/bin/bash
# ============================================================================
# JinGo VPN - 白标资源复制脚本
# ============================================================================
# 功能：将白标目录下的 bundle_config.json 和 icons 复制到 resources 目录
#
# 用法:
#   source copy-brand-assets.sh
#   copy_brand_assets [brand_id]
#
# 参数:
#   brand_id - 品牌ID (可选，默认为 "1")
#
# 版本: 1.0.0
# ============================================================================

# 获取项目根目录
# 优先使用调用脚本设置的 PROJECT_ROOT，否则从脚本位置推导
if [[ -n "$PROJECT_ROOT" ]] && [[ -d "$PROJECT_ROOT/white-labeling" ]]; then
    COPY_BRAND_PROJECT_ROOT="$PROJECT_ROOT"
else
    COPY_BRAND_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    COPY_BRAND_PROJECT_ROOT="$(cd "$COPY_BRAND_SCRIPT_DIR/../.." && pwd)"
fi

# 白标目录
WHITE_LABEL_BASE_DIR="$COPY_BRAND_PROJECT_ROOT/white-labeling"

# 目标目录
RESOURCES_DIR="$COPY_BRAND_PROJECT_ROOT/resources"

# 颜色定义 (如果尚未定义)
if [[ -z "$NC" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

# 日志函数 (如果尚未定义)
if ! type brand_log_info &> /dev/null; then
    brand_log_info()    { echo -e "${BLUE}[BRAND]${NC} $1"; }
    brand_log_success() { echo -e "${GREEN}[BRAND]${NC} $1"; }
    brand_log_warning() { echo -e "${YELLOW}[BRAND]${NC} $1"; }
    brand_log_error()   { echo -e "${RED}[BRAND]${NC} $1"; }
fi

# ============================================================================
# 复制白标资源
# ============================================================================
# 参数: $1 = 品牌ID (可选，默认 "1")
# 返回: 0 成功, 1 失败
copy_brand_assets() {
    local brand_id="${1:-1}"
    local brand_dir="$WHITE_LABEL_BASE_DIR/$brand_id"

    echo ""
    brand_log_info "=========================================="
    brand_log_info "复制白标资源 (品牌: $brand_id)"
    brand_log_info "=========================================="

    # 检查品牌目录是否存在
    if [[ ! -d "$brand_dir" ]]; then
        brand_log_error "品牌目录不存在: $brand_dir"
        brand_log_info "可用的品牌:"
        ls -1 "$WHITE_LABEL_BASE_DIR" 2>/dev/null | grep -v "README" | grep -v "^\." || echo "  (无)"
        return 1
    fi

    local copied_count=0

    # ========================================================================
    # 1. 复制 bundle_config.json 到 resources/ 目录
    # ========================================================================
    local src_config="$brand_dir/bundle_config.json"
    local dst_config="$RESOURCES_DIR/bundle_config.json"

    if [[ -f "$src_config" ]]; then
        # 备份原文件
        if [[ -f "$dst_config" ]]; then
            cp "$dst_config" "$dst_config.backup" 2>/dev/null || true
        fi

        # 复制配置文件
        cp "$src_config" "$dst_config"
        brand_log_success "bundle_config.json -> resources/"
        copied_count=$((copied_count + 1))
    else
        brand_log_warning "未找到 bundle_config.json: $src_config"
    fi

    # ========================================================================
    # 2. 复制 icons 目录到 resources/icons/
    # ========================================================================
    local src_icons="$brand_dir/icons"
    local dst_icons="$RESOURCES_DIR/icons"

    if [[ -d "$src_icons" ]]; then
        # 复制通用图标 (app.png, app.icns, app.ico, logo.png)
        for ext in png icns ico; do
            for icon_file in "$src_icons"/*.$ext; do
                if [[ -f "$icon_file" ]]; then
                    local icon_name=$(basename "$icon_file")
                    cp "$icon_file" "$dst_icons/$icon_name"
                    brand_log_success "icons/$icon_name -> resources/icons/"
                    copied_count=$((copied_count + 1))
                fi
            done
        done

        # ====================================================================
        # 3. 复制 iOS 图标到 platform/ios/Assets.xcassets/AppIcon.appiconset/
        # ====================================================================
        local src_ios_icons="$src_icons/ios"
        local dst_ios_icons="$COPY_BRAND_PROJECT_ROOT/platform/ios/Assets.xcassets/AppIcon.appiconset"

        if [[ -d "$src_ios_icons" ]] && [[ -d "$dst_ios_icons" ]]; then
            cp "$src_ios_icons"/*.png "$dst_ios_icons/" 2>/dev/null || true
            cp "$src_ios_icons"/Contents.json "$dst_ios_icons/" 2>/dev/null || true
            brand_log_success "icons/ios/* -> platform/ios/.../AppIcon.appiconset/"
            copied_count=$((copied_count + 1))
        fi

        # ====================================================================
        # 4. 复制 Android 图标到 platform/android/res/
        # ====================================================================
        local src_android_icons="$src_icons/android"
        local dst_android_res="$COPY_BRAND_PROJECT_ROOT/platform/android/res"

        if [[ -d "$src_android_icons" ]]; then
            for mipmap_dir in "$src_android_icons"/mipmap-*; do
                if [[ -d "$mipmap_dir" ]]; then
                    local mipmap_name=$(basename "$mipmap_dir")
                    mkdir -p "$dst_android_res/$mipmap_name"
                    cp "$mipmap_dir"/*.png "$dst_android_res/$mipmap_name/" 2>/dev/null || true
                fi
            done
            brand_log_success "icons/android/* -> platform/android/res/"
            copied_count=$((copied_count + 1))
        fi

    else
        brand_log_warning "未找到 icons 目录: $src_icons"
    fi

    # ========================================================================
    # 5. 复制 Linux 图标 (如果存在)
    # ========================================================================
    local linux_icon="$dst_icons/app.png"
    local linux_dest="$COPY_BRAND_PROJECT_ROOT/platform/linux/icons/512x512/apps"

    if [[ -f "$linux_icon" ]] && [[ -d "$linux_dest" ]]; then
        cp "$linux_icon" "$linux_dest/jingo.png"
        brand_log_success "icons/app.png -> platform/linux/icons/.../jingo.png"
    fi

    # ========================================================================
    # 6. 复制 license_public_key.pem 到 resources/ 目录
    # ========================================================================
    local src_pubkey="$brand_dir/license_public_key.pem"
    local dst_pubkey="$RESOURCES_DIR/license_public_key.pem"

    if [[ -f "$src_pubkey" ]]; then
        cp "$src_pubkey" "$dst_pubkey"
        brand_log_success "license_public_key.pem -> resources/"
        copied_count=$((copied_count + 1))
    else
        brand_log_warning "未找到公钥文件: $src_pubkey"
    fi

    # ========================================================================
    # 总结
    # ========================================================================
    echo ""
    if [[ $copied_count -gt 0 ]]; then
        brand_log_success "白标资源复制完成 (共 $copied_count 项)"
    else
        brand_log_warning "未复制任何资源"
    fi
    echo ""

    return 0
}

# ============================================================================
# 列出可用品牌
# ============================================================================
list_available_brands() {
    echo ""
    brand_log_info "可用的品牌:"
    if [[ -d "$WHITE_LABEL_BASE_DIR" ]]; then
        for brand_dir in "$WHITE_LABEL_BASE_DIR"/*/; do
            if [[ -d "$brand_dir" ]]; then
                local brand_id=$(basename "$brand_dir")
                # 跳过隐藏目录和非目录项
                if [[ "$brand_id" != "." && "$brand_id" != ".." && ! "$brand_id" =~ ^\. ]]; then
                    local config_file="$brand_dir/bundle_config.json"
                    if [[ -f "$config_file" ]]; then
                        # 尝试读取 appName
                        local app_name=$(jq -r 'if .__signed then .config.appName else .appName end // "Unknown"' "$config_file" 2>/dev/null || echo "Unknown")
                        echo "  $brand_id - $app_name"
                    else
                        echo "  $brand_id (无配置文件)"
                    fi
                fi
            fi
        done
    else
        echo "  (white-labeling 目录不存在)"
    fi
    echo ""
}

# 如果直接运行此脚本，显示帮助
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "JinGo VPN - 白标资源复制脚本"
    echo ""
    echo "用法:"
    echo "  source ${0} && copy_brand_assets [brand_id]"
    echo ""
    echo "或在构建脚本中:"
    echo "  source \"\$SCRIPT_DIR/copy-brand-assets.sh\""
    echo "  copy_brand_assets \"\$BRAND_NAME\""
    echo ""
    list_available_brands
fi
