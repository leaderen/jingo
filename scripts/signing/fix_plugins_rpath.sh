#!/bin/bash
# ============================================================================
# fix_plugins_rpath.sh - Fix Qt plugins rpath for macOS app bundle
# ============================================================================
# macdeployqt sets plugin rpath to @loader_path/../../lib, but Qt frameworks
# are actually in Contents/Frameworks. This script fixes the rpath.
#
# Usage:
#   ./fix_plugins_rpath.sh <app_bundle_path>
#
# ============================================================================

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <app_bundle_path>"
    exit 1
fi

APP_BUNDLE="$1"
PLUGINS_DIR="$APP_BUNDLE/Contents/PlugIns"

if [ ! -d "$PLUGINS_DIR" ]; then
    echo "PlugIns directory not found: $PLUGINS_DIR"
    exit 0
fi

echo "Fixing Qt plugins rpath..."

# Find all dylib files in PlugIns directory
find "$PLUGINS_DIR" -name "*.dylib" | while read dylib; do
    # Check if rpath already contains Frameworks
    if ! otool -l "$dylib" 2>/dev/null | grep -q "@loader_path/../../Frameworks"; then
        # Add correct rpath
        install_name_tool -add_rpath "@loader_path/../../Frameworks" "$dylib" 2>/dev/null || true
        echo "  Fixed: $(basename $dylib)"
    fi
done

echo "Plugins rpath fix complete"
