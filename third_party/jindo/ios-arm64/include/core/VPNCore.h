/**
 * @file VPNCore.h
 * @brief VPN核心管理类（包装XrayCBridge）
 * @details 提供VPN连接的核心功能，使用XrayCBridge与SuperRay交互
 *
 * @author JinGo VPN Team
 * @version 3.0
 * @date 2025
 *
 * @copyright Copyright (c) 2025
 */

#ifndef VPNCORE_H
#define VPNCORE_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <QMutex>
#include <QDateTime>
#include <QThread>

/**
 * @class VPNCore
 * @brief VPN核心管理类（单例模式）
 *
 * @details
 * VPNCore是VPN功能的核心管理类，使用XrayCBridge与SuperRay库交互。
 * 提供以下功能：
 * - Xray进程的生命周期管理
 * - 配置管理和验证
 * - 流量统计和速度监控
 * - 运行状态管理
 *
 * 架构：
 * @code
 * VPNManager
 *    ↓
 * VPNCore (本类)
 *    ↓
 * XrayCBridge (C桥接)
 *    ↓
 * SuperRay C API
 * @endcode
 */
class VPNCore : public QObject
{
    Q_OBJECT

public:
    // ========================================================================
    // 枚举和结构体
    // ========================================================================

    enum ConnectionState {
        Stopped,      ///< 已停止
        Starting,     ///< 正在启动
        Running,      ///< 运行中
        Stopping,     ///< 正在停止
        StateError    ///< 错误状态
    };

    enum LogLevel {
        Debug,
        Info,
        Warning,
        LogError
    };

    struct ConnectionStats {
        quint64 uploadBytes = 0;
        quint64 downloadBytes = 0;
        quint64 uploadSpeed = 0;
        quint64 downloadSpeed = 0;
        qint64 connectedTime = 0;

        QString formatUpload() const;
        QString formatDownload() const;
        QString formatUploadSpeed() const;
        QString formatDownloadSpeed() const;
        QString formatConnectedTime() const;
    };

    // ========================================================================
    // 单例方法
    // ========================================================================

    static VPNCore& instance();
    static void destroy();

    // ========================================================================
    // 核心方法
    // ========================================================================

    bool initialize();
    bool start(const QString& configJson);
    bool startWithSuperRay(const QString& configJson);
    bool stop();
    bool restart();

    /**
     * @brief 强制重置VPNCore状态
     * @details 用于异常情况下强制将状态重置为Stopped，清理所有资源
     *          不管当前是什么状态都会强制重置，用于解决状态残留问题
     */
    void forceReset();

    // ========================================================================
    // 查询方法
    // ========================================================================

    bool isRunning();
    ConnectionState state() const;
    QString stateString() const;
    QString getVersion() const;
    QString getInstanceID() const;
    ConnectionStats getStats() const;
    QString lastError() const;
    QString currentConfig() const;

    // ========================================================================
    // 配置和测试
    // ========================================================================

    bool testConfig(const QString& configJson, QString* errorMsg = nullptr);
    QString queryStats(const QString& tag = "", bool reset = false);
    int ping(const QString& destination, int timeout = 5000);

    // ========================================================================
    // 参数设置
    // ========================================================================

    void setStatsUpdateInterval(int intervalMs);
    void resetStats();

signals:
    void stateChanged(int state);
    void connected();
    void disconnected();
    void statsUpdated(quint64 uploadBytes, quint64 downloadBytes);
    void speedUpdated(quint64 uploadSpeed, quint64 downloadSpeed);
    void detailedStatsUpdated(const ConnectionStats& stats);
    void errorOccurred(const QString& error);
    void logMessage(int level, const QString& message);

private:
    // 私有构造函数
    explicit VPNCore(QObject* parent = nullptr);
    ~VPNCore();

    // 状态管理
    void setState(ConnectionState state);
    void setError(const QString& error);
    void clearError();

    // 统计更新
    void updateStats();
    void startStatsTimer();
    void stopStatsTimer();
    void resetStatsInternal();
    void calculateSpeed();

    // 日志
    void log(LogLevel level, const QString& message);

    // 槽函数
private slots:
    void onStatsTimerTimeout();

    // 成员变量
private:
    static VPNCore* s_instance;
    static QMutex s_instanceMutex;

    mutable QMutex m_mutex;

    ConnectionState m_state = Stopped;
    QString m_lastError;
    QString m_version;
    QString m_currentConfig;
    QString m_instanceID;

    ConnectionStats m_stats;
    QDateTime m_connectionStartTime;

    QTimer* m_statsTimer = nullptr;
    int m_statsUpdateInterval = 5000;

    quint64 m_lastUploadBytes = 0;
    quint64 m_lastDownloadBytes = 0;
    qint64 m_lastStatsTime = 0;

    bool m_initialized = false;
};

#endif // VPNCORE_H
