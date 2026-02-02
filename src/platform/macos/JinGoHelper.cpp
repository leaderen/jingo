/**
 * @file JinGoHelper.cpp
 * @brief JinGoHelper - setuid root helper for routing/DNS management
 * @details Standalone helper executable that runs with elevated privileges.
 *          Receives commands from JinGo main app via stdin/stdout.
 *          Manages system routes and DNS configuration for VPN operation.
 *
 * Commands (read from stdin as single-line JSON):
 *   {"action":"setup-routes",  "serverIP":"1.2.3.4", "tunIP":"172.19.0.1", "gateway":"192.168.1.1", "interface":"en0"}
 *   {"action":"restore-routes"}
 *   {"action":"setup-dns",     "servers":["8.8.8.8","1.1.1.1"]}
 *   {"action":"restore-dns"}
 *   {"action":"status"}
 *   {"action":"quit"}
 *
 * Response (written to stdout as single-line JSON):
 *   {"success":true}  or  {"success":false,"error":"..."}
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <array>
#include <unistd.h>
#include <signal.h>

static bool g_running = true;
static bool g_routesConfigured = false;
static std::string g_savedGateway;
static std::string g_savedInterface;

static void signalHandler(int) {
    g_running = false;
}

static bool executeCommand(const std::string& cmd) {
    return system(cmd.c_str()) == 0;
}

static std::string getDefaultGateway() {
    std::array<char, 256> buffer;
    std::string result;
    FILE* pipe = popen("route -n get default 2>/dev/null | awk '/gateway:/ {print $2}'", "r");
    if (pipe) {
        if (fgets(buffer.data(), buffer.size(), pipe)) {
            result = buffer.data();
            if (!result.empty() && result.back() == '\n')
                result.pop_back();
        }
        pclose(pipe);
    }
    return result;
}

static std::string getDefaultInterface() {
    std::array<char, 256> buffer;
    std::string result;
    FILE* pipe = popen("route -n get default 2>/dev/null | awk '/interface:/ {print $2}'", "r");
    if (pipe) {
        if (fgets(buffer.data(), buffer.size(), pipe)) {
            result = buffer.data();
            if (!result.empty() && result.back() == '\n')
                result.pop_back();
        }
        pclose(pipe);
    }
    return result;
}

static void respond(bool success, const char* error = nullptr) {
    if (success)
        printf("{\"success\":true}\n");
    else
        printf("{\"success\":false,\"error\":\"%s\"}\n", error ? error : "unknown");
    fflush(stdout);
}

static bool setupRoutes(const std::string& serverIP, const std::string& tunIP,
                        const std::string& gateway, const std::string& iface) {
    std::string gw = gateway.empty() ? getDefaultGateway() : gateway;
    std::string ifn = iface.empty() ? getDefaultInterface() : iface;

    if (gw.empty() || ifn.empty())
        return false;

    g_savedGateway = gw;
    g_savedInterface = ifn;

    // Route VPN server IP through original gateway
    executeCommand("route -n add -host " + serverIP + " " + gw);

    // Route all traffic through TUN
    executeCommand("route -n add -net 0.0.0.0/1 " + tunIP);
    executeCommand("route -n add -net 128.0.0.0/1 " + tunIP);

    g_routesConfigured = true;
    return true;
}

static bool restoreRoutes() {
    if (!g_routesConfigured)
        return true;

    executeCommand("route -n delete -net 0.0.0.0/1 2>/dev/null");
    executeCommand("route -n delete -net 128.0.0.0/1 2>/dev/null");

    g_routesConfigured = false;
    return true;
}

static bool setupDNS(const std::string& primary, const std::string& secondary) {
    std::string cmd = "networksetup -setdnsservers Wi-Fi " + primary;
    if (!secondary.empty())
        cmd += " " + secondary;
    return executeCommand(cmd);
}

static bool restoreDNS() {
    return executeCommand("networksetup -setdnsservers Wi-Fi Empty");
}

// Simple JSON field extractor (no external dependency)
static std::string jsonGetString(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":\"";
    auto pos = json.find(search);
    if (pos == std::string::npos) return "";
    pos += search.size();
    auto end = json.find('"', pos);
    if (end == std::string::npos) return "";
    return json.substr(pos, end - pos);
}

int main(int argc, char* argv[]) {
    // Drop stderr noise
    if (argc > 1 && strcmp(argv[1], "--version") == 0) {
        printf("JinGoHelper 1.0\n");
        return 0;
    }

    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);

    // Verify we are running as root
    if (geteuid() != 0) {
        fprintf(stderr, "JinGoHelper must run as root (setuid)\n");
        return 1;
    }

    char line[4096];
    while (g_running && fgets(line, sizeof(line), stdin)) {
        std::string input(line);
        if (!input.empty() && input.back() == '\n')
            input.pop_back();
        if (input.empty())
            continue;

        std::string action = jsonGetString(input, "action");

        if (action == "setup-routes") {
            std::string serverIP = jsonGetString(input, "serverIP");
            std::string tunIP = jsonGetString(input, "tunIP");
            std::string gateway = jsonGetString(input, "gateway");
            std::string iface = jsonGetString(input, "interface");
            if (serverIP.empty()) {
                respond(false, "missing serverIP");
            } else {
                respond(setupRoutes(serverIP, tunIP.empty() ? "172.19.0.1" : tunIP, gateway, iface));
            }
        } else if (action == "restore-routes") {
            respond(restoreRoutes());
        } else if (action == "setup-dns") {
            std::string primary = jsonGetString(input, "primary");
            std::string secondary = jsonGetString(input, "secondary");
            if (primary.empty()) primary = "8.8.8.8";
            respond(setupDNS(primary, secondary));
        } else if (action == "restore-dns") {
            respond(restoreDNS());
        } else if (action == "status") {
            printf("{\"success\":true,\"routes\":%s}\n", g_routesConfigured ? "true" : "false");
            fflush(stdout);
        } else if (action == "quit") {
            restoreRoutes();
            restoreDNS();
            respond(true);
            break;
        } else {
            respond(false, "unknown action");
        }
    }

    // Cleanup on exit
    if (g_routesConfigured) {
        restoreRoutes();
    }

    return 0;
}
