/**
 * Main entry point for Network Extension
 * - macOS: System Extension mode (startSystemExtensionMode)
 * - iOS: App Extension mode (no explicit start needed)
 *
 * 【重要】iOS App Extension 的入口点必须尽可能简洁
 * 不应该有任何阻塞操作或复杂的初始化代码
 * NetworkExtension 框架会在 dispatch_main() 运行后自动实例化 principal class
 */

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import <TargetConditionals.h>

int main(int argc, char *argv[]) {
    @autoreleasepool {
#if TARGET_OS_OSX
        // macOS: System Extension 需要显式启动
        NSLog(@"[Extension] Running on macOS - starting System Extension mode");
        [NEProvider startSystemExtensionMode];
#else
        // iOS: App Extension 不需要显式启动
        // 系统会在 dispatch_main() 后自动处理
        NSLog(@"[Extension] Running on iOS - entering dispatch_main");
#endif
        // 进入主事件循环
        // NetworkExtension 框架会通过 IPC 接收来自主应用的请求
        // 并自动实例化 Info.plist 中指定的 NSExtensionPrincipalClass
        dispatch_main();
    }
    return 0;
}
