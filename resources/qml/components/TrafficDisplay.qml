// components/TrafficDisplay.qml (完美优化版 - 无 GraphicalEffects 依赖)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Rectangle {
    id: trafficDisplay
    property bool isDarkMode: false
    
    radius: 20
    color: Theme.colors.surface
    border.color: isDarkMode ? "#2A2A2A" : "#E8E8E8"
    border.width: 1

    // Changed from readonly bindings to simple properties to avoid accessing vpnManager during init
    property real uploadSpeed: 0.0
    property real downloadSpeed: 0.0
    property real totalUpload: 0.0
    property real totalDownload: 0.0
    property var currentServer: null
    property real peakUploadSpeed: 0.0
    property real peakDownloadSpeed: 0.0
    property real avgUploadSpeed: 0.0
    property real avgDownloadSpeed: 0.0

    // 安全地更新流量数据
    function updateTrafficData() {
        try {
            if (vpnManager && typeof vpnManager !== 'undefined') {
                uploadSpeed = (typeof vpnManager.uploadSpeed !== 'undefined') ? Number(vpnManager.uploadSpeed) : 0.0
                downloadSpeed = (typeof vpnManager.downloadSpeed !== 'undefined') ? Number(vpnManager.downloadSpeed) : 0.0
                totalUpload = (typeof vpnManager.totalUpload !== 'undefined') ? Number(vpnManager.totalUpload) : 0.0
                totalDownload = (typeof vpnManager.totalDownload !== 'undefined') ? Number(vpnManager.totalDownload) : 0.0

                if (typeof vpnManager.currentServer !== 'undefined' && vpnManager.currentServer) {
                    currentServer = vpnManager.currentServer
                    peakUploadSpeed = (currentServer && typeof currentServer.peakUploadSpeed !== 'undefined') ? Number(currentServer.peakUploadSpeed) : 0.0
                    peakDownloadSpeed = (currentServer && typeof currentServer.peakDownloadSpeed !== 'undefined') ? Number(currentServer.peakDownloadSpeed) : 0.0
                    avgUploadSpeed = (currentServer && typeof currentServer.averageUploadSpeed !== 'undefined') ? Number(currentServer.averageUploadSpeed) : 0.0
                    avgDownloadSpeed = (currentServer && typeof currentServer.averageDownloadSpeed !== 'undefined') ? Number(currentServer.averageDownloadSpeed) : 0.0
                } else {
                    currentServer = null
                    peakUploadSpeed = 0.0
                    peakDownloadSpeed = 0.0
                    avgUploadSpeed = 0.0
                    avgDownloadSpeed = 0.0
                }
            }
        } catch (e) {
        }
    }

    // 定时更新流量数据
    Timer {
        id: trafficUpdateTimer
        interval: 5000
        running: false
        repeat: true
        onTriggered: updateTrafficData()
    }

    Component.onCompleted: {
        updateTrafficData()
        trafficUpdateTimer.start()
    }

    // 监听VPN状态变化
    Connections {
        target: vpnManager

        function onStateChanged() {
            updateTrafficData()
        }

        function onCurrentServerChanged() {
            updateTrafficData()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 标题
        Label {
            text: qsTr("Traffic Statistics")
            font.pixelSize: 14
            font.bold: true
            color: isDarkMode ? "#FFFFFF" : "#1A1A1A"
            Layout.topMargin: 20
            Layout.leftMargin: 24
        }

        // 流量数据
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 16

            // 上传
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 80
                radius: 12
                color: Theme.colors.surfaceElevated

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // 上传图标
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignVCenter
                        radius: 20
                        color: "#4CAF5020"

                        Label {
                            text: "↑"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#4CAF50"
                            anchors.centerIn: parent
                        }
                    }

                    // 数据信息 - 垂直布局
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Label {
                            text: qsTr("Upload")
                            font.pixelSize: 11
                            color: isDarkMode ? "#999999" : "#666666"
                        }

                        // 速度数据 - 水平布局
                        RowLayout {
                            spacing: 8

                            Label {
                                text: FormatUtils.formatSpeed(uploadSpeed)
                                font.pixelSize: 16
                                font.bold: true
                                color: "#4CAF50"
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 14
                                color: isDarkMode ? "#404040" : "#D0D0D0"
                            }

                            Label {
                                text: FormatUtils.formatBytes(totalUpload)
                                font.pixelSize: 12
                                color: isDarkMode ? "#666666" : "#999999"
                            }
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                color: isDarkMode ? "#2A2A2A" : "#E8E8E8"
            }

            // 下载
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 80
                radius: 12
                color: Theme.colors.surfaceElevated

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // 下载图标
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignVCenter
                        radius: 20
                        color: "#2196F320"

                        Label {
                            text: "↓"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#2196F3"
                            anchors.centerIn: parent
                        }
                    }

                    // 数据信息 - 垂直布局
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Label {
                            text: qsTr("Download")
                            font.pixelSize: 11
                            color: isDarkMode ? "#999999" : "#666666"
                        }

                        // 速度数据 - 水平布局
                        RowLayout {
                            spacing: 8

                            Label {
                                text: FormatUtils.formatSpeed(downloadSpeed)
                                font.pixelSize: 16
                                font.bold: true
                                color: "#2196F3"
                            }

                            Rectangle {
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 14
                                color: isDarkMode ? "#404040" : "#D0D0D0"
                            }

                            Label {
                                text: FormatUtils.formatBytes(totalDownload)
                                font.pixelSize: 12
                                color: isDarkMode ? "#666666" : "#999999"
                            }
                        }
                    }
                }
            }
        }

        // 速度统计分隔线
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            color: isDarkMode ? "#2A2A2A" : "#E8E8E8"
            visible: peakUploadSpeed > 0 || peakDownloadSpeed > 0
        }

        // 速度统计信息
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 16
            visible: peakUploadSpeed > 0 || peakDownloadSpeed > 0

            // 上传速度统计
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 12
                color: Theme.colors.surfaceElevated

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Peak Upload")
                            font.pixelSize: 10
                            color: isDarkMode ? "#999999" : "#666666"
                        }

                        Label {
                            text: FormatUtils.formatSpeed(peakUploadSpeed)
                            font.pixelSize: 14
                            font.bold: true
                            color: "#4CAF50"
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        color: isDarkMode ? "#404040" : "#D0D0D0"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Avg Upload")
                            font.pixelSize: 10
                            color: isDarkMode ? "#999999" : "#666666"
                        }

                        Label {
                            text: FormatUtils.formatSpeed(avgUploadSpeed)
                            font.pixelSize: 14
                            font.bold: true
                            color: isDarkMode ? "#888888" : "#666666"
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: isDarkMode ? "#2A2A2A" : "#E8E8E8"
            }

            // 下载速度统计
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 12
                color: Theme.colors.surfaceElevated

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Peak Download")
                            font.pixelSize: 10
                            color: isDarkMode ? "#999999" : "#666666"
                        }

                        Label {
                            text: FormatUtils.formatSpeed(peakDownloadSpeed)
                            font.pixelSize: 14
                            font.bold: true
                            color: "#2196F3"
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        color: isDarkMode ? "#404040" : "#D0D0D0"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: qsTr("Avg Download")
                            font.pixelSize: 10
                            color: isDarkMode ? "#999999" : "#666666"
                        }

                        Label {
                            text: FormatUtils.formatSpeed(avgDownloadSpeed)
                            font.pixelSize: 14
                            font.bold: true
                            color: isDarkMode ? "#888888" : "#666666"
                        }
                    }
                }
            }
        }
    }
}
