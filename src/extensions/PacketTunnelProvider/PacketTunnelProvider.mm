/**
 * @file PacketTunnelProvider.mm
 * @brief JinGo VPN PacketTunnel Provider - Full implementation with SuperRay
 */

#import <NetworkExtension/NetworkExtension.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import "XrayExtensionBridge.h"

#if TARGET_OS_OSX
// XPC Protocol for macOS System Extension IPC
// sendProviderMessage is unreliable for System Extensions, use XPC instead
#import "JinGoXPCProtocol.h"
#endif
#include "superray.h"
#include <memory>
#include <thread>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#if TARGET_OS_OSX
// macOS-only kernel control headers
#include <sys/kern_control.h>
#include <sys/sys_domain.h>
#endif
#include <CFNetwork/CFHost.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include <atomic>
#if TARGET_OS_IOS
#include <mach/mach.h>  // for task_info memory monitoring
#endif

// App Group ID (must match main app)
static NSString * const kAppGroupIdentifier = @"group.cfd.jingo.acc";
static NSString * const kTUNDeviceTag = @"jingo-tun";

// 全局 packetFlow 引用，用于在 C 回调中写入数据包
// 注意：使用 strong 引用确保 packetFlow 在 VPN 运行期间不会被释放
static NEPacketTunnelFlow* g_packetFlow = nil;

// C 回调函数 - 接收来自 gVisor 的输出数据包并写入 NEPacketTunnelFlow
static void TUNPacketOutputCallback(const void* data, int dataLen, int family, void* userData) {
    // 首次回调日志
    static bool firstCallLogged = false;
    if (!firstCallLogged) {
        NSLog(@"[JinGoVPN] TUNPacketOutputCallback FIRST CALL! dataLen=%d, family=%d", dataLen, family);
        firstCallLogged = true;
    }

    if (!data || dataLen <= 0) {
        NSLog(@"[JinGoVPN] TUNPacketOutputCallback: invalid data (data=%p, len=%d)", data, dataLen);
        return;
    }

    if (!g_packetFlow) {
        NSLog(@"[JinGoVPN] TUNPacketOutputCallback: g_packetFlow is nil!");
        return;
    }

    // 前10个包都记录
    static std::atomic<int> outputLogCount(0);
    int currentCount = outputLogCount.fetch_add(1);
    if (currentCount < 10) {
        uint8_t* bytes = (uint8_t*)data;
        int version = bytes[0] >> 4;
        NSLog(@"[JinGoVPN] OUTPUT packet #%d: len=%d, family=%d, IP version=%d",
              currentCount, dataLen, family, version);
    }

    // 将数据复制到 NSData
    NSData* packet = [NSData dataWithBytes:data length:dataLen];

    // family: 2=AF_INET (IPv4), 30=AF_INET6 (IPv6) on Darwin
    // NEPacketTunnelFlow.writePackets 需要 protocol number
    NSNumber* proto = @(family);

    // 写入 packetFlow
    [g_packetFlow writePackets:@[packet] withProtocols:@[proto]];
}

// 异步日志队列和缓冲区
static dispatch_queue_t g_logQueue = nil;
static NSMutableArray<NSString *> *g_logBuffer = nil;
static const int LOG_BUFFER_SIZE = 20;  // 缓冲20条日志后批量写入
static dispatch_source_t g_logFlushTimer = nil;

// 前向声明
static void FlushLogBuffer(void);

// 初始化日志系统
static void InitLogSystem() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_logQueue = dispatch_queue_create("cfd.jingo.acc.extension.logging", DISPATCH_QUEUE_SERIAL);
        g_logBuffer = [NSMutableArray array];

        // 创建定时刷新器（每2秒刷新一次，即使缓冲区未满）
        g_logFlushTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, g_logQueue);
        dispatch_source_set_timer(g_logFlushTimer, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), 2 * NSEC_PER_SEC, 100 * NSEC_PER_MSEC);
        dispatch_source_set_event_handler(g_logFlushTimer, ^{
            if (g_logBuffer.count > 0) {
                FlushLogBuffer();
            }
        });
        dispatch_resume(g_logFlushTimer);
    });
}

// 刷新日志缓冲区到文件
static void FlushLogBuffer() {
    if (g_logBuffer.count == 0) return;

    NSArray *logsToWrite = [g_logBuffer copy];
    [g_logBuffer removeAllObjects];

    NSString *combinedLogs = [logsToWrite componentsJoinedByString:@""];

#if TARGET_OS_OSX
    // macOS: 写入用户 Library/Logs 目录
    NSString *homeDir = NSHomeDirectory();
    NSString *logDir = [homeDir stringByAppendingPathComponent:@"Library/Logs/JinGo"];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *logPath = [logDir stringByAppendingPathComponent:@"extension.log"];
    NSFileHandle *logHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (logHandle) {
        [logHandle seekToEndOfFile];
        [logHandle writeData:[combinedLogs dataUsingEncoding:NSUTF8StringEncoding]];
        [logHandle closeFile];
    } else {
        [combinedLogs writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
#endif

    // iOS 和 macOS 都尝试写入 App Group
    // iOS: App Group 是主要的日志存储位置
    // macOS: App Group 作为备用（System Extension 以 root 运行可能无法访问）
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    if (containerURL) {
        NSURL *logURL = [containerURL URLByAppendingPathComponent:@"extension.log"];
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[logURL path]];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[combinedLogs dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [combinedLogs writeToURL:logURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

// Helper function to write logs to stderr, NSLog, and file (async)
static void LogMessage(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // Log to NSLog (visible in Console.app) - 保持同步以便调试
    NSLog(@"[JinGoVPN] %@", message);

    // Log to stderr and force flush
    fprintf(stderr, "%s\n", [message UTF8String]);
    fflush(stderr);

    // 异步写入文件
    InitLogSystem();

    NSString *timestamp = [[NSDate date] description];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

    dispatch_async(g_logQueue, ^{
        [g_logBuffer addObject:logLine];

        // 缓冲区满时立即刷新
        if (g_logBuffer.count >= LOG_BUFFER_SIZE) {
            FlushLogBuffer();
        }
    });
}

// C-linkage wrapper for C++ code to call LogMessage
extern "C" void ExtensionLogMessageCStyle(const char* message) {
    LogMessage(@"%s", message);
}

// Get the primary network interface IP address (for multi-NIC environments)
// This returns the IP of the interface with the default route (not utun/vpn)
static NSString* getPrimaryInterfaceIP() {
    NSString *primaryIP = nil;

#if TARGET_OS_OSX
    // macOS: Get the primary service's interface using SystemConfiguration
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("JinGoVPN"), NULL, NULL);
    if (store) {
        CFStringRef key = SCDynamicStoreKeyCreateNetworkGlobalEntity(NULL, kSCDynamicStoreDomainState, kSCEntNetIPv4);
        CFDictionaryRef globalIPv4 = (CFDictionaryRef)SCDynamicStoreCopyValue(store, key);
        CFRelease(key);

        if (globalIPv4) {
            CFStringRef primaryInterface = (CFStringRef)CFDictionaryGetValue(globalIPv4, kSCDynamicStorePropNetPrimaryInterface);
            if (primaryInterface) {
                LogMessage(@"[Extension] Primary interface from SCDynamicStore: %@", (__bridge NSString *)primaryInterface);

                // Now get the IP address for this interface
                struct ifaddrs *interfaces = NULL;
                if (getifaddrs(&interfaces) == 0) {
                    struct ifaddrs *temp_addr = interfaces;
                    while (temp_addr != NULL) {
                        if (temp_addr->ifa_addr->sa_family == AF_INET) {
                            NSString *ifName = [NSString stringWithUTF8String:temp_addr->ifa_name];

                            // Match the primary interface name
                            if ([ifName isEqualToString:(__bridge NSString *)primaryInterface]) {
                                struct sockaddr_in *addr = (struct sockaddr_in *)temp_addr->ifa_addr;
                                char ipStr[INET_ADDRSTRLEN];
                                inet_ntop(AF_INET, &(addr->sin_addr), ipStr, INET_ADDRSTRLEN);
                                primaryIP = [NSString stringWithUTF8String:ipStr];
                                LogMessage(@"[Extension] Primary interface IP: %@ (%@)", primaryIP, ifName);
                                break;
                            }
                        }
                        temp_addr = temp_addr->ifa_next;
                    }
                    freeifaddrs(interfaces);
                }
            }
            CFRelease(globalIPv4);
        }
        CFRelease(store);
    }
#endif // TARGET_OS_OSX

    // Fallback (iOS) or secondary method (macOS): enumerate all interfaces
    if (!primaryIP) {
        LogMessage(@"[Extension] Using interface enumeration method");
        struct ifaddrs *interfaces = NULL;
        if (getifaddrs(&interfaces) == 0) {
            struct ifaddrs *temp_addr = interfaces;
            while (temp_addr != NULL) {
                if (temp_addr->ifa_addr->sa_family == AF_INET) {
                    NSString *ifName = [NSString stringWithUTF8String:temp_addr->ifa_name];

                    // Skip loopback, utun, and bridge interfaces
                    if (![ifName hasPrefix:@"lo"] &&
                        ![ifName hasPrefix:@"utun"] &&
                        ![ifName hasPrefix:@"bridge"] &&
                        ![ifName hasPrefix:@"awdl"] &&
                        ![ifName hasPrefix:@"llw"]) {

                        // Check if interface is up
                        if (temp_addr->ifa_flags & IFF_UP) {
                            struct sockaddr_in *addr = (struct sockaddr_in *)temp_addr->ifa_addr;
                            char ipStr[INET_ADDRSTRLEN];
                            inet_ntop(AF_INET, &(addr->sin_addr), ipStr, INET_ADDRSTRLEN);
                            NSString *ip = [NSString stringWithUTF8String:ipStr];

                            // Skip private VPN ranges (172.19.x.x is our TUN)
                            if (![ip hasPrefix:@"172.19."]) {
                                primaryIP = ip;
                                LogMessage(@"[Extension] Fallback: found interface IP: %@ (%@)", primaryIP, ifName);
                                break;
                            }
                        }
                    }
                }
                temp_addr = temp_addr->ifa_next;
            }
            freeifaddrs(interfaces);
        }
    }

    if (!primaryIP) {
        LogMessage(@"[Extension] Could not determine primary interface IP, using 0.0.0.0");
        primaryIP = @"0.0.0.0";
    }

    return primaryIP;
}

// Helper function to call SuperRay API and parse JSON response
static NSDictionary* callSuperRayAPI(char* (*apiFunc)(void)) {
    char* result = apiFunc();
    if (!result) {
        return nil;
    }

    NSString* jsonStr = [NSString stringWithUTF8String:result];
    SuperRay_Free(result);

    NSError* error = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&error];
    return dict;
}

static NSDictionary* callSuperRayAPIWithArg(char* (*apiFunc)(const char*), NSString* arg) {
    char* result = apiFunc([arg UTF8String]);
    if (!result) {
        return nil;
    }

    NSString* jsonStr = [NSString stringWithUTF8String:result];
    SuperRay_Free(result);

    NSError* error = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&error];
    return dict;
}

@interface JinGoPacketTunnelProvider : NEPacketTunnelProvider
#if TARGET_OS_OSX
    <NSXPCListenerDelegate, JinGoXPCProtocol>
#endif
{
    std::atomic<bool> _isRunning;
    dispatch_source_t _statsTimer;      // dispatch_source for reliable timer in Extension context
    dispatch_source_t _ipRefreshTimer;  // dispatch_source for IP/delay periodic refresh
    NSString* _xrayInstanceID;

    // SuperRay 统计缓存（查询失败时返回缓存值，不返回0）
    uint64_t _cachedUploadBytes;
    uint64_t _cachedDownloadBytes;
    double _cachedUploadRate;
    double _cachedDownloadRate;
    BOOL _tunDeviceCreated;
    BOOL _hasSocks5Inbound;             // 是否有 SOCKS5 inbound（代理模式 vs TUN 模式）
    NSInteger _socksPort;               // SOCKS5 代理端口（从 providerConfiguration 获取）

    // Test settings (from providerConfiguration or handleAppMessage)
    NSInteger _testLatencyMethod;       // 0=TCP, 1=HTTP
    NSString* _testURL;
    NSInteger _testTimeout;

    // Server address (for TCP ping delay detection)
    NSString* _serverAddress;           // 当前连接的 VPN 服务器地址
    NSInteger _serverPort;              // 当前连接的 VPN 服务器端口

    // DNS settings (from providerConfiguration)
    NSArray<NSString *>* _dnsServers;        // VPN 使用的 DNS 服务器列表
    NSArray<NSString *>* _directDnsServers;  // 直连 DNS 服务器（需要排除在路由之外）

    // Cached detection results (for handleAppMessage queries)
    NSDictionary* _lastIPInfo;
    NSDictionary* _lastDelayInfo;

    // Detection status tracking (for smart retry and avoiding duplicate detection)
    BOOL _ipDetectionInProgress;
    BOOL _delayDetectionInProgress;
    NSInteger _ipDetectionRetryCount;
    NSInteger _delayDetectionRetryCount;
    NSTimeInterval _lastIPDetectionTime;
    NSTimeInterval _lastDelayDetectionTime;

#if TARGET_OS_IOS
    // Memory monitoring timer for iOS (debug)
    dispatch_source_t _memoryMonitorTimer;
    NSInteger _memoryLogCount;
#endif

#if TARGET_OS_OSX
    // XPC listener for macOS System Extension IPC
    NSXPCListener* _xpcListener;
#endif
}
@end

@implementation JinGoPacketTunnelProvider

// ============================================================================
// MARK: - Memory Optimization State
// ============================================================================
// 注意: 不要使用 +load 方法！
// +load 在类加载时运行，此时 Go runtime 可能还未初始化
// 任何 Go 调用都会导致 Extension 立即崩溃

#if TARGET_OS_IOS
static BOOL sMemoryOptimizationApplied = NO;
#endif

// ============================================================================
// MARK: - Initialization
// ============================================================================

- (instancetype)init {
    // 从 Info.plist 获取版本号
    NSBundle *extensionBundle = [NSBundle bundleForClass:[self class]];
    NSString *bundleVersion = [extensionBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown";
    NSString *buildNumber = [extensionBundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"0";
    NSString *versionString = [NSString stringWithFormat:@"%@.%@", bundleVersion, buildNumber];

    // 立即写入日志以便调试
    NSString *initLog = [NSString stringWithFormat:@"[%@] [Extension] init called - VERSION %@\n", [NSDate date], versionString];
#if TARGET_OS_OSX
    // macOS: 写入用户 Library/Logs 目录
    NSString *homeDir = NSHomeDirectory();
    NSString *logDir = [homeDir stringByAppendingPathComponent:@"Library/Logs/JinGo"];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *initLogPath = [logDir stringByAppendingPathComponent:@"extension.log"];
    [initLog writeToFile:initLogPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
#endif
    // iOS: 使用 NSLog 和 App Group（稍后在 init 完成后写入）
    NSLog(@"%@", initLog);

    LogMessage([NSString stringWithFormat:@"[Extension] init called - VERSION %@ (SuperRay mode)", versionString]);
    self = [super init];
    if (self) {
        _isRunning = false;
        _statsTimer = nil;
        _hasSocks5Inbound = NO;  // 默认 TUN 模式，无 SOCKS5 inbound
        _socksPort = 10808;      // 默认 SOCKS5 端口
        _ipRefreshTimer = nil;
        _xrayInstanceID = nil;
        // SuperRay 统计缓存初始化
        _cachedUploadBytes = 0;
        _cachedDownloadBytes = 0;
        _cachedUploadRate = 0;
        _cachedDownloadRate = 0;
        _tunDeviceCreated = NO;

        // Initialize test settings with defaults
        _testLatencyMethod = 0;  // TCP
        _testURL = @"https://www.google.com/generate_204";
        _testTimeout = 10;
        _serverAddress = nil;
        _serverPort = 443;
        _lastIPInfo = nil;
        _lastDelayInfo = nil;

        // Initialize detection status
        _ipDetectionInProgress = NO;
        _delayDetectionInProgress = NO;
        _ipDetectionRetryCount = 0;
        _delayDetectionRetryCount = 0;
        _lastIPDetectionTime = 0;
        _lastDelayDetectionTime = 0;

        // Initialize DNS settings with defaults
        // 【重要】TUN 模式下必须使用直连 DNS 服务器，因为：
        // 1. Xray 路由将 8.8.8.8/1.1.1.1 等配置为走代理
        // 2. 但代理服务器域名需要先被 DNS 解析
        // 3. 如果 DNS 也走代理，会形成死锁
        // 所以这里使用国内直连 DNS，这些 DNS 服务器会被排除在 VPN 路由之外
        _dnsServers = @[@"223.5.5.5", @"223.6.6.6", @"119.29.29.29"];
        // 默认直连 DNS（需要排除在路由之外，用于解析代理服务器域名）
        _directDnsServers = @[
            @"223.5.5.5",      // 阿里 DNS
            @"223.6.6.6",      // 阿里 DNS
            @"119.29.29.29",   // DNSPod
            @"119.28.28.28",   // DNSPod
            @"114.114.114.114" // 114 DNS
        ];

        // 诊断日志：检测编译时目标平台
        NSLog(@"[Extension] Build platform check:");
#if TARGET_OS_IOS
        NSLog(@"[Extension]   TARGET_OS_IOS = 1 (iOS build)");
#else
        NSLog(@"[Extension]   TARGET_OS_IOS = 0 (NOT iOS build)");
#endif
#if TARGET_OS_OSX
        NSLog(@"[Extension]   TARGET_OS_OSX = 1 (macOS build)");
#else
        NSLog(@"[Extension]   TARGET_OS_OSX = 0 (NOT macOS build)");
#endif

#if TARGET_OS_IOS
        // iOS memory optimization should have been applied by constructor in main.m
        // or by +load method above. Just verify and log status here.
        NSLog(@"[Extension] init: Verifying iOS memory optimization status...");
        LogMessage(@"[Extension] init: Memory optimization should already be applied");

        // Get current memory stats to verify optimization is in effect
        char* memStats = SuperRay_GetMemoryStats();
        if (memStats) {
            NSLog(@"[Extension] init: Current memory stats: %s", memStats);
            LogMessage(@"[Extension] init: Memory stats: %s", memStats);
            SuperRay_Free(memStats);
        } else {
            NSLog(@"[Extension] init: WARNING - Could not get memory stats");
        }
#else
        NSLog(@"[Extension] Skipping iOS memory optimization (not iOS target)");
#endif

#if TARGET_OS_OSX
        // 初始化 XPC 监听器用于 macOS System Extension IPC
        // 注意: NSXPCListener initWithMachServiceName 在 System Extension 中可能不可用
        // 用 @try-@catch 保护，失败时回退到 App Group 文件通信
        @try {
            LogMessage(@"[Extension] Initializing XPC listener for System Extension IPC...");
            _xpcListener = [[NSXPCListener alloc] initWithMachServiceName:kJinGoXPCServiceName];
            if (_xpcListener) {
                _xpcListener.delegate = self;
                [_xpcListener resume];
                LogMessage(@"[Extension] XPC listener started on service: %@", kJinGoXPCServiceName);
            } else {
                LogMessage(@"[Extension] XPC listener creation returned nil, falling back to App Group IPC");
            }
        } @catch (NSException *exception) {
            LogMessage(@"[Extension] XPC listener init FAILED: %@, reason: %@", exception.name, exception.reason);
            LogMessage(@"[Extension] Falling back to App Group file-based IPC");
            _xpcListener = nil;
        }
#endif
    }
    return self;
}

- (void)dealloc {
    LogMessage(@"[Extension] dealloc called");

    // Stop stats timer (dispatch_source)
    if (_statsTimer) {
        dispatch_source_cancel(_statsTimer);
        _statsTimer = nil;
    }

    // Stop IP refresh timer (dispatch_source)
    if (_ipRefreshTimer) {
        dispatch_source_cancel(_ipRefreshTimer);
        _ipRefreshTimer = nil;
    }

#if TARGET_OS_OSX
    // Stop XPC listener
    if (_xpcListener) {
        [_xpcListener invalidate];
        _xpcListener = nil;
    }
#endif

    [self stopSuperRay];
}

// ============================================================================
// MARK: - IP Detection (for main app to read)
// ============================================================================

// 智能 IP 检测：带防重复、自动重试机制
- (void)detectAndSaveIPInfoWithRetry {
    // 检查是否已有有效数据
    if (_lastIPInfo && !_lastIPInfo[@"error"] && _lastIPInfo[@"ip"] && [_lastIPInfo[@"ip"] length] > 0) {
        LogMessage(@"[Extension] IP already detected: %@, skipping", _lastIPInfo[@"ip"]);
        return;
    }

    // 检查是否正在检测
    if (_ipDetectionInProgress) {
        LogMessage(@"[Extension] IP detection already in progress, skipping");
        return;
    }

    // 检查重试次数
    if (_ipDetectionRetryCount >= 5) {
        LogMessage(@"[Extension] IP detection max retries (5) reached, giving up");
        return;
    }

    // 防止过于频繁的检测（最小间隔 3 秒）
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - _lastIPDetectionTime < 3.0) {
        LogMessage(@"[Extension] IP detection too frequent, scheduling retry in 3s");
        __weak JinGoPacketTunnelProvider *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [weakSelf detectAndSaveIPInfoWithRetry];
        });
        return;
    }

    _ipDetectionInProgress = YES;
    _ipDetectionRetryCount++;
    _lastIPDetectionTime = now;

    LogMessage(@"[Extension] Starting IP detection (attempt %ld/5) via SOCKS5 proxy (port=%ld)...",
               (long)_ipDetectionRetryCount, (long)_socksPort);

    [self performIPDetection];
}

// 执行实际的 IP 检测
- (void)performIPDetection {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = 8.0;  // 缩短超时时间

    // 始终使用 SOCKS5 代理发送请求
    NSDictionary *proxyDict = @{
        (NSString *)kCFStreamPropertySOCKSProxyHost: @"127.0.0.1",
        (NSString *)kCFStreamPropertySOCKSProxyPort: @(_socksPort),
        (NSString *)kCFStreamPropertySOCKSVersion: (NSString *)kCFStreamSocketSOCKSVersion5
    };
    config.connectionProxyDictionary = proxyDict;

    NSURL *url = [NSURL URLWithString:@"https://ipinfo.io/json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:8.0];
    [request setValue:@"JinGo VPN/1.0" forHTTPHeaderField:@"User-Agent"];

    __weak JinGoPacketTunnelProvider *weakSelf = self;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            JinGoPacketTunnelProvider *strongSelf = weakSelf;
            if (!strongSelf) return;

            strongSelf->_ipDetectionInProgress = NO;
            NSMutableDictionary *ipInfo = [NSMutableDictionary dictionary];
            ipInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
            BOOL success = NO;

            if (error) {
                LogMessage(@"[Extension] IP detection failed (attempt %ld): %@",
                           (long)strongSelf->_ipDetectionRetryCount, error.localizedDescription);
                ipInfo[@"error"] = error.localizedDescription;
            } else if (data) {
                NSError *jsonError = nil;
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                if (json) {
                    NSString *ip = json[@"ip"];
                    NSString *org = json[@"org"];
                    NSString *country = json[@"country"];

                    if (ip.length > 0) {
                        ipInfo[@"ip"] = ip;
                        ipInfo[@"country"] = country ?: @"";

                        NSString *asn = @"";
                        NSString *isp = @"";
                        if (org.length > 0) {
                            NSRange spaceRange = [org rangeOfString:@" "];
                            if (spaceRange.location != NSNotFound) {
                                asn = [org substringToIndex:spaceRange.location];
                                isp = [org substringFromIndex:spaceRange.location + 1];
                            } else {
                                asn = org;
                            }
                        }
                        ipInfo[@"asn"] = asn;
                        ipInfo[@"isp"] = isp;

                        NSMutableArray *parts = [NSMutableArray array];
                        if (asn.length > 0) [parts addObject:asn];
                        if (isp.length > 0) [parts addObject:isp];
                        if (country.length > 0) [parts addObject:country];
                        ipInfo[@"ipInfoDisplay"] = [parts componentsJoinedByString:@" | "];

                        success = YES;
                        strongSelf->_ipDetectionRetryCount = 0;  // 重置重试计数
                        LogMessage(@"[Extension] IP detected SUCCESS: %@ (%@)", ip, ipInfo[@"ipInfoDisplay"]);
                    } else {
                        ipInfo[@"error"] = @"Empty IP in response";
                    }
                } else {
                    LogMessage(@"[Extension] IP detection JSON parse error: %@", jsonError);
                    ipInfo[@"error"] = @"JSON parse error";
                }
            }

            [strongSelf saveIPInfoToSharedContainer:ipInfo];

            // 检测完成后触发延迟检测
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf detectAndSaveDelayWithRetry];
            });

            // 如果失败且还有重试次数，安排重试
            if (!success && strongSelf->_ipDetectionRetryCount < 5 && strongSelf->_isRunning) {
                NSInteger retryDelay = 3 + strongSelf->_ipDetectionRetryCount * 2;  // 3, 5, 7, 9, 11 秒
                LogMessage(@"[Extension] Scheduling IP detection retry in %lds", (long)retryDelay);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryDelay * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [strongSelf detectAndSaveIPInfoWithRetry];
                });
            }
        }];
    [task resume];
}

// 兼容旧接口
- (void)detectAndSaveIPInfo {
    [self detectAndSaveIPInfoWithRetry];
}

// 保存 IP 信息到实例变量（供 handleAppMessage 查询）
- (void)saveIPInfoToSharedContainer:(NSDictionary *)ipInfo {
    _lastIPInfo = [ipInfo copy];
    LogMessage(@"[Extension] IP info saved: %@", ipInfo[@"ip"]);
}

// ============================================================================
// MARK: - Delay Testing (for main app to read)
// ============================================================================

// 智能延迟检测：带防重复、自动重试机制
- (void)detectAndSaveDelayWithRetry {
    // 检查是否已有有效数据
    if (_lastDelayInfo && [_lastDelayInfo[@"delay"] intValue] > 0) {
        LogMessage(@"[Extension] Delay already detected: %@ms, skipping", _lastDelayInfo[@"delay"]);
        return;
    }

    // 检查是否正在检测
    if (_delayDetectionInProgress) {
        LogMessage(@"[Extension] Delay detection already in progress, skipping");
        return;
    }

    // 检查重试次数
    if (_delayDetectionRetryCount >= 5) {
        LogMessage(@"[Extension] Delay detection max retries (5) reached, giving up");
        return;
    }

    // 防止过于频繁的检测（最小间隔 2 秒）
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - _lastDelayDetectionTime < 2.0) {
        LogMessage(@"[Extension] Delay detection too frequent, scheduling retry in 2s");
        __weak JinGoPacketTunnelProvider *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [weakSelf detectAndSaveDelayWithRetry];
        });
        return;
    }

    _delayDetectionInProgress = YES;
    _delayDetectionRetryCount++;
    _lastDelayDetectionTime = now;

    LogMessage(@"[Extension] Starting delay detection (attempt %ld/5)...",
               (long)_delayDetectionRetryCount);

    [self performDelayDetection];
}

// 执行实际的延迟检测
- (void)performDelayDetection {
    NSInteger latencyMethod = _testLatencyMethod;
    NSString *testURL = _testURL;
    NSInteger timeout = _testTimeout;
    int timeoutMs = (int)(timeout * 1000);

    // TCP 模式：直接 ping VPN 服务器（测试到服务器的网络延迟）
    // HTTP 模式：通过 SOCKS5 代理 ping 测试 URL（测试通过 VPN 访问外网的延迟）
    BOOL useTCP = (latencyMethod == 0);

    // 如果是 TCP 模式但没有服务器地址，则回退到 HTTP 模式
    if (useTCP && (!_serverAddress || _serverAddress.length == 0)) {
        LogMessage(@"[Extension] TCP mode but no server address, falling back to HTTP mode");
        useTCP = NO;
    }

    LogMessage(@"[Extension] Delay detection: method=%@, server=%@:%ld, URL=%@, timeout=%dms",
               useTCP ? @"TCP" : @"HTTP",
               _serverAddress ?: @"(none)", (long)_serverPort,
               testURL, timeoutMs);

    __weak JinGoPacketTunnelProvider *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        JinGoPacketTunnelProvider *strongSelf = weakSelf;
        if (!strongSelf) return;

        int delay = -1;
        NSString *target = @"";
        BOOL success = NO;

        if (useTCP) {
            // TCP 模式：直接 ping VPN 服务器地址
            // 这测试的是本机到 VPN 服务器的网络延迟（不经过代理）
            target = [NSString stringWithFormat:@"%@:%ld", strongSelf->_serverAddress, (long)strongSelf->_serverPort];
            char *result = SuperRay_Ping([target UTF8String], timeoutMs);
            if (result) {
                NSString *jsonStr = [NSString stringWithUTF8String:result];
                NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                if ([json[@"success"] boolValue]) {
                    delay = [json[@"data"][@"latency_ms"] intValue];
                    if (delay > 0) success = YES;
                }
                SuperRay_Free(result);
            }
            LogMessage(@"[Extension] TCP ping to %@ result: %dms (success=%d)", target, delay, success);
        } else {
            // HTTP 模式：通过 SOCKS5 代理测试
            // 这测试的是通过 VPN 服务器访问外网的延迟
            target = testURL;
            NSString *proxyAddr = [NSString stringWithFormat:@"127.0.0.1:%ld", (long)strongSelf->_socksPort];
            char *result = SuperRay_HTTPPing([testURL UTF8String], [proxyAddr UTF8String], timeoutMs);
            if (result) {
                NSString *jsonStr = [NSString stringWithUTF8String:result];
                NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                if ([json[@"success"] boolValue]) {
                    delay = [json[@"data"][@"latency_ms"] intValue];
                    if (delay > 0) success = YES;
                }
                SuperRay_Free(result);
            }
            LogMessage(@"[Extension] HTTP ping via SOCKS5 result: %dms (success=%d)", delay, success);
        }

        // 保存方法名称（在主线程 block 中使用）
        NSString *methodName = useTCP ? @"TCP" : @"HTTP";

        // 更新状态
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf->_delayDetectionInProgress = NO;

            if (success) {
                strongSelf->_delayDetectionRetryCount = 0;  // 重置重试计数
            }

            // 保存结果
            NSMutableDictionary *delayInfo = [NSMutableDictionary dictionary];
            delayInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
            delayInfo[@"delay"] = @(delay);
            delayInfo[@"target"] = target;
            delayInfo[@"method"] = methodName;
            strongSelf->_lastDelayInfo = [delayInfo copy];

            LogMessage(@"[Extension] Delay info saved: %dms, method=%@, target=%@ (attempt %ld)",
                       delay, methodName, target, (long)strongSelf->_delayDetectionRetryCount);

            // 如果失败且还有重试次数，安排重试
            if (!success && strongSelf->_delayDetectionRetryCount < 5 && strongSelf->_isRunning) {
                NSInteger retryDelay = 2 + strongSelf->_delayDetectionRetryCount;  // 2, 3, 4, 5, 6 秒
                LogMessage(@"[Extension] Scheduling delay detection retry in %lds", (long)retryDelay);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryDelay * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [strongSelf detectAndSaveDelayWithRetry];
                });
            }
        });
    });
}

// 兼容旧接口
- (void)detectAndSaveDelay {
    [self detectAndSaveDelayWithRetry];
}

// ============================================================================
// MARK: - VPN Configuration
// ============================================================================

- (NEPacketTunnelNetworkSettings *)createTunnelSettingsWithServerAddresses:(NSArray<NSString *> *)serverAddresses {
    // Create tunnel settings with remote address
    // Use 198.18.0.0/15 range (TEST-NET-1, reserved for benchmark testing)
    // This avoids conflicts with RFC1918 private address ranges
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc]
        initWithTunnelRemoteAddress:@"198.18.0.1"];

    // Configure IPv4 settings
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc]
        initWithAddresses:@[@"198.18.0.2"]
        subnetMasks:@[@"255.255.255.252"]];

    // Include all routes through VPN (0.0.0.0/0)
    NEIPv4Route *defaultRoute = [NEIPv4Route defaultRoute];
    ipv4Settings.includedRoutes = @[defaultRoute];

    // Build excluded routes list to avoid routing loops
    NSMutableArray<NEIPv4Route *> *excludedRoutes = [NSMutableArray array];

    // Note: 127.0.0.0/8 (loopback) is automatically excluded by the system
    // Adding it to excludedRoutes causes error: "IPv4Route Destination address is loopback"

    // 1. Private address ranges (RFC 1918) - local LAN doesn't go through VPN
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"10.0.0.0" subnetMask:@"255.0.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"172.16.0.0" subnetMask:@"255.240.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"192.168.0.0" subnetMask:@"255.255.0.0"]];

    // 2. Reserved/special address ranges
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"169.254.0.0" subnetMask:@"255.255.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"224.0.0.0" subnetMask:@"240.0.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"240.0.0.0" subnetMask:@"240.0.0.0"]];
    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@"255.255.255.255" subnetMask:@"255.255.255.255"]];

    // 2.5 Direct DNS servers (CRITICAL - Xray uses these to resolve proxy server domain!)
    // Without excluding these, DNS queries for proxy server domain will be routed through VPN,
    // creating a deadlock (VPN needs DNS, DNS needs VPN)
    // 使用配置的直连 DNS 服务器列表
    if (_directDnsServers && _directDnsServers.count > 0) {
        for (NSString *dnsServer in _directDnsServers) {
            if (dnsServer && dnsServer.length > 0) {
                struct in_addr addr;
                if (inet_pton(AF_INET, [dnsServer UTF8String], &addr) == 1) {
                    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:dnsServer subnetMask:@"255.255.255.255"]];
                    LogMessage(@"[Extension] Added direct DNS server to excluded routes: %@", dnsServer);
                }
            }
        }
    }
    LogMessage(@"[Extension] Added %lu direct DNS servers to excluded routes", (unsigned long)_directDnsServers.count);

    // 3. Proxy server addresses (CRITICAL - must exclude to avoid routing loop!)
    if (serverAddresses && serverAddresses.count > 0) {
        for (NSString *serverAddress in serverAddresses) {
            if (!serverAddress || serverAddress.length == 0) continue;

            struct in_addr addr;
            if (inet_pton(AF_INET, [serverAddress UTF8String], &addr) == 1) {
                // Already an IP address
                [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:serverAddress subnetMask:@"255.255.255.255"]];
                LogMessage(@"[Extension] Added proxy server IP to excluded routes: %@", serverAddress);
            } else {
                // It's a domain name, resolve it
                LogMessage(@"[Extension] Resolving proxy server domain: %@", serverAddress);

                CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)serverAddress);
                if (hostRef) {
                    CFStreamError error;
                    if (CFHostStartInfoResolution(hostRef, kCFHostAddresses, &error)) {
                        Boolean hasBeenResolved;
                        CFArrayRef addresses = CFHostGetAddressing(hostRef, &hasBeenResolved);
                        if (hasBeenResolved && addresses && CFArrayGetCount(addresses) > 0) {
                            for (CFIndex i = 0; i < CFArrayGetCount(addresses); i++) {
                                NSData *addressData = (__bridge NSData *)CFArrayGetValueAtIndex(addresses, i);
                                struct sockaddr_in *sockaddr = (struct sockaddr_in *)[addressData bytes];
                                if (sockaddr->sin_family == AF_INET) {
                                    char ipStr[INET_ADDRSTRLEN];
                                    inet_ntop(AF_INET, &(sockaddr->sin_addr), ipStr, INET_ADDRSTRLEN);
                                    NSString *resolvedIP = [NSString stringWithUTF8String:ipStr];
                                    [excludedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:resolvedIP subnetMask:@"255.255.255.255"]];
                                    LogMessage(@"[Extension] Added resolved proxy server IP to excluded routes: %@ -> %@", serverAddress, resolvedIP);
                                }
                            }
                        } else {
                            LogMessage(@"[Extension] WARNING: Failed to resolve proxy server domain: %@", serverAddress);
                        }
                    } else {
                        LogMessage(@"[Extension] WARNING: DNS resolution failed for: %@ (error: %ld)", serverAddress, (long)error.error);
                    }
                    CFRelease(hostRef);
                } else {
                    LogMessage(@"[Extension] WARNING: Failed to create host reference for: %@", serverAddress);
                }
            }
        }
    } else {
        LogMessage(@"[Extension] WARNING: No server addresses to exclude - routing loop may occur!");
    }

    ipv4Settings.excludedRoutes = [excludedRoutes copy];

    LogMessage(@"[Extension] Configured %lu excluded routes", (unsigned long)excludedRoutes.count);

    settings.IPv4Settings = ipv4Settings;

    // Configure DNS settings (使用配置的 DNS 服务器)
    NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:_dnsServers];
    // CRITICAL: Set matchDomains to empty array to match ALL domains
    // Without this, DNS queries may not go through the VPN tunnel
    dnsSettings.matchDomains = @[@""];
    settings.DNSSettings = dnsSettings;
    LogMessage(@"[Extension] DNS settings configured with servers: %@", _dnsServers);

    // Set MTU - use standard MTU for iOS compatibility
    settings.MTU = @1500;

    return settings;
}

// ============================================================================
// MARK: - SuperRay Management
// ============================================================================

- (BOOL)startSuperRayWithConfig:(NSString *)xrayConfigJSON error:(NSError **)error {
    LogMessage(@"[Extension] Starting SuperRay with config length: %lu", (unsigned long)xrayConfigJSON.length);
    LogMessage(@"[Extension] DEBUG A: Before file manager init");

    // 设置 SuperRay 调试日志路径（写入 App Group 容器）
    NSFileManager *fm = [NSFileManager defaultManager];
    LogMessage(@"[Extension] DEBUG B: File manager created");
    NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    LogMessage(@"[Extension] DEBUG C: Container URL: %@", containerURL ? @"valid" : @"nil");
    // SKIP SuperRay_SetDebugLogPath - it blocks due to Go runtime issue on Apple platforms
    LogMessage(@"[Extension] Skipping SuperRay_SetDebugLogPath (blocks Go runtime)");

    // 设置 geo 资源文件目录（geoip.dat, geosite.dat）
    // iOS Extension 无法访问主应用的 bundle，需要从 App Group 共享容器读取
    NSString *datPath = nil;

    // 1. 首先尝试 App Group 共享容器
    if (containerURL) {
        NSString *sharedDatPath = [[containerURL path] stringByAppendingPathComponent:@"dat"];
        NSString *geoipPath = [sharedDatPath stringByAppendingPathComponent:@"geoip.dat"];
        if ([fm fileExistsAtPath:geoipPath]) {
            datPath = sharedDatPath;
            LogMessage(@"[Extension] Found geo files in App Group container: %@", datPath);
        }
    }

    // 2. 如果共享容器没有，尝试 Extension 自己的 bundle
    if (!datPath) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *bundleDatPath = [[bundle resourcePath] stringByAppendingPathComponent:@"dat"];
        NSString *bundleGeoipPath = [bundleDatPath stringByAppendingPathComponent:@"geoip.dat"];
        if ([fm fileExistsAtPath:bundleGeoipPath]) {
            datPath = bundleDatPath;
            LogMessage(@"[Extension] Found geo files in extension bundle: %@", datPath);
        } else {
            // 也尝试 bundle 根目录（iOS 主应用结构）
            NSString *rootGeoipPath = [[bundle resourcePath] stringByAppendingPathComponent:@"geoip.dat"];
            if ([fm fileExistsAtPath:rootGeoipPath]) {
                datPath = [bundle resourcePath];
                LogMessage(@"[Extension] Found geo files in bundle root: %@", datPath);
            }
        }
    }

    // 3. 如果都找不到，使用默认路径（可能失败）
    if (!datPath) {
        datPath = [[NSBundle mainBundle] resourcePath];
        LogMessage(@"[Extension] WARNING: geo files not found, using default path: %@", datPath);
    }

    LogMessage(@"[Extension] DEBUG G: Setting asset directory: %@", datPath);
    char* assetResult = SuperRay_SetAssetDir([datPath UTF8String]);
    LogMessage(@"[Extension] DEBUG H: SuperRay_SetAssetDir returned");
    if (assetResult) {
        LogMessage(@"[Extension] SuperRay_SetAssetDir result: %s", assetResult);
        SuperRay_Free(assetResult);
    }
    LogMessage(@"[Extension] DEBUG I: About to parse JSON config");

    // TUN 模式：移除所有 inbounds 以节省内存
    // Callback TUN 用于实际流量路由，不需要 SOCKS5/HTTP inbound
    NSString *tunModeConfig = xrayConfigJSON;
    NSError *jsonError = nil;
    NSMutableDictionary *configDict = [NSJSONSerialization JSONObjectWithData:[xrayConfigJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&jsonError];
    if (configDict && !jsonError) {
        // TUN 模式：保留测试用的 SOCKS5 inbound（用于 IP 检测、延时测试、速度测试等）
        // 移除其他 inbounds 以节省内存
        NSArray *originalInbounds = configDict[@"inbounds"];
        NSMutableArray *testInbounds = [NSMutableArray array];
        _hasSocks5Inbound = NO;

        if ([originalInbounds isKindOfClass:[NSArray class]]) {
            for (NSDictionary *inbound in originalInbounds) {
                NSString *protocol = inbound[@"protocol"];
                NSNumber *port = inbound[@"port"];

                // 保留配置端口的 SOCKS5 inbound（测试用）
                if ([protocol isEqualToString:@"socks"] && [port integerValue] == _socksPort) {
                    [testInbounds addObject:inbound];
                    _hasSocks5Inbound = YES;
                    LogMessage(@"[Extension] Kept SOCKS5 inbound on port %ld for testing", (long)_socksPort);
                }
            }
        }

        // 如果原配置没有指定端口的 SOCKS5，创建一个
        if (!_hasSocks5Inbound) {
            NSDictionary *testSocksInbound = @{
                @"tag": @"socks-test",
                @"port": @(_socksPort),
                @"listen": @"127.0.0.1",
                @"protocol": @"socks",
                @"settings": @{
                    @"auth": @"noauth",
                    @"udp": @YES
                },
                @"sniffing": @{
                    @"enabled": @YES,
                    @"destOverride": @[@"http", @"tls"]
                }
            };
            [testInbounds addObject:testSocksInbound];
            _hasSocks5Inbound = YES;
            LogMessage(@"[Extension] Created SOCKS5 inbound on port %ld for testing", (long)_socksPort);
        }

        configDict[@"inbounds"] = testInbounds;
        LogMessage(@"[Extension] TUN mode: Kept %lu test inbound(s), socksPort=%ld", (unsigned long)testInbounds.count, (long)_socksPort);

        // 强制更新 Xray 日志路径为 Extension 可写入的目录
        // 无论原配置是否有 log 配置，都需要确保使用正确的路径
        {
            NSMutableDictionary *logDict = [NSMutableDictionary dictionary];
            NSString *logDir = nil;

#if TARGET_OS_OSX
            // macOS: 使用用户 Library/Logs/JinGo 目录
            NSString *homeDir = NSHomeDirectory();
            logDir = [homeDir stringByAppendingPathComponent:@"Library/Logs/JinGo/xray"];
#else
            // iOS: 使用沙盒临时目录
            logDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"xray_logs"];
#endif

            // 创建日志目录
            [[NSFileManager defaultManager] createDirectoryAtPath:logDir
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];

            logDict[@"access"] = [logDir stringByAppendingPathComponent:@"access.log"];
            logDict[@"error"] = [logDir stringByAppendingPathComponent:@"error.log"];
            logDict[@"loglevel"] = @"warning";

            configDict[@"log"] = logDict;
            LogMessage(@"[Extension] Updated Xray log config to: %@", logDir);
        }

        NSData *updatedData = [NSJSONSerialization dataWithJSONObject:configDict options:0 error:nil];
        if (updatedData) {
            tunModeConfig = [[NSString alloc] initWithData:updatedData encoding:NSUTF8StringEncoding];
        }
    }

    LogMessage(@"[Extension] TUN mode config length: %lu", (unsigned long)tunModeConfig.length);

    // Use SuperRay_Run to start Xray directly
    LogMessage(@"[Extension] >>> About to call SuperRay_Run...");
    LogMessage(@"[Extension] >>> Memory before call: %llu bytes free", [NSProcessInfo processInfo].physicalMemory);

#if TARGET_OS_IOS
    // 在启动 Xray 前强制 GC，为 gVisor netstack 初始化腾出内存
    NSLog(@"[Extension] >>> [iOS] Forcing GC before SuperRay_Run to free memory...");
    LogMessage(@"[Extension] >>> Forcing GC before SuperRay_Run to free memory...");
    char* gcResult = SuperRay_ForceGC();
    if (gcResult) {
        NSLog(@"[Extension] >>> [iOS] GC result: %s", gcResult);
        LogMessage(@"[Extension] >>> GC result: %s", gcResult);
        SuperRay_Free(gcResult);
    }

    // 获取当前内存使用情况
    char* memStats = SuperRay_GetMemoryStats();
    if (memStats) {
        NSLog(@"[Extension] >>> [iOS] Memory stats before SuperRay_Run: %s", memStats);
        LogMessage(@"[Extension] >>> Memory stats: %s", memStats);
        SuperRay_Free(memStats);
    }
#else
    NSLog(@"[Extension] >>> Skipping iOS pre-run GC (not iOS target)");
#endif

    // 在后台线程调用 SuperRay_Run 以避免阻塞主线程
    __block char* result = nil;
    __block BOOL callCompleted = NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        LogMessage(@"[Extension] >>> SuperRay_Run starting on background thread...");
        result = SuperRay_Run([tunModeConfig UTF8String]);
        LogMessage(@"[Extension] >>> SuperRay_Run completed on background thread");
        callCompleted = YES;
    });

    // 等待最多 25 秒
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:25.0];
    while (!callCompleted && [[NSDate date] compare:timeout] == NSOrderedAscending) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    if (!callCompleted) {
        LogMessage(@"[Extension] >>> SuperRay_Run TIMEOUT after 25 seconds!");
        if (error) {
            *error = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                         code:1099
                                     userInfo:@{NSLocalizedDescriptionKey: @"SuperRay_Run timeout (25s)"}];
        }
        return NO;
    }

    LogMessage(@"[Extension] <<< SuperRay_Run returned");

    if (!result) {
        LogMessage(@"[Extension] SuperRay_Run returned null");
        if (error) {
            *error = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                         code:1003
                                     userInfo:@{NSLocalizedDescriptionKey: @"SuperRay_Run returned null"}];
        }
        return NO;
    }

    NSString* jsonStr = [NSString stringWithUTF8String:result];
    SuperRay_Free(result);

    LogMessage(@"[Extension] SuperRay_Run response: %@", jsonStr);

    NSError* parseError = nil;
    NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:&parseError];

    if (parseError || !response) {
        LogMessage(@"[Extension] Failed to parse SuperRay response: %@", parseError);
        if (error) {
            *error = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                         code:1004
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse SuperRay response"}];
        }
        return NO;
    }

    BOOL success = [response[@"success"] boolValue];
    if (!success) {
        NSString* errorMsg = response[@"error"] ?: @"Unknown error";
        LogMessage(@"[Extension] SuperRay_Run failed: %@", errorMsg);
        if (error) {
            *error = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                         code:1005
                                     userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
        }
        return NO;
    }

    // Extract instance ID
    NSDictionary* data = response[@"data"];
    if (data && data[@"id"]) {
        _xrayInstanceID = data[@"id"];
        LogMessage(@"[Extension] SuperRay instance started with ID: %@", _xrayInstanceID);
    } else {
        LogMessage(@"[Extension] WARNING: SuperRay response has no instance ID! data=%@", data);
    }

    return YES;
}

- (BOOL)createTUNDeviceWithXrayInstance:(NSString*)instanceID {
    // Create Callback TUN device configuration for NEPacketTunnelFlow integration
    // Use same address range as NEPacketTunnelNetworkSettings (198.18.0.0/15)
    NSDictionary* tunConfig = @{
        @"tag": kTUNDeviceTag,
        @"addresses": @[@"198.18.0.2/30"],
        @"mtu": @1500  // Use standard MTU for iOS
    };

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:tunConfig options:0 error:nil];
    NSString* configJSON = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    LogMessage(@"[Extension] Creating Callback TUN with Dialer, instanceID: %@, outbound: proxy", instanceID);

    // 使用 CreateCallbackTUNWithDialer 绑定到 Xray 实例的 outbound
    // 这样 TUN 流量会直接通过 XrayDialer 调用 outbound handler，无需 SOCKS5 中转
    char* result = SuperRay_CreateCallbackTUNWithDialer(
        [configJSON UTF8String],
        [instanceID UTF8String],
        "proxy"  // 对应 Xray 配置中的 outbound tag
    );

    if (!result) {
        LogMessage(@"[Extension] SuperRay_CreateCallbackTUNWithDialer returned null");
        return NO;
    }

    NSString* jsonStr = [NSString stringWithUTF8String:result];
    SuperRay_Free(result);

    LogMessage(@"[Extension] Callback TUN creation response: %@", jsonStr);

    NSError* parseError = nil;
    NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:&parseError];

    if (parseError || !response) {
        LogMessage(@"[Extension] Failed to parse Callback TUN response");
        return NO;
    }

    BOOL success = [response[@"success"] boolValue];
    if (!success) {
        LogMessage(@"[Extension] Callback TUN creation failed: %@", response[@"error"]);
        return NO;
    }

    // 【重要】设置输出回调 - 接收来自 gVisor 的响应数据包
    LogMessage(@"[Extension] Setting packet output callback...");
    char* callbackResult = SuperRay_SetTUNPacketCallback(
        [kTUNDeviceTag UTF8String],
        (void*)TUNPacketOutputCallback,
        NULL
    );
    if (callbackResult) {
        NSString *callbackResultStr = [NSString stringWithUTF8String:callbackResult];
        LogMessage(@"[Extension] SetTUNPacketCallback result: %@", callbackResultStr);

        // 检查是否成功
        NSError *parseError = nil;
        NSDictionary *callbackResponse = [NSJSONSerialization JSONObjectWithData:[callbackResultStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:0
                                                                           error:&parseError];
        if (callbackResponse && ![callbackResponse[@"success"] boolValue]) {
            LogMessage(@"[Extension] ERROR: SetTUNPacketCallback failed: %@", callbackResponse[@"error"]);
            SuperRay_Free(callbackResult);
            return NO;
        }
        SuperRay_Free(callbackResult);
    } else {
        LogMessage(@"[Extension] WARNING: SetTUNPacketCallback returned null - output packets may not work!");
    }

    // 启动 Callback TUN 处理
    LogMessage(@"[Extension] Starting Callback TUN processing...");
    char* startResult = SuperRay_StartCallbackTUN([kTUNDeviceTag UTF8String]);
    if (startResult) {
        NSString *startResultStr = [NSString stringWithUTF8String:startResult];
        LogMessage(@"[Extension] Callback TUN start result: %@", startResultStr);

        // 检查是否成功
        NSError *parseError = nil;
        NSDictionary *startResponse = [NSJSONSerialization JSONObjectWithData:[startResultStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                      options:0
                                                                        error:&parseError];
        if (startResponse && ![startResponse[@"success"] boolValue]) {
            LogMessage(@"[Extension] ERROR: StartCallbackTUN failed: %@", startResponse[@"error"]);
            SuperRay_Free(startResult);
            return NO;
        }
        SuperRay_Free(startResult);
    } else {
        LogMessage(@"[Extension] WARNING: StartCallbackTUN returned null");
    }

    _tunDeviceCreated = YES;
    LogMessage(@"[Extension] Callback TUN device created and started successfully");
    return YES;
}

- (void)stopSuperRay {
    LogMessage(@"[Extension] Stopping SuperRay");

    // 清除缓存的 IP/延迟信息
    _lastIPInfo = nil;
    _lastDelayInfo = nil;

#if TARGET_OS_IOS
    // 停止周期性 GC
    char* gcResult = SuperRay_StopPeriodicGC();
    if (gcResult) {
        LogMessage(@"[Extension] Stopped periodic GC: %s", gcResult);
        SuperRay_Free(gcResult);
    }
#endif

    // 停止 Callback TUN 设备
    if (_tunDeviceCreated) {
        char* result = SuperRay_StopCallbackTUN([kTUNDeviceTag UTF8String]);
        if (result) {
            LogMessage(@"[Extension] Callback TUN stopped: %s", result);
            SuperRay_Free(result);
        }
        _tunDeviceCreated = NO;
    }

    // Stop all instances
    char* result = SuperRay_StopAll();
    if (result) {
        LogMessage(@"[Extension] SuperRay_StopAll: %s", result);
        SuperRay_Free(result);
    }

#if TARGET_OS_IOS
    char* mmapResult = SuperRay_CloseGeoMmap();
    if (mmapResult) {
        LogMessage(@"[Extension] SuperRay_CloseGeoMmap: %s", mmapResult);
        SuperRay_Free(mmapResult);
    }
#endif

    _xrayInstanceID = nil;
    _isRunning = false;
}

// ============================================================================
// MARK: - VPN Lifecycle
// ============================================================================

- (void)startTunnelWithOptions:(NSDictionary<NSString *,NSObject *> *)options
             completionHandler:(void (^)(NSError * _Nullable))completionHandler {

    // 立即写入日志
    NSString *startLog = [NSString stringWithFormat:@"[%@] [Extension] startTunnelWithOptions CALLED!\n", [NSDate date]];
    NSLog(@"%@", startLog);

#if TARGET_OS_OSX
    // macOS: 写入用户 Library/Logs 目录
    NSString *homeDir = NSHomeDirectory();
    NSString *logDir = [homeDir stringByAppendingPathComponent:@"Library/Logs/JinGo"];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *startLogPath = [logDir stringByAppendingPathComponent:@"extension.log"];
    NSFileHandle *h = [NSFileHandle fileHandleForWritingAtPath:startLogPath];
    if (h) {
        [h seekToEndOfFile];
        [h writeData:[startLog dataUsingEncoding:NSUTF8StringEncoding]];
        [h closeFile];
    } else {
        [startLog writeToFile:startLogPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
#endif

    LogMessage(@"[Extension] startTunnelWithOptions called");

#if TARGET_OS_IOS
    // 【关键】首先初始化内存优化 - 必须在 startTunnel 中调用，不能在 +load 中调用
    // Go 运行时在 dyld 加载时初始化，但 +load 可能在此之前运行
    // Aggressive 模式: 8MB limit, GOMAXPROCS=1
    if (!sMemoryOptimizationApplied) {
        LogMessage(@"[Extension] Initializing iOS memory optimization (Aggressive mode - 8MB)...");
        char* result = SuperRay_InitIOSMemoryAggressive();
        if (result) {
            LogMessage(@"[Extension] Memory optimization SUCCESS: %s", result);
            SuperRay_Free(result);
            sMemoryOptimizationApplied = YES;
        } else {
            LogMessage(@"[Extension] WARNING - SuperRay_InitIOSMemoryAggressive returned NULL!");
        }
    } else {
        LogMessage(@"[Extension] Memory optimization already applied");
    }
#endif

    // 【关键修复】防止重复初始化 - 如果已经在运行，直接返回成功
    if (_isRunning) {
        LogMessage(@"[Extension] WARNING: startTunnelWithOptions called while already running! Ignoring duplicate call.");
        completionHandler(nil);  // 返回成功，不重复初始化
        return;
    }

    // 【关键修复】清除缓存的 IP/ASN 信息，确保切换服务器后显示新的信息
    _lastIPInfo = nil;
    _lastDelayInfo = nil;
    LogMessage(@"[Extension] Cleared cached IP/delay info for fresh detection");

    // 【关键修复】重置服务器地址和端口，确保使用新服务器的信息
    _serverAddress = nil;
    _serverPort = 443;
    LogMessage(@"[Extension] Reset server address/port for new connection");

    // 【关键修复】重置检测状态，确保新连接能正确检测
    _ipDetectionInProgress = NO;
    _delayDetectionInProgress = NO;
    _ipDetectionRetryCount = 0;
    _delayDetectionRetryCount = 0;
    _lastIPDetectionTime = 0;
    _lastDelayDetectionTime = 0;
    LogMessage(@"[Extension] Reset detection status");

    // 重置 SuperRay 统计缓存，确保切换服务器后从零开始计数
    _cachedUploadBytes = 0;
    _cachedDownloadBytes = 0;
    _cachedUploadRate = 0;
    _cachedDownloadRate = 0;
    LogMessage(@"[Extension] Reset SuperRay stats cache");

    // 【关键修复】先停止旧的 Xray 实例，确保服务器切换时使用新配置
    // 如果 Extension 进程被复用（未在 stopTunnel 时终止），旧 Xray 可能还在运行
    if (_isRunning) {
        LogMessage(@"[Extension] WARNING: Previous Xray instance still running, stopping it first...");
        [self stopSuperRay];
        LogMessage(@"[Extension] Previous Xray instance stopped");
    }

    // 添加超时保护，30秒后如果还没完成就返回错误
    __block BOOL completed = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!completed) {
            LogMessage(@"[Extension] TIMEOUT: VPN startup took too long (30s)");
            completed = YES;
            NSError *timeoutError = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                                        code:9999
                                                    userInfo:@{NSLocalizedDescriptionKey: @"VPN startup timeout (30s)"}];
            completionHandler(timeoutError);
        }
    });

    // 1. Get configuration from protocolConfiguration (System Extension cannot access user's App Group)
    NETunnelProviderProtocol *tunnelProtocol = (NETunnelProviderProtocol *)self.protocolConfiguration;
    NSDictionary *providerConfig = tunnelProtocol.providerConfiguration;

    NSString *serverAddress = providerConfig[@"serverAddress"];
    __block NSString *xrayConfigJSON = providerConfig[@"xrayConfig"];
    NSNumber *serverPortNum = providerConfig[@"serverPort"];

    // 【关键】保存服务器地址和端口，用于 TCP ping 延迟检测
    if (serverAddress && serverAddress.length > 0) {
        _serverAddress = serverAddress;
    }
    if (serverPortNum && [serverPortNum integerValue] > 0) {
        _serverPort = [serverPortNum integerValue];
    }

    LogMessage(@"[Extension] Server address from providerConfiguration: %@", serverAddress ?: @"(not set)");
    LogMessage(@"[Extension] Server port from providerConfiguration: %ld", (long)_serverPort);
    LogMessage(@"[Extension] xrayConfig from providerConfiguration: %@ bytes", xrayConfigJSON ? @(xrayConfigJSON.length) : @"(nil)");

    // 1.2 Read test settings from providerConfiguration (with defaults)
    NSNumber *latencyMethod = providerConfig[@"testLatencyMethod"];
    NSString *testURL = providerConfig[@"testURL"];
    NSNumber *testTimeout = providerConfig[@"testTimeout"];

    if (latencyMethod) {
        _testLatencyMethod = [latencyMethod integerValue];
    }
    if (testURL && testURL.length > 0) {
        _testURL = testURL;
    }
    if (testTimeout && [testTimeout integerValue] > 0) {
        _testTimeout = [testTimeout integerValue];
    }
    // 1.3 Read socksPort from providerConfiguration
    NSNumber *socksPortNum = providerConfig[@"socksPort"];
    if (socksPortNum && [socksPortNum integerValue] > 0) {
        _socksPort = [socksPortNum integerValue];
    }

    // 1.4 Read DNS configuration from providerConfiguration
    NSArray *dnsServers = providerConfig[@"dnsServers"];
    if ([dnsServers isKindOfClass:[NSArray class]] && dnsServers.count > 0) {
        _dnsServers = dnsServers;
        LogMessage(@"[Extension] Using custom DNS servers: %@", _dnsServers);
    } else {
        LogMessage(@"[Extension] Using default DNS servers: %@", _dnsServers);
    }

    NSArray *directDnsServers = providerConfig[@"directDnsServers"];
    if ([directDnsServers isKindOfClass:[NSArray class]] && directDnsServers.count > 0) {
        _directDnsServers = directDnsServers;
        LogMessage(@"[Extension] Using custom direct DNS servers: %@", _directDnsServers);
    } else {
        LogMessage(@"[Extension] Using default direct DNS servers: %@", _directDnsServers);
    }

    LogMessage(@"[Extension] Test settings: method=%ld, URL=%@, timeout=%ld, socksPort=%ld",
               (long)_testLatencyMethod, _testURL, (long)_testTimeout, (long)_socksPort);

    // 1.5 Also extract server addresses from Xray config outbounds
    NSMutableArray<NSString *> *allServerAddresses = [NSMutableArray array];
    if (serverAddress) {
        [allServerAddresses addObject:serverAddress];
    }

    if (xrayConfigJSON && xrayConfigJSON.length > 0) {
        NSError *jsonError = nil;
        NSDictionary *config = [NSJSONSerialization JSONObjectWithData:[xrayConfigJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:0
                                                                 error:&jsonError];
        if (config && !jsonError) {
            NSArray *outbounds = config[@"outbounds"];
            if ([outbounds isKindOfClass:[NSArray class]]) {
                for (NSDictionary *outbound in outbounds) {
                    if (![outbound isKindOfClass:[NSDictionary class]]) continue;

                    NSString *tag = outbound[@"tag"];
                    BOOL isProxyOutbound = [tag isKindOfClass:[NSString class]] && [tag isEqualToString:@"proxy"];

                    NSDictionary *settings = outbound[@"settings"];
                    if (![settings isKindOfClass:[NSDictionary class]]) continue;

                    // Check vnext (for vmess, vless, etc.)
                    NSArray *vnext = settings[@"vnext"];
                    if ([vnext isKindOfClass:[NSArray class]]) {
                        for (NSDictionary *server in vnext) {
                            NSString *addr = server[@"address"];
                            NSNumber *port = server[@"port"];
                            if ([addr isKindOfClass:[NSString class]] && addr.length > 0) {
                                // 所有服务器地址都添加到路由排除列表
                                [allServerAddresses addObject:addr];
                                // 【关键】只从 "proxy" outbound 提取服务器地址用于延迟检测
                                if (isProxyOutbound && (!_serverAddress || _serverAddress.length == 0)) {
                                    _serverAddress = addr;
                                    if (port && [port integerValue] > 0) {
                                        _serverPort = [port integerValue];
                                    }
                                    LogMessage(@"[Extension] Set server for ping: %@:%ld", _serverAddress, (long)_serverPort);
                                }
                                LogMessage(@"[Extension] Found outbound server (vnext): %@:%@ tag=%@", addr, port, tag ?: @"(none)");
                            }
                        }
                    }

                    // Check servers (for shadowsocks, trojan, etc.)
                    NSArray *servers = settings[@"servers"];
                    if ([servers isKindOfClass:[NSArray class]]) {
                        for (NSDictionary *server in servers) {
                            NSString *addr = server[@"address"];
                            NSNumber *port = server[@"port"];
                            if ([addr isKindOfClass:[NSString class]] && addr.length > 0) {
                                // 所有服务器地址都添加到路由排除列表
                                [allServerAddresses addObject:addr];
                                // 【关键】只从 "proxy" outbound 提取服务器地址用于延迟检测
                                if (isProxyOutbound && (!_serverAddress || _serverAddress.length == 0)) {
                                    _serverAddress = addr;
                                    if (port && [port integerValue] > 0) {
                                        _serverPort = [port integerValue];
                                    }
                                    LogMessage(@"[Extension] Set server for ping: %@:%ld", _serverAddress, (long)_serverPort);
                                }
                                LogMessage(@"[Extension] Found outbound server (servers): %@:%@ tag=%@", addr, port, tag ?: @"(none)");
                            }
                        }
                    }
                }
            }
        }
    }

    LogMessage(@"[Extension] Total server addresses to exclude: %lu", (unsigned long)allServerAddresses.count);

    // 【调试日志】确认最终用于延迟检测的服务器地址
    LogMessage(@"[Extension] Final server for delay detection: %@:%ld",
               _serverAddress ?: @"(none)", (long)_serverPort);

    // 2. Create network settings with ALL server addresses for exclusion
    NEPacketTunnelNetworkSettings *settings = [self createTunnelSettingsWithServerAddresses:allServerAddresses];

    LogMessage(@"[Extension] Created tunnel settings");
    LogMessage(@"[Extension] STEP 1: Calling setTunnelNetworkSettings...");

    // 3. Apply network settings
    __weak JinGoPacketTunnelProvider *weakSelf = self;
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *error) {
        JinGoPacketTunnelProvider *strongSelf = weakSelf;
        if (!strongSelf) {
            LogMessage(@"[Extension] ERROR: self was deallocated");
            return;
        }
        LogMessage(@"[Extension] STEP 2: setTunnelNetworkSettings callback received");
        if (completed) {
            LogMessage(@"[Extension] Already timed out, ignoring callback");
            return;
        }
        if (error) {
            LogMessage(@"[Extension] setTunnelNetworkSettings failed: %@",
                   error.localizedDescription);
            completed = YES;
            completionHandler(error);
            return;
        }

        LogMessage(@"[Extension] STEP 3: Network settings applied successfully");

        // 4. Configuration already read from protocolConfiguration at the start of this method
        // The captured xrayConfigJSON variable is used directly here
        LogMessage(@"[Extension] STEP 4: Using xrayConfig from captured variable: %@ bytes", xrayConfigJSON ? @(xrayConfigJSON.length) : @"(nil)");

        // 5. Start Xray in Extension (listening on 127.0.0.1:10808)
        if (!xrayConfigJSON || xrayConfigJSON.length == 0) {
            LogMessage(@"[Extension] No Xray config available!");
            NSError *err = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                              code:1002
                                          userInfo:@{NSLocalizedDescriptionKey: @"Missing Xray configuration"}];
            completed = YES;
            completionHandler(err);
            return;
        }

        // 5.1 Detect network interface for multi-NIC support
        // System Extension cannot access user's App Group, so we always auto-detect
        NSString *primaryIP = getPrimaryInterfaceIP();
        LogMessage(@"[Extension] Auto-detected primary interface IP: %@", primaryIP);

        // 5.2 Inject sendThrough into Xray config for multi-NIC binding
        // macOS: REQUIRED to prevent routing loop (direct traffic must bypass TUN)
        // iOS: DISABLED - iOS has single NIC, sendThrough not needed and causes hangs
#if TARGET_OS_OSX
        LogMessage(@"[Extension] STEP 5.1: Injecting sendThrough on macOS (required to prevent routing loop)");
        BOOL shouldInjectSendThrough = YES;
#else
        LogMessage(@"[Extension] STEP 5.1: Skipping sendThrough injection on iOS (not needed)");
        BOOL shouldInjectSendThrough = NO;
#endif
        if (shouldInjectSendThrough && primaryIP && ![primaryIP isEqualToString:@"0.0.0.0"]) {
            LogMessage(@"[Extension] STEP 5.2: Parsing JSON config (%lu bytes)...", (unsigned long)xrayConfigJSON.length);
            NSError *jsonError = nil;
            NSMutableDictionary *configDict = [NSJSONSerialization JSONObjectWithData:[xrayConfigJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                               options:NSJSONReadingMutableContainers
                                                                                 error:&jsonError];
            LogMessage(@"[Extension] STEP 5.3: JSON parse done (error=%@, configDict=%@)",
                       jsonError ? jsonError.localizedDescription : @"nil",
                       configDict ? @"valid" : @"nil");

            // Check if configDict is nil even without error
            if (!configDict) {
                LogMessage(@"[Extension] STEP 5.3.1: configDict is nil, skipping sendThrough injection");
            } else if (jsonError) {
                LogMessage(@"[Extension] STEP 5.3.2: JSON error, skipping sendThrough injection");
            }

            if (configDict && !jsonError) {
                LogMessage(@"[Extension] STEP 5.4: Config parsed, checking outbounds...");
                NSMutableArray *outbounds = configDict[@"outbounds"];
                if (outbounds && [outbounds isKindOfClass:[NSArray class]]) {
                    LogMessage(@"[Extension] STEP 5.5: Found %lu outbounds", (unsigned long)outbounds.count);
                    BOOL modified = NO;
                    for (NSMutableDictionary *outbound in outbounds) {
                        if ([outbound isKindOfClass:[NSMutableDictionary class]]) {
                            NSString *tag = outbound[@"tag"];
                            NSString *protocol = outbound[@"protocol"];
                            // Add sendThrough to proxy AND direct outbounds (not block)
                            // 【关键修复】direct outbound 也需要 sendThrough，否则直连流量会被路由回 VPN 形成死循环
                            if (protocol &&
                                ([protocol isEqualToString:@"vmess"] ||
                                 [protocol isEqualToString:@"vless"] ||
                                 [protocol isEqualToString:@"trojan"] ||
                                 [protocol isEqualToString:@"shadowsocks"] ||
                                 [protocol isEqualToString:@"socks"] ||
                                 [protocol isEqualToString:@"http"] ||
                                 [protocol isEqualToString:@"freedom"])) {  // freedom = direct outbound
                                outbound[@"sendThrough"] = primaryIP;
                                modified = YES;
                                LogMessage(@"[Extension] Added sendThrough=%@ to outbound '%@' (protocol=%@)", primaryIP, tag, protocol);
                            }
                        }
                    }
                    LogMessage(@"[Extension] STEP 5.6: Loop done, modified=%d", modified);
                    if (modified) {
                        LogMessage(@"[Extension] STEP 5.7: Re-serializing JSON...");
                        NSData *updatedData = [NSJSONSerialization dataWithJSONObject:configDict options:0 error:nil];
                        if (updatedData) {
                            xrayConfigJSON = [[NSString alloc] initWithData:updatedData encoding:NSUTF8StringEncoding];
                            LogMessage(@"[Extension] Xray config updated with sendThrough for multi-NIC support");
                        }
                    }
                }
            } else {
                LogMessage(@"[Extension] Failed to parse Xray config for sendThrough injection: %@", jsonError);
            }
        }
        LogMessage(@"[Extension] STEP 5.9: sendThrough injection complete, proceeding to STEP 6...");

        // 6. 启动 Xray 获取 instanceID
        // TUN 模式流程：SuperRay_Run → CreateCallbackTUNWithDialer → StartCallbackTUN → EnqueueTUNPacket
        LogMessage(@"[Extension] STEP 6: Starting SuperRay (Xray)...");
        NSError *superRayError = nil;
        BOOL superRayStarted = [strongSelf startSuperRayWithConfig:xrayConfigJSON error:&superRayError];
        LogMessage(@"[Extension] STEP 7: SuperRay start returned: %@", superRayStarted ? @"YES" : @"NO");

        if (!superRayStarted) {
            LogMessage(@"[Extension] Failed to start SuperRay: %@", superRayError.localizedDescription);
            completed = YES;
            completionHandler(superRayError);
            return;
        }

        LogMessage(@"[Extension] STEP 8: SuperRay started with instanceID: %@", strongSelf->_xrayInstanceID);

        // 7. 创建 Callback TUN 并绑定到 Xray 实例的 outbound
        if (!strongSelf->_xrayInstanceID) {
            LogMessage(@"[Extension] ERROR: No Xray instanceID available");
            completed = YES;
            completionHandler([NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                                  code:1006
                                              userInfo:@{NSLocalizedDescriptionKey: @"No Xray instanceID"}]);
            return;
        }

        // 【重要】保存 packetFlow 引用，用于在 C 回调中写入输出数据包
        g_packetFlow = strongSelf.packetFlow;
        LogMessage(@"[Extension] STEP 9: Saved packetFlow reference for output callback");

        LogMessage(@"[Extension] STEP 10: Creating TUN device...");
        if (![strongSelf createTUNDeviceWithXrayInstance:strongSelf->_xrayInstanceID]) {
            LogMessage(@"[Extension] Failed to create TUN device");
            NSError *tunError = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                                    code:1007
                                                userInfo:@{NSLocalizedDescriptionKey: @"Failed to create TUN device"}];
            completed = YES;
            completionHandler(tunError);
            return;
        }

        LogMessage(@"[Extension] STEP 11: TUN device created and bound to Xray outbound 'proxy'");

        strongSelf->_isRunning = true;

        // Start reading packets after a short delay
        // Note: weakSelf is already defined at the start of this block
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                       dispatch_get_main_queue(), ^{
            JinGoPacketTunnelProvider *strongSelf = weakSelf;
            if (strongSelf && strongSelf->_isRunning) {
                LogMessage(@"[Extension] Starting packet reading (delayed 500ms for init)");
                [strongSelf startReadingPackets];
            }
        });

        LogMessage(@"[Extension] VPN started successfully");

        // 【优化】使用智能重试机制检测 IP 和延迟
        // detectAndSaveIPInfoWithRetry 和 detectAndSaveDelayWithRetry 内部会自动处理：
        // - 防止重复检测
        // - 自动重试（最多5次，递增延迟）
        // - 成功后停止重试
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            JinGoPacketTunnelProvider *innerStrongSelf = weakSelf;
            if (innerStrongSelf && innerStrongSelf->_isRunning) {
                LogMessage(@"[Extension] Starting initial IP/delay detection...");
                [innerStrongSelf detectAndSaveIPInfoWithRetry];
                // 延迟检测会在 IP 检测完成后自动触发
            }
        });

        // Start stats monitoring timer
        strongSelf->_statsTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(strongSelf->_statsTimer, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), 1 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(strongSelf->_statsTimer, ^{
            JinGoPacketTunnelProvider *innerStrongSelf = weakSelf;
            if (innerStrongSelf && innerStrongSelf->_isRunning) {
                [innerStrongSelf logTunnelStats];
            }
        });
        dispatch_resume(strongSelf->_statsTimer);
        LogMessage(@"[Extension] Started stats monitoring timer (1s interval)");

        // Start IP/delay refresh timer (every 60 seconds, first run after 62s to allow initial detection)
        strongSelf->_ipRefreshTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(strongSelf->_ipRefreshTimer, dispatch_time(DISPATCH_TIME_NOW, 62 * NSEC_PER_SEC), 60 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(strongSelf->_ipRefreshTimer, ^{
            JinGoPacketTunnelProvider *innerStrongSelf = weakSelf;
            if (innerStrongSelf && innerStrongSelf->_isRunning) {
                LogMessage(@"[Extension] Periodic IP/delay refresh triggered");
                [innerStrongSelf detectAndSaveIPInfo];
            }
        });
        dispatch_resume(strongSelf->_ipRefreshTimer);
        LogMessage(@"[Extension] Started IP/delay refresh timer (60s interval)");

#if TARGET_OS_IOS
        // Start memory monitoring timer (every 10 seconds for debugging)
        strongSelf->_memoryLogCount = 0;
        strongSelf->_memoryMonitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(strongSelf->_memoryMonitorTimer, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), 10 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(strongSelf->_memoryMonitorTimer, ^{
            JinGoPacketTunnelProvider *innerStrongSelf = weakSelf;
            if (innerStrongSelf && innerStrongSelf->_isRunning) {
                [innerStrongSelf logMemoryStatus];
            }
        });
        dispatch_resume(strongSelf->_memoryMonitorTimer);
        LogMessage(@"[Extension] Started MEMORY monitoring timer (10s interval)");
#endif

        completed = YES;
        LogMessage(@"[Extension] VPN startup completed successfully!");
        completionHandler(nil);
    }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason
           completionHandler:(void (^)(void))completionHandler {
    LogMessage(@"stopTunnelWithReason: %ld", (long)reason);

    // Log the stop reason in detail
    NSString *reasonStr = @"Unknown";
    switch (reason) {
        case NEProviderStopReasonNone: reasonStr = @"None"; break;
        case NEProviderStopReasonUserInitiated: reasonStr = @"UserInitiated"; break;
        case NEProviderStopReasonProviderFailed: reasonStr = @"ProviderFailed"; break;
        case NEProviderStopReasonNoNetworkAvailable: reasonStr = @"NoNetworkAvailable"; break;
        case NEProviderStopReasonUnrecoverableNetworkChange: reasonStr = @"UnrecoverableNetworkChange"; break;
        case NEProviderStopReasonProviderDisabled: reasonStr = @"ProviderDisabled"; break;
        case NEProviderStopReasonAuthenticationCanceled: reasonStr = @"AuthenticationCanceled"; break;
        case NEProviderStopReasonConfigurationFailed: reasonStr = @"ConfigurationFailed"; break;
        case NEProviderStopReasonIdleTimeout: reasonStr = @"IdleTimeout"; break;
        case NEProviderStopReasonConfigurationDisabled: reasonStr = @"ConfigurationDisabled"; break;
        case NEProviderStopReasonConfigurationRemoved: reasonStr = @"ConfigurationRemoved"; break;
        case NEProviderStopReasonSuperceded: reasonStr = @"Superceded"; break;
        case NEProviderStopReasonUserLogout: reasonStr = @"UserLogout"; break;
        case NEProviderStopReasonUserSwitch: reasonStr = @"UserSwitch"; break;
        case NEProviderStopReasonConnectionFailed: reasonStr = @"ConnectionFailed"; break;
        case NEProviderStopReasonSleep: reasonStr = @"Sleep"; break;
        case NEProviderStopReasonAppUpdate: reasonStr = @"AppUpdate"; break;
        default: reasonStr = [NSString stringWithFormat:@"Unknown(%ld)", (long)reason]; break;
    }
    LogMessage([NSString stringWithFormat:@"[Extension] STOP REASON: %@ (code=%ld)", reasonStr, (long)reason]);
    LogMessage(@"[Extension] Starting async shutdown with 3s timeout");

    // Stop stats timer immediately
    if (_statsTimer) {
        dispatch_source_cancel(_statsTimer);
        _statsTimer = nil;
    }

    // Stop IP refresh timer immediately
    if (_ipRefreshTimer) {
        dispatch_source_cancel(_ipRefreshTimer);
        _ipRefreshTimer = nil;
    }

#if TARGET_OS_IOS
    // Stop memory monitoring timer
    if (_memoryMonitorTimer) {
        dispatch_source_cancel(_memoryMonitorTimer);
        _memoryMonitorTimer = nil;
    }
#endif

    // 停止日志定时器并刷新缓冲区
    if (g_logFlushTimer) {
        dispatch_source_cancel(g_logFlushTimer);
        g_logFlushTimer = nil;
    }
    // 同步刷新日志缓冲区，确保停止前日志都写入
    if (g_logQueue) {
        dispatch_sync(g_logQueue, ^{
            FlushLogBuffer();
        });
    }

    // 立即清理 packetFlow 引用，防止新的回调
    g_packetFlow = nil;
    _isRunning = false;

    // Immediately return to avoid UI freeze
    completionHandler();

    // Perform cleanup asynchronously
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL cleanupCompleted = NO;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @try {
                // 清理 packetFlow 引用
                g_packetFlow = nil;
                [self stopSuperRay];
                cleanupCompleted = YES;
                LogMessage(@"[Extension] Cleanup completed successfully");
            } @catch (NSException *exception) {
                LogMessage(@"[Extension] Exception during cleanup: %@", exception);
                cleanupCompleted = YES;
            }
        });

        // 3-second timeout - force cleanup
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if (!cleanupCompleted) {
                LogMessage(@"[Extension] Timeout! Force cleanup after 3s");
                self->_isRunning = false;
            }
            LogMessage(@"[Extension] VPN stopped");
        });
    });
}

// ============================================================================
// MARK: - Packet Reading
// ============================================================================

// 专用的数据包转发队列（高优先级）
static dispatch_queue_t g_packetForwardQueue = nil;

// 获取数据包转发队列（单例）
+ (dispatch_queue_t)packetForwardQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 创建高优先级串行队列，专门用于数据包转发
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
            DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
        g_packetForwardQueue = dispatch_queue_create("cfd.jingo.acc.packet.forward", attr);
    });
    return g_packetForwardQueue;
}

// 强制写日志（同时写 App Group / /tmp 和 NSLog）
static void ForceLog(NSString *message) {
    // 1. NSLog 始终可用
    NSLog(@"[JinGo-PKT] %@", message);

    NSString *timestamp = [[NSDate date] description];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

#if TARGET_OS_OSX
    // 2. macOS: 写入用户 Library/Logs 目录
    NSString *homeDir = NSHomeDirectory();
    NSString *logDir = [homeDir stringByAppendingPathComponent:@"Library/Logs/JinGo"];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *logPath = [logDir stringByAppendingPathComponent:@"packet_debug.log"];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (handle) {
        [handle seekToEndOfFile];
        [handle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
        [handle closeFile];
    } else {
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:[logLine dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
#else
    // 2. iOS: 写入 App Group
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    if (containerURL) {
        NSURL *logURL = [containerURL URLByAppendingPathComponent:@"packet_debug.log"];
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:[logURL path]];
        if (handle) {
            [handle seekToEndOfFile];
            [handle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        } else {
            [logLine writeToURL:logURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
#endif
}

- (void)startReadingPackets {
    // 【关键修复】每次调用都记录日志，方便诊断问题
    static NSUInteger callCount = 0;
    callCount++;

    // 强制写日志（前20次）
    if (callCount <= 20) {
        ForceLog([NSString stringWithFormat:@"startReadingPackets #%lu called", (unsigned long)callCount]);
    }

    if (!_isRunning) {
        ForceLog([NSString stringWithFormat:@"startReadingPackets #%lu: _isRunning=false, stopping", (unsigned long)callCount]);
        LogMessage(@"[Extension] startReadingPackets #%lu: _isRunning is false, stopping", (unsigned long)callCount);
        return;
    }

    // 【关键修复】检查 packetFlow 是否有效
    NEPacketTunnelFlow *flow = self.packetFlow;
    if (!flow) {
        LogMessage(@"[Extension] startReadingPackets #%lu: packetFlow is nil! Cannot read packets.", (unsigned long)callCount);
        // 尝试在 1 秒后重试
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf && strongSelf->_isRunning) {
                LogMessage(@"[Extension] Retrying startReadingPackets after packetFlow was nil...");
                [strongSelf startReadingPackets];
            }
        });
        return;
    }

    // 仅首次打印启动日志
    if (callCount == 1) {
        LogMessage(@"[Extension] Starting continuous packet reading from packetFlow (SuperRay mode)");
    }

    __weak __typeof(self) weakSelf = self;
    [flow readPacketObjectsWithCompletionHandler:^(NSArray<NEPacket *> * _Nonnull packets) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;

        // 强制日志
        static NSUInteger cbCount = 0;
        cbCount++;
        if (cbCount <= 20 || cbCount % 100 == 0) {
            ForceLog([NSString stringWithFormat:@"readPackets callback #%lu: %lu packets", (unsigned long)cbCount, (unsigned long)packets.count]);
        }

        if (!strongSelf) {
            ForceLog(@"readPackets callback: strongSelf is nil!");
            NSLog(@"[Extension] readPackets callback: strongSelf is nil, stopping read loop");
            return;
        }
        if (!strongSelf->_isRunning) {
            ForceLog(@"readPackets callback: _isRunning is false!");
            NSLog(@"[Extension] readPackets callback: _isRunning is false, stopping read loop");
            return;
        }

        // 【诊断】记录每次回调
        static NSUInteger callbackCount = 0;
        static NSUInteger lastLoggedCount = 0;
        static NSDate *lastLogTime = nil;
        callbackCount++;

        NSUInteger packetCount = packets.count;

        // 每5秒至少记录一次状态，方便诊断读取循环是否还在运行
        NSDate *now = [NSDate date];
        BOOL shouldLog = (callbackCount <= 20) ||
                         (callbackCount % 500 == 0) ||
                         (!lastLogTime || [now timeIntervalSinceDate:lastLogTime] >= 5.0);

        if (shouldLog) {
            LogMessage(@"[Extension] readPackets #%lu: %lu packets, total callbacks since last log: %lu",
                      (unsigned long)callbackCount,
                      (unsigned long)packetCount,
                      (unsigned long)(callbackCount - lastLoggedCount));
            lastLoggedCount = callbackCount;
            lastLogTime = now;
        }

        if (packetCount == 0) {
            // 收到空数据包数组，继续读取
        }

        // ========== 流量转发（高优先级队列，不阻塞读取） ==========
        if (packetCount > 0) {
            // 【诊断】记录转发情况
            static NSUInteger forwardCount = 0;
            forwardCount++;

            // 前20次和每500次记录日志
            if (forwardCount <= 20 || forwardCount % 500 == 0) {
                LogMessage(@"[Extension] Forward batch #%lu: %lu packets", (unsigned long)forwardCount, (unsigned long)packetCount);
            }

            dispatch_async([JinGoPacketTunnelProvider packetForwardQueue], ^{
                for (NEPacket *packet in packets) {
                    NSData *data = packet.data;
                    if (data.length > 0) {
                        // 直接转发，不做任何额外处理
                        char* result = SuperRay_EnqueueTUNPacket([kTUNDeviceTag UTF8String],
                                                                 (const char*)[data bytes],
                                                                 (int)data.length);
                        if (result) {
                            // 检查返回值是否表示错误
                            NSString *resultStr = [NSString stringWithUTF8String:result];
                            if ([resultStr containsString:@"error"] || [resultStr containsString:@"fail"]) {
                                static int errorLogCount = 0;
                                if (errorLogCount < 10) {
                                    LogMessage(@"[Extension] EnqueueTUNPacket error: %@", resultStr);
                                    errorLogCount++;
                                }
                            }
                            SuperRay_Free(result);
                        }
                    }
                }
            });

            // 流量统计现在完全由 SuperRay 提供，不再需要本地 TUN 统计
        }

        // ========== 立即继续读取下一批数据包 ==========
        // 【关键】这是保持读取循环运行的关键调用
        [strongSelf startReadingPackets];
    }];
}

// ============================================================================
// MARK: - Memory Monitoring (iOS Debug)
// ============================================================================

#if TARGET_OS_IOS
- (void)logMemoryStatus {
    _memoryLogCount++;

    // 1. 获取 iOS 进程内存使用（task_info）
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                    TASK_BASIC_INFO,
                                    (task_info_t)&info,
                                    &size);

    uint64_t residentMB = 0;
    uint64_t virtualMB = 0;
    if (kerr == KERN_SUCCESS) {
        residentMB = info.resident_size / (1024 * 1024);
        virtualMB = info.virtual_size / (1024 * 1024);
    }

    // 2. 获取 Go 运行时内存状态
    NSString *goMemStats = @"N/A";
    char* memResult = SuperRay_GetMemoryStats();
    if (memResult) {
        goMemStats = [NSString stringWithUTF8String:memResult];
        SuperRay_Free(memResult);
    }

    // 3. 获取 TUN 设备状态
    NSString *tunStats = @"N/A";
    char* tunResult = SuperRay_GetCallbackTUNInfo([kTUNDeviceTag UTF8String]);
    if (tunResult) {
        tunStats = [NSString stringWithUTF8String:tunResult];
        SuperRay_Free(tunResult);
    }

    // 4. 记录到日志（前60次每10秒记录一次，之后每分钟记录一次）
    BOOL shouldLog = (_memoryLogCount <= 60) || (_memoryLogCount % 6 == 0);
    if (shouldLog) {
        LogMessage(@"[MEMORY #%ld] iOS: resident=%lluMB virtual=%lluMB | Go: %@ | TUN: %@",
                   (long)_memoryLogCount, residentMB, virtualMB, goMemStats, tunStats);

        // 内存警告：resident > 12MB
        if (residentMB > 12) {
            LogMessage(@"[MEMORY WARNING] Resident memory %lluMB exceeds 12MB threshold!", residentMB);

            // 尝试强制 GC
            char* gcResult = SuperRay_ForceGC();
            if (gcResult) {
                LogMessage(@"[MEMORY] ForceGC triggered: %s", gcResult);
                SuperRay_Free(gcResult);
            }
        }
    }

    // 5. 写入单独的内存日志文件（便于分析）
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    if (containerURL) {
        NSURL *memLogURL = [containerURL URLByAppendingPathComponent:@"extension_memory.log"];
        NSString *timestamp = [[NSDateFormatter localizedStringFromDate:[NSDate date]
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterMediumStyle] stringByAppendingString:@"\n"];
        NSString *logLine = [NSString stringWithFormat:@"[%@] #%ld resident=%lluMB virtual=%lluMB Go=%@ TUN=%@\n",
                             timestamp, (long)_memoryLogCount, residentMB, virtualMB, goMemStats, tunStats];

        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:memLogURL.path];
        if (handle) {
            [handle seekToEndOfFile];
            [handle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
            [handle closeFile];
        } else {
            // 文件不存在，创建新文件（带头部）
            NSString *header = @"=== JinGo VPN Extension Memory Log ===\n";
            NSString *content = [header stringByAppendingString:logLine];
            [content writeToURL:memLogURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}
#endif

// ============================================================================
// MARK: - Stats Logging
// ============================================================================

- (void)logTunnelStats {
    if (!_isRunning) {
        return;
    }

    // 使用 SuperRay_GetTrafficStats 获取 XrayDialer 的流量统计
    static NSDate* lastLogTime = nil;
    static uint64_t lastLogUpload = 0, lastLogDownload = 0;

    char* statsResult = SuperRay_GetTrafficStats();
    if (statsResult) {
        NSString* statsJSON = [NSString stringWithUTF8String:statsResult];
        SuperRay_Free(statsResult);

        NSError* parseError = nil;
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[statsJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:&parseError];
        if (!parseError && response[@"success"] && [response[@"success"] boolValue]) {
            NSDictionary* data = response[@"data"];
            if (data) {
                NSNumber* upload = data[@"upload"];
                NSNumber* download = data[@"download"];

                // 更新缓存
                if (upload) _cachedUploadBytes = [upload unsignedLongLongValue];
                if (download) _cachedDownloadBytes = [download unsignedLongLongValue];

                // 计算速率
                NSDate* now = [NSDate date];
                if (lastLogTime) {
                    NSTimeInterval elapsed = [now timeIntervalSinceDate:lastLogTime];
                    if (elapsed > 0) {
                        _cachedUploadRate = (double)(_cachedUploadBytes - lastLogUpload) / elapsed;
                        _cachedDownloadRate = (double)(_cachedDownloadBytes - lastLogDownload) / elapsed;
                    }
                }
                lastLogTime = now;
                lastLogUpload = _cachedUploadBytes;
                lastLogDownload = _cachedDownloadBytes;
            }
        }
    }

    // 日志输出缓存的统计
    LogMessage(@"[Tunnel Stats] Xray: ↑%llu B (%.1f KB/s) ↓%llu B (%.1f KB/s)",
              _cachedUploadBytes, _cachedUploadRate / 1024.0,
              _cachedDownloadBytes, _cachedDownloadRate / 1024.0);

    // Get TUN device stats for debugging
    static int tunStatsLogCount = 0;
    if (tunStatsLogCount < 20) {  // Only log first 20 times to avoid spam
        char* tunInfoResult = SuperRay_GetCallbackTUNInfo([kTUNDeviceTag UTF8String]);
        if (tunInfoResult) {
            NSString* tunInfoJSON = [NSString stringWithUTF8String:tunInfoResult];
            SuperRay_Free(tunInfoResult);

            NSError* parseError = nil;
            NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[tunInfoJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:0
                                                                       error:&parseError];
            if (!parseError && response[@"success"] && [response[@"success"] boolValue]) {
                NSDictionary* data = response[@"data"];
                if (data) {
                    LogMessage(@"[TUN Stats] devID=%@, inject=%@, tcp=%@, udp=%@, output=%@",
                              data[@"device_id"] ?: @0,
                              data[@"inject_count"] ?: @0,
                              data[@"tcp_conn_count"] ?: @0,
                              data[@"udp_conn_count"] ?: @0,
                              data[@"output_count"] ?: @0);
                }
            }
            tunStatsLogCount++;
        }
    }

    // Note: System Extension runs as root and cannot write to user's App Group
    // Stats are available via handleAppMessage instead
    // Main app can call sendProviderMessage to get real-time stats
}

// ============================================================================
// MARK: - App Communication
// ============================================================================

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData * _Nullable))completionHandler {
    // 立即写入日志以确认方法被调用
    NSString *debugMsg = [NSString stringWithFormat:@"[%@] handleAppMessage CALLED, data=%lu bytes\n",
                          [NSDate date], (unsigned long)messageData.length];
    NSLog(@"%@", debugMsg);

#if TARGET_OS_OSX
    // macOS: 写入 /tmp
    [debugMsg writeToFile:@"/tmp/extension_ipc.log" atomically:YES encoding:NSUTF8StringEncoding error:nil];
#endif

    LogMessage(@"[Extension] handleAppMessage called, data length: %lu", (unsigned long)messageData.length);

    if (!completionHandler) {
        NSLog(@"[Extension] handleAppMessage: NO COMPLETION HANDLER!");
        return;
    }

    // Parse incoming message as JSON
    NSError *parseError = nil;
    NSDictionary *message = nil;

    if (messageData && messageData.length > 0) {
        message = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:&parseError];
    }

    if (parseError || !message) {
        LogMessage(@"[Extension] Failed to parse message or empty message, returning cached stats");
        // 返回缓存的统计数据
        NSDictionary *statsDict = @{
            @"success": @YES,
            @"type": @"stats",
            @"data": @{
                @"txBytes": @(_cachedUploadBytes),
                @"rxBytes": @(_cachedDownloadBytes),
                @"uploadRate": @(_cachedUploadRate),
                @"downloadRate": @(_cachedDownloadRate)
            }
        };
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:statsDict options:0 error:nil];
        completionHandler(responseData);
        return;
    }

    NSString *type = message[@"type"];
    LogMessage(@"[Extension] Message type: %@", type);

    if ([type isEqualToString:@"test_server"]) {
        // Server latency test command
        NSString *address = message[@"address"];  // e.g., "1.2.3.4:443" or "domain.com:443"
        NSNumber *timeoutMs = message[@"timeout"];

        if (!address || address.length == 0) {
            NSDictionary *response = @{
                @"success": @NO,
                @"type": @"test_server",
                @"error": @"Missing address parameter"
            };
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
            completionHandler(responseData);
            return;
        }

        int timeout = timeoutMs ? [timeoutMs intValue] : 5000;  // Default 5 seconds
        LogMessage(@"[Extension] Testing server: %@, timeout: %dms", address, timeout);

        // Perform TCP ping test using SuperRay_Ping
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int latency = -1;

            char *result = SuperRay_Ping([address UTF8String], timeout);
            if (result) {
                NSString *jsonStr = [NSString stringWithUTF8String:result];
                NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                if ([json[@"success"] boolValue]) {
                    latency = [json[@"data"][@"latency_ms"] intValue];
                }
                SuperRay_Free(result);
            }

            LogMessage(@"[Extension] Server test result: %@ = %dms", address, latency);

            NSDictionary *response = @{
                @"success": @YES,
                @"type": @"test_server",
                @"data": @{
                    @"address": address,
                    @"latency": @(latency)
                }
            };
            NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
            completionHandler(responseData);
        });
        return;
    }
    else if ([type isEqualToString:@"detect_delay"]) {
        // Trigger delay detection with optional parameters
        LogMessage(@"[Extension] Received detect_delay request");

        // Allow dynamic test settings via message
        NSNumber *method = message[@"method"];
        NSString *url = message[@"url"];
        NSNumber *timeout = message[@"timeout"];

        // 【关键修复】支持动态更新服务器地址（用于切换服务器后的延迟检测）
        NSString *serverAddress = message[@"serverAddress"];
        NSNumber *serverPort = message[@"serverPort"];

        if (method) {
            _testLatencyMethod = [method integerValue];
        }
        if (url && url.length > 0) {
            _testURL = url;
        }
        if (timeout && [timeout integerValue] > 0) {
            _testTimeout = [timeout integerValue];
        }

        // 【关键修复】更新服务器地址用于 TCP ping
        if (serverAddress && serverAddress.length > 0) {
            _serverAddress = serverAddress;
            LogMessage(@"[Extension] Updated server address: %@", _serverAddress);
        }
        if (serverPort && [serverPort integerValue] > 0) {
            _serverPort = [serverPort integerValue];
            LogMessage(@"[Extension] Updated server port: %ld", (long)_serverPort);
        }

        // 【关键修复】清除旧的延迟缓存，确保重新检测
        _lastDelayInfo = nil;
        _delayDetectionRetryCount = 0;
        _delayDetectionInProgress = NO;

        // 执行延时测试
        [self detectAndSaveDelay];

        // 立即返回成功，延时结果可通过 get_delay_info 查询
        NSDictionary *response = @{
            @"success": @YES,
            @"type": @"detect_delay",
            @"data": @{
                @"message": @"Delay detection started",
                @"method": @(_testLatencyMethod),
                @"url": _testURL,
                @"timeout": @(_testTimeout)
            }
        };
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        completionHandler(responseData);
        return;
    }
    else if ([type isEqualToString:@"get_delay_info"]) {
        // Return cached delay info
        LogMessage(@"[Extension] Received get_delay_info request");

        NSDictionary *response;
        if (_lastDelayInfo) {
            response = @{
                @"success": @YES,
                @"type": @"delay_info",
                @"data": _lastDelayInfo
            };
        } else {
            response = @{
                @"success": @NO,
                @"type": @"delay_info",
                @"error": @"No delay info available yet"
            };
        }
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        completionHandler(responseData);
        return;
    }
    else if ([type isEqualToString:@"get_ip_info"]) {
        // Return cached IP info
        LogMessage(@"[Extension] Received get_ip_info request");

        NSDictionary *response;
        if (_lastIPInfo) {
            response = @{
                @"success": @YES,
                @"type": @"ip_info",
                @"data": _lastIPInfo
            };
        } else {
            response = @{
                @"success": @NO,
                @"type": @"ip_info",
                @"error": @"No IP info available yet"
            };
        }
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        completionHandler(responseData);
        return;
    }
    else if ([type isEqualToString:@"set_test_settings"]) {
        // Update test settings dynamically
        LogMessage(@"[Extension] Received set_test_settings request");

        NSNumber *method = message[@"method"];
        NSString *url = message[@"url"];
        NSNumber *timeout = message[@"timeout"];

        if (method) {
            _testLatencyMethod = [method integerValue];
        }
        if (url && url.length > 0) {
            _testURL = url;
        }
        if (timeout && [timeout integerValue] > 0) {
            _testTimeout = [timeout integerValue];
        }

        NSDictionary *response = @{
            @"success": @YES,
            @"type": @"set_test_settings",
            @"data": @{
                @"method": @(_testLatencyMethod),
                @"url": _testURL,
                @"timeout": @(_testTimeout)
            }
        };
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        completionHandler(responseData);
        return;
    }
    else if ([type isEqualToString:@"refresh_ip"]) {
        // Trigger IP detection
        LogMessage(@"[Extension] Received refresh_ip request");

        [self detectAndSaveIPInfo];

        NSDictionary *response = @{
            @"success": @YES,
            @"type": @"refresh_ip",
            @"data": @{
                @"message": @"IP detection started"
            }
        };
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        completionHandler(responseData);
        return;
    }
    else if ([type isEqualToString:@"get_stats"]) {
        // Stats request - 使用 SuperRay_GetTrafficStats 获取 XrayDialer 流量统计
        LogMessage(@"[get_stats] ========== handleAppMessage get_stats START ==========");
        LogMessage(@"[get_stats] cached: tx=%llu, rx=%llu", _cachedUploadBytes, _cachedDownloadBytes);

        static NSDate* lastMsgTime = nil;
        static uint64_t lastMsgUpload = 0, lastMsgDownload = 0;

        char* statsResult = SuperRay_GetTrafficStats();
        if (statsResult) {
            NSString* statsJSON = [NSString stringWithUTF8String:statsResult];
            SuperRay_Free(statsResult);

            LogMessage(@"[get_stats] SuperRay_GetTrafficStats returned: %@", statsJSON);

            NSError* parseError = nil;
            NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[statsJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                     options:0
                                                                       error:&parseError];
            if (parseError) {
                LogMessage(@"[get_stats] JSON parse ERROR: %@", parseError.localizedDescription);
            } else if (!response[@"success"] || ![response[@"success"] boolValue]) {
                LogMessage(@"[get_stats] SuperRay success=false, error=%@", response[@"error"] ?: @"unknown");
            } else {
                NSDictionary* data = response[@"data"];
                if (data) {
                    NSNumber* upload = data[@"upload"];
                    NSNumber* download = data[@"download"];

                    uint64_t oldUp = _cachedUploadBytes, oldDown = _cachedDownloadBytes;

                    // 更新缓存
                    if (upload) _cachedUploadBytes = [upload unsignedLongLongValue];
                    if (download) _cachedDownloadBytes = [download unsignedLongLongValue];

                    // 计算速率
                    NSDate* now = [NSDate date];
                    if (lastMsgTime) {
                        NSTimeInterval elapsed = [now timeIntervalSinceDate:lastMsgTime];
                        if (elapsed > 0) {
                            _cachedUploadRate = (double)(_cachedUploadBytes - lastMsgUpload) / elapsed;
                            _cachedDownloadRate = (double)(_cachedDownloadBytes - lastMsgDownload) / elapsed;
                        }
                    }
                    lastMsgTime = now;
                    lastMsgUpload = _cachedUploadBytes;
                    lastMsgDownload = _cachedDownloadBytes;

                    LogMessage(@"[get_stats] Cache updated: tx %llu->%llu, rx %llu->%llu",
                              oldUp, _cachedUploadBytes, oldDown, _cachedDownloadBytes);
                }
            }
        } else {
            LogMessage(@"[get_stats] SuperRay_GetTrafficStats returned NULL");
        }

        // 返回缓存的流量数据
        NSDictionary *statsDict = @{
            @"success": @YES,
            @"type": @"stats",
            @"data": @{
                @"txBytes": @(_cachedUploadBytes),
                @"rxBytes": @(_cachedDownloadBytes),
                @"uploadRate": @(_cachedUploadRate),
                @"downloadRate": @(_cachedDownloadRate)
            }
        };
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:statsDict options:0 error:nil];
        completionHandler(responseData);
        return;
    }
    else {
        // Unknown command, return error
        NSDictionary *response = @{
            @"success": @NO,
            @"error": [NSString stringWithFormat:@"Unknown command type: %@", type ?: @"(nil)"]
        };
        NSData *responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        completionHandler(responseData);
    }
}

#if TARGET_OS_OSX
// ============================================================================
// MARK: - XPC Listener Delegate (macOS System Extension)
// ============================================================================

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    LogMessage(@"[Extension XPC] New connection request from PID: %d", newConnection.processIdentifier);

    // 配置连接的导出接口
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(JinGoXPCProtocol)];
    newConnection.exportedObject = self;

    // 设置连接失效处理
    newConnection.invalidationHandler = ^{
        LogMessage(@"[Extension XPC] Connection invalidated");
    };

    newConnection.interruptionHandler = ^{
        LogMessage(@"[Extension XPC] Connection interrupted");
    };

    [newConnection resume];
    LogMessage(@"[Extension XPC] Connection accepted");
    return YES;
}

// ============================================================================
// MARK: - JinGoXPCProtocol Implementation (macOS)
// ============================================================================

- (void)getStatisticsWithReply:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))reply {
    LogMessage(@"[Stats Query] ========== getStatisticsWithReply START ==========");
    LogMessage(@"[Stats Query] cached before: tx=%llu, rx=%llu, upRate=%.1f, downRate=%.1f",
               _cachedUploadBytes, _cachedDownloadBytes, _cachedUploadRate, _cachedDownloadRate);

    // 使用 SuperRay_GetTrafficStats 获取 XrayDialer 的流量统计
    // （TUN 模式下流量通过 XrayDialer，统计写入 StatsManager）
    BOOL querySuccess = NO;
    static NSDate* lastQueryTime = nil;
    static uint64_t lastUpload = 0, lastDownload = 0;

    char* statsResult = SuperRay_GetTrafficStats();
    if (statsResult) {
        NSString* statsJSON = [NSString stringWithUTF8String:statsResult];
        SuperRay_Free(statsResult);

        LogMessage(@"[Stats Query] SuperRay_GetTrafficStats returned: %@", statsJSON);

        NSError* parseError = nil;
        NSDictionary* response = [NSJSONSerialization JSONObjectWithData:[statsJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:&parseError];
        if (parseError) {
            LogMessage(@"[Stats Query] JSON parse ERROR: %@", parseError.localizedDescription);
        } else if (!response[@"success"] || ![response[@"success"] boolValue]) {
            LogMessage(@"[Stats Query] SuperRay returned success=false, error=%@", response[@"error"] ?: @"unknown");
        } else {
            NSDictionary* data = response[@"data"];
            if (data) {
                NSNumber* upload = data[@"upload"];
                NSNumber* download = data[@"download"];

                LogMessage(@"[Stats Query] Parsed: upload=%@, download=%@", upload, download);

                uint64_t oldUp = _cachedUploadBytes, oldDown = _cachedDownloadBytes;

                // 更新缓存
                if (upload) _cachedUploadBytes = [upload unsignedLongLongValue];
                if (download) _cachedDownloadBytes = [download unsignedLongLongValue];

                // 计算速率 (bytes/s)
                NSDate* now = [NSDate date];
                if (lastQueryTime) {
                    NSTimeInterval elapsed = [now timeIntervalSinceDate:lastQueryTime];
                    if (elapsed > 0) {
                        _cachedUploadRate = (double)(_cachedUploadBytes - lastUpload) / elapsed;
                        _cachedDownloadRate = (double)(_cachedDownloadBytes - lastDownload) / elapsed;
                    }
                }
                lastQueryTime = now;
                lastUpload = _cachedUploadBytes;
                lastDownload = _cachedDownloadBytes;
                querySuccess = YES;

                LogMessage(@"[Stats Query] Cache updated: tx %llu->%llu (+%llu), rx %llu->%llu (+%llu)",
                           oldUp, _cachedUploadBytes, _cachedUploadBytes - oldUp,
                           oldDown, _cachedDownloadBytes, _cachedDownloadBytes - oldDown);
            } else {
                LogMessage(@"[Stats Query] data is nil in response");
            }
        }
    } else {
        LogMessage(@"[Stats Query] SuperRay_GetTrafficStats returned NULL");
    }

    // 始终返回缓存值（查询成功时已更新缓存）
    NSDictionary *stats = @{
        @"txBytes": @(_cachedUploadBytes),
        @"rxBytes": @(_cachedDownloadBytes),
        @"uploadRate": @(_cachedUploadRate),
        @"downloadRate": @(_cachedDownloadRate)
    };

    LogMessage(@"[Stats Query] RESULT: tx=%llu, rx=%llu, upRate=%.1f, downRate=%.1f (querySuccess=%d)",
               _cachedUploadBytes, _cachedDownloadBytes, _cachedUploadRate, _cachedDownloadRate, querySuccess);
    LogMessage(@"[Stats Query] ========== getStatisticsWithReply END ==========");
    reply(stats, nil);
}

- (void)getDelayInfoWithReply:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))reply {
    LogMessage(@"[Extension XPC] getDelayInfoWithReply called");

    if (_lastDelayInfo) {
        reply(_lastDelayInfo, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey: @"No delay info available yet"}];
        reply(nil, error);
    }
}

- (void)getIPInfoWithReply:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))reply {
    LogMessage(@"[Extension XPC] getIPInfoWithReply called");

    if (_lastIPInfo) {
        reply(_lastIPInfo, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"cfd.jingo.acc.extension"
                                             code:2
                                         userInfo:@{NSLocalizedDescriptionKey: @"No IP info available yet"}];
        reply(nil, error);
    }
}

- (void)triggerDelayDetectionWithReply:(void (^)(BOOL, NSError * _Nullable))reply {
    LogMessage(@"[Extension XPC] triggerDelayDetectionWithReply called");
    [self detectAndSaveDelay];
    reply(YES, nil);
}

// 【关键修复】支持传入服务器地址的 XPC 方法
- (void)triggerDelayDetectionWithServerAddress:(NSString * _Nullable)serverAddress
                                    serverPort:(NSInteger)serverPort
                                         reply:(void (^)(BOOL, NSError * _Nullable))reply {
    LogMessage(@"[Extension XPC] triggerDelayDetectionWithServerAddress called: %@:%ld",
               serverAddress ?: @"(nil)", (long)serverPort);

    // 更新服务器地址用于 TCP ping
    if (serverAddress && serverAddress.length > 0) {
        _serverAddress = serverAddress;
        LogMessage(@"[Extension XPC] Updated server address: %@", _serverAddress);
    }
    if (serverPort > 0) {
        _serverPort = serverPort;
        LogMessage(@"[Extension XPC] Updated server port: %ld", (long)_serverPort);
    }

    // 清除旧的延迟缓存，确保重新检测
    _lastDelayInfo = nil;
    _delayDetectionRetryCount = 0;
    _delayDetectionInProgress = NO;

    [self detectAndSaveDelay];
    reply(YES, nil);
}

- (void)testServerLatency:(NSString *)address
                  timeout:(int)timeout
                withReply:(void (^)(int, NSError * _Nullable))reply {
    LogMessage(@"[Extension XPC] testServerLatency: %@, timeout: %d", address, timeout);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int latency = -1;

        char *result = SuperRay_Ping([address UTF8String], timeout);
        if (result) {
            NSString *jsonStr = [NSString stringWithUTF8String:result];
            NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            if ([json[@"success"] boolValue]) {
                latency = [json[@"data"][@"latency_ms"] intValue];
            }
            SuperRay_Free(result);
        }

        LogMessage(@"[Extension XPC] Server latency result: %@ = %dms", address, latency);
        reply(latency, nil);
    });
}
#endif

@end
