#ifndef AESCRYPTO_H
#define AESCRYPTO_H

#include <QByteArray>

/**
 * @brief AES 加密工具类
 *
 * 提供 AES-256-CBC 加解密功能，使用 OpenSSL 实现。
 */
class AesCrypto
{
public:
    // 密钥长度常量
    static constexpr int KEY_SIZE = 32;  // 256 bits
    static constexpr int IV_SIZE = 16;   // 128 bits
    static constexpr int BLOCK_SIZE = 16;

    /**
     * @brief 使用 AES-256-CBC 加密数据
     * @param data 要加密的数据
     * @param key 32字节密钥
     * @param iv 16字节初始化向量
     * @return 加密后的数据（包含 PKCS7 填充），失败返回空
     */
    static QByteArray encrypt(const QByteArray& data, const QByteArray& key,
                              const QByteArray& iv);

    /**
     * @brief 使用 AES-256-CBC 解密数据
     * @param encryptedData 加密的数据
     * @param key 32字节密钥
     * @param iv 16字节初始化向量
     * @return 解密后的数据（移除 PKCS7 填充），失败返回空
     */
    static QByteArray decrypt(const QByteArray& encryptedData, const QByteArray& key,
                              const QByteArray& iv);

    /**
     * @brief 生成随机密钥
     * @param size 密钥大小，默认32字节（256位）
     * @return 随机密钥
     */
    static QByteArray generateKey(int size = KEY_SIZE);

    /**
     * @brief 生成随机 IV
     * @param size IV 大小，默认16字节（128位）
     * @return 随机 IV
     */
    static QByteArray generateIV(int size = IV_SIZE);

private:
    /**
     * @brief PKCS7 填充
     */
    static QByteArray pkcs7Pad(const QByteArray& data, int blockSize);

    /**
     * @brief 移除 PKCS7 填充
     */
    static QByteArray pkcs7Unpad(const QByteArray& data);
};

#endif // AESCRYPTO_H
