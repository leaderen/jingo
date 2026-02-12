/**
 * @file PacketTunnelProvider.mm
 * @brief 逐步恢复版 - Step 5: + IP检测 + 延迟检测
 */

#import <NetworkExtension/NetworkExtension.h>
#import <Foundation/Foundation.h>
#import <TargetConditionals.h>
#include <arpa/inet.h>
#include <netdb.h>
#include "superray.h"
#import "platform/apple/JinDoBundleHelper.h"

// ============================================================================
// App Group - 使用 JinDo 库的 BundleHelper 从 plist 动态推导
// ============================================================================
#define kAppGroupIdentifier (JinDo_AppGroupID())

// ============================================================================
// DiagLog - 三通道诊断日志
// ============================================================================
static void DiagLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
static void DiagLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"[JinGoVPN-Diag] %@", message);

    NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", [NSDate date], message];

    @try {
        NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];
        if (shared) {
            NSString *existing = [shared stringForKey:@"extension_diag_log"] ?: @"";
            if (existing.length > 4096) {
                existing = [existing substringFromIndex:existing.length - 2048];
            }
            [shared setObject:[existing stringByAppendingString:logLine] forKey:@"extension_diag_log"];
            [shared synchronize];
        }
    } @catch (NSException *e) {}

    @try {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
        if (containerURL) {
            NSURL *logURL = [containerURL URLByAppendingPathComponent:@"extension_early_diag.log"];
            NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[logURL path]];
            if (fh) {
                [fh seekToEndOfFile];
                [fh writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
                [fh synchronizeFile];
                [fh closeFile];
            } else {
                [logLine writeToURL:logURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
    } @catch (NSException *e) {}
}

// ============================================================================
// 全局 packetFlow 引用
// ============================================================================
static NEPacketTunnelFlow* g_packetFlow = nil;

static void TUNPacketOutputCallback(const void* data, int dataLen, int family, void* userData) {
    if (!data || dataLen <= 0 || !g_packetFlow) return;
    NSData *packetData = [NSData dataWithBytes:data length:dataLen];
    NSNumber *proto = (family == AF_INET6) ? @(AF_INET6) : @(AF_INET);
    [g_packetFlow writePackets:@[packetData] withProtocols:@[proto]];
}

// ============================================================================
// JinGoPacketTunnelProvider
// ============================================================================

@interface JinGoPacketTunnelProvider : NEPacketTunnelProvider {
    BOOL _isRunning;
    NSString *_xrayInstanceID;
    BOOL _tunDeviceCreated;

    // 服务器信息
    NSString *_serverAddress;
    NSInteger _serverPort;
    NSInteger _socksPort;

    // 测试设置
    NSInteger _testLatencyMethod;  // 0=TCP, 1=HTTP
    NSString *_testURL;
    NSInteger _testTimeout;

    // IP 检测
    NSDictionary *_lastIPInfo;
    BOOL _ipDetectionInProgress;
    NSInteger _ipDetectionRetryCount;
    NSTimeInterval _lastIPDetectionTime;

    // 延迟检测
    NSDictionary *_lastDelayInfo;
    BOOL _delayDetectionInProgress;
    NSInteger _delayDetectionRetryCount;
    NSTimeInterval _lastDelayDetectionTime;

    // 统计写入定时器
    dispatch_source_t _statsTimer;
    uint64_t _lastTxBytes;
    uint64_t _lastRxBytes;
}
@end

@implementation JinGoPacketTunnelProvider

// ============================================================================
// init
// ============================================================================
- (instancetype)init {
    DiagLog(@"[EXT] init called");
    self = [super init];
    if (self) {
        _isRunning = NO;
        _xrayInstanceID = nil;
        _tunDeviceCreated = NO;
        _serverAddress = nil;
        _serverPort = 443;
        _socksPort = 10808;
        _testLatencyMethod = 0;
        _testURL = @"https://www.google.com/generate_204";
        _testTimeout = 10;
        _lastIPInfo = nil;
        _lastDelayInfo = nil;
        _ipDetectionInProgress = NO;
        _delayDetectionInProgress = NO;
        _ipDetectionRetryCount = 0;
        _delayDetectionRetryCount = 0;
        _lastIPDetectionTime = 0;
        _lastDelayDetectionTime = 0;
        _statsTimer = nil;
        _lastTxBytes = 0;
        _lastRxBytes = 0;

        char *ver = SuperRay_Version();
        if (ver) {
            DiagLog(@"[EXT] SuperRay version: %s", ver);
            SuperRay_Free(ver);
        }
    }
    return self;
}

// ============================================================================
// startTunnelWithOptions
// ============================================================================
- (void)startTunnelWithOptions:(NSDictionary<NSString *,NSObject *> *)options
             completionHandler:(void (^)(NSError * _Nullable))completionHandler {

    // 清空旧诊断日志
    @try {
        NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupIdentifier];
        [shared removeObjectForKey:@"extension_diag_log"];
        [shared synchronize];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
        if (containerURL) {
            NSURL *logURL = [containerURL URLByAppendingPathComponent:@"extension_early_diag.log"];
            [fm removeItemAtURL:logURL error:nil];
        }
    } @catch (NSException *e) {}

    DiagLog(@"[EXT] startTunnelWithOptions called");

    // 重置状态
    _lastIPInfo = nil;
    _lastDelayInfo = nil;
    _ipDetectionInProgress = NO;
    _delayDetectionInProgress = NO;
    _ipDetectionRetryCount = 0;
    _delayDetectionRetryCount = 0;

    // 1. 读取配置
    NETunnelProviderProtocol *tunnelProtocol = (NETunnelProviderProtocol *)self.protocolConfiguration;
    NSDictionary *providerConfig = tunnelProtocol.providerConfiguration;

    NSString *serverAddress = providerConfig[@"serverAddress"];
    __block NSString *xrayConfigJSON = providerConfig[@"xrayConfig"];
    NSNumber *serverPortNum = providerConfig[@"serverPort"];
    NSNumber *socksPortNum = providerConfig[@"socksPort"];
    NSNumber *latencyMethod = providerConfig[@"testLatencyMethod"];
    NSString *testURL = providerConfig[@"testURL"];
    NSNumber *testTimeout = providerConfig[@"testTimeout"];

    if (serverAddress) _serverAddress = serverAddress;
    if (serverPortNum) _serverPort = [serverPortNum integerValue];
    if (socksPortNum && [socksPortNum integerValue] > 0) _socksPort = [socksPortNum integerValue];
    if (latencyMethod) _testLatencyMethod = [latencyMethod integerValue];
    if (testURL && testURL.length > 0) _testURL = testURL;
    if (testTimeout && [testTimeout integerValue] > 0) _testTimeout = [testTimeout integerValue];

    DiagLog(@"[EXT] server=%@:%ld, socks=%ld, xrayConfig=%ld bytes",
            _serverAddress ?: @"(nil)", (long)_serverPort, (long)_socksPort,
            (long)(xrayConfigJSON ? xrayConfigJSON.length : 0));

    // 从 xray config 中提取服务器地址
    NSMutableArray<NSString *> *allServerAddresses = [NSMutableArray array];
    if (_serverAddress) [allServerAddresses addObject:_serverAddress];
    [self extractServerAddressesFromConfig:xrayConfigJSON into:allServerAddresses];

    DiagLog(@"[EXT] Extracted %lu server addresses: %@",
            (unsigned long)allServerAddresses.count, allServerAddresses);

    // 2. 网络设置
    // tunnelRemoteAddress 和 excludedRoutes 必须是 IP 地址，不能是域名
    // 域名类的服务器地址先 DNS 解析，解析失败则用占位 IP
    NSString *tunnelRemoteAddr = @"192.0.2.1";
    NSMutableArray<NSString *> *resolvedServerIPs = [NSMutableArray array];
    for (NSString *addr in allServerAddresses) {
        if ([self isIPAddress:addr]) {
            [resolvedServerIPs addObject:addr];
            if ([tunnelRemoteAddr isEqualToString:@"192.0.2.1"]) {
                tunnelRemoteAddr = addr;
            }
        } else {
            // 域名 → DNS 解析
            NSString *resolved = [self resolveHostname:addr];
            if (resolved) {
                [resolvedServerIPs addObject:resolved];
                if ([tunnelRemoteAddr isEqualToString:@"192.0.2.1"]) {
                    tunnelRemoteAddr = resolved;
                }
                DiagLog(@"[EXT] Resolved %@ -> %@", addr, resolved);
            } else {
                DiagLog(@"[EXT] DNS resolve FAILED for %@, exclude route NOT added!", addr);
            }
        }
    }

    DiagLog(@"[EXT] tunnelRemoteAddr=%@, excludedIPs=%@", tunnelRemoteAddr, resolvedServerIPs);

    NEPacketTunnelNetworkSettings *settings =
        [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:tunnelRemoteAddr];

    NEIPv4Settings *ipv4 = [[NEIPv4Settings alloc]
        initWithAddresses:@[@"10.0.0.1"]
              subnetMasks:@[@"255.255.255.0"]];
    ipv4.includedRoutes = @[[NEIPv4Route defaultRoute]];

    NSMutableArray *excludeRoutes = [NSMutableArray array];
    for (NSString *ip in resolvedServerIPs) {
        [excludeRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:ip subnetMask:@"255.255.255.255"]];
    }
    for (NSString *dns in @[@"223.5.5.5", @"223.6.6.6", @"119.29.29.29"]) {
        [excludeRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:dns subnetMask:@"255.255.255.255"]];
    }
    ipv4.excludedRoutes = excludeRoutes;
    settings.IPv4Settings = ipv4;
    settings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@"223.5.5.5", @"223.6.6.6"]];
    settings.MTU = @1500;

    // 3. 应用网络设置 + 启动 Xray + TUN
    __weak JinGoPacketTunnelProvider *weakSelf = self;
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *error) {
        JinGoPacketTunnelProvider *strongSelf = weakSelf;
        if (!strongSelf) return;

        if (error) {
            DiagLog(@"[EXT] setTunnelNetworkSettings FAILED: %@", error);
            completionHandler(error);
            return;
        }

        if (!xrayConfigJSON || xrayConfigJSON.length == 0) {
            DiagLog(@"[EXT] No xrayConfig");
            completionHandler(nil);
            return;
        }

        // iOS Extension: 过滤 socks/http inbound（TUN 模式不需要）
        xrayConfigJSON = [strongSelf stripUnsupportedProtocols:xrayConfigJSON];
        DiagLog(@"[EXT] Starting SuperRay with config %ld bytes", (long)xrayConfigJSON.length);

        // 设置 geo 文件路径（geoip.dat, geosite.dat 在 Extension bundle 根目录）
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        char *assetResult = SuperRay_SetAssetDir([bundlePath UTF8String]);
        if (assetResult) {
            DiagLog(@"[EXT] SetAssetDir(%@): %s", bundlePath, assetResult);
            SuperRay_Free(assetResult);
        }

        // SuperRay_Run
        char *result = SuperRay_Run([xrayConfigJSON UTF8String]);
        if (!result) {
            DiagLog(@"[EXT] SuperRay_Run returned NULL");
            completionHandler(nil);
            return;
        }
        NSString *resultStr = [NSString stringWithUTF8String:result];
        SuperRay_Free(result);
        DiagLog(@"[EXT] SuperRay_Run: %@", resultStr);

        NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:[resultStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:0 error:nil];
        NSString *instanceID = resultDict[@"data"][@"id"] ?: resultDict[@"data"][@"instanceID"] ?: resultDict[@"data"][@"instance_id"];
        if (!instanceID) {
            DiagLog(@"[EXT] No instanceID");
            completionHandler(nil);
            return;
        }

        // TUN
        NSString *tunCfg = @"{\"tag\":\"jingo-tun\",\"mtu\":1500}";
        char *tunResult = SuperRay_CreateCallbackTUNWithDialer([tunCfg UTF8String], [instanceID UTF8String], "proxy");
        if (tunResult) { DiagLog(@"[EXT] CreateTUN: %s", tunResult); SuperRay_Free(tunResult); }

        char *cbResult = SuperRay_SetTUNPacketCallback("jingo-tun", (void*)TUNPacketOutputCallback, NULL);
        if (cbResult) { SuperRay_Free(cbResult); }

        char *startResult = SuperRay_StartCallbackTUN("jingo-tun");
        if (startResult) { SuperRay_Free(startResult); }

        g_packetFlow = strongSelf.packetFlow;
        strongSelf->_xrayInstanceID = instanceID;
        strongSelf->_tunDeviceCreated = YES;
        strongSelf->_isRunning = YES;

        // 开始读包
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)),
                       dispatch_get_main_queue(), ^{
            JinGoPacketTunnelProvider *s = weakSelf;
            if (s && s->_isRunning) [s startReadingPackets];
        });

        DiagLog(@"[EXT] VPN started!");
        completionHandler(nil);

        // 延迟 3 秒后检测 IP
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            JinGoPacketTunnelProvider *s = weakSelf;
            if (s && s->_isRunning) [s detectIPWithRetry];
        });
    }];
}

// ============================================================================
// IP 地址判断
// ============================================================================
- (BOOL)isIPAddress:(NSString *)str {
    struct in_addr addr4;
    struct in6_addr addr6;
    return (inet_pton(AF_INET, [str UTF8String], &addr4) == 1 ||
            inet_pton(AF_INET6, [str UTF8String], &addr6) == 1);
}

// ============================================================================
// 域名 DNS 解析（同步，返回第一个 IPv4 地址）
// ============================================================================
- (NSString *)resolveHostname:(NSString *)hostname {
    struct addrinfo hints = {0};
    hints.ai_family = AF_INET;  // IPv4
    hints.ai_socktype = SOCK_STREAM;

    struct addrinfo *result = NULL;
    int ret = getaddrinfo([hostname UTF8String], NULL, &hints, &result);
    if (ret != 0 || !result) return nil;

    char ipStr[INET_ADDRSTRLEN];
    struct sockaddr_in *addr = (struct sockaddr_in *)result->ai_addr;
    inet_ntop(AF_INET, &addr->sin_addr, ipStr, sizeof(ipStr));
    freeaddrinfo(result);
    return [NSString stringWithUTF8String:ipStr];
}

// ============================================================================
// 过滤 iOS TUN 模式不需要的协议
// - inbound: socks/http（TUN 模式不需要本地代理入站）
// ============================================================================
- (NSString *)stripUnsupportedProtocols:(NSString *)configJSON {
    NSData *data = [configJSON dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *config = [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] mutableCopy];
    if (!config) return configJSON;

    // 1. 过滤 inbound: socks/http
    NSArray *inbounds = config[@"inbounds"];
    if ([inbounds isKindOfClass:[NSArray class]]) {
        NSMutableArray *filtered = [NSMutableArray array];
        for (NSDictionary *inbound in inbounds) {
            NSString *protocol = inbound[@"protocol"];
            if ([protocol isEqualToString:@"socks"] || [protocol isEqualToString:@"http"]) {
                DiagLog(@"[EXT] Stripped inbound: tag=%@, protocol=%@", inbound[@"tag"], protocol);
                continue;
            }
            [filtered addObject:inbound];
        }
        config[@"inbounds"] = filtered;
    }

    NSData *newData = [NSJSONSerialization dataWithJSONObject:config options:0 error:nil];
    return newData ? [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding] : configJSON;
}

// ============================================================================
// 从 xray config 提取服务器地址
// ============================================================================
- (void)extractServerAddressesFromConfig:(NSString *)configJSON into:(NSMutableArray<NSString *> *)addresses {
    if (!configJSON) return;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:[configJSON dataUsingEncoding:NSUTF8StringEncoding]
                                                           options:0 error:nil];
    if (!config) return;

    NSArray *outbounds = config[@"outbounds"];
    if (![outbounds isKindOfClass:[NSArray class]]) return;

    for (NSDictionary *outbound in outbounds) {
        if (![outbound isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *settings = outbound[@"settings"];
        if (![settings isKindOfClass:[NSDictionary class]]) continue;

        NSString *tag = outbound[@"tag"];
        BOOL isProxy = [tag isEqualToString:@"proxy"];

        for (NSString *key in @[@"vnext", @"servers"]) {
            NSArray *servers = settings[key];
            if (![servers isKindOfClass:[NSArray class]]) continue;
            for (NSDictionary *server in servers) {
                NSString *addr = server[@"address"];
                if ([addr isKindOfClass:[NSString class]] && addr.length > 0) {
                    [addresses addObject:addr];
                    if (isProxy && (!_serverAddress || _serverAddress.length == 0)) {
                        _serverAddress = addr;
                        NSNumber *port = server[@"port"];
                        if (port) _serverPort = [port integerValue];
                    }
                }
            }
        }
    }
}

// ============================================================================
// 写 IP 信息到共享容器
// ============================================================================
- (void)writeIPInfoToSharedContainer:(NSDictionary *)ipInfo {
    @try {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
        if (!containerURL) return;

        NSURL *fileURL = [containerURL URLByAppendingPathComponent:@"ipinfo.json"];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:ipInfo options:0 error:nil];
        if (jsonData) {
            [jsonData writeToURL:fileURL atomically:YES];
            DiagLog(@"[EXT] Wrote ipinfo.json to shared container");
        }
    } @catch (NSException *e) {
        DiagLog(@"[EXT] writeIPInfoToSharedContainer exception: %@", e.reason);
    }
}

// ============================================================================
// 数据包读取
// ============================================================================
- (void)startReadingPackets {
    __weak JinGoPacketTunnelProvider *weakSelf = self;
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
        JinGoPacketTunnelProvider *s = weakSelf;
        if (!s || !s->_isRunning) return;
        for (NSUInteger i = 0; i < packets.count; i++) {
            SuperRay_EnqueueTUNPacket("jingo-tun", (const char *)packets[i].bytes, (int)packets[i].length);
        }
        [s startReadingPackets];
    }];
}

// ============================================================================
// IP 检测
// ============================================================================
- (void)detectIPWithRetry {
    if (_lastIPInfo && _lastIPInfo[@"ip"] && [_lastIPInfo[@"ip"] length] > 0 && !_lastIPInfo[@"error"]) return;
    if (_ipDetectionInProgress) return;
    if (_ipDetectionRetryCount >= 5) return;

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - _lastIPDetectionTime < 3.0) {
        __weak JinGoPacketTunnelProvider *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [weakSelf detectIPWithRetry];
        });
        return;
    }

    _ipDetectionInProgress = YES;
    _ipDetectionRetryCount++;
    _lastIPDetectionTime = now;

    DiagLog(@"[EXT] IP detection attempt %ld/5 via SOCKS5 port %ld", (long)_ipDetectionRetryCount, (long)_socksPort);

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = 8.0;
    config.connectionProxyDictionary = @{
        (NSString *)kCFStreamPropertySOCKSProxyHost: @"127.0.0.1",
        (NSString *)kCFStreamPropertySOCKSProxyPort: @(_socksPort),
        (NSString *)kCFStreamPropertySOCKSVersion: (NSString *)kCFStreamSocketSOCKSVersion5
    };

    NSURL *url = [NSURL URLWithString:@"https://ipinfo.io/json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"JinGo VPN/1.0" forHTTPHeaderField:@"User-Agent"];

    __weak JinGoPacketTunnelProvider *weakSelf = self;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // 立即释放 session
        [session finishTasksAndInvalidate];

        JinGoPacketTunnelProvider *s = weakSelf;
        if (!s) return;
        s->_ipDetectionInProgress = NO;

        NSMutableDictionary *ipInfo = [NSMutableDictionary dictionary];
        ipInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
        BOOL success = NO;

        if (error) {
            DiagLog(@"[EXT] IP detection failed: %@", error.localizedDescription);
            ipInfo[@"error"] = error.localizedDescription;
        } else if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSString *ip = json[@"ip"];
            if (ip.length > 0) {
                ipInfo[@"ip"] = ip;
                ipInfo[@"country"] = json[@"country"] ?: @"";
                NSString *org = json[@"org"] ?: @"";
                NSString *asn = @"", *isp = @"";
                NSRange spaceRange = [org rangeOfString:@" "];
                if (spaceRange.location != NSNotFound) {
                    asn = [org substringToIndex:spaceRange.location];
                    isp = [org substringFromIndex:spaceRange.location + 1];
                } else {
                    asn = org;
                }
                ipInfo[@"asn"] = asn;
                ipInfo[@"isp"] = isp;
                NSMutableArray *parts = [NSMutableArray array];
                if (asn.length > 0) [parts addObject:asn];
                if (isp.length > 0) [parts addObject:isp];
                if (json[@"country"]) [parts addObject:json[@"country"]];
                ipInfo[@"ipInfoDisplay"] = [parts componentsJoinedByString:@" | "];
                success = YES;
                s->_ipDetectionRetryCount = 0;
                DiagLog(@"[EXT] IP detected: %@ (%@)", ip, ipInfo[@"ipInfoDisplay"]);
            }
        }
        s->_lastIPInfo = [ipInfo copy];

        // 写入共享容器 ipinfo.json 供主 App 直接读取
        if (success) {
            [s writeIPInfoToSharedContainer:ipInfo];
        }

        // 触发延迟检测
        dispatch_async(dispatch_get_main_queue(), ^{ [s detectDelayWithRetry]; });

        // 重试
        if (!success && s->_ipDetectionRetryCount < 5 && s->_isRunning) {
            NSInteger delay = 3 + s->_ipDetectionRetryCount * 2;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{ [s detectIPWithRetry]; });
        }
    }] resume];
}

// ============================================================================
// 延迟检测
// ============================================================================
- (void)detectDelayWithRetry {
    if (_lastDelayInfo && [_lastDelayInfo[@"delay"] intValue] > 0) return;
    if (_delayDetectionInProgress) return;
    if (_delayDetectionRetryCount >= 5) return;

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - _lastDelayDetectionTime < 2.0) {
        __weak JinGoPacketTunnelProvider *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [weakSelf detectDelayWithRetry];
        });
        return;
    }

    _delayDetectionInProgress = YES;
    _delayDetectionRetryCount++;
    _lastDelayDetectionTime = now;

    BOOL useTCP = (_testLatencyMethod == 0);
    if (useTCP && (!_serverAddress || _serverAddress.length == 0)) useTCP = NO;

    DiagLog(@"[EXT] Delay detection attempt %ld/5, method=%@", (long)_delayDetectionRetryCount, useTCP ? @"TCP" : @"HTTP");

    __weak JinGoPacketTunnelProvider *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        JinGoPacketTunnelProvider *s = weakSelf;
        if (!s) return;

        int delay = -1;
        NSString *target = @"";
        NSString *method = useTCP ? @"TCP" : @"HTTP";
        BOOL success = NO;
        int timeoutMs = (int)(s->_testTimeout * 1000);

        if (useTCP) {
            target = [NSString stringWithFormat:@"%@:%ld", s->_serverAddress, (long)s->_serverPort];
            char *result = SuperRay_Ping([target UTF8String], timeoutMs);
            if (result) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:
                    [[NSString stringWithUTF8String:result] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                if ([json[@"success"] boolValue]) {
                    delay = [json[@"data"][@"latency_ms"] intValue];
                    if (delay > 0) success = YES;
                }
                SuperRay_Free(result);
            }
        } else {
            target = s->_testURL;
            NSString *proxyAddr = [NSString stringWithFormat:@"127.0.0.1:%ld", (long)s->_socksPort];
            char *result = SuperRay_HTTPPing([target UTF8String], [proxyAddr UTF8String], timeoutMs);
            if (result) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:
                    [[NSString stringWithUTF8String:result] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                if ([json[@"success"] boolValue]) {
                    delay = [json[@"data"][@"latency_ms"] intValue];
                    if (delay > 0) success = YES;
                }
                SuperRay_Free(result);
            }
        }

        DiagLog(@"[EXT] Delay result: %dms, method=%@, target=%@", delay, method, target);

        dispatch_async(dispatch_get_main_queue(), ^{
            s->_delayDetectionInProgress = NO;
            if (success) s->_delayDetectionRetryCount = 0;

            NSMutableDictionary *delayInfo = [NSMutableDictionary dictionary];
            delayInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
            delayInfo[@"delay"] = @(delay);
            delayInfo[@"target"] = target;
            delayInfo[@"method"] = method;
            s->_lastDelayInfo = [delayInfo copy];

            if (!success && s->_delayDetectionRetryCount < 5 && s->_isRunning) {
                NSInteger retryDelay = 2 + s->_delayDetectionRetryCount;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, retryDelay * NSEC_PER_SEC),
                               dispatch_get_main_queue(), ^{ [s detectDelayWithRetry]; });
            }
        });
    });
}

// ============================================================================
// stopTunnel
// ============================================================================
- (void)stopTunnelWithReason:(NEProviderStopReason)reason
           completionHandler:(void (^)(void))completionHandler {
    DiagLog(@"[EXT] stopTunnelWithReason: %ld", (long)reason);
    _isRunning = NO;
    g_packetFlow = nil;

    if (_tunDeviceCreated) {
        char *r = SuperRay_StopCallbackTUN("jingo-tun");
        if (r) { SuperRay_Free(r); }
        _tunDeviceCreated = NO;
    }
    if (_xrayInstanceID) {
        char *r = SuperRay_StopInstance([_xrayInstanceID UTF8String]);
        if (r) { SuperRay_Free(r); }
        _xrayInstanceID = nil;
    }
    completionHandler();
}

// ============================================================================
// handleAppMessage - 主 App IPC 协议
// 主 App 发送 JSON: {"type": "detect_delay", ...}
// 期望回复 JSON: {"success": true/false, "data": {...}, "error": "..."}
// ============================================================================
- (void)handleAppMessage:(NSData *)messageData
       completionHandler:(void (^)(NSData * _Nullable))completionHandler {
    if (!completionHandler) return;

    // 解析 JSON 消息
    NSDictionary *message = nil;
    if (messageData) {
        message = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
    }
    NSString *type = message[@"type"];
    DiagLog(@"[EXT] handleAppMessage type=%@", type ?: @"(nil)");

    if ([type isEqualToString:@"get_ip_info"]) {
        if (_lastIPInfo && _lastIPInfo[@"ip"]) {
            NSDictionary *response = @{@"success": @YES, @"data": _lastIPInfo};
            completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
        } else {
            NSDictionary *response = @{@"success": @NO, @"error": @"IP not detected yet"};
            completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
        }

    } else if ([type isEqualToString:@"get_delay_info"]) {
        if (_lastDelayInfo && [_lastDelayInfo[@"delay"] intValue] > 0) {
            NSDictionary *response = @{@"success": @YES, @"data": _lastDelayInfo};
            completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
        } else {
            NSDictionary *response = @{@"success": @NO, @"error": @"Delay not detected yet"};
            completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
        }

    } else if ([type isEqualToString:@"detect_delay"]) {
        // 主 App 触发延迟检测，可能包含新的服务器地址
        NSString *serverAddr = message[@"serverAddress"];
        NSNumber *serverPort = message[@"serverPort"];
        if (serverAddr && serverAddr.length > 0) {
            _serverAddress = serverAddr;
            if (serverPort && [serverPort integerValue] > 0) {
                _serverPort = [serverPort integerValue];
            }
            DiagLog(@"[EXT] detect_delay: updated server=%@:%ld", _serverAddress, (long)_serverPort);
        }
        _lastDelayInfo = nil;
        _delayDetectionRetryCount = 0;
        [self detectDelayWithRetry];
        NSDictionary *response = @{@"success": @YES};
        completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);

    } else if ([type isEqualToString:@"get_stats"]) {
        // 流量统计
        char *statsResult = SuperRay_GetXrayStats();
        if (statsResult) {
            NSDictionary *statsJSON = [NSJSONSerialization JSONObjectWithData:
                [[NSString stringWithUTF8String:statsResult] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            SuperRay_Free(statsResult);
            if ([statsJSON[@"success"] boolValue]) {
                NSDictionary *data = statsJSON[@"data"];
                NSDictionary *response = @{
                    @"success": @YES,
                    @"data": @{
                        @"txBytes": data[@"uplink"] ?: @(0),
                        @"rxBytes": data[@"downlink"] ?: @(0),
                        @"uploadRate": data[@"uplink_rate"] ?: @(0),
                        @"downloadRate": data[@"downlink_rate"] ?: @(0)
                    }
                };
                completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
            } else {
                NSDictionary *response = @{@"success": @NO, @"error": @"Stats not available"};
                completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
            }
        } else {
            NSDictionary *response = @{@"success": @NO, @"error": @"SuperRay_GetXrayStats returned null"};
            completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
        }

    } else if ([type isEqualToString:@"detect_ip"]) {
        _lastIPInfo = nil;
        _ipDetectionRetryCount = 0;
        [self detectIPWithRetry];
        NSDictionary *response = @{@"success": @YES};
        completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);

    } else {
        // 未知消息 → 作为心跳
        NSDictionary *response = @{@"success": @YES, @"data": @{@"status": @"alive"}};
        completionHandler([NSJSONSerialization dataWithJSONObject:response options:0 error:nil]);
    }
}

@end
