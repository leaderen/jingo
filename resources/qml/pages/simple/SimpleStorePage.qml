// pages/simple/SimpleStorePage.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import JinGo 1.0

Rectangle {
    id: simpleStorePage
    readonly property var mainWindow: ApplicationWindow.window
    color: Theme.colors.pageBackground

    readonly property bool isDarkMode: mainWindow ? mainWindow.isDarkMode : false

    // IAP detection
    readonly property bool useIAP: typeof iapManager !== 'undefined' && iapManager && iapManager.isAvailable
    readonly property bool isApplePlatform: Qt.platform.os === "ios" || Qt.platform.os === "osx"

    property var subscriptionListModel: subscriptionManager ? subscriptionManager.subscriptionListModel : null
    property var currentSubscription: subscriptionManager ? subscriptionManager.currentSubscription : null

    // Subscription data state
    property var subscribeData: null
    property bool isLoadingSubscribe: false
    property string subscribeError: ""

    // Plans data state
    property var plansData: []
    property bool isLoadingPlans: false
    property string plansError: ""

    // Plans list model
    ListModel {
        id: plansListModel
    }

    // Period options cache: { planId: [{period, name, price, monthlyPrice, description}, ...] }
    property var planPeriodOptions: ({})

    // Purchase flow state
    property int purchasingPlanId: 0
    property string currentOrderId: ""
    property var availablePaymentMethods: []
    property bool isLoadingPaymentMethods: false
    property bool isCreatingOrder: false
    property bool isProcessingPayment: false
    property string selectedPeriod: ""

    // ========================================================================
    // Update subscription data reference
    // ========================================================================
    function updateSubscriptionData() {
        if (subscriptionManager) {
            subscriptionListModel = subscriptionManager.subscriptionListModel
            currentSubscription = subscriptionManager.currentSubscription
        } else {
            subscriptionListModel = null
            currentSubscription = null
        }
    }

    // ========================================================================
    // Rebuild plansListModel when plansData changes
    // ========================================================================
    onPlansDataChanged: {
        plansListModel.clear()
        planPeriodOptions = {}

        for (var i = 0; i < plansData.length; i++) {
            var plan = plansData[i]

            if (plan.show === false) {
                continue
            }

            var periodOptions = []

            if (plan.month_price !== undefined && plan.month_price > 0) {
                var monthPrice = (plan.month_price / 100.0).toFixed(2)
                periodOptions.push({
                    period: "month_price",
                    name: qsTr("Monthly"),
                    price: monthPrice,
                    monthlyPrice: monthPrice,
                    description: qsTr("Billed monthly")
                })
            }

            if (plan.quarter_price !== undefined && plan.quarter_price > 0) {
                var quarterPrice = (plan.quarter_price / 100.0).toFixed(2)
                var quarterMonthly = (plan.quarter_price / 100.0 / 3).toFixed(2)
                periodOptions.push({
                    period: "quarter_price",
                    name: qsTr("Quarterly"),
                    price: quarterPrice,
                    monthlyPrice: quarterMonthly,
                    description: qsTr("Billed every 3 months")
                })
            }

            if (plan.half_year_price !== undefined && plan.half_year_price > 0) {
                var halfYearPrice = (plan.half_year_price / 100.0).toFixed(2)
                var halfYearMonthly = (plan.half_year_price / 100.0 / 6).toFixed(2)
                periodOptions.push({
                    period: "half_year_price",
                    name: qsTr("Semi-Annual"),
                    price: halfYearPrice,
                    monthlyPrice: halfYearMonthly,
                    description: qsTr("Billed every 6 months")
                })
            }

            if (plan.year_price !== undefined && plan.year_price > 0) {
                var yearPrice = (plan.year_price / 100.0).toFixed(2)
                var yearMonthly = (plan.year_price / 100.0 / 12).toFixed(2)
                periodOptions.push({
                    period: "year_price",
                    name: qsTr("Yearly"),
                    price: yearPrice,
                    monthlyPrice: yearMonthly,
                    description: qsTr("Billed annually - Best value!")
                })
            }

            if (plan.two_year_price !== undefined && plan.two_year_price > 0) {
                var twoYearPrice = (plan.two_year_price / 100.0).toFixed(2)
                var twoYearMonthly = (plan.two_year_price / 100.0 / 24).toFixed(2)
                periodOptions.push({
                    period: "two_year_price",
                    name: qsTr("2 Years"),
                    price: twoYearPrice,
                    monthlyPrice: twoYearMonthly,
                    description: qsTr("Billed every 2 years")
                })
            }

            if (plan.three_year_price !== undefined && plan.three_year_price > 0) {
                var threeYearPrice = (plan.three_year_price / 100.0).toFixed(2)
                var threeYearMonthly = (plan.three_year_price / 100.0 / 36).toFixed(2)
                periodOptions.push({
                    period: "three_year_price",
                    name: qsTr("3 Years"),
                    price: threeYearPrice,
                    monthlyPrice: threeYearMonthly,
                    description: qsTr("Billed every 3 years")
                })
            }

            if (plan.onetime_price !== undefined && plan.onetime_price > 0) {
                var onetimePrice = (plan.onetime_price / 100.0).toFixed(2)
                periodOptions.push({
                    period: "onetime_price",
                    name: qsTr("One-time"),
                    price: onetimePrice,
                    monthlyPrice: "",
                    description: qsTr("One-time payment, no renewal")
                })
            }

            // Use first available period as default display
            var planPrice = "0"
            var planPeriod = ""

            if (periodOptions.length > 0) {
                planPrice = periodOptions[0].price
                planPeriod = periodOptions[0].name
            }

            // Store period options by plan id
            var planId = plan.id || 0
            planPeriodOptions[planId] = periodOptions

            // Parse traffic quota
            var dataLimit = plan.transfer_enable || 0

            // Parse features list
            var featuresList = []
            if (plan.content) {
                var lines = plan.content.split('\n')
                for (var j = 0; j < lines.length; j++) {
                    var line = lines[j].trim()
                    if (line) {
                        featuresList.push(line)
                    }
                }
            }

            plansListModel.append({
                id: planId,
                name: plan.name || qsTr("Unnamed Plan"),
                price: planPrice,
                originalPrice: "",
                currency: "\u00A5",
                duration: planPeriod,
                dataLimit: dataLimit,
                deviceLimit: plan.device_limit || 5,
                speed: plan.speed_limit > 0 ? (plan.speed_limit + " Mbps") : qsTr("Unlimited"),
                features: featuresList,
                isRecommended: plan.is_recommended || false,
                isPopular: plan.is_popular || false,
                isPurchasing: false,
                hasPeriodOptions: periodOptions.length > 1
            })
        }

        // Trigger property change notification
        planPeriodOptions = planPeriodOptions
    }

    // ========================================================================
    // Initialization
    // ========================================================================
    Component.onCompleted: {
        updateSubscriptionData()

        // IAP: load product info
        if (useIAP && iapManager) {
            iapManager.loadProducts()
        }

        // Read cached data from authManager
        if (authManager && typeof authManager !== 'undefined') {
            if (authManager.subscribeInfo && typeof authManager.subscribeInfo !== 'undefined') {
                var data = authManager.subscribeInfo
                subscribeData = simplifySubscribeData(data)
                isLoadingSubscribe = false
                subscribeError = ""
            }

            if (authManager.plans && typeof authManager.plans !== 'undefined') {
                plansData = authManager.plans
                isLoadingPlans = false
                plansError = ""
            }
        }
    }

    // ========================================================================
    // Simplify subscribe data helper
    // ========================================================================
    function simplifySubscribeData(data) {
        return {
            d: data.d || 0,
            u: data.u || 0,
            transfer_enable: data.transfer_enable || 0,
            device_limit: data.device_limit || 0,
            email: data.email || "",
            expired_at: data.expired_at || 0,
            next_reset_at: data.next_reset_at || 0,
            plan_id: data.plan_id || 0,
            reset_day: data.reset_day || 0,
            speed_limit: data.speed_limit || 0,
            subscribe_url: data.subscribe_url || "",
            token: data.token || "",
            uuid: data.uuid || ""
        }
    }

    // ========================================================================
    // Connections: subscriptionManager
    // ========================================================================
    Connections {
        target: subscriptionManager

        function onCurrentSubscriptionChanged() {
            updateSubscriptionData()
        }

        function onSubscriptionListModelChanged() {
            updateSubscriptionData()
        }
    }

    // ========================================================================
    // Connections: authManager
    // ========================================================================
    Connections {
        target: authManager

        function onAuthenticationChanged() {
            if (authManager && authManager.isAuthenticated) {
                updateSubscriptionData()
            } else {
                subscribeData = null
                plansData = []
            }
        }

        function onSubscribeInfoLoaded(data) {
            subscribeData = simplifySubscribeData(data)
            isLoadingSubscribe = false
            subscribeError = ""
        }

        function onSubscribeInfoLoadFailed(error) {
            isLoadingSubscribe = false
            subscribeError = error
        }

        function onPlansLoaded(plans) {
            plansData = plans
            isLoadingPlans = false
            plansError = ""
        }

        function onPlansLoadFailed(error) {
            isLoadingPlans = false
            plansError = error
        }

        function onSubscribeInfoChanged() {
            if (authManager && authManager.subscribeInfo) {
                subscribeData = simplifySubscribeData(authManager.subscribeInfo)
                isLoadingSubscribe = false
                subscribeError = ""
            }
        }

        function onPlansChanged() {
            if (authManager && authManager.plans) {
                plansData = authManager.plans
                isLoadingPlans = false
                plansError = ""
            }
        }
    }

    // ========================================================================
    // Connections: backgroundDataUpdater
    // ========================================================================
    Connections {
        target: typeof backgroundDataUpdater !== 'undefined' ? backgroundDataUpdater : null
        enabled: typeof backgroundDataUpdater !== 'undefined' && backgroundDataUpdater !== null

        function onSubscriptionInfoUpdated() {
            if (!backgroundDataUpdater.isUpdating) {
                updateSubscriptionData()
            }
        }

        function onPlansUpdated() {
            // Plans already updated via authManager.onPlansLoaded
        }

        function onDataUpdateCompleted() {
            if (!backgroundDataUpdater.isUpdating) {
                updateSubscriptionData()
            }
        }
    }

    // ========================================================================
    // Connections: iapManager
    // ========================================================================
    Connections {
        target: (useIAP && typeof iapManager !== 'undefined') ? iapManager : null
        enabled: useIAP

        function onPurchaseSucceeded(productId, receipt, transactionId) {
            showSuccessMessage(qsTr("Purchase successful!"))
            refreshSubscriptionTimer.restart()
            purchasingPlanId = 0
        }

        function onPurchaseFailed(productId, error) {
            showErrorMessage(error)
            purchasingPlanId = 0
        }

        function onPurchaseCancelled(productId) {
            purchasingPlanId = 0
        }

        function onPurchasesRestored(restoredProducts) {
            if (restoredProducts.length > 0) {
                showSuccessMessage(qsTr("Purchases restored successfully"))
                refreshSubscriptionTimer.restart()
            } else {
                showSuccessMessage(qsTr("No purchases to restore"))
            }
        }

        function onRestoreFailed(error) {
            showErrorMessage(qsTr("Restore failed: ") + error)
        }

        function onProductsLoaded(products) {
            // Products loaded, available for localized pricing if needed
        }

        function onReceiptVerified(success, response) {
            if (success) {
                refreshSubscriptionTimer.restart()
            }
        }
    }

    // ========================================================================
    // Connections: orderManager
    // ========================================================================
    Connections {
        target: typeof orderManager !== 'undefined' ? orderManager : null
        enabled: typeof orderManager !== 'undefined'

        function onOrderCreated(order) {
            isCreatingOrder = false
            currentOrderId = order.trade_no || ""
            loadPaymentMethods()
        }

        function onOrderFailed(error) {
            isCreatingOrder = false
            showErrorMessage(error)
            purchasingPlanId = 0
        }

        function onPaymentMethodsLoaded(methods) {
            isLoadingPaymentMethods = false
            var tempMethods = []
            if (methods) {
                for (var i = 0; i < methods.length; i++) {
                    tempMethods.push(methods[i])
                }
            }
            availablePaymentMethods = tempMethods

            if (availablePaymentMethods.length > 0) {
                paymentDialog.open()
            } else {
                showErrorMessage(qsTr("No payment methods available"))
                purchasingPlanId = 0
                currentOrderId = ""
            }
        }

        function onPaymentMethodsFailed(error) {
            isLoadingPaymentMethods = false
            showErrorMessage(error)
            purchasingPlanId = 0
            currentOrderId = ""
        }

        function onPaymentUrlReady(url, type) {
            isProcessingPayment = false
            paymentDialog.close()
            showSuccessMessage(qsTr("Payment initiated successfully"))

            if (url) {
                Qt.openUrlExternally(url)
            }

            refreshSubscriptionTimer.restart()
            purchasingPlanId = 0
            currentOrderId = ""
        }

        function onPaymentFailed(error) {
            isProcessingPayment = false
            showErrorMessage(error)
        }
    }

    // ========================================================================
    // Refresh subscription timer (after payment)
    // ========================================================================
    Timer {
        id: refreshSubscriptionTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (authManager) {
                authManager.getUserSubscribe()
            }
        }
    }

    // ========================================================================
    // Helper functions
    // ========================================================================
    function loadSubscribeInfo() {
        if (!authManager || !authManager.isAuthenticated) return
        isLoadingSubscribe = true
        subscribeError = ""
        authManager.getUserSubscribe()
    }

    function loadPlans() {
        if (!authManager || !authManager.isAuthenticated) return
        isLoadingPlans = true
        plansError = ""
        authManager.fetchPlans()
    }

    function formatExpireDate(timestamp) {
        if (!timestamp) return ""
        var date = new Date(timestamp * 1000)
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    function getPlanName(planId) {
        if (!planId) return qsTr("Unknown Plan")
        for (var i = 0; i < plansListModel.count; i++) {
            var plan = plansListModel.get(i)
            if (plan.id === planId) {
                return plan.name
            }
        }
        return qsTr("Plan #") + planId
    }

    function getRemainingTraffic() {
        if (!subscribeData) return 0
        var total = subscribeData.transfer_enable || 0
        var upload = subscribeData.u || 0
        var download = subscribeData.d || 0
        var used = upload + download
        return Math.max(0, total - used)
    }

    function getTrafficPercentage() {
        if (!subscribeData || !subscribeData.transfer_enable) return 0
        var total = subscribeData.transfer_enable
        var remaining = getRemainingTraffic()
        return Math.round((remaining / total) * 100)
    }

    function isExpiringSoon(timestamp) {
        if (!timestamp) return false
        var expireDate = new Date(timestamp * 1000)
        var now = new Date()
        var daysDiff = Math.floor((expireDate - now) / (1000 * 60 * 60 * 24))
        return daysDiff <= 7 && daysDiff >= 0
    }

    function formatBytes(bytes) {
        if (bytes === 0) return "0 B"
        if (bytes < 0) return qsTr("Unlimited")
        var k = 1024
        var sizes = ["B", "KB", "MB", "GB", "TB"]
        var i = Math.floor(Math.log(bytes) / Math.log(k))
        var value = (bytes / Math.pow(k, i)).toFixed(2)
        return value + " " + sizes[i]
    }

    // ========================================================================
    // Purchase flow functions
    // ========================================================================
    function startPurchase(planId, planName, price, currency) {
        if (!authManager || !authManager.isAuthenticated) {
            showErrorMessage(qsTr("Please login first"))
            return
        }

        purchasingPlanId = planId

        // IAP platform: use native in-app purchase
        if (useIAP) {
            startIAPPurchase(planId)
            return
        }

        // Non-IAP: standard order flow
        paymentDialog.planId = planId
        paymentDialog.planName = planName
        paymentDialog.planPrice = price
        paymentDialog.currency = currency

        var periodOptions = planPeriodOptions[planId] || []

        if (periodOptions.length > 1) {
            periodSelectDialog.planId = planId
            periodSelectDialog.planName = planName
            periodSelectDialog.periodOptions = periodOptions
            periodSelectDialog.currency = currency
            periodSelectDialog.open()
        } else if (periodOptions.length === 1) {
            selectedPeriod = periodOptions[0].period
            paymentDialog.planPrice = periodOptions[0].price
            createOrder(planId, periodOptions[0].period)
        } else {
            selectedPeriod = ""
            createOrder(planId, "")
        }
    }

    function startIAPPurchase(planId) {
        if (!iapManager) {
            showErrorMessage(qsTr("IAP not available"))
            purchasingPlanId = 0
            return
        }

        var periodOptions = planPeriodOptions[planId] || []

        if (periodOptions.length > 1) {
            iapPeriodSelectDialog.planId = planId
            iapPeriodSelectDialog.periodOptions = periodOptions
            iapPeriodSelectDialog.open()
        } else if (periodOptions.length === 1) {
            var iapProductId = periodToIAPProductId(periodOptions[0].period)
            if (iapProductId) {
                iapManager.purchase(iapProductId)
            } else {
                showErrorMessage(qsTr("No matching IAP product for this plan"))
                purchasingPlanId = 0
            }
        } else {
            showErrorMessage(qsTr("No subscription options available"))
            purchasingPlanId = 0
        }
    }

    function periodToIAPProductId(period) {
        var map = {
            "month_price": "jingo_monthly",
            "quarter_price": "jingo_quarterly",
            "half_year_price": "jingo_half_yearly",
            "year_price": "jingo_yearly"
        }
        return map[period] || ""
    }

    function createOrder(planId, period) {
        if (!orderManager) {
            showErrorMessage(qsTr("Order manager not available"))
            return
        }
        isCreatingOrder = true
        orderManager.createOrder(planId, period || "", "")
    }

    function loadPaymentMethods() {
        if (!orderManager) {
            showErrorMessage(qsTr("Order manager not available"))
            return
        }
        isLoadingPaymentMethods = true
        orderManager.fetchPaymentMethods()
    }

    function processPayment(paymentMethod) {
        if (!orderManager || !currentOrderId) {
            showErrorMessage(qsTr("Invalid order"))
            return
        }
        isProcessingPayment = true
        orderManager.getPaymentUrl(currentOrderId, paymentMethod.toString())
    }

    // ========================================================================
    // Toast message functions
    // ========================================================================
    function showErrorMessage(message) {
        errorToast.errorText = message
        errorToast.opacity = 1
        errorToastAnimation.restart()
    }

    function showSuccessMessage(message) {
        successToast.successText = message
        successToast.opacity = 1
        successToastAnimation.restart()
    }

    // ========================================================================
    // Main scrollable content
    // ========================================================================
    ScrollView {
        id: mainScrollView
        anchors.fill: parent
        anchors.leftMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 16
        anchors.rightMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 16
        anchors.topMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 0
        anchors.bottomMargin: (mainWindow && mainWindow.isDesktop) ? 40 : 0
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: mainScrollView.width

        ColumnLayout {
            width: mainScrollView.width
            spacing: Theme.spacing.lg

            // 页面标题行 + 模式切换按钮（桌面端由 main.qml 顶部栏显示，隐藏此行）
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: (mainWindow && !mainWindow.isDesktop) ? (mainWindow ? mainWindow.safeAreaTop / 2 : 0) : 0
                spacing: 8
                visible: mainWindow ? mainWindow.isMobile : true

                Label {
                    text: qsTr("Store")
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.colors.textPrimary
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: storeModeArea.pressed
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
                        id: storeModeArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (mainWindow) mainWindow.switchUiMode() }
                    }
                }
            }

            // ==============================================================
            // Current subscription status card
            // ==============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: {
                    if (!authManager || !authManager.isAuthenticated) return 0
                    if (subscribeData) return 140
                    if (isLoadingSubscribe) return 100
                    return 120
                }
                radius: Theme.radius.md
                color: Theme.colors.surface
                border.width: 1
                border.color: Theme.colors.border
                visible: authManager && authManager.isAuthenticated
                opacity: visible ? 1 : 0

                Behavior on Layout.preferredHeight {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }

                // Loading state
                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacing.sm
                    visible: isLoadingSubscribe

                    BusyIndicator {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        running: isLoadingSubscribe
                    }

                    Label {
                        text: qsTr("Loading subscription information...")
                        font.pixelSize: Theme.typography.body2
                        color: Theme.colors.textSecondary
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.lg
                    spacing: Theme.spacing.md
                    visible: !isLoadingSubscribe

                    // Subscription icon
                    Label {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignVCenter
                        text: subscribeData ? "\u25C6" : "\u25CB"
                        font.pixelSize: 32
                        color: subscribeData ? Theme.colors.primary : Theme.colors.textTertiary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Subscription info
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Theme.spacing.xs

                        Label {
                            text: qsTr("Current Subscription")
                            font.pixelSize: Theme.typography.caption
                            color: Theme.colors.textSecondary
                        }

                        Label {
                            text: subscribeData ?
                                  getPlanName(subscribeData.plan_id) :
                                  qsTr("No Subscription")
                            font.pixelSize: Theme.typography.h4
                            font.weight: Theme.typography.weightBold
                            color: subscribeData ? Theme.colors.textPrimary : Theme.colors.textSecondary
                        }

                        // No subscription hint
                        Label {
                            visible: !subscribeData
                            text: qsTr("Select a plan below to get started")
                            font.pixelSize: Theme.typography.body2
                            color: Theme.colors.textTertiary
                        }

                        // Subscription details (expiry and remaining traffic)
                        RowLayout {
                            spacing: Theme.spacing.md
                            visible: subscribeData !== null

                            // Expiry date
                            RowLayout {
                                visible: subscribeData && subscribeData.expired_at
                                spacing: Theme.spacing.xs

                                IconSymbol {
                                    icon: "clock"
                                    size: 14
                                    color: isExpiringSoon(subscribeData ? subscribeData.expired_at : 0) ? Theme.colors.warning : Theme.colors.textSecondary
                                }

                                Label {
                                    text: subscribeData ?
                                          qsTr("Exp: %1").arg(formatExpireDate(subscribeData.expired_at)) :
                                          ""
                                    font.pixelSize: Theme.typography.body2
                                    color: isExpiringSoon(subscribeData ? subscribeData.expired_at : 0) ?
                                           Theme.colors.warning : Theme.colors.textSecondary
                                }
                            }

                            // Remaining traffic
                            RowLayout {
                                visible: subscribeData && subscribeData.transfer_enable
                                spacing: Theme.spacing.xs

                                IconSymbol {
                                    icon: "traffic"
                                    size: 14
                                    color: getTrafficPercentage() < 20 ? Theme.colors.error : Theme.colors.textSecondary
                                }

                                Label {
                                    text: subscribeData ?
                                          qsTr("Rem: %1").arg(formatBytes(getRemainingTraffic())) :
                                          ""
                                    font.pixelSize: Theme.typography.body2
                                    color: getTrafficPercentage() < 20 ?
                                           Theme.colors.error : Theme.colors.textSecondary
                                }
                            }
                        }

                        // Traffic usage progress bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6
                            radius: 3
                            color: Theme.colors.divider
                            visible: subscribeData && subscribeData.transfer_enable

                            Rectangle {
                                width: parent.width * ((100 - getTrafficPercentage()) / 100)
                                height: parent.height
                                radius: parent.radius
                                color: {
                                    var usedPercent = 100 - getTrafficPercentage()
                                    if (usedPercent > 80) return Theme.colors.error
                                    if (usedPercent > 50) return Theme.colors.warning
                                    return Theme.colors.success
                                }
                            }
                        }
                    }
                }
            }

            // ==============================================================
            // Plans section title
            // ==============================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.md

                Label {
                    text: qsTr("Select Plan")
                    font.pixelSize: Theme.typography.h4
                    font.weight: Theme.typography.weightBold
                    color: Theme.colors.textPrimary
                }

                Item { Layout.fillWidth: true }
            }

            // ==============================================================
            // Plans grid with SubscriptionCard components
            // ==============================================================
            GridLayout {
                id: plansGrid
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.xs

                columns: {
                    var w = mainScrollView.width
                    if (w < 500) return 1
                    else if (w < 1000) return 2
                    else return 3
                }

                columnSpacing: mainScrollView.width < 500 ? 0 : (mainScrollView.width < 600 ? Theme.spacing.xs : Theme.spacing.sm)
                rowSpacing: mainScrollView.width < 500 ? Theme.spacing.sm : Theme.spacing.md

                Repeater {
                    model: plansListModel

                    SubscriptionCard {
                        Layout.fillWidth: true
                        Layout.preferredWidth: {
                            var availableWidth = mainScrollView.width
                            var cols = plansGrid.columns
                            if (cols === 1) {
                                return availableWidth
                            } else {
                                var totalSpacing = (cols - 1) * plansGrid.columnSpacing
                                return (availableWidth - totalSpacing) / cols
                            }
                        }

                        height: {
                            var cols = plansGrid.columns
                            if (cols === 1) return 320
                            else if (mainWindow && mainWindow.isMobile) return 360
                            else return 380
                        }

                        planId: model.id || ""
                        planName: model.name || qsTr("Unnamed Plan")
                        price: model.price || "0"
                        currency: model.currency || "\u00A5"
                        duration: model.duration || qsTr("Month")
                        originalPrice: model.originalPrice || ""
                        dataLimit: model.dataLimit || 0
                        deviceLimit: model.deviceLimit || 5
                        speed: model.speed || ""
                        features: model.features || []
                        isRecommended: model.isRecommended || false
                        isPopular: model.isPopular || false
                        isPurchasing: model.isPurchasing || false
                        isPurchased: (subscribeData && subscribeData.plan_id === model.id) || false

                        onPurchaseClicked: {
                            startPurchase(planId, model.name, model.price, model.currency)
                        }
                    }
                }
            }

            // ==============================================================
            // Restore Purchases button (Apple platforms only)
            // ==============================================================
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.topMargin: Theme.spacing.sm
                radius: Theme.radius.md
                color: restoreArea.containsMouse ? Theme.alpha(Theme.colors.primary, 0.08) : "transparent"
                border.width: 1
                border.color: restoreArea.containsMouse ? Theme.colors.primary : Theme.colors.border
                visible: isApplePlatform && useIAP

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.spacing.sm

                    IconSymbol {
                        icon: "refresh"
                        size: 16
                        color: Theme.colors.primary

                        RotationAnimator on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            running: iapManager && iapManager.isLoading
                            loops: Animation.Infinite
                        }
                    }

                    Label {
                        text: qsTr("Restore Purchases")
                        font.pixelSize: Theme.typography.body2
                        font.weight: Theme.typography.weightMedium
                        color: Theme.colors.primary
                    }
                }

                MouseArea {
                    id: restoreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !(iapManager && iapManager.isLoading)
                    onClicked: {
                        if (iapManager) {
                            iapManager.restorePurchases()
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            // ==============================================================
            // Empty state
            // ==============================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacing.md
                visible: plansListModel.count === 0 && !isLoadingPlans

                Label {
                    text: "\u25CB"
                    font.pixelSize: 64
                    color: Theme.colors.textTertiary
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: plansError ? plansError : qsTr("No Available Plans")
                    font.pixelSize: Theme.typography.h4
                    color: plansError ? Theme.colors.error : Theme.colors.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // ==============================================================
            // Loading plans indicator
            // ==============================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacing.md
                visible: isLoadingPlans

                BusyIndicator {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignHCenter
                    running: isLoadingPlans
                }

                Label {
                    text: qsTr("Loading Plans...")
                    font.pixelSize: Theme.typography.body1
                    color: Theme.colors.textSecondary
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // 底部预留浮动导航栏 + 安全区域高度
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: (mainWindow && !mainWindow.isDesktop) ? (132 + (mainWindow ? mainWindow.safeAreaBottom : 0)) : Theme.spacing.lg
            }
        }
    }

    // ========================================================================
    // Period Select Dialog
    // ========================================================================
    PeriodSelectDialog {
        id: periodSelectDialog
        parent: Overlay.overlay

        onPeriodConfirmed: function(planId, period, periodName, price) {
            selectedPeriod = period
            paymentDialog.planPrice = price
            paymentDialog.currency = "\u00A5"
            createOrder(planId, period)
        }

        onRejected: {
            purchasingPlanId = 0
        }
    }

    // ========================================================================
    // IAP Period Select Dialog
    // ========================================================================
    Dialog {
        id: iapPeriodSelectDialog
        modal: true
        standardButtons: Dialog.NoButton
        closePolicy: Popup.CloseOnEscape

        property int planId: 0
        property var periodOptions: []

        width: Math.min(380, parent ? parent.width * 0.9 : 380)
        x: parent ? (parent.width - width) / 2 : 0
        y: parent ? (parent.height - height) / 2 : 0

        background: Rectangle {
            color: Theme.colors.background
            radius: Theme.radius.xl
            border.width: 1
            border.color: Theme.colors.border
        }

        Overlay.modal: Rectangle {
            color: Theme.alpha("#000000", 0.5)
        }

        header: Item { height: 0 }
        padding: 0

        contentItem: ColumnLayout {
            spacing: 0

            // Title area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: Theme.alpha(Theme.colors.primary, 0.08)

                Label {
                    anchors.centerIn: parent
                    text: qsTr("Select Subscription Period")
                    font.pixelSize: Theme.typography.h4
                    font.weight: Theme.typography.weightBold
                    color: Theme.colors.textPrimary
                }
            }

            // Period option list
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacing.lg
                spacing: Theme.spacing.sm

                Repeater {
                    model: iapPeriodSelectDialog.periodOptions

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: Theme.radius.md
                        color: iapOptionArea.containsMouse ? Theme.alpha(Theme.colors.primary, 0.08) : Theme.colors.surface
                        border.width: 1
                        border.color: iapOptionArea.containsMouse ? Theme.colors.primary : Theme.colors.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacing.md
                            anchors.rightMargin: Theme.spacing.md

                            Label {
                                text: modelData.name || ""
                                font.pixelSize: Theme.typography.body1
                                font.weight: Theme.typography.weightMedium
                                color: Theme.colors.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: "\u00A5" + (modelData.price || "0")
                                font.pixelSize: Theme.typography.body1
                                font.weight: Theme.typography.weightBold
                                color: Theme.colors.primary
                            }
                        }

                        MouseArea {
                            id: iapOptionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var period = modelData.period || ""
                                var iapProductId = periodToIAPProductId(period)
                                if (iapProductId && iapManager) {
                                    iapPeriodSelectDialog.close()
                                    iapManager.purchase(iapProductId)
                                } else {
                                    showErrorMessage(qsTr("This period is not available for in-app purchase"))
                                    purchasingPlanId = 0
                                }
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Cancel button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                Layout.margins: Theme.spacing.lg
                Layout.topMargin: 0
                radius: Theme.radius.md
                color: iapCancelArea.containsMouse ? Theme.colors.surfaceHover : Theme.colors.surface
                border.width: 1
                border.color: Theme.colors.border

                Label {
                    anchors.centerIn: parent
                    text: qsTr("Cancel")
                    font.pixelSize: Theme.typography.body2
                    color: Theme.colors.textPrimary
                }

                MouseArea {
                    id: iapCancelArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        iapPeriodSelectDialog.reject()
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        onRejected: {
            purchasingPlanId = 0
        }
    }

    // ========================================================================
    // Payment Dialog
    // ========================================================================
    PaymentDialog {
        id: paymentDialog
        parent: Overlay.overlay

        paymentMethods: availablePaymentMethods
        isProcessing: isProcessingPayment

        onPaymentConfirmed: function(planId, paymentMethod) {
            processPayment(paymentMethod)
        }

        onRejected: {
            purchasingPlanId = 0
            currentOrderId = ""
            selectedPeriod = ""
        }
    }

    // ========================================================================
    // Error toast
    // ========================================================================
    Rectangle {
        id: errorToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        width: Math.min(300, parent.width * 0.8)
        height: 60
        radius: Theme.radius.md
        color: Theme.colors.error
        opacity: 0
        visible: opacity > 0

        property string errorText: ""

        Label {
            anchors.centerIn: parent
            anchors.margins: Theme.spacing.sm
            text: errorToast.errorText
            color: "white"
            font.pixelSize: Theme.typography.body2
            font.weight: Theme.typography.weightMedium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - Theme.spacing.lg
        }

        NumberAnimation on opacity {
            id: errorToastAnimation
            running: false
            from: 1
            to: 0
            duration: 3000
            easing.type: Easing.InOutQuad
        }
    }

    // ========================================================================
    // Success toast
    // ========================================================================
    Rectangle {
        id: successToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 150
        width: Math.min(300, parent.width * 0.8)
        height: 60
        radius: Theme.radius.md
        color: Theme.colors.success
        opacity: 0
        visible: opacity > 0

        property string successText: ""

        Label {
            anchors.centerIn: parent
            anchors.margins: Theme.spacing.sm
            text: successToast.successText
            color: "white"
            font.pixelSize: Theme.typography.body2
            font.weight: Theme.typography.weightMedium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - Theme.spacing.lg
        }

        NumberAnimation on opacity {
            id: successToastAnimation
            running: false
            from: 1
            to: 0
            duration: 3000
            easing.type: Easing.InOutQuad
        }
    }
}
