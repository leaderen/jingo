/**
 * @file MacOSTunManager.h
 * @brief macOS TUN 虚拟网卡管理器（JinGoCore 模式）
 * @details 通过 JinGoCore (setuid root) 服务程序来创建和管理 TUN 设备
 *          JinGoCore 类似 FlClash 的 FlClashCore，包含完整的 VPN 功能
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright (c) 2025 JinGo Team. All rights reserved.
 */

#pragma once

// 只在 macOS 上编译，不在 iOS 上
#if defined(__APPLE__) && defined(__MACH__)
#include <TargetConditionals.h>
#if TARGET_OS_OSX

#include <QObject>
#include <QString>
#include <QStringList>
#include <QProcess>
#include <QThread>
#include <atomic>

namespace JinGo {

/**
 * @brief macOS TUN 设备管理器（JinGoCore 模式）
 *
 * @details
 * 通过 JinGoCore（setuid root 程序）来创建和管理 TUN 设备。
 * JinGoCore 包含完整的 Xray + TUN + 路由/DNS 管理功能。
 *
 * 架构类似 FlClash：
 * - JinGoCore: setuid root 的核心服务程序，负责 Xray/TUN/路由
 * - JinGo: GUI 应用，通过启动/停止 JinGoCore 来控制 VPN
 *
 * 优点：
 * - 首次安装需要管理员密码，之后无需密码
 * - 不需要 Network Extension 签名
 * - 主应用退出后 VPN 仍可运行（JinGoCore 独立进程）
 */
class MacOSTunManager : public QObject {
    Q_OBJECT

public:
    static MacOSTunManager& instance();

    // 禁止拷贝
    MacOSTunManager(const MacOSTunManager&) = delete;
    MacOSTunManager& operator=(const MacOSTunManager&) = delete;

    /**
     * @brief 初始化 TUN 设备
     * @param tunIP TUN 设备 IP 地址（如 "172.19.0.1"）
     * @param mtu MTU 大小（默认 1500）
     * @return 成功返回 true
     */
    bool initialize(const QString& tunIP = "172.19.0.1", int mtu = 1500);

    /**
     * @brief 启动 TUN 模式（通过 JinGoCore）
     * @param xrayConfig Xray 配置 JSON
     * @param error 错误信息输出
     * @return 成功返回 true
     */
    bool start(const QString& xrayConfig, QString* error = nullptr);

    /**
     * @brief 停止 TUN 模式
     */
    void stop();

    /**
     * @brief 检查是否正在运行
     */
    bool isRunning() const { return m_isRunning; }

    /**
     * @brief 获取 TUN 设备名称
     */
    QString deviceName() const;

    /**
     * @brief 获取 TUN IP
     */
    QString tunIP() const;

    /**
     * @brief 获取 MTU
     */
    int mtu() const;

    /**
     * @brief 获取上传字节数
     */
    quint64 uploadBytes() const;

    /**
     * @brief 获取下载字节数
     */
    quint64 downloadBytes() const;

    /**
     * @brief 获取上传速度（字节/秒）
     */
    double uploadSpeed() const;

    /**
     * @brief 获取下载速度（字节/秒）
     */
    double downloadSpeed() const;

    /**
     * @brief 更新统计信息
     */
    void updateStats();

    /**
     * @brief 配置网络（由 JinGoCore 内部处理）
     */
    bool configureNetwork(const QString& serverIP, const QStringList& dnsServers = {});

    /**
     * @brief 恢复网络（由 JinGoCore 内部处理）
     */
    bool restoreNetwork();

    // 以下方法保留向后兼容，实际由 JinGoCore 处理
    bool configureRoutes(const QString& serverIP);
    void configureDNS(const QStringList& dnsServers);
    void restoreRoutes();
    void restoreDNS();

    // Helper 兼容方法（实际使用 JinGoCore）
    QString helperPath() const;
    bool isHelperInstalled();
    bool installHelper();
    bool executeHelper(const QString& command, QString* output = nullptr);
    bool executeAsAdmin(const QString& command);

signals:
    void started();
    void stopped();
    void errorOccurred(const QString& message);
    void statsUpdated(quint64 upload, quint64 download);

private:
    MacOSTunManager();
    ~MacOSTunManager();

    // JinGoCore 管理
    QString corePath() const;
    bool isCoreInstalled();
    bool installCore();

    bool m_isRunning;
    QString m_deviceName;
    QString m_tunIP;
    int m_mtu;

    // JinGoCore 进程
    QProcess* m_coreProcess = nullptr;
    bool m_coreInstalled;

    // 统计
    std::atomic<quint64> m_uploadBytes;
    std::atomic<quint64> m_downloadBytes;
    quint64 m_lastUploadBytes;
    quint64 m_lastDownloadBytes;
    qint64 m_lastStatsTime;
};

} // namespace JinGo

#endif // TARGET_OS_OSX
#endif // __APPLE__ && __MACH__
