/**
 * @file ApiClient.h
 * @brief HTTP API 客户端头文件
 * @details 提供统一的网络请求接口，支持 RESTful API 调用、Token 管理、文件下载等功能
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef APICLIENT_H
#define APICLIENT_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonDocument>
#include <QStringList>
#include <functional>

// ============================================================================
// 常量定义
// ============================================================================

/**
 * @brief API 配置常量命名空间
 * @details 使用匿名命名空间限制常量作用域，避免符号冲突
 */
namespace {
    /**
     * @brief XBoard API 基础 URL（默认为空，强制从 BundleConfig 读取）
     */
    const QString API_BASE_URL = "";
}

// ============================================================================
// ApiClient 类定义
// ============================================================================

/**
 * @class ApiClient
 * @brief 统一的 HTTP API 客户端（单例模式）
 *
 * @details
 * 核心功能：
 * - 单例设计：全局唯一的网络请求管理器
 * - 支持 RESTful：GET、POST、PUT、DELETE、PATCH
 * - 自动 Token 管理：登录后自动在请求头携带 Authorization
 * - JSON 解析：自动解析响应并通过槽函数回调
 * - 错误处理：统一的网络错误和业务错误处理
 * - 进度反馈：支持下载进度监听
 * - 超时控制：可配置请求超时时间
 *
 * @note 线程安全：单例实例在多线程环境下是安全的（C++11 保证）
 *
 * @example 基本使用示例
 * @code
 * // 1. 获取单例实例
 * ApiClient& client = ApiClient::instance();
 *
 * // 2. 设置 Token（登录后）
 * client.setAuthToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");
 *
 * // 3. 发起 GET 请求
 * client.get("/user/profile", this,
 *            SLOT(onProfileSuccess(QJsonObject)),
 *            SLOT(onProfileError(QString)));
 *
 * // 4. 发起 POST 请求
 * QJsonObject data;
 * data["email"] = "user@example.com";
 * data["password"] = "123456";
 * client.post("/auth/login", data, this,
 *             SLOT(onLoginSuccess(QJsonObject)),
 *             SLOT(onLoginError(QString)));
 * @endcode
 */
class ApiClient : public QObject
{
    Q_OBJECT

public:
    // ========================================================================
    // Lambda 回调类型定义
    // ========================================================================

    using SuccessCallback = std::function<void(const QJsonObject&)>;
    using ErrorCallback = std::function<void(const QString&)>;
    using DownloadCallback = std::function<void(const QByteArray&)>;

    // ========================================================================
    // 枚举类型
    // ========================================================================

    /**
     * @enum Method
     * @brief HTTP 请求方法枚举
     * @details 支持标准的 RESTful API 方法
     */
    enum Method {
        GET,    ///< 获取资源
        POST,   ///< 创建资源
        PUT,    ///< 完整更新资源
        DELETE, ///< 删除资源
        PATCH   ///< 部分更新资源
    };

    // ========================================================================
    // 单例访问
    // ========================================================================

    /**
     * @brief 获取 ApiClient 单例实例
     * @return ApiClient& 全局唯一实例的引用
     * @note 线程安全（C++11 静态局部变量保证）
     */
    static ApiClient& instance();

    // ========================================================================
    // 配置接口
    // ========================================================================

    /**
     * @brief 设置 API 基础 URL
     * @param url 基础 URL 地址（如 "https://api.example.com"）
     * @note 末尾的斜杠会被自动移除，避免拼接时出现双斜杠
     * @see baseUrl()
     */
    void setBaseUrl(const QString& url);

    /**
     * @brief 获取当前 API 基础 URL
     * @return QString 当前配置的基础 URL
     * @see setBaseUrl()
     */
    QString baseUrl() const;

    /**
     * @brief 设置身份验证 Token
     * @param token JWT 或其他格式的认证令牌
     * @details 设置后，所有请求会自动在 Header 中添加：
     *          Authorization: Bearer {token}
     * @note 通常在登录成功后调用此方法
     * @see authToken(), clearAuthToken()
     */
    void setAuthToken(const QString& token);

    /**
     * @brief 获取当前身份验证 Token
     * @return QString 当前存储的 Token（可能为空）
     * @see setAuthToken()
     */
    QString authToken() const;

    /**
     * @brief 清除身份验证 Token
     * @details 用于用户登出场景，清空后后续请求将不再携带 Authorization 头
     * @note 通常在用户主动登出或 Token 过期时调用
     * @see setAuthToken()
     */
    void clearAuthToken();

    /**
     * @brief 获取最近一次失败请求的 HTTP 状态码
     * @return int HTTP 状态码，0 表示网络层错误（未收到 HTTP 响应）
     * @note 用于区分网络连接错误（0）和服务器拒绝（401/403 等）
     */
    int lastHttpStatusCode() const;

    /**
     * @brief 更新备用 URL 列表（从 API 响应中获取）
     * @param urls 备用 URL 列表
     */
    void updateFallbackUrls(const QStringList& urls);

    /**
     * @brief 设置请求超时时间
     * @param timeout 超时时间（毫秒），0 表示无限等待（不推荐）
     * @note 若传入负数会自动修正为 0
     * @warning 超时时间过短可能导致请求频繁失败
     * @see timeout()
     */
    void setTimeout(int timeout);

    /**
     * @brief 获取当前超时配置
     * @return int 超时时间（毫秒）
     * @see setTimeout()
     */
    int timeout() const;

    // ========================================================================
    // 核心请求接口
    // ========================================================================

    /**
     * @brief 执行通用 HTTP 请求
     * @param method HTTP 方法（GET/POST/PUT/DELETE/PATCH）
     * @param endpoint API 端点路径（如 "/api/v1/login"）
     * @param data 请求体数据（JSON 对象），GET/DELETE 可传空对象
     * @param receiver 回调接收对象指针
     * @param successSlot 成功回调槽函数（签名：void(QJsonObject)）
     * @param errorSlot 失败回调槽函数（签名：void(QString)）
     *
     * @details
     * 执行流程：
     * 1. 拼接完整 URL = baseUrl + endpoint
     * 2. 添加标准请求头（Content-Type、User-Agent、Authorization 等）
     * 3. 发起异步网络请求
     * 4. 等待响应完成
     * 5. 检查网络错误 → 解析 JSON → 检查业务错误 → 回调
     *
     * @note
     * - 槽函数必须使用 Q_INVOKABLE 或 slots 标记
     * - 回调采用队列连接（Qt::QueuedConnection），避免阻塞
     * - 响应会自动解析为 QJsonObject
     *
     * @warning
     * - receiver 对象必须存活到回调执行，否则会崩溃
     * - 建议在对象析构前断开所有请求或使用 QPointer
     *
     * @example
     * @code
     * QJsonObject loginData;
     * loginData["email"] = "user@example.com";
     * loginData["password"] = "secret";
     *
     * ApiClient::instance().request(
     *     ApiClient::POST,
     *     "/auth/login",
     *     loginData,
     *     this,
     *     SLOT(onLoginSuccess(QJsonObject)),
     *     SLOT(onLoginError(QString))
     * );
     * @endcode
     *
     * @see get(), post()
     */
    void request(Method method,
                 const QString& endpoint,
                 const QJsonObject& data = QJsonObject(),
                 QObject* receiver = nullptr,
                 const char* successSlot = nullptr,
                 const char* errorSlot = nullptr);

    /**
     * @brief 执行通用 HTTP 请求（Lambda 回调版本）
     * @param method HTTP 方法
     * @param endpoint API 端点路径
     * @param data 请求体数据
     * @param onSuccess 成功回调函数
     * @param onError 错误回调函数
     */
    void request(Method method,
                 const QString& endpoint,
                 const QJsonObject& data,
                 SuccessCallback onSuccess,
                 ErrorCallback onError);

    // ========================================================================
    // 便捷请求接口
    // ========================================================================

    /**
     * @brief 发起 GET 请求
     * @param endpoint API 端点路径
     * @param receiver 回调接收对象
     * @param successSlot 成功回调槽（签名：void(QJsonObject)）
     * @param errorSlot 失败回调槽（签名：void(QString)）
     *
     * @details
     * GET 请求的简化封装，无需传递请求体数据
     *
     * @example
     * @code
     * // 获取用户订阅信息
     * ApiClient::instance().get(
     *     "/user/subscribe",
     *     this,
     *     SLOT(onSubscribeLoaded(QJsonObject)),
     *     SLOT(onError(QString))
     * );
     * @endcode
     *
     * @see request()
     */
    void get(const QString& endpoint,
             QObject* receiver = nullptr,
             const char* successSlot = nullptr,
             const char* errorSlot = nullptr);

    /**
     * @brief 发起 GET 请求（Lambda 回调版本）
     * @param endpoint API 端点路径
     * @param onSuccess 成功回调函数
     * @param onError 错误回调函数
     */
    void get(const QString& endpoint,
             SuccessCallback onSuccess,
             ErrorCallback onError);

    /**
     * @brief 发起 POST 请求
     * @param endpoint API 端点路径
     * @param data 请求体 JSON 数据
     * @param receiver 回调接收对象
     * @param successSlot 成功回调槽（签名：void(QJsonObject)）
     * @param errorSlot 失败回调槽（签名：void(QString)）
     *
     * @details
     * POST 请求的简化封装，用于创建资源或提交表单
     *
     * @example
     * @code
     * // 用户注册
     * QJsonObject registerData;
     * registerData["email"] = "newuser@example.com";
     * registerData["password"] = "password123";
     * registerData["invite_code"] = "ABC123";
     *
     * ApiClient::instance().post(
     *     "/auth/register",
     *     registerData,
     *     this,
     *     SLOT(onRegisterSuccess(QJsonObject)),
     *     SLOT(onRegisterError(QString))
     * );
     * @endcode
     *
     * @see request()
     */
    void post(const QString& endpoint,
              const QJsonObject& data,
              QObject* receiver = nullptr,
              const char* successSlot = nullptr,
              const char* errorSlot = nullptr);

    /**
     * @brief 发起 POST 请求（Lambda 回调版本）
     * @param endpoint API 端点路径
     * @param data 请求体 JSON 数据
     * @param onSuccess 成功回调函数
     * @param onError 错误回调函数
     */
    void post(const QString& endpoint,
              const QJsonObject& data,
              SuccessCallback onSuccess,
              ErrorCallback onError);

    /**
     * @brief 发起 POST 请求（表单格式，application/x-www-form-urlencoded）
     * @param endpoint API 端点路径
     * @param formData 表单数据（键值对）
     * @param onSuccess 成功回调函数
     * @param onError 错误回调函数
     */
    void postForm(const QString& endpoint,
                  const QMap<QString, QString>& formData,
                  SuccessCallback onSuccess,
                  ErrorCallback onError);

    // ========================================================================
    // 文件下载接口
    // ========================================================================

    /**
     * @brief 下载文件资源
     * @param url 完整的文件 URL（可以是外部 URL，不受 baseUrl 限制）
     * @param receiver 回调接收对象
     * @param successSlot 成功回调槽（签名：void(QByteArray)）
     * @param errorSlot 失败回调槽（签名：void(QString)）
     *
     * @details
     * - 支持大文件下载
     * - 自动携带 Token（如已设置）
     * - 通过 downloadProgress 信号监听下载进度
     * - 返回原始字节数据，调用方需自行保存或解析
     *
     * @note
     * - 适用于下载配置文件、图片、文档等资源
     * - 对于超大文件，建议监听 downloadProgress 信号显示进度
     *
     * @example
     * @code
     * // 下载 VPN 配置文件
     * ApiClient::instance().download(
     *     "https://cdn.example.com/configs/node-001.ovpn",
     *     this,
     *     SLOT(onConfigDownloaded(QByteArray)),
     *     SLOT(onDownloadError(QString))
     * );
     *
     * // 在槽函数中保存文件
     * void onConfigDownloaded(const QByteArray& data) {
     *     QFile file("node-001.ovpn");
     *     if (file.open(QIODevice::WriteOnly)) {
     *         file.write(data);
     *         file.close();
     *     }
     * }
     * @endcode
     *
     * @see downloadProgress()
     */
    void download(const QString& url,
                  QObject* receiver = nullptr,
                  const char* successSlot = nullptr,
                  const char* errorSlot = nullptr);

    /**
     * @brief 下载文件（Lambda 回调版本）
     * @param url 完整的文件 URL
     * @param onSuccess 成功回调函数
     * @param onError 错误回调函数
     */
    void download(const QString& url,
                  DownloadCallback onSuccess,
                  ErrorCallback onError);

    // ========================================================================
    // 文件上传接口
    // ========================================================================

    /**
     * @brief 上传文件（multipart/form-data）
     * @param endpoint API 端点路径
     * @param filePath 本地文件路径
     * @param fieldName 表单字段名（默认 "file"）
     * @param extraFields 额外的表单字段
     * @param onSuccess 成功回调函数
     * @param onError 错误回调函数
     */
    void uploadFile(const QString& endpoint,
                    const QString& filePath,
                    const QString& fieldName,
                    const QMap<QString, QString>& extraFields,
                    SuccessCallback onSuccess,
                    ErrorCallback onError);

    // ========================================================================
    // 信号定义
    // ========================================================================

signals:
    /**
     * @brief 请求开始信号
     * @param endpoint 请求的端点路径
     * @note 可用于显示 Loading 状态
     */
    void requestStarted(const QString& endpoint);

    /**
     * @brief 请求成功完成信号
     * @param endpoint 请求的端点路径
     * @param response 服务器返回的 JSON 数据
     * @note 在调用槽函数回调之前发出此信号
     */
    void requestFinished(const QString& endpoint, const QJsonObject& response);

    /**
     * @brief 请求失败信号
     * @param endpoint 请求的端点路径
     * @param error 错误描述信息
     * @note 包含网络错误、JSON 解析错误、业务错误
     */
    void requestFailed(const QString& endpoint, const QString& error);

    /**
     * @brief 下载进度信号
     * @param bytesReceived 已接收字节数
     * @param bytesTotal 总字节数（若服务器未提供则为 -1）
     * @note 可用于更新进度条 UI
     */
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);

    /**
     * @brief 上传进度信号
     * @param bytesSent 已发送字节数
     * @param bytesTotal 总字节数
     */
    void uploadProgress(qint64 bytesSent, qint64 bytesTotal);

    // ========================================================================
    // 私有部分
    // ========================================================================

private:
    /**
     * @brief 私有构造函数（单例模式）
     * @param parent 父对象指针
     * @details 初始化网络管理器和默认配置
     */
    ApiClient(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     * @details 自动清理网络管理器资源
     */
    ~ApiClient();

    // 禁用拷贝和赋值（单例模式）
    ApiClient(const ApiClient&) = delete;
    ApiClient& operator=(const ApiClient&) = delete;

    /**
     * @brief 处理网络响应（已废弃，保留用于兼容）
     * @param reply 网络响应对象
     * @deprecated 当前版本使用 lambda 直接处理响应
     */
    void handleReply(QNetworkReply* reply);

    /**
     * @brief 准备标准 HTTP 请求对象
     * @param url 完整的请求 URL
     * @return QNetworkRequest 配置好的请求对象
     * @details 自动添加标准请求头（Content-Type、User-Agent、Authorization 等）
     */
    QNetworkRequest prepareRequest(const QString& url);

    /**
     * @brief 将 HTTP 方法枚举转换为字符串
     * @param method HTTP 方法枚举值
     * @return QString 方法名称（如 "GET", "POST"）
     * @note 主要用于日志输出
     */
    QString methodToString(Method method) const;

    // ========================================================================
    // 私有成员变量
    // ========================================================================

private:
    QNetworkAccessManager* m_networkManager; ///< Qt 网络访问管理器
    QString m_baseUrl;                       ///< API 基础 URL
    QString m_authToken;                     ///< 身份验证 Token
    int m_timeout;                           ///< 请求超时时间（毫秒）
    int m_lastHttpStatusCode = 0;            ///< 最近一次失败请求的 HTTP 状态码（0=网络错误）

    // Fallback URL 支持
    QStringList m_allUrls;                   ///< 所有可用 URL（主 URL + 备用 URL）
    int m_currentUrlIndex;                   ///< 当前使用的 URL 索引
    int m_consecutiveFailures;               ///< 当前 URL 连续失败次数

    /**
     * @brief 网络连接错误时切换到下一个备用 URL
     * @return true 如果成功切换到新 URL，false 如果已尝试所有 URL
     */
    bool switchToNextUrl();

    /**
     * @brief 从本地文件加载备用 URL 列表
     */
    void loadFallbackUrls();

    /**
     * @brief 保存备用 URL 列表到本地文件
     */
    void saveFallbackUrls();

    /**
     * @brief 获取备用 URL 本地存储路径
     */
    static QString fallbackUrlsFilePath();
};

#endif // APICLIENT_H