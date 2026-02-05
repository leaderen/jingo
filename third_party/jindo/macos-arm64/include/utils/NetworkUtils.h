/**
 * @file NetworkUtils.h
 * @brief 网络工具类头文件
 * @details 提供URL编码、IP验证、端口检查等网络相关的实用工具函数
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef NETWORKUTILS_H
#define NETWORKUTILS_H

#include <QString>
#include <QUrl>

/**
 * @class NetworkUtils
 * @brief 网络工具类
 *
 * @details 提供网络编程中常用的工具函数，包括：
 * - URL编码/解码
 * - IP地址验证（IPv4/IPv6）
 * - 端口号验证
 * - URL解析（提取主机名/端口）
 * - 本地地址检查
 *
 * 主要功能：
 * - URL处理：编码、解码、解析
 * - IP验证：支持IPv4和IPv6地址验证
 * - 端口检查：验证端口号范围
 * - 地址分析：提取URL组件、判断本地地址
 *
 * 使用场景：
 * - 服务器配置：验证用户输入的服务器地址和端口
 * - URL处理：编码/解码订阅链接参数
 * - 代理设置：解析代理服务器地址
 * - 安全检查：防止连接到本地地址
 *
 * @note
 * - 所有方法都是静态的，无需实例化
 * - 线程安全：所有方法都是无状态的
 * - 工具类：禁止实例化和拷贝
 *
 * @example 使用示例
 * @code
 * // URL编码
 * QString encoded = NetworkUtils::urlEncode("user@example.com");
 *
 * // 验证IP地址
 * bool valid = NetworkUtils::isValidIp("192.168.1.1"); // true
 * bool valid6 = NetworkUtils::isValidIpv6("2001:db8::1"); // true
 *
 * // 验证端口
 * bool portOk = NetworkUtils::isValidPort(8080); // true
 *
 * // 提取主机名
 * QString host = NetworkUtils::extractHostFromUrl("https://example.com:8080/path");
 * // host = "example.com"
 *
 * // 检查本地地址
 * bool isLocal = NetworkUtils::isLocalAddress("127.0.0.1"); // true
 * @endcode
 */
class NetworkUtils
{
public:
    // ========================================================================
    // URL 编码/解码
    // ========================================================================

    /**
     * @brief URL编码
     * @param data 要编码的字符串
     * @return QString URL编码后的字符串
     *
     * @details 将字符串编码为URL安全格式
     * - 保留字符：A-Z, a-z, 0-9, -, _, ., ~
     * - 其他字符转换为 %XX 格式（XX为十六进制）
     * - 空格编码为 %20
     *
     * @note 符合RFC 3986标准
     *
     * @example
     * @code
     * QString encoded = NetworkUtils::urlEncode("hello world!");
     * // encoded = "hello%20world%21"
     * @endcode
     *
     * @see urlDecode
     */
    static QString urlEncode(const QString& data);

    /**
     * @brief URL解码
     * @param encoded URL编码的字符串
     * @return QString 解码后的字符串
     *
     * @details 将URL编码的字符串解码为原始字符串
     * - %XX格式转换回原始字符
     * - %20转换为空格
     * - +也可转换为空格（兼容表单编码）
     *
     * @note 如果解码失败，返回空字符串
     *
     * @example
     * @code
     * QString decoded = NetworkUtils::urlDecode("hello%20world%21");
     * // decoded = "hello world!"
     * @endcode
     *
     * @see urlEncode
     */
    static QString urlDecode(const QString& encoded);

    // ========================================================================
    // URL 验证和解析
    // ========================================================================

    /**
     * @brief 验证URL格式
     * @param url URL字符串
     * @return bool 有效返回true，无效返回false
     *
     * @details 验证URL是否符合标准格式
     * - 检查协议（http、https、ws、wss等）
     * - 检查主机名/IP地址
     * - 检查端口号（可选）
     * - 检查路径（可选）
     *
     * @example
     * @code
     * bool valid = NetworkUtils::isValidUrl("https://example.com/path");
     * // valid = true
     *
     * bool invalid = NetworkUtils::isValidUrl("not-a-url");
     * // invalid = false
     * @endcode
     */
    static bool isValidUrl(const QString& url);

    /**
     * @brief 从URL提取主机名
     * @param url URL字符串
     * @return QString 主机名，失败返回空字符串
     *
     * @details 从URL中提取主机名（域名或IP）
     * - 支持带协议的URL
     * - 支持带端口的URL
     * - 自动去除端口号
     *
     * @example
     * @code
     * QString host = NetworkUtils::extractHostFromUrl("https://example.com:8080/path");
     * // host = "example.com"
     *
     * QString host2 = NetworkUtils::extractHostFromUrl("192.168.1.1:1080");
     * // host2 = "192.168.1.1"
     * @endcode
     *
     * @see extractPortFromUrl
     */
    static QString extractHostFromUrl(const QString& url);

    /**
     * @brief 从URL提取端口号
     * @param url URL字符串
     * @param defaultPort 默认端口（URL中未指定端口时使用）
     * @return int 端口号
     *
     * @details 从URL中提取端口号
     * - 如果URL指定了端口，返回该端口
     * - 如果URL未指定端口，返回defaultPort
     * - 如果URL无效，返回defaultPort
     *
     * @note 标准端口：HTTP=80, HTTPS=443, SOCKS=1080
     *
     * @example
     * @code
     * int port = NetworkUtils::extractPortFromUrl("https://example.com:8080", 443);
     * // port = 8080
     *
     * int port2 = NetworkUtils::extractPortFromUrl("https://example.com", 443);
     * // port2 = 443
     * @endcode
     *
     * @see extractHostFromUrl
     */
    static int extractPortFromUrl(const QString& url, int defaultPort = 80);

    // ========================================================================
    // IP 地址验证
    // ========================================================================

    /**
     * @brief 验证IP地址（IPv4或IPv6）
     * @param ip IP地址字符串
     * @return bool 有效返回true，无效返回false
     *
     * @details 验证IP地址是否为有效的IPv4或IPv6格式
     * - 自动判断IPv4或IPv6
     * - 同时支持两种格式
     *
     * @example
     * @code
     * bool valid4 = NetworkUtils::isValidIp("192.168.1.1"); // true
     * bool valid6 = NetworkUtils::isValidIp("2001:db8::1"); // true
     * bool invalid = NetworkUtils::isValidIp("999.999.999.999"); // false
     * @endcode
     *
     * @see isValidIpv4, isValidIpv6
     */
    static bool isValidIp(const QString& ip);

    /**
     * @brief 验证IPv4地址
     * @param ip IPv4地址字符串
     * @return bool 有效返回true，无效返回false
     *
     * @details 验证是否为有效的IPv4地址
     * - 格式：xxx.xxx.xxx.xxx
     * - 每段取值范围：0-255
     * - 不支持CIDR表示法（如192.168.1.0/24）
     *
     * @example
     * @code
     * bool valid = NetworkUtils::isValidIpv4("192.168.1.1"); // true
     * bool invalid = NetworkUtils::isValidIpv4("256.1.1.1"); // false
     * @endcode
     *
     * @see isValidIp, isValidIpv6
     */
    static bool isValidIpv4(const QString& ip);

    /**
     * @brief 验证IPv6地址
     * @param ip IPv6地址字符串
     * @return bool 有效返回true，无效返回false
     *
     * @details 验证是否为有效的IPv6地址
     * - 格式：xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx
     * - 支持缩写格式（::）
     * - 例如：2001:db8::1（等价于 2001:0db8:0000:0000:0000:0000:0000:0001）
     *
     * @example
     * @code
     * bool valid = NetworkUtils::isValidIpv6("2001:db8::1"); // true
     * bool valid2 = NetworkUtils::isValidIpv6("::1"); // true (localhost)
     * bool invalid = NetworkUtils::isValidIpv6("gggg::1"); // false
     * @endcode
     *
     * @see isValidIp, isValidIpv4
     */
    static bool isValidIpv6(const QString& ip);

    // ========================================================================
    // 端口验证
    // ========================================================================

    /**
     * @brief 验证端口号
     * @param port 端口号
     * @return bool 有效返回true，无效返回false
     *
     * @details 验证端口号是否在有效范围内
     * - 有效范围：1-65535
     * - 0和负数无效
     * - 大于65535无效
     *
     * @note
     * - 知名端口：1-1023（需要root权限）
     * - 注册端口：1024-49151
     * - 动态端口：49152-65535
     *
     * @example
     * @code
     * bool valid = NetworkUtils::isValidPort(8080); // true
     * bool invalid = NetworkUtils::isValidPort(0); // false
     * bool invalid2 = NetworkUtils::isValidPort(70000); // false
     * @endcode
     */
    static bool isValidPort(int port);

    // ========================================================================
    // 地址分析
    // ========================================================================

    /**
     * @brief 检查是否是本地地址
     * @param address IP地址或主机名
     * @return bool 是本地地址返回true，否则返回false
     *
     * @details 检查地址是否指向本地主机
     * - IPv4本地地址：
     *   - 127.0.0.0/8（127.0.0.1-127.255.255.255）
     *   - 0.0.0.0
     * - IPv6本地地址：
     *   - ::1（localhost）
     *   - ::（all interfaces）
     * - 主机名：
     *   - localhost
     *   - 127.0.0.1
     *
     * @note 用于安全检查，防止连接到本地服务
     *
     * @example
     * @code
     * bool local1 = NetworkUtils::isLocalAddress("127.0.0.1"); // true
     * bool local2 = NetworkUtils::isLocalAddress("localhost"); // true
     * bool local3 = NetworkUtils::isLocalAddress("::1"); // true
     * bool remote = NetworkUtils::isLocalAddress("8.8.8.8"); // false
     * @endcode
     */
    static bool isLocalAddress(const QString& address);

private:
    /**
     * @brief 私有构造函数
     * @details 工具类，禁止实例化
     */
    NetworkUtils() = delete;

    /**
     * @brief 禁用拷贝构造
     */
    NetworkUtils(const NetworkUtils&) = delete;

    /**
     * @brief 禁用赋值操作
     */
    NetworkUtils& operator=(const NetworkUtils&) = delete;
};

#endif // NETWORKUTILS_H
