/**
 * @file IOSPlatform.h
 * @brief iOS平台实现头文件
 * @details 实现iOS平台特定的VPN功能，使用NetworkExtension框架
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef IOSPLATFORM_H
#define IOSPLATFORM_H

#include "PlatformInterface.h"
#include <QString>

/**
 * @class IOSPlatform
 * @brief iOS平台实现类
 *
 * @details 提供iOS平台的VPN功能实现
 * - VPN管理：使用iOS NetworkExtension框架
 * - 权限管理：需要用户授权VPN配置权限
 * - 通知功能：使用UserNotifications框架
 * - 设备信息：获取设备标识和型号
 * - 系统限制：iOS对VPN有严格的安全限制
 *
 * iOS VPN架构：
 * ```
 * JinGo App (Qt/C++)
 *   ↓ Objective-C Bridge (IOSPlatformHelper)
 * NetworkExtension Framework
 *   ↓ iOS System
 * VPN Configuration Profile
 *   ↓ Network Stack
 * iOS VPN Subsystem
 * ```
 *
 * 主要特点：
 * - NetworkExtension：iOS官方VPN框架（iOS 8+）
 * - VPN配置文件：通过NEVPNManager管理VPN配置
 * - 沙盒限制：受iOS沙盒安全模型限制
 * - 权限请求：需要用户显式授权VPN配置
 * - 后台运行：VPN可在后台保持连接
 * - 通知权限：需要单独请求通知权限
 *
 * NetworkExtension框架支持：
 * - Personal VPN：个人VPN配置
 * - IKEv2：Internet Key Exchange v2协议
 * - IPsec：IP安全协议
 * - 自定义VPN：通过Network Extension Provider
 *
 * 依赖组件：
 * - NetworkExtension.framework：VPN功能
 * - UserNotifications.framework：通知功能
 * - UIKit.framework：设备信息
 * - 版本支持：iOS 12.0及以上
 *
 * @note
 * - 仅在iOS平台编译和使用
 * - 需要在Info.plist中声明VPN权限
 * - 需要有效的开发者证书和配置文件
 * - iOS不支持开机自启动（系统限制）
 * - iOS不支持系统代理修改（沙盒限制）
 *
 * @example
 * @code
 * IOSPlatform* platform = new IOSPlatform();
 *
 * // 请求VPN权限
 * if (platform->requestVPNPermission()) {
 *     // 配置并启动VPN
 *     QString serverConfig = "{...}"; // VPN配置JSON
 *     if (platform->startVPN(serverConfig)) {
 *         qDebug() << "VPN started successfully";
 *     }
 * }
 *
 * // 检查VPN连接状态
 * if (platform->isVPNConnected()) {
 *     qDebug() << "VPN is connected";
 * }
 * @endcode
 */
class IOSPlatform : public PlatformInterface
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     *
     * @details 初始化iOS平台实现
     * - 初始化成员变量
     * - 创建IOSPlatformHelper桥接对象
     * - 调用initializeIOSComponents()
     */
    explicit IOSPlatform(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     *
     * @details 清理资源
     * - 停止VPN连接
     * - 销毁IOSPlatformHelper
     * - 释放iOS对象
     */
    ~IOSPlatform() override;

    // ========================================================================
    // VPN 权限
    // ========================================================================

    /**
     * @brief 请求VPN权限
     * @return bool 成功返回true，失败返回false
     *
     * @details 请求iOS VPN配置权限
     * - 显示系统VPN权限对话框
     * - 用户授权后可以创建VPN配置
     * - 用户拒绝或已授权其他VPN返回false
     *
     * @note
     * - 此操作需要用户交互
     * - 如果已授权，直接返回true
     * - iOS系统同时只能有一个VPN配置
     *
     * @see hasVPNPermission
     */
    bool requestVPNPermission() override;

    /**
     * @brief 检查是否有VPN权限
     * @return bool 有权限返回true，无权限返回false
     *
     * @details 检查应用是否已获得VPN配置权限
     * - 通过NEVPNManager检查权限状态
     *
     * @see requestVPNPermission
     */
    bool hasVPNPermission() override;

    // ========================================================================
    // 系统功能（iOS限制）
    // ========================================================================

    /**
     * @brief 设置系统代理
     * @param host 代理服务器地址（未使用）
     * @param port 代理服务器端口（未使用）
     * @return bool 始终返回false
     *
     * @details iOS不支持修改系统代理
     * - iOS沙盒限制，应用无法修改系统网络设置
     * - 此方法仅为满足接口要求，实际不执行任何操作
     *
     * @note iOS系统限制：无法实现此功能
     */
    bool setupSystemProxy(const QString& host, int port) override;

    /**
     * @brief 清除系统代理
     * @return bool 始终返回false
     *
     * @details iOS不支持修改系统代理
     * - 此方法仅为满足接口要求
     *
     * @note iOS系统限制：无法实现此功能
     */
    bool clearSystemProxy() override;

    /**
     * @brief 设置开机自启动
     * @param enable true启用，false禁用（未使用）
     * @return bool 始终返回false
     *
     * @details iOS不支持应用开机自启动
     * - iOS系统限制，应用无法在启动时自动运行
     * - 此方法仅为满足接口要求
     *
     * @note iOS系统限制：无法实现此功能
     */
    bool setAutoStart(bool enable) override;

    /**
     * @brief 检查是否已启用开机自启动
     * @return bool 始终返回false
     *
     * @details iOS不支持开机自启动
     *
     * @note iOS系统限制：无法实现此功能
     */
    bool isAutoStartEnabled() override;

    // ========================================================================
    // 通知
    // ========================================================================

    /**
     * @brief 显示系统通知
     * @param title 通知标题
     * @param message 通知内容
     *
     * @details 显示iOS通知
     * - 使用UserNotifications框架（iOS 10+）
     * - 需要先请求通知权限（requestNotificationPermission）
     * - 通知会显示在通知中心
     *
     * @note 需要通知权限，否则通知不会显示
     *
     * @see requestNotificationPermission, hasNotificationPermission
     */
    void showNotification(const QString& title, const QString& message) override;

    // ========================================================================
    // 设备信息
    // ========================================================================

    /**
     * @brief 获取设备ID
     * @return QString 设备唯一标识符
     *
     * @details 返回iOS设备的唯一标识符
     * - 使用identifierForVendor（应用厂商特定ID）
     * - iOS 6+：IDFV（Identifier For Vendor）
     * - 应用重装后不变，但卸载后重装会变化
     *
     * @note
     * - IDFV在同一厂商的应用间相同
     * - 应用卸载后重装，IDFV会变化
     */
    QString getDeviceId() override;

    /**
     * @brief 获取平台名称
     * @return QString 平台名称（"iOS"）
     */
    QString getPlatformName() override { return "iOS"; }

    // ========================================================================
    // iOS 特有方法
    // ========================================================================

    /**
     * @brief 获取iOS版本
     * @return QString iOS系统版本（例如："16.4", "17.0"）
     *
     * @details 返回iOS操作系统版本
     * - 格式：主版本.次版本.补丁版本
     * - 例如：iOS 16.4.1返回"16.4.1"
     * - 通过UIDevice.systemVersion获取
     */
    QString osVersion() const;

    /**
     * @brief 获取平台名称（别名）
     * @return QString 平台名称（"iOS"）
     *
     * @details 与getPlatformName()功能相同
     *
     * @see getPlatformName
     */
    QString platformName() const { return "iOS"; }

    // ========================================================================
    // VPN 控制
    // ========================================================================

    /**
     * @brief 启动VPN连接
     * @param serverConfig VPN服务器配置（JSON格式）
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置并启动iOS VPN连接
     * - 创建VPN配置文件（NEVPNProtocolIKEv2或自定义）
     * - 保存配置到系统
     * - 启动VPN连接
     *
     * @note
     * - 需要先获得VPN权限
     * - serverConfig应包含服务器地址、认证信息等
     *
     * @see stopVPN, isVPNConnected, configureVPNProfile
     */
    bool startVPN(const QString& serverConfig);

    /**
     * @brief 停止VPN连接
     * @return bool 成功返回true，失败返回false
     *
     * @details 断开iOS VPN连接
     * - 停止当前VPN会话
     * - 不删除VPN配置文件
     *
     * @see startVPN, isVPNConnected
     */
    bool stopVPN();

    /**
     * @brief 检查VPN是否已连接
     * @return bool 已连接返回true，未连接返回false
     *
     * @details 检查VPN连接状态
     * - 通过NEVPNManager获取连接状态
     * - 状态包括：未连接、正在连接、已连接、正在断开
     *
     * @see startVPN, stopVPN
     */
    bool isVPNConnected();

    /**
     * @brief 获取设备型号
     * @return QString 设备型号名称
     *
     * @details 返回iOS设备型号
     * - 例如："iPhone 14 Pro", "iPad Air"
     * - 通过UIDevice.model和硬件标识符获取
     *
     * @note 返回用户友好的型号名称，而非硬件标识符
     */
    QString getDeviceModel() const;

    // ========================================================================
    // TUN 设备管理（PlatformInterface要求实现，iOS不支持）
    // ========================================================================

    /**
     * @brief 创建TUN设备（iOS不支持）
     * @return bool 始终返回false
     * @note iOS通过NetworkExtension管理TUN设备，应用无法直接创建
     */
    bool createTunDevice(const QString& deviceName) override;

    /**
     * @brief 关闭TUN设备（iOS不支持）
     * @return bool 始终返回false
     */
    bool closeTunDevice() override;

    /**
     * @brief 配置TUN设备（iOS不支持）
     * @return bool 始终返回false
     */
    bool configureTunDevice(const TunDeviceConfig& config) override;

    /**
     * @brief 读取数据包（iOS不支持）
     * @return QByteArray 始终返回空数组
     */
    QByteArray readPacket() override;

    /**
     * @brief 写入数据包（iOS不支持）
     * @return bool 始终返回false
     */
    bool writePacket(const QByteArray& packet) override;

    /**
     * @brief 获取TUN文件描述符（iOS不支持）
     * @return int 始终返回-1
     */
    int getTunFileDescriptor() override;

    /**
     * @brief 检查TUN设备是否已创建（iOS不支持）
     * @return bool 始终返回false
     */
    bool isTunDeviceCreated() const override;

    // ========================================================================
    // App Group 共享数据
    // ========================================================================

    /**
     * @brief 从共享 UserDefaults 读取数据
     * @param key 键名
     * @param defaultValue 默认值
     * @return QString 读取的值或默认值
     *
     * @details 从 App Group 共享容器的 UserDefaults 读取数据
     * - 用于主应用读取 Network Extension 写入的数据
     * - App Group: group.work.opine.jingo
     */
    QString readFromSharedDefaults(const QString& key, const QString& defaultValue = QString()) override;

    /**
     * @brief 保存数据到共享 UserDefaults
     * @param key 键名
     * @param value 值
     * @return bool 成功返回 true
     */
    bool saveToSharedDefaults(const QString& key, const QString& value) override;

    // ========================================================================
    // 路由管理（PlatformInterface要求实现，iOS不支持）
    // ========================================================================

    /**
     * @brief 添加路由（iOS不支持）
     * @return bool 始终返回false
     * @note iOS通过NetworkExtension配置路由，应用无法直接操作
     */
    bool addRoute(const RouteConfig& route) override;

    /**
     * @brief 删除路由（iOS不支持）
     * @return bool 始终返回false
     */
    bool deleteRoute(const RouteConfig& route) override;

private:
    // ========================================================================
    // 成员变量
    // ========================================================================

    void* m_iosHelper;           ///< IOSPlatformHelper桥接对象（不透明指针）

    // ========================================================================
    // 私有方法
    // ========================================================================

    /**
     * @brief 初始化iOS组件
     *
     * @details 初始化iOS平台相关组件
     * - 创建IOSPlatformHelper实例
     * - 初始化NetworkExtension
     * - 设置VPN状态监听
     */
    void initializeIOSComponents();

    /**
     * @brief 配置VPN配置文件
     * @param config VPN配置（JSON格式）
     * @return bool 成功返回true，失败返回false
     *
     * @details 创建或更新VPN配置文件
     * - 解析JSON配置
     * - 创建NEVPNProtocol对象
     * - 保存到NEVPNManager
     *
     * @see startVPN, removeVPNProfile
     */
    bool configureVPNProfile(const QString& config);

    /**
     * @brief 删除VPN配置文件
     * @return bool 成功返回true，失败返回false
     *
     * @details 从系统中删除VPN配置
     * - 停止VPN连接（如果正在运行）
     * - 删除NEVPNManager中的配置
     *
     * @see configureVPNProfile
     */
    bool removeVPNProfile();

    /**
     * @brief 请求通知权限
     * @return bool 成功返回true，失败返回false
     *
     * @details 请求iOS通知权限
     * - 显示系统权限对话框
     * - 用户授权后可以发送通知
     *
     * @note
     * - iOS 10+需要显式请求权限
     * - 用户拒绝后需要引导到设置中开启
     *
     * @see hasNotificationPermission, showNotification
     */
    bool requestNotificationPermission();

    /**
     * @brief 检查是否有通知权限
     * @return bool 有权限返回true，无权限返回false
     *
     * @details 检查应用是否已获得通知权限
     * - 通过UNUserNotificationCenter查询权限状态
     *
     * @see requestNotificationPermission
     */
    bool hasNotificationPermission();
};

#endif // IOSPLATFORM_H
