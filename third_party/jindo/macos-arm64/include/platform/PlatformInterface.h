/**
 * @file PlatformInterface.h
 * @brief 平台接口头文件
 * @details 定义跨平台VPN功能的抽象接口，支持Windows/macOS/Linux/iOS/Android
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef PLATFORMINTERFACE_H
#define PLATFORMINTERFACE_H

#include <QObject>
#include <QString>
#include <QByteArray>

// ============================================================================
// 枚举和数据结构
// ============================================================================

/**
 * @enum PlatformError
 * @brief 平台操作错误码
 *
 * @details 定义平台相关操作可能出现的错误类型
 */
enum class PlatformError {
    Success = 0,           ///< 操作成功
    PermissionDenied,      ///< 权限被拒绝
    DeviceNotFound,        ///< 设备未找到
    DeviceAlreadyExists,   ///< 设备已存在
    ConfigurationFailed,   ///< 配置失败
    NetworkError,          ///< 网络错误
    NotSupported,          ///< 功能不支持
    InternalError,         ///< 内部错误
    TimeoutError           ///< 超时错误
};

/**
 * @struct TunDeviceConfig
 * @brief TUN设备配置结构
 *
 * @details 用于配置TUN虚拟网卡的参数
 */
struct TunDeviceConfig {
    QString ipAddress;       ///< IP地址（例如: "172.19.0.1"）
    QString netmask;         ///< 子网掩码（例如: "255.255.255.0"）
    QString gateway;         ///< 网关地址（例如: "172.19.0.254"）
    int mtu = 1500;          ///< 最大传输单元（字节）
    bool persistMode = false; ///< 是否持久模式
    QString proxyServerHost;  ///< 代理服务器域名（用于xray连接的SNI）
    QString proxyServerIP;    ///< 代理服务器IP（用于路由排除，避免循环）

    // Android 分应用代理配置
    int perAppProxyMode = 0;      ///< 分应用代理模式 (0=禁用, 1=白名单, 2=黑名单)
    QStringList perAppProxyList;  ///< 分应用代理应用列表（包名）

    // 所有服务器IP列表（用于路由排除，避免VPN流量循环）
    QStringList allServerIPs;     ///< 所有代理服务器的IP地址

    /**
     * @brief 默认构造函数
     */
    TunDeviceConfig() = default;

    /**
     * @brief 构造函数
     * @param ip IP地址
     * @param mask 子网掩码
     * @param mtuValue MTU值
     */
    TunDeviceConfig(const QString& ip, const QString& mask, int mtuValue = 1500)
        : ipAddress(ip), netmask(mask), mtu(mtuValue) {}
};

/**
 * @struct RouteConfig
 * @brief 路由配置结构
 *
 * @details 用于配置网络路由的参数
 */
struct RouteConfig {
    QString destination;     ///< 目标网络（例如: "0.0.0.0"）
    QString netmask;         ///< 子网掩码（例如: "0.0.0.0"）
    QString gateway;         ///< 网关地址
    int metric = 0;          ///< 路由优先级（值越小优先级越高）

    /**
     * @brief 默认构造函数
     */
    RouteConfig() = default;

    /**
     * @brief 构造函数
     * @param dest 目标网络
     * @param mask 子网掩码
     * @param gw 网关地址
     */
    RouteConfig(const QString& dest, const QString& mask, const QString& gw)
        : destination(dest), netmask(mask), gateway(gw) {}
};

// ============================================================================
// PlatformInterface 类定义
// ============================================================================

/**
 * @class PlatformInterface
 * @brief 跨平台功能抽象接口
 *
 * @details 定义VPN应用需要的所有平台相关功能的抽象接口
 * - TUN设备管理：创建、配置、读写虚拟网卡
 * - VPN权限管理：请求和检查VPN权限
 * - 路由管理：添加和删除系统路由
 * - 系统代理：设置和清除系统代理配置
 * - 开机自启动：管理应用自启动
 * - 通知：显示系统通知
 * - 设备信息：获取设备ID和平台名称
 *
 * 平台实现：
 * - AndroidPlatform：Android平台实现
 * - IOSPlatform：iOS平台实现
 * - MacOSPlatform：macOS平台实现
 * - WindowsPlatform：Windows平台实现
 * - LinuxPlatform：Linux平台实现
 *
 * 使用方式：
 * - 通过工厂方法create()获取平台特定实例
 * - 所有虚函数必须在子类中实现
 * - 错误信息通过lastError()和lastErrorString()获取
 *
 * @note
 * - 这是一个抽象基类，不能直接实例化
 * - 所有虚函数都是纯虚函数，必须在子类实现
 * - 子类应调用setError()和clearError()管理错误状态
 *
 * @example
 * @code
 * // 创建平台实例
 * PlatformInterface* platform = PlatformInterface::create();
 *
 * // 请求VPN权限
 * if (platform->requestVPNPermission()) {
 *     // 创建TUN设备
 *     if (platform->createTunDevice("jingo0")) {
 *         // 配置TUN设备
 *         TunDeviceConfig config("172.19.0.1", "255.255.255.0", 1500);
 *         platform->configureTunDevice(config);
 *     }
 * }
 * @endcode
 */
class PlatformInterface : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     */
    explicit PlatformInterface(QObject* parent = nullptr) : QObject(parent) {}

    /**
     * @brief 虚析构函数
     */
    virtual ~PlatformInterface() = default;

    // ========================================================================
    // 工厂方法
    // ========================================================================

    /**
     * @brief 创建平台特定实例
     * @param parent 父对象
     * @return PlatformInterface* 平台实例指针
     *
     * @details 根据当前操作系统创建相应的平台实例
     * - Android: 返回AndroidPlatform
     * - iOS: 返回IOSPlatform
     * - macOS: 返回MacOSPlatform
     * - Windows: 返回WindowsPlatform
     * - Linux: 返回LinuxPlatform
     *
     * @note 调用者负责释放返回的对象
     */
    static PlatformInterface* create(QObject* parent = nullptr);

    // ========================================================================
    // VPN 权限管理
    // ========================================================================

    /**
     * @brief 请求VPN权限
     * @return bool 成功返回true，失败返回false
     *
     * @details 向系统请求VPN权限
     * - Android/iOS: 显示系统VPN权限对话框
     * - Windows/macOS/Linux: 检查管理员权限
     *
     * @note 某些平台可能需要用户交互
     */
    virtual bool requestVPNPermission() = 0;

    /**
     * @brief 检查是否有VPN权限
     * @return bool 有权限返回true，无权限返回false
     *
     * @details 检查应用是否已获得VPN权限
     */
    virtual bool hasVPNPermission() = 0;

    // ========================================================================
    // TUN 设备管理
    // ========================================================================

    /**
     * @brief 创建TUN设备
     * @param deviceName 设备名称（例如: "jingo0", "utun0"）
     * @return bool 成功返回true，失败返回false
     *
     * @details 创建TUN虚拟网卡
     * - 需要VPN权限
     * - 创建后需要配置IP地址和路由
     *
     * @see configureTunDevice
     */
    virtual bool createTunDevice(const QString& deviceName) = 0;

    /**
     * @brief 关闭TUN设备
     * @return bool 成功返回true，失败返回false
     *
     * @details 关闭并销毁TUN设备
     * - 清理路由配置
     * - 释放系统资源
     */
    virtual bool closeTunDevice() = 0;

    /**
     * @brief 配置TUN设备
     * @param config TUN设备配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置TUN设备的IP地址、子网掩码和MTU
     *
     * @see TunDeviceConfig
     */
    virtual bool configureTunDevice(const TunDeviceConfig& config) = 0;

    /**
     * @brief 配置TUN设备（兼容旧接口）
     * @param ipAddress IP地址
     * @param netmask 子网掩码
     * @param mtu MTU值
     * @return bool 成功返回true，失败返回false
     *
     * @details 这是兼容旧代码的便利方法，内部调用新接口
     *
     * @see configureTunDevice(const TunDeviceConfig&)
     */
    bool configureTunDevice(const QString& ipAddress, const QString& netmask, int mtu = 1500) {
        TunDeviceConfig config(ipAddress, netmask, mtu);
        return configureTunDevice(config);
    }

    /**
     * @brief 从TUN设备读取数据包
     * @return QByteArray 数据包内容，失败返回空数组
     *
     * @details 从TUN设备读取一个IP数据包
     * - 阻塞操作，直到有数据可读或发生错误
     * - 返回完整的IP数据包（包括IP头）
     */
    virtual QByteArray readPacket() = 0;

    /**
     * @brief 向TUN设备写入数据包
     * @param packet 数据包内容
     * @return bool 成功返回true，失败返回false
     *
     * @details 向TUN设备写入一个IP数据包
     * - packet应包含完整的IP数据包
     */
    virtual bool writePacket(const QByteArray& packet) = 0;

    // ========================================================================
    // 路由管理
    // ========================================================================

    /**
     * @brief 添加路由
     * @param route 路由配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 向系统路由表添加一条路由
     *
     * @see RouteConfig
     */
    virtual bool addRoute(const RouteConfig& route) = 0;

    /**
     * @brief 删除路由
     * @param route 路由配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 从系统路由表删除一条路由
     */
    virtual bool deleteRoute(const RouteConfig& route) = 0;

    /**
     * @brief 添加路由（兼容旧接口）
     * @param destination 目标网络
     * @param netmask 子网掩码
     * @param gateway 网关地址
     * @return bool 成功返回true，失败返回false
     */
    bool addRoute(const QString& destination, const QString& netmask, const QString& gateway) {
        RouteConfig route(destination, netmask, gateway);
        return addRoute(route);
    }

    /**
     * @brief 删除路由（兼容旧接口）
     * @param destination 目标网络
     * @param netmask 子网掩码
     * @return bool 成功返回true，失败返回false
     */
    bool deleteRoute(const QString& destination, const QString& netmask) {
        RouteConfig route(destination, netmask, "");
        return deleteRoute(route);
    }

    // ========================================================================
    // TUN 设备状态查询
    // ========================================================================

    /**
     * @brief 获取TUN设备文件描述符
     * @return int 文件描述符，失败返回-1
     *
     * @details 获取TUN设备的底层文件描述符
     * - 可用于select/poll等系统调用
     * - 某些平台可能不支持（返回-1）
     */
    virtual int getTunFileDescriptor() = 0;

    /**
     * @brief 检查TUN设备是否已创建
     * @return bool 已创建返回true，否则返回false
     */
    virtual bool isTunDeviceCreated() const = 0;

    /**
     * @brief 获取TUN设备名称
     * @return QString 设备名称，未创建返回空字符串
     */
    virtual QString getTunDeviceName() const { return QString(); }

    // ========================================================================
    // 设备统计信息
    // ========================================================================

    /**
     * @brief 获取接收字节数
     * @return quint64 接收的字节数
     */
    virtual quint64 getBytesReceived() const { return 0; }

    /**
     * @brief 获取发送字节数
     * @return quint64 发送的字节数
     */
    virtual quint64 getBytesSent() const { return 0; }

    /**
     * @brief 重置统计信息
     */
    virtual void resetStatistics() {}

    // ========================================================================
    // 系统代理
    // ========================================================================

    /**
     * @brief 设置系统代理
     * @param host 代理服务器地址
     * @param socksPort SOCKS5代理端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置系统的SOCKS5代理
     * - 使用SOCKS5协议代理所有流量
     * - 影响所有使用系统代理的应用
     * - 某些平台可能不支持
     */
    virtual bool setupSystemProxy(const QString& host, int socksPort) = 0;

    /**
     * @brief 清除系统代理
     * @return bool 成功返回true，失败返回false
     *
     * @details 移除系统代理配置
     */
    virtual bool clearSystemProxy() = 0;

    // ========================================================================
    // 开机自启动
    // ========================================================================

    /**
     * @brief 设置开机自启动
     * @param enable true启用，false禁用
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置应用是否开机自启动
     * - Windows: 注册表启动项
     * - macOS: LaunchAgent
     * - Linux: systemd或autostart
     */
    virtual bool setAutoStart(bool enable) = 0;

    /**
     * @brief 检查是否已启用开机自启动
     * @return bool 已启用返回true，未启用返回false
     */
    virtual bool isAutoStartEnabled() = 0;

    // ========================================================================
    // 通知
    // ========================================================================

    /**
     * @brief 显示系统通知
     * @param title 通知标题
     * @param message 通知内容
     *
     * @details 显示系统托盘或通知中心的通知
     */
    virtual void showNotification(const QString& title, const QString& message) = 0;

    // ========================================================================
    // 设备信息
    // ========================================================================

    /**
     * @brief 获取设备ID
     * @return QString 设备唯一标识符
     *
     * @details 获取设备的唯一标识
     * - Android: Android ID
     * - iOS: IDFV
     * - 桌面: 机器ID或MAC地址
     */
    virtual QString getDeviceId() = 0;

    /**
     * @brief 获取平台名称
     * @return QString 平台名称
     *
     * @details 返回当前平台的名称
     * - 例如: "Android", "iOS", "Windows", "macOS", "Linux"
     */
    virtual QString getPlatformName() = 0;

    // ========================================================================
    // 共享存储（App Group / Shared Preferences）
    // ========================================================================

    /**
     * @brief 保存值到共享存储
     * @param key 键名
     * @param value 值
     * @return bool 成功返回true，失败返回false
     *
     * @details 保存键值对到共享存储（用于与 Network Extension 等组件共享数据）
     * - macOS/iOS: NSUserDefaults with App Group
     * - Android: SharedPreferences
     * - 其他平台: QSettings
     */
    virtual bool saveToSharedDefaults(const QString& key, const QString& value) { Q_UNUSED(key); Q_UNUSED(value); return false; }

    /**
     * @brief 从共享存储读取值
     * @param key 键名
     * @param defaultValue 默认值
     * @return QString 读取的值，如果不存在返回默认值
     */
    virtual QString readFromSharedDefaults(const QString& key, const QString& defaultValue = QString()) { Q_UNUSED(key); return defaultValue; }

    // ========================================================================
    // 错误处理
    // ========================================================================

    /**
     * @brief 获取最后的错误码
     * @return PlatformError 错误码
     */
    PlatformError lastError() const { return m_lastError; }

    /**
     * @brief 获取最后的错误描述
     * @return QString 错误描述字符串
     */
    QString lastErrorString() const { return m_lastErrorString; }

protected:
    // ========================================================================
    // 子类辅助方法
    // ========================================================================

    /**
     * @brief 设置错误
     * @param error 错误码
     * @param errorString 错误描述
     *
     * @details 供子类调用以设置错误状态
     * - 自动发出errorOccurred信号
     */
    void setError(PlatformError error, const QString& errorString = QString()) {
        m_lastError = error;
        m_lastErrorString = errorString;
        if (error != PlatformError::Success) {
            emit errorOccurred(error, errorString);
        }
    }

    /**
     * @brief 清除错误
     *
     * @details 重置错误状态为Success
     */
    void clearError() {
        m_lastError = PlatformError::Success;
        m_lastErrorString.clear();
    }

signals:
    /**
     * @brief 通知请求信号
     * @param title 通知标题
     * @param message 通知内容
     */
    void notificationRequested(const QString& title, const QString& message);

    /**
     * @brief TUN数据包接收信号
     * @param packet 数据包内容
     */
    void tunPacketReceived(const QByteArray& packet);

    /**
     * @brief TUN设备错误信号
     * @param error 错误描述
     */
    void tunDeviceError(const QString& error);

    /**
     * @brief 错误发生信号
     * @param error 错误码
     * @param errorString 错误描述
     */
    void errorOccurred(PlatformError error, const QString& errorString);

    /**
     * @brief 统计信息更新信号
     * @param bytesReceived 接收字节数
     * @param bytesSent 发送字节数
     */
    void statisticsUpdated(quint64 bytesReceived, quint64 bytesSent);

private:
    PlatformError m_lastError = PlatformError::Success;  ///< 最后的错误码
    QString m_lastErrorString;                           ///< 最后的错误描述
};

#endif // PLATFORMINTERFACE_H
