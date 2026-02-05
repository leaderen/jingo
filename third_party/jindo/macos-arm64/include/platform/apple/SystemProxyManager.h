/**
 * @file SystemProxyManager.h
 * @brief macOS系统代理管理器
 * @details 使用SystemConfiguration框架设置系统SOCKS5代理
 *
 * @note 仅macOS平台可用
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief macOS系统代理管理器
 *
 * @details
 * 管理macOS系统级别的代理设置
 *
 * 功能:
 * - 设置SOCKS5系统代理
 * - 恢复原始代理设置
 * - 配置代理排除列表
 * - 支持多网络接口
 *
 * 工作原理:
 * 1. 使用SystemConfiguration框架修改系统代理设置
 * 2. 保存原始配置,以便恢复
 * 3. 应用到所有活动网络服务
 *
 * 权限要求:
 * - 修改系统代理可能需要管理员权限
 * - 用户首次设置时会弹出授权对话框
 *
 * 使用示例:
 * ```objective-c
 * SystemProxyManager *manager = [SystemProxyManager sharedManager];
 *
 * // 启用系统代理
 * NSError *error = nil;
 * if ([manager enableSystemProxy:@"127.0.0.1" port:10808 error:&error]) {
 *     NSLog(@"System proxy enabled");
 * }
 *
 * // 禁用系统代理(恢复原始设置)
 * [manager disableSystemProxyWithError:nil];
 * ```
 *
 * @warning
 * - 仅macOS平台可用
 * - 需要授权访问系统配置
 * - 修改后会影响所有应用的网络连接
 */
@interface SystemProxyManager : NSObject

// ============================================================================
// MARK: - 单例
// ============================================================================

/**
 * @brief 获取共享实例
 * @return 单例对象
 */
+ (instancetype)sharedManager;

// ============================================================================
// MARK: - 系统代理控制
// ============================================================================

/**
 * @brief 启用系统SOCKS5代理
 *
 * @param host SOCKS5代理服务器地址 (如 "127.0.0.1")
 * @param port SOCKS5代理端口 (如 10808)
 * @param error 错误信息输出参数
 * @return 成功返回YES,失败返回NO
 *
 * @details
 * 设置系统级SOCKS5代理,影响所有网络连接
 *
 * 配置内容:
 * - SOCKS代理: host:port
 * - 排除列表: 本地地址和私有网络
 * - 应用范围: 所有活动网络服务
 *
 * 排除地址列表:
 * - localhost, 127.0.0.1, ::1
 * - 10.0.0.0/8
 * - 172.16.0.0/12
 * - 192.168.0.0/16
 * - *.local
 *
 * 注意事项:
 * - 会保存当前代理设置用于恢复
 * - 如果已启用代理,会先禁用再重新启用
 * - 修改需要用户授权
 *
 * @warning 此方法必须在主线程调用
 */
- (BOOL)enableSystemProxy:(NSString *)host
                     port:(int)port
                    error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 * @brief 禁用系统代理(恢复原始设置)
 *
 * @param error 错误信息输出参数
 * @return 成功返回YES,失败返回NO
 *
 * @details
 * 恢复启用代理前的系统设置
 *
 * 恢复流程:
 * 1. 读取保存的原始配置
 * 2. 应用到所有网络服务
 * 3. 清理保存的配置
 *
 * @note 如果代理未启用,调用此方法是安全的(无操作)
 */
- (BOOL)disableSystemProxyWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 * @brief 检查系统代理是否已启用
 *
 * @return 已启用返回YES,否则返回NO
 *
 * @details
 * 检查是否通过此管理器启用了代理
 *
 * 注意:
 * - 仅检查通过此管理器设置的代理
 * - 用户手动设置的代理不会被检测
 */
- (BOOL)isProxyEnabled;

// ============================================================================
// MARK: - 代理信息查询
// ============================================================================

/**
 * @brief 获取当前系统代理配置
 *
 * @return 代理配置字典,包含:
 *         - SOCKSEnabled: 是否启用 (NSNumber)
 *         - SOCKSProxy: 代理地址 (NSString)
 *         - SOCKSPort: 代理端口 (NSNumber)
 *         - ExceptionsList: 排除列表 (NSArray)
 *         如果未启用或获取失败,返回nil
 */
- (nullable NSDictionary *)getCurrentProxySettings;

/**
 * @brief 获取所有网络服务列表
 *
 * @return 网络服务名称数组 (如 @[@"Wi-Fi", @"Ethernet"])
 *         获取失败返回空数组
 *
 * @details
 * 列出系统中所有网络服务
 * 用于调试和诊断
 */
- (NSArray<NSString *> *)getNetworkServices;

// ============================================================================
// MARK: - 日志和调试
// ============================================================================

/**
 * @brief 输出诊断信息
 *
 * @details
 * 打印系统代理管理器的详细状态:
 * - 代理启用状态
 * - 当前代理配置
 * - 网络服务列表
 * - 原始配置备份
 */
- (void)dumpDiagnostics;

@end

NS_ASSUME_NONNULL_END

#endif // TARGET_OS_OSX
