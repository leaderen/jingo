import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Rectangle {
    id: simpleProfilePage
    readonly property var mainWindow: ApplicationWindow.window
    color: Theme.colors.pageBackground

    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    // User info properties - avoid accessing authManager during init
    property bool isPremium: false
    property string userEmail: qsTr("Users")
    property string userAccountId: "N/A"
    property string userExpiryDate: "--"

    // Subscription data
    property var subscribeData: null

    // Email masking toggle
    property bool emailMasked: true

    // Reactive subscription computed properties
    readonly property real usedTrafficBytes: subscribeData ? ((subscribeData.u || 0) + (subscribeData.d || 0)) : 0
    readonly property real totalTrafficBytes: subscribeData ? (subscribeData.transfer_enable || 0) : 0
    readonly property int remainingDays: {
        if (!subscribeData || !subscribeData.expired_at) return 0
        var now = Math.floor(Date.now() / 1000)
        var diff = subscribeData.expired_at - now
        return diff > 0 ? Math.ceil(diff / 86400) : 0
    }
    readonly property int usedPercent: totalTrafficBytes > 0 ? Math.round(usedTrafficBytes / totalTrafficBytes * 100) : 0

    // Email masking function
    function maskEmail(email) {
        if (!email || email.indexOf("@") === -1) return email

        var parts = email.split("@")
        var localPart = parts[0]
        var domainPart = parts[1]

        var maskedLocal = localPart
        if (localPart.length > 2) {
            maskedLocal = localPart.substring(0, localPart.length - 2) + "**"
        } else {
            maskedLocal = "**"
        }

        var maskedDomain = domainPart
        var lastDotIndex = domainPart.lastIndexOf(".")
        if (lastDotIndex !== -1) {
            maskedDomain = domainPart.substring(0, lastDotIndex + 1) + "**"
        }

        return maskedLocal + "@" + maskedDomain
    }

    // Safely update user info from authManager
    function updateUserInfo() {
        try {
            if (authManager && typeof authManager.currentUser !== 'undefined' && authManager.currentUser) {
                var user = authManager.currentUser

                if (typeof user.email !== 'undefined' && user.email !== null) {
                    userEmail = String(user.email)
                } else {
                    userEmail = qsTr("Users")
                }

                if (typeof user.isPremium !== 'undefined' && user.isPremium !== null) {
                    isPremium = user.isPremium
                } else {
                    isPremium = false
                }

                if (typeof user.id !== 'undefined' && user.id !== null) {
                    userAccountId = String(user.id).substring(0, 8)
                } else {
                    userAccountId = "N/A"
                }

                if (typeof user.formatExpiryDate === 'function') {
                    userExpiryDate = user.formatExpiryDate()
                } else {
                    userExpiryDate = "--"
                }
            } else {
                userEmail = qsTr("Users")
                isPremium = false
                userAccountId = "N/A"
                userExpiryDate = "--"
            }

            // Update subscription data
            if (authManager && authManager.subscribeInfo && typeof authManager.subscribeInfo !== 'undefined') {
                var data = authManager.subscribeInfo
                subscribeData = {
                    d: data.d || 0,
                    u: data.u || 0,
                    transfer_enable: data.transfer_enable || 0,
                    expired_at: data.expired_at || 0,
                    plan_id: data.plan_id || 0
                }
            } else {
                subscribeData = null
            }
        } catch (e) {
            userEmail = qsTr("Users")
            isPremium = false
            userAccountId = "N/A"
            userExpiryDate = "--"
            subscribeData = null
        }
    }

    // Format bytes to human readable string
    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        if (bytes < 0) return qsTr("Unlimited")

        var k = 1024
        var sizes = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))
        var value = (bytes / Math.pow(k, i)).toFixed(2)

        return value + " " + sizes[i]
    }

    // Get remaining traffic
    function getRemainingTraffic() {
        if (!subscribeData) return 0

        var total = subscribeData.transfer_enable || 0
        var upload = subscribeData.u || 0
        var download = subscribeData.d || 0
        var used = upload + download

        return Math.max(0, total - used)
    }

    // Get traffic usage percentage (remaining)
    function getTrafficPercentage() {
        if (!subscribeData || !subscribeData.transfer_enable) return 0

        var total = subscribeData.transfer_enable
        var remaining = getRemainingTraffic()

        return Math.round((remaining / total) * 100)
    }

    // Initialize
    Component.onCompleted: {
        updateUserInfo()
    }

    // Listen for auth state changes
    Connections {
        target: authManager

        function onCurrentUserChanged() {
            updateUserInfo()
        }

        function onAuthenticationChanged() {
            updateUserInfo()
        }

        function onSubscribeInfoChanged() {
            if (authManager && authManager.subscribeInfo) {
                var data = authManager.subscribeInfo
                subscribeData = {
                    d: data.d || 0,
                    u: data.u || 0,
                    transfer_enable: data.transfer_enable || 0,
                    expired_at: data.expired_at || 0,
                    plan_id: data.plan_id || 0
                }
            }
        }
    }

    // Listen for background data updates
    Connections {
        target: typeof backgroundDataUpdater !== 'undefined' ? backgroundDataUpdater : null
        enabled: typeof backgroundDataUpdater !== 'undefined' && backgroundDataUpdater !== null

        function onUserInfoUpdated() {
            if (!backgroundDataUpdater.isUpdating) {
                updateUserInfo()
            }
        }

        function onSubscriptionInfoUpdated() {
            if (!backgroundDataUpdater.isUpdating) {
                updateUserInfo()
            }
        }

        function onDataUpdateCompleted() {
            if (!backgroundDataUpdater.isUpdating) {
                updateUserInfo()
            }
        }
    }

    Flickable {
        id: profileFlickable
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 0
        contentWidth: width
        contentHeight: profileMainColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: profileMainColumn
            width: profileFlickable.width
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: (mainWindow && mainWindow.isDesktop) ? 500 : profileFlickable.width
                Layout.topMargin: (mainWindow ? mainWindow.safeAreaTop / 2 : 0)
                spacing: 16

                // Page title row + mode switch button (desktop: hidden, shown in main.qml top bar)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: mainWindow ? mainWindow.isMobile : true

                    Label {
                        text: qsTr("Profile")
                        font.pixelSize: 20
                        font.bold: true
                        color: Theme.colors.textPrimary
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: profileModeArea.pressed
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
                            id: profileModeArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (mainWindow) mainWindow.switchUiMode() }
                        }
                    }
                }

                // ========================================
                // Section 1: User Avatar + Email + Account ID
                // ========================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: userInfoRow.implicitHeight + 40
                    radius: Theme.radius.md
                    color: Theme.colors.cardBackground

                    RowLayout {
                        id: userInfoRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 14

                        // Avatar circle with first letter of email
                        Rectangle {
                            Layout.preferredWidth: 56
                            Layout.preferredHeight: 56
                            radius: 28
                            color: Theme.colors.surfaceElevated

                            Label {
                                text: userEmail.charAt(0).toUpperCase()
                                font.pixelSize: 26
                                font.bold: true
                                color: Theme.colors.primary
                                anchors.centerIn: parent
                            }
                        }

                        // Email + Account ID
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                spacing: 8

                                Label {
                                    text: emailMasked ? maskEmail(userEmail) : userEmail
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: Theme.colors.textPrimary
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                // Eye icon - toggle email visibility
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    color: "transparent"

                                    Image {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: emailMasked ? "qrc:/icons/eye-closed.svg" : "qrc:/icons/eye-open.svg"
                                        sourceSize: Qt.size(20, 20)
                                        opacity: 0.7
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            emailMasked = !emailMasked
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                spacing: 8

                                Label {
                                    text: qsTr("Account ID: ") + userAccountId
                                    font.pixelSize: 11
                                    color: isDarkMode ? "#999999" : "#666666"
                                }

                                LevelBadge {
                                    level: isPremium ? 2 : 0
                                    compact: true
                                }
                            }
                        }
                    }
                }

                // ========================================
                // Section 2: Subscription Status Overview
                // ========================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: subsContentCol.implicitHeight + 32
                    radius: Theme.radius.md
                    color: Theme.colors.cardBackground

                    ColumnLayout {
                        id: subsContentCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            text: qsTr("Subscription Overview")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.colors.textPrimary
                        }

                        // 2x2 grid: Status | Expiry | Used Traffic | Remaining
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10

                            // Subscription status
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 10
                                color: Theme.colors.surfaceElevated

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Label {
                                        text: isPremium ? qsTr("Active") : qsTr("Inactive")
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: isPremium ? Theme.colors.success : Theme.colors.error
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label {
                                        text: qsTr("Status")
                                        font.pixelSize: 10
                                        color: isDarkMode ? "#999999" : "#888888"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            // Expiry date
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 10
                                color: Theme.colors.surfaceElevated

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Label {
                                        text: isPremium ? userExpiryDate : "--"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: Theme.colors.textPrimary
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label {
                                        text: qsTr("Expiry Date")
                                        font.pixelSize: 10
                                        color: isDarkMode ? "#999999" : "#888888"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            // Used traffic
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 10
                                color: Theme.colors.surfaceElevated

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Label {
                                        text: formatBytes(usedTrafficBytes)
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: Theme.colors.textPrimary
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label {
                                        text: qsTr("Used Traffic")
                                        font.pixelSize: 10
                                        color: isDarkMode ? "#999999" : "#888888"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            // Remaining time
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 10
                                color: Theme.colors.surfaceElevated

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Label {
                                        text: {
                                            if (!isPremium) return "--"
                                            if (remainingDays <= 0) return qsTr("Expired")
                                            return remainingDays + qsTr(" days")
                                        }
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: {
                                            if (!isPremium || remainingDays <= 0) return Theme.colors.error
                                            if (remainingDays <= 7) return Theme.colors.warning
                                            return Theme.colors.textPrimary
                                        }
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                    Label {
                                        text: qsTr("Remaining")
                                        font.pixelSize: 10
                                        color: isDarkMode ? "#999999" : "#888888"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }

                        // Traffic progress bar
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: totalTrafficBytes > 0

                            RowLayout {
                                Layout.fillWidth: true

                                Label {
                                    text: qsTr("Traffic")
                                    font.pixelSize: 12
                                    color: Theme.colors.textSecondary
                                }

                                Item { Layout.fillWidth: true }

                                Label {
                                    text: formatBytes(usedTrafficBytes) + " / " + formatBytes(totalTrafficBytes)
                                    font.pixelSize: 12
                                    color: Theme.colors.textPrimary
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Theme.colors.divider

                                Rectangle {
                                    width: parent.width * (usedPercent / 100)
                                    height: parent.height
                                    radius: 3
                                    color: {
                                        if (usedPercent > 90) return Theme.colors.error
                                        if (usedPercent > 70) return Theme.colors.warning
                                        return Theme.colors.primary
                                    }

                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }
                    }
                }

                // ========================================
                // Section 3: Action Buttons
                // ========================================
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: actionsCol.implicitHeight + 32
                    radius: Theme.radius.md
                    color: Theme.colors.cardBackground

                    ColumnLayout {
                        id: actionsCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 10

                        Label {
                            text: qsTr("Account Actions")
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.colors.textPrimary
                        }

                        // Order Management
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            radius: 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "order"
                                    size: 20
                                    color: Theme.colors.primary
                                }

                                Label {
                                    text: qsTr("Order Management")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: orderListDialog.open()
                            }
                        }

                        // Ticket System
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            radius: 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "edit"
                                    size: 20
                                    color: Theme.colors.info
                                }

                                Label {
                                    text: qsTr("Ticket System")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ticketListDialog.open()
                            }
                        }

                        // Help Center
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            radius: 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "help"
                                    size: 20
                                    color: Theme.colors.success
                                }

                                Label {
                                    text: qsTr("Help Center")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: helpCenterDialog.open()
                            }
                        }

                        // Change Password
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            radius: 12
                            color: Theme.colors.surfaceElevated
                            border.color: Theme.colors.border
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                IconSymbol {
                                    icon: "key"
                                    size: 20
                                    color: "#FF9800"
                                }

                                Label {
                                    text: qsTr("Change Password")
                                    font.pixelSize: 14
                                    color: Theme.colors.textPrimary
                                    Layout.fillWidth: true
                                }

                                Label {
                                    text: ">"
                                    font.pixelSize: 20
                                    color: isDarkMode ? "#666666" : "#CCCCCC"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: changePasswordDialog.open()
                            }
                        }
                    }
                }

                // ========================================
                // Section 4: Logout Button
                // ========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.minimumHeight: Theme.size.touchTarget
                    Layout.topMargin: 10
                    radius: 12
                    color: Theme.colors.surfaceElevated
                    border.color: Theme.colors.error
                    border.width: 1

                    Label {
                        text: qsTr("Logout")
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.colors.error
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (authManager) {
                                authManager.logout()
                            }
                        }
                    }
                }

                // Bottom spacing for floating navigation bar + safe area
                Item { Layout.preferredHeight: 132 + (mainWindow ? mainWindow.safeAreaBottom : 0) }
            }
        }
    }

    // ========================================
    // Dialogs
    // ========================================

    OrderListDialog {
        id: orderListDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
    }

    TicketListDialog {
        id: ticketListDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        ticketMgr: ticketManager
    }

    HelpCenterDialog {
        id: helpCenterDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        sysConfigMgr: systemConfigManager
    }

    ChangePasswordDialog {
        id: changePasswordDialog
        parent: Overlay.overlay
        anchors.centerIn: parent

        onAccepted: {
            successToast.text = qsTr("Password changed successfully")
            successToast.show()
        }
    }

    // ========================================
    // Success Toast
    // ========================================
    Rectangle {
        id: successToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: Math.min(parent.width * 0.8, 400)
        height: 60
        radius: Theme.radius.lg
        color: Theme.colors.success
        visible: opacity > 0
        opacity: 0

        property string text: ""

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.md
            spacing: Theme.spacing.sm

            Label {
                text: qsTr("OK")
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }

            Label {
                text: successToast.text
                font.pixelSize: Theme.typography.body1
                color: "white"
                Layout.fillWidth: true
            }
        }

        function show() {
            opacity = 1
            hideTimer.restart()
        }

        Timer {
            id: hideTimer
            interval: 3000
            onTriggered: successToast.opacity = 0
        }
    }
}
