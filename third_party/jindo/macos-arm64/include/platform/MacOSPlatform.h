/**
 * @file MacOSPlatform.h
 * @brief macOS平台实现头文件
 * @details 实现macOS平台特定的VPN功能，使用utun虚拟网络接口
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef MACOSPLATFORM_H
#define MACOSPLATFORM_H

#include "PlatformInterface.h"
#include <QString>
#include <QStringList>
#include <QMap>

/**
 * @class MacOSPlatform
 * @brief macOS平台实现类
 *
 * @details 提供macOS平台的VPN功能实现
 * - TUN设备管理：使用macOS原生utun设备（/dev/utunX）
 * - 路由管理：通过route命令配置系统路由
 * - 系统代理：通过networksetup命令配置网络代理
 * - 权限管理：某些操作需要管理员权限（通过AuthorizationServices）
 * - 系统功能：通知、设备ID、开机自启动等
 *
 * macOS VPN架构：
 * ```
 * JinGo App (Qt/C++)
 *   ↓ BSD Socket API
 * utun Device (/dev/utunX)
 *   ↓ Kernel Extension
 * macOS Network Stack
 * ```
 *
 * 主要特点：
 * - utun设备：macOS内置的虚拟网络接口，无需安装驱动
 * - 文件描述符：通过socket()和connect()创建utun设备
 * - 路由命令：使用route命令管理系统路由表
 * - networksetup：系统自带的网络配置工具
 * - Keychain：使用macOS Keychain存储敏感信息
 * - 管理员权限：某些操作需要通过AuthorizationServices提升权限
 *
 * 依赖组件：
 * - utun驱动：macOS内置，无需安装
 * - 版本支持：macOS 10.13及以上
 * - 权限要求：路由和代理操作需要管理员权限
 *
 * @note
 * - 仅在macOS平台编译和使用
 * - utun设备名称自动分配（utun0, utun1, ...）
 * - 某些操作需要管理员权限（会弹出授权对话框）
 * - 系统代理修改会影响所有网络服务
 *
 * @example
 * @code
 * MacOSPlatform* platform = new MacOSPlatform();
 *
 * // 检查VPN权限（macOS上通常默认有权限）
 * if (platform->hasVPNPermission()) {
 *     // 创建TUN设备（设备名自动分配）
 *     if (platform->createTunDevice("utun")) {
 *         // 配置设备
 *         TunDeviceConfig config("172.19.0.1", "255.255.255.0", 1500);
 *         platform->configureTunDevice(config);
 *
 *         // 添加路由
 *         RouteConfig route("0.0.0.0", "0.0.0.0", "172.19.0.1");
 *         platform->addRoute(route);
 *     }
 * }
 * @endcode
 */
class MacOSPlatform : public PlatformInterface {
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     *
     * @details 初始化macOS平台实现
     * - 初始化成员变量
     * - 准备utun设备环境
     */
    explicit MacOSPlatform(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     *
     * @details 清理资源
     * - 关闭TUN设备
     * - 清理路由配置
     */
    ~MacOSPlatform() override;

    // ========================================================================
    // VPN 权限
    // ========================================================================

    /**
     * @brief 检查是否有VPN权限
     * @return bool 有权限返回true，无权限返回false
     *
     * @details macOS上检查应用是否有权限创建TUN设备
     * - macOS上普通应用即可创建utun设备
     * - 某些操作需要管理员权限（通过requestAdminPrivileges获取）
     */
    bool hasVPNPermission() override;

    /**
     * @brief 请求VPN权限
     * @return bool 成功返回true，失败返回false
     *
     * @details macOS上的VPN权限请求
     * - macOS通常不需要特殊VPN权限
     * - 如果需要管理员权限，会调用requestAdminPrivileges
     *
     * @see requestAdminPrivileges
     */
    bool requestVPNPermission() override;

    // ========================================================================
    // TUN 设备管理
    // ========================================================================

    /**
     * @brief 创建TUN设备
     * @param deviceName 设备名称（通常为"utun"，系统自动分配编号）
     * @return bool 成功返回true，失败返回false
     *
     * @details 创建macOS utun虚拟网络接口
     * - 通过socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL)创建
     * - 使用connect()连接到utun控制器
     * - 设备名自动分配（如utun0, utun1等）
     *
     * @note 不需要管理员权限
     *
     * @see configureTunDevice, closeTunDevice, openTunDevice
     */
    bool createTunDevice(const QString& deviceName) override;

    /**
     * @brief 打开已存在的TUN设备
     * @param deviceName 设备名称（如"utun0"）
     * @return bool 成功返回true，失败返回false
     *
     * @details 打开指定的utun设备
     * - 内部实现与createTunDevice类似
     * - 可用于重新连接到已创建的设备
     *
     * @see createTunDevice
     */
    bool openTunDevice(const QString& deviceName);

    /**
     * @brief 关闭TUN设备
     * @return bool 成功返回true，失败返回false
     *
     * @details 关闭utun设备
     * - 关闭文件描述符
     * - 清理路由配置
     * - 重置统计信息
     *
     * @see createTunDevice
     */
    bool closeTunDevice() override;

    /**
     * @brief 配置TUN设备
     * @param config TUN设备配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置utun设备的网络参数
     * - 使用ifconfig命令配置IP地址
     * - 设置MTU
     * - 配置子网掩码
     * - 启用设备（up）
     *
     * @note 需要管理员权限
     *
     * @see TunDeviceConfig, requestAdminPrivileges
     */
    bool configureTunDevice(const TunDeviceConfig& config) override;

    // ========================================================================
    // 数据包读写
    // ========================================================================

    /**
     * @brief 从TUN设备读取数据包
     * @return QByteArray 数据包内容，失败返回空数组
     *
     * @details 从utun设备读取IP数据包
     * - 使用read()系统调用阻塞读取
     * - utun设备会在包前添加4字节协议头（需要剥离）
     * - 自动更新接收字节统计
     *
     * @note 应在独立线程中调用以避免阻塞UI
     *
     * @see writePacket, readTunPacket
     */
    QByteArray readPacket() override;

    /**
     * @brief 向TUN设备写入数据包
     * @param packet 数据包内容（IP数据包）
     * @return bool 成功返回true，失败返回false
     *
     * @details 向utun设备写入IP数据包
     * - 需要在包前添加4字节协议头（AF_INET或AF_INET6）
     * - 使用write()系统调用
     * - 自动更新发送字节统计
     *
     * @see readPacket, writeTunPacket
     */
    bool writePacket(const QByteArray& packet) override;

    /**
     * @brief 向TUN设备写入数据包（原始接口）
     * @param packet 数据包内容（包含4字节协议头）
     * @return bool 成功返回true，失败返回false
     *
     * @details 向utun设备写入原始数据包
     * - 与writePacket不同，此方法假设packet已包含协议头
     * - 直接调用write()系统调用
     *
     * @see writePacket
     */
    bool writeTunPacket(const QByteArray& packet);

    /**
     * @brief 从TUN设备读取数据包（原始接口）
     * @return QByteArray 数据包内容（包含4字节协议头）
     *
     * @details 从utun设备读取原始数据包
     * - 与readPacket不同，此方法返回包含协议头的数据
     * - 直接调用read()系统调用
     *
     * @see readPacket
     */
    QByteArray readTunPacket();

    // ========================================================================
    // TUN 设备信息
    // ========================================================================

    /**
     * @brief 获取TUN设备文件描述符
     * @return int 文件描述符，失败返回-1
     *
     * @details 返回utun设备的文件描述符
     * - 可用于select/poll等待数据
     * - 可用于fcntl设置非阻塞模式
     */
    int getTunFileDescriptor() override;

    /**
     * @brief 检查TUN设备是否已创建
     * @return bool 已创建返回true，否则返回false
     */
    bool isTunDeviceCreated() const override;

    /**
     * @brief 获取TUN设备名称
     * @return QString 设备名称（如"utun0"）
     */
    QString getTunDeviceName() const override;

    /**
     * @brief 获取接收字节数
     * @return quint64 接收的字节数
     */
    quint64 getBytesReceived() const override;

    /**
     * @brief 获取发送字节数
     * @return quint64 发送的字节数
     */
    quint64 getBytesSent() const override;

    /**
     * @brief 重置统计信息
     *
     * @details 将接收和发送字节数重置为0
     */
    void resetStatistics() override;

    // ========================================================================
    // 路由管理
    // ========================================================================

    /**
     * @brief 添加路由
     * @param route 路由配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 向macOS路由表添加路由
     * - 使用route add命令
     * - 需要管理员权限
     *
     * @note 需要管理员权限
     *
     * @see deleteRoute, requestAdminPrivileges
     */
    bool addRoute(const RouteConfig& route) override;

    /**
     * @brief 删除路由
     * @param route 路由配置
     * @return bool 成功返回true，失败返回false
     *
     * @details 从macOS路由表删除路由
     * - 使用route delete命令
     * - 需要管理员权限
     *
     * @note 需要管理员权限
     *
     * @see addRoute, requestAdminPrivileges
     */
    bool deleteRoute(const RouteConfig& route) override;

    // ========================================================================
    // 网络信息
    // ========================================================================

    /**
     * @brief 获取默认网关
     * @return QString 默认网关IP地址
     *
     * @details 获取系统当前的默认网关
     * - 使用route -n get default命令
     * - 用于保存原始网关，以便恢复
     */
    QString getDefaultGateway() const;

    /**
     * @brief 获取DNS服务器列表
     * @return QStringList DNS服务器IP地址列表
     *
     * @details 获取系统当前的DNS服务器
     * - 使用networksetup -getdnsservers命令
     * - 用于保存原始DNS，以便恢复
     */
    QStringList getDnsServers() const;

    // ========================================================================
    // 系统代理
    // ========================================================================

    /**
     * @brief 设置系统代理
     * @param host 代理服务器地址
     * @param port 代理服务器端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置macOS系统代理
     * - 使用networksetup命令配置所有网络服务
     * - 影响HTTP、HTTPS、SOCKS代理
     * - 需要管理员权限
     *
     * @note 需要管理员权限
     *
     * @see clearSystemProxy, setSystemProxy, requestAdminPrivileges
     */
    bool setupSystemProxy(const QString& host, int socksPort) override;

    /**
     * @brief 设置系统代理（实现方法）
     * @param host 代理服务器地址
     * @param httpPort HTTP/HTTPS代理端口
     * @param socksPort SOCKS代理端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 内部实现方法，与setupSystemProxy功能相同
     *
     * @see setupSystemProxy
     */
    bool setSystemProxy(const QString& host, int socksPort);

    /**
     * @brief 清除系统代理
     * @return bool 成功返回true，失败返回false
     *
     * @details 清除macOS系统代理配置
     * - 使用networksetup命令禁用代理
     * - 恢复为直接连接
     * - 需要管理员权限
     *
     * @note 需要管理员权限
     *
     * @see setupSystemProxy, requestAdminPrivileges
     */
    bool clearSystemProxy() override;

    // ========================================================================
    // 权限管理
    // ========================================================================

    /**
     * @brief 请求管理员权限
     * @param reason 请求权限的原因（显示给用户）
     * @return bool 成功返回true，失败返回false
     *
     * @details 请求macOS管理员权限
     * - 使用AuthorizationServices API
     * - 显示系统授权对话框
     * - 用户需要输入管理员密码
     *
     * @note
     * - 需要在Info.plist中声明权限原因
     * - 用户可以拒绝授权
     *
     * @example
     * @code
     * if (platform->requestAdminPrivileges("JinGo needs admin privileges to configure VPN routes")) {
     *     // 已获得管理员权限，可以执行需要权限的操作
     *     platform->addRoute(route);
     * }
     * @endcode
     */
    bool requestAdminPrivileges(const QString& reason);

    // ========================================================================
    // 通知
    // ========================================================================

    /**
     * @brief 显示系统通知
     * @param title 通知标题
     * @param message 通知内容
     *
     * @details 显示macOS通知中心通知
     * - 使用NSUserNotificationCenter（macOS 10.14及以下）
     * - 使用UNUserNotificationCenter（macOS 10.14+）
     * - 通知会显示在通知中心
     */
    void showNotification(const QString& title, const QString& message) override;

    // ========================================================================
    // 自启动
    // ========================================================================

    /**
     * @brief 检查是否已启用开机自启动
     * @return bool 已启用返回true，未启用返回false
     *
     * @details 检查应用是否在登录时自动启动
     * - 检查~/Library/LaunchAgents/中的plist文件
     */
    bool isAutoStartEnabled() override;

    /**
     * @brief 设置开机自启动
     * @param enable true启用，false禁用
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置macOS开机自启动
     * - 在~/Library/LaunchAgents/创建或删除plist文件
     * - 使用launchctl管理启动项
     */
    bool setAutoStart(bool enable) override;

    // ========================================================================
    // 平台信息
    // ========================================================================

    /**
     * @brief 获取设备ID
     * @return QString 设备唯一标识符
     *
     * @details 返回macOS设备的唯一标识符
     * - 使用IOPlatformUUID（硬件UUID）
     * - 通过IOKit框架获取
     */
    QString getDeviceId() override;

    /**
     * @brief 获取平台名称
     * @return QString 平台名称（"macOS"）
     */
    QString getPlatformName() override;

    /**
     * @brief 获取macOS版本
     * @return QString macOS版本（例如："14.2", "13.6"）
     *
     * @details 返回macOS操作系统版本
     * - 格式：主版本.次版本
     * - 例如：macOS Sonoma返回"14.x"
     */
    QString getPlatformVersion() const;

    // ========================================================================
    // 共享存储（App Group）
    // ========================================================================

    /**
     * @brief 保存值到App Group共享存储
     * @param key 键名
     * @param value 值
     * @return bool 成功返回true，失败返回false
     *
     * @details 保存键值对到App Group共享存储
     * - 使用NSUserDefaults with App Group identifier
     * - 用于与Network Extension共享数据
     */
    bool saveToSharedDefaults(const QString& key, const QString& value) override;

    /**
     * @brief 从App Group共享存储读取值
     * @param key 键名
     * @param defaultValue 默认值
     * @return QString 读取的值，如果不存在返回默认值
     */
    QString readFromSharedDefaults(const QString& key, const QString& defaultValue = QString()) override;

private:
    // ========================================================================
    // 私有方法
    // ========================================================================

    /**
     * @brief 执行系统命令
     * @param program 程序名称或路径
     * @param arguments 参数列表
     * @return bool 成功返回true，失败返回false
     *
     * @details 执行外部命令并等待完成
     * - 使用QProcess执行命令
     * - 等待命令执行完成
     * - 检查退出码判断成功或失败
     */
    bool executeCommand(const QString& program, const QStringList& arguments);

    /**
     * @brief 获取所有活动的网络服务列表
     * @return QStringList 活动的网络服务名称列表
     */
    QStringList getActiveNetworkServices();

    /**
     * @brief 获取当前系统代理设置
     * @param service 网络服务名称（如"Wi-Fi"）
     * @param webProxyHost 输出HTTP代理主机
     * @param webProxyPort 输出HTTP代理端口
     * @param webProxyEnabled 输出HTTP代理是否启用
     * @param secureWebProxyHost 输出HTTPS代理主机
     * @param secureWebProxyPort 输出HTTPS代理端口
     * @param secureWebProxyEnabled 输出HTTPS代理是否启用
     * @param socksProxyHost 输出SOCKS代理主机
     * @param socksProxyPort 输出SOCKS代理端口
     * @param socksProxyEnabled 输出SOCKS代理是否启用
     * @return bool 成功返回true，失败返回false
     */
    bool getCurrentProxySettings(const QString& service,
                                QString& webProxyHost, int& webProxyPort, bool& webProxyEnabled,
                                QString& secureWebProxyHost, int& secureWebProxyPort, bool& secureWebProxyEnabled,
                                QString& socksProxyHost, int& socksProxyPort, bool& socksProxyEnabled);

    /**
     * @brief 保存当前系统代理设置
     * @return bool 成功返回true，失败返回false
     */
    bool saveCurrentProxySettings();

    /**
     * @brief 恢复原有系统代理设置
     * @return bool 成功返回true，失败返回false
     */
    bool restoreProxySettings();

    // ========================================================================
    // 成员变量
    // ========================================================================

    int m_tunFd;                 ///< TUN设备文件描述符
    QString m_deviceName;        ///< TUN设备名称（如"utun0"）
    bool m_tunCreated;           ///< TUN设备是否已创建
    quint64 m_bytesReceived;     ///< 接收字节数
    quint64 m_bytesSent;         ///< 发送字节数

    // 代理设置结构（用于存储每个网络服务的代理配置）
    struct ProxySettings {
        QString webProxyHost;
        int webProxyPort = 0;
        bool webProxyEnabled = false;
        QString secureWebProxyHost;
        int secureWebProxyPort = 0;
        bool secureWebProxyEnabled = false;
        QString socksProxyHost;
        int socksProxyPort = 0;
        bool socksProxyEnabled = false;
    };

    // 原有系统代理设置（用于恢复）- 以网络服务名称为key
    bool m_proxySettingsSaved;   ///< 是否已保存原有代理设置
    QMap<QString, ProxySettings> m_savedProxySettings;  ///< 保存的各网络服务代理设置
};

#endif // MACOSPLATFORM_H
