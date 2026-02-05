/**
 * @file IcmpPing.h
 * @brief ICMP Ping 工具类头文件
 * @details 提供跨平台的 ICMP Echo Request/Reply 延迟测试功能
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef ICMPPING_H
#define ICMPPING_H

#include <QString>

/**
 * @class IcmpPing
 * @brief ICMP Ping 工具类
 * @details 通过发送 ICMP Echo Request 来测试服务器延迟
 *
 * @note 权限要求:
 * - Linux/macOS: 需要 root 权限或 CAP_NET_RAW capability
 * - Windows: 使用 IcmpSendEcho API,普通用户权限即可
 * - 如果权限不足,将自动回退到使用系统 ping 命令
 */
class IcmpPing
{
public:
    /**
     * @brief 测试 ICMP Ping 延迟
     * @param host 目标主机地址(IP或域名)
     * @param timeoutMs 超时时间(毫秒)
     * @param count Ping 次数(默认1次)
     * @return 平均延迟时间(毫秒),失败返回 -1
     *
     * @details 实现原理:
     * 1. 优先尝试使用原生 ICMP socket (需要权限)
     * 2. 如果权限不足,回退到使用系统 ping 命令
     * 3. 发送 count 次 ICMP Echo Request
     * 4. 等待 Echo Reply 并计算 RTT
     * 5. 返回平均延迟
     */
    static int ping(const QString& host, int timeoutMs = 5000, int count = 1);

private:
    /**
     * @brief 解析主机名为 IP 地址
     * @param host 主机名或 IP 地址
     * @param ipAddress 输出参数,解析后的 IP 地址
     * @return 解析成功返回 true,失败返回 false
     */
    static bool resolveHost(const QString& host, QString& ipAddress);

    /**
     * @brief 使用系统 ping 命令进行测试(回退方案)
     * @param host 目标主机
     * @param timeoutMs 超时时间(毫秒)
     * @param count Ping 次数
     * @return 平均延迟时间(毫秒),失败返回 -1
     */
    static int pingWithCommand(const QString& host, int timeoutMs, int count);

#ifdef Q_OS_WIN
    /**
     * @brief Windows 平台使用 IcmpSendEcho API
     */
    static int pingWindows(const QString& ipAddress, int timeoutMs, int count);
#else
    /**
     * @brief Unix/Linux/macOS 平台使用 raw socket
     */
    static int pingUnix(const QString& ipAddress, int timeoutMs, int count);
#endif
};

#endif // ICMPPING_H
