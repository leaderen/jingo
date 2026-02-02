# ============================================================================
# Platform-iOS.cmake - iOS Platform Configuration
# ============================================================================
# This module handles:
# - iOS deployment target configuration
# - iOS frameworks (UIKit, NetworkExtension, etc.)
# - iOS Team ID for code signing
# - iOS entitlements paths
#
# Note: Platform source files (PlatformInterface, IOSPlatform, etc.) are
#       pre-compiled in libJinDoCore.a and do not need to be compiled again.
#
# Usage:
#   if(TARGET_IOS)
#       include(cmake/Platform-iOS.cmake)
#   endif()
#
# Variables set by this module:
#   PLATFORM_NAME - "iOS"
#   PLATFORM_SOURCES - (empty, sources in JinDoCore)
#   PLATFORM_LIBS - iOS frameworks
#   CMAKE_OSX_DEPLOYMENT_TARGET - Minimum iOS version
#   IOS_TEAM_ID - Development Team ID for code signing
# ============================================================================

if(NOT TARGET_IOS)
    message(WARNING "Platform-iOS.cmake included but TARGET_IOS is not set")
    return()
endif()

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Configuring iOS Platform")
message(STATUS "========================================")

# ============================================================================
# iOS Platform Configuration
# ============================================================================

set(PLATFORM_NAME "iOS")

# ============================================================================
# iOS Deployment Target
# ============================================================================

set(CMAKE_OSX_DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum iOS version")
message(STATUS "iOS deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")

# ============================================================================
# CMake 3.29+ Workaround: Disable -no_warn_duplicate_libraries
# ============================================================================
# CMake 3.29+ adds -Wl,-no_warn_duplicate_libraries by default, but Xcode's
# clang doesn't understand this argument. Disable it for iOS builds.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.29")
    set(CMAKE_LINK_LIBRARY_USING_WHOLE_ARCHIVE "")
    # Xcode generator specific settings
    if(CMAKE_GENERATOR STREQUAL "Xcode")
        set(CMAKE_XCODE_ATTRIBUTE_OTHER_LDFLAGS "")
    endif()
endif()

# ============================================================================
# iOS Team ID Configuration
# ============================================================================

# Set iOS Team ID from environment variable if not already defined
if(NOT DEFINED IOS_TEAM_ID AND DEFINED ENV{IOS_TEAM_ID})
    set(IOS_TEAM_ID "$ENV{IOS_TEAM_ID}" CACHE STRING "iOS Development Team ID")
endif()

# Fall back to APPLE_DEVELOPMENT_TEAM if IOS_TEAM_ID is not set
if(NOT DEFINED IOS_TEAM_ID AND DEFINED APPLE_DEVELOPMENT_TEAM)
    set(IOS_TEAM_ID "${APPLE_DEVELOPMENT_TEAM}" CACHE STRING "iOS Development Team ID")
endif()

if(DEFINED IOS_TEAM_ID)
    message(STATUS "iOS Team ID: ${IOS_TEAM_ID}")
else()
    message(WARNING "IOS_TEAM_ID not set - code signing may fail")
    message(WARNING "  Set via: cmake -DIOS_TEAM_ID=YOUR_TEAM_ID ...")
    message(WARNING "  Or environment variable: export IOS_TEAM_ID=YOUR_TEAM_ID")
endif()

# ============================================================================
# iOS Source Files
# ============================================================================

# 平台源文件已编译在 libJinDoCore.a 中，无需重复编译
set(PLATFORM_SOURCES "")
message(STATUS "iOS platform sources: provided by JinDoCore static library")

# ============================================================================
# iOS Frameworks
# ============================================================================

find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
find_library(SECURITY_FRAMEWORK Security REQUIRED)
find_library(UIKIT_FRAMEWORK UIKit REQUIRED)
find_library(COREFOUNDATION_FRAMEWORK CoreFoundation REQUIRED)
find_library(NETWORKEXTENSION_FRAMEWORK NetworkExtension REQUIRED)
find_library(USERNOTIFICATIONS_FRAMEWORK UserNotifications REQUIRED)

set(PLATFORM_LIBS
    ${FOUNDATION_FRAMEWORK}
    ${SECURITY_FRAMEWORK}
    ${UIKIT_FRAMEWORK}
    ${COREFOUNDATION_FRAMEWORK}
    ${NETWORKEXTENSION_FRAMEWORK}
    ${USERNOTIFICATIONS_FRAMEWORK}
)

message(STATUS "iOS frameworks configured:")
message(STATUS "  - Foundation")
message(STATUS "  - Security")
message(STATUS "  - UIKit")
message(STATUS "  - CoreFoundation")
message(STATUS "  - NetworkExtension")
message(STATUS "  - UserNotifications")

# ============================================================================
# iOS Entitlements Paths
# ============================================================================

set(IOS_APP_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/platform/ios/JinGo.entitlements"
    CACHE PATH "iOS app entitlements file")
set(IOS_EXTENSION_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/platform/ios/PacketTunnelProvider.entitlements"
    CACHE PATH "iOS PacketTunnelProvider entitlements file")

if(EXISTS "${IOS_APP_ENTITLEMENTS}")
    message(STATUS "iOS app entitlements: ${IOS_APP_ENTITLEMENTS}")
else()
    message(WARNING "iOS app entitlements not found: ${IOS_APP_ENTITLEMENTS}")
endif()

if(EXISTS "${IOS_EXTENSION_ENTITLEMENTS}")
    message(STATUS "iOS extension entitlements: ${IOS_EXTENSION_ENTITLEMENTS}")
else()
    message(WARNING "iOS extension entitlements not found: ${IOS_EXTENSION_ENTITLEMENTS}")
endif()

message(STATUS "iOS platform configured successfully")
message(STATUS "========================================")
message(STATUS "")
