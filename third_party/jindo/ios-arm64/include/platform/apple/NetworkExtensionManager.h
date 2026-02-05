/**
 * @file NetworkExtensionManager.h
 * @brief Network Extension VPN管理器头文件
 * @details 使用NETunnelProviderManager管理VPN连接
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

// Include Server.h instead of forward declaration to avoid conflicts
#include "../models/Server.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief VPN连接状态枚举（对应NEVPNStatus）
 */
typedef NS_ENUM(NSInteger, NEVPNConnectionStatus) {
    NEVPNConnectionStatusInvalid = 0,        ///< 无效状态
    NEVPNConnectionStatusDisconnected = 1,   ///< 已断开
    NEVPNConnectionStatusConnecting = 2,     ///< 正在连接
    NEVPNConnectionStatusConnected = 3,      ///< 已连接
    NEVPNConnectionStatusReasserting = 4,    ///< 正在重新建立连接
    NEVPNConnectionStatusDisconnecting = 5   ///< 正在断开
};

/**
 * @brief VPN模式枚举
 * @details 支持两种工作模式
 */
typedef NS_ENUM(NSInteger, VPNMode) {
    VPNModeTUN = 0,         ///< TUN VPN模式 - NEPacketTunnelProvider (全局VPN,捕获所有IP层流量,Xray在Extension内)
    VPNModeProxy = 1        ///< 系统代理模式 - 非VPN,Xray在主应用提供SOCKS5代理(macOS)
};

/**
 * @brief Network Extension VPN管理器
 *
 * @details
 * 这个类是主应用中使用的VPN管理器，使用Apple的Network Extension Framework
 * 替代直接的TUN设备操作
 *
 * 主要职责：
 * 1. 管理NETunnelProviderManager实例
 * 2. 配置VPN设置
 * 3. 启动和停止VPN连接
 * 4. 监听VPN状态变化
 * 5. 与Extension通信获取统计信息
 * 6. 处理VPN配置的保存和加载
 *
 * 使用流程：
 * ```objective-c
 * NetworkExtensionManager *manager = [NetworkExtensionManager sharedManager];
 *
 * // 1. 配置VPN
 * [manager configureVPNWithServer:server
 *                      completion:^(NSError *error) {
 *     if (!error) {
 *         // 2. 连接VPN
 *         [manager connect:^(NSError *error) {
 *             if (!error) {
 *                 NSLog(@"VPN连接成功");
 *             }
 *         }];
 *     }
 * }];
 * ```
 *
 * 状态监听：
 * ```objective-c
 * [[NSNotificationCenter defaultCenter] addObserver:self
 *     selector:@selector(vpnStatusDidChange:)
 *     name:NEVPNStatusDidChangeNotification
 *     object:manager.tunnelManager.connection];
 * ```
 *
 * @note
 * - 使用单例模式
 * - 需要在Info.plist中配置Network Extension权限
 * - 需要配置entitlements
 */
@interface NetworkExtensionManager : NSObject

// ============================================================================
// MARK: - 单例
// ============================================================================

/**
 * @brief 获取共享实例
 * @return 单例对象
 */
+ (instancetype)sharedManager;

// ============================================================================
// MARK: - VPN管理器
// ============================================================================

/**
 * @brief NETunnelProviderManager实例 (TUN模式)
 *
 * @details
 * 用于管理PacketTunnelProvider Extension
 * 仅在VPNModeTUN时使用
 *
 * 功能：
 * - 配置TUN模式VPN
 * - 启动/停止PacketTunnel Extension
 * - 监听连接状态
 * - 与Extension通信
 */
@property (nonatomic, strong, readonly, nullable) NETunnelProviderManager *tunnelManager;

/**
 * @brief VPN连接对象
 *
 * @details
 * 返回tunnelManager的connection
 */
@property (nonatomic, strong, readonly, nullable) NEVPNConnection *connection;

/**
 * @brief 当前VPN状态
 *
 * @details
 * 对应NEVPNStatus枚举值
 * 使用KVO监听状态变化
 */
@property (nonatomic, assign, readonly) NEVPNConnectionStatus status;

/**
 * @brief 当前VPN模式
 *
 * @details
 * 指定使用TUN模式或系统代理模式
 * 默认值: VPNModeTUN
 *
 * TUN模式 (VPNModeTUN):
 * - 使用NEPacketTunnelProvider
 * - 全局VPN,捕获所有IP层流量
 * - 支持UDP转发
 * - Bundle ID: work.opine.jingo.PacketTunnelProvider
 *
 * 系统代理模式 (VPNModeProxy):
 * - 非VPN,Xray在主应用提供SOCKS5代理
 * - macOS/iOS通用
 */
@property (nonatomic, assign) VPNMode vpnMode;

// ============================================================================
// MARK: - VPN配置
// ============================================================================

/**
 * @brief 加载VPN配置
 *
 * @param completion 完成回调，error为nil表示成功
 *
 * @details
 * 从系统加载已保存的VPN配置
 * 如果之前没有配置，会创建一个新的
 *
 * @note
 * 在执行connect前必须先调用此方法
 * 或调用configureVPN
 */
- (void)loadVPNConfigWithCompletion:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 配置VPN
 *
 * @param server 服务器配置对象
 * @param completion 完成回调
 *
 * @details
 * 配置VPN并保存到系统
 *
 * 配置内容包括：
 * - VPN描述（显示在系统设置中）
 * - Extension Bundle Identifier
 * - 服务器配置（通过App Group共享给Extension）
 * - VPNCore配置（通过App Group共享给Extension）
 * - DNS设置
 * - 路由设置
 *
 * @note
 * - 需要用户授权（首次配置时会弹出权限对话框）
 * - 配置会保存到系统，重启应用后仍然有效
 * - 如果已有配置，会更新现有配置
 */
- (void)configureVPNWithServer:(Server *)server
                    completion:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 删除VPN配置
 *
 * @param completion 完成回调
 *
 * @details
 * 从系统中删除VPN配置
 * 删除后需要重新调用configureVPN才能连接
 *
 * @warning 会断开当前VPN连接
 */
- (void)removeVPNConfigWithCompletion:(void (^)(NSError * _Nullable error))completion;

// ============================================================================
// MARK: - VPN连接控制
// ============================================================================

/**
 * @brief 使用指定模式连接VPN
 *
 * @param mode VPN模式 (VPNModeTUN 或 VPNModeProxy)
 * @param completion 完成回调
 *
 * @details
 * 使用指定的Extension模式启动VPN连接
 *
 * 根据mode参数选择不同的Extension:
 * - VPNModeTUN: 使用PacketTunnelProvider.appex
 * - VPNModeProxy: 使用系统代理模式
 *
 * 连接流程：
 * 1. 设置vpnMode属性
 * 2. 选择对应的Extension Bundle ID
 * 3. 加载Extension配置
 * 4. 启动Extension进程
 * 5. Extension建立连接
 *
 * @note
 * - 模式会自动保存,下次连接使用相同模式
 * - 切换模式需要先断开当前连接
 */
- (void)connectWithMode:(VPNMode)mode
             completion:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 连接VPN（使用当前模式）
 *
 * @param completion 完成回调
 *
 * @details
 * 使用当前的vpnMode属性连接VPN
 * 等效于 connectWithMode:self.vpnMode completion:completion
 *
 * @note
 * - 连接前必须先调用configureVPN
 * - 可能需要用户授权（首次连接时）
 * - 连接过程是异步的，通过状态通知跟踪进度
 */
- (void)connect:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 断开VPN
 *
 * @details
 * 停止VPN连接
 *
 * 断开流程：
 * 1. 调用Extension的stopTunnel
 * 2. 停止数据包转发
 * 3. 清理网络设置
 * 4. 终止Extension进程
 */
- (void)disconnect;

/**
 * @brief 检查是否已连接
 *
 * @return YES=已连接，NO=未连接
 */
- (BOOL)isConnected;

/**
 * @brief 检查是否正在连接
 *
 * @return YES=正在连接，NO=其他状态
 */
- (BOOL)isConnecting;

// ============================================================================
// MARK: - SystemProxy模式 (macOS/iOS通用)
// ============================================================================

/**
 * @brief 启动SystemProxy模式
 *
 * @param server 服务器配置
 * @param completion 完成回调
 *
 * @details
 * SystemProxy模式工作流程:
 * 1. 在主应用启动Xray Core (监听127.0.0.1:10808)
 * 2. (macOS) 设置系统SOCKS5代理到127.0.0.1:10808
 * 3. (iOS) 用户需要手动配置代理或通过PAC文件
 *
 * 与VPN模式的区别:
 * - 不使用Network Extension
 * - Xray在主应用进程运行
 * - 依赖主应用保持运行
 * - macOS: 自动设置系统代理
 * - iOS: 需要手动配置或PAC
 *
 * @note SystemProxy模式不使用connect/disconnect方法
 * @warning 依赖主应用运行,退出应用会断开连接
 */
- (void)startSystemProxyWithServer:(Server *)server
                        completion:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 停止SystemProxy模式
 *
 * @details
 * 停止流程:
 * 1. (macOS) 恢复系统代理设置
 * 2. 停止主应用中的Xray
 *
 * @note 此方法是同步的
 */
- (void)stopSystemProxy;

// ============================================================================
// MARK: - Extension通信
// ============================================================================

/**
 * @brief 向Extension发送消息
 *
 * @param message 消息字典（将转换为JSON）
 * @param completion 完成回调，返回Extension的响应
 *
 * @details
 * 通过NETunnelProviderSession发送消息给Extension
 *
 * 支持的消息类型：
 * - {"type": "get_stats"}: 获取流量统计
 * - {"type": "ping"}: 检查Extension是否响应
 *
 * @example
 * ```objective-c
 * [manager sendMessageToExtension:@{@"type": @"get_stats"}
 *                      completion:^(NSDictionary *response, NSError *error) {
 *     if (!error && response[@"success"]) {
 *         NSDictionary *stats = response[@"data"];
 *         NSLog(@"Upload: %@, Download: %@",
 *               stats[@"bytesSent"], stats[@"bytesReceived"]);
 *     }
 * }];
 * ```
 */
- (void)sendMessageToExtension:(NSDictionary *)message
                    completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion;

/**
 * @brief 获取流量统计
 *
 * @param completion 完成回调
 *
 * @details
 * 从Extension获取实时流量统计
 * 内部调用sendMessageToExtension发送get_stats消息
 *
 * @note 需要在VPN连接状态下调用
 */
- (void)getStatistics:(void (^)(NSDictionary * _Nullable stats, NSError * _Nullable error))completion;

/**
 * @brief 通过 Extension 测试服务器延时
 *
 * @param address 服务器地址，格式: "host:port"
 * @param timeout 超时时间（毫秒）
 * @param completion 完成回调，返回延时值（毫秒）或 -1 表示失败
 *
 * @details
 * 在 TUN 模式下，网络流量通过 Extension 路由
 * 因此需要在 Extension 内部执行延时测试才能得到正确结果
 * 此方法发送测试命令到 Extension，由 Extension 执行 TCP ping
 *
 * @note 需要在 VPN 连接状态下调用
 */
- (void)testServerLatency:(NSString *)address
                  timeout:(int)timeout
               completion:(void (^)(int latency, NSError * _Nullable error))completion;

/**
 * @brief 触发 Extension 执行延时检测并保存到共享容器
 *
 * @param completion 完成回调，error 为 nil 表示成功触发
 *
 * @details
 * 发送 detect_delay 消息到 Extension，触发其执行延时检测
 * Extension 会将结果写入 App Group 共享容器的 delayinfo.json
 * 主应用可以通过读取该文件获取延时值
 *
 * @note
 * - 需要在 VPN 连接状态下调用
 * - 延时检测是异步的，此方法返回时结果可能尚未写入
 * - 建议等待 1-2 秒后再读取共享容器
 */
- (void)triggerDelayDetection:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 触发 Extension 执行延时检测（带服务器地址）
 *
 * @param serverAddress 服务器地址，用于 TCP ping 检测
 * @param serverPort 服务器端口
 * @param completion 完成回调，error 为 nil 表示成功触发
 *
 * @details
 * 发送 detect_delay 消息到 Extension，同时更新 Extension 内部的服务器地址
 * 适用于切换服务器后需要立即检测新服务器延时的场景
 *
 * @note
 * - 需要在 VPN 连接状态下调用
 * - 切换服务器后应使用此方法传入新服务器地址
 */
- (void)triggerDelayDetectionWithServerAddress:(NSString * _Nullable)serverAddress
                                    serverPort:(NSInteger)serverPort
                                    completion:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 从 Extension 获取延迟信息
 *
 * @param completion 完成回调，返回延迟信息字典或错误
 *
 * @details
 * 发送 get_delay_info 消息到 Extension，获取缓存的延迟检测结果
 * 返回数据包含：timestamp, delay, target, method
 *
 * @note
 * - 需要在 VPN 连接状态下调用
 * - 需要先调用 triggerDelayDetection 触发检测
 * - System Extension 无法写入 App Group，只能通过此方式获取
 */
- (void)getDelayInfo:(void (^)(NSDictionary * _Nullable delayInfo, NSError * _Nullable error))completion;

/**
 * @brief 从 Extension 获取 IP 信息
 *
 * @param completion 完成回调，返回 IP 信息字典或错误
 *
 * @details
 * 发送 get_ip_info 消息到 Extension，获取缓存的 IP 检测结果
 * 返回数据包含：ip, country, asn, isp, ipInfoDisplay
 *
 * @note
 * - 需要在 VPN 连接状态下调用
 * - Extension 会在连接成功后自动检测 IP
 * - System Extension 无法写入 App Group，只能通过此方式获取
 */
- (void)getIPInfo:(void (^)(NSDictionary * _Nullable ipInfo, NSError * _Nullable error))completion;

/**
 * @brief 触发 Extension 刷新 IP 检测
 *
 * @param completion 完成回调，error 为 nil 表示成功触发
 *
 * @details
 * 发送 refresh_ip 消息到 Extension，触发其重新检测 IP
 */
- (void)refreshIPDetection:(void (^)(NSError * _Nullable error))completion;

// ============================================================================
// MARK: - App Group共享
// ============================================================================

/**
 * @brief 保存服务器配置到App Group
 *
 * @param server 服务器对象
 * @param xrayConfig VPNCore配置JSON字符串
 *
 * @details
 * 将配置保存到App Group的共享存储
 * Extension启动时会从这里读取配置
 *
 * @note
 * - 使用NSUserDefaults(App Group)
 * - Extension和主应用都可以访问
 * - 配置包括服务器信息、VPNCore配置和SOCKS端口
 */
- (void)saveServerConfigToSharedStorage:(Server *)server
                            xrayConfig:(NSString *)xrayConfig
                             socksPort:(int)socksPort;

/**
 * @brief 从App Group读取服务器配置
 *
 * @return 服务器配置字典
 */
- (nullable NSDictionary *)loadServerConfigFromSharedStorage;

/**
 * @brief 从App Group读取VPNCore配置
 *
 * @return VPNCore配置JSON字符串
 */
- (nullable NSString *)loadXrayConfigFromSharedStorage;

// ============================================================================
// MARK: - 状态管理和重置
// ============================================================================

/**
 * @brief 强制重新加载VPN配置
 *
 * @param completion 完成回调
 *
 * @details
 * 不复用已缓存的tunnelManager，强制从系统重新加载
 * 用于解决状态残留导致的连接问题
 *
 * @note 会先清除当前缓存的manager，然后重新加载
 */
- (void)forceReloadConfigWithCompletion:(void (^)(NSError * _Nullable error))completion;

/**
 * @brief 强制断开VPN连接
 *
 * @details
 * 无论当前状态如何，都尝试断开VPN连接
 * 用于异常状态下的清理
 *
 * @note 会清除所有缓存的状态
 */
- (void)forceDisconnect;

/**
 * @brief 重置所有VPN状态
 *
 * @details
 * 清除所有缓存的manager和连接状态
 * 下次连接会重新加载配置
 */
- (void)resetAllState;

// ============================================================================
// MARK: - 状态监听
// ============================================================================

/**
 * @brief 开始监听VPN状态变化
 *
 * @details
 * 注册状态变化通知
 * 状态变化时会发送NEVPNStatusDidChangeNotification通知
 *
 * @note 自动在init中调用，通常不需要手动调用
 */
- (void)startObservingVPNStatus;

/**
 * @brief 停止监听VPN状态变化
 *
 * @note 自动在dealloc中调用，通常不需要手动调用
 */
- (void)stopObservingVPNStatus;

// ============================================================================
// MARK: - 日志和调试
// ============================================================================

/**
 * @brief 获取Extension日志
 *
 * @param lines 要获取的行数（0=全部）
 * @return 日志字符串
 *
 * @details
 * 从App Group共享的日志文件读取Extension日志
 * Extension会将日志写入共享容器
 */
- (nullable NSString *)getExtensionLogsWithLines:(NSUInteger)lines;

/**
 * @brief 输出诊断信息
 *
 * @details
 * 输出VPN管理器的详细状态：
 * - tunnelManager状态
 * - VPN连接状态
 * - 配置信息
 * - Extension通信状态
 */
- (void)dumpDiagnostics;

/**
 * @brief 读取Extension早期诊断日志
 *
 * @details
 * 读取Extension在启动时写入App Group的诊断日志
 * 用于调试Extension启动失败的问题
 *
 * @return 诊断日志内容，如果不存在返回错误信息
 */
- (NSString *)readExtensionDiagnosticLog;

/**
 * @brief 清除Extension诊断日志
 *
 * @details
 * 删除之前的诊断日志，用于下次测试前清空
 */
- (void)clearExtensionDiagnosticLog;

/**
 * @brief 清除所有Extension日志（诊断日志+运行时日志）
 *
 * @details
 * 删除App Group中的所有Extension日志文件
 */
- (void)clearExtensionLogs;

@end

NS_ASSUME_NONNULL_END
