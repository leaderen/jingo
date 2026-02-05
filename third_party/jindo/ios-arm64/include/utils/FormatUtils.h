/**
 * @file FormatUtils.h
 * @brief 格式化工具类头文件
 * @details 提供各种数据格式化功能供QML使用
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef FORMATUTILS_H
#define FORMATUTILS_H

#include <QString>
#include <QDateTime>
#include <QObject>
#include <QtGlobal>

/**
 * @class FormatUtils
 * @brief 格式化工具类
 *
 * @details 提供以下格式化功能：
 * - 字节数格式化（如 1024 -> "1.00 KB"）
 * - 网络速度格式化（如 1048576 -> "1.00 MB/s"）
 * - 时长格式化（如 3665 -> "1h 1m 5s"）
 * - 相对时间格式化（如 "2小时前"）
 * - 日期时间格式化
 *
 * @note 此类设计为QML单例，所有方法都是静态的
 */
class FormatUtils : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象指针
     */
    explicit FormatUtils(QObject *parent = nullptr) : QObject(parent) {}

    /**
     * @brief 格式化字节数为人类可读格式
     * @param bytes 字节数
     * @return 格式化后的字符串（如 "1.50 GB"）
     *
     * @details 自动选择合适的单位：B, KB, MB, GB, TB
     */
    Q_INVOKABLE static QString formatBytes(quint64 bytes);

    /**
     * @brief 格式化网络速度为人类可读格式
     * @param bytesPerSecond 每秒字节数
     * @return 格式化后的字符串（如 "2.50 MB/s"）
     *
     * @details 自动选择合适的单位：B/s, KB/s, MB/s, GB/s
     */
    Q_INVOKABLE static QString formatSpeed(quint64 bytesPerSecond);

    /**
     * @brief 格式化时长为可读格式
     * @param seconds 秒数
     * @return 格式化后的字符串（如 "1h 30m 25s"）
     *
     * @details 格式示例：
     * - 小于60秒: "45s"
     * - 小于1小时: "15m 30s"
     * - 超过1小时: "2h 15m 30s"
     */
    Q_INVOKABLE static QString formatDuration(qint64 seconds);

    /**
     * @brief 格式化相对时间（多久之前）
     * @param dateTime 要格式化的日期时间
     * @return 相对时间字符串（如 "3小时前"、"昨天"）
     *
     * @details 格式示例：
     * - 小于1分钟: "刚刚"
     * - 小于1小时: "15分钟前"
     * - 小于1天: "3小时前"
     * - 小于7天: "2天前"
     * - 超过7天: 具体日期
     */
    Q_INVOKABLE static QString formatTimeAgo(const QDateTime& dateTime);

    /**
     * @brief 格式化日期时间
     * @param dateTime 要格式化的日期时间
     * @return 格式化后的日期时间字符串（如 "2025-01-01 12:30:45"）
     */
    Q_INVOKABLE static QString formatDateTime(const QDateTime& dateTime);
};

#endif // FORMATUTILS_H