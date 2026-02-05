#ifndef LICENSEMANAGER_H
#define LICENSEMANAGER_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QJsonObject>
#include <QTimer>

class QNetworkAccessManager;
class QNetworkReply;

/**
 * @brief 授权管理器
 *
 * 管理应用的授权验证，包括：
 * - 解密并加载授权配置
 * - 本地有效期验证
 * - 在线授权验证
 * - 设备数量限制检查
 * - 离线宽限期管理
 */
class LicenseManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isValid READ isValid NOTIFY licenseStatusChanged)
    Q_PROPERTY(QString vendorName READ vendorName NOTIFY licenseStatusChanged)
    Q_PROPERTY(QString licenseId READ licenseId NOTIFY licenseStatusChanged)
    Q_PROPERTY(QDateTime expiresAt READ expiresAt NOTIFY licenseStatusChanged)
    Q_PROPERTY(int remainingDays READ remainingDays NOTIFY licenseStatusChanged)
    Q_PROPERTY(int maxDevices READ maxDevices NOTIFY licenseStatusChanged)
    Q_PROPERTY(int activeDevices READ activeDevices NOTIFY licenseStatusChanged)
    Q_PROPERTY(bool isOfflineMode READ isOfflineMode NOTIFY offlineModeChanged)

public:
    /**
     * @brief 获取单例实例
     */
    static LicenseManager& instance();

    /**
     * @brief 初始化授权管理器
     *
     * 解密配置并进行本地验证。
     * @return 初始化成功返回 true
     */
    bool initialize();

    /**
     * @brief 执行在线验证
     *
     * 异步验证授权状态，结果通过信号通知。
     */
    Q_INVOKABLE void verifyOnline();

    /**
     * @brief 检查是否需要强制在线验证
     * @return 超过离线宽限期返回 true
     */
    bool requiresOnlineVerification() const;

    // 属性访问器
    bool isValid() const { return m_isValid; }
    QString vendorName() const { return m_vendorName; }
    QString vendorId() const { return m_vendorId; }
    QString licenseId() const { return m_licenseId; }
    QDateTime expiresAt() const { return m_expiresAt; }
    int remainingDays() const;
    int maxDevices() const { return m_maxDevices; }
    int activeDevices() const { return m_activeDevices; }
    bool isOfflineMode() const { return m_isOfflineMode; }
    QString licenseServerUrl() const { return m_licenseServerUrl; }

signals:
    /**
     * @brief 授权状态变化
     */
    void licenseStatusChanged();

    /**
     * @brief 授权有效
     */
    void licenseValid();

    /**
     * @brief 授权已过期
     * @param message 过期提示信息
     */
    void licenseExpired(const QString& message);

    /**
     * @brief 设备数量超限
     * @param message 超限提示信息
     */
    void deviceLimitExceeded(const QString& message);

    /**
     * @brief 需要更新应用
     * @param message 更新提示信息
     * @param updateUrl 更新链接
     */
    void updateRequired(const QString& message, const QString& updateUrl);

    /**
     * @brief 验证失败（网络错误等）
     * @param error 错误信息
     */
    void verificationFailed(const QString& error);

    /**
     * @brief 离线模式状态变化
     */
    void offlineModeChanged();

    /**
     * @brief 需要退出应用
     * @param title 对话框标题
     * @param message 对话框消息
     */
    void exitRequired(const QString& title, const QString& message);

private:
    explicit LicenseManager(QObject* parent = nullptr);
    ~LicenseManager() override;

    // 禁止拷贝
    LicenseManager(const LicenseManager&) = delete;
    LicenseManager& operator=(const LicenseManager&) = delete;

    /**
     * @brief 解密配置文件
     * @return 解密成功返回 true
     */
    bool decryptConfig();

    /**
     * @brief 检查本地有效性
     * @return 本地验证通过返回 true
     */
    bool checkLocalValidity();

    /**
     * @brief 处理在线验证响应
     * @param response 服务器响应
     */
    void handleVerifyResponse(const QJsonObject& response);

    /**
     * @brief 处理网络错误
     * @param error 错误信息
     */
    void handleNetworkError(const QString& error);

    /**
     * @brief 安排下次验证
     */
    void scheduleNextCheck();

    /**
     * @brief 保存验证缓存
     */
    void saveVerificationCache();

    /**
     * @brief 加载验证缓存
     */
    void loadVerificationCache();

    /**
     * @brief 注册设备
     */
    void registerDevice();

private slots:
    void onVerifyReplyFinished();

private:
    // 授权信息
    QString m_licenseId;
    QString m_vendorId;
    QString m_vendorName;
    QDateTime m_issuedAt;
    QDateTime m_expiresAt;
    int m_maxDevices = 0;
    int m_activeDevices = 0;
    QStringList m_features;

    // 服务器配置
    QString m_licenseServerUrl;
    int m_checkInterval = 86400;        // 默认 24 小时
    int m_offlineGracePeriod = 604800;  // 默认 7 天

    // 状态
    bool m_isValid = false;
    bool m_isOfflineMode = false;
    bool m_isInitialized = false;

    // 验证缓存
    QDateTime m_lastOnlineCheck;
    QString m_cachedDeviceId;
    qint64 m_serverTimeOffset = 0;  // 服务器时间与本地时间的偏移量（秒）

    // 网络
    QNetworkAccessManager* m_networkManager = nullptr;
    QNetworkReply* m_currentReply = nullptr;

    // 定时器
    QTimer* m_checkTimer = nullptr;
};

#endif // LICENSEMANAGER_H
