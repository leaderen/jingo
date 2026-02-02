/*
 * SuperRay - Cross-platform Xray Library with C ABI
 *
 * This header provides the C API for SuperRay library.
 * All functions that return char* require caller to free the memory using SuperRay_Free().
 * All returned strings are JSON formatted.
 *
 * Response format:
 * {
 *   "success": true|false,
 *   "data": {...},      // present on success
 *   "error": "..."      // present on failure
 * }
 */

#ifndef SUPERRAY_H
#define SUPERRAY_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ========== Version Functions ========== */

/* Get SuperRay library version */
extern char* SuperRay_Version(void);

/* Get underlying Xray-core version */
extern char* SuperRay_XrayVersion(void);

/* ========== Instance Management ========== */

/*
 * Create a new Xray instance from JSON config
 * @param configJSON: Full Xray JSON configuration string
 * @return JSON: {"success":true,"data":{"id":"instance_id"}}
 */
extern char* SuperRay_CreateInstance(const char* configJSON);

/*
 * Start an Xray instance by ID
 * @param instanceID: Instance ID returned from CreateInstance
 * @return JSON with success status
 */
extern char* SuperRay_StartInstance(const char* instanceID);

/*
 * Stop a running Xray instance
 * @param instanceID: Instance ID
 * @return JSON with success status
 */
extern char* SuperRay_StopInstance(const char* instanceID);

/*
 * Stop and destroy an Xray instance
 * @param instanceID: Instance ID
 * @return JSON with success status
 */
extern char* SuperRay_DestroyInstance(const char* instanceID);

/*
 * Get the state of an instance
 * @param instanceID: Instance ID
 * @return JSON: {"success":true,"data":{"id":"...","state":"running|stopped|starting|stopping"}}
 */
extern char* SuperRay_GetInstanceState(const char* instanceID);

/*
 * Get detailed information about an instance
 * @param instanceID: Instance ID
 * @return JSON with id, state, start_at, uptime_seconds
 */
extern char* SuperRay_GetInstanceInfo(const char* instanceID);

/*
 * List all instance IDs
 * @return JSON: {"success":true,"data":{"instances":["id1","id2"],"count":2}}
 */
extern char* SuperRay_ListInstances(void);

/* ========== Simple API ========== */

/*
 * Create, start and run Xray in one call
 * @param configJSON: Full Xray JSON configuration
 * @return JSON with instance ID and status
 */
extern char* SuperRay_Run(const char* configJSON);

/*
 * Run Xray from a config file path (supports JSON, YAML, TOML)
 * @param configPath: Path to Xray config file
 * @return JSON with instance ID and status
 */
extern char* SuperRay_RunFromFile(const char* configPath);

/*
 * Run Xray from multiple config files (like: xray run -c a.json -c b.json)
 * @param pathsJSON: JSON array of config file paths, e.g. ["/path/a.json", "/path/b.json"]
 * @return JSON with instance ID and status
 */
extern char* SuperRay_RunFromFiles(const char* pathsJSON);

/*
 * Run Xray from all config files in a directory
 * @param configDir: Directory path containing config files
 * @return JSON with instance ID and status
 */
extern char* SuperRay_RunFromDir(const char* configDir);

/*
 * Stop all running instances
 * @return JSON with count of stopped instances
 */
extern char* SuperRay_StopAll(void);

/*
 * Validate Xray configuration without starting
 * @param configJSON: Xray JSON configuration
 * @return JSON: {"success":true,"data":{"valid":true}}
 */
extern char* SuperRay_ValidateConfig(const char* configJSON);

/* ========== DNS Functions ========== */

/*
 * Initialize custom DNS servers
 * @param serversJSON: JSON array of DNS servers, e.g. ["8.8.8.8","1.1.1.1"]
 * @return JSON with success status
 */
extern char* SuperRay_InitDNS(const char* serversJSON);

/*
 * Reset to system default DNS
 * @return JSON with success status
 */
extern char* SuperRay_ResetDNS(void);

/*
 * Resolve hostname to IP addresses
 * @param host: Hostname to resolve
 * @return JSON: {"success":true,"data":{"host":"...","addresses":["1.2.3.4"]}}
 */
extern char* SuperRay_LookupHost(const char* host);

/* ========== Share Link Functions ========== */

/*
 * Parse a single share link (vmess://, vless://, trojan://, ss://)
 * @param link: Share link string
 * @return JSON with parsed link details
 */
extern char* SuperRay_ParseShareLink(const char* link);

/*
 * Parse multiple share links (one per line)
 * @param content: Multi-line string with share links
 * @return JSON: {"success":true,"data":{"links":[...],"errors":[...],"count":N}}
 */
extern char* SuperRay_ParseShareLinks(const char* content);

/*
 * Convert a share link to Xray outbound config
 * @param link: Share link string
 * @return JSON with Xray outbound configuration
 */
extern char* SuperRay_ShareLinkToXrayConfig(const char* link);

/*
 * Generate a share link from config
 * @param protocol: Protocol name (vmess, vless, trojan, ss)
 * @param configJSON: JSON object with address, port, uuid, etc.
 * @return JSON: {"success":true,"data":{"link":"vmess://..."}}
 */
extern char* SuperRay_GenerateShareLink(const char* protocol, const char* configJSON);

/*
 * Convert multiple share links to Xray config with outbounds
 * @param content: Multi-line share links
 * @return JSON Xray config with outbounds array
 */
extern char* SuperRay_ConvertLinksToConfig(const char* content);

/* ========== Geo Data Functions ========== */

/*
 * Set the asset directory for geo files (geoip.dat, geosite.dat)
 * @param dir: Directory path
 * @return JSON with success status
 */
extern char* SuperRay_SetAssetDir(const char* dir);

/*
 * Get the current asset directory
 * @return JSON: {"success":true,"data":{"asset_dir":"..."}}
 */
extern char* SuperRay_GetAssetDir(void);

/*
 * Set debug log file path for SuperRay TUN debugging
 * @param path: File path to write debug logs to
 * @return JSON: {"success":true,"data":{"status":"debug log path set","log_path":"..."}}
 */
extern char* SuperRay_SetDebugLogPath(const char* path);

/*
 * Check if geo files exist
 * @return JSON with geoip_path and geosite_path
 */
extern char* SuperRay_CheckGeoFiles(void);

/*
 * Find geo references in a config
 * @param configJSON: Xray JSON configuration
 * @return JSON: {"success":true,"data":{"references":["geoip:cn"],"count":1}}
 */
extern char* SuperRay_FindGeoInConfig(const char* configJSON);

/*
 * Close all memory-mapped geo files (iOS optimization)
 * On iOS, geo files (geoip.dat, geosite.dat) are loaded via mmap to reduce memory usage.
 * Call this when shutting down to release the mmap resources.
 * On non-iOS platforms, this is a no-op.
 * @return JSON: {"success":true,"data":{"status":"closed"}}
 */
extern char* SuperRay_CloseGeoMmap(void);

/* ========== Network Utility Functions ========== */

/*
 * Get available TCP ports
 * @param count: Number of ports to find (max 100)
 * @return JSON: {"success":true,"data":{"ports":[12345,12346],"count":2}}
 */
extern char* SuperRay_GetFreePorts(int count);

/*
 * TCP ping to test connectivity
 * @param address: Address in format "host:port"
 * @param timeoutMs: Timeout in milliseconds (0 = default 5000ms)
 * @return JSON with latency_ms
 */
extern char* SuperRay_Ping(const char* address, int timeoutMs);

/*
 * HTTP ping through optional proxy
 * @param url: URL to ping (e.g., "https://www.google.com")
 * @param proxyAddr: Proxy address "host:port" or empty for direct
 * @param timeoutMs: Timeout in milliseconds (0 = default 10000ms)
 * @return JSON with status_code and latency_ms
 */
extern char* SuperRay_HTTPPing(const char* url, const char* proxyAddr, int timeoutMs);

/*
 * Check if a port is open
 * @param host: Host address
 * @param port: Port number
 * @param timeoutMs: Timeout in milliseconds (0 = default 3000ms)
 * @return JSON: {"success":true,"data":{"host":"...","port":443,"open":true}}
 */
extern char* SuperRay_CheckPort(const char* host, int port, int timeoutMs);

/* ========== Config Builder Functions ========== */

/*
 * Create a quick proxy configuration
 * @param localPort: Local SOCKS5 port
 * @param protocol: Protocol (vmess, vless, trojan, ss)
 * @param address: Server address
 * @param port: Server port
 * @param uuid: UUID or password
 * @return JSON with generated config
 */
extern char* SuperRay_QuickConfig(int localPort, const char* protocol, const char* address, int port, const char* uuid);

/*
 * Build a detailed config from parameters
 * @param paramsJSON: JSON with local_port, protocol, address, port, uuid, password, method, network, tls, sni, path, host
 * @return JSON with generated config
 */
extern char* SuperRay_BuildConfig(const char* paramsJSON);

/*
 * Merge outbounds into a base config
 * @param baseConfigJSON: Base Xray config JSON
 * @param outboundsJSON: Array of outbound configs to add
 * @return JSON with merged config
 */
extern char* SuperRay_MergeConfigs(const char* baseConfigJSON, const char* outboundsJSON);

/* ========== Protocol Inbound Builders ========== */

/*
 * Create a SOCKS5 inbound configuration
 * @param tag: Inbound tag name
 * @param listen: Listen address (e.g., "127.0.0.1")
 * @param port: Listen port
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateSOCKSInbound(const char* tag, const char* listen, int port);

/*
 * Create a SOCKS5 inbound with authentication
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param user: Username
 * @param pass: Password
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateSOCKSInboundWithAuth(const char* tag, const char* listen, int port, const char* user, const char* pass);

/*
 * Create an HTTP proxy inbound configuration
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateHTTPInbound(const char* tag, const char* listen, int port);

/*
 * Create an HTTP proxy inbound with authentication
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param user: Username
 * @param pass: Password
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateHTTPInboundWithAuth(const char* tag, const char* listen, int port, const char* user, const char* pass);

/*
 * Create a dokodemo-door inbound (transparent proxy)
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param network: Network type ("tcp", "udp", "tcp,udp")
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateDokodemoInbound(const char* tag, const char* listen, int port, const char* network);

/*
 * Create a dokodemo-door inbound forwarding to specific address
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param destAddr: Destination address
 * @param destPort: Destination port
 * @param network: Network type
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateDokodemoInboundToAddr(const char* tag, const char* listen, int port, const char* destAddr, int destPort, const char* network);

/*
 * Create a VMess inbound configuration
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param uuid: User UUID
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateVMessInbound(const char* tag, const char* listen, int port, const char* uuid);

/*
 * Create a VLESS inbound configuration
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param uuid: User UUID
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateVLESSInbound(const char* tag, const char* listen, int port, const char* uuid);

/*
 * Create a VLESS inbound with XTLS
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param uuid: User UUID
 * @param flow: XTLS flow (e.g., "xtls-rprx-vision")
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateVLESSInboundXTLS(const char* tag, const char* listen, int port, const char* uuid, const char* flow);

/*
 * Create a Trojan inbound configuration
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param password: User password
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateTrojanInbound(const char* tag, const char* listen, int port, const char* password);

/*
 * Create a Shadowsocks inbound configuration
 * @param tag: Inbound tag name
 * @param listen: Listen address
 * @param port: Listen port
 * @param method: Encryption method (e.g., "aes-256-gcm")
 * @param password: Password
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateShadowsocksInbound(const char* tag, const char* listen, int port, const char* method, const char* password);

/* ========== Protocol Outbound Builders ========== */

/*
 * Create a freedom (direct) outbound
 * @param tag: Outbound tag name
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateFreedomOutbound(const char* tag);

/*
 * Create a blackhole outbound
 * @param tag: Outbound tag name
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateBlackholeOutbound(const char* tag);

/*
 * Create a VMess outbound configuration
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param uuid: User UUID
 * @param security: Security type ("auto", "aes-128-gcm", "chacha20-poly1305", "none")
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateVMessOutbound(const char* tag, const char* address, int port, const char* uuid, const char* security);

/*
 * Create a VMess outbound with full options
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param uuid: User UUID
 * @param security: Security type
 * @param network: Network type ("tcp", "ws", "grpc", "h2")
 * @param tls: Enable TLS (1=true, 0=false)
 * @param sni: Server Name Indication
 * @param path: WebSocket/gRPC path
 * @param host: Host header
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateVMessOutboundFull(const char* tag, const char* address, int port, const char* uuid, const char* security, const char* network, int tls, const char* sni, const char* path, const char* host);

/*
 * Create a VLESS outbound configuration
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param uuid: User UUID
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateVLESSOutbound(const char* tag, const char* address, int port, const char* uuid);

/*
 * Create a VLESS outbound with XTLS
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param uuid: User UUID
 * @param flow: XTLS flow (e.g., "xtls-rprx-vision")
 * @param sni: Server Name Indication
 * @param fingerprint: TLS fingerprint ("chrome", "firefox", "safari", "randomized")
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateVLESSOutboundXTLS(const char* tag, const char* address, int port, const char* uuid, const char* flow, const char* sni, const char* fingerprint);

/*
 * Create a VLESS outbound with Reality
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param uuid: User UUID
 * @param flow: XTLS flow
 * @param sni: Server Name Indication
 * @param fingerprint: TLS fingerprint
 * @param publicKey: Reality public key
 * @param shortId: Reality short ID
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateVLESSOutboundReality(const char* tag, const char* address, int port, const char* uuid, const char* flow, const char* sni, const char* fingerprint, const char* publicKey, const char* shortId);

/*
 * Create a VLESS outbound with full options
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param uuid: User UUID
 * @param flow: XTLS flow (empty for none)
 * @param network: Network type
 * @param security: Security type ("none", "tls", "reality")
 * @param sni: Server Name Indication
 * @param path: WebSocket/gRPC path
 * @param host: Host header
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateVLESSOutboundFull(const char* tag, const char* address, int port, const char* uuid, const char* flow, const char* network, const char* security, const char* sni, const char* path, const char* host);

/*
 * Create a Trojan outbound configuration
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param password: User password
 * @param sni: Server Name Indication (empty uses address)
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateTrojanOutbound(const char* tag, const char* address, int port, const char* password, const char* sni);

/*
 * Create a Trojan outbound with full options
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param password: User password
 * @param network: Network type ("tcp", "ws", "grpc")
 * @param sni: Server Name Indication
 * @param path: WebSocket/gRPC path
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateTrojanOutboundFull(const char* tag, const char* address, int port, const char* password, const char* network, const char* sni, const char* path);

/*
 * Create a Shadowsocks outbound configuration
 * @param tag: Outbound tag name
 * @param address: Server address
 * @param port: Server port
 * @param method: Encryption method
 * @param password: Password
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateShadowsocksOutbound(const char* tag, const char* address, int port, const char* method, const char* password);

/*
 * Create a WireGuard outbound configuration
 * @param tag: Outbound tag name
 * @param privateKey: WireGuard private key
 * @param addressJSON: JSON array of addresses, e.g. ["10.0.0.2/32", "fd00::2/128"]
 * @param peersJSON: JSON array of peer objects with publicKey, endpoint, allowedIPs
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateWireGuardOutbound(const char* tag, const char* privateKey, const char* addressJSON, const char* peersJSON);

/*
 * Create a DNS outbound
 * @param tag: Outbound tag name
 * @return JSON with outbound configuration
 */
extern char* SuperRay_CreateDNSOutbound(const char* tag);

/* ========== Full Config Builder ========== */

/*
 * Create a complete client configuration
 * @param localPort: Local SOCKS5 port (HTTP port will be localPort+1)
 * @param outboundJSON: JSON object of outbound configuration
 * @return JSON with complete Xray configuration
 */
extern char* SuperRay_CreateClientConfig(int localPort, const char* outboundJSON);

/*
 * Build a full Xray configuration from components
 * @param inboundsJSON: JSON array of inbound configurations
 * @param outboundsJSON: JSON array of outbound configurations
 * @param logLevel: Log level ("debug", "info", "warning", "error", "none")
 * @param dnsServersJSON: JSON array of DNS servers (can be empty "[]")
 * @return JSON with complete Xray configuration
 */
extern char* SuperRay_BuildFullConfig(const char* inboundsJSON, const char* outboundsJSON, const char* logLevel, const char* dnsServersJSON);

/*
 * Get list of supported protocols
 * @return JSON with inbound, outbound, transport, and security options
 */
extern char* SuperRay_GetProtocolList(void);

/* ========== Routing Rules ========== */

/*
 * Create a domain-based routing rule
 * @param domainsJSON: JSON array of domains, e.g. ["geosite:cn", "domain:example.com"]
 * @param outboundTag: Target outbound tag
 * @return JSON with routing rule
 */
extern char* SuperRay_CreateRoutingRuleDomain(const char* domainsJSON, const char* outboundTag);

/*
 * Create an IP-based routing rule
 * @param ipsJSON: JSON array of IPs, e.g. ["geoip:cn", "0.0.0.0/8"]
 * @param outboundTag: Target outbound tag
 * @return JSON with routing rule
 */
extern char* SuperRay_CreateRoutingRuleIP(const char* ipsJSON, const char* outboundTag);

/*
 * Create a port-based routing rule
 * @param portRange: Port range string, e.g. "80,443" or "1-1024"
 * @param outboundTag: Target outbound tag
 * @return JSON with routing rule
 */
extern char* SuperRay_CreateRoutingRulePort(const char* portRange, const char* outboundTag);

/* ========== TUN Device Functions ========== */

/*
 * Create a TUN inbound configuration
 * @param tag: Inbound tag name
 * @param addressesJSON: JSON array of addresses, e.g. ["10.0.0.1/24", "fd00::1/64"]
 * @param mtu: MTU size (default: 1500)
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateTUNInbound(const char* tag, const char* addressesJSON, int mtu);

/*
 * Create a TUN inbound with full options
 * @param tag: Inbound tag name
 * @param name: TUN device name (empty for auto)
 * @param addressesJSON: JSON array of addresses
 * @param mtu: MTU size
 * @param autoRoute: Auto configure routing (1=true, 0=false)
 * @return JSON with inbound configuration
 */
extern char* SuperRay_CreateTUNInboundFull(const char* tag, const char* name, const char* addressesJSON, int mtu, int autoRoute);

/*
 * Create a TUN device (gvisor netstack)
 * @param configJSON: JSON config with tag, addresses, mtu
 * @return JSON with device info
 */
extern char* SuperRay_CreateTUNDevice(const char* configJSON);

/*
 * Remove a TUN device
 * @param tag: TUN device tag
 * @return JSON with status
 */
extern char* SuperRay_RemoveTUNDevice(const char* tag);

/*
 * List all TUN devices
 * @return JSON with device list
 */
extern char* SuperRay_ListTUNDevices(void);

/*
 * Write IP packet to TUN device
 * @param tag: TUN device tag
 * @param packetData: Raw IP packet data
 * @param packetLen: Packet length
 * @return JSON with status
 */
extern char* SuperRay_WriteTUNPacket(const char* tag, const char* packetData, int packetLen);

/*
 * Close all TUN devices
 * @return JSON with status
 */
extern char* SuperRay_CloseAllTUNDevices(void);

/*
 * Get TUN device information
 * @param tag: TUN device tag
 * @return JSON with device info
 */
extern char* SuperRay_GetTUNInfo(const char* tag);

/* ========== Callback-based TUN API for NEPacketTunnelFlow ========== */

/*
 * Create a callback-based TUN device for NEPacketTunnelFlow integration
 * Use this mode when packets are received via NEPacketTunnelFlow.readPackets()
 * and sent via NEPacketTunnelFlow.writePackets()
 *
 * @param configJSON: JSON config with tag, addresses, mtu
 * @return JSON with device info
 *
 * Example usage flow:
 * 1. SuperRay_CreateCallbackTUN() - create the TUN device
 * 2. SuperRay_Run() - start Xray with appropriate config
 * 3. In NEPacketTunnelFlow.readPackets() callback:
 *    - Call SuperRay_EnqueueTUNPacket() for each received packet
 * 4. SuperRay_StopCallbackTUN() - stop when done
 */
extern char* SuperRay_CreateCallbackTUN(const char* configJSON);

/*
 * Enqueue a packet into the callback TUN device
 * Call this from NEPacketTunnelFlow.readPackets() handler
 *
 * @param tag: TUN device tag
 * @param packetData: Raw IP packet data
 * @param packetLen: Packet length
 * @return JSON with bytes count
 */
extern char* SuperRay_EnqueueTUNPacket(const char* tag, const char* packetData, int packetLen);

/*
 * Start the callback TUN device processing
 * @param tag: TUN device tag
 * @return JSON with status
 */
extern char* SuperRay_StartCallbackTUN(const char* tag);

/*
 * Stop and remove a callback TUN device
 * @param tag: TUN device tag
 * @return JSON with status
 */
extern char* SuperRay_StopCallbackTUN(const char* tag);

/*
 * Get callback TUN device information
 * @param tag: TUN device tag
 * @return JSON with device info including running status
 */
extern char* SuperRay_GetCallbackTUNInfo(const char* tag);

/*
 * List all callback TUN devices
 * @return JSON with device list
 */
extern char* SuperRay_ListCallbackTUNs(void);

/*
 * Close all callback TUN devices
 * @return JSON with status
 */
extern char* SuperRay_CloseAllCallbackTUNs(void);

/*
 * Set XrayDialer for callback TUN device
 * This connects the TUN device to an Xray instance for packet forwarding
 * @param tunTag: Callback TUN device tag
 * @param instanceID: Xray instance ID (from SuperRay_Run)
 * @param outboundTag: Xray outbound tag to use (e.g., "proxy"), empty for default
 * @return JSON with success status
 */
extern char* SuperRay_SetCallbackTUNDialer(const char* tunTag, const char* instanceID, const char* outboundTag);

/*
 * Create callback TUN with XrayDialer in one step
 * @param configJSON: TUN config {"tag":"tun0","addresses":["10.0.0.1/24"],"mtu":1500}
 * @param instanceID: Xray instance ID
 * @param outboundTag: Xray outbound tag (empty for "proxy")
 * @return JSON with TUN device info
 */
extern char* SuperRay_CreateCallbackTUNWithDialer(const char* configJSON, const char* instanceID, const char* outboundTag);

/* ========== TUN Packet Output API ========== */

/*
 * Packet output callback function type
 * Called when a packet is ready to be sent to NEPacketTunnelFlow.writePackets()
 *
 * @param data: Packet data pointer
 * @param dataLen: Packet length
 * @param family: AF_INET (2) for IPv4, AF_INET6 (30 on Darwin) for IPv6
 * @param userData: User data passed to SetTUNPacketCallback
 */
typedef void (*SuperRay_PacketOutputCallback)(const void* data, int dataLen, int family, void* userData);

/*
 * Set packet output callback for TUN device
 * When gVisor has a packet ready to send, this callback will be called
 * Use this to send packets back to NEPacketTunnelFlow.writePackets()
 *
 * @param tag: TUN device tag
 * @param callback: C function pointer to receive packets
 * @param userData: User data passed to callback
 * @return JSON with status
 *
 * Example Swift usage:
 *   let callback: @convention(c) (UnsafeRawPointer?, Int32, Int32, UnsafeMutableRawPointer?) -> Void = { data, len, family, _ in
 *       guard let data = data else { return }
 *       let packet = Data(bytes: data, count: Int(len))
 *       let proto = NSNumber(value: family == 2 ? AF_INET : AF_INET6)
 *       packetFlow.writePackets([packet], withProtocols: [proto])
 *   }
 *   SuperRay_SetTUNPacketCallback(tag, callback, nil)
 */
extern char* SuperRay_SetTUNPacketCallback(const char* tag, void* callback, void* userData);

/*
 * Read a packet from TUN output buffer (polling mode, non-blocking)
 * Alternative to SetTUNPacketCallback for applications that prefer polling
 *
 * @param tag: TUN device tag
 * @param buffer: Buffer to receive packet data
 * @param bufferLen: Buffer size (should be >= MTU)
 * @return Number of bytes read, 0 if no packet available, -1 on error
 */
extern int SuperRay_ReadTUNPacket(const char* tag, void* buffer, int bufferLen);

/*
 * Read a packet from TUN output buffer with IP family (polling mode, non-blocking)
 *
 * @param tag: TUN device tag
 * @param buffer: Buffer to receive packet data
 * @param bufferLen: Buffer size
 * @param family: Output parameter for IP family (2=IPv4, 30=IPv6 on Darwin)
 * @return Number of bytes read, 0 if no packet available, -1 on error
 */
extern int SuperRay_ReadTUNPacketWithFamily(const char* tag, void* buffer, int bufferLen, int* family);

/* ========== Traffic Statistics ========== */

/*
 * Get traffic statistics
 * @return JSON with upload, download bytes and connection count
 */
extern char* SuperRay_GetTrafficStats(void);

/*
 * Reset traffic statistics
 * @return JSON with status
 */
extern char* SuperRay_ResetTrafficStats(void);

/*
 * Get active connections
 * @return JSON with connection list
 */
extern char* SuperRay_GetConnections(void);

/*
 * Get active connection count
 * @return Number of active connections
 */
extern int SuperRay_GetConnectionCount(void);

/* ========== Xray Core Stats (Direct Function Export, No gRPC) ========== */

/*
 * Get Xray core traffic statistics from all running instances
 * @return JSON: {"success":true,"data":{"uplink":123,"downlink":456,"uplink_rate":100.5,"downlink_rate":200.3,"users":{},"inbounds":{},"outbounds":{}}}
 * Note: Requires "stats":{} in Xray config to enable statistics
 */
extern char* SuperRay_GetXrayStats(void);

/*
 * Get Xray core stats for a specific instance
 * @param instanceID: The instance ID returned by SuperRay_Run
 * @return JSON with stats for the specified instance
 */
extern char* SuperRay_GetXrayStatsForInstance(const char* instanceID);

/*
 * Reset all Xray stats counters
 * @return JSON with status
 */
extern char* SuperRay_ResetXrayStats(void);

/*
 * Get current upload/download speed
 * @return JSON: {"success":true,"data":{"uplink_rate":1234.5,"downlink_rate":5678.9,"uplink_kbps":1.2,"downlink_kbps":5.5,"uplink_mbps":0.001,"downlink_mbps":0.005}}
 * Note: Rate is calculated based on the time since the last call to this function
 */
extern char* SuperRay_GetCurrentSpeed(void);

/* ========== Subscription Management ========== */

/*
 * Add a subscription
 * @param name: Subscription name
 * @param url: Subscription URL
 * @return JSON with status
 */
extern char* SuperRay_AddSubscription(const char* name, const char* url);

/*
 * Remove a subscription
 * @param name: Subscription name
 * @return JSON with status
 */
extern char* SuperRay_RemoveSubscription(const char* name);

/*
 * Update a subscription (fetch and parse)
 * @param name: Subscription name
 * @return JSON with subscription info and servers
 */
extern char* SuperRay_UpdateSubscription(const char* name);

/*
 * Update all subscriptions
 * @return JSON with results for each subscription
 */
extern char* SuperRay_UpdateAllSubscriptions(void);

/*
 * Get subscription info
 * @param name: Subscription name
 * @return JSON with subscription info
 */
extern char* SuperRay_GetSubscription(const char* name);

/*
 * List all subscriptions
 * @return JSON with subscription names
 */
extern char* SuperRay_ListSubscriptions(void);

/*
 * Get all servers from all subscriptions
 * @return JSON with server list
 */
extern char* SuperRay_GetAllServers(void);

/*
 * Export subscription as JSON
 * @param name: Subscription name
 * @return JSON with subscription data
 */
extern char* SuperRay_ExportSubscription(const char* name);

/*
 * Import subscription from JSON
 * @param jsonData: Subscription JSON data
 * @return JSON with status
 */
extern char* SuperRay_ImportSubscription(const char* jsonData);

/* ========== Logging ========== */

/*
 * Set log level
 * @param level: Log level ("debug", "info", "warning", "error", "none")
 * @return JSON with status
 */
extern char* SuperRay_SetLogLevel(const char* level);

/*
 * Get current log level
 * @return JSON with current level
 */
extern char* SuperRay_GetLogLevel(void);

/*
 * Get recent log entries
 * @param count: Number of entries to retrieve
 * @return JSON with log entries
 */
extern char* SuperRay_GetRecentLogs(int count);

/*
 * Clear log buffer
 * @return JSON with status
 */
extern char* SuperRay_ClearLogs(void);

/*
 * Write a log entry
 * @param level: Log level
 * @param tag: Log tag
 * @param message: Log message
 * @return JSON with status
 */
extern char* SuperRay_Log(const char* level, const char* tag, const char* message);

/* ========== Speed Test / Latency ========== */

/*
 * TCP ping to test latency
 * @param address: Server address
 * @param port: Server port
 * @param timeoutMs: Timeout in milliseconds
 * @return JSON with latency result
 */
extern char* SuperRay_TCPPing(const char* address, int port, int timeoutMs);

/*
 * TCP ping multiple times
 * @param address: Server address
 * @param port: Server port
 * @param count: Number of pings
 * @param timeoutMs: Timeout per ping
 * @return JSON with average, min, max latency
 */
extern char* SuperRay_TCPPingMultiple(const char* address, int port, int count, int timeoutMs);

/*
 * Batch latency test for multiple servers
 * @param serversJSON: JSON array of servers [{address, port, name}]
 * @param concurrent: Max concurrent tests
 * @param count: Pings per server
 * @param timeoutMs: Timeout per ping
 * @return JSON with sorted results
 */
extern char* SuperRay_BatchLatencyTest(const char* serversJSON, int concurrent, int count, int timeoutMs);

/*
 * Batch latency test for proxy servers using HTTP ping through actual proxy connection
 * @param serversJSON: JSON array of server objects with full configuration
 * @param concurrent: Max concurrent tests
 * @param timeoutMs: Timeout per test in milliseconds
 * @return JSON with sorted results
 */
extern char* SuperRay_BatchProxyLatencyTest(const char* serversJSON, int concurrent, int timeoutMs);

/*
 * Run download speed test
 * @param downloadURL: URL to download from
 * @param proxyAddr: Proxy address (host:port) or empty
 * @param durationSec: Test duration in seconds
 * @return JSON with download speed in Mbps
 */
extern char* SuperRay_SpeedTest(const char* downloadURL, const char* proxyAddr, int durationSec);

/*
 * Test all servers in a subscription
 * @param subscriptionName: Name of subscription
 * @param concurrent: Max concurrent tests
 * @param timeoutMs: Timeout per test
 * @return JSON with sorted results
 */
extern char* SuperRay_TestSubscriptionServers(const char* subscriptionName, int concurrent, int timeoutMs);

/* ========== Auto Failover ========== */

/*
 * Setup automatic failover
 * @param serversJSON: JSON array of servers
 * @param checkIntervalSec: Health check interval in seconds
 * @param failThreshold: Consecutive failures to trigger switch
 * @param latencyLimitMs: Max acceptable latency (0 = no limit)
 * @return JSON with status
 */
extern char* SuperRay_SetupFailover(const char* serversJSON, int checkIntervalSec, int failThreshold, int latencyLimitMs);

/*
 * Start failover monitoring
 * @return JSON with status
 */
extern char* SuperRay_StartFailover(void);

/*
 * Stop failover monitoring
 * @return JSON with status
 */
extern char* SuperRay_StopFailover(void);

/*
 * Get current active server
 * @return JSON with server info
 */
extern char* SuperRay_GetCurrentServer(void);

/*
 * Manually switch to a server
 * @param index: Server index
 * @return JSON with status
 */
extern char* SuperRay_SwitchServer(int index);

/* ========== System TUN Functions (Desktop Platforms) ========== */

/*
 * Create a system TUN device (macOS/Linux/Windows only)
 * Requires root/administrator privileges
 * On iOS/Android: returns error, use Callback TUN API instead
 *
 * @param configJSON: JSON configuration
 *   {
 *     "tag": "tun0",
 *     "name": "utun",        // optional, auto-generated if empty
 *     "mtu": 1500,
 *     "addresses": ["10.255.0.1/24"]
 *   }
 * @return JSON with device info: {"tag":"tun0","name":"utun5","mtu":1500,"status":"created"}
 */
extern char* SuperRay_CreateSystemTUN(const char* configJSON);

/*
 * Start TUN stack connected to Xray instance
 * Routes TUN traffic through the specified Xray outbound
 *
 * @param tag: TUN device tag (from CreateSystemTUN)
 * @param instanceID: Xray instance ID (from SuperRay_Run)
 * @param outboundTag: Xray outbound tag (e.g., "proxy"), empty for default
 * @return JSON with status
 */
extern char* SuperRay_StartSystemTUNStack(const char* tag, const char* instanceID, const char* outboundTag);

/*
 * Setup system routes for TUN (full global proxy mode)
 * Configures routing table to send all traffic through TUN
 * Excludes VPN server address to prevent routing loops
 *
 * @param tag: TUN device tag
 * @param serverAddress: VPN server address to exclude from routing
 * @return JSON with status
 */
extern char* SuperRay_SetupRoutes(const char* tag, const char* serverAddress);

/*
 * Cleanup system routes (restore original routing)
 * @param tag: TUN device tag
 * @return JSON with status
 */
extern char* SuperRay_CleanupRoutes(const char* tag);

/*
 * Close a system TUN device
 * Automatically stops TUN stack and cleans up routes
 * @param tag: TUN device tag
 * @return JSON with status
 */
extern char* SuperRay_CloseSystemTUN(const char* tag);

/*
 * Close all system TUN devices
 * @return JSON with status
 */
extern char* SuperRay_CloseAllSystemTUNs(void);

/* ========== iOS Memory Optimization ========== */

/*
 * Initialize iOS memory optimizations
 * Should be called as early as possible in the iOS app lifecycle
 * On non-iOS platforms, this is a no-op
 *
 * @param configJSON: JSON configuration string, or NULL for defaults
 *   {
 *     "memory_limit_mb": 12,      // Soft memory limit (8-14 MB for iOS)
 *     "max_procs": 2,             // GOMAXPROCS (1-4)
 *     "gc_percent": 50,           // GOGC percentage (lower = more frequent GC)
 *     "gc_interval_seconds": 30   // Periodic GC interval (0 to disable)
 *   }
 * @return JSON with previous GOMAXPROCS and applied config
 */
extern char* SuperRay_InitIOSMemory(const char* configJSON);

/*
 * Initialize iOS memory with default settings (12MB limit, GOMAXPROCS=2)
 * @return JSON with configuration
 */
extern char* SuperRay_InitIOSMemoryDefault(void);

/*
 * Initialize iOS memory with aggressive settings (8MB limit, GOMAXPROCS=1)
 * Use for very constrained memory environments
 * @return JSON with configuration
 */
extern char* SuperRay_InitIOSMemoryAggressive(void);

/*
 * Initialize iOS memory with Tailscale-style ultra-aggressive settings
 * Based on Tailscale's successful iOS gVisor netstack implementation
 * Uses: 6MB limit, GOMAXPROCS=1, GCPercent=5, GCInterval=5s
 * @return JSON with configuration
 */
extern char* SuperRay_InitIOSMemoryTailscale(void);

/*
 * Get current memory usage statistics
 * Works on all platforms
 * @return JSON with memory stats (alloc_mb, heap_mb, num_gc, etc.)
 */
extern char* SuperRay_GetMemoryStats(void);

/*
 * Force immediate garbage collection
 * @return JSON with memory stats after GC
 */
extern char* SuperRay_ForceGC(void);

/*
 * Handle iOS memory warning
 * Should be called when iOS sends didReceiveMemoryWarning
 * Aggressively frees memory and temporarily increases GC frequency
 * @return JSON with handled status and memory stats
 */
extern char* SuperRay_HandleMemoryWarning(void);

/*
 * Check if memory usage is approaching the limit
 * Returns true if heap usage is above 80% of configured limit
 * Only meaningful on iOS; always returns false on other platforms
 * @return JSON with memory_pressure boolean
 */
extern char* SuperRay_IsMemoryPressure(void);

/*
 * Stop periodic GC goroutine if running
 * Should be called when shutting down
 * @return JSON with stopped status
 */
extern char* SuperRay_StopPeriodicGC(void);

/* ========== Memory Management ========== */

/*
 * Free memory allocated by SuperRay functions
 * Must be called for every returned char* to prevent memory leaks
 * @param ptr: Pointer returned by SuperRay functions
 */
extern void SuperRay_Free(char* ptr);

/*
 * Free raw bytes allocated by SuperRay
 * @param ptr: Pointer to free
 */
extern void SuperRay_FreeBytes(void* ptr);

/* ========== TUN Service API ========== */

/*
 * Create a TUN service for an Xray instance
 * @param instanceID: Xray instance ID (used as handle)
 * @return JSON: {"success":true,"data":{"handle":"...","status":"created"}}
 */
extern char* SuperRay_TUNCreate(const char* instanceID);

/*
 * Start the TUN service (creates device, configures routing)
 * @param handle: TUN service handle (instance ID)
 * @param serverAddr: VPN server address for route bypass (e.g., "1.2.3.4:443")
 * @param tunAddr: TUN IP with CIDR (e.g., "10.0.0.1/24"), NULL or empty for default
 * @param dnsAddr: DNS server (e.g., "8.8.8.8:53"), NULL or empty for default
 * @param mtu: MTU size (0 for default 1500)
 * @return JSON: {"success":true,"data":{"status":"running","device_name":"...","mtu":1500}}
 */
extern char* SuperRay_TUNStart(const char* handle, const char* serverAddr, const char* tunAddr, const char* dnsAddr, int mtu);

/*
 * Stop the TUN service (restores routing, closes device)
 * @param handle: TUN service handle
 * @return JSON: {"success":true,"data":{"status":"stopped"}}
 */
extern char* SuperRay_TUNStop(const char* handle);

/*
 * Check if TUN service is running
 * @param handle: TUN service handle
 * @return 1 if running, 0 if not running or invalid handle
 */
extern int SuperRay_TUNIsRunning(const char* handle);

/*
 * Get TUN service information
 * @param handle: TUN service handle
 * @return JSON: {"success":true,"data":{"running":true,"device_name":"...","mtu":1500}}
 */
extern char* SuperRay_TUNGetInfo(const char* handle);

/*
 * Destroy the TUN service and free resources
 * @param handle: TUN service handle
 * @return JSON: {"success":true,"data":{"status":"destroyed"}}
 */
extern char* SuperRay_TUNDestroy(const char* handle);

/* ========== DNS Configuration API ========== */

/*
 * Set DNS servers (primary and optional secondary)
 * @param primary: Primary DNS address (e.g., "8.8.8.8:53" or "114.114.114.114:53")
 * @param secondary: Secondary DNS address (e.g., "1.1.1.1:53"), can be empty/NULL
 * @return JSON with configuration status
 */
extern char* SuperRay_SetDNSServer(const char* primary, const char* secondary);

/*
 * Get current DNS server configuration
 * @return JSON with current primary_dns and secondary_dns
 */
extern char* SuperRay_GetDNSServer(void);

/*
 * Reset DNS configuration to defaults
 * @return JSON with reset status
 */
extern char* SuperRay_ResetDNSServer(void);

/* ========== Timeout Configuration API ========== */

/*
 * Set global timeout configuration for all network operations
 * @param tcpPingMs: TCP Ping timeout in milliseconds (default 5000)
 * @param httpPingMs: HTTP Ping timeout in milliseconds (default 10000)
 * @param dnsMs: DNS query timeout in milliseconds (default 10000)
 * @param tcpConnMs: TCP connection timeout in milliseconds (default 30000)
 * @return JSON with configuration status
 */
extern char* SuperRay_SetTimeoutConfig(int tcpPingMs, int httpPingMs, int dnsMs, int tcpConnMs);

/*
 * Get current timeout configuration
 * @return JSON with current timeout values in milliseconds
 */
extern char* SuperRay_GetTimeoutConfig(void);

/*
 * Reset timeout configuration to defaults
 * @return JSON with reset status
 */
extern char* SuperRay_ResetTimeoutConfig(void);

/* ========== Buffer Configuration API ========== */

/*
 * Set network stack buffer configuration
 * @param tcpRxSize: TCP receive buffer size in bytes (e.g., 1048576 for 1MB)
 * @param tcpTxSize: TCP send buffer size in bytes (e.g., 1048576 for 1MB)
 * @param channelSize: Packet channel size (e.g., 512)
 * @return JSON with configuration status
 * @note: Useful for optimizing memory usage on low-memory devices or performance on high-bandwidth networks
 */
extern char* SuperRay_SetBufferConfig(int tcpRxSize, int tcpTxSize, int channelSize);

/*
 * Get current buffer configuration
 * @return JSON with current buffer sizes
 */
extern char* SuperRay_GetBufferConfig(void);

/*
 * Reset buffer configuration to defaults
 * @return JSON with reset status
 */
extern char* SuperRay_ResetBufferConfig(void);

/* ========== TCP Options Configuration API ========== */

/*
 * Set TCP options configuration
 * @param tcpNodelay: 1 to enable TCP_NODELAY (disable Nagle's algorithm), 0 to disable
 * @param keepAliveMs: TCP keep-alive interval in milliseconds (0 to disable)
 * @param keepAliveProbesCount: Number of keep-alive probes (0-100)
 * @param congestionAlgo: Congestion control algorithm (cubic, reno, bbr, vegas, highspeed, htcp)
 * @return JSON with configuration status
 */
extern char* SuperRay_SetTCPOptions(int tcpNodelay, int keepAliveMs, int keepAliveProbesCount, const char* congestionAlgo);

/*
 * Get current TCP options configuration
 * @return JSON with all TCP options
 */
extern char* SuperRay_GetTCPOptions(void);

/*
 * Reset TCP options to defaults
 * @return JSON with reset status
 */
extern char* SuperRay_ResetTCPOptions(void);

/*
 * Set TCP_NODELAY option
 * @param enable: 1 to enable, 0 to disable
 * @return JSON with configuration status
 */
extern char* SuperRay_SetTCPNodelay(int enable);

/*
 * Set TCP keep-alive interval
 * @param ms: Keep-alive interval in milliseconds (0 to disable)
 * @return JSON with configuration status
 */
extern char* SuperRay_SetKeepAliveMs(int ms);

/*
 * Set TCP keep-alive probes count
 * @param count: Number of probes (0-100)
 * @return JSON with configuration status
 */
extern char* SuperRay_SetKeepAliveProbesCount(int count);

/*
 * Set TCP congestion control algorithm
 * @param algo: Algorithm name (cubic, reno, bbr, vegas, highspeed, htcp)
 * @return JSON with configuration status
 */
extern char* SuperRay_SetTCPCongestion(const char* algo);

/* ========== TUN Gateway Configuration API ========== */

/*
 * Set TUN device gateway IP address
 * @param handle: TUN service handle
 * @param gateway: Gateway IP address (e.g., "10.0.0.1" or "172.19.0.1")
 * @return JSON with configuration status
 * @note: Can only be called before TUN is started
 */
extern char* SuperRay_SetTUNGateway(const char* handle, const char* gateway);

/*
 * Get current TUN gateway IP address
 * @param handle: TUN service handle
 * @return JSON with current gateway address
 */
extern char* SuperRay_GetTUNGateway(const char* handle);

/* ========== Route Management API ========== */

/*
 * Add a custom route to the route manager
 * @param handle: TUN service handle
 * @param destCIDR: Destination CIDR (e.g., "192.168.0.0/16")
 * @param gateway: Gateway IP address (e.g., "10.0.0.1")
 * @return JSON: {"success":true,"data":{"destination":"...","gateway":"...","status":"added"}}
 */
extern char* SuperRay_AddRoute(const char* handle, const char* destCIDR, const char* gateway);

/*
 * Remove a custom route from the route manager
 * @param handle: TUN service handle
 * @param destCIDR: Destination CIDR to remove
 * @return JSON: {"success":true,"data":{"destination":"...","status":"removed"}}
 */
extern char* SuperRay_RemoveRoute(const char* handle, const char* destCIDR);

/*
 * Get all custom routes from the route manager
 * @param handle: TUN service handle
 * @return JSON: {"success":true,"data":{"routes":{"192.168.0.0/16":"10.0.0.1"},"count":1}}
 */
extern char* SuperRay_GetRoutes(const char* handle);

/*
 * Clear all custom routes from the route manager
 * @param handle: TUN service handle
 * @return JSON: {"success":true,"data":{"status":"cleared"}}
 */
extern char* SuperRay_ClearRoutes(const char* handle);

/* ========== Extended TUN API ========== */

/*
 * Create a TUN service with extended configuration (JSON-based)
 * @param instanceID: Xray instance ID
 * @param configJSON: TUN configuration JSON (optional, NULL/empty for defaults)
 *        Example: {"dns_addr":"8.8.8.8:53", "mtu":1500}
 * @return JSON with handle and configuration
 */
extern char* SuperRay_TUNCreateEx(const char* instanceID, const char* configJSON);

/*
 * Create Xray instance and TUN service in one call
 * @param xrayConfigJSON: Xray configuration JSON
 * @param tunConfigJSON: TUN configuration JSON (optional, NULL/empty for defaults)
 *        Example: {"dns_addr":"8.8.8.8:53", "mtu":1500}
 * @return JSON with instance_id and tun_handle
 */
extern char* SuperRay_CreateInstanceWithTUN(const char* xrayConfigJSON, const char* tunConfigJSON);

/*
 * Create, start Xray instance and TUN service, all in one call
 * @param xrayConfigJSON: Xray configuration JSON
 * @param tunConfigJSON: TUN configuration JSON (optional, NULL/empty for defaults)
 *        Example: {"dns_addr":"8.8.8.8:53", "mtu":1500, "tun_addr":"10.0.0.1/24"}
 * @param serverAddr: VPN server address for route bypass
 * @return JSON with complete configuration details
 */
extern char* SuperRay_StartInstanceWithTUN(const char* xrayConfigJSON, const char* tunConfigJSON, const char* serverAddr);

/* ========== Desktop Socket Protect (Bind Interface) API ========== */

/*
 * Set the network interface to bind outgoing sockets to.
 * On desktop platforms (macOS/Linux/Windows), this prevents TUN routing loops
 * by binding freedom outbound and direct sockets to the physical network interface.
 *
 * @param ifName: Interface name (e.g., "en0" on macOS, "eth0" on Linux)
 * @return JSON: {"success":true,"data":{"interface":"en0","ip":"192.168.1.100","status":"bound"}}
 */
extern char* SuperRay_SetBindInterface(const char* ifName);

/*
 * Get the currently bound interface name and IP
 * @return JSON: {"success":true,"data":{"interface":"en0","ip":"192.168.1.100"}}
 */
extern char* SuperRay_GetBindInterface(void);

/*
 * List available network interfaces with their IPs
 * Useful for settings UI to let users choose which interface to bind to
 * @return JSON: {"success":true,"data":{"interfaces":[{"name":"en0","ips":["192.168.1.100/24"],"is_default":true}],"default_interface":"en0","default_ip":"192.168.1.100"}}
 */
extern char* SuperRay_DetectInterfaces(void);

/* ========== Android TUN Stack API (VpnService Integration) ========== */

/*
 * Create an Android TUN stack from VpnService file descriptor
 * Does NOT start the TUN stack - call SuperRay_StartAndroidTUN after setting dialer
 *
 * @param fd: File descriptor from VpnService.Builder.establish()
 * @param configJSON: JSON configuration
 *   {
 *     "tag": "android-tun",       // TUN stack identifier (default: "android-tun")
 *     "mtu": 1500,                // MTU size (default: 1500)
 *     "dns_addr": "8.8.8.8:53"    // DNS server address (default: "8.8.8.8:53")
 *   }
 * @return JSON: {"success":true,"data":{"tag":"...","fd":N,"mtu":1500,"status":"created"}}
 */
extern char* SuperRay_CreateAndroidTUN(int fd, const char* configJSON);

/*
 * Create, bind Xray dialer, and start Android TUN in one call
 * This is the recommended API for simple use cases
 *
 * @param fd: File descriptor from VpnService.Builder.establish()
 * @param configJSON: JSON configuration (same as SuperRay_CreateAndroidTUN)
 * @param instanceID: Xray instance ID (from SuperRay_Run or SuperRay_CreateInstance)
 * @param outboundTag: Xray outbound tag to route traffic through (e.g., "proxy"), empty for default
 * @return JSON: {"success":true,"data":{"tag":"...","fd":N,"mtu":1500,"status":"running"}}
 */
extern char* SuperRay_CreateAndStartAndroidTUN(int fd, const char* configJSON, const char* instanceID, const char* outboundTag);

/*
 * Set XrayDialer for an existing Android TUN stack
 * Call this after SuperRay_CreateAndroidTUN and before SuperRay_StartAndroidTUN
 *
 * @param tunTag: TUN stack tag
 * @param instanceID: Xray instance ID
 * @param outboundTag: Xray outbound tag (empty for "proxy")
 * @return JSON: {"success":true,"data":{"status":"dialer_set"}}
 */
extern char* SuperRay_SetAndroidTUNDialer(const char* tunTag, const char* instanceID, const char* outboundTag);

/*
 * Start an existing Android TUN stack
 * The TUN must have a dialer set via SuperRay_SetAndroidTUNDialer first
 *
 * @param tunTag: TUN stack tag
 * @return JSON: {"success":true,"data":{"tag":"...","status":"running"}}
 */
extern char* SuperRay_StartAndroidTUN(const char* tunTag);

/*
 * Stop an Android TUN stack (can be restarted)
 *
 * @param tunTag: TUN stack tag
 * @return JSON: {"success":true,"data":{"tag":"...","status":"stopped"}}
 */
extern char* SuperRay_StopAndroidTUN(const char* tunTag);

/*
 * Close and remove an Android TUN stack
 * The TUN cannot be restarted after this call
 *
 * @param tunTag: TUN stack tag
 * @return JSON: {"success":true,"data":{"tag":"...","status":"closed"}}
 */
extern char* SuperRay_CloseAndroidTUN(const char* tunTag);

/*
 * Get information about an Android TUN stack
 *
 * @param tunTag: TUN stack tag
 * @return JSON: {"success":true,"data":{"tag":"...","exists":true}}
 */
extern char* SuperRay_GetAndroidTUNInfo(const char* tunTag);

/*
 * List all Android TUN stacks
 *
 * @return JSON: {"success":true,"data":{"tuns":["tag1","tag2"],"count":2}}
 */
extern char* SuperRay_ListAndroidTUNs(void);

/*
 * Close all Android TUN stacks
 *
 * @return JSON: {"success":true,"data":{"closed_count":N,"status":"all closed"}}
 */
extern char* SuperRay_CloseAllAndroidTUNs(void);

/* ========== Android Socket Protection API ========== */

/*
 * Socket protection callback type for Android VPN
 * This callback is invoked for each outgoing socket to prevent routing loops
 *
 * @param fd: Socket file descriptor to protect
 * @return 1 if protection succeeded (VpnService.protect() returned true), 0 otherwise
 *
 * Example JNI implementation:
 *   static int protect_socket(int fd) {
 *       return (*env)->CallBooleanMethod(env, vpnService, protectMethod, fd) ? 1 : 0;
 *   }
 */
typedef int (*socket_protect_callback)(int fd);

/*
 * Set the socket protection callback for Android VPN
 * This callback will be called for every outgoing socket created by SuperRay
 * to prevent VPN traffic from being routed back through the VPN (routing loop)
 *
 * @param callback: C function pointer that calls VpnService.protect(fd)
 *                  Pass NULL to clear the callback
 * @return JSON: {"success":true,"data":{"status":"callback_set"}}
 *
 * Example usage:
 *   // In JNI code:
 *   static int protect_socket(int fd) {
 *       JNIEnv* env = get_jni_env();
 *       return (*env)->CallBooleanMethod(env, vpnServiceObj, protectMethod, fd) ? 1 : 0;
 *   }
 *   SuperRay_SetSocketProtect(protect_socket);
 */
extern char* SuperRay_SetSocketProtect(socket_protect_callback callback);

/*
 * Manually protect a single socket file descriptor
 * Use this if you need to protect sockets outside of the automatic callback mechanism
 *
 * @param fd: Socket file descriptor to protect
 * @return JSON: {"success":true,"data":{"fd":N,"status":"protected"}}
 */
extern char* SuperRay_ProtectSocket(int fd);

/*
 * Clear the socket protection callback
 *
 * @return JSON: {"success":true,"data":{"status":"cleared"}}
 */
extern char* SuperRay_ClearSocketProtect(void);

#ifdef __cplusplus
}
#endif

#endif /* SUPERRAY_H */
