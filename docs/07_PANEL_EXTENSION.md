# Panel Extension Development Guide

[中文文档](07_PANEL_EXTENSION_zh.md)

This document describes how to add new panel system support for JinGo.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Interface Definition](#interface-definition)
3. [Development Steps](#development-steps)
4. [Code Examples](#code-examples)
5. [API Endpoint Mapping](#api-endpoint-mapping)
6. [Data Format Conversion](#data-format-conversion)
7. [Registration and Usage](#registration-and-usage)
8. [Testing Recommendations](#testing-recommendations)

---

## Architecture Overview

JinGo uses an extensible panel architecture:

```
┌─────────────────────────────────────────────────────┐
│                  JinGo Application Layer             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │ LoginView   │  │ OrderView   │  │ TicketView  │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  │
│         │                │                │         │
│         └────────────────┼────────────────┘         │
│                          ▼                          │
│                 ┌─────────────────┐                 │
│                 │  PanelManager   │                 │
│                 │ (Singleton Mgr) │                 │
│                 └────────┬────────┘                 │
│                          │                          │
│         ┌────────────────┼────────────────┐         │
│         ▼                ▼                ▼         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │ XBoard      │  │ V2Board     │  │ Custom Panel│  │
│  │ (JinDo)     │  │ (JinGo Ext) │  │ (User Ext)  │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  │
│         │                │                │         │
│         └────────────────┼────────────────┘         │
│                          ▼                          │
│                 ┌─────────────────┐                 │
│                 │ IPanelProvider  │                 │
│                 │ (Unified API)   │                 │
│                 └─────────────────┘                 │
└─────────────────────────────────────────────────────┘
```

**Core Components:**

| Component | Location | Description |
|-----------|----------|-------------|
| `IPanelProvider` | JinDo | Panel interface definition |
| `PanelManager` | JinDo | Panel manager (registration, switching, configuration) |
| `XBoardProvider` | JinDo | XBoard built-in implementation |
| `V2BoardProvider` | JinGo | V2Board extension implementation (reference) |

---

## Interface Definition

All panel providers must implement the `IPanelProvider` interface:

```cpp
class IPanelProvider : public QObject
{
    Q_OBJECT

public:
    // Callback types
    using SuccessCallback = std::function<void(const QJsonObject&)>;
    using ErrorCallback = std::function<void(const QString&)>;

    // Panel type enum
    enum PanelType { XBoard, V2Board, SSPanel, Custom };

    // ========== Required Methods ==========

    // Panel info
    virtual PanelType panelType() const = 0;
    virtual QString panelName() const = 0;
    virtual QString panelVersion() const = 0;

    // Configuration
    virtual void setBaseUrl(const QString& url) = 0;
    virtual QString baseUrl() const = 0;
    virtual void setAuthToken(const QString& token) = 0;
    virtual QString authToken() const = 0;

    // User authentication
    virtual void login(const QString& email, const QString& password,
                       SuccessCallback onSuccess, ErrorCallback onError) = 0;
    virtual void register_(const QString& email, const QString& password,
                           const QString& inviteCode, const QString& emailCode,
                           SuccessCallback onSuccess, ErrorCallback onError) = 0;
    virtual void logout(SuccessCallback onSuccess, ErrorCallback onError) = 0;

    // User info
    virtual void getUserInfo(SuccessCallback onSuccess, ErrorCallback onError) = 0;
    virtual void getSubscribeInfo(SuccessCallback onSuccess, ErrorCallback onError) = 0;

    // Plans
    virtual void fetchPlans(SuccessCallback onSuccess, ErrorCallback onError) = 0;

    // Orders
    virtual void createOrder(int planId, const QString& period, const QString& couponCode,
                             SuccessCallback onSuccess, ErrorCallback onError) = 0;
    virtual void fetchOrders(int page, int pageSize,
                             SuccessCallback onSuccess, ErrorCallback onError) = 0;

    // Payment
    virtual void fetchPaymentMethods(SuccessCallback onSuccess, ErrorCallback onError) = 0;
    virtual void getPaymentUrl(const QString& tradeNo, const QString& paymentMethod,
                               SuccessCallback onSuccess, ErrorCallback onError) = 0;

    // Tickets
    virtual void fetchTickets(int page, int pageSize,
                              SuccessCallback onSuccess, ErrorCallback onError) = 0;
    virtual void createTicket(const QString& subject, int level, const QString& message,
                              SuccessCallback onSuccess, ErrorCallback onError) = 0;

    // System config
    virtual void getSystemConfig(SuccessCallback onSuccess, ErrorCallback onError) = 0;

signals:
    void authenticationChanged(bool authenticated);
    void tokenUpdated(const QString& token);
    void errorOccurred(const QString& error);
};
```

---

## Development Steps

### Step 1: Create Header File

Create `MyPanelProvider.h` in `JinGo/src/panel/` directory:

```cpp
#ifndef MYPANELPROVIDER_H
#define MYPANELPROVIDER_H

#include <panel/IPanelProvider.h>
#include <QNetworkAccessManager>

class MyPanelProvider : public IPanelProvider
{
    Q_OBJECT

public:
    explicit MyPanelProvider(QObject* parent = nullptr);
    ~MyPanelProvider() override;

    // Panel info
    PanelType panelType() const override { return PanelType::Custom; }
    QString panelName() const override { return "MyPanel"; }
    QString panelVersion() const override { return "1.0"; }

    // Configuration
    void setBaseUrl(const QString& url) override;
    QString baseUrl() const override;
    void setAuthToken(const QString& token) override;
    QString authToken() const override;

    // Implement all pure virtual functions...
    void login(const QString& email, const QString& password,
               SuccessCallback onSuccess, ErrorCallback onError) override;
    // ... other methods

private:
    QString m_baseUrl;
    QString m_authToken;
    QNetworkAccessManager* m_networkManager;
};

#endif // MYPANELPROVIDER_H
```

### Step 2: Implement API Calls

Create `MyPanelProvider.cpp`:

```cpp
#include "MyPanelProvider.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>

namespace MyPanelEndpoints {
    const QString Login = "/api/auth/login";
    const QString UserInfo = "/api/user/info";
}

MyPanelProvider::MyPanelProvider(QObject* parent)
    : IPanelProvider(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
}

void MyPanelProvider::login(const QString& email,
                            const QString& password,
                            SuccessCallback onSuccess,
                            ErrorCallback onError)
{
    QString url = m_baseUrl + MyPanelEndpoints::Login;

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject data;
    data["email"] = email;
    data["password"] = password;

    QNetworkReply* reply = m_networkManager->post(
        request, QJsonDocument(data).toJson());

    connect(reply, &QNetworkReply::finished, [=]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            if (onError) onError(reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonObject response = doc.object();

        QString token = response["data"].toObject()["token"].toString();
        if (!token.isEmpty()) {
            setAuthToken(token);
            emit authenticationChanged(true);
            emit tokenUpdated(token);
        }

        if (onSuccess) onSuccess(response);
    });
}
```

### Step 3: Update CMakeLists.txt

Add source files in `JinGo/CMakeLists.txt`:

```cmake
set(NETWORK_SOURCES
    src/network/V2BoardProvider.cpp
    src/network/MyPanelProvider.cpp    # Add new file
)
```

### Step 4: Register Panel

Register in `main.cpp`:

```cpp
#include <panel/PanelManager.h>
#include "network/MyPanelProvider.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    PanelManager::instance().registerProvider(
        "mypanel",
        new MyPanelProvider()
    );

    PanelManager::instance().setPanelUrl(
        "mypanel",
        "https://panel.example.com"
    );

    // ... other initialization
}
```

---

## Code Examples

### API Endpoint Definition

```cpp
namespace MyPanelEndpoints {
    const QString Login = "/api/auth/login";
    const QString UserInfo = "/api/user/info";
    // ... other endpoints
}
```

### Response Handling

```cpp
// Extract Token (adjust based on your panel response format)
QString token = response["data"].toObject()["token"].toString();
if (!token.isEmpty()) {
    setAuthToken(token);
    emit authenticationChanged(true);
    emit tokenUpdated(token);
}
```

---

## API Endpoint Mapping

Different panel systems may have different API endpoints:

### Authentication

| Function | XBoard | V2Board | SSPanel |
|----------|--------|---------|---------|
| Login | `/passport/auth/login` | `/api/v1/passport/auth/login` | `/auth/login` |
| Register | `/passport/auth/register` | `/api/v1/passport/auth/register` | `/auth/register` |
| Logout | `/passport/auth/logout` | `/api/v1/passport/auth/logout` | `/auth/logout` |
| Send Verification Code | `/passport/comm/sendEmailVerify` | `/api/v1/passport/comm/sendEmailVerify` | `/auth/send` |

### User

| Function | XBoard | V2Board | SSPanel |
|----------|--------|---------|---------|
| User Info | `/user/info` | `/api/v1/user/info` | `/user` |
| Subscribe Info | `/user/getSubscribe` | `/api/v1/user/getSubscribe` | `/user/subscribe` |
| Reset Security | `/user/resetSecurity` | `/api/v1/user/resetSecurity` | `/user/reset` |

### Orders

| Function | XBoard | V2Board | SSPanel |
|----------|--------|---------|---------|
| Plan List | `/user/plan/fetch` | `/api/v1/user/plan/fetch` | `/user/shop` |
| Create Order | `/user/order/save` | `/api/v1/user/order/save` | `/user/order` |
| Order List | `/user/order/fetch` | `/api/v1/user/order/fetch` | `/user/order` |
| Payment Methods | `/user/order/getPaymentMethod` | `/api/v1/user/order/getPaymentMethod` | `/user/payment` |

### Tickets

| Function | XBoard | V2Board | SSPanel |
|----------|--------|---------|---------|
| Ticket List | `/user/ticket/fetch` | `/api/v1/user/ticket/fetch` | `/user/ticket` |
| Create Ticket | `/user/ticket/save` | `/api/v1/user/ticket/save` | `/user/ticket` |
| Reply Ticket | `/user/ticket/reply` | `/api/v1/user/ticket/reply` | `/user/ticket/{id}` |

---

## Data Format Conversion

Different panels may return different data formats. Convert to unified format:

### Login Response

**XBoard Format:**
```json
{
  "data": {
    "auth_data": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**V2Board Format:**
```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "auth_data": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**Unified Handling:**
```cpp
QString token = response["data"].toObject()["auth_data"].toString();
if (token.isEmpty()) {
    token = response["data"].toObject()["token"].toString();
}
```

### User Info

**XBoard/V2Board Format:**
```json
{
  "data": {
    "email": "user@example.com",
    "transfer_enable": 107374182400,
    "u": 1073741824,
    "d": 5368709120,
    "expired_at": 1735689600
  }
}
```

### User Info Normalization

```cpp
QJsonObject normalizeUserInfo(const QJsonObject& data)
{
    QJsonObject result;
    result["email"] = data["email"];

    qint64 total = data["transfer_enable"].toVariant().toLongLong();
    qint64 up = data["u"].toVariant().toLongLong();
    qint64 down = data["d"].toVariant().toLongLong();

    result["total_traffic"] = total;
    result["used_upload"] = up;
    result["used_download"] = down;
    result["used_traffic"] = up + down;
    result["remaining_traffic"] = total - up - down;
    result["expire_time"] = data["expired_at"];

    return result;
}
```

### Plan List

**Unified Format:**
```json
{
  "id": 1,
  "name": "Basic Plan",
  "price": 9.99,
  "traffic": 107374182400,
  "period": "month",
  "features": ["Unlimited speed", "Multi-device"]
}
```

---

## Registration and Usage

### Register at Application Startup

```cpp
#include <panel/PanelManager.h>
#include "network/MyPanelProvider.h"

void initPanelProviders()
{
    auto& pm = PanelManager::instance();

    pm.registerProvider("v2board", new V2BoardProvider());
    pm.setPanelUrl("v2board", "https://v2board.example.com");

    pm.registerProvider("mypanel", new MyPanelProvider());
    pm.setPanelUrl("mypanel", "https://mypanel.example.com");

    QString selectedPanel = Settings::value("panel/selected", "xboard");
    pm.setCurrentProvider(selectedPanel);
}
```

### Switch Panel in QML

```qml
ComboBox {
    id: panelSelector
    model: PanelManager.availableProviders

    onCurrentTextChanged: {
        PanelManager.setCurrentProvider(currentText)
    }
}

TextField {
    id: panelUrlField
    placeholderText: "Panel API URL"

    onEditingFinished: {
        PanelManager.setPanelUrl(
            panelSelector.currentText,
            text
        )
    }
}
```

### Use Panel API

```cpp
PanelManager::instance().login(email, password);

auto provider = PanelManager::instance().currentProvider();
provider->fetchPlans(
    [](const QJsonObject& response) {
        // Handle plan list
    },
    [](const QString& error) {
        // Handle error
    }
);
```

---

## Testing Recommendations

### 1. Unit Tests

```cpp
void TestMyPanelProvider::testLogin()
{
    MyPanelProvider provider;
    provider.setBaseUrl("https://test.example.com");

    QSignalSpy spy(&provider, &IPanelProvider::authenticationChanged);

    provider.login("test@example.com", "password",
        [](const QJsonObject& response) {
            QVERIFY(response.contains("data"));
        },
        [](const QString& error) {
            QFAIL(error.toUtf8());
        });

    // Wait for async completion
    QTRY_COMPARE(spy.count(), 1);
    QCOMPARE(spy.takeFirst().at(0).toBool(), true);
}
```

### 2. Integration Test Checklist

- [ ] Login/logout flow
- [ ] Token refresh
- [ ] Get user info
- [ ] Get subscription info
- [ ] Get plan list
- [ ] Create and query orders
- [ ] Payment flow
- [ ] Create and reply tickets
- [ ] Error handling (network errors, auth failures, etc.)

### 3. Debugging Tips

```cpp
// Enable network request logging
void MyPanelProvider::request(const QString& url, const QJsonObject& data)
{
    qDebug() << "[MyPanel] Request:" << url;
    qDebug() << "[MyPanel] Data:" << QJsonDocument(data).toJson();

    // ... send request

    // In response handler
    qDebug() << "[MyPanel] Response:" << reply->readAll();
}
```

---

## Reference Implementations

- **XBoardProvider**: `JinDo/src/panel/XBoardProvider.cpp`
- **V2BoardProvider**: `JinGo/src/panel/V2BoardProvider.cpp`

---

## FAQ

### Q: How to handle different authentication methods?

Set different request headers in `setAuthToken` based on panel type:

```cpp
void MyPanelProvider::setAuthToken(const QString& token)
{
    m_authToken = token;
    // Some panels use "Bearer token"
    // Some panels use "token"
    // Adjust based on your panel
}

QNetworkRequest createRequest(const QString& url)
{
    QNetworkRequest request(url);
    if (!m_authToken.isEmpty()) {
        // XBoard/V2Board format
        request.setRawHeader("Authorization", m_authToken.toUtf8());
        // Or Bearer format
        // request.setRawHeader("Authorization",
        //     ("Bearer " + m_authToken).toUtf8());
    }
    return request;
}
```

### Q: How to handle pagination?

Use unified `page` and `pageSize` parameters:

```cpp
void MyPanelProvider::fetchOrders(int page, int pageSize,
                                  SuccessCallback onSuccess,
                                  ErrorCallback onError)
{
    // Some panels use page/pageSize
    QString url = QString("%1/orders?page=%2&pageSize=%3")
        .arg(m_baseUrl).arg(page).arg(pageSize);

    // Some panels use offset/limit
    // int offset = (page - 1) * pageSize;
    // QString url = QString("%1/orders?offset=%2&limit=%3")
    //     .arg(m_baseUrl).arg(offset).arg(pageSize);

    // ...
}
```

### Q: How to support WebSocket real-time notifications?

Add WebSocket support in the provider:

```cpp
class MyPanelProvider : public IPanelProvider
{
    // ...
private:
    QWebSocket* m_webSocket;

public:
    void connectNotifications() {
        m_webSocket = new QWebSocket();
        connect(m_webSocket, &QWebSocket::textMessageReceived,
                this, &MyPanelProvider::onNotification);
        m_webSocket->open(QUrl(m_baseUrl + "/ws"));
    }

private slots:
    void onNotification(const QString& message) {
        // Handle real-time notifications
    }
};
```
