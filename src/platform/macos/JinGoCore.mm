/**
 * @file JinGoCore.mm
 * @brief JinGoCore - Standalone core service with Xray + TUN + routing
 * @details setuid root executable that runs as an independent process.
 *          The JinGo GUI app launches and controls this via stdin/stdout IPC.
 *
 *          Architecture (similar to FlClash's FlClashCore):
 *          - JinGoCore: root-privileged process managing Xray/TUN/routes/DNS
 *          - JinGo: unprivileged GUI app controlling JinGoCore via IPC
 *
 * Commands (read from stdin as single-line JSON):
 *   {"action":"start",    "config":"<xray JSON>", "serverAddr":"1.2.3.4:443"}
 *   {"action":"stop"}
 *   {"action":"status"}
 *   {"action":"version"}
 *   {"action":"stats"}
 *   {"action":"quit"}
 */

#import <Foundation/Foundation.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <unistd.h>
#include <signal.h>

#include "superray.h"

static bool g_running = true;
static bool g_xrayRunning = false;
static bool g_tunRunning = false;
static std::string g_instanceID;
static std::string g_tunHandle;

static void signalHandler(int) {
    g_running = false;
}

static void respond(bool success, const char* data = nullptr, const char* error = nullptr) {
    if (success) {
        if (data)
            printf("{\"success\":true,\"data\":%s}\n", data);
        else
            printf("{\"success\":true}\n");
    } else {
        printf("{\"success\":false,\"error\":\"%s\"}\n", error ? error : "unknown");
    }
    fflush(stdout);
}

// Simple JSON field extractor
static std::string jsonGetString(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":\"";
    auto pos = json.find(search);
    if (pos == std::string::npos) return "";
    pos += search.size();
    auto end = json.find('"', pos);
    if (end == std::string::npos) return "";
    return json.substr(pos, end - pos);
}

// Extract a possibly large JSON value (for "config" field that contains nested JSON)
static std::string jsonGetValue(const std::string& json, const std::string& key) {
    std::string search = "\"" + key + "\":";
    auto pos = json.find(search);
    if (pos == std::string::npos) return "";
    pos += search.size();

    // Skip whitespace
    while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\t'))
        pos++;

    if (pos >= json.size()) return "";

    // If it starts with quote, extract string
    if (json[pos] == '"') {
        pos++;
        std::string result;
        while (pos < json.size() && json[pos] != '"') {
            if (json[pos] == '\\' && pos + 1 < json.size()) {
                result += json[pos + 1];
                pos += 2;
            } else {
                result += json[pos];
                pos++;
            }
        }
        return result;
    }

    // If it starts with {, find matching }
    if (json[pos] == '{') {
        int depth = 0;
        size_t start = pos;
        while (pos < json.size()) {
            if (json[pos] == '{') depth++;
            else if (json[pos] == '}') { depth--; if (depth == 0) { pos++; break; } }
            else if (json[pos] == '"') {
                pos++;
                while (pos < json.size() && json[pos] != '"') {
                    if (json[pos] == '\\') pos++;
                    pos++;
                }
            }
            pos++;
        }
        return json.substr(start, pos - start);
    }

    return "";
}

static void stopAll() {
    if (g_tunRunning && !g_tunHandle.empty()) {
        char* result = SuperRay_TUNStop(g_tunHandle.c_str());
        if (result) SuperRay_Free(result);
        result = SuperRay_TUNDestroy(g_tunHandle.c_str());
        if (result) SuperRay_Free(result);
        g_tunRunning = false;
        g_tunHandle.clear();
    }

    if (g_xrayRunning) {
        char* result = SuperRay_StopAll();
        if (result) SuperRay_Free(result);
        g_xrayRunning = false;
        g_instanceID.clear();
    }
}

static bool startCore(const std::string& xrayConfig, const std::string& serverAddr) {
    // Stop existing if running
    stopAll();

    @autoreleasepool {
        // Set asset directory for geo files
        NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
        if (bundlePath) {
            char* result = SuperRay_SetAssetDir([bundlePath UTF8String]);
            if (result) SuperRay_Free(result);
        }

        // Detect and bind to default interface to prevent routing loops
        char* ifResult = SuperRay_DetectInterfaces();
        if (ifResult) {
            // Parse default_interface from result
            NSString* jsonStr = [NSString stringWithUTF8String:ifResult];
            NSData* jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
            NSString* defaultIf = parsed[@"data"][@"default_interface"];
            if (defaultIf) {
                char* bindResult = SuperRay_SetBindInterface([defaultIf UTF8String]);
                if (bindResult) SuperRay_Free(bindResult);
            }
            SuperRay_Free(ifResult);
        }

        // Start Xray
        char* runResult = SuperRay_Run(xrayConfig.c_str());
        if (!runResult) {
            return false;
        }

        NSString* runJson = [NSString stringWithUTF8String:runResult];
        NSData* runData = [runJson dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* runParsed = [NSJSONSerialization JSONObjectWithData:runData options:0 error:nil];
        SuperRay_Free(runResult);

        if (![runParsed[@"success"] boolValue]) {
            return false;
        }

        g_instanceID = [runParsed[@"data"][@"id"] UTF8String] ?: "";
        g_xrayRunning = true;

        // Create and start TUN
        char* tunResult = SuperRay_TUNCreate(g_instanceID.c_str());
        if (!tunResult) {
            return true; // Xray running but no TUN
        }

        NSString* tunJson = [NSString stringWithUTF8String:tunResult];
        NSData* tunData = [tunJson dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* tunParsed = [NSJSONSerialization JSONObjectWithData:tunData options:0 error:nil];
        SuperRay_Free(tunResult);

        if ([tunParsed[@"success"] boolValue]) {
            g_tunHandle = g_instanceID;

            char* startResult = SuperRay_TUNStart(
                g_tunHandle.c_str(),
                serverAddr.c_str(),
                "10.255.0.1/24",  // TUN address
                "8.8.8.8:53",     // DNS
                1500              // MTU
            );
            if (startResult) {
                NSString* startJson = [NSString stringWithUTF8String:startResult];
                NSData* startData = [startJson dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary* startParsed = [NSJSONSerialization JSONObjectWithData:startData options:0 error:nil];
                SuperRay_Free(startResult);
                g_tunRunning = [startParsed[@"success"] boolValue];
            }
        }
    }

    return true;
}

int main(int argc, char* argv[]) {
    if (argc > 1 && strcmp(argv[1], "--version") == 0) {
        char* ver = SuperRay_Version();
        if (ver) {
            printf("JinGoCore 1.0 (SuperRay %s)\n", ver);
            SuperRay_Free(ver);
        } else {
            printf("JinGoCore 1.0\n");
        }
        return 0;
    }

    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);

    // Verify root privileges
    if (geteuid() != 0) {
        fprintf(stderr, "JinGoCore must run as root (setuid)\n");
        return 1;
    }

    char line[65536]; // Large buffer for Xray config
    while (g_running && fgets(line, sizeof(line), stdin)) {
        std::string input(line);
        if (!input.empty() && input.back() == '\n')
            input.pop_back();
        if (input.empty())
            continue;

        std::string action = jsonGetString(input, "action");

        if (action == "start") {
            std::string config = jsonGetValue(input, "config");
            std::string serverAddr = jsonGetString(input, "serverAddr");
            if (config.empty()) {
                respond(false, nullptr, "missing config");
            } else {
                bool ok = startCore(config, serverAddr);
                if (ok) {
                    std::string data = "{\"xray\":true,\"tun\":" +
                        std::string(g_tunRunning ? "true" : "false") + "}";
                    respond(true, data.c_str());
                } else {
                    respond(false, nullptr, "failed to start xray");
                }
            }
        } else if (action == "stop") {
            stopAll();
            respond(true);
        } else if (action == "status") {
            char data[256];
            snprintf(data, sizeof(data),
                "{\"xray\":%s,\"tun\":%s}",
                g_xrayRunning ? "true" : "false",
                g_tunRunning ? "true" : "false");
            respond(true, data);
        } else if (action == "version") {
            char* ver = SuperRay_Version();
            char data[128];
            snprintf(data, sizeof(data), "{\"version\":\"%s\"}", ver ? ver : "unknown");
            if (ver) SuperRay_Free(ver);
            respond(true, data);
        } else if (action == "stats") {
            @autoreleasepool {
                char* stats = SuperRay_GetXrayStats();
                if (stats) {
                    printf("%s\n", stats);
                    fflush(stdout);
                    SuperRay_Free(stats);
                } else {
                    respond(false, nullptr, "no stats available");
                }
            }
        } else if (action == "quit") {
            stopAll();
            respond(true);
            break;
        } else {
            respond(false, nullptr, "unknown action");
        }
    }

    stopAll();
    return 0;
}
