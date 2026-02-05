// src/models/ConnectionStatus.h
/**
 * @file ConnectionStatus.h
 * @brief 连接状态数据模型头文件
 * @details 定义了VPN/代理连接的实时状态信息，包括连接状态、流量统计、速度监控等
 * @author Your Name
 * @date 2024
 */

#ifndef CONNECTIONSTATUS_H
#define CONNECTIONSTATUS_H

#include <QObject>
#include <QString>
#include <QDateTime>

/**
 * @class ConnectionStatus
 * @brief 连接状态数据模型类
 * @details 管理和追踪当前连接的实时状态信息，包括：
 *          - 连接状态（已断开、正在连接、已连接等）
 *          - 服务器信息（名称、地址、协议）
 *          - 时间信息（连接时间、持续时长）
 *          - 流量统计（上传/下载字节数）
 *          - 速度监控（上传/下载速度）
 *          - 错误信息（错误消息、延迟）
 *
 * 该类继承自QObject，支持Qt的信号槽机制和属性系统，
 * 可实时更新UI显示连接状态。所有流量和速度数据都会自动格式化为易读文本。
 */
class ConnectionStatus : public QObject
{
    Q_OBJECT

    // ========== Qt属性定义 ==========

    /// 连接状态枚举值
    Q_PROPERTY(State state READ state WRITE setState NOTIFY stateChanged)

    /// 服务器名称
    Q_PROPERTY(QString serverName READ serverName WRITE setServerName NOTIFY serverNameChanged)

    /// 服务器地址
    Q_PROPERTY(QString serverAddress READ serverAddress WRITE setServerAddress NOTIFY serverAddressChanged)

    /// 协议类型
    Q_PROPERTY(QString protocol READ protocol WRITE setProtocol NOTIFY protocolChanged)

    /// 连接持续时长（秒）
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)

    /// 上传字节数
    Q_PROPERTY(quint64 uploadBytes READ uploadBytes NOTIFY uploadBytesChanged)

    /// 下载字节数
    Q_PROPERTY(quint64 downloadBytes READ downloadBytes NOTIFY downloadBytesChanged)

    /// 上传速度（字节/秒）
    Q_PROPERTY(quint64 uploadSpeed READ uploadSpeed NOTIFY uploadSpeedChanged)

    /// 下载速度（字节/秒）
    Q_PROPERTY(quint64 downloadSpeed READ downloadSpeed NOTIFY downloadSpeedChanged)

    /// 状态字符串（派生属性）
    Q_PROPERTY(QString stateString READ stateString NOTIFY stateChanged)

    /// 格式化的持续时长
    Q_PROPERTY(QString formattedDuration READ formattedDuration NOTIFY durationChanged)

    /// 格式化的上传流量
    Q_PROPERTY(QString formattedUpload READ formattedUpload NOTIFY uploadBytesChanged)

    /// 格式化的下载流量
    Q_PROPERTY(QString formattedDownload READ formattedDownload NOTIFY downloadBytesChanged)

    /// 格式化的上传速度
    Q_PROPERTY(QString formattedUploadSpeed READ formattedUploadSpeed NOTIFY uploadSpeedChanged)

    /// 格式化的下载速度
    Q_PROPERTY(QString formattedDownloadSpeed READ formattedDownloadSpeed NOTIFY downloadSpeedChanged)

public:
    /**
     * @enum State
     * @brief 连接状态枚举
     * @details 定义了连接的各种可能状态
     */
    enum State {
        Disconnected,       ///< 已断开：未连接到任何服务器
        Connecting,         ///< 正在连接：正在建立连接
        Connected,          ///< 已连接：成功连接并可以使用
        Disconnecting,      ///< 正在断开：正在断开连接
        Reconnecting,       ///< 正在重连：连接中断后尝试重新连接
        Error               ///< 错误：连接过程中发生错误
    };
    Q_ENUM(State)

    /**
     * @brief 构造函数
     * @param parent 父对象指针，用于Qt对象树管理
     */
    explicit ConnectionStatus(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~ConnectionStatus() override;

    // ========== 状态管理 ==========

    /**
     * @brief 获取当前连接状态
     * @return State 连接状态枚举值
     */
    State state() const;

    /**
     * @brief 设置连接状态
     * @param state 新的连接状态
     * @details 当状态变为Connected时，会自动记录连接时间；
     *          当状态变为Disconnected时，会清除连接时间
     */
    void setState(State state);

    /**
     * @brief 获取状态的字符串表示
     * @return QString 状态的本地化字符串（如"已连接"、"正在连接"）
     */
    QString stateString() const;

    // ========== 服务器信息 ==========

    /**
     * @brief 获取服务器名称
     * @return QString 当前连接的服务器名称
     */
    QString serverName() const;

    /**
     * @brief 设置服务器名称
     * @param name 服务器名称
     */
    void setServerName(const QString& name);

    /**
     * @brief 获取服务器地址
     * @return QString 服务器IP地址或域名
     */
    QString serverAddress() const;

    /**
     * @brief 设置服务器地址
     * @param address 服务器地址
     */
    void setServerAddress(const QString& address);

    /**
     * @brief 获取协议类型
     * @return QString 协议名称（如VMess、VLESS、Trojan）
     */
    QString protocol() const;

    /**
     * @brief 设置协议类型
     * @param protocol 协议名称
     */
    void setProtocol(const QString& protocol);

    /**
     * @brief 获取服务器位置
     * @return QString 服务器所在位置（国家/地区）
     */
    QString location() const;

    /**
     * @brief 设置服务器位置
     * @param location 位置字符串
     */
    void setLocation(const QString& location);

    // ========== 时间信息 ==========

    /**
     * @brief 获取连接建立的时间
     * @return QDateTime 连接时间，如果未连接则无效
     */
    QDateTime connectedAt() const;

    /**
     * @brief 设置连接建立时间
     * @param dateTime 连接时间
     */
    void setConnectedAt(const QDateTime& dateTime);

    /**
     * @brief 获取连接持续时长
     * @return qint64 持续秒数，如果未连接或连接时间无效则返回0
     * @details 实时计算从连接建立到当前的时间差
     */
    qint64 duration() const;

    // ========== 流量统计 ==========

    /**
     * @brief 获取上传字节数
     * @return quint64 总上传字节数
     */
    quint64 uploadBytes() const;

    /**
     * @brief 设置上传字节数
     * @param bytes 上传字节数
     */
    void setUploadBytes(quint64 bytes);

    /**
     * @brief 获取下载字节数
     * @return quint64 总下载字节数
     */
    quint64 downloadBytes() const;

    /**
     * @brief 设置下载字节数
     * @param bytes 下载字节数
     */
    void setDownloadBytes(quint64 bytes);

    /**
     * @brief 获取总流量
     * @return quint64 上传和下载的总字节数
     */
    quint64 totalBytes() const;

    // ========== 速度监控 ==========

    /**
     * @brief 获取上传速度
     * @return quint64 当前上传速度（字节/秒）
     */
    quint64 uploadSpeed() const;

    /**
     * @brief 设置上传速度
     * @param speed 上传速度（字节/秒）
     */
    void setUploadSpeed(quint64 speed);

    /**
     * @brief 获取下载速度
     * @return quint64 当前下载速度（字节/秒）
     */
    quint64 downloadSpeed() const;

    /**
     * @brief 设置下载速度
     * @param speed 下载速度（字节/秒）
     */
    void setDownloadSpeed(quint64 speed);

    /**
     * @brief 获取总速度
     * @return quint64 上传和下载的总速度（字节/秒）
     */
    quint64 totalSpeed() const;

    // ========== 格式化输出 ==========

    /**
     * @brief 获取格式化的持续时长
     * @return QString 时长字符串（如"01:23:45"或"23:45"）
     */
    QString formattedDuration() const;

    /**
     * @brief 获取格式化的上传流量
     * @return QString 流量字符串（如"1.25 GB"）
     */
    QString formattedUpload() const;

    /**
     * @brief 获取格式化的下载流量
     * @return QString 流量字符串（如"3.50 GB"）
     */
    QString formattedDownload() const;

    /**
     * @brief 获取格式化的总流量
     * @return QString 流量字符串（如"4.75 GB"）
     */
    QString formattedTotal() const;

    /**
     * @brief 获取格式化的上传速度
     * @return QString 速度字符串（如"2.5 MB/s"）
     */
    QString formattedUploadSpeed() const;

    /**
     * @brief 获取格式化的下载速度
     * @return QString 速度字符串（如"10.8 MB/s"）
     */
    QString formattedDownloadSpeed() const;

    /**
     * @brief 获取格式化的总速度
     * @return QString 速度字符串（如"13.3 MB/s"）
     */
    QString formattedTotalSpeed() const;

    // ========== 其他信息 ==========

    /**
     * @brief 获取错误消息
     * @return QString 错误描述，无错误时为空
     */
    QString errorMessage() const;

    /**
     * @brief 设置错误消息
     * @param message 错误描述
     */
    void setErrorMessage(const QString& message);

    /**
     * @brief 获取网络延迟
     * @return int 延迟值（毫秒），-1表示未测试
     */
    int latency() const;

    /**
     * @brief 设置网络延迟
     * @param ms 延迟值（毫秒）
     */
    void setLatency(int ms);

    // ========== 操作方法 ==========

    /**
     * @brief 重置所有数据
     * @details 将所有字段恢复到初始状态：
     *          - 状态设为Disconnected
     *          - 清空服务器信息
     *          - 清空连接时间
     *          - 重置流量统计
     *          - 清空错误消息
     *          - 重置延迟为-1
     */
    void reset();

    /**
     * @brief 重置流量统计
     * @details 将上传/下载字节数和速度都设为0，但保留其他信息
     */
    void resetStats();

    /**
     * @brief 转换为JSON对象
     * @return QJsonObject 包含所有状态信息的JSON对象
     * @details 用于保存状态或通过网络传输
     */
    QJsonObject toJson() const;

signals:
    // ========== 信号定义 ==========

    void stateChanged();              ///< 连接状态改变信号
    void serverNameChanged();         ///< 服务器名称改变信号
    void serverAddressChanged();      ///< 服务器地址改变信号
    void protocolChanged();           ///< 协议类型改变信号
    void durationChanged();           ///< 连接时长改变信号
    void uploadBytesChanged();        ///< 上传流量改变信号
    void downloadBytesChanged();      ///< 下载流量改变信号
    void uploadSpeedChanged();        ///< 上传速度改变信号
    void downloadSpeedChanged();      ///< 下载速度改变信号
    void errorMessageChanged();       ///< 错误消息改变信号
    void latencyChanged();            ///< 延迟改变信号

private:
    // ========== 私有成员变量 ==========

    State m_state;                ///< 当前连接状态
    QString m_serverName;         ///< 服务器名称
    QString m_serverAddress;      ///< 服务器地址
    QString m_protocol;           ///< 协议类型
    QString m_location;           ///< 服务器位置
    QDateTime m_connectedAt;      ///< 连接建立时间
    quint64 m_uploadBytes;        ///< 上传字节数
    quint64 m_downloadBytes;      ///< 下载字节数
    quint64 m_uploadSpeed;        ///< 上传速度（字节/秒）
    quint64 m_downloadSpeed;      ///< 下载速度（字节/秒）
    QString m_errorMessage;       ///< 错误消息
    int m_latency;                ///< 网络延迟（毫秒），-1表示未测试

    // ========== 私有静态方法 ==========

    /**
     * @brief 格式化字节数为易读文本
     * @param bytes 字节数
     * @return QString 格式化文本（如"1.25 GB"、"256.5 MB"）
     * @details 自动选择合适的单位（B/KB/MB/GB/TB）
     */
    static QString formatBytes(quint64 bytes);

    /**
     * @brief 格式化速度为易读文本
     * @param bytesPerSecond 速度（字节/秒）
     * @return QString 格式化文本（如"2.5 MB/s"、"150 KB/s"）
     * @details 自动选择合适的单位（B/s、KB/s、MB/s、GB/s）
     */
    static QString formatSpeed(quint64 bytesPerSecond);

    /**
     * @brief 格式化时长为易读文本
     * @param seconds 秒数
     * @return QString 格式化文本（如"01:23:45"表示1小时23分45秒，"23:45"表示23分45秒）
     * @details 小于1小时显示MM:SS格式，大于等于1小时显示HH:MM:SS格式
     */
    static QString formatDuration(qint64 seconds);

    /**
     * @brief 状态枚举转字符串
     * @param state 连接状态枚举值
     * @return QString 本地化的状态字符串
     */
    static QString stateToString(State state);
};

#endif // CONNECTIONSTATUS_H