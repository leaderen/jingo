# ============================================================================
# Platform-macOS.cmake - macOS Platform Configuration
# ============================================================================
# This module handles:
# - macOS deployment target configuration
# - macOS-specific source files
# - macOS frameworks (AppKit, NetworkExtension, etc.)
# - macOS Team ID for code signing
# - macOS entitlements paths
# - macOS bundle icon configuration
# - Code signing identity setup
#
# Usage:
#   if(TARGET_MACOS)
#       include(cmake/Platform-macOS.cmake)
#   endif()
#
# Variables set by this module:
#   PLATFORM_NAME - "macOS"
#   PLATFORM_SOURCES - macOS-specific source files
#   PLATFORM_LIBS - macOS frameworks
#   PLATFORM_RESOURCES - macOS bundle resources (icon)
#   CMAKE_OSX_DEPLOYMENT_TARGET - Minimum macOS version
#   MACOS_TEAM_ID - Development Team ID for code signing
#   APPLE_CODE_SIGN_IDENTITY - Code signing identity
#   SIGNING_IDENTITY - Alias for APPLE_CODE_SIGN_IDENTITY
#   APP_ENTITLEMENTS_SIGNED - Path to main app entitlements
#   EXT_ENTITLEMENTS_SIGNED - Path to extension entitlements
# ============================================================================

if(NOT TARGET_MACOS)
    message(WARNING "Platform-macOS.cmake included but TARGET_MACOS is not set")
    return()
endif()

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Configuring macOS Platform")
message(STATUS "========================================")

# ============================================================================
# macOS Platform Configuration
# ============================================================================

set(PLATFORM_NAME "macOS")

# ============================================================================
# macOS Deployment Target
# ============================================================================

set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum macOS version" FORCE)
message(STATUS "macOS deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")

# ============================================================================
# macOS Team ID and Code Signing Configuration
# ============================================================================

# Set default code signing identity if not already set
# macOS 分发使用 Developer ID Application
if(NOT DEFINED APPLE_CODE_SIGN_IDENTITY)
    set(APPLE_CODE_SIGN_IDENTITY "Developer ID Application"
        CACHE STRING "Code signing identity for Apple platforms")
endif()

# Set macOS Team ID from environment variable if not already defined
if(NOT DEFINED MACOS_TEAM_ID AND DEFINED ENV{MACOS_TEAM_ID})
    set(MACOS_TEAM_ID "$ENV{MACOS_TEAM_ID}" CACHE STRING "macOS Development Team ID")
endif()

# Fall back to APPLE_DEVELOPMENT_TEAM if MACOS_TEAM_ID is not set
if(NOT DEFINED MACOS_TEAM_ID AND DEFINED APPLE_DEVELOPMENT_TEAM)
    set(MACOS_TEAM_ID "${APPLE_DEVELOPMENT_TEAM}" CACHE STRING "macOS Development Team ID")
endif()

# Set default Team ID for JinGo project if not already set
if(NOT DEFINED MACOS_TEAM_ID)
    set(MACOS_TEAM_ID "P6H5GHKRFU" CACHE STRING "macOS Development Team ID (default for JinGo)")
    message(STATUS "Using default MACOS_TEAM_ID: ${MACOS_TEAM_ID}")
endif()

# Create signing identity alias for convenience
# CI 环境：不设置 SIGNING_IDENTITY，跳过构建阶段签名，由 build-macos.sh 的 sign_app() 处理
if(BUILD_KEYCHAIN_PATH)
    set(SIGNING_IDENTITY "")
    message(STATUS "CI Mode: Post-build signing DISABLED (will be handled by build script)")
else()
    set(SIGNING_IDENTITY "${APPLE_CODE_SIGN_IDENTITY}")
endif()

message(STATUS "macOS Code Signing Configuration:")
message(STATUS "  Code Sign Identity: ${APPLE_CODE_SIGN_IDENTITY}")
message(STATUS "  Team ID: ${MACOS_TEAM_ID}")

# ============================================================================
# macOS Source Files
# ============================================================================

# 平台源文件已编译在 libJinDoCore.a 中，无需重复编译
set(PLATFORM_SOURCES "")
message(STATUS "macOS platform sources: provided by JinDoCore static library")

# ============================================================================
# macOS Frameworks
# ============================================================================

find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
find_library(SECURITY_FRAMEWORK Security REQUIRED)
find_library(COREFOUNDATION_FRAMEWORK CoreFoundation REQUIRED)
find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
find_library(SYSTEMCONFIGURATION_FRAMEWORK SystemConfiguration REQUIRED)
find_library(NETWORKEXTENSION_FRAMEWORK NetworkExtension REQUIRED)
find_library(USERNOTIFICATIONS_FRAMEWORK UserNotifications REQUIRED)
find_library(SYSTEMEXTENSIONS_FRAMEWORK SystemExtensions REQUIRED)

set(PLATFORM_LIBS
    ${FOUNDATION_FRAMEWORK}
    ${SECURITY_FRAMEWORK}
    ${COREFOUNDATION_FRAMEWORK}
    ${APPKIT_FRAMEWORK}
    ${IOKIT_FRAMEWORK}
    ${SYSTEMCONFIGURATION_FRAMEWORK}
    ${NETWORKEXTENSION_FRAMEWORK}
    ${USERNOTIFICATIONS_FRAMEWORK}
    ${SYSTEMEXTENSIONS_FRAMEWORK}
)

message(STATUS "macOS frameworks configured:")
message(STATUS "  - Foundation")
message(STATUS "  - Security")
message(STATUS "  - CoreFoundation")
message(STATUS "  - AppKit")
message(STATUS "  - IOKit")
message(STATUS "  - SystemConfiguration")
message(STATUS "  - NetworkExtension")
message(STATUS "  - UserNotifications")
message(STATUS "  - SystemExtensions")

# ============================================================================
# macOS Bundle Icon Configuration
# ============================================================================

set(MACOSX_BUNDLE_ICON_FILE app.icns)
set(APP_ICON_PATH ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/app.icns)

if(EXISTS ${APP_ICON_PATH})
    set(PLATFORM_RESOURCES ${APP_ICON_PATH})
    message(STATUS "macOS bundle icon: ${APP_ICON_PATH}")
else()
    message(WARNING "macOS icon file not found: ${APP_ICON_PATH}")
    set(PLATFORM_RESOURCES "")
endif()

# ============================================================================
# macOS Entitlements Paths
# ============================================================================

set(APP_ENTITLEMENTS_SIGNED "${CMAKE_CURRENT_SOURCE_DIR}/platform/macos/JinGo.entitlements"
    CACHE PATH "macOS app entitlements file")
set(EXT_ENTITLEMENTS_SIGNED "${CMAKE_CURRENT_SOURCE_DIR}/platform/macos/PacketTunnelProvider.entitlements"
    CACHE PATH "macOS PacketTunnelProvider entitlements file")

if(EXISTS "${APP_ENTITLEMENTS_SIGNED}")
    message(STATUS "macOS app entitlements: ${APP_ENTITLEMENTS_SIGNED}")
else()
    message(WARNING "macOS app entitlements not found: ${APP_ENTITLEMENTS_SIGNED}")
endif()

if(EXISTS "${EXT_ENTITLEMENTS_SIGNED}")
    message(STATUS "macOS extension entitlements: ${EXT_ENTITLEMENTS_SIGNED}")
else()
    message(WARNING "macOS extension entitlements not found: ${EXT_ENTITLEMENTS_SIGNED}")
endif()

# ============================================================================
# macOS Compiler Flags
# ============================================================================

# Note: Objective-C modules (-fmodules) are configured in main CMakeLists.txt
# using target_compile_options() for JinGo target (line ~1041)

message(STATUS "macOS platform configured successfully")
message(STATUS "========================================")
message(STATUS "")
