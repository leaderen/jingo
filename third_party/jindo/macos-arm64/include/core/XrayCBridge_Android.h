/**
 * @file XrayCBridge_Android.h
 * @brief Android平台Xray桥接头文件 - 使用SuperRay C API
 * @details 直接调用SuperRay/LibXray兼容C API，不再使用JNI调用Java
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef ANDROIDXRAYBRIDGE_H
#define ANDROIDXRAYBRIDGE_H

#include <QtGlobal>

// 仅在 Android 平台编译
#ifdef Q_OS_ANDROID

#include <QString>
#include <QObject>

/**
 * @class AndroidXrayBridge
 * @brief Android平台Xray桥接类 - 使用SuperRay C API
 *
 * @details 本类为Android平台提供Xray核心控制接口
 * - 直接调用SuperRay的C API（不再使用JNI调用Java）
 * - 提供与桌面平台一致的API接口
 * - 支持异步操作和信号通知
 * - 支持TUN模式（通过SuperRay_CreateTUNFromFD）
 *
 * 架构说明：
 * ```
 * C++ (AndroidXrayBridge)
 *   ↓ Direct C call
 * SuperRay C API (libsuperray.so)
 *   ↓
 * Xray-core (Go)
 * ```
 *
 * @note 仅在Android平台编译和使用
 *
 * @see XrayCBridge_Apple.mm (Apple平台等效实现)
 */
class AndroidXrayBridge : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象指针
     */
    explicit AndroidXrayBridge(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~AndroidXrayBridge();

    // ========================================================================
    // Xray 核心操作
    // ========================================================================

    /**
     * @brief 使用JSON配置启动Xray
     * @param configJSON JSON格式的Xray配置字符串
     * @return QString 失败时返回错误信息，成功时返回空字符串
     */
    QString startXray(const QString& configJSON);

    /**
     * @brief 停止运行中的Xray实例
     * @return QString 失败时返回错误信息，成功时返回空字符串
     */
    QString stopXray();

    /**
     * @brief 检查Xray是否正在运行
     * @return bool 运行中返回true，否则返回false
     */
    bool isRunning() const;

    /**
     * @brief 获取geo文件数据目录路径
     * @return QString 数据目录路径
     */
    QString getDatDir() const;

    /**
     * @brief 获取Xray版本字符串
     * @return QString 版本字符串或错误信息
     */
    QString getVersion();

    // ========================================================================
    // 统计和监控
    // ========================================================================

    /**
     * @brief 查询流量统计数据
     * @param pattern 匹配模式（现在不使用，SuperRay返回所有统计）
     * @param reset 是否在查询后重置计数器
     * @return QString JSON格式的统计数据
     */
    QString queryStats(const QString& pattern, bool reset = false);

    /**
     * @brief 获取当前Xray状态
     * @return QString JSON格式的状态信息
     */
    QString getState();

    // ========================================================================
    // 工具函数
    // ========================================================================

    /**
     * @brief 获取系统可用端口
     * @param count 需要的端口数量
     * @return QString JSON格式的端口列表
     */
    QString getFreePorts(int count);

    /**
     * @brief 通过Xray ping目标地址
     * @param destination 目标地址（域名或IP:port）
     * @param timeout 超时时间（毫秒）
     * @return int 延迟时间（毫秒），失败返回-1
     */
    int ping(const QString& destination, int timeout);

    /**
     * @brief 测试DNS功能
     * @param domain 要测试的域名
     * @param timeout 超时时间（毫秒）
     * @return QString JSON格式的测试结果
     */
    QString testDns(const QString& domain, int timeout);

    // ========================================================================
    // TUN设备管理 (VPN模式)
    // ========================================================================

    /**
     * @brief 从文件描述符创建TUN设备
     * @param fd VpnService.Builder.establish()返回的文件描述符
     * @param configJSON TUN配置JSON（包含mtu, addresses, tag等）
     * @return QString JSON格式的结果
     *
     * @details 用于Android VPN模式，从VpnService获取的FD创建TUN设备
     */
    QString createTunFromFD(int fd, const QString& configJSON);

    /**
     * @brief 移除TUN设备
     * @param tag TUN设备标签
     * @return QString JSON格式的结果
     */
    QString removeTunDevice(const QString& tag);

    // ========================================================================
    // 错误处理
    // ========================================================================

    /**
     * @brief 获取最后的错误信息
     * @return QString 错误信息或空字符串
     */
    QString lastError() const { return m_lastError; }

    /**
     * @brief 清除最后的错误信息
     */
    void clearError() { m_lastError.clear(); }

signals:
    /**
     * @brief Xray启动成功信号
     */
    void xrayStarted();

    /**
     * @brief Xray停止信号
     */
    void xrayStopped();

    /**
     * @brief 错误发生信号
     * @param error 错误信息描述
     */
    void errorOccurred(const QString& error);

    /**
     * @brief 流量统计更新信号
     * @param uplink 上传字节数
     * @param downlink 下载字节数
     */
    void statsUpdated(quint64 uplink, quint64 downlink);

private:
    /**
     * @brief 设置错误信息
     * @param error 错误描述
     */
    void setError(const QString& error);

    /**
     * @brief 复制geo文件到数据目录
     * @param destDir 目标目录
     */
    void copyGeoFiles(const QString& destDir);

    // ========================================================================
    // 成员变量
    // ========================================================================

    QString m_lastError;              ///< 最后的错误信息
    bool m_isRunning;                 ///< Xray运行状态标志
    QString m_datDir;                 ///< geo文件数据目录路径
};

// ============================================================================
// C语言兼容包装函数
// ============================================================================

extern "C" {
    /**
     * @brief 启动Xray (C兼容包装)
     * @param configJSON 配置JSON字符串
     * @return int 成功返回0，失败返回-1
     */
    int Android_Xray_Start(const char* configJSON);

    /**
     * @brief 停止Xray (C兼容包装)
     * @return int 成功返回0，失败返回-1
     */
    int Android_Xray_Stop();

    /**
     * @brief 检查是否运行 (C兼容包装)
     * @return int 运行中返回1，否则返回0
     */
    int Android_Xray_IsRunning();

    /**
     * @brief 获取版本 (C兼容包装)
     * @param buffer 用于存储版本字符串的缓冲区
     * @param bufferSize 缓冲区大小
     * @return int 成功返回0，失败返回-1
     */
    int Android_Xray_GetVersion(char* buffer, int bufferSize);

    /**
     * @brief 查询统计数据 (C兼容包装)
     * @param pattern 匹配模式
     * @param reset 是否重置计数器
     * @param result 结果缓冲区
     * @param resultSize 结果缓冲区大小
     * @return int 成功返回0，失败返回-1
     */
    int Android_Xray_QueryStats(const char* pattern, int reset, char* result, int resultSize);

    /**
     * @brief 测试配置 (C兼容包装)
     * @param configJSON 要测试的配置JSON
     * @return int 成功返回0，配置无效返回-2，其他错误返回-1
     */
    int Android_Xray_TestConfig(const char* configJSON);

    // ========================================================================
    // TUN设备C包装函数
    // ========================================================================

    /**
     * @brief 从FD创建并启动TUN设备 (C兼容包装)
     * @param fd 文件描述符
     * @param configJSON TUN配置JSON
     * @param instanceID Xray实例ID (用于绑定XrayDialer)
     * @param result 结果缓冲区
     * @param resultSize 缓冲区大小
     * @return int 成功返回0，失败返回-1
     */
    int Android_CreateTunFromFD(int fd, const char* configJSON, const char* instanceID, char* result, int resultSize);

    /**
     * @brief 移除TUN设备 (C兼容包装)
     * @param tag TUN设备标签
     * @return int 成功返回0，失败返回-1
     */
    int Android_RemoveTunDevice(const char* tag);
}

// ============================================================================
// 注意：Xray_* 函数在 XrayCBridge_Android.cpp 中直接实现
// 不再使用宏映射，以避免与其他编译单元冲突
// ============================================================================

#endif // Q_OS_ANDROID

#endif // ANDROIDXRAYBRIDGE_H
