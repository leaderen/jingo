#ifndef DEVICEIDENTIFIER_H
#define DEVICEIDENTIFIER_H

#include <QString>
#include <QJsonObject>

/**
 * @brief 设备标识工具类
 *
 * 生成跨平台的唯一设备标识符，用于授权验证中的设备追踪。
 *
 * 各平台实现:
 * - Android: Settings.Secure.ANDROID_ID
 * - iOS: identifierForVendor
 * - macOS: IOPlatformSerialNumber
 * - Windows: MachineGuid
 * - Linux: /etc/machine-id
 */
class DeviceIdentifier
{
public:
    /**
     * @brief 获取设备唯一标识（SHA256 哈希）
     * @return 64字符的十六进制字符串
     */
    static QString getDeviceId();

    /**
     * @brief 获取设备详细信息
     * @return JSON 对象包含平台、系统版本、设备型号等
     */
    static QJsonObject getDeviceInfo();

    /**
     * @brief 获取平台名称
     * @return android, ios, macos, windows, linux
     */
    static QString getPlatform();

    /**
     * @brief 获取操作系统版本
     * @return 版本字符串
     */
    static QString getOsVersion();

    /**
     * @brief 获取设备型号
     * @return 设备型号名称
     */
    static QString getDeviceModel();

private:
    /**
     * @brief 获取平台特定的原始设备标识
     * @return 原始标识符
     */
    static QString getRawDeviceId();

    /**
     * @brief 获取平台附加标识（硬件信息）
     * @return 额外的硬件标识符
     */
    static QString getPlatformExtraId();

    /**
     * @brief 生成设备指纹（多个标识符组合）
     * @return 组合后的指纹字符串
     */
    static QString generateFingerprint();

    /**
     * @brief 从安全存储中读取或生成持久化 ID
     * @return 持久化的设备 ID
     */
    static QString getOrCreatePersistentId();
};

#endif // DEVICEIDENTIFIER_H
