/**
 * @file ProxyDetector.h
 * @brief 系统代理检测工具
 * @details 检测系统是否配置了SOCKS5代理，用于避免登录问题
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef PROXYDETECTOR_H
#define PROXYDETECTOR_H

#include <QString>

/**
 * @brief 系统代理检测工具类
 * @details 提供简单的系统SOCKS5代理检测功能
 */
class ProxyDetector
{
public:
    /**
     * @brief 检测系统是否启用了SOCKS5代理
     * @return true=存在启用的SOCKS5代理，false=没有
     */
    static bool hasSocks5ProxyEnabled();

    /**
     * @brief 获取代理信息描述
     * @return 代理信息字符串（如"Wi-Fi: 127.0.0.1:7890"）
     */
    static QString getProxyInfo();

    /**
     * @brief 清除系统SOCKS5代理设置
     * @return true=成功清除，false=清除失败
     */
    static bool clearSystemProxy();
};

#endif // PROXYDETECTOR_H
