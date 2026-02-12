#!/bin/bash
# ============================================================================
# post_build_macos.sh - macOS Post-Build Script
# ============================================================================
# This script handles all post-build steps for macOS in the correct order:
# 1. Fix Qt plugins rpath (CRITICAL for app to run)
# 2. Sign frameworks and app (only if SIGNING_IDENTITY is provided)
#
# Usage:
#   ./post_build_macos.sh <app_bundle_path> [signing_identity] [app_entitlements] [ext_entitlements]
#
# Arguments:
#   app_bundle_path   - Path to NexLink.app bundle
#   signing_identity  - (Optional) Code signing identity
#   app_entitlements  - (Optional) App entitlements file
#   ext_entitlements  - (Optional) Extension entitlements file
#
# Note: This script is called during Xcode build phase. For CI builds,
#       signing is typically done by build-macos.sh after the build.
# ============================================================================

set -e

APP_BUNDLE="$1"
SIGNING_IDENTITY="$2"
APP_ENTITLEMENTS="$3"
EXT_ENTITLEMENTS="$4"

if [ -z "$APP_BUNDLE" ]; then
    echo "Usage: $0 <app_bundle_path> [signing_identity] [app_entitlements] [ext_entitlements]"
    exit 1
fi

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found: $APP_BUNDLE"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Post-Build: Processing NexLink.app"
echo "=========================================="
echo "App bundle: $APP_BUNDLE"

# ============================================================================
# Step 1: Fix Qt plugins rpath (CRITICAL - macdeployqt uses wrong path)
# ============================================================================
echo ""
echo "Step 1: Fixing Qt plugins rpath (CRITICAL for app to run)..."
PLUGINS_DIR="$APP_BUNDLE/Contents/PlugIns"
if [ -d "$PLUGINS_DIR" ]; then
    echo "Fixing Qt plugins rpath..."
    while IFS= read -r -d '' dylib; do
        if ! otool -l "$dylib" 2>/dev/null | grep -q "@loader_path/../../Frameworks"; then
            install_name_tool -add_rpath "@loader_path/../../Frameworks" "$dylib" 2>/dev/null || true
            echo "  Fixed rpath: $(basename "$dylib")"
        fi
    done < <(find "$PLUGINS_DIR" -name "*.dylib" -print0 2>/dev/null)
    echo "  Plugins rpath fix complete"
fi

# ============================================================================
# Step 2: Code Signing (only if SIGNING_IDENTITY is provided)
# ============================================================================
if [ -n "$SIGNING_IDENTITY" ]; then
    echo ""
    echo "Step 2: Code Signing with identity: $SIGNING_IDENTITY"

    # 2.1 Sign all frameworks first
    echo "  Signing frameworks..."
    FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
    if [ -d "$FRAMEWORKS_DIR" ]; then
        for framework in "$FRAMEWORKS_DIR"/*.framework "$FRAMEWORKS_DIR"/*.dylib; do
            if [ -e "$framework" ]; then
                codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime "$framework" 2>&1 || true
            fi
        done
        echo "  Frameworks signed"
    fi

    # 2.2 Sign all Qt plugins (CRITICAL - must sign after rpath fix, before extensions)
    echo "  Signing Qt plugins..."
    if [ -d "$PLUGINS_DIR" ]; then
        while IFS= read -r -d '' dylib; do
            codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime "$dylib" 2>&1 | grep -v "replacing existing signature" || true
        done < <(find "$PLUGINS_DIR" -name "*.dylib" -print0 2>/dev/null)
        echo "  Qt plugins signed"
    fi

    # 2.3 Sign PacketTunnelProvider extension (supports both System Extension and App Extension)
    PTP_SYSEXT="$APP_BUNDLE/Contents/Library/SystemExtensions/cfd.nexlink.acc.PacketTunnelProvider.systemextension"
    PTP_APPEX="$APP_BUNDLE/Contents/PlugIns/PacketTunnelProvider.appex"

    # Prefer System Extension if exists, otherwise use App Extension
    if [ -d "$PTP_SYSEXT" ]; then
        PTP_EXTENSION="$PTP_SYSEXT"
        echo "  Signing PacketTunnelProvider.systemextension..."
    elif [ -d "$PTP_APPEX" ]; then
        PTP_EXTENSION="$PTP_APPEX"
        echo "  Signing PacketTunnelProvider.appex..."
    else
        PTP_EXTENSION=""
    fi

    if [ -n "$PTP_EXTENSION" ]; then
        # Sign internal frameworks first
        if [ -d "$PTP_EXTENSION/Contents/Frameworks" ]; then
            for framework in "$PTP_EXTENSION/Contents/Frameworks"/*.framework "$PTP_EXTENSION/Contents/Frameworks"/*.dylib; do
                if [ -e "$framework" ]; then
                    codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime "$framework" 2>&1 || true
                fi
            done
        fi
        # Sign extension with entitlements
        if [ -n "$EXT_ENTITLEMENTS" ] && [ -f "$EXT_ENTITLEMENTS" ]; then
            if codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$EXT_ENTITLEMENTS" --timestamp=none --options runtime "$PTP_EXTENSION" 2>&1; then
                echo "  PacketTunnelProvider signed (with entitlements)"
            else
                echo "  WARNING: PacketTunnelProvider signing failed"
            fi
        else
            codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime "$PTP_EXTENSION" 2>&1 || true
            echo "  PacketTunnelProvider signed (no entitlements)"
        fi
    fi

    # 2.4 Sign main app bundle (must be LAST - after all subcomponents)
    echo "  Signing main app bundle..."
    if [ -n "$APP_ENTITLEMENTS" ] && [ -f "$APP_ENTITLEMENTS" ]; then
        if codesign --force --sign "$SIGNING_IDENTITY" --entitlements "$APP_ENTITLEMENTS" --timestamp=none --options runtime "$APP_BUNDLE" 2>&1; then
            echo "  Main app signed (with entitlements)"
        else
            echo "  WARNING: Main app signing with entitlements failed, trying without..."
            codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime --deep "$APP_BUNDLE" 2>&1 || true
        fi
    else
        codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none --options runtime --deep "$APP_BUNDLE" 2>&1 || true
        echo "  Main app signed"
    fi

    echo "  Code signing complete!"
else
    echo ""
    echo "Step 3: Code Signing SKIPPED (no signing identity provided)"
    echo "  App will use ad-hoc signature for local development"
fi

echo ""
echo "=========================================="
echo "Post-build processing complete!"
echo "=========================================="
