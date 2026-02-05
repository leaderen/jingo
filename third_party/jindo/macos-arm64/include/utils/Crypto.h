/**
 * @file Crypto.h
 * @brief 加密工具类头文件
 * @details 提供常用的加密、哈希、编码和随机数生成功能，纯静态工具类
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef CRYPTO_H
#define CRYPTO_H

#include <QString>
#include <QByteArray>

/**
 * @class Crypto
 * @brief 加密和编码工具类
 *
 * @details 提供常用的加密、哈希、编码功能，包括：
 * - Base64编码/解码（标准和URL安全）
 * - 哈希算法（MD5、SHA256）
 * - 随机字符串生成
 * - UUID生成
 *
 * 主要功能：
 * - Base64编码：标准Base64和URL安全Base64
 * - 哈希计算：MD5和SHA256哈希值
 * - 随机生成：随机字符串和UUID
 * - 多类型支持：QString和QByteArray
 *
 * 使用场景：
 * - 数据传输：Base64编码用于二进制数据的文本传输
 * - 密码存储：哈希算法用于密码加密存储
 * - 唯一标识：UUID用于生成唯一ID
 * - 安全令牌：随机字符串用于生成临时令牌
 *
 * @note
 * - 所有方法都是静态的，无需实例化
 * - 线程安全：所有方法都是无状态的
 * - 工具类：禁止实例化和拷贝
 *
 * @example 使用示例
 * @code
 * // Base64编码
 * QString encoded = Crypto::base64Encode("Hello World");
 * QString decoded = Crypto::base64Decode(encoded);
 *
 * // MD5哈希
 * QString hash = Crypto::md5("password123");
 *
 * // 生成随机字符串
 * QString token = Crypto::randomString(32);
 *
 * // 生成UUID
 * QString id = Crypto::generateUuid();
 * @endcode
 */
class Crypto
{
public:
    // ========================================================================
    // Base64 编码/解码
    // ========================================================================

    /**
     * @brief Base64编码（QString版本）
     * @param data 要编码的字符串
     * @return QString Base64编码后的字符串
     *
     * @details 将字符串编码为标准Base64格式
     * - 使用标准Base64字符集：A-Z, a-z, 0-9, +, /
     * - 使用=作为填充字符
     * - 输出可包含+和/字符
     *
     * @note 如果需要URL安全的编码，请使用base64UrlEncode()
     *
     * @see base64Decode, base64UrlEncode
     */
    static QString base64Encode(const QString& data);

    /**
     * @brief Base64编码（QByteArray版本）
     * @param data 要编码的二进制数据
     * @return QString Base64编码后的字符串
     *
     * @details 将二进制数据编码为标准Base64格式
     * - 适用于编码任意二进制数据
     * - 输出为ASCII文本字符串
     *
     * @see base64DecodeToBytes
     */
    static QString base64Encode(const QByteArray& data);

    /**
     * @brief Base64解码（返回QString）
     * @param encoded Base64编码的字符串
     * @return QString 解码后的字符串
     *
     * @details 将Base64字符串解码为原始字符串
     * - 自动处理填充字符
     * - 忽略无效字符
     * - 假设解码后是UTF-8文本
     *
     * @note 如果解码失败，返回空字符串
     *
     * @see base64Encode
     */
    static QString base64Decode(const QString& encoded);

    /**
     * @brief Base64解码（返回QByteArray）
     * @param encoded Base64编码的字符串
     * @return QByteArray 解码后的二进制数据
     *
     * @details 将Base64字符串解码为二进制数据
     * - 适用于解码任意二进制内容
     * - 不假设内容是文本
     *
     * @note 如果解码失败，返回空数组
     *
     * @see base64Encode
     */
    static QByteArray base64DecodeToBytes(const QString& encoded);

    /**
     * @brief URL安全的Base64编码
     * @param data 要编码的字符串
     * @return QString URL安全的Base64字符串
     *
     * @details 将字符串编码为URL安全的Base64格式
     * - 使用-替换+
     * - 使用_替换/
     * - 不使用=填充字符
     * - 可安全用于URL参数
     *
     * @note URL安全Base64主要用于URL参数和文件名
     *
     * @example
     * @code
     * QString urlParam = Crypto::base64UrlEncode("user@example.com");
     * // 可直接用于URL: https://example.com/api?token=urlParam
     * @endcode
     *
     * @see base64UrlDecode, base64Encode
     */
    static QString base64UrlEncode(const QString& data);

    /**
     * @brief URL安全的Base64解码
     * @param encoded URL安全的Base64字符串
     * @return QString 解码后的字符串
     *
     * @details 将URL安全的Base64字符串解码
     * - 自动将-转换为+
     * - 自动将_转换为/
     * - 自动补充缺失的=填充
     *
     * @note 如果解码失败，返回空字符串
     *
     * @see base64UrlEncode
     */
    static QString base64UrlDecode(const QString& encoded);

    // ========================================================================
    // 哈希算法
    // ========================================================================

    /**
     * @brief 计算MD5哈希（QString版本）
     * @param data 要计算哈希的字符串
     * @return QString 32位小写十六进制MD5哈希值
     *
     * @details 计算字符串的MD5哈希值
     * - 返回32位小写十六进制字符串
     * - 例如: "5d41402abc4b2a76b9719d911017c592"
     *
     * @note
     * - MD5已不再安全，不应用于密码存储
     * - 仅用于快速校验和非安全场景
     *
     * @example
     * @code
     * QString hash = Crypto::md5("hello");
     * // hash = "5d41402abc4b2a76b9719d911017c592"
     * @endcode
     *
     * @see sha256
     */
    static QString md5(const QString& data);

    /**
     * @brief 计算MD5哈希（QByteArray版本）
     * @param data 要计算哈希的二进制数据
     * @return QString 32位小写十六进制MD5哈希值
     *
     * @details 计算二进制数据的MD5哈希值
     * - 适用于文件内容、二进制数据等
     *
     * @see md5(const QString&)
     */
    static QString md5(const QByteArray& data);

    /**
     * @brief 计算SHA256哈希（QString版本）
     * @param data 要计算哈希的字符串
     * @return QString 64位小写十六进制SHA256哈希值
     *
     * @details 计算字符串的SHA256哈希值
     * - 返回64位小写十六进制字符串
     * - 比MD5更安全
     * - 例如: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
     *
     * @note 推荐用于密码哈希和数据完整性验证
     *
     * @example
     * @code
     * QString hash = Crypto::sha256("hello");
     * // hash = "2cf24dba5fb0a30e26e83b2ac5b9e29e..."
     * @endcode
     *
     * @see md5
     */
    static QString sha256(const QString& data);

    /**
     * @brief 计算SHA256哈希（QByteArray版本）
     * @param data 要计算哈希的二进制数据
     * @return QString 64位小写十六进制SHA256哈希值
     *
     * @details 计算二进制数据的SHA256哈希值
     * - 适用于文件内容、二进制数据等
     *
     * @see sha256(const QString&)
     */
    static QString sha256(const QByteArray& data);

    // ========================================================================
    // 随机生成
    // ========================================================================

    /**
     * @brief 生成随机字符串
     * @param length 字符串长度
     * @return QString 随机字符串
     *
     * @details 生成指定长度的随机字符串
     * - 字符集：A-Z, a-z, 0-9（62个字符）
     * - 使用密码学安全的随机数生成器
     * - 适用于生成临时令牌、验证码等
     *
     * @note
     * - length应大于0
     * - length为0或负数时返回空字符串
     *
     * @example
     * @code
     * QString token = Crypto::randomString(32);
     * // token = "aB3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW"
     * @endcode
     *
     * @see generateUuid
     */
    static QString randomString(int length);

    /**
     * @brief 生成UUID
     * @return QString UUID字符串
     *
     * @details 生成符合RFC 4122标准的UUID
     * - 格式：8-4-4-4-12（36个字符含连字符）
     * - 例如：550e8400-e29b-41d4-a716-446655440000
     * - 使用Version 4 UUID（随机生成）
     * - 全局唯一标识符
     *
     * @note UUID可用于数据库主键、文件名、会话ID等
     *
     * @example
     * @code
     * QString id = Crypto::generateUuid();
     * // id = "550e8400-e29b-41d4-a716-446655440000"
     * @endcode
     *
     * @see randomString
     */
    static QString generateUuid();

private:
    /**
     * @brief 私有构造函数
     * @details 工具类，禁止实例化
     */
    Crypto() = delete;

    /**
     * @brief 禁用拷贝构造
     */
    Crypto(const Crypto&) = delete;

    /**
     * @brief 禁用赋值操作
     */
    Crypto& operator=(const Crypto&) = delete;
};

#endif // CRYPTO_H
