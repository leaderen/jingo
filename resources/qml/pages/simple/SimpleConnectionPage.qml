// pages/simple/SimpleConnectionPage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Rectangle {
    id: simpleConnectionPage
    color: Theme.colors.pageBackground

    readonly property var mainWindow: ApplicationWindow.window
    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    // Connection state properties (manual update via signals to avoid accessing deleted objects)
    property bool isConnected: false
    property bool isConnecting: false
    property bool isDisconnecting: false
    property bool isAuthenticated: false

    // Server info properties
    property var currentServer: null
    property string serverName: qsTr("No Server Selected")
    property string serverCountryCode: ""

    // Subscription info properties
    property var subscribeData: null
    property string planName: qsTr("No Plan")
    property string expiryDateText: "--"
    property real trafficUsed: 0
    property real trafficTotal: 0
    property real trafficProgress: 0

    // Notice/announcement properties
    property var noticeList: []
    property int currentNoticeIndex: 0
    property bool hasNotice: noticeList.length > 0
    property bool noticeExpanded: false

    property string currentNoticeTitle: hasNotice ? (noticeList[currentNoticeIndex].title || "") : ""
    property string currentNoticeContent: hasNotice ? (noticeList[currentNoticeIndex].content || "").replace(/<[^>]*>/g, "") : ""

    function loadNotices() {
        try {
            if (typeof subscriptionManager !== 'undefined' && subscriptionManager) {
                subscriptionManager.fetchNotices()
            }
        } catch (e) {
            // Ignore
        }
    }

    // Auto-rotate notices every 5 seconds
    Timer {
        id: noticeRotateTimer
        interval: 5000
        running: noticeList.length > 1 && !noticeExpanded
        repeat: true
        onTriggered: {
            currentNoticeIndex = (currentNoticeIndex + 1) % noticeList.length
        }
    }

    // Computed color based on connection state
    readonly property color mainColor: {
        if (isConnecting || isDisconnecting) return Theme.colors.warning
        if (isConnected) return Theme.colors.success
        return Theme.colors.primary
    }

    readonly property string connectButtonText: {
        if (isConnecting) return qsTr("Connecting...")
        if (isDisconnecting) return qsTr("Disconnecting...")
        if (isConnected) return qsTr("Connected")
        return qsTr("Not Connected")
    }

    // Server select dialog
    ServerSelectDialog {
        id: serverSelectDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        isDarkMode: simpleConnectionPage.isDarkMode
        selectedServer: simpleConnectionPage.currentServer

        onServerSelected: function(server) {
            if (!server) return
            if (!server.id) return
            if (!vpnManager) return

            try {
                vpnManager.selectServer(server)
            } catch (error) {
                // Ignore selection errors
            }
        }
    }

    // Safely get current server for connect action
    function getCurrentServer() {
        try {
            if (typeof vpnManager !== 'undefined' && vpnManager) {
                return vpnManager.currentServer || null
            }
        } catch (e) {
            // Ignore
        }
        return null
    }

    // Update connection state from vpnManager
    function updateConnectionState() {
        try {
            if (vpnManager && typeof vpnManager.isConnected !== 'undefined') {
                isConnected = vpnManager.isConnected || false
                isConnecting = vpnManager.isConnecting || false
                isDisconnecting = vpnManager.isDisconnecting || false
            } else {
                isConnected = false
                isConnecting = false
                isDisconnecting = false
            }
        } catch (error) {
            isConnected = false
            isConnecting = false
            isDisconnecting = false
        }
    }

    // Safely update server info
    function updateServerInfo() {
        try {
            if (vpnManager && typeof vpnManager.currentServer !== 'undefined') {
                var server = vpnManager.currentServer
                if (server && typeof server === 'object') {
                    currentServer = server

                    if (typeof server.name !== 'undefined' && server.name !== null) {
                        serverName = String(server.name)
                    } else {
                        serverName = qsTr("No Server Selected")
                    }

                    if (typeof server.countryCode !== 'undefined' && server.countryCode !== null) {
                        serverCountryCode = String(server.countryCode)
                    } else {
                        serverCountryCode = ""
                    }

                    return
                }
            }
        } catch (e) {
            // Ignore
        }

        currentServer = null
        serverName = qsTr("No Server Selected")
        serverCountryCode = ""
    }

    // Update subscription data from authManager
    function updateSubscriptionData() {
        try {
            if (authManager && typeof authManager.subscribeInfo !== 'undefined' && authManager.subscribeInfo) {
                var data = authManager.subscribeInfo
                subscribeData = {
                    d: data.d || 0,
                    u: data.u || 0,
                    transfer_enable: data.transfer_enable || 0,
                    expired_at: data.expired_at || 0,
                    plan_id: data.plan_id || 0
                }

                // Calculate traffic usage
                trafficUsed = (subscribeData.d || 0) + (subscribeData.u || 0)
                trafficTotal = subscribeData.transfer_enable || 0
                trafficProgress = trafficTotal > 0 ? Math.min(trafficUsed / trafficTotal, 1.0) : 0

                // Format expiry date
                if (subscribeData.expired_at && subscribeData.expired_at > 0) {
                    var expDate = new Date(subscribeData.expired_at * 1000)
                    expiryDateText = Qt.formatDate(expDate, "yyyy-MM-dd")
                } else {
                    expiryDateText = "--"
                }

                // Plan name from plan_id
                if (subscribeData.plan_id && subscribeData.plan_id > 0) {
                    planName = qsTr("Plan") + " #" + subscribeData.plan_id
                } else {
                    planName = qsTr("No Plan")
                }

                // Try to resolve plan name from plans list
                try {
                    if (authManager.plans && authManager.plans.length > 0) {
                        for (var i = 0; i < authManager.plans.length; i++) {
                            var plan = authManager.plans[i]
                            if (plan && plan.id === subscribeData.plan_id) {
                                planName = plan.name || planName
                                break
                            }
                        }
                    }
                } catch (e) {
                    // Keep fallback plan name
                }
            } else {
                subscribeData = null
                planName = qsTr("No Plan")
                expiryDateText = "--"
                trafficUsed = 0
                trafficTotal = 0
                trafficProgress = 0
            }
        } catch (e) {
            subscribeData = null
            planName = qsTr("No Plan")
            expiryDateText = "--"
            trafficUsed = 0
            trafficTotal = 0
            trafficProgress = 0
        }
    }

    // Initialization
    Component.onCompleted: {
        try {
            if (typeof authManager !== 'undefined' && authManager && typeof authManager.isAuthenticated !== 'undefined') {
                isAuthenticated = authManager.isAuthenticated || false
            }
        } catch (e) {
            isAuthenticated = false
        }

        initTimer.start()
        loadNotices()
    }

    onVisibleChanged: {
        if (visible) {
            initTimer.start()
        }
    }

    Timer {
        id: initTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            updateConnectionState()
            updateServerInfo()
            updateSubscriptionData()
        }
    }

    // Listen to auth state changes
    Connections {
        target: authManager

        function onAuthenticationChanged() {
            try {
                if (typeof authManager !== 'undefined' && authManager) {
                    isAuthenticated = authManager.isAuthenticated || false
                }
            } catch (e) {
                // Ignore init errors
            }
        }

        function onLoginSucceeded() {
            isAuthenticated = true
        }

        function onLogoutCompleted() {
            isAuthenticated = false
        }

        function onSubscribeInfoChanged() {
            updateSubscriptionData()
        }

        function onSubscribeInfoLoaded(data) {
            updateSubscriptionData()
        }

        function onPlansChanged() {
            // Re-resolve plan name when plans list is updated
            updateSubscriptionData()
        }

        function onCurrentUserChanged() {
            updateSubscriptionData()
        }
    }

    // Listen to VPN state changes
    Connections {
        target: vpnManager

        function onCurrentServerChanged() {
            updateServerInfo()
        }

        function onStateChanged(newState) {
            updateConnectionState()
            updateServerInfo()
        }

        function onConnected() {
            updateConnectionState()
            updateServerInfo()
        }

        function onDisconnected() {
            updateConnectionState()
            updateServerInfo()
        }

        function onConnectFailed(reason) {
            updateConnectionState()
            updateServerInfo()
        }
    }

    // Listen to background data updates
    Connections {
        target: typeof backgroundDataUpdater !== 'undefined' ? backgroundDataUpdater : null
        enabled: typeof backgroundDataUpdater !== 'undefined' && backgroundDataUpdater !== null

        function onSubscriptionInfoUpdated() {
            if (!backgroundDataUpdater.isUpdating) {
                updateSubscriptionData()
            }
        }

        function onDataUpdateCompleted() {
            if (!backgroundDataUpdater.isUpdating) {
                updateSubscriptionData()
            }
        }
    }

    // Listen to notice signals
    Connections {
        target: typeof subscriptionManager !== 'undefined' ? subscriptionManager : null
        enabled: typeof subscriptionManager !== 'undefined' && subscriptionManager !== null

        function onNoticesLoaded(notices) {
            var list = []
            for (var i = 0; i < notices.length; i++) {
                list.push(notices[i])
            }
            noticeList = list
            currentNoticeIndex = 0
        }
    }

    // Background decoration (performance optimized - visible only when connected)
    Item {
        anchors.fill: parent
        opacity: 0.03
        visible: isConnected

        Rectangle {
            width: parent.width * 0.6
            height: parent.width * 0.6
            radius: width / 2
            color: mainColor
            anchors.centerIn: parent
            opacity: 0.15

            SequentialAnimation on scale {
                running: isConnected && simpleConnectionPage.visible
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.2; duration: 8000; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.2; to: 1.0; duration: 8000; easing.type: Easing.InOutQuad }
            }
        }
    }

    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: mainColumn
            width: mainFlickable.width
            spacing: 0

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 20
                Layout.rightMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 20
                Layout.maximumWidth: (mainWindow && mainWindow.isDesktop) ? 500 : 9999
                Layout.topMargin: (mainWindow ? mainWindow.safeAreaTop / 2 : 0)
                spacing: 10

                // 页面标题行 + 模式切换按钮（桌面端由 main.qml 顶部栏显示，隐藏此行）
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: mainWindow ? mainWindow.isMobile : true

                    Label {
                        text: qsTr("Dashboard")
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.colors.textPrimary
                        Layout.fillWidth: true
                    }

                    // 简约/专业模式切换按钮
                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: modeSwitchArea.pressed
                            ? Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.25)
                            : Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.12)

                        Label {
                            anchors.centerIn: parent
                            text: "S"
                            color: Theme.colors.primary
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            id: modeSwitchArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (mainWindow) mainWindow.switchUiMode()
                            }
                        }
                    }
                }

                // ============================================================
                // 0. Notice / Announcement Bar (auto-rotate)
                // ============================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: noticeBarContent.implicitHeight + 20
                    radius: 12
                    color: Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.08)
                    border.color: Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.2)
                    border.width: 1
                    visible: hasNotice
                    clip: true

                    ColumnLayout {
                        id: noticeBarContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Bell icon
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: Theme.colors.primary
                                Layout.alignment: Qt.AlignVCenter

                                Label {
                                    text: "!"
                                    anchors.centerIn: parent
                                    color: "white"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            // Title with fade animation
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: noticeTitleLabel.implicitHeight

                                Label {
                                    id: noticeTitleLabel
                                    anchors.fill: parent
                                    text: currentNoticeTitle
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter

                                    Behavior on text {
                                        SequentialAnimation {
                                            NumberAnimation { target: noticeTitleLabel; property: "opacity"; to: 0; duration: 200 }
                                            PropertyAction { target: noticeTitleLabel; property: "text" }
                                            NumberAnimation { target: noticeTitleLabel; property: "opacity"; to: 1; duration: 200 }
                                        }
                                    }
                                }
                            }

                            // Page indicator (e.g. "1/3")
                            Label {
                                text: noticeList.length > 1 ? (currentNoticeIndex + 1) + "/" + noticeList.length : ""
                                font.pixelSize: 10
                                color: Theme.colors.textTertiary
                                Layout.alignment: Qt.AlignVCenter
                                visible: noticeList.length > 1
                            }

                            // Expand/collapse arrow
                            Label {
                                text: noticeExpanded ? "\u25B2" : "\u25BC"
                                font.pixelSize: 10
                                color: Theme.colors.textTertiary
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        // Expandable content
                        Label {
                            id: noticeContentLabel
                            text: currentNoticeContent
                            font.pixelSize: 12
                            color: Theme.colors.textSecondary
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            visible: noticeExpanded
                            maximumLineCount: 5
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: noticeExpanded = !noticeExpanded
                    }
                }

                // ============================================================
                // 1. Subscription Info Card
                // ============================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: subscriptionColumn.implicitHeight + 32
                    radius: 16
                    color: Theme.colors.surface
                    border.color: Theme.colors.border
                    border.width: 1

                    ColumnLayout {
                        id: subscriptionColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 10

                        // Plan name and expiry row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: planName
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: qsTr("Expires: %1").arg(expiryDateText)
                                    font.pixelSize: 12
                                    color: Theme.colors.textTertiary
                                }
                            }

                            // Renew button
                            Rectangle {
                                Layout.preferredWidth: renewLabel.implicitWidth + 24
                                Layout.preferredHeight: 32
                                Layout.minimumHeight: 32
                                radius: 16
                                color: Theme.colors.primary

                                Label {
                                    id: renewLabel
                                    text: qsTr("Renew")
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "white"
                                    anchors.centerIn: parent
                                }

                                scale: renewArea.pressed ? 0.95 : 1.0
                                Behavior on scale {
                                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                                }

                                MouseArea {
                                    id: renewArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (mainWindow) {
                                            mainWindow.navigateTo("store", mainWindow.getPagePath("store"))
                                        }
                                    }
                                }
                            }
                        }

                        // Traffic usage section
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Label {
                                    text: qsTr("Traffic Used")
                                    font.pixelSize: 12
                                    color: Theme.colors.textSecondary
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: FormatUtils.formatBytes(trafficUsed) + " / " + FormatUtils.formatBytes(trafficTotal)
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                }
                            }

                            // Traffic progress bar
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 8
                                radius: 4
                                color: Theme.colors.surfaceElevated

                                Rectangle {
                                    width: parent.width * trafficProgress
                                    height: parent.height
                                    radius: 4
                                    color: {
                                        if (trafficProgress > 0.9) return Theme.colors.error
                                        if (trafficProgress > 0.7) return Theme.colors.warning
                                        return Theme.colors.primary
                                    }

                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }

                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                            }

                            Label {
                                text: qsTr("%1% used").arg(Math.round(trafficProgress * 100))
                                font.pixelSize: 11
                                color: {
                                    if (trafficProgress > 0.9) return Theme.colors.error
                                    if (trafficProgress > 0.7) return Theme.colors.warning
                                    return Theme.colors.textTertiary
                                }
                            }
                        }
                    }
                }

                // ============================================================
                // 2. Connection Button (large circular)
                // ============================================================
                Item { Layout.preferredHeight: 8 }

                Item {
                    readonly property real btnSize: Math.min(simpleConnectionPage.width * 0.4, 180)
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: btnSize
                    Layout.preferredHeight: btnSize

                    // Outer ring animation
                    Rectangle {
                        id: outerRing
                        anchors.centerIn: parent
                        width: isConnected ? parent.btnSize * 1.09 : parent.btnSize
                        height: isConnected ? parent.btnSize * 1.09 : parent.btnSize
                        radius: width / 2
                        color: "transparent"
                        border.color: mainColor
                        border.width: 2
                        opacity: isConnecting ? 0.6 : 0.3

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                        Behavior on height {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 300 }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 300 }
                        }

                        RotationAnimation on rotation {
                            running: isConnecting && simpleConnectionPage.visible
                            from: 0; to: 360; duration: 2000
                            loops: Animation.Infinite
                        }

                        SequentialAnimation on scale {
                            running: isConnected && !isConnecting && simpleConnectionPage.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 1.08; duration: 1500; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.08; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Middle glow circle
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.btnSize * 0.87
                        height: parent.btnSize * 0.87
                        radius: width / 2
                        color: mainColor
                        opacity: 0.1

                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }
                    }

                    // Main button body
                    Rectangle {
                        id: connectButton
                        anchors.centerIn: parent
                        width: parent.btnSize * 0.72
                        height: parent.btnSize * 0.72
                        radius: width / 2

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: mainColor }
                            GradientStop { position: 1.0; color: Qt.darker(mainColor, 1.2) }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: width / 2
                            color: mainColor
                            opacity: 0.2
                            z: -1
                        }

                        scale: connectBtnMouseArea.pressed ? 0.95 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                        }

                        SequentialAnimation on opacity {
                            running: isConnecting && simpleConnectionPage.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.7; duration: 800; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.7; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                        }

                        Image {
                            source: isConnected ? "qrc:/images/connect.png" : "qrc:/images/disconnect.png"
                            width: connectButton.width * 0.37
                            height: connectButton.width * 0.37
                            anchors.centerIn: parent
                            smooth: true
                            antialiasing: true
                        }

                        MouseArea {
                            id: connectBtnMouseArea
                            anchors.fill: parent
                            enabled: isAuthenticated && !isConnecting && !isDisconnecting && (!subscriptionManager || !subscriptionManager.isUpdating)
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                            onClicked: {
                                if (!vpnManager) return

                                if (!isConnected) {
                                    var serverToConnect = getCurrentServer()
                                    if (!serverToConnect) {
                                        serverSelectDialog.open()
                                        return
                                    }
                                    if (!serverToConnect.id) return

                                    try {
                                        vpnManager.connecting(serverToConnect)
                                    } catch (e) {
                                        // Ignore connection errors
                                    }
                                } else {
                                    try {
                                        vpnManager.disconnect()
                                    } catch (e) {
                                        // Ignore disconnect errors
                                    }
                                }
                            }
                        }
                    }
                }

                // Connection state text
                Label {
                    text: connectButtonText
                    font.pixelSize: 18
                    font.bold: true
                    color: mainColor
                    Layout.alignment: Qt.AlignHCenter

                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }

                // ============================================================
                // 2.5 Routing Mode Toggle
                // ============================================================
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(simpleConnectionPage.width * 0.5, 200)
                    Layout.preferredHeight: 36
                    radius: 18
                    color: Theme.colors.surface
                    border.color: Theme.colors.border
                    border.width: 1

                    property bool isGlobalMode: configManager ? (configManager.routingMode === 0) : false

                    Row {
                        anchors.fill: parent
                        anchors.margins: 3

                        Rectangle {
                            width: (parent.width) / 2
                            height: parent.height
                            radius: 15
                            color: parent.parent.isGlobalMode ? Theme.colors.primary : "transparent"

                            Label {
                                text: qsTr("Global")
                                anchors.centerIn: parent
                                font.pixelSize: 13
                                font.bold: parent.parent.parent.isGlobalMode
                                color: parent.parent.parent.isGlobalMode ? "white" : Theme.colors.textSecondary
                            }

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (configManager) configManager.routingMode = 0
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width) / 2
                            height: parent.height
                            radius: 15
                            color: !parent.parent.isGlobalMode ? Theme.colors.primary : "transparent"

                            Label {
                                text: qsTr("Smart")
                                anchors.centerIn: parent
                                font.pixelSize: 13
                                font.bold: !parent.parent.parent.isGlobalMode
                                color: !parent.parent.parent.isGlobalMode ? "white" : Theme.colors.textSecondary
                            }

                            Behavior on color {
                                ColorAnimation { duration: 200 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (configManager) configManager.routingMode = 1
                                }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 4 }

                // ============================================================
                // 3. Server Selector Card
                // ============================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 16
                    color: Theme.colors.surface
                    border.color: Theme.colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        FlagIcon {
                            size: 40
                            countryCode: serverCountryCode
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Label {
                                text: serverName
                                font.pixelSize: 15
                                font.bold: true
                                color: Theme.colors.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label {
                                text: currentServer ? qsTr("Tap to change server") : qsTr("Tap to select a server")
                                font.pixelSize: 12
                                color: Theme.colors.textTertiary
                            }
                        }

                        Label {
                            text: ">"
                            font.pixelSize: 20
                            color: Theme.colors.textDisabled
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: serverSelectDialog.open()
                    }
                }

                // 底部预留浮动导航栏 + 安全区域高度
                Item { Layout.preferredHeight: 132 + (mainWindow ? mainWindow.safeAreaBottom : 0) }
            }
        }
    }
}
