/**
 * @file XrayCBridge_Apple.mm
 * @brief Apple平台Xray桥接实现文件
 * @details 实现C++到SuperRay Framework的桥接层
 * @author JinGo VPN Team
 * @date 2025
 */

// 不包含 XrayCBridge.h，避免与framework头文件冲突
// #include "XrayCBridge.h"

// Extension模式下不包含Qt依赖
#ifndef NETWORK_EXTENSION_TARGET
#include "Logger.h"
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QDateTime>
#endif

#ifdef NETWORK_EXTENSION_TARGET
// Extension模式下使用NSLog代替LOG_*宏
#define LOG_DEBUG(msg) NSLog(@"[XrayCBridge] %@", @msg)
#define LOG_DEBUG_F(msg, ...) NSLog(@"[XrayCBridge] " msg, __VA_ARGS__)
#define LOG_INFO(msg) NSLog(@"[XrayCBridge] %@", @msg)
#define LOG_INFO_F(msg, ...) NSLog(@"[XrayCBridge] " msg, __VA_ARGS__)
#define LOG_WARNING(msg) NSLog(@"[XrayCBridge] WARNING: %@", @msg)
#define LOG_WARNING_F(msg, ...) NSLog(@"[XrayCBridge] WARNING: " msg, __VA_ARGS__)
#define LOG_ERROR(msg) NSLog(@"[XrayCBridge] ERROR: %@", @msg)
#define LOG_ERROR_F(msg, ...) NSLog(@"[XrayCBridge] ERROR: " msg, __VA_ARGS__)
#endif

#import <Foundation/Foundation.h>
#include <mutex>
// 使用 SuperRay 静态库
#import "superray.h"

// 声明导出的C函数
extern "C" {
    int Xray_Start(const char* configJSON);
    int Xray_Stop(void);
    int Xray_TestConfig(const char* configJSON);
    int Xray_GetVersion(char* version, int size);
    int Xray_Ping(const char* destination, int timeout);
    int Xray_GetRunning(void);
    int Xray_QueryStats(const char* pattern, int reset, char* result, int resultSize);
    int Xray_QueryStatsGRPC(const char* pattern, int reset, char* result, int resultSize);
    int Xray_GetLastError(char* buffer, int bufferSize);

    // 延迟测试函数 (使用 SuperRay API)
    int Xray_TCPPing(const char* address, int port, int timeout);
    int Xray_HTTPPing(const char* url, const char* proxyAddr, int timeout);

    // 速度测试函数
    int Xray_SpeedTest(const char* downloadURL, const char* proxyAddr, int durationSec, char* result, int resultSize);

    // TUN 设备管理函数 (macOS System TUN)
    int Xray_CreateTUN(const char* tunConfigJSON);
    int Xray_StartTUN(const char* tunTag, const char* outboundTag);
    int Xray_StopTUN(const char* tunTag);
    int Xray_GetInstanceID(char* buffer, int bufferSize);
}

// ============================================================================
// 全局状态
// ============================================================================

static bool g_isRunning = false;          // 运行状态标志
static NSString* g_lastError = nil;       // 最后的错误信息
static std::mutex g_xray_mutex;           // 用于保护全局状态的互斥锁

// ============================================================================
// 辅助函数
// ============================================================================

/**
 * @brief 将 C 字符串转换为 NSString
 */
static NSString* CStringToNSString(const char* cstr) {
    if (!cstr) return nil;
    return [NSString stringWithUTF8String:cstr];
}

/**
 * @brief 将 NSString 转换为 C 字符串（临时缓冲区）
 */
static const char* NSStringToCString(NSString* nsstr) {
    if (!nsstr) return nullptr;
    return [nsstr UTF8String];
}

// ============================================================================
// Xray 核心控制函数实现
// ============================================================================

/**
 * @brief 启动Xray核心
 * @param configJSON JSON格式的Xray配置字符串
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_Start(const char* configJSON)
{
    @autoreleasepool {
        LOG_DEBUG("[XrayCBridge] Xray_Start called");

        if (!configJSON || strlen(configJSON) == 0) {
            LOG_ERROR("[XrayCBridge] Invalid config: configJSON is null or empty");
            return -2;  // 无效配置
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] Config JSON length: %1 bytes", QString::number(strlen(configJSON)));
#else
        LOG_DEBUG_F("[XrayCBridge] Config JSON length: %zu bytes", strlen(configJSON));
#endif

        // 如果已经在运行，先停止（在锁外调用以避免死锁）
        {
            std::lock_guard<std::mutex> lock(g_xray_mutex);
            if (g_isRunning) {
                LOG_DEBUG("[XrayCBridge] Xray is already running, need to stop first");
            }
        }

        // 在锁外调用Stop，避免死锁
        if (g_isRunning) {
            LOG_DEBUG("[XrayCBridge] Stopping existing Xray instance...");
            Xray_Stop();

            // 等待一段时间让Go runtime完全清理
            // 这是为了避免expvar的"Reuse of exported var name: stats"错误
            LOG_DEBUG("[XrayCBridge] Waiting 2 seconds for Go runtime cleanup...");
            [NSThread sleepForTimeInterval:2.0];
        }

        // 现在重新获取锁来启动
        std::lock_guard<std::mutex> lock(g_xray_mutex);

        // 转换配置为 NSString
        NSString* configStr = CStringToNSString(configJSON);

#ifndef NETWORK_EXTENSION_TARGET
        // 记录配置的前500个字符用于调试
        QString configPreview = QString::fromUtf8(configJSON).left(500);
        LOG_DEBUG_F("[XrayCBridge] Config preview: %1%2",
                   configPreview,
                   QString(strlen(configJSON) > 500 ? "..." : ""));
#else
        // Extension模式：简化的配置预览
        size_t previewLen = strlen(configJSON) > 500 ? 500 : strlen(configJSON);
        NSString* preview = [[NSString alloc] initWithBytes:configJSON length:previewLen encoding:NSUTF8StringEncoding];
        LOG_DEBUG_F("[XrayCBridge] Config preview: %@%s", preview, strlen(configJSON) > 500 ? "..." : "");
#endif
        if (!configStr) {
            LOG_ERROR("[XrayCBridge] Failed to convert config to NSString");
            return -2;
        }

        LOG_DEBUG("[XrayCBridge] Calling LibXrayRunXrayFromJSON");

        // 调用 SuperRay 的 Objective-C API
        // 注意：LibXrayRunXrayFromJSON 接受的是 base64 编码的请求字符串
        // 我们需要构建正确格式的请求
        NSError* error = nil;

        // 获取geo文件目录路径，不同平台策略不同
        NSString* datDir = nil;

#ifndef NETWORK_EXTENSION_TARGET
        // 主应用模式：根据平台选择策略
#ifdef Q_OS_IOS
        // iOS: 直接使用App Bundle根目录（只读，但无需复制，节省空间）
        datDir = [[NSBundle mainBundle] bundlePath];
        LOG_DEBUG_F("[XrayCBridge] iOS - using App Bundle datDir: %1", QString::fromUtf8([datDir UTF8String]));

        // 验证geo文件是否存在
        QString geoipPath = QString::fromUtf8([datDir UTF8String]) + "/geoip.dat";
        QString geositePath = QString::fromUtf8([datDir UTF8String]) + "/geosite.dat";
        if (QFile::exists(geoipPath) && QFile::exists(geositePath)) {
            LOG_INFO("[XrayCBridge] Geo files found in App Bundle");
        } else {
            LOG_WARNING_F("[XrayCBridge] Geo files not found! geoip: %1, geosite: %2",
                         QFile::exists(geoipPath) ? "exists" : "MISSING",
                         QFile::exists(geositePath) ? "exists" : "MISSING");
        }
#else
        // macOS: 优先使用Resources/dat，如果不存在则复制到Application Support
        NSString* bundleResourcePath = [[NSBundle mainBundle] resourcePath];
        NSString* bundleDatPath = [bundleResourcePath stringByAppendingPathComponent:@"dat"];

        // 检查bundle中的geo文件是否存在
        BOOL geoipExists = [[NSFileManager defaultManager] fileExistsAtPath:[bundleDatPath stringByAppendingPathComponent:@"geoip.dat"]];
        BOOL geositeExists = [[NSFileManager defaultManager] fileExistsAtPath:[bundleDatPath stringByAppendingPathComponent:@"geosite.dat"]];

        if (geoipExists && geositeExists) {
            // 直接使用bundle中的geo文件
            datDir = bundleDatPath;
            LOG_DEBUG_F("[XrayCBridge] macOS - using Bundle Resources datDir: %1", QString::fromUtf8([datDir UTF8String]));
        } else {
            // fallback: 复制到Application Support目录
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
            NSString* appSupportDir = [paths firstObject];
            datDir = [appSupportDir stringByAppendingPathComponent:@"Opine Work/JinGo"];

            QString datDirPath = QString::fromUtf8([datDir UTF8String]);
            QDir().mkpath(datDirPath);  // 确保目录存在

            LOG_DEBUG_F("[XrayCBridge] macOS - copying geo files to Application Support: %1", datDirPath);

            QString sourceDatPath = QString::fromUtf8([bundleDatPath UTF8String]);
            QStringList geoFiles = {"geoip.dat", "geosite.dat"};
            for (const QString& fileName : geoFiles) {
                QString destPath = datDirPath + "/" + fileName;
                QString sourcePath = sourceDatPath + "/" + fileName;

                if (!QFile::exists(destPath) && QFile::exists(sourcePath)) {
                    QFile sourceFile(sourcePath);
                    if (sourceFile.copy(destPath)) {
                        QFile::setPermissions(destPath, QFile::ReadOwner | QFile::WriteOwner | QFile::ReadGroup | QFile::ReadOther);
                        LOG_INFO_F("[XrayCBridge] Copied %1 to Application Support", fileName);
                    } else {
                        LOG_WARNING_F("[XrayCBridge] Failed to copy %1: %2", fileName, sourceFile.errorString());
                    }
                }
            }
        }
#endif
#else
        // Extension模式：直接使用Extension bundle中的资源
        NSString* bundleResourcePath = [[NSBundle mainBundle] resourcePath];
        datDir = [bundleResourcePath stringByAppendingPathComponent:@"dat"];
        LOG_DEBUG_F("[XrayCBridge] Extension mode - using bundle resources datDir: %s", [datDir UTF8String]);
#endif

        // 使用 SuperRay API 设置资源目录
        LOG_DEBUG("[XrayCBridge] Setting asset directory for geo files");
        char* assetResult = SuperRay_SetAssetDir([datDir UTF8String]);
        if (assetResult) {
            LOG_DEBUG_F("[XrayCBridge] SuperRay_SetAssetDir result: %s", assetResult);
            SuperRay_Free(assetResult);
        }

        LOG_DEBUG("[XrayCBridge] Starting Xray with SuperRay_Run");

        // 启动 Xray (使用 SuperRay API)
        char* resultCStr = SuperRay_Run([configStr UTF8String]);

        if (!resultCStr) {
            LOG_ERROR("[XrayCBridge] SuperRay_Run returned null");
            g_lastError = @"Xray start failed - null response";
            g_isRunning = false;
            return -1;
        }

        // 转换为 NSString 以便后续处理
        NSString* result = [NSString stringWithUTF8String:resultCStr];
        SuperRay_Free(resultCStr);  // 释放结果字符串

        // SuperRay_Run 返回 JSON 响应（不再是 base64 编码）
        // 格式: {"success": true/false, "data": {...}, "error": "错误信息(如果有)"}
        if (result && [result length] > 0) {
            const char* resultCStrLog = [result UTF8String];
#ifndef NETWORK_EXTENSION_TARGET
            LOG_DEBUG_F("[XrayCBridge] Xray start result: %1", QString::fromUtf8(resultCStrLog));
#else
            LOG_DEBUG_F("[XrayCBridge] Xray start result: %s", resultCStrLog);
#endif

            // 直接解析 JSON（SuperRay 返回的是纯 JSON，不是 base64）
            NSError* jsonError = nil;
            NSData* jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

            if (jsonError || !responseDict) {
#ifndef NETWORK_EXTENSION_TARGET
                LOG_WARNING_F("[XrayCBridge] Failed to parse JSON. Error: %1",
                           QString::fromUtf8(jsonError ? [[jsonError localizedDescription] UTF8String] : "Unknown error"));
                LOG_INFO_F("[XrayCBridge] Response was: %1", QString::fromUtf8([result UTF8String]));
#else
                LOG_WARNING_F("[XrayCBridge] Failed to parse JSON. Error: %@",
                           jsonError ? [jsonError localizedDescription] : @"Unknown error");
                LOG_INFO_F("[XrayCBridge] Response was: %@", result);
#endif
                // 验证 Xray 是否真的在运行（通过 ListInstances）
                char* instancesJson = SuperRay_ListInstances();
                if (instancesJson) {
                    NSString* instancesStr = [NSString stringWithUTF8String:instancesJson];
                    SuperRay_Free(instancesJson);

                    NSError* checkError = nil;
                    NSDictionary* instances = [NSJSONSerialization JSONObjectWithData:[instancesStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                              options:0
                                                                                error:&checkError];
                    if (!checkError && instances) {
                        NSDictionary* data = instances[@"data"];
                        NSNumber* count = data[@"count"];
                        if (count && [count intValue] > 0) {
                            // Xray 确实在运行
                            LOG_INFO("[XrayCBridge] Xray verified running via ListInstances");
                            g_isRunning = true;
                            g_lastError = nil;
                            return 0;
                        }
                    }
                }

                // 无法验证 Xray 运行状态，视为失败
                LOG_ERROR("[XrayCBridge] Cannot verify Xray is running - treating as failure");
                g_isRunning = false;
                g_lastError = @"Failed to parse response and cannot verify Xray status";
                return -2;
            }

            // 检查success字段
            NSNumber* successNum = responseDict[@"success"];
            if (successNum && [successNum boolValue]) {
                // API调用成功，设置运行标志
                // 注意：不在这里阻塞验证，避免冻结UI
                LOG_INFO("[XrayCBridge] Xray start API returned success=true");
                g_isRunning = true;
                g_lastError = nil;
                return 0;
            } else {
                // 启动失败，获取错误信息
                NSString* errorMsg = responseDict[@"error"];
                if (!errorMsg) {
                    errorMsg = result; // 使用整个响应作为错误信息
                }

#ifndef NETWORK_EXTENSION_TARGET
                LOG_ERROR_F("[XrayCBridge] Xray start failed: %1", QString::fromUtf8([errorMsg UTF8String]));
#else
                LOG_ERROR_F("[XrayCBridge] Xray start failed: %@", errorMsg);
#endif

                // 尝试解析错误类型
                NSString* lowerError = [errorMsg lowercaseString];

                // 忽略端口占用错误 - Xray 实际上已经在运行
                // 特别是 metrics 端口 (15490) 的占用可以忽略
                if ([lowerError containsString:@"address already in use"] ||
                    [lowerError containsString:@"bind:"] ||
                    [lowerError containsString:@"only one usage of each socket address"]) {

                    // 检查是否是 metrics 端口 (15490) 或其他非关键端口
                    if ([lowerError containsString:@"15490"]) {
                        LOG_WARNING("[XrayCBridge] Metrics port conflict ignored (15490), Xray is running");
                        g_isRunning = true;
                        g_lastError = nil;
                        return 0;
                    }

                    // 如果是 Start 操作且有端口冲突，可能是之前的实例还在运行
                    // 这种情况下也视为成功（但会记录警告）
#ifndef NETWORK_EXTENSION_TARGET
                    LOG_WARNING_F("[XrayCBridge] Port conflict detected, but Xray may already be running: %1",
                                 QString::fromUtf8([errorMsg UTF8String]));
#else
                    LOG_WARNING_F("[XrayCBridge] Port conflict detected, but Xray may already be running: %@",
                                 errorMsg);
#endif
                    // 仍然返回 OK，因为 Xray 可能已经在运行
                    g_isRunning = true;
                    g_lastError = nil;
                    return 0;
                }

                // 其他错误类型
                g_lastError = errorMsg;
                g_isRunning = false;

                if ([lowerError containsString:@"config"] || [lowerError containsString:@"invalid"]) {
                    LOG_ERROR("[XrayCBridge] Error type: Invalid config (-2)");
                    return -2;
                } else {
#ifndef NETWORK_EXTENSION_TARGET
                    LOG_ERROR_F("[XrayCBridge] Error type: Other error: %1",
                               QString::fromUtf8([errorMsg UTF8String]));
#else
                    LOG_ERROR_F("[XrayCBridge] Error type: Other error: %@",
                               errorMsg);
#endif
                    return -1;
                }
            }
        }

        // 如果返回空字符串，也认为是成功（兼容旧版本）
        LOG_INFO("[XrayCBridge] Xray core started successfully (empty response)");
        g_isRunning = true;
        g_lastError = nil;
        return 0;
    }
}

/**
 * @brief 停止Xray核心
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_Stop(void)
{
    @autoreleasepool {
        // 加锁以保护对 g_isRunning 和 g_lastError 的访问
        std::lock_guard<std::mutex> lock(g_xray_mutex);

        LOG_DEBUG("[XrayCBridge] Xray_Stop called");

        if (!g_isRunning) {
            LOG_DEBUG("[XrayCBridge] Xray is not running, nothing to stop");
            return 0;  // 未运行，直接返回成功
        }

        LOG_DEBUG("[XrayCBridge] Calling SuperRay_StopAll");

        // 调用 SuperRay 停止所有实例
        char* resultCStr = SuperRay_StopAll();

        if (!resultCStr) {
            LOG_WARNING("[XrayCBridge] SuperRay_StopAll returned null");
            g_isRunning = false;
            return 0;  // 即使返回 null 也认为停止成功
        }

        NSString* result = [NSString stringWithUTF8String:resultCStr];
        SuperRay_Free(resultCStr);  // 释放结果字符串

        // SuperRay_StopAll 返回 JSON 响应（不再是 base64 编码）
        if (result && [result length] > 0) {
            const char* resultCStrLog = [result UTF8String];
#ifndef NETWORK_EXTENSION_TARGET
            LOG_DEBUG_F("[XrayCBridge] Xray stop result: %1", QString::fromUtf8(resultCStrLog));
#else
            LOG_DEBUG_F("[XrayCBridge] Xray stop result: %s", resultCStrLog);
#endif

            // 直接解析 JSON
            NSError* jsonError = nil;
            NSData* jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

            if (!jsonError && responseDict) {
                NSNumber* successNum = responseDict[@"success"];
                if (successNum && [successNum boolValue]) {
                    // 停止成功
                    LOG_INFO("[XrayCBridge] Xray core stopped successfully");
                    g_isRunning = false;
                    g_lastError = nil;

                    // 添加等待时间确保Go runtime完全清理，包括 expvar 变量
                    LOG_INFO("[XrayCBridge] Waiting 2 seconds for Go runtime cleanup (expvar, metrics, etc.)...");
                    [NSThread sleepForTimeInterval:2.0];
                    LOG_INFO("[XrayCBridge] Cleanup complete, ready for next start");

                    return 0;
                } else {
                    // 停止失败
                    NSString* errorMsg = responseDict[@"error"];
                    if (!errorMsg) {
                        errorMsg = result;
                    }
#ifndef NETWORK_EXTENSION_TARGET
                    LOG_ERROR_F("[XrayCBridge] Xray stop failed: %1", QString::fromUtf8([errorMsg UTF8String]));
#else
                    LOG_ERROR_F("[XrayCBridge] Xray stop failed: %@", errorMsg);
#endif
                    g_lastError = errorMsg;
                    g_isRunning = false;
                    return -1;
                }
            }

            // 如果不是base64或JSON格式，当作错误消息处理
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR_F("[XrayCBridge] Xray stop failed: %1", QString::fromUtf8(resultCStr));
#else
            LOG_ERROR_F("[XrayCBridge] Xray stop failed: %s", resultCStr);
#endif
            g_lastError = result;
            g_isRunning = false;
            return -1;
        }

        // 返回空字符串，认为成功
        LOG_INFO("[XrayCBridge] Xray core stopped successfully");
        g_isRunning = false;
        g_lastError = nil;

        // 添加等待时间确保Go runtime完全清理，包括 expvar 变量
        LOG_INFO("[XrayCBridge] Waiting 2 seconds for Go runtime cleanup (expvar, metrics, etc.)...");
        [NSThread sleepForTimeInterval:2.0];
        LOG_INFO("[XrayCBridge] Cleanup complete, ready for next start");

        return 0;
    }
}

/**
 * @brief 测试配置有效性
 * @param configJSON JSON格式的Xray配置字符串
 * @return int 配置有效返回0，无效返回负数错误码
 */
int Xray_TestConfig(const char* configJSON)
{
    @autoreleasepool {
        if (!configJSON || strlen(configJSON) == 0) {
            return -2;  // 无效配置
        }

        char* result = SuperRay_ValidateConfig(configJSON);
        if (!result) {
            LOG_ERROR("[XrayCBridge] SuperRay_ValidateConfig returned null");
            return -3;
        }

        NSString* resultStr = [NSString stringWithUTF8String:result];
        SuperRay_Free(result);

        NSData* data = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        bool success = [json[@"success"] boolValue];
        if (!success) {
            NSString* error = json[@"error"] ?: @"Unknown error";
#ifdef NETWORK_EXTENSION_TARGET
            NSLog(@"[XrayCBridge] ERROR: Config validation failed: %@", error);
#else
            LOG_ERROR(QString("[XrayCBridge] Config validation failed: %1").arg(QString::fromNSString(error)));
#endif
            return -1;
        }

        return 0;
    }
}

/**
 * @brief 获取Xray版本信息
 * @param version 用于存储版本字符串的缓冲区
 * @param size 缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_GetVersion(char* version, int size)
{
    @autoreleasepool {
        LOG_DEBUG("[XrayCBridge] Xray_GetVersion called");

        if (!version || size <= 0) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR_F("[XrayCBridge] Invalid parameters: version=%1, size=%2",
                       QString::number((qulonglong)version, 16), QString::number(size));
#else
            LOG_ERROR_F("[XrayCBridge] Invalid parameters: version=%p, size=%d",
                       version, size);
#endif
            return -1;
        }

        LOG_DEBUG("[XrayCBridge] Calling SuperRay_XrayVersion");
        char* versionCStr = SuperRay_XrayVersion();

        if (!versionCStr) {
            LOG_ERROR("[XrayCBridge] SuperRay_XrayVersion returned null");
            return -1;
        }

        NSString* versionStr = [NSString stringWithUTF8String:versionCStr];
        SuperRay_Free(versionCStr);  // 释放版本字符串

        if (!versionStr) {
            LOG_ERROR("[XrayCBridge] Failed to convert version to NSString");
            return -1;
        }

        const char* cstr = NSStringToCString(versionStr);
        if (!cstr) {
            LOG_ERROR("[XrayCBridge] Failed to convert version to C string");
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] Xray version: %1",
                   QString::fromUtf8(cstr ? cstr : "Unknown"));
#else
        LOG_DEBUG_F("[XrayCBridge] Xray version: %s",
                   cstr ? cstr : "Unknown");
#endif

        size_t len = strlen(cstr);
        if (len >= static_cast<size_t>(size)) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR_F("[XrayCBridge] Buffer too small: need %1 bytes, got %2 bytes",
                       QString::number(len + 1), QString::number(size));
#else
            LOG_ERROR_F("[XrayCBridge] Buffer too small: need %zu bytes, got %d bytes",
                       len + 1, size);
#endif
            return -1;  // 缓冲区太小
        }

        strncpy(version, cstr, size - 1);
        version[size - 1] = '\0';  // 确保以null结尾

        return 0;
    }
}

/**
 * @brief 检查Xray是否正在运行
 * @return int 运行中返回1，未运行返回0
 */
int Xray_GetRunning(void)
{
    @autoreleasepool {
        // 加锁以保护对 g_isRunning 的读取和潜在写入
        std::lock_guard<std::mutex> lock(g_xray_mutex);

        // 方法1：使用内部状态标志
        if (g_isRunning) {
            return 1;
        }

        // 方法2：调用 SuperRay 列表实例函数检查是否有运行中的实例
        char* instancesJson = SuperRay_ListInstances();
        if (instancesJson) {
            NSString* jsonStr = [NSString stringWithUTF8String:instancesJson];
            SuperRay_Free(instancesJson);

            // 解析 JSON 检查实例数量
            NSError* error = nil;
            NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

            if (!error && dict) {
                NSDictionary* data = dict[@"data"];
                if (data) {
                    NSNumber* count = data[@"count"];
                    if (count && [count intValue] > 0) {
                        g_isRunning = true;  // 更新状态
                        return 1;
                    }
                }
            }
        }

        return 0;
    }
}

// ============================================================================
// 流量统计查询函数实现
// ============================================================================

/**
 * @brief 查询流量统计数据
 * @param pattern 统计项匹配模式（支持通配符）- 现在不使用，SuperRay返回所有统计
 * @param reset 查询后是否重置计数器（1=重置，0=不重置）
 * @param result 用于存储JSON格式统计结果的缓冲区
 * @param resultSize 结果缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 *
 * @note 使用 SuperRay 的直接 API，不再需要 HTTP 查询
 */
int Xray_QueryStats(const char* pattern, int reset, char* result, int resultSize)
{
    @autoreleasepool {
        std::lock_guard<std::mutex> lock(g_xray_mutex);

        // 1. 检查结果缓冲区
        if (!result || resultSize <= 0) {
            return -1;
        }

        if (!g_isRunning) {
            result[0] = '\0';
            return 0;
        }

        LOG_DEBUG("[XrayCBridge] QueryStats: Using SuperRay direct API");

        // =================================================================
        // 使用 SuperRay 的直接 API 查询流量统计
        // 不再需要 HTTP 查询 (端口 10085)
        // =================================================================
        char* responseCStr = SuperRay_GetXrayStats();

        if (!responseCStr) {
            LOG_WARNING("[XrayCBridge] QueryStats: SuperRay_GetXrayStats returned null");
            result[0] = '\0';
            return -1;
        }

        NSString* response = [NSString stringWithUTF8String:responseCStr];
        SuperRay_Free(responseCStr);  // 释放响应字符串

        if (!response || [response length] == 0) {
            LOG_WARNING("[XrayCBridge] QueryStats: Got empty response");
            result[0] = '\0';
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] QueryStats: Got response: %1",
                   QString::fromUtf8([response UTF8String]).left(500));
#else
        NSString* responsePreview = [response length] > 500 ? [response substringToIndex:500] : response;
        LOG_DEBUG_F("[XrayCBridge] QueryStats: Got response: %@%s",
                   responsePreview, [response length] > 500 ? "..." : "");
#endif

        // SuperRay_GetXrayStats 直接返回 JSON，不需要 Base64 解码
        const char* jsonCStr = [response UTF8String];
        size_t responseLen = strlen(jsonCStr);

        // 如果需要重置统计
        if (reset) {
            char* resetResult = SuperRay_ResetXrayStats();
            if (resetResult) {
                SuperRay_Free(resetResult);
            }
        }

        // 复制响应到结果缓冲区
        if (responseLen >= (size_t)resultSize) {
            strncpy(result, jsonCStr, resultSize - 1);
            result[resultSize - 1] = '\0';
        } else {
            strcpy(result, jsonCStr);
        }

        return 0;
    }
}

/**
 * @brief 通过直接API查询流量统计数据（新实现）
 * @param pattern 统计项匹配模式 - 现在不使用，SuperRay返回所有统计
 * @param reset 是否重置计数器
 * @param result 结果缓冲区
 * @param resultSize 缓冲区大小
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 使用 SuperRay 的直接 API 查询流量统计
 * 不再需要 HTTP 或 gRPC 查询
 */
int Xray_QueryStatsGRPC(const char* pattern, int reset, char* result, int resultSize)
{
    @autoreleasepool {
        std::lock_guard<std::mutex> lock(g_xray_mutex);

        // 1. 检查参数
        if (!result || resultSize <= 0) {
            LOG_ERROR("[XrayCBridge] QueryStatsGRPC: Invalid parameters");
            if (result) result[0] = '\0';
            return -1;
        }

        // 2. 检查Xray是否运行
        if (!g_isRunning) {
            LOG_WARNING("[XrayCBridge] QueryStatsGRPC: Xray is not running");
            result[0] = '\0';
            return -1;
        }

        LOG_DEBUG("[XrayCBridge] QueryStatsGRPC: Using SuperRay direct API");

        // =================================================================
        // 使用 SuperRay 的直接 API 查询流量统计
        // 不再需要 HTTP 查询 (端口 15490)
        // =================================================================
        char* responseCStr = SuperRay_GetXrayStats();

        if (!responseCStr) {
            LOG_WARNING("[XrayCBridge] QueryStatsGRPC: SuperRay_GetXrayStats returned null");
            result[0] = '\0';
            return -1;
        }

        NSString* response = [NSString stringWithUTF8String:responseCStr];
        SuperRay_Free(responseCStr);  // 释放响应字符串

        if (!response || [response length] == 0) {
            LOG_WARNING("[XrayCBridge] QueryStatsGRPC: Got empty response");
            result[0] = '\0';
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] QueryStatsGRPC: Got response: %1",
                   QString::fromUtf8([response UTF8String]).left(200));
#else
        NSString* responsePreview = [response length] > 200 ? [response substringToIndex:200] : response;
        LOG_DEBUG_F("[XrayCBridge] QueryStatsGRPC: Got response: %@%s",
                   responsePreview, [response length] > 200 ? "..." : "");
#endif

        // SuperRay_GetXrayStats 直接返回 JSON，不需要 Base64 解码
        const char* jsonCStr = [response UTF8String];
        size_t responseLen = strlen(jsonCStr);

        // 如果需要重置统计
        if (reset) {
            char* resetResult = SuperRay_ResetXrayStats();
            if (resetResult) {
                SuperRay_Free(resetResult);
            }
        }

        // 复制结果到缓冲区
        if (responseLen >= (size_t)resultSize) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_WARNING_F("[XrayCBridge] QueryStatsGRPC: Response truncated (size=%1, buffer=%2)",
                         QString::number(responseLen),
                         QString::number(resultSize));
#else
            LOG_WARNING_F("[XrayCBridge] QueryStatsGRPC: Response truncated (size=%zu, buffer=%d)",
                         responseLen, resultSize);
#endif
            strncpy(result, jsonCStr, resultSize - 1);
            result[resultSize - 1] = '\0';
        } else {
            strcpy(result, jsonCStr);
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] QueryStatsGRPC: Success, result length=%1",
                   QString::number(strlen(result)));
#else
        LOG_DEBUG_F("[XrayCBridge] QueryStatsGRPC: Success, result length=%zu",
                   strlen(result));
#endif

        return 0;
    }
}

/**
 * @brief 测试目标服务器的延迟(Ping)
 * @param configJSON 完整的Xray ping配置JSON字符串
 *                   格式: {"destination": "https://...", "timeout": "5000ms", "proxy": {...}}
 * @param timeout 超时时间（毫秒）- 作为备用参数
 * @return int 延迟时间（毫秒），失败返回-1
 *
 * @note LibXrayPing expects base64-encoded ping config JSON
 */
int Xray_Ping(const char* configJSON, int timeout)
{
    @autoreleasepool {
        LOG_INFO("[XrayCBridge] Xray_Ping called");

        if (!configJSON || strlen(configJSON) == 0) {
            LOG_ERROR("[XrayCBridge] Invalid parameters: configJSON is null/empty");
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        QString configStr = QString::fromUtf8(configJSON);
        LOG_INFO_F("[XrayCBridge] Config size: %1 bytes", QString::number(configStr.length()));

        @try {
            // 1. 获取数据目录路径 (geoip.dat 和 geosite.dat 所在目录)
            NSString* datDirNS = [[NSBundle mainBundle] resourcePath];
            QString datDir = QString::fromNSString(datDirNS);

            // 2. 创建临时配置文件
            QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
            QString tempConfigPath = tempDir + "/xray_ping_config_" +
                                   QString::number(QDateTime::currentMSecsSinceEpoch()) + ".json";

            QFile tempFile(tempConfigPath);
            if (!tempFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
                LOG_ERROR_F("[XrayCBridge] Failed to create temp config file: %1", tempConfigPath);
                return -1;
            }

            tempFile.write(configStr.toUtf8());
            tempFile.close();

            LOG_INFO_F("[XrayCBridge] Wrote config to temp file: %1", tempConfigPath);

            // 3. 构建 LibXrayPing 请求
            // LibXrayPing 期望的格式:
            // {
            //   "DatDir": "/path/to/dat",
            //   "ConfigPath": "/path/to/config.json",
            //   "Timeout": 5,
            //   "Url": "https://www.google.com/generate_204",
            //   "Proxy": "socks5://127.0.0.1:10808"
            // }
            QJsonObject pingRequest;
            pingRequest["DatDir"] = datDir;
            pingRequest["ConfigPath"] = tempConfigPath;
            pingRequest["Timeout"] = timeout / 1000;  // 转换为秒
            pingRequest["Url"] = "https://www.google.com/generate_204";
            pingRequest["Proxy"] = "socks5://127.0.0.1:10808";  // 本地 socks5 代理

            // 4. 删除临时配置文件（不再需要）
            QFile::remove(tempConfigPath);
            LOG_INFO_F("[XrayCBridge] Removed temp config file: %1", tempConfigPath);

            // 5. 使用 SuperRay_HTTPPing API 进行 HTTP ping
            // SuperRay_HTTPPing(url, proxyAddr, timeoutMs)
            QString proxyAddr = "127.0.0.1:10808";  // 本地 SOCKS5 代理
            QString testUrl = "https://www.google.com/generate_204";

            LOG_INFO_F("[XrayCBridge] HTTPPing: url=%1, proxy=%2, timeout=%3ms", testUrl, proxyAddr, QString::number(timeout));

            char* resultCStr = SuperRay_HTTPPing(
                testUrl.toUtf8().constData(),
                proxyAddr.toUtf8().constData(),
                timeout
            );

            if (!resultCStr) {
                LOG_ERROR("[XrayCBridge] SuperRay_HTTPPing returned null");
                return -1;
            }

            NSString* resultStr = [NSString stringWithUTF8String:resultCStr];
            SuperRay_Free(resultCStr);  // 释放结果字符串

            if (!resultStr || [resultStr length] == 0) {
                LOG_ERROR("[XrayCBridge] SuperRay_HTTPPing returned empty string");
                return -1;
            }

            // 6. 解析返回结果 (SuperRay 返回 JSON，不是 base64)
            QString resultQStr = QString::fromNSString(resultStr);
            LOG_INFO_F("[XrayCBridge] SuperRay_HTTPPing result: %1", resultQStr);

            // 7. 解析延迟值
            int latency = -1;

            // SuperRay_HTTPPing 返回格式:
            // {"success": true, "data": {"latency_ms": 123, "status_code": 204}}
            QJsonDocument resultDoc = QJsonDocument::fromJson(resultQStr.toUtf8());
            if (!resultDoc.isNull() && resultDoc.isObject()) {
                QJsonObject resultObj = resultDoc.object();

                // 检查是否有错误
                if (resultObj.contains("error") && !resultObj["error"].toString().isEmpty()) {
                    QString error = resultObj["error"].toString();
                    LOG_ERROR_F("[XrayCBridge] Ping failed with error: %1", error);
                    g_lastError = [NSString stringWithUTF8String:error.toUtf8().constData()];
                    return -1;
                }

                // 读取 data 字段 (延迟值，单位：毫秒)
                if (resultObj.contains("data")) {
                    QJsonValue dataValue = resultObj["data"];
                    if (dataValue.isDouble() || dataValue.isString()) {
                        latency = dataValue.toInt(-1);
                    }
                }
            }

            if (latency >= 0) {
                LOG_INFO_F("[XrayCBridge] Ping successful: %1 ms", QString::number(latency));
                g_lastError = nil;
                return latency;
            } else {
                LOG_ERROR_F("[XrayCBridge] Failed to parse latency from result: %1", resultQStr);
                g_lastError = @"Failed to parse ping result";
                return -1;
            }

        } @catch (NSException* exception) {
            LOG_ERROR_F("[XrayCBridge] Exception in Xray_Ping: %1",
                       QString::fromUtf8([[exception description] UTF8String]));
            g_lastError = [exception reason];
            return -1;
        }
#else
        // Extension模式：Ping功能不可用
        LOG_INFO_F("[XrayCBridge] Config size: %zu bytes (Ping not supported in extension mode)", strlen(configJSON));
        LOG_WARNING("[XrayCBridge] Xray_Ping is not supported in Network Extension mode");
        return -1;
#endif
    }
}

/**
 * @brief 获取最后一次操作的错误消息
 * @param buffer 用于存储错误消息的缓冲区
 * @param bufferSize 缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_GetLastError(char* buffer, int bufferSize)
{
    if (!buffer || bufferSize <= 0) {
        return -1;
    }

    @autoreleasepool {
        if (g_lastError) {
            NSString* errorStr = g_lastError;
            const char* errorCStr = [errorStr UTF8String];
            strncpy(buffer, errorCStr, bufferSize - 1);
            buffer[bufferSize - 1] = '\0';
        } else {
            buffer[0] = '\0';
        }
    }

    return 0;
}

// ============================================================================
// 延迟测试函数实现 (使用 SuperRay API)
// ============================================================================

/**
 * @brief TCP连接延迟测试（使用 SuperRay_Ping）
 * @param address 服务器地址（如 "www.google.com"）
 * @param timeout 超时时间（毫秒）
 * @return int 延迟时间（毫秒），失败返回-1
 */
int Xray_SimplePing(const char* address, int timeout)
{
    @autoreleasepool {
        if (!address || strlen(address) == 0) {
            LOG_ERROR("[XrayCBridge] Xray_SimplePing: Invalid address");
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] SimplePing: %1, timeout=%2ms",
                   QString::fromUtf8(address), QString::number(timeout));
#else
        LOG_DEBUG_F("[XrayCBridge] SimplePing: %s, timeout=%dms", address, timeout);
#endif

        // 使用 SuperRay_Ping API
        char* resultCStr = SuperRay_Ping(address, timeout);

        if (!resultCStr) {
            LOG_ERROR("[XrayCBridge] SuperRay_Ping returned null");
            return -1;
        }

        NSString* resultStr = [NSString stringWithUTF8String:resultCStr];
        SuperRay_Free(resultCStr);

        if (!resultStr || [resultStr length] == 0) {
            LOG_ERROR("[XrayCBridge] SuperRay_Ping returned empty string");
            return -1;
        }

        // 解析 JSON 结果
        NSData* jsonData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError* jsonError = nil;
        NSDictionary* resultDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (jsonError || !resultDict) {
            LOG_ERROR("[XrayCBridge] Failed to parse SimplePing result JSON");
            return -1;
        }

        NSNumber* success = resultDict[@"success"];
        if (!success || ![success boolValue]) {
            NSString* errorMsg = resultDict[@"error"];
#ifndef NETWORK_EXTENSION_TARGET
            LOG_WARNING_F("[XrayCBridge] SimplePing failed: %1",
                         QString::fromUtf8(errorMsg ? [errorMsg UTF8String] : "Unknown error"));
#else
            LOG_WARNING_F("[XrayCBridge] SimplePing failed: %@", errorMsg ?: @"Unknown error");
#endif
            return -1;
        }

        // 读取延迟值
        NSDictionary* data = resultDict[@"data"];
        if (!data) {
            LOG_ERROR("[XrayCBridge] SimplePing result missing 'data' field");
            return -1;
        }

        NSNumber* latencyMs = data[@"latency_ms"];
        if (!latencyMs) {
            LOG_ERROR("[XrayCBridge] SimplePing result missing 'latency_ms' field");
            return -1;
        }

        int latency = [latencyMs intValue];
#ifndef NETWORK_EXTENSION_TARGET
        LOG_INFO_F("[XrayCBridge] SimplePing success: %1 ms", QString::number(latency));
#else
        LOG_INFO_F("[XrayCBridge] SimplePing success: %d ms", latency);
#endif

        return latency;
    }
}

/**
 * @brief TCP连接延迟测试
 * @param address 服务器地址
 * @param port 服务器端口
 * @param timeout 超时时间（毫秒）
 * @return int 延迟时间（毫秒），失败返回-1
 */
int Xray_TCPPing(const char* address, int port, int timeout)
{
    @autoreleasepool {
        if (!address || strlen(address) == 0 || port <= 0) {
            LOG_ERROR("[XrayCBridge] Xray_TCPPing: Invalid parameters");
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] TCPPing: %1:%2, timeout=%3ms",
                   QString::fromUtf8(address), QString::number(port), QString::number(timeout));
#else
        LOG_DEBUG_F("[XrayCBridge] TCPPing: %s:%d, timeout=%dms", address, port, timeout);
#endif

        // 使用 SuperRay_TCPPing API
        char* resultCStr = SuperRay_TCPPing(address, port, timeout);

        if (!resultCStr) {
            LOG_ERROR("[XrayCBridge] SuperRay_TCPPing returned null");
            return -1;
        }

        NSString* resultStr = [NSString stringWithUTF8String:resultCStr];
        SuperRay_Free(resultCStr);

        if (!resultStr || [resultStr length] == 0) {
            LOG_ERROR("[XrayCBridge] SuperRay_TCPPing returned empty string");
            return -1;
        }

        // 解析 JSON 结果
        // 格式: {"success":true,"data":{"latency_ms":123}} 或 {"success":false,"error":"..."}
        NSData* jsonData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError* jsonError = nil;
        NSDictionary* resultDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (jsonError || !resultDict) {
            LOG_ERROR("[XrayCBridge] Failed to parse TCPPing result JSON");
            return -1;
        }

        NSNumber* success = resultDict[@"success"];
        if (!success || ![success boolValue]) {
            NSString* errorMsg = resultDict[@"error"];
#ifndef NETWORK_EXTENSION_TARGET
            LOG_WARNING_F("[XrayCBridge] TCPPing failed: %1",
                         QString::fromUtf8(errorMsg ? [errorMsg UTF8String] : "Unknown error"));
#else
            LOG_WARNING_F("[XrayCBridge] TCPPing failed: %@", errorMsg ?: @"Unknown error");
#endif
            return -1;
        }

        // 读取延迟值
        NSDictionary* data = resultDict[@"data"];
        if (!data) {
            LOG_ERROR("[XrayCBridge] TCPPing result missing 'data' field");
            return -1;
        }

        NSNumber* latencyMs = data[@"latency_ms"];
        if (!latencyMs) {
            LOG_ERROR("[XrayCBridge] TCPPing result missing 'latency_ms' field");
            return -1;
        }

        int latency = [latencyMs intValue];
#ifndef NETWORK_EXTENSION_TARGET
        LOG_INFO_F("[XrayCBridge] TCPPing success: %1 ms", QString::number(latency));
#else
        LOG_INFO_F("[XrayCBridge] TCPPing success: %d ms", latency);
#endif

        return latency;
    }
}

/**
 * @brief HTTP延迟测试
 * @param url 测试URL (如 "https://www.google.com/generate_204")
 * @param proxyAddr 代理地址 (如 "127.0.0.1:10808")，空字符串表示直连
 * @param timeout 超时时间（毫秒）
 * @return int 延迟时间（毫秒），失败返回-1
 */
int Xray_HTTPPing(const char* url, const char* proxyAddr, int timeout)
{
    @autoreleasepool {
        if (!url || strlen(url) == 0) {
            LOG_ERROR("[XrayCBridge] Xray_HTTPPing: Invalid URL");
            return -1;
        }

        // proxyAddr 可以为空（直连测试）
        const char* proxy = proxyAddr ? proxyAddr : "";

#ifndef NETWORK_EXTENSION_TARGET
        LOG_DEBUG_F("[XrayCBridge] HTTPPing: url=%1, proxy=%2, timeout=%3ms",
                   QString::fromUtf8(url),
                   QString::fromUtf8(proxy),
                   QString::number(timeout));
#else
        LOG_DEBUG_F("[XrayCBridge] HTTPPing: url=%s, proxy=%s, timeout=%dms", url, proxy, timeout);
#endif

        // 使用 SuperRay_HTTPPing API
        char* resultCStr = SuperRay_HTTPPing(url, proxy, timeout);

        if (!resultCStr) {
            LOG_ERROR("[XrayCBridge] SuperRay_HTTPPing returned null");
            return -1;
        }

        NSString* resultStr = [NSString stringWithUTF8String:resultCStr];
        SuperRay_Free(resultCStr);

        if (!resultStr || [resultStr length] == 0) {
            LOG_ERROR("[XrayCBridge] SuperRay_HTTPPing returned empty string");
            return -1;
        }

        // 解析 JSON 结果
        // 格式: {"success":true,"data":{"latency_ms":123,"status_code":204}} 或 {"success":false,"error":"..."}
        NSData* jsonData = [resultStr dataUsingEncoding:NSUTF8StringEncoding];
        NSError* jsonError = nil;
        NSDictionary* resultDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (jsonError || !resultDict) {
            LOG_ERROR("[XrayCBridge] Failed to parse HTTPPing result JSON");
            return -1;
        }

        NSNumber* success = resultDict[@"success"];
        if (!success || ![success boolValue]) {
            NSString* errorMsg = resultDict[@"error"];
#ifndef NETWORK_EXTENSION_TARGET
            LOG_WARNING_F("[XrayCBridge] HTTPPing failed: %1",
                         QString::fromUtf8(errorMsg ? [errorMsg UTF8String] : "Unknown error"));
#else
            LOG_WARNING_F("[XrayCBridge] HTTPPing failed: %@", errorMsg ?: @"Unknown error");
#endif
            return -1;
        }

        // 读取延迟值
        NSDictionary* data = resultDict[@"data"];
        if (!data) {
            LOG_ERROR("[XrayCBridge] HTTPPing result missing 'data' field");
            return -1;
        }

        NSNumber* latencyMs = data[@"latency_ms"];
        if (!latencyMs) {
            LOG_ERROR("[XrayCBridge] HTTPPing result missing 'latency_ms' field");
            return -1;
        }

        int latency = [latencyMs intValue];
#ifndef NETWORK_EXTENSION_TARGET
        LOG_INFO_F("[XrayCBridge] HTTPPing success: %1 ms", QString::number(latency));
#else
        LOG_INFO_F("[XrayCBridge] HTTPPing success: %d ms", latency);
#endif

        return latency;
    }
}

/**
 * @brief 执行速度测试
 * @param downloadURL 下载测试URL
 * @param proxyAddr 代理地址 (格式: socks5://127.0.0.1:1080)
 * @param durationSec 测试时长(秒)
 * @param result 结果缓冲区
 * @param resultSize 结果缓冲区大小
 * @return 成功返回0，失败返回错误码
 */
int Xray_SpeedTest(const char* downloadURL, const char* proxyAddr, int durationSec, char* result, int resultSize)
{
    @autoreleasepool {
        if (!downloadURL || !proxyAddr || !result || resultSize <= 0) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR("[XrayCBridge] SpeedTest: Invalid parameters");
#else
            LOG_ERROR_F("[XrayCBridge] SpeedTest: Invalid parameters %s", "");
#endif
            return -1;
        }

#ifndef NETWORK_EXTENSION_TARGET
        LOG_INFO_F("[XrayCBridge] Starting speed test: url=%1, proxy=%2, duration=%3s",
                  QString::fromUtf8(downloadURL),
                  QString::fromUtf8(proxyAddr),
                  QString::number(durationSec));
#else
        LOG_INFO_F("[XrayCBridge] Starting speed test: url=%s, proxy=%s, duration=%ds",
                  downloadURL, proxyAddr, durationSec);
#endif

        // 调用 SuperRay_SpeedTest
        char* resultJson = SuperRay_SpeedTest(downloadURL, proxyAddr, durationSec);
        if (!resultJson) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR("[XrayCBridge] SpeedTest failed: SuperRay_SpeedTest returned null");
#else
            LOG_ERROR_F("[XrayCBridge] SpeedTest failed: SuperRay_SpeedTest returned null %s", "");
#endif
            return -1;
        }

        // 解析结果
        NSString* jsonStr = [NSString stringWithUTF8String:resultJson];
        SuperRay_Free(resultJson);

        NSError* error = nil;
        NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* resultDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

        if (error || !resultDict) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR_F("[XrayCBridge] SpeedTest: Failed to parse result JSON: %1",
                       error ? QString::fromNSString([error localizedDescription]) : QString("null result"));
#else
            LOG_ERROR_F("[XrayCBridge] SpeedTest: Failed to parse result JSON %s", "");
#endif
            return -1;
        }

        // 检查是否有错误
        NSNumber* successNum = resultDict[@"success"];
        if (![successNum boolValue]) {
            NSString* errorMsg = resultDict[@"error"];
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR_F("[XrayCBridge] SpeedTest failed: %1",
                       QString::fromNSString(errorMsg ? errorMsg : @"Unknown error"));
#else
            LOG_ERROR_F("[XrayCBridge] SpeedTest failed: %s",
                       errorMsg ? [errorMsg UTF8String] : "Unknown error");
#endif
            return -1;
        }

        // 复制结果到输出缓冲区
        const char* resultCStr = [jsonStr UTF8String];
        size_t resultLen = strlen(resultCStr);
        if (resultLen >= (size_t)resultSize) {
#ifndef NETWORK_EXTENSION_TARGET
            LOG_ERROR_F("[XrayCBridge] SpeedTest: Result buffer too small: need %1 bytes, got %2 bytes",
                       QString::number(resultLen + 1), QString::number(resultSize));
#else
            LOG_ERROR_F("[XrayCBridge] SpeedTest: Result buffer too small %s", "");
#endif
            return -1;
        }

        strncpy(result, resultCStr, resultSize - 1);
        result[resultSize - 1] = '\0';

#ifndef NETWORK_EXTENSION_TARGET
        LOG_INFO_F("[XrayCBridge] SpeedTest completed successfully: %1", QString::fromUtf8(result));
#else
        LOG_INFO_F("[XrayCBridge] SpeedTest completed successfully %s", "");
#endif

        return 0;
    }
}

// ============================================================================
// TUN 设备管理函数实现 (macOS System TUN - 管理员模式)
// ============================================================================

#if TARGET_OS_OSX && !defined(NETWORK_EXTENSION_TARGET)

// 辅助函数：解析 SuperRay JSON 响应，检查是否成功
static bool parseJsonResponse(const char* jsonResponse, NSDictionary** outData, QString* errorMsg)
{
    if (!jsonResponse) {
        if (errorMsg) *errorMsg = "Null response";
        return false;
    }

    NSString* jsonStr = [NSString stringWithUTF8String:jsonResponse];
    NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    if (error || !dict) {
        if (errorMsg) *errorMsg = QString("JSON parse error: %1").arg(error ? QString::fromNSString([error localizedDescription]) : "null");
        return false;
    }

    NSNumber* success = dict[@"success"];
    if (![success boolValue]) {
        NSString* errStr = dict[@"error"];
        if (errorMsg) *errorMsg = errStr ? QString::fromNSString(errStr) : "Unknown error";
        return false;
    }

    if (outData) *outData = dict[@"data"];
    return true;
}

int Xray_GetInstanceID(char* buffer, int bufferSize)
{
    @autoreleasepool {
        if (!buffer || bufferSize <= 0) {
            LOG_ERROR("[XrayCBridge] GetInstanceID: Invalid buffer");
            return -1;
        }

        char* response = SuperRay_ListInstances();
        if (!response) {
            LOG_ERROR("[XrayCBridge] GetInstanceID: SuperRay_ListInstances returned null");
            buffer[0] = '\0';
            return -1;
        }

        // 解析 JSON 响应
        NSDictionary* data = nil;
        QString errorMsg;
        bool success = parseJsonResponse(response, &data, &errorMsg);
        SuperRay_Free(response);

        if (!success) {
            LOG_ERROR_F("[XrayCBridge] GetInstanceID: %1", errorMsg);
            buffer[0] = '\0';
            return -1;
        }

        // 从 data 中获取 instances 数组
        NSArray* instances = data[@"instances"];
        if (!instances || instances.count == 0) {
            LOG_ERROR("[XrayCBridge] GetInstanceID: No instances running");
            buffer[0] = '\0';
            return -1;
        }

        // 获取第一个实例 ID
        NSString* firstInstance = instances[0];
        const char* instanceCStr = [firstInstance UTF8String];
        size_t len = strlen(instanceCStr);

        if (len >= (size_t)bufferSize) {
            LOG_ERROR("[XrayCBridge] GetInstanceID: Buffer too small");
            return -1;
        }

        strncpy(buffer, instanceCStr, bufferSize - 1);
        buffer[bufferSize - 1] = '\0';

        LOG_INFO_F("[XrayCBridge] GetInstanceID: %1", QString::fromUtf8(buffer));
        return 0;
    }
}

int Xray_CreateTUN(const char* tunConfigJSON)
{
    @autoreleasepool {
        if (!tunConfigJSON) {
            LOG_ERROR("[XrayCBridge] CreateTUN: Config is null");
            g_lastError = @"TUN config is null";
            return -1;
        }

        LOG_INFO("[XrayCBridge] CreateTUN: Creating system TUN device...");
        LOG_INFO_F("[XrayCBridge] CreateTUN config: %1", QString::fromUtf8(tunConfigJSON));

        char* response = SuperRay_CreateSystemTUN(tunConfigJSON);
        if (!response) {
            LOG_ERROR("[XrayCBridge] CreateTUN: SuperRay_CreateSystemTUN returned null");
            g_lastError = @"SuperRay_CreateSystemTUN returned null";
            return -1;
        }

        LOG_INFO_F("[XrayCBridge] CreateTUN response: %1", QString::fromUtf8(response));

        QString errorMsg;
        bool success = parseJsonResponse(response, nil, &errorMsg);
        SuperRay_Free(response);

        if (!success) {
            LOG_ERROR_F("[XrayCBridge] CreateTUN failed: %1", errorMsg);
            g_lastError = [NSString stringWithUTF8String:errorMsg.toUtf8().constData()];
            return -1;
        }

        LOG_INFO("[XrayCBridge] CreateTUN: System TUN device created successfully");
        g_lastError = nil;
        return 0;
    }
}

int Xray_StartTUN(const char* tunTag, const char* outboundTag)
{
    @autoreleasepool {
        if (!tunTag || !outboundTag) {
            LOG_ERROR("[XrayCBridge] StartTUN: Invalid parameters");
            return -1;
        }

        LOG_INFO_F("[XrayCBridge] StartTUN: tunTag=%1, outboundTag=%2",
                   QString::fromUtf8(tunTag), QString::fromUtf8(outboundTag));

        // 首先获取当前运行的 Xray 实例 ID
        char instanceID[256];
        if (Xray_GetInstanceID(instanceID, sizeof(instanceID)) != 0) {
            LOG_ERROR("[XrayCBridge] StartTUN: Failed to get Xray instance ID");
            return -1;
        }

        char* response = SuperRay_StartSystemTUNStack(tunTag, instanceID, outboundTag);
        if (!response) {
            LOG_ERROR("[XrayCBridge] StartTUN: SuperRay_StartSystemTUNStack returned null");
            return -1;
        }

        QString errorMsg;
        bool success = parseJsonResponse(response, nil, &errorMsg);
        SuperRay_Free(response);

        if (!success) {
            LOG_ERROR_F("[XrayCBridge] StartTUN failed: %1", errorMsg);
            return -1;
        }

        LOG_INFO("[XrayCBridge] StartTUN: System TUN stack started successfully");
        return 0;
    }
}

int Xray_StopTUN(const char* tunTag)
{
    @autoreleasepool {
        if (!tunTag) {
            LOG_ERROR("[XrayCBridge] StopTUN: tunTag is null");
            return -1;
        }

        LOG_INFO_F("[XrayCBridge] StopTUN: Stopping TUN with tag: %1", QString::fromUtf8(tunTag));

        char* response = SuperRay_CloseSystemTUN(tunTag);
        if (!response) {
            LOG_ERROR("[XrayCBridge] StopTUN: SuperRay_CloseSystemTUN returned null");
            return -1;
        }

        QString errorMsg;
        bool success = parseJsonResponse(response, nil, &errorMsg);
        SuperRay_Free(response);

        if (!success) {
            LOG_ERROR_F("[XrayCBridge] StopTUN failed: %1", errorMsg);
            return -1;
        }

        LOG_INFO("[XrayCBridge] StopTUN: System TUN stopped successfully");
        return 0;
    }
}

#else
// iOS 或 Network Extension 中不支持系统 TUN（使用 Network Extension 代替）

int Xray_GetInstanceID(char* buffer, int bufferSize)
{
    if (buffer && bufferSize > 0) buffer[0] = '\0';
    return -1;
}

int Xray_CreateTUN(const char* tunConfigJSON)
{
    (void)tunConfigJSON;
    return -1;
}

int Xray_StartTUN(const char* tunTag, const char* outboundTag)
{
    (void)tunTag;
    (void)outboundTag;
    return -1;
}

int Xray_StopTUN(const char* tunTag)
{
    (void)tunTag;
    return -1;
}

#endif
