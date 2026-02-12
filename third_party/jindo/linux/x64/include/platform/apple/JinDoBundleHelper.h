/**
 * @file JinDoBundleHelper.h
 * @brief ObjC/Foundation Bundle ID 推导工具（header-only）
 *
 * 从当前进程的 Bundle ID 动态推导主应用 Bundle ID，兼容 Extension 进程。
 * 所有函数均为 static inline，可在多个 .mm 文件中安全 #import。
 */

#import <Foundation/Foundation.h>

/// 获取主应用 Bundle ID（自动去掉 .PacketTunnelProvider 后缀）
static inline NSString * JinDo_MainAppBundleID() {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *suffix = @".PacketTunnelProvider";
    if ([bundleID hasSuffix:suffix]) {
        bundleID = [bundleID substringToIndex:bundleID.length - suffix.length];
    }
    return bundleID;
}

/// App Group ID: group.<mainAppBundleID>
static inline NSString * JinDo_AppGroupID() {
    return [@"group." stringByAppendingString:JinDo_MainAppBundleID()];
}

/// Extension Bundle ID: <mainAppBundleID>.PacketTunnelProvider
static inline NSString * JinDo_ExtensionBundleID() {
    return [JinDo_MainAppBundleID() stringByAppendingString:@".PacketTunnelProvider"];
}
