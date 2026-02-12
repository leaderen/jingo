/**
 * @file JinGoXPCProtocol.h
 * @brief XPC Protocol for communication between main app and System Extension
 *
 * Since sendProviderMessage/handleAppMessage is unreliable for macOS System Extensions,
 * we use XPC for inter-process communication.
 *
 * @see https://developer.apple.com/forums/thread/110264
 */

#import <Foundation/Foundation.h>
#import "platform/apple/JinDoBundleHelper.h"

NS_ASSUME_NONNULL_BEGIN

// XPC Service name - 使用 JinDo 库从 plist 动态推导（兼容 Extension 进程）
#define kJinGoXPCServiceName (JinDo_AppGroupID())

/**
 * Protocol for the XPC service exposed by the System Extension
 */
@protocol JinGoXPCProtocol <NSObject>

/**
 * Get VPN statistics (traffic bytes, rates)
 * @param reply Callback with stats dictionary or nil on error
 */
- (void)getStatisticsWithReply:(void (^)(NSDictionary * _Nullable stats, NSError * _Nullable error))reply;

/**
 * Get delay/latency information
 * @param reply Callback with delay info dictionary or nil on error
 */
- (void)getDelayInfoWithReply:(void (^)(NSDictionary * _Nullable delayInfo, NSError * _Nullable error))reply;

/**
 * Get IP information (public IP, location)
 * @param reply Callback with IP info dictionary or nil on error
 */
- (void)getIPInfoWithReply:(void (^)(NSDictionary * _Nullable ipInfo, NSError * _Nullable error))reply;

/**
 * Trigger delay detection
 * @param reply Callback with success status
 */
- (void)triggerDelayDetectionWithReply:(void (^)(BOOL success, NSError * _Nullable error))reply;

/**
 * Trigger delay detection with server address
 * @param serverAddress VPN server address for TCP ping
 * @param serverPort VPN server port
 * @param reply Callback with success status
 *
 * @note Use this method after switching servers to update the delay detection target
 */
- (void)triggerDelayDetectionWithServerAddress:(NSString * _Nullable)serverAddress
                                    serverPort:(NSInteger)serverPort
                                         reply:(void (^)(BOOL success, NSError * _Nullable error))reply;

/**
 * Test server latency
 * @param address Server address (host:port)
 * @param timeout Timeout in milliseconds
 * @param reply Callback with latency in ms (-1 on failure)
 */
- (void)testServerLatency:(NSString *)address
                  timeout:(int)timeout
                withReply:(void (^)(int latency, NSError * _Nullable error))reply;

@end

NS_ASSUME_NONNULL_END
