/**
 * @file XrayExtensionBridge.mm
 * @brief Xray管理类实现 - Network Extension专用版本
 */

#import "XrayExtensionBridge.h"

#ifdef HAVE_SUPERRAY
// Include XrayCBridge C API
#import "core/XrayCBridge.h"
#endif

// App Group ID (must match main app)
static NSString * const kAppGroupIdentifier = @"group.work.opine.jingo";

// Helper function to write logs to both NSLog and file
static void XrayLogMessage(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    // Log to NSLog
    NSLog(@"%@", message);

    // Log to app group file
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *containerURL = [fm containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    if (containerURL) {
        NSURL *logURL = [containerURL URLByAppendingPathComponent:@"extension.log"];
        NSString *timestamp = [[NSDate date] description];
        NSString *logLine = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

        // Append to log file
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[logURL path]];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logLine dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle synchronizeFile];  // Force write to disk
            [fileHandle closeFile];
        } else {
            // Create new log file
            [logLine writeToURL:logURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

@interface XrayExtensionBridge ()

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) dispatch_queue_t xrayQueue;

@end

@implementation XrayExtensionBridge

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static XrayExtensionBridge *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isRunning = NO;
        _xrayQueue = dispatch_queue_create("work.opine.jingo.extension.xray", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

#pragma mark - Public Methods

- (BOOL)startWithConfig:(NSString *)configJSON error:(NSError **)error {
#ifdef HAVE_SUPERRAY
    __block BOOL success = NO;
    __block NSError *blockError = nil;

    dispatch_sync(self.xrayQueue, ^{
        // 如果已经运行,先停止
        if (self.isRunning) {
            XrayLogMessage(@"[XrayExtensionBridge] Xray already running, stopping first...");
            Xray_Stop();
            self.isRunning = NO;
        }

        XrayLogMessage(@"[XrayExtensionBridge] Starting Xray with config length: %lu", (unsigned long)configJSON.length);

        // 启动Xray
        int result = Xray_Start([configJSON UTF8String]);

        if (result == 0) {
            self.isRunning = YES;
            success = YES;
            XrayLogMessage(@"[XrayExtensionBridge] ✅ Xray started successfully on 127.0.0.1:10808");
        } else {
            // 获取详细错误信息
            char errorBuffer[1024];
            if (Xray_GetLastError(errorBuffer, sizeof(errorBuffer)) == 0) {
                NSString *errorMsg = [NSString stringWithUTF8String:errorBuffer];
                XrayLogMessage(@"[XrayExtensionBridge] ❌ Xray start failed: %@", errorMsg);
                blockError = [NSError errorWithDomain:@"work.opine.jingo.xray"
                                                  code:result
                                              userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
            } else {
                XrayLogMessage(@"[XrayExtensionBridge] ❌ Xray start failed with code: %d", result);
                blockError = [NSError errorWithDomain:@"work.opine.jingo.xray"
                                                  code:result
                                              userInfo:@{NSLocalizedDescriptionKey: @"Xray start failed"}];
            }
            success = NO;
        }
    });

    if (error && blockError) {
        *error = blockError;
    }

    return success;
#else
    XrayLogMessage(@"[XrayExtensionBridge] ⚠️ SuperRay not available - compiled without HAVE_SUPERRAY");
    if (error) {
        *error = [NSError errorWithDomain:@"work.opine.jingo.xray"
                                      code:-1
                                  userInfo:@{NSLocalizedDescriptionKey: @"SuperRay not available"}];
    }
    return NO;
#endif
}

- (void)stop {
#ifdef HAVE_SUPERRAY
    dispatch_sync(self.xrayQueue, ^{
        if (self.isRunning) {
            XrayLogMessage(@"[XrayExtensionBridge] Stopping Xray...");
            int result = Xray_Stop();
            self.isRunning = NO;

            if (result == 0) {
                XrayLogMessage(@"[XrayExtensionBridge] ✅ Xray stopped successfully");
            } else {
                XrayLogMessage(@"[XrayExtensionBridge] ⚠️ Xray stop returned code: %d", result);
            }
        } else {
            XrayLogMessage(@"[XrayExtensionBridge] Xray not running, nothing to stop");
        }
    });
#else
    XrayLogMessage(@"[XrayExtensionBridge] ⚠️ SuperRay not available");
#endif
}

- (nullable NSString *)getVersion {
#ifdef HAVE_SUPERRAY
    char versionBuffer[64];
    if (Xray_GetVersion(versionBuffer, sizeof(versionBuffer)) == 0) {
        return [NSString stringWithUTF8String:versionBuffer];
    }
    return nil;
#else
    return @"N/A (SuperRay not available)";
#endif
}

- (BOOL)testConfig:(NSString *)configJSON {
#ifdef HAVE_SUPERRAY
    int result = Xray_TestConfig([configJSON UTF8String]);
    if (result == 0) {
        XrayLogMessage(@"[XrayExtensionBridge] ✅ Config test passed");
        return YES;
    } else {
        char errorBuffer[1024];
        if (Xray_GetLastError(errorBuffer, sizeof(errorBuffer)) == 0) {
            XrayLogMessage(@"[XrayExtensionBridge] ❌ Config test failed: %s", errorBuffer);
        } else {
            XrayLogMessage(@"[XrayExtensionBridge] ❌ Config test failed with code: %d", result);
        }
        return NO;
    }
#else
    XrayLogMessage(@"[XrayExtensionBridge] ⚠️ SuperRay not available");
    return NO;
#endif
}

@end
