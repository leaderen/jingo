/**
 * @file XrayCBridge.h
 * @brief Xray C语言桥接头文件
 * @details 提供C++到SuperRay库的C语言接口桥接，支持所有平台
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef XRAY_C_BRIDGE_H
#define XRAY_C_BRIDGE_H

// 各平台实现文件：
// - Android: XrayCBridge_Android.cpp (使用 SuperRay C API)
// - Apple: XrayCBridge_Apple.mm (使用 SuperRay Framework)
// - Windows/Linux: XrayCBridge_CGo.c (使用 SuperRay 动态库)
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// 返回值常量
// ============================================================================
#define XRAY_OK     0   ///< 操作成功
#define XRAY_ERROR -1   ///< 操作失败

// ============================================================================
// Xray 核心控制函数
// ============================================================================

/**
 * @brief 启动Xray核心
 * @param configJSON JSON格式的Xray配置字符串
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 使用提供的JSON配置启动Xray核心实例
 * - 配置必须是有效的Xray JSON格式
 * - 如果Xray已在运行，需先调用Xray_Stop()
 * - 启动成功后，Xray将在后台运行并处理流量
 *
 * @note 此函数会阻塞直到启动完成或失败
 *
 * @see Xray_Stop, Xray_TestConfig
 */
int Xray_Start(const char* configJSON);

/**
 * @brief 停止Xray核心
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 停止正在运行的Xray核心实例
 * - 如果Xray未运行，调用此函数是安全的
 * - 停止后会清理所有资源和连接
 * - 流量统计数据会被重置
 *
 * @note 此函数会阻塞直到停止完成
 *
 * @see Xray_Start
 */
int Xray_Stop(void);

/**
 * @brief 测试配置有效性
 * @param configJSON JSON格式的Xray配置字符串
 * @return int 配置有效返回0，无效返回负数错误码
 *
 * @details 验证JSON配置是否符合Xray规范
 * - 仅检查配置有效性，不实际启动Xray
 * - 用于在启动前验证配置，避免启动失败
 * - 可以在Xray运行时调用（不影响运行中的实例）
 *
 * @note 不会修改运行状态或配置
 *
 * @see Xray_Start
 */
int Xray_TestConfig(const char* configJSON);

/**
 * @brief 获取Xray版本信息
 * @param version 用于存储版本字符串的缓冲区
 * @param size 缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 获取SuperRay库的版本信息
 * - 版本字符串格式通常为 "X.Y.Z" (例如: "1.8.4")
 * - 如果缓冲区太小，返回错误码
 * - 可以在任何时候调用（无需Xray运行）
 *
 * @note 确保缓冲区足够大（建议至少64字节）
 *
 * @example
 * @code
 * char version[64];
 * if (Xray_GetVersion(version, sizeof(version)) == 0) {
 *     printf("Xray version: %s\n", version);
 * }
 * @endcode
 */
int Xray_GetVersion(char* version, int size);

/**
 * @brief 测试目标服务器的延迟（Ping）
 * @param configJSON 完整的Xray ping配置JSON字符串
 *                   格式: {"destination": "https://...", "timeout": "5000ms", "proxy": {...}}
 *                   或向后兼容的简单地址格式 (如 "1.1.1.1:443")
 * @param timeout 超时时间（毫秒）- 当configJSON不包含timeout时使用
 * @return int 延迟时间（毫秒），失败返回-1
 *
 * @details 使用Xray库测试到目标服务器的网络延迟
 * - 可以在Xray未运行时调用
 * - 支持通过代理服务器测试（通过proxy字段配置）
 * - 返回值是往返时间（RTT）
 * - 超时或连接失败返回-1
 *
 * @note 建议timeout至少设置为3000ms（3秒）
 *
 * @example 简单测试（向后兼容）
 * @code
 * int latency = Xray_Ping("8.8.8.8:443", 5000);
 * if (latency > 0) {
 *     printf("Latency: %d ms\n", latency);
 * } else {
 *     printf("Ping failed\n");
 * }
 * @endcode
 *
 * @example 通过代理测试
 * @code
 * const char* config = "{\"destination\":\"https://www.google.com/generate_204\","
 *                      "\"timeout\":\"5000ms\","
 *                      "\"proxy\":{\"protocol\":\"vmess\",\"settings\":{...}}}";
 * int latency = Xray_Ping(config, 5000);
 * @endcode
 */
int Xray_Ping(const char* configJSON, int timeout);

/**
 * @brief 检查Xray是否正在运行
 * @return int 运行中返回1，未运行返回0
 *
 * @details 查询Xray核心的运行状态
 * - 返回1表示Xray正在运行
 * - 返回0表示Xray已停止或未启动
 * - 可以随时调用，无副作用
 *
 * @note 轻量级查询操作，不会影响性能
 *
 * @see Xray_Start, Xray_Stop
 */
int Xray_GetRunning(void);

// ============================================================================
// 流量统计查询函数 (使用 SuperRay 直接 API)
// ============================================================================

/**
 * @brief 查询流量统计数据
 * @param pattern 统计项匹配模式 - 现在不使用，SuperRay返回所有统计
 * @param reset 查询后是否重置计数器（1=重置，0=不重置）
 * @param result 用于存储JSON格式统计结果的缓冲区
 * @param resultSize 结果缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 使用 SuperRay_GetXrayStats() 直接 API 查询流量统计
 * 不再需要 HTTP 或 gRPC 查询
 *
 * @note 内部调用 SuperRay_GetXrayStats()
 */
int Xray_QueryStats(const char* pattern, int reset, char* result, int resultSize);

/**
 * @brief 查询流量统计数据（推荐使用）
 * @param pattern 统计项匹配模式 - 现在不使用，SuperRay返回所有统计
 * @param reset 查询后是否重置计数器（1=重置，0=不重置）
 * @param result 用于存储JSON格式统计结果的缓冲区
 * @param resultSize 结果缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 使用 SuperRay 直接 API 查询 Xray 流量统计信息
 * - 内部调用 SuperRay_GetXrayStats()
 * - 不再需要 HTTP (端口 15490) 或 gRPC 查询
 * - 结果以JSON格式返回，包含统计数据
 * - reset=1时，查询后会将计数器归零（调用 SuperRay_ResetXrayStats）
 * - 仅在Xray运行时可用
 *
 * @note 确保结果缓冲区足够大（建议至少4096字节）
 *
 * @example
 * @code
 * char stats[4096];
 * if (Xray_QueryStatsGRPC("", 0, stats, sizeof(stats)) == 0) {
 *     // 解析 JSON 统计数据
 * }
 * @endcode
 *
 * @see Xray_GetRunning, Xray_QueryStats
 */
int Xray_QueryStatsGRPC(const char* pattern, int reset, char* result, int resultSize);

/**
 * @brief 获取最后一次操作的错误消息
 * @param buffer 用于存储错误消息的缓冲区
 * @param bufferSize 缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 获取最后一次Xray操作失败时的详细错误消息
 * - 错误消息可能包含来自SuperRay的详细诊断信息
 * - 如果没有错误，缓冲区将被设置为空字符串
 * - 错误消息在下次操作时会被清除
 *
 * @note 建议缓冲区至少1024字节以容纳完整错误消息
 *
 * @example
 * @code
 * if (Xray_Start(config) != 0) {
 *     char error[1024];
 *     if (Xray_GetLastError(error, sizeof(error)) == 0) {
 *         printf("Xray启动失败: %s\n", error);
 *     }
 * }
 * @endcode
 */
int Xray_GetLastError(char* buffer, int bufferSize);

// ============================================================================
// 延迟测试函数 (使用 SuperRay API)
// ============================================================================

/**
 * @brief TCP连接延迟测试（使用 SuperRay_Ping）
 * @param address 服务器地址（如 "www.google.com"）
 * @param timeout 超时时间（毫秒）
 * @return int 延迟时间（毫秒），失败返回-1
 *
 * @details 使用 SuperRay_Ping 测试 TCP 连接延迟
 * - 直接 TCP 连接测试
 * - 快速且准确
 */
int Xray_SimplePing(const char* address, int timeout);

/**
 * @brief TCP连接延迟测试
 * @param address 服务器地址
 * @param port 服务器端口
 * @param timeout 超时时间（毫秒）
 * @return int 延迟时间（毫秒），失败返回-1
 *
 * @details 使用 SuperRay_TCPPing 直接测试到服务器端口的TCP连接延迟
 * - 不经过代理，直接连接
 * - 快速且准确
 * - 适合测试服务器是否可达
 */
int Xray_TCPPing(const char* address, int port, int timeout);

/**
 * @brief HTTP延迟测试
 * @param url 测试URL (如 "https://www.google.com/generate_204")
 * @param proxyAddr 代理地址 (如 "127.0.0.1:10808")，空字符串表示直连
 * @param timeout 超时时间（毫秒）
 * @return int 延迟时间（毫秒），失败返回-1
 *
 * @details 使用 SuperRay_HTTPPing 测试HTTP请求延迟
 * - 可以通过代理测试
 * - 更准确反映实际使用延迟
 * - 适合测试代理连接质量
 */
int Xray_HTTPPing(const char* url, const char* proxyAddr, int timeout);


// ============================================================================
// TUN 设备管理函数 (Windows/Linux/macOS System TUN)
// ============================================================================

/**
 * @brief 创建系统TUN设备
 * @param tunConfigJSON TUN配置JSON字符串
 *        格式: {"tag":"tun0","name":"JinGoVPN","mtu":1500,"addresses":["172.19.0.1/24"]}
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_CreateTUN(const char* tunConfigJSON);

/**
 * @brief 启动TUN栈并连接到Xray实例
 * @param tunTag TUN设备标签（与创建时的tag一致）
 * @param outboundTag Xray出站标签（如"proxy"），空字符串表示默认
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_StartTUN(const char* tunTag, const char* outboundTag);

/**
 * @brief 停止并关闭TUN设备
 * @param tunTag TUN设备标签
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_StopTUN(const char* tunTag);

/**
 * @brief 从文件描述符创建TUN设备 (Linux/Android)
 * @param fd TUN设备文件描述符
 * @param tunConfigJSON TUN配置JSON字符串
 *        格式: {"tag":"tun0","mtu":1500,"addresses":["172.19.0.1/24"]}
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 用于Linux/Android平台，从已创建的TUN设备文件描述符创建SuperRay TUN
 * - Linux: 使用LinuxTunManager创建TUN设备后，传递fd给SuperRay
 * - Android: 从VpnService.Builder.establish()获取fd后，传递给SuperRay
 * - 创建后，需调用Xray_StartTUN()启动TUN栈
 */
int Xray_CreateTUNFromFD(int fd, const char* tunConfigJSON);

/**
 * @brief 移除TUN设备 (Linux/Android)
 * @param tunTag TUN设备标签
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 用于移除通过Xray_CreateTUNFromFD()创建的TUN设备
 * - 停止TUN栈并清理资源
 * - 不会关闭文件描述符（由调用方管理）
 */
int Xray_RemoveTUNDevice(const char* tunTag);

/**
 * @brief 获取当前运行的Xray实例ID
 * @param buffer 用于存储实例ID的缓冲区
 * @param bufferSize 缓冲区大小
 * @return int 成功返回0，失败返回负数错误码
 */
int Xray_GetInstanceID(char* buffer, int bufferSize);

/**
 * @brief 下载速度测试（吞吐量测试）
 * @param downloadURL 下载测试URL (如 "https://speed.cloudflare.com/__down?bytes=10000000")
 * @param proxyAddr 代理地址 (如 "127.0.0.1:10808")，空字符串表示直连
 * @param durationSec 测试持续时间（秒）
 * @param result 用于存储JSON格式测试结果的缓冲区
 * @param resultSize 结果缓冲区大小（字节数）
 * @return int 成功返回0，失败返回负数错误码
 *
 * @details 使用 SuperRay_SpeedTest 测试下载速度
 * - 通过代理下载测试文件
 * - 返回下载速度（Mbps）
 * - 结果JSON格式: {"speed_mbps": 12.5, "bytes": 10000000, "duration_ms": 800}
 */
int Xray_SpeedTest(const char* downloadURL, const char* proxyAddr, int durationSec, char* result, int resultSize);

#ifdef __cplusplus
}
#endif

#endif // XRAY_C_BRIDGE_H
