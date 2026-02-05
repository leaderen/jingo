/**
 * @file LinuxPlatform.h
 * @brief Linux平台实现头文件
 * @details 实现Linux平台特定的VPN功能，使用TUN设备和多桌面环境支持
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef LINUXPLATFORM_H
#define LINUXPLATFORM_H

#include "PlatformInterface.h"
#include "linux/LinuxTunManager.h"
#include <QString>
#include <QProcess>
#include <memory>

/**
 * @class LinuxPlatform
 * @brief Linux平台实现类
 *
 * @details 提供Linux平台的VPN功能实现
 * - TUN设备管理：使用/dev/net/tun虚拟网络接口
 * - 路由管理：通过ip route命令配置系统路由
 * - 系统代理：支持多种桌面环境（GNOME/KDE/XFCE/MATE等）
 * - 权限管理：某些操作需要root权限或CAP_NET_ADMIN能力
 * - 系统功能：通知、设备ID、开机自启动等
 *
 * Linux VPN架构：
 * ```
 * JinGo App (Qt/C++)
 *   ↓ ioctl/read/write
 * TUN Device (/dev/net/tun)
 *   ↓ Linux Kernel
 * Linux Network Stack
 * ```
 *
 * 主要特点：
 * - TUN设备：使用/dev/net/tun创建虚拟网络接口
 * - 多桌面环境：自动检测并适配GNOME、KDE、XFCE等
 * - 路由命令：使用ip route（新版）或route（旧版）命令
 * - D-Bus通知：通过org.freedesktop.Notifications发送通知
 * - systemd集成：使用systemd管理开机自启动
 * - 环境变量：支持通过环境变量设置代理（适用于命令行应用）
 *
 * 桌面环境支持：
 * - GNOME：通过gsettings配置代理
 * - KDE：通过kwriteconfig5配置代理
 * - XFCE：通过xfconf-query配置代理
 * - MATE：通过mateconftool配置代理
 * - 其他：通过环境变量配置（~/.profile或~/.bashrc）
 *
 * 依赖组件：
 * - TUN/TAP驱动：Linux内核内置
 * - 版本支持：Linux内核3.10及以上
 * - 桌面工具：各桌面环境的配置工具
 * - D-Bus：通知和系统集成
 * - 权限要求：TUN设备需要CAP_NET_ADMIN或root权限
 *
 * @note
 * - 仅在Linux平台编译和使用
 * - 需要在/dev/net/tun有读写权限
 * - 路由操作需要root权限或CAP_NET_ADMIN
 * - 代理设置因桌面环境而异
 *
 * @example
 * @code
 * LinuxPlatform* platform = new LinuxPlatform();
 *
 * // 检查VPN权限
 * if (platform->hasVPNPermission()) {
 *     // 创建TUN设备
 *     if (platform->createTunDevice("tun0")) {
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
class LinuxPlatform : public PlatformInterface
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     *
     * @details 初始化Linux平台实现
     * - 初始化成员变量
     * - 检测桌面环境
     * - 准备TUN设备环境
     */
    explicit LinuxPlatform(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     *
     * @details 清理资源
     * - 关闭TUN设备
     * - 清理路由配置
     */
    ~LinuxPlatform() override;

    // ========================================================================
    // VPN 权限
    // ========================================================================

    /**
     * @brief 检查并在需要时自动请求VPN权限
     *
     * @details 在应用启动时自动检查VPN权限状态
     * - 如果已有权限，无操作
     * - 如果没有权限，自动弹出pkexec授权对话框
     * - 权限授予后需要重启应用才能生效
     *
     * @note 此方法在LinuxPlatform构造函数中延迟调用（1秒后）
     *
     * @see requestVPNPermission, hasVPNPermission
     */
    void checkAndRequestVPNPermissionIfNeeded();

    /**
     * @brief 请求VPN权限
     * @return bool 成功返回true，失败返回false
     *
     * @details Linux上的VPN权限请求
     * - 检查/dev/net/tun是否可访问
     * - 检查是否具有CAP_NET_ADMIN能力
     * - 如果需要，提示用户使用sudo或setcap
     *
     * @note
     * - Linux上通常需要root权限或CAP_NET_ADMIN能力
     * - 可通过sudo运行或setcap授予能力
     *
     * @see hasVPNPermission
     */
    bool requestVPNPermission() override;

    /**
     * @brief 检查是否有VPN权限
     * @return bool 有权限返回true，无权限返回false
     *
     * @details 检查应用是否有权限创建TUN设备
     * - 检查/dev/net/tun可读写性
     * - 检查是否为root用户或具有CAP_NET_ADMIN
     *
     * @see requestVPNPermission
     */
    bool hasVPNPermission() override;

    // ========================================================================
    // 系统代理
    // ========================================================================

    /**
     * @brief 设置系统代理
     * @param host 代理服务器地址
     * @param port 代理服务器端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置Linux系统代理
     * - 自动检测桌面环境
     * - GNOME：通过gsettings设置
     * - KDE：通过kwriteconfig5设置
     * - 其他：通过环境变量设置
     *
     * @note 不同桌面环境行为可能不同
     *
     * @see clearSystemProxy, setGnomeProxy, setKdeProxy, setEnvironmentProxy
     */
    bool setupSystemProxy(const QString& host, int port) override;

    /**
     * @brief 清除系统代理
     * @return bool 成功返回true，失败返回false
     *
     * @details 清除Linux系统代理配置
     * - 根据桌面环境清除相应配置
     * - GNOME：禁用gsettings代理
     * - KDE：禁用KDE代理
     * - 其他：移除环境变量
     *
     * @see setupSystemProxy, clearGnomeProxy, clearKdeProxy, clearEnvironmentProxy
     */
    bool clearSystemProxy() override;

    // ========================================================================
    // 自启动
    // ========================================================================

    /**
     * @brief 设置开机自启动
     * @param enable true启用，false禁用
     * @return bool 成功返回true，失败返回false
     *
     * @details 配置Linux开机自启动
     * - 在~/.config/autostart/创建或删除.desktop文件
     * - 符合XDG Autostart规范
     * - 支持所有主流桌面环境
     *
     * @see isAutoStartEnabled, createDesktopFile, getAutostartFilePath
     */
    bool setAutoStart(bool enable) override;

    /**
     * @brief 检查是否已启用开机自启动
     * @return bool 已启用返回true，未启用返回false
     *
     * @details 检查应用是否在登录时自动启动
     * - 检查~/.config/autostart/中的.desktop文件
     *
     * @see setAutoStart
     */
    bool isAutoStartEnabled() override;

    // ========================================================================
    // 系统功能
    // ========================================================================

    /**
     * @brief 显示系统通知
     * @param title 通知标题
     * @param message 通知内容
     *
     * @details 显示Linux桌面通知
     * - 优先使用D-Bus（org.freedesktop.Notifications）
     * - 备选使用notify-send命令
     * - 支持所有符合freedesktop规范的桌面
     *
     * @see sendDbusNotification, sendNotifySendNotification
     */
    void showNotification(const QString& title, const QString& message) override;

    /**
     * @brief 获取设备ID
     * @return QString 设备唯一标识符
     *
     * @details 返回Linux设备的唯一标识符
     * - 优先使用/etc/machine-id（systemd）
     * - 备选使用/var/lib/dbus/machine-id（D-Bus）
     * - 最后备选使用主机名
     *
     * @note machine-id在系统重装后会变化
     *
     * @see getMachineId, getHostname
     */
    QString getDeviceId() override;

    /**
     * @brief 获取平台名称
     * @return QString 平台名称（"Linux"）
     */
    QString getPlatformName() override { return "Linux"; }

    // ========================================================================
    // Linux 特有方法
    // ========================================================================

    /**
     * @brief 获取Linux版本
     * @return QString Linux内核版本或发行版版本
     *
     * @details 返回Linux操作系统版本
     * - 格式：内核版本或发行版名称+版本
     * - 例如："5.15.0" 或 "Ubuntu 22.04"
     *
     * @note 实现可能因发行版而异
     */
    QString osVersion() const;

    /**
     * @brief 获取平台名称（别名）
     * @return QString 平台名称（"Linux"）
     *
     * @details 与getPlatformName()功能相同
     *
     * @see getPlatformName
     */
    QString platformName() const { return "Linux"; }

    // ========================================================================
    // TUN设备管理（待实现）
    // ========================================================================

    /**
     * @brief 创建TUN设备
     * @note 当前为存根实现，待完整实现
     */
    bool createTunDevice(const QString& deviceName) override;

    /**
     * @brief 关闭TUN设备
     * @note 当前为存根实现，待完整实现
     */
    bool closeTunDevice() override;

    /**
     * @brief 配置TUN设备
     * @note 当前为存根实现，待完整实现
     */
    bool configureTunDevice(const TunDeviceConfig& config) override;

    /**
     * @brief 读取数据包
     * @note 当前为存根实现，待完整实现
     */
    QByteArray readPacket() override;

    /**
     * @brief 写入数据包
     * @note 当前为存根实现，待完整实现
     */
    bool writePacket(const QByteArray& packet) override;

    /**
     * @brief 添加路由
     * @note 当前为存根实现，待完整实现
     */
    bool addRoute(const RouteConfig& route) override;

    /**
     * @brief 删除路由
     * @note 当前为存根实现，待完整实现
     */
    bool deleteRoute(const RouteConfig& route) override;

    /**
     * @brief 获取TUN文件描述符
     * @note 当前为存根实现，待完整实现
     */
    int getTunFileDescriptor() override;

    /**
     * @brief 检查TUN设备是否已创建
     * @note 当前为存根实现，待完整实现
     */
    bool isTunDeviceCreated() const override;

private:
    // ========================================================================
    // 桌面环境枚举
    // ========================================================================

    /**
     * @enum DesktopEnvironment
     * @brief Linux桌面环境类型枚举
     *
     * @details 定义支持的Linux桌面环境类型
     * - Unknown：未知或未检测到桌面环境
     * - GNOME：GNOME桌面环境
     * - KDE：KDE Plasma桌面环境
     * - XFCE：XFCE桌面环境
     * - MATE：MATE桌面环境
     * - Cinnamon：Cinnamon桌面环境（Linux Mint）
     * - LXDE：LXDE轻量级桌面环境
     * - Other：其他桌面环境
     */
    enum DesktopEnvironment {
        Unknown,     ///< 未知桌面环境
        GNOME,       ///< GNOME桌面
        KDE,         ///< KDE Plasma桌面
        XFCE,        ///< XFCE桌面
        MATE,        ///< MATE桌面
        Cinnamon,    ///< Cinnamon桌面
        LXDE,        ///< LXDE桌面
        Other        ///< 其他桌面环境
    };

    // ========================================================================
    // 桌面环境检测
    // ========================================================================

    /**
     * @brief 检测当前桌面环境
     * @return DesktopEnvironment 检测到的桌面环境类型
     *
     * @details 检测当前运行的Linux桌面环境
     * - 检查环境变量：XDG_CURRENT_DESKTOP、DESKTOP_SESSION等
     * - 检查运行的进程（gnome-shell、kwin等）
     * - 检查D-Bus服务
     *
     * @see DesktopEnvironment, getDesktopEnvironmentName
     */
    DesktopEnvironment detectDesktopEnvironment() const;

    /**
     * @brief 获取桌面环境名称
     * @return QString 桌面环境名称字符串
     *
     * @details 返回当前桌面环境的名称
     * - 基于detectDesktopEnvironment()的结果
     * - 返回可读的字符串（如"GNOME", "KDE"等）
     *
     * @see detectDesktopEnvironment
     */
    QString getDesktopEnvironmentName() const;

    // ========================================================================
    // GNOME 代理设置
    // ========================================================================

    /**
     * @brief 设置GNOME桌面代理
     * @param host 代理服务器地址
     * @param port 代理服务器端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 使用gsettings配置GNOME代理
     * - 设置org.gnome.system.proxy模式为manual
     * - 配置http、https代理
     * - 配置socks代理（可选）
     *
     * @note 需要安装gsettings工具
     *
     * @see clearGnomeProxy
     */
    bool setGnomeProxy(const QString& host, int port);

    /**
     * @brief 清除GNOME桌面代理
     * @return bool 成功返回true，失败返回false
     *
     * @details 使用gsettings清除GNOME代理
     * - 设置org.gnome.system.proxy模式为none
     *
     * @see setGnomeProxy
     */
    bool clearGnomeProxy();

    // ========================================================================
    // KDE 代理设置
    // ========================================================================

    /**
     * @brief 设置KDE桌面代理
     * @param host 代理服务器地址
     * @param port 代理服务器端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 使用kwriteconfig5配置KDE代理
     * - 修改kioslaverc配置文件
     * - 配置HTTP、HTTPS、FTP代理
     * - 通知KDE应用更新代理设置
     *
     * @note 需要安装kwriteconfig5工具
     *
     * @see clearKdeProxy
     */
    bool setKdeProxy(const QString& host, int port);

    /**
     * @brief 清除KDE桌面代理
     * @return bool 成功返回true，失败返回false
     *
     * @details 使用kwriteconfig5清除KDE代理
     * - 禁用kioslaverc中的代理配置
     *
     * @see setKdeProxy
     */
    bool clearKdeProxy();

    // ========================================================================
    // 环境变量代理设置
    // ========================================================================

    /**
     * @brief 通过环境变量设置代理
     * @param host 代理服务器地址
     * @param port 代理服务器端口
     * @return bool 成功返回true，失败返回false
     *
     * @details 在shell配置文件中设置代理环境变量
     * - 修改~/.profile或~/.bashrc
     * - 设置http_proxy、https_proxy等变量
     * - 适用于命令行应用和部分GUI应用
     *
     * @note 需要重新登录或source配置文件生效
     *
     * @see clearEnvironmentProxy
     */
    bool setEnvironmentProxy(const QString& host, int port);

    /**
     * @brief 清除环境变量代理
     * @return bool 成功返回true，失败返回false
     *
     * @details 从shell配置文件中移除代理环境变量
     * - 移除http_proxy、https_proxy等变量
     *
     * @see setEnvironmentProxy
     */
    bool clearEnvironmentProxy();

    // ========================================================================
    // 自启动文件管理
    // ========================================================================

    /**
     * @brief 获取自启动文件路径
     * @return QString .desktop文件的完整路径
     *
     * @details 返回应用自启动.desktop文件的路径
     * - 路径：~/.config/autostart/jingo-vpn.desktop
     * - 符合XDG Autostart规范
     *
     * @see createDesktopFile
     */
    QString getAutostartFilePath() const;

    /**
     * @brief 创建desktop文件
     * @param filePath .desktop文件路径
     * @return bool 成功返回true，失败返回false
     *
     * @details 创建符合规范的.desktop文件
     * - 包含Name、Exec、Icon等字段
     * - 设置Type=Application
     * - 设置X-GNOME-Autostart-enabled=true
     *
     * @see getAutostartFilePath
     */
    bool createDesktopFile(const QString& filePath);

    // ========================================================================
    // 设备标识
    // ========================================================================

    /**
     * @brief 获取机器ID
     * @return QString 机器唯一标识符
     *
     * @details 读取Linux机器ID
     * - 优先读取/etc/machine-id
     * - 备选读取/var/lib/dbus/machine-id
     * - systemd和D-Bus都使用此ID
     *
     * @see getDeviceId
     */
    QString getMachineId() const;

    /**
     * @brief 获取主机名
     * @return QString 主机名
     *
     * @details 获取系统主机名
     * - 使用gethostname()系统调用
     * - 或读取/etc/hostname
     *
     * @see getDeviceId
     */
    QString getHostname() const;

    // ========================================================================
    // 通知实现
    // ========================================================================

    /**
     * @brief 通过D-Bus发送通知
     * @param title 通知标题
     * @param message 通知内容
     * @return bool 成功返回true，失败返回false
     *
     * @details 使用D-Bus发送freedesktop规范的通知
     * - 调用org.freedesktop.Notifications服务
     * - 方法：Notify
     * - 支持所有符合规范的桌面环境
     *
     * @see showNotification, sendNotifySendNotification
     */
    bool sendDbusNotification(const QString& title, const QString& message);

    /**
     * @brief 通过notify-send发送通知
     * @param title 通知标题
     * @param message 通知内容
     * @return bool 成功返回true，失败返回false
     *
     * @details 使用notify-send命令发送通知
     * - 备选方案，当D-Bus不可用时使用
     * - 需要安装libnotify-bin包
     *
     * @see showNotification, sendDbusNotification
     */
    bool sendNotifySendNotification(const QString& title, const QString& message);

    // ========================================================================
    // 命令执行
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
     *
     * @see executeCommandWithOutput
     */
    bool executeCommand(const QString& program, const QStringList& arguments);

    /**
     * @brief 执行系统命令并获取输出
     * @param program 程序名称或路径
     * @param arguments 参数列表
     * @return QString 命令的标准输出，失败返回空字符串
     *
     * @details 执行外部命令并捕获输出
     * - 使用QProcess执行命令
     * - 等待命令执行完成
     * - 返回标准输出内容
     *
     * @see executeCommand
     */
    QString executeCommandWithOutput(const QString& program, const QStringList& arguments);

    // ========================================================================
    // TUN设备管理成员
    // ========================================================================

    /**
     * @brief LinuxTunManager实例
     * @details 管理TUN虚拟网卡设备
     */
    std::unique_ptr<JinGo::LinuxTunManager> m_tunManager;
};

#endif // LINUXPLATFORM_H
