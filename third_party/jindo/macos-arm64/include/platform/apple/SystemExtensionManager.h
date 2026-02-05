/**
 * @file SystemExtensionManager.h
 * @brief macOS System Extension 管理器
 * @details 使用 OSSystemExtensionRequest API 管理系统扩展的安装和卸载
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright (c) 2025 JinGo Team. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// macOS 10.15+ 才支持 System Extension
#if TARGET_OS_OSX

/**
 * @brief System Extension 安装状态
 */
typedef NS_ENUM(NSInteger, SystemExtensionStatus) {
    SystemExtensionStatusUnknown = 0,
    SystemExtensionStatusNotInstalled,
    SystemExtensionStatusInstalled,
    SystemExtensionStatusNeedsApproval,
    SystemExtensionStatusInstalling,
    SystemExtensionStatusUninstalling
};

/**
 * @brief System Extension 管理器
 * @details 管理 PacketTunnelProvider System Extension 的安装、卸载和状态检查
 */
@interface SystemExtensionManager : NSObject

/**
 * @brief 获取单例实例
 */
+ (instancetype)sharedManager;

/**
 * @brief 当前系统扩展状态
 */
@property (nonatomic, readonly) SystemExtensionStatus status;

/**
 * @brief 检查 System Extension 是否已安装
 * @return YES 表示已安装，NO 表示未安装
 */
- (BOOL)isSystemExtensionInstalled;

/**
 * @brief 请求安装 System Extension
 * @param completion 完成回调 (error 为 nil 表示成功)
 * @discussion 如果扩展已安装，会直接返回成功
 *             如果需要用户授权，系统会显示授权对话框
 */
- (void)requestInstallSystemExtension:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 请求卸载 System Extension
 * @param completion 完成回调
 */
- (void)requestUninstallSystemExtension:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 获取 System Extension 版本
 * @return 扩展版本字符串，如果未安装返回 nil
 */
- (nullable NSString *)systemExtensionVersion;

/**
 * @brief System Extension Bundle ID
 */
@property (nonatomic, readonly) NSString *extensionBundleIdentifier;

@end

#endif // TARGET_OS_OSX

NS_ASSUME_NONNULL_END
