/**
 * @file IOSPlatformHelper.h
 * @brief iOS平台Objective-C桥接接口
 * @details 提供C/C++到Objective-C的桥接，用于访问iOS平台特定功能
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef IOSPLATFORMHELPER_H
#define IOSPLATFORMHELPER_H

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// 不透明指针类型
// ============================================================================

/**
 * @typedef IOSPlatformHelperRef
 * @brief IOSPlatformHelper不透明指针类型
 *
 * @details 用于隐藏Objective-C实现细节的不透明指针
 * - 在C/C++代码中作为句柄使用
 * - 实际指向Objective-C对象
 * - 通过C函数接口操作
 */
typedef void* IOSPlatformHelperRef;

// ============================================================================
// 生命周期管理
// ============================================================================

/**
 * @brief 创建IOSPlatformHelper实例
 * @return IOSPlatformHelperRef Helper实例引用，失败返回NULL
 *
 * @details 创建iOS平台助手对象
 * - 分配并初始化Objective-C对象
 * - 初始化NetworkExtension和UserNotifications
 * - 返回不透明指针供后续操作使用
 *
 * @note 使用完毕后必须调用IOSPlatformHelper_destroy释放
 *
 * @see IOSPlatformHelper_destroy
 */
IOSPlatformHelperRef IOSPlatformHelper_create(void);

/**
 * @brief 销毁IOSPlatformHelper实例
 * @param helper 要销毁的Helper实例
 *
 * @details 释放iOS平台助手对象
 * - 释放Objective-C对象
 * - 清理VPN配置（可选）
 * - 释放所有相关资源
 *
 * @note helper可以为NULL（安全）
 *
 * @see IOSPlatformHelper_create
 */
void IOSPlatformHelper_destroy(IOSPlatformHelperRef helper);

// ============================================================================
// VPN 权限管理
// ============================================================================

/**
 * @brief 请求VPN配置权限
 * @param helper Helper实例引用
 * @return bool 成功返回true，失败返回false
 *
 * @details 请求iOS VPN配置权限
 * - 调用NEVPNManager.shared().loadFromPreferences
 * - 如果未授权，显示系统权限对话框
 * - 异步操作，可能需要等待用户响应
 *
 * @note
 * - 需要在Info.plist中声明VPN权限
 * - 用户可能拒绝授权
 * - iOS同时只能有一个VPN配置
 *
 * @see IOSPlatformHelper_hasVPNPermission
 */
bool IOSPlatformHelper_requestVPNPermission(IOSPlatformHelperRef helper);

/**
 * @brief 检查是否已有VPN权限
 * @param helper Helper实例引用
 * @return bool 有权限返回true，无权限返回false
 *
 * @details 检查VPN配置权限状态
 * - 查询NEVPNManager当前状态
 * - 检查是否可以访问VPN配置
 *
 * @see IOSPlatformHelper_requestVPNPermission
 */
bool IOSPlatformHelper_hasVPNPermission(IOSPlatformHelperRef helper);

// ============================================================================
// VPN 控制
// ============================================================================

/**
 * @brief 配置VPN
 * @param helper Helper实例引用
 * @param config VPN配置字符串（JSON格式）
 * @return bool 成功返回true，失败返回false
 *
 * @details 创建或更新VPN配置文件
 * - 解析JSON配置参数
 * - 创建NEVPNProtocolIKEv2或自定义协议配置
 * - 保存配置到系统（NEVPNManager.saveToPreferences）
 *
 * 配置JSON格式示例：
 * @code{.json}
 * {
 *   "serverAddress": "vpn.example.com",
 *   "username": "user@example.com",
 *   "password": "password",
 *   "remoteIdentifier": "vpn.example.com",
 *   "localIdentifier": "user@example.com"
 * }
 * @endcode
 *
 * @note
 * - 需要先获得VPN权限
 * - config必须是有效的JSON字符串
 *
 * @see IOSPlatformHelper_startVPN, IOSPlatformHelper_removeVPNProfile
 */
bool IOSPlatformHelper_configureVPN(IOSPlatformHelperRef helper, const char* config);

/**
 * @brief 启动VPN连接
 * @param helper Helper实例引用
 * @return bool 成功返回true，失败返回false
 *
 * @details 启动VPN连接
 * - 调用NEVPNManager.connection.startVPNTunnel
 * - 使用之前配置的VPN参数
 * - 异步操作，连接状态通过回调通知
 *
 * @note
 * - 需要先调用configureVPN配置VPN
 * - 连接过程可能需要几秒钟
 *
 * @see IOSPlatformHelper_configureVPN, IOSPlatformHelper_stopVPN, IOSPlatformHelper_isVPNConnected
 */
bool IOSPlatformHelper_startVPN(IOSPlatformHelperRef helper);

/**
 * @brief 停止VPN连接
 * @param helper Helper实例引用
 * @return bool 成功返回true，失败返回false
 *
 * @details 断开VPN连接
 * - 调用NEVPNManager.connection.stopVPNTunnel
 * - 不删除VPN配置文件
 * - 可以再次调用startVPN重新连接
 *
 * @see IOSPlatformHelper_startVPN, IOSPlatformHelper_isVPNConnected
 */
bool IOSPlatformHelper_stopVPN(IOSPlatformHelperRef helper);

/**
 * @brief 检查VPN是否已连接
 * @param helper Helper实例引用
 * @return bool 已连接返回true，未连接返回false
 *
 * @details 查询VPN连接状态
 * - 获取NEVPNManager.connection.status
 * - 状态值：Invalid(0), Disconnected(1), Connecting(2), Connected(3), Reasserting(4), Disconnecting(5)
 * - 仅当状态为Connected(3)时返回true
 *
 * @see IOSPlatformHelper_startVPN, IOSPlatformHelper_stopVPN
 */
bool IOSPlatformHelper_isVPNConnected(IOSPlatformHelperRef helper);

/**
 * @brief 删除VPN配置文件
 * @param helper Helper实例引用
 * @return bool 成功返回true，失败返回false
 *
 * @details 从系统中删除VPN配置
 * - 如果VPN正在连接，先停止连接
 * - 调用NEVPNManager.removeFromPreferences
 * - 删除后需要重新配置才能使用VPN
 *
 * @see IOSPlatformHelper_configureVPN
 */
bool IOSPlatformHelper_removeVPNProfile(IOSPlatformHelperRef helper);

// ============================================================================
// 通知管理
// ============================================================================

/**
 * @brief 请求通知权限
 * @param helper Helper实例引用
 * @return bool 成功返回true，失败返回false
 *
 * @details 请求iOS通知权限
 * - 调用UNUserNotificationCenter.requestAuthorization
 * - 显示系统权限对话框
 * - 请求alert、sound、badge权限
 *
 * @note
 * - iOS 10+需要显式请求权限
 * - 用户拒绝后需要引导到设置中开启
 * - 每个应用只需请求一次
 *
 * @see IOSPlatformHelper_hasNotificationPermission, IOSPlatformHelper_showNotification
 */
bool IOSPlatformHelper_requestNotificationPermission(IOSPlatformHelperRef helper);

/**
 * @brief 检查是否已有通知权限
 * @param helper Helper实例引用
 * @return bool 有权限返回true，无权限返回false
 *
 * @details 查询通知权限状态
 * - 调用UNUserNotificationCenter.getNotificationSettings
 * - 检查authorizationStatus是否为authorized
 *
 * @see IOSPlatformHelper_requestNotificationPermission
 */
bool IOSPlatformHelper_hasNotificationPermission(IOSPlatformHelperRef helper);

/**
 * @brief 显示通知
 * @param helper Helper实例引用
 * @param title 通知标题（UTF-8编码）
 * @param message 通知内容（UTF-8编码）
 *
 * @details 发送iOS本地通知
 * - 创建UNMutableNotificationContent
 * - 设置title和body
 * - 使用UNUserNotificationCenter发送
 *
 * @note
 * - 需要先获得通知权限
 * - 如果无权限，通知不会显示
 * - 应用在前台时通知行为可能不同
 *
 * @see IOSPlatformHelper_requestNotificationPermission, IOSPlatformHelper_hasNotificationPermission
 */
void IOSPlatformHelper_showNotification(IOSPlatformHelperRef helper,
                                        const char* title,
                                        const char* message);

// ============================================================================
// 设备信息
// ============================================================================

/**
 * @brief 获取设备唯一标识符
 * @param helper Helper实例引用
 * @return const char* 设备ID字符串（UTF-8编码），失败返回空字符串
 *
 * @details 获取iOS设备的唯一标识符
 * - 使用UIDevice.identifierForVendor（IDFV）
 * - 返回UUID字符串格式
 * - IDFV在同一厂商的应用间相同
 *
 * @note
 * - 返回的字符串由helper管理，不要free
 * - 应用卸载后重装，IDFV会变化
 * - IDFV在同一设备、同一厂商的所有应用间共享
 *
 * @see IOSPlatformHelper_getDeviceModel
 */
const char* IOSPlatformHelper_getDeviceId(IOSPlatformHelperRef helper);

/**
 * @brief 获取设备型号名称
 * @param helper Helper实例引用
 * @return const char* 设备型号字符串（UTF-8编码），失败返回空字符串
 *
 * @details 获取iOS设备型号
 * - 使用UIDevice.model（如"iPhone", "iPad"）
 * - 或通过sysctlbyname获取详细型号（如"iPhone14,2"）
 * - 可选：映射到用户友好名称（如"iPhone 14 Pro"）
 *
 * @note 返回的字符串由helper管理，不要free
 *
 * @see IOSPlatformHelper_getDeviceId
 */
const char* IOSPlatformHelper_getDeviceModel(IOSPlatformHelperRef helper);

// ============================================================================
// App Group 共享数据
// ============================================================================

/**
 * @brief 从 App Group SharedDefaults 读取数据
 * @param helper Helper实例引用
 * @param key 键名
 * @return const char* 值字符串，失败返回空字符串
 */
const char* IOSPlatformHelper_readFromSharedDefaults(IOSPlatformHelperRef helper, const char* key);

/**
 * @brief 保存数据到 App Group SharedDefaults
 * @param helper Helper实例引用
 * @param key 键名
 * @param value 值
 * @return bool 成功返回 true
 */
bool IOSPlatformHelper_saveToSharedDefaults(IOSPlatformHelperRef helper, const char* key, const char* value);

#ifdef __cplusplus
}

// ============================================================================
// C++ 包装类
// ============================================================================

/**
 * @class IOSPlatformHelper
 * @brief C++包装类，提供面向对象的接口
 *
 * @details 将C风格的函数接口封装为C++静态方法
 * - 简化C++代码中的调用
 * - 保持与C接口的兼容性
 * - 所有方法都是静态方法，直接调用C函数
 *
 * @note
 * - 仅在C++环境中可用
 * - 所有方法都是静态方法，无需实例化
 * - helper参数为void*类型（不透明指针）
 *
 * @example
 * @code
 * // 创建helper
 * void* helper = IOSPlatformHelper::create();
 *
 * // 请求权限
 * if (IOSPlatformHelper::requestVPNPermission(helper)) {
 *     // 配置VPN
 *     const char* config = "{\"serverAddress\":\"vpn.example.com\"}";
 *     IOSPlatformHelper::configureVPN(helper, config);
 *
 *     // 启动VPN
 *     IOSPlatformHelper::startVPN(helper);
 * }
 *
 * // 销毁helper
 * IOSPlatformHelper::destroy(helper);
 * @endcode
 */
class IOSPlatformHelper {
public:
    /**
     * @brief 创建Helper实例
     * @return void* Helper实例指针
     * @see IOSPlatformHelper_create
     */
    static void* create() {
        return IOSPlatformHelper_create();
    }

    /**
     * @brief 销毁Helper实例
     * @param helper Helper实例指针
     * @see IOSPlatformHelper_destroy
     */
    static void destroy(void* helper) {
        IOSPlatformHelper_destroy((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 请求VPN权限
     * @param helper Helper实例指针
     * @return bool 成功返回true
     * @see IOSPlatformHelper_requestVPNPermission
     */
    static bool requestVPNPermission(void* helper) {
        return IOSPlatformHelper_requestVPNPermission((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 检查VPN权限
     * @param helper Helper实例指针
     * @return bool 有权限返回true
     * @see IOSPlatformHelper_hasVPNPermission
     */
    static bool hasVPNPermission(void* helper) {
        return IOSPlatformHelper_hasVPNPermission((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 配置VPN
     * @param helper Helper实例指针
     * @param config VPN配置JSON字符串
     * @return bool 成功返回true
     * @see IOSPlatformHelper_configureVPN
     */
    static bool configureVPN(void* helper, const char* config) {
        return IOSPlatformHelper_configureVPN((IOSPlatformHelperRef)helper, config);
    }

    /**
     * @brief 启动VPN
     * @param helper Helper实例指针
     * @return bool 成功返回true
     * @see IOSPlatformHelper_startVPN
     */
    static bool startVPN(void* helper) {
        return IOSPlatformHelper_startVPN((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 停止VPN
     * @param helper Helper实例指针
     * @return bool 成功返回true
     * @see IOSPlatformHelper_stopVPN
     */
    static bool stopVPN(void* helper) {
        return IOSPlatformHelper_stopVPN((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 检查VPN连接状态
     * @param helper Helper实例指针
     * @return bool 已连接返回true
     * @see IOSPlatformHelper_isVPNConnected
     */
    static bool isVPNConnected(void* helper) {
        return IOSPlatformHelper_isVPNConnected((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 删除VPN配置
     * @param helper Helper实例指针
     * @return bool 成功返回true
     * @see IOSPlatformHelper_removeVPNProfile
     */
    static bool removeVPNProfile(void* helper) {
        return IOSPlatformHelper_removeVPNProfile((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 请求通知权限
     * @param helper Helper实例指针
     * @return bool 成功返回true
     * @see IOSPlatformHelper_requestNotificationPermission
     */
    static bool requestNotificationPermission(void* helper) {
        return IOSPlatformHelper_requestNotificationPermission((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 检查通知权限
     * @param helper Helper实例指针
     * @return bool 有权限返回true
     * @see IOSPlatformHelper_hasNotificationPermission
     */
    static bool hasNotificationPermission(void* helper) {
        return IOSPlatformHelper_hasNotificationPermission((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 显示通知
     * @param helper Helper实例指针
     * @param title 通知标题
     * @param message 通知内容
     * @see IOSPlatformHelper_showNotification
     */
    static void showNotification(void* helper, const char* title, const char* message) {
        IOSPlatformHelper_showNotification((IOSPlatformHelperRef)helper, title, message);
    }

    /**
     * @brief 获取设备ID
     * @param helper Helper实例指针
     * @return const char* 设备ID字符串
     * @see IOSPlatformHelper_getDeviceId
     */
    static const char* getDeviceId(void* helper) {
        return IOSPlatformHelper_getDeviceId((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 获取设备型号
     * @param helper Helper实例指针
     * @return const char* 设备型号字符串
     * @see IOSPlatformHelper_getDeviceModel
     */
    static const char* getDeviceModel(void* helper) {
        return IOSPlatformHelper_getDeviceModel((IOSPlatformHelperRef)helper);
    }

    /**
     * @brief 从共享 UserDefaults 读取数据
     * @param helper Helper实例指针
     * @param key 键名
     * @return const char* 值字符串
     */
    static const char* readFromSharedDefaults(void* helper, const char* key) {
        return IOSPlatformHelper_readFromSharedDefaults((IOSPlatformHelperRef)helper, key);
    }

    /**
     * @brief 保存数据到共享 UserDefaults
     * @param helper Helper实例指针
     * @param key 键名
     * @param value 值
     * @return bool 成功返回 true
     */
    static bool saveToSharedDefaults(void* helper, const char* key, const char* value) {
        return IOSPlatformHelper_saveToSharedDefaults((IOSPlatformHelperRef)helper, key, value);
    }
};

#endif // __cplusplus

#endif // IOSPLATFORMHELPER_H
