/**
 * @file BackgroundDataUpdater.h
 * @brief 后台数据更新器头文件
 * @details 在独立线程中定期更新订阅、套餐和服务器数据
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef BACKGROUNDDATAUPDATER_H
#define BACKGROUNDDATAUPDATER_H

#include <QThread>
#include <QTimer>
#include <QMutex>
#include <QMutexLocker>

/**
 * @class BackgroundDataUpdater
 * @brief 后台数据更新器（单例模式，线程安全）
 *
 * @details
 * 核心功能：
 * - 定期更新：每5分钟自动更新一次数据
 * - 独立线程：在后台线程中执行，不阻塞UI
 * - 互斥锁保护：使用锁确保数据访问安全
 * - 信号通知：更新完成后通知UI刷新
 *
 * 更新内容：
 * - 用户信息（个人资料、会员状态）
 * - 订阅信息（流量、到期时间）
 * - 套餐列表（可购买的套餐）
 * - 服务器列表（订阅中的所有服务器）
 *
 * 使用方式：
 * 1. 获取单例：BackgroundDataUpdater::instance()
 * 2. 启动更新器：start()
 * 3. 连接信号：dataUpdateCompleted()
 * 4. UI检查锁：isUpdating()
 * 5. 停止更新器：stop()
 *
 * 线程安全：
 * - 使用 QMutex 保护更新状态
 * - UI 访问数据前检查 isUpdating()
 * - 如果正在更新，UI 跳过本次刷新
 * - 更新完成后发出信号，UI 响应刷新
 *
 * @example
 * @code
 * // 在应用启动时
 * BackgroundDataUpdater::instance().start();
 *
 * // 在 QML 或 C++ 中连接信号
 * connect(&BackgroundDataUpdater::instance(),
 *         &BackgroundDataUpdater::dataUpdateCompleted,
 *         this, &MyPage::refreshUI);
 *
 * // UI 刷新时检查锁
 * void MyPage::refreshUI() {
 *     if (BackgroundDataUpdater::instance().isUpdating()) {
 *         qDebug() << "Data is being updated, skip this refresh";
 *         return;
 *     }
 *     // 安全地访问数据并更新UI
 *     loadDataFromDatabase();
 * }
 * @endcode
 */
class BackgroundDataUpdater : public QThread
{
    Q_OBJECT

    /**
     * @property isUpdating
     * @brief 是否正在更新（只读属性）
     * @details
     * - true：后台线程正在更新数据
     * - false：空闲状态，可以安全访问数据
     * @notify isUpdatingChanged()
     */
    Q_PROPERTY(bool isUpdating READ isUpdating NOTIFY isUpdatingChanged)

    /**
     * @property updateInterval
     * @brief 更新间隔（秒）
     * @details 默认 300 秒（5分钟）
     * @notify updateIntervalChanged()
     */
    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)

public:
    /**
     * @brief 获取单例实例
     * @return BackgroundDataUpdater& 全局唯一实例的引用
     */
    static BackgroundDataUpdater& instance();

    /**
     * @brief 销毁单例实例
     * @details 停止线程并清理资源
     */
    static void destroy();

    /**
     * @brief 启动后台更新器
     * @details 启动定时器，开始定期更新
     */
    Q_INVOKABLE void start();

    /**
     * @brief 停止后台更新器
     * @details 停止定时器和线程
     */
    Q_INVOKABLE void stop();

    /**
     * @brief 手动触发一次更新
     * @details 立即执行一次数据更新，不等待定时器
     */
    Q_INVOKABLE void triggerUpdate();

    /**
     * @brief 获取是否正在更新
     * @return bool true 表示正在更新，false 表示空闲
     */
    bool isUpdating() const;

    /**
     * @brief 获取更新间隔
     * @return int 更新间隔（秒）
     */
    int updateInterval() const;

    /**
     * @brief 设置更新间隔
     * @param seconds 更新间隔（秒）
     */
    void setUpdateInterval(int seconds);

signals:
    /**
     * @brief 数据更新完成信号
     * @details
     * 发出此信号表示后台数据更新已完成，UI 可以安全地刷新
     * 包括：用户信息、订阅信息、套餐列表、服务器列表
     */
    void dataUpdateCompleted();

    /**
     * @brief 用户信息更新完成信号
     */
    void userInfoUpdated();

    /**
     * @brief 订阅信息更新完成信号
     */
    void subscriptionInfoUpdated();

    /**
     * @brief 套餐列表更新完成信号
     */
    void plansUpdated();

    /**
     * @brief 服务器列表更新完成信号
     */
    void serversUpdated();

    /**
     * @brief 更新状态变化信号
     */
    void isUpdatingChanged();

    /**
     * @brief 更新间隔变化信号
     */
    void updateIntervalChanged();

    /**
     * @brief 错误发生信号
     * @param error 错误描述
     */
    void errorOccurred(const QString& error);

protected:
    /**
     * @brief 线程主循环
     * @details 设置定时器并进入事件循环
     */
    void run() override;

private:
    /**
     * @brief 私有构造函数（单例模式）
     */
    explicit BackgroundDataUpdater(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~BackgroundDataUpdater();

    // 禁用拷贝和赋值（单例模式）
    BackgroundDataUpdater(const BackgroundDataUpdater&) = delete;
    BackgroundDataUpdater& operator=(const BackgroundDataUpdater&) = delete;

    /**
     * @brief 设置更新状态
     * @param updating 是否正在更新
     */
    void setUpdating(bool updating);

private slots:
    /**
     * @brief 执行数据更新
     * @details 在后台线程中调用各个管理器的更新方法
     */
    void performUpdate();

    /**
     * @brief 定时器触发槽
     * @details 定时器到期时调用此函数执行更新
     */
    void onTimerTimeout();

    /**
     * @brief 批量更新完成回调
     * @details 在 SubscriptionManager 批量更新完成后标记更新结束
     * @param successCount 成功更新的订阅数
     * @param failedCount 失败的订阅数
     */
    void onBatchUpdateCompleted(int successCount, int failedCount);

private:
    static BackgroundDataUpdater* s_instance;  ///< 单例实例指针
    static QMutex s_instanceMutex;             ///< 单例创建互斥锁

    QTimer* m_timer;                           ///< 定时器
    mutable QMutex m_updateMutex;              ///< 更新状态互斥锁
    bool m_isUpdating;                         ///< 是否正在更新
    int m_updateInterval;                      ///< 更新间隔（秒）
    bool m_shouldStop;                         ///< 是否应该停止
    bool m_waitingForBatchUpdate = false;      ///< 是否在等待批量更新完成
};

#endif // BACKGROUNDDATAUPDATER_H
