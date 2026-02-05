/**
 * @file TcpPing.h
 * @brief TCP Ping 工具类头文件
 * @details 提供跨平台的 TCP 连接延迟测试功能
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef TCPPING_H
#define TCPPING_H

#include <QString>

/**
 * @class TcpPing
 * @brief TCP Ping 工具类
 * @details 通过建立 TCP 连接来测试服务器延迟，支持跨平台（Windows、macOS、Linux、Android、iOS）
 */
class TcpPing
{
public:
    /**
     * @brief 测试 TCP 连接延迟
     * @param host 目标主机地址（IP或域名）
     * @param port 目标端口
     * @param timeoutMs 超时时间（毫秒）
     * @return 延迟时间（毫秒），失败返回 -1
     *
     * @details 实现原理：
     * 1. 记录开始时间
     * 2. 创建非阻塞 socket
     * 3. 尝试连接到目标 host:port
     * 4. 使用 select/poll 等待连接完成或超时
     * 5. 记录结束时间
     * 6. 返回连接耗时（毫秒）
     */
    static int ping(const QString& host, int port, int timeoutMs = 5000);

private:
    /**
     * @brief 解析主机名为 IP 地址
     * @param host 主机名或 IP 地址
     * @param ipAddress 输出参数，解析后的 IP 地址
     * @return 解析成功返回 true，失败返回 false
     */
    static bool resolveHost(const QString& host, QString& ipAddress);
};

#endif // TCPPING_H
