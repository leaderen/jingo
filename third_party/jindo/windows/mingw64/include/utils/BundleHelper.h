/**
 * @file BundleHelper.h
 * @brief C++ Bundle ID 推导工具（header-only, Apple 平台专用）
 *
 * 提供 CoreFoundation C 版本和 Qt/QString 版本的 Bundle ID 推导，
 * 用于纯 C++ 编译单元（不依赖 Foundation）。
 */

#ifndef JINDO_BUNDLE_HELPER_H
#define JINDO_BUNDLE_HELPER_H

#ifdef __APPLE__

#include <CoreFoundation/CoreFoundation.h>
#include <cstring>

/// CoreFoundation C 版本：获取主应用 Bundle ID（去掉 .PacketTunnelProvider 后缀）
/// 返回指向内部静态缓冲区的指针，线程安全（仅初始化一次）。
static inline const char* JinDo_GetMainAppBundleIdCStr() {
    static char bundleId[256] = {0};
    if (bundleId[0] == 0) {
        CFBundleRef mainBundle = CFBundleGetMainBundle();
        if (mainBundle) {
            CFStringRef bundleIdRef = CFBundleGetIdentifier(mainBundle);
            if (bundleIdRef) {
                CFStringGetCString(bundleIdRef, bundleId, sizeof(bundleId), kCFStringEncodingUTF8);
            }
        }
        if (bundleId[0] == 0) {
            strncpy(bundleId, "work.opine.jingo", sizeof(bundleId) - 1);
        }
        const char *suffix = ".PacketTunnelProvider";
        size_t idLen = strlen(bundleId);
        size_t sufLen = strlen(suffix);
        if (idLen > sufLen && strcmp(bundleId + idLen - sufLen, suffix) == 0) {
            bundleId[idLen - sufLen] = '\0';
        }
    }
    return bundleId;
}

#if __has_include(<QString>)
#include <QString>

/// Qt/QString 版本：去掉 Bundle ID 中的 .PacketTunnelProvider 后缀
static inline QString JinDo_StripExtensionSuffix(QString bundleId) {
    const QString ptSuffix = QStringLiteral(".PacketTunnelProvider");
    if (bundleId.endsWith(ptSuffix)) {
        bundleId.chop(ptSuffix.length());
    }
    return bundleId;
}

/// Qt/QString 版本：获取主应用 Bundle ID（从 CoreFoundation 读取并去后缀）
static inline QString JinDo_GetMainAppBundleIdQString() {
    return QString::fromUtf8(JinDo_GetMainAppBundleIdCStr());
}

#endif // __has_include(<QString>)
#endif // __APPLE__
#endif // JINDO_BUNDLE_HELPER_H
