// qml/main.qml (完美优化版 - 无 GraphicalEffects 依赖)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Window 2.15
import JinGo 1.0

ApplicationWindow {
    id: mainWindow

    // 暴露 stackView 给子页面使用
    property alias stackView: stackView

    visible: true

    // 移动端全屏显示标志
    flags: (Qt.platform.os === "android" || Qt.platform.os === "ios") ?
           Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint : Qt.Window

    // 移动端使用屏幕尺寸，桌面端使用固定尺寸
    width: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.width : 900
    height: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.height : 720
    minimumWidth: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.width : 880
    minimumHeight: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? Screen.height : 600
    title: "JinGo - " + qsTr("Secure. Fast. Borderless.")

    // 全局字体设置（针对移动端优化）
    font.family: Theme.typography.fontFamily
    font.weight: isMobile ? Theme.typography.mobileWeightNormal : Theme.typography.weightRegular

    // RTL布局镜像支持（根据应用布局方向自动启用）
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    // 响应式断点
    readonly property bool isMobile: Qt.platform.os === "android" ||
                                     Qt.platform.os === "ios" ||
                                     width < 768
    readonly property bool isTablet: width >= 768 && width < 1024
    readonly property bool isDesktop: width >= 1024

    // 安全区域 - 系统状态栏/导航栏高度（逻辑像素 dp）
    readonly property real safeAreaTop: {
        if (Qt.platform.os === "ios") return 47
        if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined' && androidStatusBarManager) {
            var h = androidStatusBarManager.statusBarHeight || 0
            return h
        }
        return 0
    }
    readonly property real safeAreaBottom: {
        if (Qt.platform.os === "ios") return 34
        if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined' && androidStatusBarManager) {
            var h = androidStatusBarManager.navigationBarHeight || 0
            return h
        }
        return 0
    }

    // 侧边栏状态
    property bool sidebarCollapsed: isMobile
    readonly property int sidebarWidth: isMobile ? 0 : 90

    // 主题系统 - 从 settingsViewModel 读取
    property bool isDarkMode: settingsViewModel ? settingsViewModel.isDarkMode : false

    // Android状态栏和导航栏图标颜色 - 始终使用深色图标
    onIsDarkModeChanged: {
        // 同步到 Theme 单例
        Theme.isDarkMode = isDarkMode

        if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined') {
            // 无论什么主题，都使用深色图标（黑色）
            // false = 深色图标，适合浅色背景
            androidStatusBarManager.setSystemBarIconsColor(false, false)
        }
    }

    // 监听主题变化
    Connections {
        target: configManager
        function onThemeChanged() {
            if (configManager && typeof configManager.theme !== 'undefined') {
                Theme.currentTheme = Theme.themes[configManager.theme] || Theme.jingoTheme
            }
        }
    }

    // UI 模式
    property bool isSimpleMode: configManager ? (configManager.uiMode === "simple") : true

    // 监听 UI 模式变化
    Connections {
        target: configManager
        function onUiModeChanged() {
            isSimpleMode = (configManager.uiMode === "simple")
            if (isAuthenticated) {
                navigateTo("connection", getPagePath("connection"))
            }
        }
    }

    // 应用状态
    property bool isAuthenticated: false  // 修改为普通属性，避免在初始化时访问authManager
    property bool isConnected: false  // 使用本地属性，通过信号手动更新
    property string currentPage: "loading"
    property bool hasShownTrayHint: false

    // 更新连接状态的函数
    function updateVPNConnectionState() {
        try {
            if (vpnManager && typeof vpnManager.isConnected !== 'undefined') {
                isConnected = vpnManager.isConnected || false
            } else {
                isConnected = false
            }
        } catch (error) {
            isConnected = false
        }
    }

    // 背景色 - 使用主题配置
    color: Theme.colors.pageBackground

    // 页面切换函数
    function navigateTo(page, qmlFile) {
        currentPage = page
        stackView.replace(qmlFile)
    }

    // 推送新页面（用于子页面导航，如应用选择页面）
    function pushPage(qmlFile) {
        stackView.push(qmlFile)
    }

    // 弹出页面
    function popPage() {
        if (stackView.depth > 1) {
            stackView.pop()
        }
    }

    // 页面路径解析函数 - 根据当前 UI 模式返回正确的页面路径
    function getPagePath(pageName) {
        if (pageName === "login") return "pages/LoginPage.qml"
        if (isSimpleMode) {
            switch (pageName) {
                case "connection": return "pages/simple/SimpleConnectionPage.qml"
                case "store":      return "pages/simple/SimpleStorePage.qml"
                case "profile":    return "pages/simple/SimpleProfilePage.qml"
                default:           return "pages/simple/SimpleConnectionPage.qml"
            }
        } else {
            switch (pageName) {
                case "connection": return "pages/ConnectionPage.qml"
                case "servers":    return "pages/ServerListPage.qml"
                case "store":      return "pages/StorePage.qml"
                case "settings":   return "pages/SettingsPage.qml"
                case "profile":    return "pages/ProfilePage.qml"
                default:           return "pages/ConnectionPage.qml"
            }
        }
    }

    // 切换 UI 模式
    function switchUiMode() {
        if (configManager) {
            configManager.uiMode = isSimpleMode ? "professional" : "simple"
        }
    }

    // 显示 Toast 提示
    function showToast(message) {
        toastLabel.text = message
        toastPopup.open()
    }

    // 监听宽度变化
    onWidthChanged: {
        if (isMobile) {
            sidebarCollapsed = true
        }
    }

    // 系统托盘连接
    Connections {
        target: systemTrayManager

        function onShowWindowRequested() {
            mainWindow.showNormal()
            mainWindow.raise()
            mainWindow.requestActivate()
        }

        function onQuickConnectRequested() {
            if (vpnManager && !isConnected) {
                vpnManager.connecting(vpnManager.currentServer)
            }
        }

        function onDisconnectRequested() {
            if (vpnManager) {
                vpnManager.disconnect()
            }
        }

        function onSettingsRequested() {
            mainWindow.showNormal()
            mainWindow.raise()
            mainWindow.requestActivate()
            if (isSimpleMode) {
                navigateTo("profile", getPagePath("profile"))
            } else {
                navigateTo("settings", getPagePath("settings"))
            }
        }

        function onQuitRequested() {
            Qt.quit()
        }
    }

    // macOS: 点击 Dock 图标恢复窗口
    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.platform.os === "osx" && Qt.application.state === Qt.ApplicationActive) {
                if (mainWindow.visibility === Window.Minimized || mainWindow.visibility === Window.Hidden || !mainWindow.visible) {
                    mainWindow.showNormal()
                    mainWindow.raise()
                    mainWindow.requestActivate()
                }
            }
        }
    }

    // VPN 状态变化通知
    Connections {
        target: vpnManager

        function onConnected() {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("Connected"), qsTr("VPN ConnectSuccess"))
            }
        }
        function onDisconnected() {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("Disconnected"), qsTr("VPN Disconnected"))
            }
        }
        function onConnectFailed(reason) {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("ConnectFailed"), reason)
            }
        }
        function onErrorOccurred(error) {
            if (systemTrayManager) {
                systemTrayManager.showMessage(qsTr("Error"), error)
            }
        }
    }

    // 认证状态变化
    Connections {
        target: authManager

        function onAuthenticationChanged() {
            // 安全地更新isAuthenticated状态
            try {
                if (authManager && typeof authManager.isAuthenticated !== 'undefined') {
                    isAuthenticated = authManager.isAuthenticated || false
                }
            } catch (e) {
                isAuthenticated = false
            }

            // 根据状态导航到相应页面
            if (!isAuthenticated) {
                // 用户登出，重置数据加载标记
                hasLoadedInitialData = false
                navigateTo("login", "pages/LoginPage.qml")
            } else {
                // 用户登录，导航到首页
                navigateTo("connection", getPagePath("connection"))
                // 延迟加载数据，确保页面已准备好
                Qt.callLater(loadInitialData)
            }
        }
    }

    // 菜单栏
    menuBar: MenuBar {
        visible: isDesktop

        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("Preferences")
                onTriggered: {
                    if (isSimpleMode) {
                        navigateTo("profile", getPagePath("profile"))
                    } else {
                        navigateTo("settings", getPagePath("settings"))
                    }
                }
            }
            MenuSeparator {}
            MenuItem { 
                text: qsTr("Quit")
                onTriggered: Qt.quit() 
            }
        }

        Menu {
            title: qsTr("Connect")
            MenuItem {
                text: isConnected ? qsTr("DisconnectConnect") : qsTr("Connect")
                enabled: isAuthenticated
                onTriggered: {
                    if (vpnManager) {
                        if (isConnected) { 
                            vpnManager.disconnect() 
                        } else { 
                            vpnManager.connecting(vpnManager.currentServer) 
                        }
                    }
                }
            }
            MenuItem {
                text: qsTr("Select Server")
                visible: !isSimpleMode
                onTriggered: navigateTo("servers", getPagePath("servers"))
            }
        }

        Menu {
            title: qsTr("Help")
            MenuItem { 
                text: qsTr("Documentation")
                onTriggered: Qt.openUrlExternally(bundleConfig.docsUrl || "https://docs.jingo.com") 
            }
            MenuItem { 
                text: qsTr("Report Issue")
                onTriggered: Qt.openUrlExternally(bundleConfig.issuesUrl || "https://github.com/jingo/jingo-vpn/issues") 
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("About JinGo")
                onTriggered: aboutDialog.item && aboutDialog.item.open()
            }
        }
    }

    // 全局对话框 - 使用正确的路径加载（根据CMakeLists.txt，components映射到JinGo）
    Loader {
        id: aboutDialog
        source: "qrc:/qml/JinGo/AboutDialog.qml"
    }

    // 主布局
    Item {
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ========================================================================
            // 左侧导航栏（桌面端）
            // ========================================================================
            Rectangle {
                id: sidebar
                Layout.preferredWidth: sidebarWidth
                Layout.fillHeight: true
                color: Theme.colors.navButtonBackground
                visible: !isMobile && currentPage !== "login"

                // 右边框（替代阴影）
                Rectangle {
                    anchors.right: parent.right
                    width: 0
                    height: parent.height
                    color: Qt.darker(Theme.colors.navButtonBackground, 1.05)
                }

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutCubic }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Logo/标题区域
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: "transparent"

                        // Logo 居中
                        Rectangle {
                            anchors.centerIn: parent
                            width: 56
                            height: 56
                            radius: 14
                            color: "transparent"

                            Image {
                                source: "qrc:/images/logo.png"
                                anchors.centerIn: parent
                                width: parent.width * 0.9
                                height: parent.height * 0.9
                                smooth: true
                                antialiasing: true
                            }
                        }
                    }

                    // 分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        height: 0
                        color: Qt.darker(Theme.colors.navButtonBackground, 1.05)
                    }

                    // 导航按钮组
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 8
                        clip: true
                        
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: sidebar.width
                            spacing: 2

                            // 连接页面
                            SidebarDelegate {
                                pageName: "connection"
                                labelText: isSimpleMode ? qsTr("Dashboard") : qsTr("Connect")
                                iconSource: mainWindow.isConnected ?
                                    "qrc:/icons/connected.png" : "qrc:/icons/disconnected.png"
                                collapsed: true
                                visible: isAuthenticated
                                isCurrentPage: mainWindow.currentPage === "connection"
                                enabled: mainWindow.isAuthenticated

                                onClicked: navigateTo("connection", getPagePath("connection"))
                            }

                            // 服务器列表（简约模式隐藏）
                            SidebarDelegate {
                                pageName: "servers"
                                labelText: qsTr("Servers")
                                iconSource: "qrc:/icons/services.png"
                                collapsed: true
                                visible: isAuthenticated && !isSimpleMode
                                isCurrentPage: mainWindow.currentPage === "servers"

                                onClicked: navigateTo("servers", getPagePath("servers"))
                            }

                            // 订阅
                            SidebarDelegate {
                                pageName: "store"
                                labelText: qsTr("Subscription")
                                iconSource: "qrc:/icons/store.png"
                                collapsed: true
                                visible: isAuthenticated
                                isCurrentPage: mainWindow.currentPage === "store"

                                onClicked: navigateTo("store", getPagePath("store"))
                            }

                            // 设置（简约模式隐藏）
                            SidebarDelegate {
                                pageName: "settings"
                                labelText: qsTr("Settings")
                                iconSource: "qrc:/icons/settings.png"
                                collapsed: true
                                visible: isAuthenticated && !isSimpleMode
                                isCurrentPage: mainWindow.currentPage === "settings"

                                onClicked: navigateTo("settings", getPagePath("settings"))
                            }

                            // 填充空间
                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    // 分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        height: 0
                        color: Qt.darker(Theme.colors.navButtonBackground, 1.05)
                    }

                    // 模式切换按钮
                    ItemDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        visible: isAuthenticated

                        background: Rectangle {
                            color: parent.hovered ?
                                (isDarkMode ? "#252525" : "#F8F8F8") : "transparent"
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            Rectangle {
                                anchors.centerIn: parent
                                width: 44
                                height: 44
                                radius: 22
                                color: Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.15)

                                Label {
                                    text: isSimpleMode ? "S" : "P"
                                    anchors.centerIn: parent
                                    color: Theme.colors.primary
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                        }

                        ToolTip.visible: hovered
                        ToolTip.text: isSimpleMode ? qsTr("Switch to Professional Mode") : qsTr("Switch to Simple Mode")
                        ToolTip.delay: 500

                        onClicked: switchUiMode()
                    }

                    // 底部用户信息区域
                    ItemDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70

                        background: Rectangle {
                            color: parent.hovered ? 
                                (isDarkMode ? "#252525" : "#F8F8F8") : "transparent"
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            // 用户头像居中
                            Rectangle {
                                anchors.centerIn: parent
                                width: 44
                                height: 44
                                radius: 22

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#667EEA" }
                                    GradientStop { position: 1.0; color: "#764BA2" }
                                }

                                Label {
                                    text: isAuthenticated ?
                                        (authManager.user && authManager.user.name ?
                                            authManager.user.name.charAt(0).toUpperCase() : "U") : "?"
                                    anchors.centerIn: parent
                                    color: "white"
                                    font.pixelSize: 20
                                    font.bold: true
                                }

                                // 在线状态指示器
                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: isConnected ? "#4CAF50" : "#999999"
                                    border.color: "white"
                                    border.width: 2
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                            }
                        }

                        onClicked: {
                            if (authManager && !authManager.isAuthenticated) {
                                navigateTo("login", "pages/LoginPage.qml")
                            } else {
                                navigateTo("profile", getPagePath("profile"))
                            }
                        }
                    }
                }
            }

            // ========================================================================
            // 右侧主内容区域
            // ========================================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.colors.pageBackground

                // 状态栏区域背景（与导航按钮块背景色一致）
                Rectangle {
                    width: parent.width
                    height: mainWindow.safeAreaTop > 0 ? mainWindow.safeAreaTop : 0
                    y: -(mainWindow.safeAreaTop > 0 ? mainWindow.safeAreaTop : 0)
                    color: Theme.colors.navButtonBackground
                    visible: (Qt.platform.os === "android" || Qt.platform.os === "ios") && currentPage !== "login" && mainWindow.safeAreaTop > 0
                    z: 100
                }

                // 底部导航栏区域背景（与导航按钮块背景色一致）
                Rectangle {
                    width: parent.width
                    height: mainWindow.safeAreaBottom > 0 ? mainWindow.safeAreaBottom : 0
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -(mainWindow.safeAreaBottom > 0 ? mainWindow.safeAreaBottom : 0)
                    color: Theme.colors.navButtonBackground
                    visible: (Qt.platform.os === "android" || Qt.platform.os === "ios") && mainWindow.safeAreaBottom > 0
                    z: 100
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // 顶部栏（简约模式移动端隐藏，让页面自己管理顶部空间）
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: isMobile ? 60 : 70
                        color: Theme.colors.navButtonBackground
                        visible: currentPage !== "login" && !(isMobile && isSimpleMode)

                        Component.onCompleted: {
                        }

                        Connections {
                            target: Theme
                            function onCurrentThemeChanged() {
                            }
                        }

                        // 底部边框（替代阴影）
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.colors.divider
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: isMobile ? 60 : 70
                            anchors.leftMargin: isMobile ? 16 : 20
                            anchors.rightMargin: isMobile ? 16 : 20
                            spacing: 15

                            // 页面标题（左对齐）
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft
                                spacing: 2

                                Label {
                                    Layout.alignment: Qt.AlignLeft
                                    text: {
                                        if (currentPage === "connection") return isSimpleMode ? qsTr("Dashboard") : qsTr("Connection")
                                        if (currentPage === "servers") return qsTr("Server List")
                                        if (currentPage === "settings") return qsTr("Settings")
                                        if (currentPage === "profile") return qsTr("Profile")
                                        if (currentPage === "login") return qsTr("Login/Register")
                                        if (currentPage === "store") return isSimpleMode ? qsTr("Store") : qsTr("Subscription")
                                        return "JinGo"
                                    }
                                    font.pixelSize: isMobile ? 18 : 20
                                    font.weight: isMobile ? Theme.typography.mobileWeightBold : Font.Bold
                                    color: Theme.colors.navButtonText
                                }

                                Label {
                                    Layout.alignment: Qt.AlignLeft
                                    text: {
                                        if (currentPage === "connection") return qsTr("Manage your VPN connection")
                                        if (currentPage === "servers") return qsTr("Select the best server")
                                        if (currentPage === "store") return qsTr("Upgrade your subscription plan")
                                        return ""
                                    }
                                    font.pixelSize: 12
                                    font.weight: isMobile ? Theme.typography.mobileWeightNormal : Font.Normal
                                    color: isDarkMode ? "#999999" : Theme.colors.textSecondary
                                    visible: text !== "" && !isMobile
                                }
                            }

                            // 模式切换按钮（仅移动端专业模式显示）
                            AbstractButton {
                                Layout.alignment: Qt.AlignRight
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                visible: isMobile && isAuthenticated

                                background: Rectangle {
                                    radius: 18
                                    color: parent.pressed ? Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.25)
                                         : Qt.rgba(Theme.colors.primary.r, Theme.colors.primary.g, Theme.colors.primary.b, 0.12)
                                }

                                contentItem: Label {
                                    text: isSimpleMode ? "S" : "P"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: Theme.colors.primary
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                onClicked: switchUiMode()
                            }

                            // 连接状态指示器（仅桌面端显示）
                            Rectangle {
                                Layout.alignment: Qt.AlignRight
                                Layout.preferredWidth: 150
                                Layout.preferredHeight: 36
                                radius: 18
                                color: isConnected ? "#FF980020" : "#99999920"
                                border.color: isConnected ? "#FF9800" : "#999999"
                                border.width: 1
                                visible: !isMobile && currentPage !== "login"

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: isConnected ? "#FF9800" : "#999999"

                                        SequentialAnimation on opacity {
                                            running: isConnected
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                                        }
                                    }

                                    Label {
                                        text: isConnected ? qsTr("Connected") : qsTr("Not Connected")
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: isConnected ? "#FF9800" : "#999999"
                                    }
                                }
                            }
                        }
                    }

                    // 页面内容区域
                    StackView {
                        id: stackView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // 为底部导航栏预留空间
                        // 简约模式：浮动胶囊有自己的定位，页面自己预留空间
                        // 专业模式：导航栏高度68px
                        Layout.bottomMargin: isMobile && currentPage !== "login" && currentPage !== "loading" ? (isSimpleMode ? 0 : 68) : 0

                        // Android页面切换时重新设置状态栏
                        onCurrentItemChanged: {
                            if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined') {
                                // 无论什么主题，都使用深色图标（黑色）
                                androidStatusBarManager.setSystemBarIconsColor(false, false)
                            }
                        }

                        // 优化页面切换动画，避免闪烁
                        replaceEnter: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }
                        replaceExit: Transition {
                            NumberAnimation {
                                property: "opacity"
                                from: 1
                                to: 0
                                duration: 100
                                easing.type: Easing.InQuad
                            }
                        }

                        // 确保背景色一致，避免闪烁
                        background: Rectangle {
                            color: Theme.colors.pageBackground
                        }
                    }
                }

                // 移动端底部导航栏 - 根据模式切换组件
                Loader {
                    id: bottomNavLoader
                    width: parent.width
                    anchors.bottom: parent.bottom
                    visible: isMobile && currentPage !== "login" && currentPage !== "loading"
                    sourceComponent: isSimpleMode ? simpleNavComp : proNavComp
                }

                Component {
                    id: proNavComp
                    BottomNavigationBar {
                        width: bottomNavLoader.width
                        currentPage: mainWindow.currentPage
                        isDarkMode: mainWindow.isDarkMode
                        isConnected: mainWindow.isConnected
                        onNavigateToPage: function(page, qmlFile) {
                            mainWindow.navigateTo(page, qmlFile)
                        }
                    }
                }

                Component {
                    id: simpleNavComp
                    SimpleBottomNavigationBar {
                        width: bottomNavLoader.width
                        currentPage: mainWindow.currentPage
                        isDarkMode: mainWindow.isDarkMode
                        isConnected: mainWindow.isConnected
                        bottomPadding: mainWindow.safeAreaBottom / 5
                        onNavigateToPage: function(page, qmlFile) {
                            mainWindow.navigateTo(page, qmlFile)
                        }
                    }
                }
            }
        }

    }

    // 窗口关闭事件
    onClosing: function(close) {
        if (!isMobile) {
            // 检查是否开启了最小化到系统托盘
            var shouldMinimizeToTray = configManager && configManager.minimizeToTray

            if (shouldMinimizeToTray) {
                // 最小化到系统托盘
                close.accepted = false
                mainWindow.hide()

                if (!hasShownTrayHint && systemTrayManager) {
                    systemTrayManager.showMessage(
                        qsTr("JinGo"),
                        qsTr("Application minimized to system tray, click the tray icon to reopen")
                    )
                    hasShownTrayHint = true
                }
            } else {
                // 直接退出应用
                close.accepted = true
                Qt.quit()
            }
        }
    }

    // 监听VPN状态变化
    Connections {
        target: vpnManager

        function onStateChanged(newState) {
            updateVPNConnectionState()
        }

        function onConnected() {
            updateVPNConnectionState()
        }

        function onDisconnected() {
            updateVPNConnectionState()
        }
    }

    // 应用启动时的数据加载标记
    property bool hasLoadedInitialData: false

    // 启动时预加载所有数据
    function loadInitialData() {
        if (hasLoadedInitialData || !authManager || !authManager.isAuthenticated) {
            return
        }

        hasLoadedInitialData = true

        // 1. 加载用户信息（loadSession 不调用此方法，保留）
        if (authManager && typeof authManager.loadUserInfo === 'function') {
            authManager.loadUserInfo()
        }

        // 2-3. getUserSubscribe 和 fetchPlans 已由 AuthManager::loadSession() 调用，不再重复
        // 4. 服务器列表已在 ServerListViewModel 构造函数中加载，不再重复调用

    }

    // 初始化
    Component.onCompleted: {
        // 安全地更新isAuthenticated状态
        try {
            if (authManager && typeof authManager.isAuthenticated !== 'undefined') {
                isAuthenticated = authManager.isAuthenticated || false
            }
        } catch (e) {
            isAuthenticated = false
        }

        // 加载主题配置
        try {
            if (configManager && typeof configManager.theme !== 'undefined') {
                var loadedTheme = configManager.theme || "JinGO"
                Theme.currentTheme = Theme.themes[loadedTheme] || Theme.jingoTheme
            } else {
                Theme.currentTheme = Theme.jingoTheme
            }
        } catch (e) {
            Theme.currentTheme = Theme.jingoTheme
        }

        // Android状态栏和导航栏图标初始化 - 始终使用深色图标
        if (Qt.platform.os === "android" && typeof androidStatusBarManager !== 'undefined') {
            // 无论什么主题，都使用深色图标（黑色）
            androidStatusBarManager.setSystemBarIconsColor(false, false)
        }

        // 延迟初始化连接状态，确保所有对象都已就绪
        Qt.callLater(updateVPNConnectionState)

        // 设置初始页面
        if (isAuthenticated) {
            navigateTo("connection", getPagePath("connection"))
            // 应用启动时预加载所有数据
            Qt.callLater(loadInitialData)
        } else {
            navigateTo("login", "pages/LoginPage.qml")
        }
    }

    // Toast 弹窗组件
    Popup {
        id: toastPopup
        x: (parent.width - width) / 2
        y: parent.height - height - 100
        width: Math.min(toastLabel.implicitWidth + 40, parent.width - 40)
        height: 48
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: isDarkMode ? "#424242" : "#323232"
            radius: 24
            opacity: 0.95
        }

        contentItem: Label {
            id: toastLabel
            text: ""
            color: "white"
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }

        // 自动关闭定时器
        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: toastPopup.close()
        }

        onOpened: toastTimer.start()
        onClosed: toastTimer.stop()

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 }
        }
    }
}
