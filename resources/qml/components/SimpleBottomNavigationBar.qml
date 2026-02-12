// components/SimpleBottomNavigationBar.qml
// 简约模式底部导航栏 - 浮动按钮组，3 标签（仪表盘/商店/个人中心）
import QtQuick 2.15
import QtQuick.Controls 2.15
import JinGo 1.0
import QtQuick.Layouts 2.15

Item {
    id: bottomNav

    property string currentPage: "connection"
    property bool isDarkMode: false
    property bool isConnected: false
    property real bottomPadding: 0  // 底部安全区域高度

    signal navigateToPage(string page, string qmlFile)

    readonly property int navBarHeight: 64
    height: navBarHeight + bottomPadding

    // 浮动胶囊背景（底部紧贴安全区域上沿）
    Rectangle {
        id: floatingBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: bottomPadding
        width: Math.min(parent.width - 32, 360)
        height: navBarHeight
        radius: navBarHeight / 2
        color: Theme.colors.surface
        border.color: Theme.colors.border
        border.width: 1

        // 阴影效果
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 2
            height: parent.height + 2
            radius: parent.radius + 1
            color: Qt.rgba(0, 0, 0, 0.08)
            z: -1
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 4

            // 仪表盘
            BottomNavButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                iconSource: isConnected ? "qrc:/icons/connected.png" : "qrc:/icons/disconnected.png"
                labelText: qsTr("Dashboard")
                isActive: currentPage === "connection"
                isDarkMode: bottomNav.isDarkMode

                onClicked: navigateToPage("connection", "pages/simple/SimpleConnectionPage.qml")
            }

            // 商店
            BottomNavButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                iconSource: "qrc:/icons/store.png"
                labelText: qsTr("Store")
                isActive: currentPage === "store"
                isDarkMode: bottomNav.isDarkMode

                onClicked: navigateToPage("store", "pages/simple/SimpleStorePage.qml")
            }

            // 个人中心
            BottomNavButton {
                Layout.fillWidth: true
                Layout.fillHeight: true

                iconSource: "qrc:/icons/user.png"
                labelText: qsTr("Profile")
                isActive: currentPage === "profile"
                isDarkMode: bottomNav.isDarkMode

                onClicked: navigateToPage("profile", "pages/simple/SimpleProfilePage.qml")
            }
        }
    }
}
