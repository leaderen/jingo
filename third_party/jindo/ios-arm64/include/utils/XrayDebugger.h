/**
 * @file XrayDebugger.h
 * @brief Xray调试工具类
 * @details 提供各种诊断和调试功能，帮助排查Xray启动问题
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef XRAYDEBUGGER_H
#define XRAYDEBUGGER_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QJsonDocument>
#include <QJsonObject>

/**
 * @class XrayDebugger
 * @brief Xray调试工具类
 *
 * @details
 * 提供以下调试功能：
 * - SuperRay framework检查
 * - Xray配置验证
 * - 端口占用检查
 * - 完整的诊断报告
 */
class XrayDebugger : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief 获取单例实例
     */
    static XrayDebugger& instance();

    /**
     * @brief 检查SuperRay framework是否正确加载
     * @return QVariantMap 检查结果
     *
     * @details 返回的Map包含:
     * - success: bool - 是否成功
     * - version: QString - Xray版本
     * - error: QString - 错误信息（如果有）
     */
    Q_INVOKABLE QVariantMap checkSuperRay();

    /**
     * @brief 验证Xray配置JSON
     * @param configJson JSON格式的配置字符串
     * @return QVariantMap 验证结果
     *
     * @details 返回的Map包含:
     * - valid: bool - 配置是否有效
     * - error: QString - 错误信息（如果有）
     * - warnings: QStringList - 警告列表
     * - inbounds: int - 入站数量
     * - outbounds: int - 出站数量
     */
    Q_INVOKABLE QVariantMap validateConfig(const QString& configJson);

    /**
     * @brief 检查端口是否被占用
     * @param port 端口号
     * @return QVariantMap 检查结果
     *
     * @details 返回的Map包含:
     * - available: bool - 端口是否可用
     * - process: QString - 占用端口的进程（如果被占用）
     * - pid: int - 进程ID（如果被占用）
     */
    Q_INVOKABLE QVariantMap checkPort(int port);

    /**
     * @brief 运行完整的诊断
     * @param configJson 要测试的配置
     * @return QVariantMap 诊断报告
     *
     * @details 返回的Map包含:
     * - superray: QVariantMap - SuperRay检查结果
     * - config: QVariantMap - 配置验证结果
     * - ports: QVariantMap - 端口检查结果
     * - recommendations: QStringList - 建议列表
     */
    Q_INVOKABLE QVariantMap runDiagnostics(const QString& configJson);

    /**
     * @brief 获取详细的错误信息
     * @param errorCode Xray_Start返回的错误码
     * @return QString 详细的错误说明
     */
    Q_INVOKABLE QString getErrorDetails(int errorCode);

signals:
    /**
     * @brief 诊断进度信号
     * @param step 当前步骤
     * @param message 进度消息
     */
    void diagnosticProgress(const QString& step, const QString& message);

private:
    XrayDebugger(QObject* parent = nullptr);
    ~XrayDebugger() = default;

    XrayDebugger(const XrayDebugger&) = delete;
    XrayDebugger& operator=(const XrayDebugger&) = delete;

    /**
     * @brief 验证JSON格式
     */
    QJsonParseError validateJsonFormat(const QString& json, QJsonDocument& doc);

    /**
     * @brief 检查必需的配置字段
     */
    QStringList checkRequiredFields(const QJsonObject& config);

    /**
     * @brief 验证入站配置
     */
    QStringList validateInbounds(const QJsonArray& inbounds);

    /**
     * @brief 验证出站配置
     */
    QStringList validateOutbounds(const QJsonArray& outbounds);

    /**
     * @brief 获取端口占用进程信息（macOS）
     */
    QString getProcessUsingPort(int port);
};

#endif // XRAYDEBUGGER_H
