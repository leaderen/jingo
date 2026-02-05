/**
 * @file SecureStorage.h
 * @brief 安全存储头文件
 * @details 提供跨平台的安全存储API，用于敏感数据（密码、令牌等）的加密存储
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef SECURESTORAGE_H
#define SECURESTORAGE_H

#include <QString>

/**
 * @class SecureStorage
 * @brief 安全存储工具类
 *
 * @details 提供跨平台的安全存储功能，使用操作系统提供的加密存储API：
 * - Windows: DPAPI (Data Protection API)
 * - macOS/iOS: Keychain Services
 * - Linux: libsecret
 * - Android: KeyStore
 *
 * 主要功能：
 * - 密码存储：保存和读取用户密码
 * - 令牌管理：保存和读取认证令牌
 * - 通用密钥：保存和读取任意敏感数据
 * - 自动加密：所有数据自动使用系统级加密
 *
 * 安全特性：
 * - 系统级加密：使用操作系统提供的安全存储机制
 * - 用户隔离：数据仅对当前用户可访问
 * - 内存安全：不在内存中长期保留敏感数据
 *
 * @note
 * - 所有方法都是静态的，无需实例化
 * - 线程安全：依赖系统API的线程安全性
 * - 跨平台：不同平台使用不同的底层实现
 *
 * @example 使用示例
 * @code
 * // 保存密码
 * SecureStorage::savePassword("user@example.com", "myPassword123");
 *
 * // 读取密码
 * QString password = SecureStorage::loadPassword("user@example.com");
 *
 * // 删除密码
 * SecureStorage::deletePassword("user@example.com");
 *
 * // 保存令牌
 * SecureStorage::saveToken("eyJhbGciOiJIUzI1...");
 *
 * // 保存通用密钥
 * SecureStorage::saveSecret("api_key", "sk-1234567890");
 * @endcode
 */
class SecureStorage
{
public:
    // ========================================================================
    // 密码管理
    // ========================================================================

    /**
     * @brief 保存密码
     * @param username 用户名（作为密钥标识）
     * @param password 要保存的密码
     * @return bool 成功返回true，失败返回false
     *
     * @details 将密码加密后保存到系统安全存储中
     * - Windows: 使用DPAPI加密并保存到注册表或文件
     * - macOS/iOS: 使用Keychain保存
     * - Linux: 使用libsecret保存到GNOME Keyring
     * - Android: 使用KeyStore保存
     *
     * @note 如果该用户名已存在密码，将被覆盖
     */
    static bool savePassword(const QString& username, const QString& password);

    /**
     * @brief 加载密码
     * @param username 用户名（密钥标识）
     * @return QString 密码明文，失败返回空字符串
     *
     * @details 从系统安全存储中解密并读取密码
     *
     * @note 如果用户名不存在或解密失败，返回空字符串
     */
    static QString loadPassword(const QString& username);

    /**
     * @brief 删除密码
     * @param username 用户名（密钥标识）
     * @return bool 成功返回true，失败或不存在返回false
     *
     * @details 从系统安全存储中删除指定用户名的密码
     */
    static bool deletePassword(const QString& username);

    // ========================================================================
    // 令牌管理
    // ========================================================================

    /**
     * @brief 保存令牌
     * @param token 认证令牌（如JWT token）
     * @return bool 成功返回true，失败返回false
     *
     * @details 将认证令牌加密后保存到系统安全存储中
     * - 令牌使用固定的密钥名称"auth_token"
     * - 适用于存储API令牌、会话令牌等
     *
     * @note 如果已存在令牌，将被覆盖
     */
    static bool saveToken(const QString& token);

    /**
     * @brief 加载令牌
     * @return QString 令牌内容，失败返回空字符串
     *
     * @details 从系统安全存储中解密并读取认证令牌
     */
    static QString loadToken();

    /**
     * @brief 删除令牌
     * @return bool 成功返回true，失败或不存在返回false
     *
     * @details 从系统安全存储中删除认证令牌
     */
    static bool deleteToken();

    // ========================================================================
    // 通用密钥管理
    // ========================================================================

    /**
     * @brief 保存通用密钥
     * @param key 密钥标识名称
     * @param value 密钥值
     * @return bool 成功返回true，失败返回false
     *
     * @details 将任意敏感数据加密后保存到系统安全存储中
     * - 适用于API密钥、配置密码、加密密钥等
     * - 密钥名称应该是唯一的标识符
     *
     * @note 如果该密钥名称已存在，将被覆盖
     *
     * @example
     * @code
     * SecureStorage::saveSecret("database_password", "myDBPass123");
     * SecureStorage::saveSecret("encryption_key", "aes-256-key-here");
     * @endcode
     */
    static bool saveSecret(const QString& key, const QString& value);

    /**
     * @brief 加载通用密钥
     * @param key 密钥标识名称
     * @return QString 密钥值，失败返回空字符串
     *
     * @details 从系统安全存储中解密并读取密钥值
     *
     * @note 如果密钥不存在或解密失败，返回空字符串
     */
    static QString loadSecret(const QString& key);

    /**
     * @brief 删除通用密钥
     * @param key 密钥标识名称
     * @return bool 成功返回true，失败或不存在返回false
     *
     * @details 从系统安全存储中删除指定密钥
     */
    static bool deleteSecret(const QString& key);

    // ========================================================================
    // 工具方法
    // ========================================================================

    /**
     * @brief 清除所有存储的数据
     * @return bool 成功返回true，失败返回false
     *
     * @details 删除所有由本应用保存的安全数据
     * - 包括所有密码、令牌和密钥
     * - 用于用户登出或重置应用时
     *
     * @warning 此操作不可逆，请谨慎使用
     */
    static bool clearAll();

    /**
     * @brief 检查是否支持安全存储
     * @return bool 支持返回true，不支持返回false
     *
     * @details 检查当前平台是否支持安全存储功能
     * - 通常所有主流平台都支持
     * - 某些精简版Linux发行版可能不支持
     */
    static bool isSupported();

private:
    /**
     * @brief 私有构造函数
     * @details 工具类，禁止实例化
     */
    SecureStorage() = delete;

    /**
     * @brief 禁用拷贝构造
     */
    SecureStorage(const SecureStorage&) = delete;

    /**
     * @brief 禁用赋值操作
     */
    SecureStorage& operator=(const SecureStorage&) = delete;

    // ========================================================================
    // 私有辅助方法
    // ========================================================================

    /**
     * @brief 获取服务名称
     * @return QString 服务名称（用于Keychain等）
     *
     * @details 返回用于标识安全存储的服务名称
     * - 格式：组织名.应用名
     * - 用于macOS Keychain作为服务标识
     */
    static QString serviceName();

    /**
     * @brief 检查密钥是否存在
     * @param key 密钥标识
     * @return bool 存在返回true，不存在返回false
     *
     * @details 检查指定密钥是否已存储
     * - macOS: 查询Keychain
     * - 其他平台可能有不同实现
     */
    static bool hasSecret(const QString& key);
};

#endif // SECURESTORAGE_H
