/**
 * @file Plan.h
 * @brief 订阅计划数据模型头文件
 * @details 定义订阅计划信息模型，用于 XBoard 的套餐管理
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef PLAN_H
#define PLAN_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include <QStringList>

/**
 * @class Plan
 * @brief 订阅计划数据模型
 *
 * @details
 * 用于存储和管理 XBoard 订阅计划信息，包括：
 * - 基本信息（ID、名称、价格、周期）
 * - 流量信息（流量配额、限速）
 * - 设备限制
 * - 特性列表
 * - 状态标记（推荐、热门等）
 */
class Plan : public QObject
{
    Q_OBJECT

    /// 计划ID（只读）
    Q_PROPERTY(int planId READ planId CONSTANT)

    /// 计划名称
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)

    /// 价格
    Q_PROPERTY(double price READ price NOTIFY priceChanged)

    /// 原价（用于显示折扣）
    Q_PROPERTY(double originalPrice READ originalPrice NOTIFY originalPriceChanged)

    /// 货币符号
    Q_PROPERTY(QString currency READ currency NOTIFY currencyChanged)

    /// 周期类型（月/季/年）
    Q_PROPERTY(QString period READ period NOTIFY periodChanged)

    /// 流量配额（字节）
    Q_PROPERTY(qint64 dataLimit READ dataLimit NOTIFY dataLimitChanged)

    /// 设备数量限制
    Q_PROPERTY(int deviceLimit READ deviceLimit NOTIFY deviceLimitChanged)

    /// 限速（Mbps）
    Q_PROPERTY(int speedLimit READ speedLimit NOTIFY speedLimitChanged)

    /// 是否推荐
    Q_PROPERTY(bool isRecommended READ isRecommended NOTIFY isRecommendedChanged)

    /// 是否热门
    Q_PROPERTY(bool isPopular READ isPopular NOTIFY isPopularChanged)

    /// 是否可用
    Q_PROPERTY(bool isAvailable READ isAvailable NOTIFY isAvailableChanged)

    /// 特性列表
    Q_PROPERTY(QStringList features READ features NOTIFY featuresChanged)

public:
    /**
     * @brief 构造函数
     * @param parent 父对象指针
     */
    explicit Plan(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~Plan() override;

    // ========== 基本信息 Getters/Setters ==========

    /**
     * @brief 获取计划ID
     * @return int 计划唯一标识符
     */
    int planId() const;

    /**
     * @brief 设置计划ID
     * @param id 计划ID
     */
    void setPlanId(int id);

    /**
     * @brief 获取计划名称
     * @return QString 计划名称
     */
    QString name() const;

    /**
     * @brief 设置计划名称
     * @param name 计划名称
     */
    void setName(const QString& name);

    /**
     * @brief 获取价格
     * @return double 价格
     */
    double price() const;

    /**
     * @brief 设置价格
     * @param price 价格
     */
    void setPrice(double price);

    /**
     * @brief 获取原价
     * @return double 原价（0表示无折扣）
     */
    double originalPrice() const;

    /**
     * @brief 设置原价
     * @param price 原价
     */
    void setOriginalPrice(double price);

    /**
     * @brief 获取货币符号
     * @return QString 货币符号（如 "¥", "$"）
     */
    QString currency() const;

    /**
     * @brief 设置货币符号
     * @param currency 货币符号
     */
    void setCurrency(const QString& currency);

    /**
     * @brief 获取周期类型
     * @return QString 周期类型（如 "月", "季", "年"）
     */
    QString period() const;

    /**
     * @brief 设置周期类型
     * @param period 周期类型
     */
    void setPeriod(const QString& period);

    // ========== 流量和限制 Getters/Setters ==========

    /**
     * @brief 获取流量配额
     * @return qint64 流量配额（字节）
     */
    qint64 dataLimit() const;

    /**
     * @brief 设置流量配额
     * @param bytes 流量配额（字节）
     */
    void setDataLimit(qint64 bytes);

    /**
     * @brief 获取设备数量限制
     * @return int 设备数量限制
     */
    int deviceLimit() const;

    /**
     * @brief 设置设备数量限制
     * @param limit 设备数量限制
     */
    void setDeviceLimit(int limit);

    /**
     * @brief 获取限速
     * @return int 限速（Mbps）
     */
    int speedLimit() const;

    /**
     * @brief 设置限速
     * @param speed 限速（Mbps）
     */
    void setSpeedLimit(int speed);

    // ========== 状态标记 Getters/Setters ==========

    /**
     * @brief 是否为推荐计划
     * @return bool true 表示推荐
     */
    bool isRecommended() const;

    /**
     * @brief 设置是否推荐
     * @param recommended 是否推荐
     */
    void setIsRecommended(bool recommended);

    /**
     * @brief 是否为热门计划
     * @return bool true 表示热门
     */
    bool isPopular() const;

    /**
     * @brief 设置是否热门
     * @param popular 是否热门
     */
    void setIsPopular(bool popular);

    /**
     * @brief 是否可用
     * @return bool true 表示可用
     */
    bool isAvailable() const;

    /**
     * @brief 设置是否可用
     * @param available 是否可用
     */
    void setIsAvailable(bool available);

    // ========== 特性列表 Getters/Setters ==========

    /**
     * @brief 获取特性列表
     * @return QStringList 特性列表
     */
    QStringList features() const;

    /**
     * @brief 设置特性列表
     * @param features 特性列表
     */
    void setFeatures(const QStringList& features);

    /**
     * @brief 添加特性
     * @param feature 特性描述
     */
    void addFeature(const QString& feature);

    // ========== 序列化/反序列化 ==========

    /**
     * @brief 将计划信息序列化为 JSON 对象
     * @return QJsonObject 包含计划信息的 JSON 对象
     */
    QJsonObject toJson() const;

    /**
     * @brief 从 JSON 对象创建 Plan 实例
     * @param json JSON 对象，包含计划信息
     * @param parent 父对象指针
     * @return Plan* 创建的计划对象指针，失败返回 nullptr
     */
    static Plan* fromJson(const QJsonObject& json, QObject* parent = nullptr);

    // ========== 格式化输出 ==========

    /**
     * @brief 格式化价格显示
     * @return QString 格式化的价格字符串（如 "¥99.00/月"）
     */
    Q_INVOKABLE QString formatPrice() const;

    /**
     * @brief 格式化流量显示
     * @return QString 格式化的流量字符串（如 "100 GB"）
     */
    Q_INVOKABLE QString formatDataLimit() const;

    /**
     * @brief 格式化限速显示
     * @return QString 格式化的限速字符串（如 "100 Mbps"）
     */
    Q_INVOKABLE QString formatSpeedLimit() const;

signals:
    void nameChanged();
    void priceChanged();
    void originalPriceChanged();
    void currencyChanged();
    void periodChanged();
    void dataLimitChanged();
    void deviceLimitChanged();
    void speedLimitChanged();
    void isRecommendedChanged();
    void isPopularChanged();
    void isAvailableChanged();
    void featuresChanged();

private:
    int m_planId;              ///< 计划ID
    QString m_name;            ///< 计划名称
    double m_price;            ///< 价格
    double m_originalPrice;    ///< 原价
    QString m_currency;        ///< 货币符号
    QString m_period;          ///< 周期类型
    qint64 m_dataLimit;        ///< 流量配额（字节）
    int m_deviceLimit;         ///< 设备数量限制
    int m_speedLimit;          ///< 限速（Mbps）
    bool m_isRecommended;      ///< 是否推荐
    bool m_isPopular;          ///< 是否热门
    bool m_isAvailable;        ///< 是否可用
    QStringList m_features;    ///< 特性列表
};

#endif // PLAN_H
