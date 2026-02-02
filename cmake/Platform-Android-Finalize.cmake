# ============================================================================
# Platform-Android-Finalize.cmake - Android平台Finalization配置
# ============================================================================
# 说明: Android特定的最终配置,包括APK打包、库复制、资源部署等
#      必须在主应用目标创建和链接之后调用
# ============================================================================

if(NOT TARGET_ANDROID)
    message(FATAL_ERROR "Platform-Android-Finalize.cmake should only be included for Android builds")
endif()

# 设置 Android 包名 (从 APP_BUNDLE_ID 转换)
# iOS: cfd.jingo.acc -> Android: cfd.jingo.acc (保持一致)
if(NOT ANDROID_PACKAGE_NAME)
    set(ANDROID_PACKAGE_NAME "${APP_BUNDLE_ID}" CACHE STRING "Android package name")
endif()
message(STATUS "✓ Android Package Name: ${ANDROID_PACKAGE_NAME}")

set_target_properties(JinGo PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/platform/android
        QT_ANDROID_PACKAGE_NAME ${ANDROID_PACKAGE_NAME}
        QT_ANDROID_MIN_SDK_VERSION ${ANDROID_MIN_SDK_VERSION}
        QT_ANDROID_TARGET_SDK_VERSION ${ANDROID_TARGET_SDK_VERSION}
        QT_ANDROID_COMPILE_SDK_VERSION ${ANDROID_COMPILE_SDK_VERSION}
        QT_ANDROID_SDK_BUILD_TOOLS_REVISION ${ANDROID_BUILD_TOOLS_VERSION}
        QT_ANDROID_VERSION_CODE 1
        QT_ANDROID_VERSION_NAME ${PROJECT_VERSION}
)

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/platform/android/AndroidManifest.xml)
    message(STATUS "✓ AndroidManifest.xml found")
else()
    message(WARNING "Android manifest not found at platform/android/AndroidManifest.xml")
endif()

# Add OpenSSL libraries to APK before finalization
if(ANDROID_EXTRA_LIBS)
    set_property(TARGET JinGo APPEND PROPERTY QT_ANDROID_EXTRA_LIBS ${ANDROID_EXTRA_LIBS})
    message(STATUS "✓ OpenSSL libraries will be bundled in APK")
endif()

# Add SuperRay library dependencies
# SuperRay is a unified library that includes both Xray-core and TUN processing
if(SUPERRAY_IS_AAR AND EXISTS ${AAR_EXTRACT_DIR})
    # Add libsuperray.so to extra libs
    if(EXISTS ${SUPERRAY_SO_PATH})
        set_property(TARGET JinGo APPEND PROPERTY QT_ANDROID_EXTRA_LIBS ${SUPERRAY_SO_PATH})
        message(STATUS "✓ libsuperray.so will be bundled in APK: ${SUPERRAY_SO_PATH}")
    endif()
endif()

# Add OpenSSL libraries for Android (required for HTTPS/TLS)
if(ANDROID_EXTRA_LIBS)
    foreach(ssl_lib ${ANDROID_EXTRA_LIBS})
        set_property(TARGET JinGo APPEND PROPERTY QT_ANDROID_EXTRA_LIBS ${ssl_lib})
        get_filename_component(ssl_lib_name ${ssl_lib} NAME)
        message(STATUS "✓ ${ssl_lib_name} will be bundled in APK")
    endforeach()
    message(STATUS "✓ OpenSSL libraries will be bundled in APK")
else()
    message(WARNING "OpenSSL libraries not configured - HTTPS/TLS will not work")
endif()

# Add SuperRay CORE library for Android (if not using AAR)
# SuperRay provides both Xray-core and TUN processing in a unified library
# Note: The core library is renamed to libsuperray_core.so to avoid conflict with JNI wrapper
# 从 JinDoCore 目录查找 SuperRay 动态库
if(NOT DEFINED SUPERRAY_LIB OR NOT EXISTS "${SUPERRAY_LIB}")
    set(SUPERRAY_LIB "${JINDO_THIRD_PARTY}/android/${CMAKE_ANDROID_ARCH_ABI}/libsuperray.so")
endif()

if(TARGET superray_imported)
    # Using imported target from Dependencies-Xray.cmake
    get_target_property(SUPERRAY_SO_LOCATION superray_imported IMPORTED_LOCATION)
    if(EXISTS "${SUPERRAY_SO_LOCATION}")
        # Copy to build directory with new name (libsuperray_core.so)
        set(SUPERRAY_CORE_LIB "${CMAKE_CURRENT_BINARY_DIR}/lib/libsuperray_core.so")
        file(COPY ${SUPERRAY_SO_LOCATION} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/lib)
        file(RENAME "${CMAKE_CURRENT_BINARY_DIR}/lib/libsuperray.so" "${SUPERRAY_CORE_LIB}")
        set_property(TARGET JinGo APPEND PROPERTY QT_ANDROID_EXTRA_LIBS ${SUPERRAY_CORE_LIB})
        message(STATUS "✓ libsuperray_core.so will be bundled in APK: ${SUPERRAY_CORE_LIB}")
    endif()
elseif(EXISTS "${SUPERRAY_LIB}")
    # Copy to build directory with new name
    set(SUPERRAY_CORE_LIB "${CMAKE_CURRENT_BINARY_DIR}/lib/libsuperray_core.so")
    file(COPY ${SUPERRAY_LIB} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/lib)
    file(RENAME "${CMAKE_CURRENT_BINARY_DIR}/lib/libsuperray.so" "${SUPERRAY_CORE_LIB}")
    set_property(TARGET JinGo APPEND PROPERTY QT_ANDROID_EXTRA_LIBS ${SUPERRAY_CORE_LIB})
    message(STATUS "✓ libsuperray_core.so will be bundled in APK: ${SUPERRAY_CORE_LIB}")
else()
    message(WARNING "SuperRay library not found, VPN functionality may not work")
endif()

qt_finalize_target(JinGo)

# 设置 Android 部署配置（必须在 finalize 之后,让 Qt Creator 能正确识别）
set_target_properties(JinGo PROPERTIES
    QT_ANDROID_ABIS "${ANDROID_ABI}"
    QT_ANDROID_MIN_SDK_VERSION 28
    QT_ANDROID_TARGET_SDK_VERSION 34
)
message(STATUS "✓ Android deployment configured: ABI=${ANDROID_ABI}, minSDK=28, targetSDK=34")

# 创建清理 Gradle 缓存的自定义目标
add_custom_target(clean_gradle_cache
    COMMAND ${CMAKE_COMMAND} -E echo "Cleaning Gradle cache..."
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/merged_jni_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/stripped_native_libs"
    COMMAND ${CMAKE_COMMAND} -E echo "✓ Gradle cache cleaned"
    COMMENT "Cleaning Gradle intermediate cache"
)

# 自动复制 libJinGo 库到 Gradle libs 目录（确保 Gradle 使用最新编译的库）
# 需要复制到两个可能的目录：android-build 和 android-build-JinGo
add_custom_command(TARGET JinGo PRE_LINK
    # 清理 Gradle 缓存（在链接之前,确保使用最新的库文件）
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/merged_jni_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/stripped_native_libs"
    COMMENT "Cleaning Gradle cache before linking"
    VERBATIM
)

add_custom_command(TARGET JinGo POST_BUILD
    # 先清理 Gradle 缓存的中间文件（在复制新文件之前）
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build-JinGo/build/intermediates/merged_jni_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build-JinGo/build/intermediates/merged_native_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build-JinGo/build/intermediates/stripped_native_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/merged_jni_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/merged_native_libs"
    COMMAND ${CMAKE_COMMAND} -E remove_directory
        "${CMAKE_BINARY_DIR}/android-build/build/intermediates/stripped_native_libs"

    # 复制到 android-build 目录
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "${CMAKE_BINARY_DIR}/android-build/libs/${ANDROID_ABI}"
    COMMAND ${CMAKE_COMMAND} -E remove -f
        "${CMAKE_BINARY_DIR}/android-build/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"
    COMMAND ${CMAKE_COMMAND} -E copy
        "$<TARGET_FILE:JinGo>"
        "${CMAKE_BINARY_DIR}/android-build/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"
    COMMAND ${CMAKE_COMMAND} -E touch
        "${CMAKE_BINARY_DIR}/android-build/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"

    # 复制到 android-build-JinGo 目录
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "${CMAKE_BINARY_DIR}/android-build-JinGo/libs/${ANDROID_ABI}"
    COMMAND ${CMAKE_COMMAND} -E remove -f
        "${CMAKE_BINARY_DIR}/android-build-JinGo/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"
    COMMAND ${CMAKE_COMMAND} -E copy
        "$<TARGET_FILE:JinGo>"
        "${CMAKE_BINARY_DIR}/android-build-JinGo/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"
    COMMAND ${CMAKE_COMMAND} -E touch
        "${CMAKE_BINARY_DIR}/android-build-JinGo/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"

    COMMENT "Cleaning Gradle cache, copying libJinGo to Gradle libs directories with updated timestamp"
    VERBATIM
)
message(STATUS "✓ libJinGo will be automatically copied to android-build*/libs/${ANDROID_ABI}/ after build")

# 复制翻译文件到 Android assets (必须在 finalize 之后)
set(ANDROID_ASSETS_TRANSLATIONS "${CMAKE_CURRENT_SOURCE_DIR}/platform/android/assets/translations")
file(MAKE_DIRECTORY "${ANDROID_ASSETS_TRANSLATIONS}")

# 直接从resources/translations复制预编译的.qm文件（所有平台通用）
file(GLOB QM_RESOURCE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/resources/translations/*.qm")
if(QM_RESOURCE_FILES)
    foreach(qm_file ${QM_RESOURCE_FILES})
        get_filename_component(qm_filename ${qm_file} NAME)
        configure_file(${qm_file} "${ANDROID_ASSETS_TRANSLATIONS}/${qm_filename}" COPYONLY)
    endforeach()

    list(LENGTH QM_RESOURCE_FILES QM_COUNT)
    message(STATUS "✓ Copied ${QM_COUNT} translation files to Android assets")
else()
    message(WARNING "No translation files found in resources/translations/")
endif()

# 复制 GeoIP 数据文件到 Android assets (必须在 finalize 之后)
if(EXISTS ${GEOIP_DAT_FILE} AND EXISTS ${GEOSITE_DAT_FILE})
    add_custom_command(TARGET JinGo POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${GEOIP_DAT_FILE}"
            "${ANDROID_GEOIP_ASSETS_DIR}/geoip.dat"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${GEOSITE_DAT_FILE}"
            "${ANDROID_GEOIP_ASSETS_DIR}/geosite.dat"
        COMMENT "Copying GeoIP data files to Android assets/dat"
    )
    message(STATUS "✓ Will copy GeoIP data files (geoip.dat, geosite.dat) to Android assets on each build")
else()
    message(WARNING "GeoIP data files not found in ${GEOIP_SOURCE_DIR}")
endif()

# Note: SuperRay does not require classes.jar copying
# SuperRay is a pure native library with C API, no Java/Kotlin bindings needed

# ========================================================================
# 每次编译前复制自定义build.gradle（禁用Gradle缓存）
# ========================================================================
add_custom_command(TARGET JinGo PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "=== [PRE_BUILD] Copying custom build.gradle to disable Gradle caching ==="
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/platform/android/build.gradle"
        "${CMAKE_BINARY_DIR}/android-build-JinGo/build.gradle"
    COMMENT "Copying custom build.gradle with caching disabled"
    VERBATIM
)

# ========================================================================
# 每次编译都在POST_BUILD中强制复制.so到所有libs目录（不检查是否不同）
# ========================================================================
add_custom_command(TARGET JinGo POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "=== [POST_BUILD] Force copy libJinGo to ALL libs locations ==="

    # 删除整个android-build的build和.gradle目录（强制Gradle重新构建）
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_BINARY_DIR}/android-build-JinGo/build"
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_BINARY_DIR}/android-build-JinGo/.gradle"

    # 1. 复制到android-build/libs目录
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/android-build-JinGo/libs/${ANDROID_ABI}"
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_BINARY_DIR}/lib/libJinGo_${ANDROID_ABI}.so"
        "${CMAKE_BINARY_DIR}/android-build-JinGo/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"

    # 2. 复制到platform/android/libs目录（Qt的apk target会从这里复制）
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/platform/android/libs/${ANDROID_ABI}"
    COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_BINARY_DIR}/lib/libJinGo_${ANDROID_ABI}.so"
        "${CMAKE_SOURCE_DIR}/platform/android/libs/${ANDROID_ABI}/libJinGo_${ANDROID_ABI}.so"

    COMMAND ${CMAKE_COMMAND} -E echo "=== [POST_BUILD] libJinGo copied to android-build/libs and platform/android/libs ==="
    COMMENT "Force copy libJinGo to all libs directories"
    VERBATIM
)

message(STATUS "✓ Added PRE_BUILD: custom build.gradle (no-cache) will be copied before each build")
message(STATUS "✓ Added POST_BUILD: libJinGo will be forcibly copied and Gradle caches cleared after each build")

# ============================================================================
# Android JNI库配置 - SuperRay
# ============================================================================

message(STATUS "")
message(STATUS "========================================")
message(STATUS "Building Android SuperRay JNI library")
message(STATUS "========================================")

# SuperRay JNI库 - 统一的TUN和Xray处理
# 注意: 库名为 "superray" 以便 Kotlin 通过 System.loadLibrary("superray") 加载
# JNI 源文件从 JinDoCore 导出的 jni/ 目录获取
set(JINDO_JNI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/jindo/android/jni")
set(SUPERRAY_JNI_SOURCE "${JINDO_JNI_DIR}/tun2socks_jni.cpp")
message(STATUS "Using JNI source from JinDoCore: ${SUPERRAY_JNI_SOURCE}")

add_library(superray SHARED
    ${SUPERRAY_JNI_SOURCE}
)

target_include_directories(superray PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/platform/android/cpp
    ${JINDO_INCLUDE_DIR}
)

# Link to SuperRay CORE library (renamed to avoid conflict)
# We use the renamed library (libsuperray_core.so) to avoid collision with JNI wrapper
if(EXISTS "${SUPERRAY_CORE_LIB}")
    # Create an imported target for the renamed core library
    add_library(superray_core_imported SHARED IMPORTED)
    set_target_properties(superray_core_imported PROPERTIES
        IMPORTED_LOCATION "${SUPERRAY_CORE_LIB}"
        IMPORTED_NO_SONAME TRUE
    )
    target_link_libraries(superray
        android
        log
        superray_core_imported
    )
    # Add linker flag to use just the library name in NEEDED
    target_link_options(superray PRIVATE
        "-Wl,-soname,libsuperray.so"
    )
    message(STATUS "✓ Linked superray JNI to libsuperray_core.so")
elseif(TARGET superray_imported)
    target_link_libraries(superray
        android
        log
        superray_imported
    )
    message(STATUS "✓ Linked superray JNI to imported SuperRay target")
elseif(EXISTS "${SUPERRAY_LIB}")
    target_link_libraries(superray
        android
        log
        ${SUPERRAY_LIB}
    )
    message(STATUS "✓ Linked superray JNI to ${SUPERRAY_LIB}")
else()
    target_link_libraries(superray
        android
        log
    )
    message(WARNING "SuperRay library not found, JNI will fail at runtime")
endif()

# Make sure JNI library is built before JinGo target
add_dependencies(JinGo superray)

# Link JinGo to superray JNI wrapper (required for Android_ProtectedTcpPing etc.)
# Use explicit full path to ensure the JNI wrapper is found (not the core library with same name)
set(SUPERRAY_JNI_WRAPPER "${CMAKE_CURRENT_BINARY_DIR}/lib/libsuperray.so")
target_link_libraries(JinGo PRIVATE "${SUPERRAY_JNI_WRAPPER}")

# Also ensure superray_core is linked for the SuperRay core functions
if(EXISTS "${SUPERRAY_CORE_LIB}")
    target_link_libraries(JinGo PRIVATE "${SUPERRAY_CORE_LIB}")
    message(STATUS "✓ JinGo linked to superray core: ${SUPERRAY_CORE_LIB}")
endif()
message(STATUS "✓ JinGo linked to superray JNI wrapper: ${SUPERRAY_JNI_WRAPPER}")

# Add JNI library to APK
set_property(TARGET JinGo APPEND PROPERTY
    QT_ANDROID_EXTRA_LIBS
    "${CMAKE_CURRENT_BINARY_DIR}/lib/libsuperray.so"
)

message(STATUS "Android SuperRay JNI library configured")
message(STATUS "  superray: libsuperray.so (JNI wrapper)")
message(STATUS "  ABI: ${ANDROID_ABI}")
message(STATUS "  API Level: ${ANDROID_PLATFORM}")
message(STATUS "  ✓ SuperRay JNI library will be bundled in APK")
message(STATUS "========================================")
message(STATUS "")
