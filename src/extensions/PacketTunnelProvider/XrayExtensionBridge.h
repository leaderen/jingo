/**
 * @file XrayExtensionBridge.h
 * @brief Xray管理类 - Network Extension专用版本
 * @details 在Extension内部运行SuperRay实例,监听127.0.0.1:10808
 *          供SuperRay TUN连接使用
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Extension内的Xray管理类
 *
 * 此类在Network Extension进程中运行SuperRay实例
 * TUN模式: SuperRay TUN连接到127.0.0.1:10808
 */
@interface XrayExtensionBridge : NSObject

/**
 * @brief Xray是否正在运行
 */
@property (nonatomic, readonly) BOOL isRunning;

/**
 * @brief 获取单例实例
 */
+ (instancetype)sharedInstance;

/**
 * @brief 启动Xray
 * @param configJSON Xray配置JSON字符串
 * @param error 错误信息(如果启动失败)
 * @return 成功返回YES,失败返回NO
 *
 * @note 此方法会在后台启动Xray,SOCKS5默认监听127.0.0.1:10808
 */
- (BOOL)startWithConfig:(NSString *)configJSON error:(NSError **)error;

/**
 * @brief 停止Xray
 *
 * @note 安全调用,即使Xray未运行也不会出错
 */
- (void)stop;

/**
 * @brief 获取Xray版本
 * @return Xray版本字符串,失败返回nil
 */
- (nullable NSString *)getVersion;

/**
 * @brief 测试配置有效性
 * @param configJSON Xray配置JSON字符串
 * @return 配置有效返回YES,无效返回NO
 */
- (BOOL)testConfig:(NSString *)configJSON;

@end

NS_ASSUME_NONNULL_END
