/**
 * @file AndroidVpnHelper.h
 * @brief Android VPN服务助手头文件
 * @details 封装与Java层VpnService的JNI交互，简化Android VPN操作
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef ANDROIDVPNHELPER_H
#define ANDROIDVPNHELPER_H

#include <QObject>
#include <QString>
#include <QJniObject>

/**
 * @class AndroidVpnHelper
 * @brief Android VPN服务助手类
 *
 * @details 封装Android VpnService的JNI调用，提供C++友好的接口
 * - VPN服务管理：启动和停止Android VpnService
 * - 文件描述符：获取TUN设备的文件描述符
 * - 流量统计：跟踪上传和下载的字节数
 * - JNI桥接：通过Qt JNI调用Java层VpnService方法
 *
 * Java层架构：
 * ```
 * AndroidVpnHelper (C++/Qt)
 *   ↓ Qt JNI (QJniObject)
 * VpnService (Java)
 *   ↓ Android Framework
 * TUN Device (Linux Kernel)
 * ```
 *
 * 主要功能：
 * - VPN服务启动：配置IP地址、子网掩码、MTU
 * - TUN设备访问：获取可读写的文件描述符
 * - 流量统计：实时跟踪接收和发送的字节数
 * - Activity引用：获取当前Android Activity用于Intent操作
 *
 * 使用场景：
 * - AndroidPlatform使用此类与Java层VpnService通信
 * - 简化JNI调用，提供类型安全的C++接口
 * - 集中管理VPN服务的生命周期
 *
 * @note
 * - 仅在Android平台使用
 * - 需要配合Java层的VpnService实现
 * - 需要在AndroidManifest.xml中声明VPN权限
 *
 * @example
 * @code
 * AndroidVpnHelper* helper = new AndroidVpnHelper();
 *
 * // 启动VPN服务
 * if (helper->startVpnService("172.19.0.1", "255.255.255.0", 1500)) {
 *     // 获取文件描述符用于读写数据包
 *     int fd = helper->getVpnFileDescriptor();
 *     if (fd >= 0) {
 *         // 使用文件描述符进行数据包读写
 *         // read(fd, buffer, size);
 *         // write(fd, packet, length);
 *     }
 * }
 *
 * // 获取流量统计
 * qDebug() << "Received:" << helper->getBytesReceived();
 * qDebug() << "Sent:" << helper->getBytesSent();
 *
 * // 停止VPN服务
 * helper->stopVpnService();
 * @endcode
 */
class AndroidVpnHelper : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     *
     * @details 初始化Android VPN助手
     * - 初始化成员变量
     * - 准备JNI环境
     */
    explicit AndroidVpnHelper(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     *
     * @details 清理资源
     * - 停止VPN服务（如果正在运行）
     * - 释放JNI引用
     */
    ~AndroidVpnHelper();

    // ========================================================================
    // VPN 服务控制
    // ========================================================================

    /**
     * @brief 启动VPN服务
     * @param address VPN本地IP地址（如"172.19.0.1"）
     * @param netmask 子网掩码（如"255.255.255.0"）
     * @param mtu 最大传输单元（通常1500字节）
     * @param proxyServerHost 代理服务器域名（用于xray连接的SNI握手）
     * @param proxyServerIP 代理服务器IP（用于路由排除，避免循环）
     * @param perAppProxyMode 分应用代理模式（0=禁用，1=白名单，2=黑名单）
     * @param perAppProxyList 分应用代理应用列表（包名）
     * @return bool 成功返回true，失败返回false
     *
     * @details 启动Android VpnService并创建TUN设备
     * - 调用Java层VpnService.Builder配置参数
     * - 设置TUN设备的IP地址和子网掩码
     * - 设置MTU（Maximum Transmission Unit）
     * - 使用IP配置代理服务器路由排除（避免循环）
     * - 保留域名用于xray的SNI握手
     * - 配置分应用代理（如果启用）
     * - 建立VPN连接并返回文件描述符
     *
     * Java层操作流程：
     * 1. 创建VpnService.Builder实例
     * 2. 调用addAddress(address, prefixLength)
     * 3. 调用setMtu(mtu)
     * 4. 调用addRoute("0.0.0.0", 0) 添加默认路由（可选）
     * 5. 添加代理服务器IP的路由排除（避免死循环）
     * 6. 根据分应用代理模式调用addAllowedApplication/addDisallowedApplication
     * 7. 调用establish()创建TUN设备
     * 8. 返回文件描述符
     *
     * @note
     * - 需要先获得VPN权限
     * - Android系统同时只能有一个VPN连接
     * - 启动成功后可通过getVpnFileDescriptor()获取文件描述符
     * - 代理服务器IP会被自动排除路由，确保不产生路由循环
     * - 代理服务器域名保留用于xray的SNI握手
     * - 分应用代理配置在VpnService.Builder中处理
     *
     * @see stopVpnService, getVpnFileDescriptor
     */
    bool startVpnService(const QString& address, const QString& netmask, int mtu,
                         const QString& proxyServerHost = QString(),
                         const QString& proxyServerIP = QString(),
                         int perAppProxyMode = 0,
                         const QStringList& perAppProxyList = QStringList(),
                         const QStringList& allServerIPs = QStringList());

    /**
     * @brief 停止VPN服务
     * @return bool 成功返回true，失败返回false
     *
     * @details 停止Android VpnService并关闭TUN设备
     * - 关闭TUN设备的文件描述符
     * - 调用Java层VpnService.stop()
     * - 清理VPN连接状态
     *
     * @see startVpnService
     */
    bool stopVpnService();

    // ========================================================================
    // TUN 设备访问
    // ========================================================================

    /**
     * @brief 获取VPN文件描述符
     * @return int 文件描述符，失败返回-1
     *
     * @details 获取TUN设备的文件描述符
     * - 文件描述符由VpnService.Builder.establish()返回
     * - 可用于read()和write()系统调用读写数据包
     * - 可用于select/poll/epoll等待数据
     *
     * 使用方式：
     * @code
     * int fd = helper->getVpnFileDescriptor();
     * if (fd >= 0) {
     *     // 阻塞读取数据包
     *     ssize_t n = read(fd, buffer, sizeof(buffer));
     *
     *     // 写入数据包
     *     ssize_t sent = write(fd, packet, packet_len);
     *
     *     // 非阻塞模式
     *     fcntl(fd, F_SETFL, O_NONBLOCK);
     * }
     * @endcode
     *
     * @note
     * - 需要先调用startVpnService
     * - 返回的文件描述符由Java层管理，不要手动close
     *
     * @see startVpnService
     */
    int getVpnFileDescriptor();

    // ========================================================================
    // 流量统计
    // ========================================================================

    /**
     * @brief 获取接收字节数
     * @return quint64 从VPN接收的总字节数
     *
     * @details 返回从TUN设备读取的总字节数
     * - 由Java层VpnService维护统计
     * - 通过JNI调用获取
     *
     * @see getBytesSent, resetStatistics
     */
    quint64 getBytesReceived();

    /**
     * @brief 获取发送字节数
     * @return quint64 通过VPN发送的总字节数
     *
     * @details 返回向TUN设备写入的总字节数
     * - 由Java层VpnService维护统计
     * - 通过JNI调用获取
     *
     * @see getBytesReceived, resetStatistics
     */
    quint64 getBytesSent();

    /**
     * @brief 重置流量统计
     *
     * @details 将接收和发送字节数重置为0
     * - 调用Java层VpnService.resetStatistics()
     * - 用于重新开始流量统计
     *
     * @see getBytesReceived, getBytesSent
     */
    void resetStatistics();

private:
    // ========================================================================
    // 私有方法
    // ========================================================================

    /**
     * @brief 获取当前Activity
     * @return QJniObject Android Activity对象
     *
     * @details 通过Qt JNI获取当前Android Activity的引用
     * - 用于启动VPN服务Intent
     * - 用于显示权限请求对话框
     * - 通过QtAndroid::androidActivity()获取
     *
     * @note 返回的QJniObject是Activity的JNI引用
     */
    QJniObject getActivity();
};

#endif // ANDROIDVPNHELPER_H
