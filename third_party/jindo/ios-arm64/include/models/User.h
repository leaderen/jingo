/**
 * @file User.h
 * @brief 用户数据模型头文件
 * @details 定义用户信息模型，包括基本信息、会员状态、流量统计等
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef USER_H
#define USER_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QJsonObject>
#include <QTimeZone>

// 前向声明：User 类
class User : public QObject
{
    Q_OBJECT

    /// 用户唯一标识符（只读）
    Q_PROPERTY(QString id READ id CONSTANT)

    /// 邮箱地址（可读写，变化时发出 emailChanged 信号）
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)

    /// 头像 URL（可读写，变化时发出 avatarUrlChanged 信号）
    Q_PROPERTY(QString avatarUrl READ avatarUrl WRITE setAvatarUrl NOTIFY avatarUrlChanged)

    /// 订阅计划 ID (只读，用于判断是否为付费会员)
    Q_PROPERTY(int planId READ planId NOTIFY planIdChanged)

    /// 会员过期时间（可读写，变化时发出 expiryDateChanged 信号）
    Q_PROPERTY(QDateTime expiryDate READ expiryDate WRITE setExpiryDate NOTIFY expiryDateChanged)

    /// 距离过期的天数（只读，过期时间变化时发出 expiryDateChanged 信号）
    Q_PROPERTY(int daysUntilExpiry READ daysUntilExpiry NOTIFY expiryDateChanged)

    /// 是否为付费会员 (只读计算属性，基于 planId 判断)
    Q_PROPERTY(bool isPremium READ isPremium NOTIFY planIdChanged)

public:
    /**
     * @brief 构造函数
     * @param parent 父对象指针，用于 Qt 对象树管理
     */
    explicit User(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~User() override;

    // ========== 基本信息 Getters/Setters ==========

    /**
     * @brief 获取用户 ID
     * @return QString 用户唯一标识符（UUID 格式，无大括号）
     */
    QString id() const;

    /**
     * @brief 设置用户 ID
     * @param id 新的用户 ID
     */
    void setId(const QString& id);

    /**
     * @brief 获取邮箱地址
     * @return QString 用户邮箱
     */
    QString email() const;

    /**
     * @brief 设置邮箱地址
     * @param email 新的邮箱地址
     * @details 如果邮箱发生变化，会发出 emailChanged() 信号
     */
    void setEmail(const QString& email);

    /**
     * @brief 获取头像 URL
     * @return QString 头像图片的网络地址或本地路径
     */
    QString avatarUrl() const;

    /**
     * @brief 设置头像 URL
     * @param url 新的头像地址
     * @details 如果头像 URL 发生变化，会发出 avatarUrlChanged() 信号
     */
    void setAvatarUrl(const QString& url);

    // ========== 会员状态 Getters/Setters ==========

    /**
     * @brief 获取订阅计划 ID
     * @return int 订阅计划 ID。0 或负数表示免费用户
     */
    int planId() const;

    /**
     * @brief 设置订阅计划 ID
     * @param id 新的计划 ID
     * @details 如果计划 ID 发生变化，会发出 planIdChanged() 信号
     */
    void setPlanId(int id);

    /**
     * @brief 检查是否为付费会员（计算属性）
     * @return bool true 表示付费会员（planId > 0），false 表示免费用户
     */
    bool isPremium() const;

    /**
     * @brief 获取会员过期时间
     * @return QDateTime 会员到期的日期时间
     * @note 如果返回无效的 QDateTime，表示永久会员
     */
    QDateTime expiryDate() const;

    /**
     * @brief 设置会员过期时间
     * @param date 到期时间
     * @details 如果过期时间发生变化，会发出 expiryDateChanged() 信号
     */
    void setExpiryDate(const QDateTime& date);

    // ========== 时间信息 Getters/Setters ==========

    /**
     * @brief 获取账户创建时间
     * @return QDateTime 账户创建的日期时间
     */
    QDateTime createdAt() const;

    /**
     * @brief 设置账户创建时间
     * @param date 创建时间
     */
    void setCreatedAt(const QDateTime& date);

    /**
     * @brief 获取最后登录时间
     * @return QDateTime 最后一次登录的日期时间
     */
    QDateTime lastLogin() const;

    /**
     * @brief 设置最后登录时间
     * @param date 最后登录时间
     */
    void setLastLogin(const QDateTime& date);

    // ========== 额外信息 Getters/Setters ==========
    QString phoneNumber() const;
    void setPhoneNumber(const QString& phone);
    QString fullName() const;
    void setFullName(const QString& name);
    QString country() const;
    void setCountry(const QString& country);

    // ========== 统计信息 Getters/Setters ==========
    qint64 totalTraffic() const;
    void setTotalTraffic(qint64 bytes);
    qint64 usedTraffic() const;
    void setUsedTraffic(qint64 bytes);
    qint64 remainingTraffic() const;

    // ========== 订阅信息 Getters/Setters ==========
    QString subscribeUrl() const;
    void setSubscribeUrl(const QString& url);
    QString subscribeToken() const;
    void setSubscribeToken(const QString& token);

    // ========== 序列化/反序列化 ==========

    /**
     * @brief 将用户信息序列化为 JSON 对象
     * @return QJsonObject 包含用户完整信息的 JSON 对象
     */
    QJsonObject toJson() const;

    /**
     * @brief 从 JSON 对象创建 User 实例（兼容本地和 V2Board 格式）
     * @param json JSON 对象，包含用户信息
     * @param parent 父对象指针
     * @return User* 创建的用户对象指针，失败返回 nullptr
     */
    static User* fromJson(const QJsonObject& json, QObject* parent = nullptr);

    // ========== 验证/计算 ==========

    /**
     * @brief 检查用户信息是否有效
     * @return bool true 表示有效，false 表示无效
     */
    bool isValid() const;

    /**
     * @brief 检查会员是否已过期
     * @return bool true 表示已过期，false 表示未过期或永久会员
     */
    bool isExpired() const;

    /**
     * @brief 获取距离过期的天数
     * @return int 剩余天数
     */
    int daysUntilExpiry() const;

    /**
     * @brief 获取流量使用百分比
     * @return double 使用百分比，范围 0.0 - 100.0
     */
    double trafficUsagePercent() const;

    // ========== 格式化输出 ==========
    Q_INVOKABLE QString formatTraffic() const;
    Q_INVOKABLE QString formatExpiryDate() const;

signals:
    /**
     * @brief 邮箱变化信号
     */
    void emailChanged();

    /**
     * @brief 头像 URL 变化信号
     */
    void avatarUrlChanged();

    /**
     * @brief 计划 ID 变化信号
     */
    void planIdChanged();

    /**
     * @brief 过期时间变化信号
     */
    void expiryDateChanged();

    /**
     * @brief 流量信息变化信号
     */
    void trafficChanged();

private:
    QString m_id;              ///< 用户唯一标识符
    QString m_email;           ///< 邮箱地址
    QString m_avatarUrl;       ///< 头像 URL
    int m_planId;              ///< 订阅计划 ID
    QDateTime m_expiryDate;    ///< 会员过期时间
    QDateTime m_createdAt;     ///< 账户创建时间
    QDateTime m_lastLogin;     ///< 最后登录时间
    QString m_phoneNumber;     ///< 手机号码
    QString m_fullName;        ///< 全名
    QString m_country;         ///< 国家
    qint64 m_totalTraffic;     ///< 总流量配额（字节）
    qint64 m_usedTraffic;      ///< 已使用流量（字节）
    QString m_subscribeUrl;    ///< 订阅链接
    QString m_subscribeToken;  ///< 订阅令牌
};

#endif // USER_H