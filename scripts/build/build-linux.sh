#!/bin/bash
# ============================================================================
# JinGo VPN - Linux 构建脚本
# ============================================================================
# 描述：编译 Linux 应用 (在 Linux 上运行)
#
# 功能：编译、部署依赖、打包 DEB/RPM/TGZ
# 依赖：Linux, CMake 3.21+, Qt 6.5+, GCC/Clang
# 版本：1.2.0
# ============================================================================

set -e  # 遇到错误立即退出
set -o pipefail  # 管道中的错误也触发退出

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
# Qt Linux 安装路径 (gcc_64 目录)
# 优先使用环境变量 QT_DIR 或 Qt6_DIR，否则使用默认值
# 本地开发请修改下面的默认路径，或设置环境变量
# 示例: "/opt/Qt/6.8.0/gcc_64" 或 "/home/yourname/Qt/6.8.0/gcc_64"
if [[ -n "${QT_DIR:-}" ]]; then
    : # 使用已设置的 QT_DIR
elif [[ -n "${Qt6_DIR:-}" ]]; then
    QT_DIR="$Qt6_DIR"
else
    QT_DIR="/mnt/dev/Qt/6.10.1/gcc_64"
fi

# --------------------- 构建配置 ---------------------
# 是否使用 Ninja (推荐，更快)
USE_NINJA=true

# --------------------- 脚本初始化 ---------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 错误处理
trap 'on_error $LINENO' ERR

on_error() {
    local line=$1
    print_error "脚本在第 $line 行发生错误"
    exit 1
}

# 加载白标资源复制脚本
if [[ -f "$SCRIPT_DIR/copy-brand-assets.sh" ]]; then
    source "$SCRIPT_DIR/copy-brand-assets.sh"
fi

# --------------------- 应用信息 ---------------------
APP_NAME="JinGo"

# ============================================================================
# 脚本内部变量 (一般不需要修改)
# ============================================================================
# SCRIPT_DIR 已在上面定义
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-linux"
RELEASE_DIR="$PROJECT_ROOT/release"
CONFIGURATION="Debug"
CLEAN_BUILD=false
CREATE_PACKAGE=false
DEPLOY_DEPS=false
UPDATE_TRANSLATIONS=false
VERBOSE=false
BRAND_NAME=""

# --------------------- 输出命名 ---------------------
# 获取构建日期 (YYYYMMDD 格式)
BUILD_DATE=$(date +%Y%m%d)

# 生成输出文件名: {brand}-{version}-{date}-{platform}.{ext}
generate_output_name() {
    local version="${1:-1.0.0}"
    local ext="${2:-}"
    local brand="${BRAND_NAME:-${BRAND:-1}}"
    local platform="linux"

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
CYAN='\033[0;36m'
BOLD='\033[1m'
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
    echo -e "\n${CYAN}${BOLD}>>> $1${NC}\n"
}

# 格式化文件大小
format_size() {
    local size=$1
    if [[ $size -ge 1073741824 ]]; then
        echo "$(echo "scale=2; $size/1073741824" | bc)GB"
    elif [[ $size -ge 1048576 ]]; then
        echo "$(echo "scale=2; $size/1048576" | bc)MB"
    elif [[ $size -ge 1024 ]]; then
        echo "$(echo "scale=2; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
${BOLD}JinGoVPN Linux 构建脚本 v1.2.0${NC}

${CYAN}用法:${NC}
    $0 [选项]

${CYAN}构建选项:${NC}
    -c, --clean          清理构建目录后重新构建
    -d, --debug          Debug 模式构建（默认）
    -r, --release        Release 模式构建
    -p, --package        打包 DEB/RPM/TGZ

${CYAN}部署选项:${NC}
    --deploy             部署 Qt 依赖库和插件

${CYAN}翻译选项:${NC}
    -t, --translate      更新翻译（运行 Python 翻译脚本）

${CYAN}白标定制:${NC}
    -b, --brand NAME     应用白标定制（从 white-labeling/<NAME> 加载配置）

${CYAN}其他选项:${NC}
    -v, --verbose        显示详细输出
    -h, --help           显示此帮助信息

${CYAN}环境变量:${NC}
    Qt6_DIR              Qt 6 安装路径（例如: /opt/Qt/6.10.0/gcc_64）
    CMAKE_PREFIX_PATH    CMake 查找路径

${CYAN}示例:${NC}
    # 编译 Debug 版本
    $0

    # 清理并编译 Release 版本
    $0 --clean --release

    # 编译 Release 版本并部署依赖
    $0 --release --deploy

    # 编译并打包
    $0 --release --package

    # 更新翻译后编译
    $0 --translate

    # 使用白标定制编译
    $0 --brand jingo --release --package

${CYAN}输出目录:${NC}
    Debug:   $PROJECT_ROOT/build-linux/bin/
    Release: $PROJECT_ROOT/build-linux/bin/
    Packages: $PROJECT_ROOT/build-linux/

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
            -p|--package)
                CREATE_PACKAGE=true
                shift
                ;;
            --deploy)
                DEPLOY_DEPS=true
                shift
                ;;
            -t|--translate)
                UPDATE_TRANSLATIONS=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
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
    # Linux 平台默认使用品牌 4
    local brand_id="${BRAND_NAME:-${BRAND:-4}}"

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

    # 检查 Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "此脚本只能在 Linux 上运行"
        exit 1
    fi

    # 检查 CMake
    if ! command -v cmake &> /dev/null; then
        print_error "CMake 未安装。请安装 CMake"
        print_info "Ubuntu/Debian: sudo apt install cmake"
        print_info "Fedora/RHEL: sudo dnf install cmake"
        exit 1
    fi
    print_success "CMake: $(cmake --version | head -n1)"

    # 检查编译器
    if ! command -v g++ &> /dev/null; then
        print_error "g++ 未安装。请安装 C++ 编译器"
        print_info "Ubuntu/Debian: sudo apt install build-essential"
        print_info "Fedora/RHEL: sudo dnf install gcc-c++"
        exit 1
    fi
    print_success "g++: $(g++ --version | head -n1)"

    # 检查 Qt
    if [ -z "$QT_DIR" ]; then
        # 尝试自动查找 Qt
        QT_PATHS=(
            "/opt/Qt/*/gcc_64"
            "$HOME/Qt/*/gcc_64"
            "/usr/lib/x86_64-linux-gnu/qt6"
            "/usr/lib/qt6"
        )

        for pattern in "${QT_PATHS[@]}"; do
            for path in $pattern; do
                if [ -d "$path" ] && [ -f "$path/bin/qmake" ]; then
                    QT_DIR="$path"
                    print_success "自动找到 Qt: $QT_DIR"
                    break 2
                fi
            done
        done

        if [ -z "$QT_DIR" ]; then
            print_warning "未找到 Qt，请设置 Qt6_DIR 环境变量"
            print_info "例如: export Qt6_DIR=/opt/Qt/6.8.0/gcc_64"
        fi
    else
        if [ ! -d "$QT_DIR" ]; then
            print_error "Qt 目录不存在: $QT_DIR"
            exit 1
        fi
        print_success "Qt: $QT_DIR"
    fi

    # 检查 ninja (可选，但推荐)
    if command -v ninja &> /dev/null; then
        print_success "Ninja: $(ninja --version)"
        USE_NINJA=true
    else
        print_warning "Ninja 未安装，将使用 make（推荐安装 ninja 以提升编译速度）"
        print_info "Ubuntu/Debian: sudo apt install ninja-build"
        print_info "Fedora/RHEL: sudo dnf install ninja-build"
        USE_NINJA=false
    fi

    # 检查打包工具（如果需要打包）
    if [ "$CREATE_PACKAGE" = true ]; then
        if command -v dpkg-deb &> /dev/null; then
            print_success "dpkg-deb 可用（可生成 DEB 包）"
        fi
        if command -v rpmbuild &> /dev/null; then
            print_success "rpmbuild 可用（可生成 RPM 包）"
        fi
    fi

    print_success "构建环境检查完成"
}

# ============================================================================
# 更新翻译内容（Python 脚本）
# ============================================================================
update_translations() {
    if [[ "$UPDATE_TRANSLATIONS" != true ]]; then
        return
    fi

    print_step "更新翻译内容"

    local translate_script="$SCRIPT_DIR/translate_ts.py"

    if [[ ! -f "$translate_script" ]]; then
        print_warning "翻译脚本不存在: $translate_script"
        return
    fi

    if ! command -v python3 &> /dev/null; then
        print_warning "python3 未安装，跳过翻译更新"
        return
    fi

    print_info "运行翻译脚本..."
    if python3 "$translate_script" 2>&1; then
        print_success "翻译内容已更新"
    else
        print_warning "翻译脚本执行失败"
    fi
}

# ============================================================================
# 生成翻译文件
# ============================================================================
generate_translations() {
    local translations_dir="$PROJECT_ROOT/resources/translations"
    local lrelease=""

    # 查找 lrelease 工具
    if [[ -n "$QT_DIR" ]] && [[ -x "$QT_DIR/bin/lrelease" ]]; then
        lrelease="$QT_DIR/bin/lrelease"
    elif command -v lrelease &> /dev/null; then
        lrelease="lrelease"
    elif command -v lrelease-qt6 &> /dev/null; then
        lrelease="lrelease-qt6"
    fi

    if [[ -z "$lrelease" ]]; then
        print_warning "lrelease 未找到，跳过翻译生成"
        return
    fi

    if [[ ! -d "$translations_dir" ]]; then
        print_warning "翻译目录不存在: $translations_dir"
        return
    fi

    # 检查是否需要重新生成翻译文件
    local need_regenerate=false
    local ts_count=0
    local qm_count=0
    local languages=()

    for ts_file in "$translations_dir"/*.ts; do
        if [[ -f "$ts_file" ]]; then
            ts_count=$((ts_count + 1))
            local base_name=$(basename "$ts_file" .ts)
            local qm_file="$translations_dir/$base_name.qm"
            local lang=$(echo "$base_name" | sed 's/jingo_//')
            languages+=("$lang")

            # 检查 .qm 是否存在且比 .ts 新
            if [[ ! -f "$qm_file" ]] || [[ "$ts_file" -nt "$qm_file" ]]; then
                need_regenerate=true
            fi
        fi
    done

    if [[ "$need_regenerate" == false ]] && [[ "$CLEAN_BUILD" != true ]]; then
        print_info "翻译文件已是最新，跳过生成"
        return
    fi

    print_step "生成翻译文件 (.qm)"

    # 编译所有 .ts 文件为 .qm 文件
    for ts_file in "$translations_dir"/*.ts; do
        if [[ -f "$ts_file" ]]; then
            local base_name=$(basename "$ts_file" .ts)

            if [[ "$VERBOSE" == true ]]; then
                print_info "编译: $base_name.ts"
                "$lrelease" "$ts_file" -qm "$translations_dir/$base_name.qm" 2>&1 | grep -E "Generated|Ignored" || true
            else
                "$lrelease" "$ts_file" -qm "$translations_dir/$base_name.qm" > /dev/null 2>&1
            fi

            if [[ -f "$translations_dir/$base_name.qm" ]]; then
                qm_count=$((qm_count + 1))
            fi
        fi
    done

    if [[ $qm_count -gt 0 ]]; then
        print_success "生成 $qm_count 个翻译文件"
        local lang_list=$(IFS=','; echo "${languages[*]}")
        print_info "支持语言: $lang_list"
    else
        print_warning "未生成翻译文件"
    fi
}

# 清理构建目录
clean_build_dir() {
    if [ "$CLEAN_BUILD" = true ]; then
        print_info "清理构建目录: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
        print_success "构建目录已清理"
    fi
}

# 配置项目
configure_project() {
    print_info "配置 CMake 项目..."
    print_info "  项目目录: $PROJECT_ROOT"
    print_info "  构建目录: $BUILD_DIR"
    print_info "  配置: $CONFIGURATION"

    mkdir -p "$BUILD_DIR"

    CMAKE_ARGS=(
        -S "$PROJECT_ROOT"
        -B "$BUILD_DIR"
        -DCMAKE_BUILD_TYPE="$CONFIGURATION"
    )

    # 使用 Ninja 生成器
    if [ "$USE_NINJA" = true ]; then
        CMAKE_ARGS+=(-G Ninja)
    fi

    # 设置 Qt 路径
    if [ -n "$QT_DIR" ]; then
        CMAKE_ARGS+=(-DCMAKE_PREFIX_PATH="$QT_DIR")
    fi

    # 如果需要打包，启用 CPack
    if [ "$CREATE_PACKAGE" = true ]; then
        CMAKE_ARGS+=(-DENABLE_PACKAGING=ON)
    fi

    # 安全功能开关
    if [ "${ENABLE_LICENSE_CHECK:-}" = "ON" ]; then
        CMAKE_ARGS+=(-DENABLE_LICENSE_CHECK=ON)
        print_info "CMake: 启用授权验证 (ENABLE_LICENSE_CHECK=ON)"
    fi
    if [ "${ENABLE_CONFIG_SIGNATURE_VERIFY:-}" = "ON" ]; then
        CMAKE_ARGS+=(-DENABLE_CONFIG_SIGNATURE_VERIFY=ON)
        print_info "CMake: 启用配置签名验证 (ENABLE_CONFIG_SIGNATURE_VERIFY=ON)"
    fi

    cmake "${CMAKE_ARGS[@]}"

    print_success "CMake 配置完成"
}

# 编译项目
build_project() {
    print_step "编译 $CONFIGURATION 版本"

    cd "$BUILD_DIR"

    # 获取 CPU 核心数
    NPROC=$(nproc 2>/dev/null || echo 4)
    print_info "使用 $NPROC 个并行任务编译"

    # 开始计时
    local start_time=$(date +%s)

    # 编译
    echo ""
    local build_log="$BUILD_DIR/build.log"
    cmake --build . --config "$CONFIGURATION" -j"$NPROC" 2>&1 | tee "$build_log"
    local build_result=${PIPESTATUS[0]}

    # 检查编译结果
    if [[ $build_result -ne 0 ]] || grep -q "error:" "$build_log"; then
        print_error "编译失败 (exit code: $build_result)"
        echo ""
        echo "=== 错误信息 ==="
        grep -i "error:" "$build_log" | head -30
        echo ""
        echo "=== 最后 50 行日志 ==="
        tail -50 "$build_log"
        exit 1
    fi

    # 计算编译时间
    local end_time=$(date +%s)
    local build_time=$((end_time - start_time))

    # 检查编译结果
    BIN_DIR="$BUILD_DIR/bin"
    APP_PATH="$BIN_DIR/$APP_NAME"

    if [[ ! -f "$APP_PATH" ]]; then
        print_error "编译失败: 主可执行文件不存在"
        print_error "期望路径: $APP_PATH"
        ls -la "$BIN_DIR/" 2>/dev/null || true
        exit 1
    fi

    echo ""
    print_success "编译成功！耗时 ${build_time} 秒"

    # 显示应用大小
    local app_size=$(stat -c%s "$APP_PATH" 2>/dev/null || echo "0")
    print_info "应用大小: $(format_size $app_size)"

    # 显示架构
    local arch=$(file "$APP_PATH" | grep -o "x86-64\|x86_64\|aarch64\|ARM" | head -1 || echo "unknown")
    print_info "架构: $arch"
}

# 部署依赖
deploy_dependencies() {
    if [ "$DEPLOY_DEPS" = false ]; then
        return
    fi

    print_info "部署 Qt 依赖库和插件..."

    BIN_DIR="$BUILD_DIR/bin"
    LIB_DIR="$BIN_DIR/lib"
    PLUGINS_DIR="$BIN_DIR/plugins"

    if [ ! -f "$BIN_DIR/$APP_NAME" ]; then
        print_error "未找到可执行文件: $BIN_DIR/$APP_NAME"
        exit 1
    fi

    # 创建 lib 目录
    mkdir -p "$LIB_DIR"

    # 拷贝 Qt 库
    print_info "拷贝 Qt 依赖库..."
    ldd "$BIN_DIR/$APP_NAME" | grep "Qt6" | awk '{print $3}' | while read -r lib; do
        if [ -f "$lib" ]; then
            cp -v "$lib" "$LIB_DIR/"
            # 也拷贝符号链接
            lib_name=$(basename "$lib")
            lib_base=$(echo "$lib_name" | sed 's/\.so\..*/\.so/')
            if [ "$lib_base" != "$lib_name" ]; then
                ln -sf "$lib_name" "$LIB_DIR/$lib_base"
            fi
        fi
    done

    # 拷贝 Qt 插件
    if [ -n "$QT_DIR" ]; then
        print_info "拷贝 Qt 插件..."
        mkdir -p "$PLUGINS_DIR/platforms"
        mkdir -p "$PLUGINS_DIR/imageformats"
        mkdir -p "$PLUGINS_DIR/iconengines"
        mkdir -p "$PLUGINS_DIR/platformthemes"

        cp -v "$QT_DIR/plugins/platforms/libqxcb.so" "$PLUGINS_DIR/platforms/" 2>/dev/null || true
        cp -v "$QT_DIR/plugins/platforms/libqwayland"*.so "$PLUGINS_DIR/platforms/" 2>/dev/null || true
        cp -v "$QT_DIR/plugins/imageformats"/*.so "$PLUGINS_DIR/imageformats/" 2>/dev/null || true
        cp -v "$QT_DIR/plugins/iconengines"/*.so "$PLUGINS_DIR/iconengines/" 2>/dev/null || true
        cp -v "$QT_DIR/plugins/platformthemes"/*.so "$PLUGINS_DIR/platformthemes/" 2>/dev/null || true
    fi

    # 创建启动脚本
    print_info "创建启动脚本..."
    cat > "$BIN_DIR/jingo" << 'EOF'
#!/bin/bash
# JinGo VPN 启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${SCRIPT_DIR}/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="${SCRIPT_DIR}/plugins/platforms"

exec "${SCRIPT_DIR}/JinGo" "$@"
EOF

    chmod +x "$BIN_DIR/jingo"
    print_success "启动脚本已创建: $BIN_DIR/jingo"

    print_success "依赖部署完成"
}

# 创建安装包
create_packages() {
    if [ "$CREATE_PACKAGE" = false ]; then
        return
    fi

    print_info "开始创建安装包..."

    cd "$BUILD_DIR"

    # 生成 DEB 包
    if command -v dpkg-deb &> /dev/null; then
        print_info "生成 DEB 包..."
        cpack -G DEB

        DEB_FILE=$(find . -name "*.deb" -type f | head -n 1)
        if [ -n "$DEB_FILE" ]; then
            DEB_SIZE=$(du -h "$DEB_FILE" | cut -f1)
            print_success "DEB 包创建成功: $DEB_FILE ($DEB_SIZE)"
        fi
    fi

    # 生成 RPM 包
    if command -v rpmbuild &> /dev/null; then
        print_info "生成 RPM 包..."
        cpack -G RPM

        RPM_FILE=$(find . -name "*.rpm" -type f | head -n 1)
        if [ -n "$RPM_FILE" ]; then
            RPM_SIZE=$(du -h "$RPM_FILE" | cut -f1)
            print_success "RPM 包创建成功: $RPM_FILE ($RPM_SIZE)"
        fi
    fi

    # 生成 TGZ 包
    print_info "生成 TGZ 包..."
    cpack -G TGZ

    TGZ_FILE=$(find . -name "*.tar.gz" -type f | head -n 1)
    if [ -n "$TGZ_FILE" ]; then
        TGZ_SIZE=$(du -h "$TGZ_FILE" | cut -f1)
        print_success "TGZ 包创建成功: $TGZ_FILE ($TGZ_SIZE)"
    fi

    print_success "安装包创建完成"
}

# 显示验证信息
verify_app() {
    print_step "验证应用"

    BIN_DIR="$BUILD_DIR/bin"
    APP_PATH="$BIN_DIR/$APP_NAME"

    if [[ ! -f "$APP_PATH" ]]; then
        print_error "未找到可执行文件"
        return
    fi

    # 显示文件大小
    local app_size=$(stat -c%s "$APP_PATH" 2>/dev/null || echo "0")
    print_success "可执行文件大小: $(format_size $app_size)"

    # 显示架构
    local arch=$(file "$APP_PATH" | grep -o "x86-64\|x86_64\|aarch64\|ARM" | head -1 || echo "unknown")
    print_success "架构: $arch"

    # 显示依赖
    print_info "Qt 依赖库:"
    if ldd "$APP_PATH" 2>/dev/null | grep -q "Qt6"; then
        ldd "$APP_PATH" | grep "Qt6" | awk '{print "  " $1 " => " $3}' | head -10
        local qt_count=$(ldd "$APP_PATH" | grep "Qt6" | wc -l)
        print_info "共找到 $qt_count 个 Qt6 依赖"
    else
        print_warning "未找到 Qt6 依赖"
    fi

    # 检查是否部署了依赖
    if [[ -d "$BIN_DIR/lib" ]]; then
        local lib_count=$(ls -1 "$BIN_DIR/lib" 2>/dev/null | wc -l)
        print_success "已部署 $lib_count 个依赖库"
    else
        print_info "未部署依赖库（使用系统库）"
    fi

    if [[ -d "$BIN_DIR/plugins" ]]; then
        local plugin_count=$(find "$BIN_DIR/plugins" -name "*.so" 2>/dev/null | wc -l)
        print_success "已部署 $plugin_count 个 Qt 插件"
    else
        print_info "未部署 Qt 插件"
    fi

    # 检查可执行权限
    if [[ -x "$APP_PATH" ]]; then
        print_success "可执行权限: 正常"
    else
        print_warning "可执行权限: 缺失"
    fi
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

    BIN_DIR="$BUILD_DIR/bin"
    APP_PATH="$BIN_DIR/$APP_NAME"

    if [[ -f "$APP_PATH" ]]; then
        # 获取版本号 (默认)
        local version="1.0.0"

        # 创建压缩包
        # 使用统一命名: {brand}-{version}-{date}-{platform}.{ext}
        local tar_name=$(generate_output_name "$version" "tar.gz")
        print_info "创建压缩包: $tar_name"

        # 打包整个 bin 目录
        (cd "$BUILD_DIR" && tar -czf "$RELEASE_DIR/$tar_name" bin)

        if [[ -f "$RELEASE_DIR/$tar_name" ]]; then
            print_success "已复制: $RELEASE_DIR/$tar_name"
        fi
    fi

    # 复制 DEB/RPM 包 (如果存在)
    for pkg in $(find "$BUILD_DIR" -name "*.deb" -o -name "*.rpm" 2>/dev/null); do
        if [[ -f "$pkg" ]]; then
            cp "$pkg" "$RELEASE_DIR/"
            print_success "已复制: $RELEASE_DIR/$(basename "$pkg")"
        fi
    done

    print_success "构建产物已复制到: $RELEASE_DIR"
}

# ============================================================================
# 显示构建摘要
# ============================================================================
show_summary() {
    BIN_DIR="$BUILD_DIR/bin"
    APP_PATH="$BIN_DIR/$APP_NAME"

    echo ""
    echo -e "${GREEN}${BOLD}=================================================="
    echo "              构建完成！"
    echo "==================================================${NC}"
    echo ""

    if [[ -n "$APP_PATH" ]] && [[ -f "$APP_PATH" ]]; then
        echo -e "${CYAN}应用路径:${NC}"
        echo "  $APP_PATH"
        echo ""

        if [[ "$DEPLOY_DEPS" == true ]] && [[ -f "$BIN_DIR/jingo" ]]; then
            echo -e "${CYAN}运行应用（已部署依赖）:${NC}"
            echo "  $BIN_DIR/jingo"
        else
            echo -e "${CYAN}运行应用:${NC}"
            echo "  $APP_PATH"
            echo ""
            echo -e "${CYAN}部署依赖（如需要）:${NC}"
            echo "  $0 --deploy"
        fi

        if [[ "$CREATE_PACKAGE" == true ]]; then
            echo ""
            echo -e "${CYAN}安装包位置:${NC}"
            find "$BUILD_DIR" -maxdepth 1 \( -name "*.deb" -o -name "*.rpm" -o -name "*.tar.gz" \) 2>/dev/null | sed 's/^/  /' || echo "  未找到安装包"
        fi
    fi
    echo ""
}

# 主函数
main() {
    echo ""
    echo -e "${BOLD}=================================================="
    echo "      JinGoVPN Linux 构建脚本 v1.2.0"
    echo "==================================================${NC}"
    echo ""

    parse_args "$@"

    # 记录开始时间
    local start_time=$(date +%s)

    print_info "构建配置: $CONFIGURATION"
    if [[ -n "$BRAND_NAME" ]]; then
        print_info "品牌定制: $BRAND_NAME"
    fi
    print_info "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    if [[ "$VERBOSE" == true ]]; then
        print_info "详细模式: 开启"
    fi
    if [[ "$UPDATE_TRANSLATIONS" == true ]]; then
        print_info "翻译更新: 开启"
    fi
    if [[ "$CREATE_PACKAGE" == true ]]; then
        print_info "创建安装包: 开启"
    fi
    if [[ "$DEPLOY_DEPS" == true ]]; then
        print_info "部署依赖: 开启"
    fi

    # 应用白标定制 (如果指定了品牌)
    apply_brand_customization

    check_requirements
    clean_build_dir
    update_translations
    generate_translations
    configure_project
    build_project
    deploy_dependencies
    verify_app
    create_packages
    copy_to_release
    show_summary

    # 显示总耗时
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    print_info "总耗时: ${total_time} 秒"

    echo ""
}

# 执行主函数
main "$@"
