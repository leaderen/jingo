/**
 * @file LinuxTunManager.h
 * @brief Linux TUN虚拟网卡管理器
 * @details 使用Linux内核原生TUN/TAP设备实现VPN功能
 *
 * @author JinGo VPN Team
 * @date 2025
 * @copyright Copyright © 2025 JinGo Team. All rights reserved.
 */

#pragma once

#ifdef __linux__

#include <string>
#include <vector>
#include <atomic>
#include <memory>
#include <cstdint>

namespace JinGo {

/**
 * Linux TUN设备管理器
 *
 * 负责：
 * - 打开/dev/net/tun设备
 * - 配置TUN设备属性
 * - 配置IP地址、路由、DNS
 * - 读写数据包
 * - 收集统计信息
 */
class LinuxTunManager {
public:
    LinuxTunManager();
    ~LinuxTunManager();

    // 禁止拷贝
    LinuxTunManager(const LinuxTunManager&) = delete;
    LinuxTunManager& operator=(const LinuxTunManager&) = delete;

    /**
     * 初始化TUN设备
     * @param deviceName 设备名称（如"tun0"，留空则自动分配）
     * @param mtu MTU大小（默认1500）
     * @return 成功返回true
     */
    bool initialize(const std::string& deviceName = "jingo0", int mtu = 1500);

    /**
     * 关闭设备
     */
    void shutdown();

    /**
     * 获取设备名称
     */
    std::string getDeviceName() const { return deviceName_; }

    /**
     * 获取设备文件描述符
     */
    int getFd() const { return tunFd_; }

    /**
     * 配置IP地址
     * @param ipAddress IP地址字符串（如"172.19.0.1"）
     * @param prefixLength 前缀长度（如24）
     * @return 成功返回true
     */
    bool setIPAddress(const std::string& ipAddress, uint8_t prefixLength);

    /**
     * 设置设备状态（up/down）
     * @param up true表示启动设备，false表示关闭设备
     * @return 成功返回true
     */
    bool setDeviceState(bool up);

    /**
     * 设置MTU
     * @param mtu MTU大小
     * @return 成功返回true
     */
    bool setMTU(int mtu);

    /**
     * 添加路由
     * @param destination 目标网络（如"0.0.0.0"表示默认路由）
     * @param prefixLength 前缀长度（0表示默认路由）
     * @param gateway 网关地址（可选）
     * @return 成功返回true
     */
    bool addRoute(const std::string& destination, uint8_t prefixLength,
                  const std::string& gateway = "");

    /**
     * 删除路由
     * @param destination 目标网络
     * @param prefixLength 前缀长度
     * @return 成功返回true
     */
    bool deleteRoute(const std::string& destination, uint8_t prefixLength);

    /**
     * 设置DNS服务器
     * @param dnsServers DNS服务器列表
     * @return 成功返回true
     */
    bool setDNS(const std::vector<std::string>& dnsServers);

    /**
     * 读取数据包
     * @param buffer 缓冲区
     * @param bufferSize 缓冲区大小
     * @return 实际读取的字节数，-1表示错误
     */
    ssize_t readPacket(uint8_t* buffer, size_t bufferSize);

    /**
     * 写入数据包
     * @param buffer 数据包
     * @param size 数据包大小
     * @return 实际写入的字节数，-1表示错误
     */
    ssize_t writePacket(const uint8_t* buffer, size_t size);

    /**
     * 检查是否正在运行
     */
    bool isRunning() const { return tunFd_ >= 0; }

    /**
     * 统计信息
     */
    struct Statistics {
        uint64_t bytesReceived;
        uint64_t bytesSent;
        uint64_t packetsReceived;
        uint64_t packetsSent;
        uint64_t errorsReceived;
        uint64_t errorsSent;
    };

    Statistics getStatistics() const;

private:
    // 设备信息
    int tunFd_;
    std::string deviceName_;
    int mtu_;

    // 统计信息
    std::atomic<uint64_t> bytesReceived_;
    std::atomic<uint64_t> bytesSent_;
    std::atomic<uint64_t> packetsReceived_;
    std::atomic<uint64_t> packetsSent_;
    std::atomic<uint64_t> errorsReceived_;
    std::atomic<uint64_t> errorsSent_;

    // 辅助函数
    int createTunDevice(const std::string& deviceName);
    bool executeCommand(const std::string& command);
    int createNetlinkSocket();
    bool netlinkAddIPAddress(const std::string& ipAddress, uint8_t prefixLength);
    bool netlinkSetDeviceState(bool up);
    bool netlinkSetMTU(int mtu);
    bool netlinkAddRoute(const std::string& destination, uint8_t prefixLength,
                        const std::string& gateway);
    bool netlinkDeleteRoute(const std::string& destination, uint8_t prefixLength);
};

} // namespace JinGo

#endif // __linux__
