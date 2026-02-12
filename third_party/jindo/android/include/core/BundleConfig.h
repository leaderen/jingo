/**
 * @file BundleConfig.h
 * @brief Bundle configuration reader for cross-platform app customization
 *
 * @details Reads configuration from a JSON file embedded in the app bundle.
 * Supports signature verification to prevent tampering.
 *
 * Configuration file formats:
 *
 * 1. Signed config (production):
 * {
 *   "__signed": true,
 *   "config": { ... actual config ... },
 *   "signature": "Base64 RSA-SHA256 signature"
 * }
 *
 * 2. Plain config (development):
 * { ... config fields directly ... }
 *
 * 动态授权信息（过期时间、设备数等）通过 LicenseManager 从服务器获取。
 */

#ifndef BUNDLECONFIG_H
#define BUNDLECONFIG_H

#include <QObject>
#include <QString>
#include <QJsonObject>

class BundleConfig : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString panelType READ panelType NOTIFY configChanged)
    Q_PROPERTY(QString panelUrl READ panelUrl NOTIFY configChanged)
    Q_PROPERTY(QString appName READ appName NOTIFY configChanged)
    Q_PROPERTY(QString supportEmail READ supportEmail NOTIFY configChanged)
    Q_PROPERTY(QString privacyPolicyUrl READ privacyPolicyUrl NOTIFY configChanged)
    Q_PROPERTY(QString termsOfServiceUrl READ termsOfServiceUrl NOTIFY configChanged)
    Q_PROPERTY(QString telegramUrl READ telegramUrl NOTIFY configChanged)
    Q_PROPERTY(QString discordUrl READ discordUrl NOTIFY configChanged)
    Q_PROPERTY(QString docsUrl READ docsUrl NOTIFY configChanged)
    Q_PROPERTY(QString issuesUrl READ issuesUrl NOTIFY configChanged)
    Q_PROPERTY(QString latencyTestUrl READ latencyTestUrl NOTIFY configChanged)
    Q_PROPERTY(QString ipInfoUrl READ ipInfoUrl NOTIFY configChanged)
    Q_PROPERTY(QString speedTestBaseUrl READ speedTestBaseUrl NOTIFY configChanged)
    Q_PROPERTY(bool hideSubscriptionBlock READ hideSubscriptionBlock NOTIFY configChanged)
    Q_PROPERTY(QString updateCheckUrl READ updateCheckUrl NOTIFY configChanged)
    Q_PROPERTY(QString licenseUrl READ licenseUrl NOTIFY configChanged)

    // License properties
    Q_PROPERTY(QString licenseId READ licenseId NOTIFY configChanged)
    Q_PROPERTY(QString vendorId READ vendorId NOTIFY configChanged)
    Q_PROPERTY(QString vendorName READ vendorName NOTIFY configChanged)
    Q_PROPERTY(QString licenseServerUrl READ licenseServerUrl NOTIFY configChanged)

    // Signature status
    Q_PROPERTY(bool isSigned READ isSigned NOTIFY configChanged)
    Q_PROPERTY(bool isSignatureValid READ isSignatureValid NOTIFY configChanged)

public:
    static BundleConfig& instance();

    // =============================================
    // Application Settings
    // =============================================

    QString panelType() const;
    QString panelUrl() const;
    QString appName() const;
    QString supportEmail() const;
    QString privacyPolicyUrl() const;
    QString termsOfServiceUrl() const;
    QString telegramUrl() const;
    QString discordUrl() const;
    QString docsUrl() const;
    QString issuesUrl() const;
    QString latencyTestUrl() const;
    QString ipInfoUrl() const;
    QString speedTestBaseUrl() const;
    bool hideSubscriptionBlock() const;
    QString updateCheckUrl() const;
    QString licenseUrl() const;

    // =============================================
    // License Configuration
    // =============================================

    QString licenseId() const;
    QString vendorId() const;
    QString vendorName() const;
    QString licenseServerUrl() const;
    int licenseCheckInterval() const;
    int offlineGracePeriod() const;

    // =============================================
    // Signature Verification
    // =============================================

    /**
     * @brief Check if config file has signature
     */
    bool isSigned() const { return m_isSigned; }

    /**
     * @brief Check if signature is valid (only meaningful if isSigned() is true)
     */
    bool isSignatureValid() const { return m_isSignatureValid; }

    /**
     * @brief Check if config is tampered (signed but signature invalid)
     */
    bool isTampered() const { return m_isSigned && !m_isSignatureValid; }

    // =============================================
    // General Methods
    // =============================================

    Q_INVOKABLE QString getValue(const QString& key, const QString& defaultValue = QString()) const;
    Q_INVOKABLE void reload();
    bool isValid() const;
    QString configFilePath() const;

    // =============================================
    // Runtime Feature Flags (set by JinGo before loading config)
    // =============================================

    /**
     * @brief Enable/disable signature verification at runtime
     * @details Call before reload(). Default: false (disabled).
     *          CI builds should call setSignatureVerifyEnabled(true).
     */
    static void setSignatureVerifyEnabled(bool enabled) { s_signatureVerifyEnabled = enabled; }
    static bool signatureVerifyEnabled() { return s_signatureVerifyEnabled; }

    /**
     * @brief Enable/disable license check at runtime
     * @details Call before VPNManager is constructed. Default: false (disabled).
     *          CI builds should call setLicenseCheckEnabled(true).
     */
    static void setLicenseCheckEnabled(bool enabled) { s_licenseCheckEnabled = enabled; }
    static bool licenseCheckEnabled() { return s_licenseCheckEnabled; }

signals:
    void configChanged();

    /**
     * @brief Emitted when config file signature verification fails
     */
    void configTampered(const QString& message);

private:
    explicit BundleConfig(QObject* parent = nullptr);
    ~BundleConfig() = default;

    BundleConfig(const BundleConfig&) = delete;
    BundleConfig& operator=(const BundleConfig&) = delete;

    QString findConfigFile() const;
    void loadConfig();
    bool loadSignedConfig(const QJsonObject& rootObj);
    bool verifySignature(const QByteArray& data, const QByteArray& signature);

    QJsonObject m_config;
    QString m_configPath;
    bool m_isValid;
    bool m_isSigned;
    bool m_isSignatureValid;

    // Default values
    static const QString DEFAULT_PANEL_URL;
    static const QString DEFAULT_APP_NAME;
    static const QString DEFAULT_LATENCY_TEST_URL;
    static const QString DEFAULT_IP_INFO_URL;
    static const QString DEFAULT_SPEED_TEST_BASE_URL;
    static const QString DEFAULT_LICENSE_SERVER_URL;
    static const int DEFAULT_LICENSE_CHECK_INTERVAL;
    static const int DEFAULT_OFFLINE_GRACE_PERIOD;

    // Runtime feature flags
    static bool s_signatureVerifyEnabled;
    static bool s_licenseCheckEnabled;
};

#endif // BUNDLECONFIG_H
