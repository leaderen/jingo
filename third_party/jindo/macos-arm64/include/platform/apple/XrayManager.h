/**
 * @file XrayManager.h
 * @brief Xray Core管理器 - 在主应用进程中运行Xray
 * @details 用于SystemProxy模式
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Xray Core管理器
 *
 * @details
 * 在主应用进程中管理Xray Core实例
 *
 * 使用场景:
 * - macOS SystemProxy模式: Xray在主应用,提供127.0.0.1:10808代理
 *
 * 与Extension内Xray的区别:
 * - Extension内Xray: TUN模式专用,Extension进程管理
 * - 主应用内Xray: SystemProxy模式,主应用管理
 *
 * 生命周期:
 * - 主应用启动时不自动启动Xray
 * - 用户选择SystemProxy模式并连接时启动
 * - 断开连接或应用退出时停止
 *
 * 使用示例:
 * ```objective-c
 * XrayManager *manager = [XrayManager sharedManager];
 *
 * // 启动Xray
 * NSString *config = @"{...}";  // Xray JSON配置
 * NSError *error = nil;
 * if ([manager startXrayWithConfig:config error:&error]) {
 *     NSLog(@"Xray started, version: %@", [manager getVersion]);
 * }
 *
 * // 停止Xray
 * [manager stopXray];
 * ```
 */
@interface XrayManager : NSObject

// ============================================================================
// MARK: - 单例
// ============================================================================

/**
 * @brief 获取共享实例
 * @return 单例对象
 */
+ (instancetype)sharedManager;

// ============================================================================
// MARK: - Xray生命周期管理
// ============================================================================

/**
 * @brief 启动Xray Core
 *
 * @param configJSON Xray配置JSON字符串
 * @param error 错误信息输出参数
 * @return 成功返回YES,失败返回NO
 *
 * @details
 * 在主应用进程中启动Xray Core
 *
 * 配置要求:
 * - 必须包含有效的inbounds配置
 * - 建议使用127.0.0.1监听(SystemProxy模式)
 * - SOCKS5端口默认10808
 *
 * 注意事项:
 * - 如果Xray已经在运行,会先停止再启动
 * - 启动失败时,error参数会包含详细错误信息
 * - Xray日志会输出到控制台和日志文件
 *
 * @warning 此方法必须在主线程调用
 */
- (BOOL)startXrayWithConfig:(NSString *)configJSON
                      error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 * @brief 停止Xray Core
 *
 * @details
 * 优雅地停止Xray进程
 *
 * 停止流程:
 * 1. 发送停止信号给Xray
 * 2. 等待Xray正常退出
 * 3. 清理资源
 *
 * @note 如果Xray未运行,调用此方法是安全的(无操作)
 */
- (void)stopXray;

/**
 * @brief 检查Xray是否正在运行
 *
 * @return 运行中返回YES,否则返回NO
 */
- (BOOL)isRunning;

// ============================================================================
// MARK: - Xray信息查询
// ============================================================================

/**
 * @brief 获取Xray版本号
 *
 * @return Xray版本字符串,如 "Xray 1.8.4 (Go 1.21.0)"
 *         如果Xray未运行,返回nil
 *
 * @details
 * 通过XrayCBridge获取Xray版本信息
 */
- (nullable NSString *)getVersion;

/**
 * @brief 获取Xray统计信息
 *
 * @return 统计信息字典,包含:
 *         - uplink: 上行流量(字节)
 *         - downlink: 下行流量(字节)
 *         - uptime: 运行时间(秒)
 *         如果Xray未运行,返回nil
 *
 * @details
 * 实时查询Xray的流量统计
 */
- (nullable NSDictionary *)getStatistics;

/**
 * @brief 获取当前SOCKS5端口
 *
 * @return SOCKS5监听端口,如10808
 *         如果Xray未运行,返回0
 */
- (int)getSocksPort;

// ============================================================================
// MARK: - 日志和调试
// ============================================================================

/**
 * @brief 获取Xray日志
 *
 * @param lines 获取最近N行日志,0表示全部
 * @return 日志字符串
 *
 * @details
 * 从日志文件读取Xray输出
 */
- (nullable NSString *)getLogsWithLines:(NSUInteger)lines;

/**
 * @brief 输出诊断信息
 *
 * @details
 * 打印Xray管理器的详细状态:
 * - 运行状态
 * - 版本信息
 * - 配置信息
 * - 统计信息
 */
- (void)dumpDiagnostics;

@end

NS_ASSUME_NONNULL_END
