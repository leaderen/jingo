/**
 * @file AndroidPlatform.h
 * @brief Android平台实现头文件
 * @details 实现Android平台特定的VPN功能，使用Android VPNService API
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef ANDROIDPLATFORM_H
#define ANDROIDPLATFORM_H

#include "PlatformInterface.h"
#include <QJniObject>

/**
 * @class AndroidPlatform
 * @brief Android平台实现类
 *
 * @details 提供Android平台的VPN功能实现
 * - TUN设备管理：通过Android VpnService API创建和管理TUN设备
 * - VPN权限管理：使用Android权限系统请求和检查VPN权限
 * - 路由管理：通过VpnService配置路由规则
 * - 系统功能：通知、设备ID、开机自启动等
 *
 * Android VPN架构：
 * ```
 * JinGo App (Qt/C++)
 *   ↓ JNI
 * VpnService (Java)
 *   ↓ Android Framework
 * TUN Device (Kernel)
 * ```
 *
 * 主要特点：
 * - 使用VpnService API：Android官方VPN接口
 * - JNI桥接：通过Qt JNI调用Java代码
 * - 权限管理：需要用户授权VPN权限
 * - 流量统计：实时统计上传/下载流量
 *
 * 使用限制：
 * - 需要VPN权限：用户必须在系统对话框中授权
 * - 单一VPN：Android系统同时只能有一个VPN连接
 * - 后台限制：需要前台服务通知以保持运行
 *
 * @note
 * - 仅在Android平台编译和使用
 * - 需要在AndroidManifest.xml中声明VPN权限
 * - 需要实现VpnService的Java代码
 *
 * @example
 * @code
 * AndroidPlatform* platform = new AndroidPlatform();
 *
 * // 请求VPN权限
 * if (platform->requestVPNPermission()) {
 *     // 创建TUN设备
 *     if (platform->createTunDevice("jingo0")) {
 *         // 配置设备
 *         TunDeviceConfig config("172.19.0.1", "255.255.255.0", 1500);
 *         platform->configureTunDevice(config);
 *     }
 * }
 * @endcode
 */
class AndroidPlatform : public PlatformInterface
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     *
     * @details 初始化Android平台实现
     * - 初始化成员变量
     * - 准备JNI环境
     * - 调用initializeAndroidComponents()
     */
    explicit AndroidPlatform(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     *
     * @details 清理资源
     * - 关闭TUN设备
     * - 释放JNI引用
     */
    ~AndroidPlatform() override;

    // ========================================================================
    // TUN 接口实现
    // ========================================================================

    /**
     * @brief 创建TUN设备
     * @param deviceName 设备名称（Android上通常忽略此参数）
     * @return bool 成功返回true，失败返回false
     *
     * @details 通过Android VpnService创建TUN设备
     * - 调用Java层的VpnService.Builder
     * - 配置TUN参数（地址、路由等）
     * - 获取TUN设备的文件描述符
     *
     * @note 需要先获得VPN权限
     *
     * @see configureTunDevice, closeTunDevice
     */
    bool createTunDevice(const QString& deviceName) override;

    /**
     * @brief 关闭TUN设备
     * @return bool 成功返回true，失败返回false
     *
     * @details 关闭VpnService创建的TUN设备
     * - 停止VpnService
     * - 关闭文件描述符
     * - 清理路由配置
     *
     * @see createTunDevice
     */
    bool closeTunDevice() override;

    /**
     * @brief 配置TUN设备
     * @param config TUN设备配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置TUN设备的IP地址和网络参数
     * - 设置TUN设备IP地址
     * - 配置MTU
     * - 添加默认路由（可选）
     *
     * @see TunDeviceConfig
     */
    bool configureTunDevice(const TunDeviceConfig& config) override;

    /**
     * @brief 从TUN设备读取数据包
     * @return QByteArray 数据包内容，失败返回空数组
     *
     * @details 从TUN设备读取IP数据包
     * - 阻塞读取，直到有数据或发生错误
     * - 使用read()系统调用
     * - 自动更新接收字节统计
     *
     * @note 应在独立线程中调用以避免阻塞UI
     */
    QByteArray readPacket() override;

    /**
     * @brief 向TUN设备写入数据包
     * @param packet 数据包内容
     * @return bool 成功返回true，失败返回false
     *
     * @details 向TUN设备写入IP数据包
     * - 使用write()系统调用
     * - 自动更新发送字节统计
     */
    bool writePacket(const QByteArray& packet) override;

    /**
     * @brief 添加路由
     * @param route 路由配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 通过VpnService添加路由规则
     * - Android上需要在Builder中预先配置
     * - 动态添加路由可能需要重建TUN设备
     *
     * @note Android限制：路由需要在创建TUN时配置
     */
    bool addRoute(const RouteConfig& route) override;

    /**
     * @brief 删除路由
     * @param route 路由配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 删除路由规则
     * - Android上可能需要重建TUN设备
     */
    bool deleteRoute(const RouteConfig& route) override;

    /**
     * @brief 获取TUN设备文件描述符
     * @return int 文件描述符，失败返回-1
     *
     * @details 返回VpnService创建的TUN设备的FD
     * - 可用于select/poll等待数据
     */
    int getTunFileDescriptor() override;

    /**
     * @brief 检查TUN设备是否已创建
     * @return bool 已创建返回true，否则返回false
     */
    bool isTunDeviceCreated() const override;

    /**
     * @brief 获取TUN设备名称
     * @return QString 设备名称
     *
     * @details Android上通常返回固定名称（如"tun0"）
     */
    QString getTunDeviceName() const override;

    // ========================================================================
    // 统计信息
    // ========================================================================

    /**
     * @brief 获取接收字节数
     * @return quint64 接收的字节数
     *
     * @details 返回从TUN设备读取的总字节数
     */
    quint64 getBytesReceived() const override;

    /**
     * @brief 获取发送字节数
     * @return quint64 发送的字节数
     *
     * @details 返回向TUN设备写入的总字节数
     */
    quint64 getBytesSent() const override;

    /**
     * @brief 重置统计信息
     *
     * @details 将接收和发送字节数重置为0
     */
    void resetStatistics() override;

    // ========================================================================
    // VPN 权限
    // ========================================================================

    /**
     * @brief 请求VPN权限
     * @return bool 成功返回true，失败返回false
     *
     * @details 请求Android VPN权限
     * - 显示系统VPN权限对话框
     * - 用户授权后返回true
     * - 用户拒绝或已授权其他VPN返回false
     *
     * @note
     * - 此操作需要用户交互
     * - 如果已授权，直接返回true
     */
    bool requestVPNPermission() override;

    /**
     * @brief 检查是否有VPN权限
     * @return bool 有权限返回true，无权限返回false
     *
     * @details 检查应用是否已获得VPN权限
     * - 通过VpnService.prepare()检查
     */
    bool hasVPNPermission() override;

    // ========================================================================
    // 系统功能
    // ========================================================================

    /**
     * @brief 设置系统代理
     * @param host 代理服务器地址
     * @param port 代理服务器端口
     * @return bool 成功返回true，失败返回false
     *
     * @details Android上系统代理功能受限
     * - 需要ROOT权限或系统应用
     * - 普通应用无法修改系统代理
     *
     * @note Android限制：通常返回false
     */
    bool setupSystemProxy(const QString& host, int port) override;

    /**
     * @brief 清除系统代理
     * @return bool 成功返回true，失败返回false
     *
     * @note Android限制：通常返回false
     */
    bool clearSystemProxy() override;

    /**
     * @brief 设置开机自启动
     * @param enable true启用，false禁用
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置应用是否开机自启动
     * - 注册BOOT_COMPLETED广播接收器
     * - 需要在Manifest中声明RECEIVE_BOOT_COMPLETED权限
     */
    bool setAutoStart(bool enable) override;

    /**
     * @brief 检查是否已启用开机自启动
     * @return bool 已启用返回true，未启用返回false
     */
    bool isAutoStartEnabled() override;

    /**
     * @brief 显示系统通知
     * @param title 通知标题
     * @param message 通知内容
     *
     * @details 显示Android通知
     * - 使用NotificationManager
     * - 支持Android 8.0+的通知渠道
     */
    void showNotification(const QString& title, const QString& message) override;

    /**
     * @brief 获取设备ID
     * @return QString 设备唯一标识符
     *
     * @details 返回Android设备ID
     * - 使用Android ID（Settings.Secure.ANDROID_ID）
     * - Android 8.0+：应用特定的ID
     *
     * @note Android ID在应用重装后可能变化
     */
    QString getDeviceId() override;

    /**
     * @brief 获取平台名称
     * @return QString 平台名称（"Android"）
     */
    QString getPlatformName() override;

    // ========================================================================
    // Android 特有方法
    // ========================================================================

    /**
     * @brief 获取Android版本
     * @return QString Android版本号（例如："11", "12"）
     *
     * @details 返回Android系统版本
     * - 格式：主版本号
     * - 例如：Android 11返回"11"
     */
    QString getAndroidVersion() const;

    /**
     * @brief 获取已安装应用列表
     * @return QVariantList 应用列表，每项包含 packageName, appName, isSystemApp
     *
     * @details 使用 PackageManager 获取设备上已安装的应用
     */
    Q_INVOKABLE QVariantList getInstalledApps() const;

private:
    // ========================================================================
    // 成员变量
    // ========================================================================

    // TUN 设备相关
    int m_vpnServiceFd;          ///< VpnService创建的文件描述符
    QString m_deviceName;        ///< TUN设备名称
    bool m_tunCreated;           ///< TUN设备是否已创建

    // 统计信息
    quint64 m_bytesReceived;     ///< 接收字节数
    quint64 m_bytesSent;         ///< 发送字节数

    // ========================================================================
    // 私有方法
    // ========================================================================

    /**
     * @brief 初始化Android组件
     *
     * @details 初始化JNI和Android相关组件
     * - 获取Activity引用
     * - 初始化VpnService
     */
    void initializeAndroidComponents();

    /**
     * @brief 获取Android ID
     * @return QString Android设备ID
     *
     * @details 通过JNI获取Settings.Secure.ANDROID_ID
     */
    QString getAndroidId() const;

    /**
     * @brief 获取当前Activity
     * @return QJniObject Activity对象
     *
     * @details 通过Qt JNI获取当前Activity引用
     */
    QJniObject getActivity() const;
};

#endif // ANDROIDPLATFORM_H
