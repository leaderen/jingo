#ifndef RSACRYPTO_H
#define RSACRYPTO_H

#include <QByteArray>
#include <QString>

/**
 * @brief RSA 加密工具类
 *
 * 提供跨平台的 RSA-2048 加解密和签名验证功能。
 * - Android/Linux: 使用 OpenSSL
 * - macOS/iOS: 使用 Security.framework
 * - Windows: 使用 CryptoAPI (bcrypt)
 */
class RsaCrypto
{
public:
    /**
     * @brief 使用公钥加密数据
     * @param data 要加密的数据
     * @param publicKeyPem PEM 格式的公钥
     * @return 加密后的数据，失败返回空
     */
    static QByteArray encrypt(const QByteArray& data, const QByteArray& publicKeyPem);

    /**
     * @brief 使用私钥解密数据
     * @param encryptedData 加密的数据
     * @param privateKeyPem PEM 格式的私钥
     * @return 解密后的数据，失败返回空
     */
    static QByteArray decrypt(const QByteArray& encryptedData, const QByteArray& privateKeyPem);

    /**
     * @brief 使用私钥对数据签名
     * @param data 要签名的数据
     * @param privateKeyPem PEM 格式的私钥
     * @return 签名数据，失败返回空
     */
    static QByteArray sign(const QByteArray& data, const QByteArray& privateKeyPem);

    /**
     * @brief 使用公钥验证签名
     * @param data 原始数据
     * @param signature 签名数据
     * @param publicKeyPem PEM 格式的公钥
     * @return 验证成功返回 true
     */
    static bool verify(const QByteArray& data, const QByteArray& signature,
                       const QByteArray& publicKeyPem);

    /**
     * @brief 从安装包目录读取公钥文件
     * @return PEM 格式的公钥，读取失败返回空
     */
    static QByteArray getPublicKey();

    /**
     * @brief 检查 RSA 功能是否可用
     * @return 可用返回 true
     */
    static bool isSupported();

#if defined(Q_OS_IOS) || defined(Q_OS_MACOS)
    // Apple Security.framework 实现（在 RsaCrypto_ios.mm 中）
    static QByteArray encryptWithAppleSecurity(const QByteArray& data, const QByteArray& publicKeyPem);
    static QByteArray decryptWithAppleSecurity(const QByteArray& encryptedData, const QByteArray& privateKeyPem);
    static QByteArray signWithAppleSecurity(const QByteArray& data, const QByteArray& privateKeyPem);
    static bool verifyWithAppleSecurity(const QByteArray& data, const QByteArray& signature,
                                        const QByteArray& publicKeyPem);
#endif

#if defined(Q_OS_WIN)
    // Windows BCrypt 实现（在 RsaCrypto_windows.cpp 中）
    static QByteArray encryptWithWindowsBCrypt(const QByteArray& data, const QByteArray& publicKeyPem);
    static QByteArray decryptWithWindowsBCrypt(const QByteArray& encryptedData, const QByteArray& privateKeyPem);
    static QByteArray signWithWindowsBCrypt(const QByteArray& data, const QByteArray& privateKeyPem);
    static bool verifyWithWindowsBCrypt(const QByteArray& data, const QByteArray& signature,
                                        const QByteArray& publicKeyPem);
#endif

private:
};

#endif // RSACRYPTO_H
