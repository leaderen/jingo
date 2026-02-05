/**
 * @file CacheManager.h
 * @brief 缓存管理器头文件
 * @details 提供内存和磁盘两级缓存系统，支持过期时间、LRU淘汰策略和自动清理
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef CACHEMANAGER_H
#define CACHEMANAGER_H

#include <QObject>
#include <QString>
#include <QVariant>
#include <QDateTime>
#include <QMap>
#include <QMutex>

class QTimer;

/**
 * @class CacheManager
 * @brief 两级缓存管理器（单例模式，线程安全）
 *
 * @details 提供完整的缓存管理功能，包括：
 * - 两级缓存：内存缓存（快速）+ 磁盘缓存（持久）
 * - 过期机制：支持TTL（生存时间）
 * - LRU淘汰：根据最近访问时间和使用频率淘汰
 * - 自动清理：定时清理过期和冗余缓存
 * - 容量控制：限制内存和磁盘缓存大小
 * - 线程安全：使用互斥锁保护共享数据
 *
 * 缓存层次：
 * ```
 * 读取流程:
 * 1. 查找内存缓存（最快）
 * 2. 如果未命中，查找磁盘缓存
 * 3. 如果命中，加载到内存缓存
 * 4. 如果都未命中，返回默认值
 *
 * 写入流程:
 * 1. 写入内存缓存
 * 2. 如果启用磁盘缓存，同时写入磁盘
 * 3. 如果超过容量限制，执行LRU淘汰
 * ```
 *
 * 主要功能：
 * - 缓存读写：set/get/has/remove
 * - 容量管理：内存和磁盘大小限制
 * - 自动过期：基于TTL的自动失效
 * - LRU淘汰：智能清理策略
 * - 统计信息：缓存命中率、大小等
 *
 * 使用场景：
 * - API响应缓存：减少网络请求
 * - 图片缓存：加速图片加载
 * - 配置缓存：避免频繁读取配置文件
 * - 计算结果缓存：避免重复计算
 *
 * @note
 * - 单例模式：全局唯一实例
 * - 线程安全：所有公共方法都加锁保护
 * - 自动清理：定时清理过期缓存
 * - 持久化：磁盘缓存在应用重启后仍然有效
 *
 * @example 使用示例
 * @code
 * // 获取单例实例
 * CacheManager& cache = CacheManager::instance();
 *
 * // 设置缓存（5分钟有效期）
 * cache.set("user_profile", userData, 300000);
 *
 * // 读取缓存
 * QVariant data = cache.get("user_profile");
 * if (!data.isNull()) {
 *     // 使用缓存数据
 * }
 *
 * // 检查缓存是否存在
 * if (cache.has("api_response")) {
 *     QVariant response = cache.get("api_response");
 * }
 *
 * // 清理所有缓存
 * cache.clear();
 * @endcode
 */
class CacheManager : public QObject
{
    Q_OBJECT

public:
    /**
     * @struct CacheItem
     * @brief 缓存项数据结构
     *
     * @details 存储单个缓存项的所有信息
     * - value: 缓存的值（支持任意QVariant类型）
     * - expiry: 过期时间（QDateTime）
     * - size: 数据大小（字节）
     * - lastAccess: 最后访问时间（用于LRU）
     * - hitCount: 访问次数（用于热度统计）
     * - onDisk: 是否已保存到磁盘
     */
    struct CacheItem {
        QVariant value;               ///< 缓存值
        QDateTime expiry;             ///< 过期时间（无限期为null）
        qint64 size = 0;              ///< 数据大小（字节）
        mutable QDateTime lastAccess; ///< 最后访问时间
        mutable int hitCount = 0;     ///< 访问次数
        bool onDisk = false;          ///< 是否在磁盘上
    };

    // ========================================================================
    // 单例模式
    // ========================================================================

    /**
     * @brief 获取CacheManager单例实例
     * @return CacheManager& 单例引用
     *
     * @details 线程安全的单例获取方法
     * - 第一次调用时创建实例
     * - 后续调用返回同一实例
     * - C++11保证线程安全
     *
     * @note 应用程序生命周期内只有一个实例
     *
     * @example
     * @code
     * CacheManager& cache = CacheManager::instance();
     * @endcode
     */
    static CacheManager& instance();

    // ========================================================================
    // 缓存操作
    // ========================================================================

    /**
     * @brief 设置缓存
     * @param key 缓存键（唯一标识符）
     * @param value 缓存值（支持任意QVariant类型）
     * @param ttl 生存时间（毫秒），0表示永不过期
     *
     * @details 将数据存入缓存
     * - 存入内存缓存
     * - 如果启用磁盘缓存，同时写入磁盘
     * - 设置过期时间（当前时间 + ttl）
     * - 如果键已存在，会被覆盖
     * - 自动触发容量检查和淘汰
     *
     * @note
     * - ttl=0表示永不过期（除非手动删除）
     * - 大对象建议启用磁盘缓存
     *
     * @example
     * @code
     * // 缓存5分钟
     * cache.set("user_data", userData, 300000);
     *
     * // 永久缓存
     * cache.set("app_config", config, 0);
     * @endcode
     *
     * @see get, remove
     */
    void set(const QString& key, const QVariant& value, int ttl = 0);

    /**
     * @brief 获取缓存
     * @param key 缓存键
     * @param defaultValue 默认值（缓存不存在或过期时返回）
     * @return QVariant 缓存值或默认值
     *
     * @details 从缓存读取数据
     * - 先查找内存缓存
     * - 内存未命中时查找磁盘缓存
     * - 检查是否过期
     * - 更新访问时间和命中计数
     *
     * @note
     * - 过期的缓存会自动忽略
     * - 未命中返回defaultValue
     *
     * @example
     * @code
     * QVariant data = cache.get("user_profile");
     * if (data.isNull()) {
     *     // 缓存未命中，从服务器获取
     *     data = fetchFromServer();
     *     cache.set("user_profile", data, 300000);
     * }
     * @endcode
     *
     * @see set, has
     */
    QVariant get(const QString& key, const QVariant& defaultValue = QVariant()) const;

    /**
     * @brief 检查缓存是否存在
     * @param key 缓存键
     * @return bool 存在且未过期返回true，否则返回false
     *
     * @details 检查指定键的缓存是否存在且有效
     * - 检查内存缓存和磁盘缓存
     * - 自动忽略已过期的缓存
     *
     * @note 轻量级操作，不更新访问时间
     *
     * @example
     * @code
     * if (cache.has("api_token")) {
     *     QString token = cache.get("api_token").toString();
     * } else {
     *     // 重新登录获取token
     * }
     * @endcode
     *
     * @see get
     */
    bool has(const QString& key) const;

    /**
     * @brief 移除缓存
     * @param key 缓存键
     *
     * @details 删除指定键的缓存
     * - 从内存缓存中删除
     * - 从磁盘缓存中删除
     * - 发出cacheRemoved信号
     *
     * @note 如果键不存在，操作是安全的（不会报错）
     *
     * @example
     * @code
     * // 用户登出时清除用户数据缓存
     * cache.remove("user_profile");
     * cache.remove("user_settings");
     * @endcode
     *
     * @see set, clear
     */
    void remove(const QString& key);

    /**
     * @brief 清空所有缓存
     *
     * @details 删除所有缓存数据
     * - 清空内存缓存
     * - 清空磁盘缓存
     * - 重置统计信息
     * - 发出cacheCleared信号
     *
     * @note 此操作不可恢复
     *
     * @example
     * @code
     * // 应用重置时清空所有缓存
     * cache.clear();
     * @endcode
     *
     * @see remove
     */
    void clear();

    /**
     * @brief 清理过期缓存
     *
     * @details 手动触发清理操作
     * - 删除所有已过期的缓存项
     * - 释放占用的内存和磁盘空间
     * - 更新统计信息
     *
     * @note
     * - 定时器会自动调用此方法
     * - 也可以手动调用进行即时清理
     *
     * @example
     * @code
     * // 手动清理过期缓存
     * cache.cleanup();
     * @endcode
     *
     * @see setCleanupInterval
     */
    void cleanup();

    // ========================================================================
    // 配置管理
    // ========================================================================

    /**
     * @brief 设置最大内存缓存大小
     * @param size 最大大小（字节）
     *
     * @details 限制内存缓存的最大容量
     * - 超过限制时触发LRU淘汰
     * - 默认：10MB
     * - 设置为0表示无限制（不推荐）
     *
     * @note 设置后会立即触发淘汰检查
     *
     * @example
     * @code
     * // 限制内存缓存为20MB
     * cache.setMaxMemoryCacheSize(20 * 1024 * 1024);
     * @endcode
     *
     * @see setMaxDiskCacheSize
     */
    void setMaxMemoryCacheSize(qint64 size);

    /**
     * @brief 设置最大磁盘缓存大小
     * @param size 最大大小（字节）
     *
     * @details 限制磁盘缓存的最大容量
     * - 超过限制时触发LRU淘汰
     * - 默认：100MB
     * - 设置为0表示无限制（不推荐）
     *
     * @note 设置后会立即触发淘汰检查
     *
     * @example
     * @code
     * // 限制磁盘缓存为200MB
     * cache.setMaxDiskCacheSize(200 * 1024 * 1024);
     * @endcode
     *
     * @see setMaxMemoryCacheSize
     */
    void setMaxDiskCacheSize(qint64 size);

    /**
     * @brief 启用/禁用磁盘缓存
     * @param enabled true启用，false禁用
     *
     * @details 控制是否使用磁盘缓存
     * - 启用：数据会持久化到磁盘
     * - 禁用：仅使用内存缓存
     * - 默认：启用
     *
     * @note 禁用时不会删除现有磁盘缓存
     *
     * @example
     * @code
     * // 禁用磁盘缓存（仅使用内存）
     * cache.setDiskCacheEnabled(false);
     * @endcode
     */
    void setDiskCacheEnabled(bool enabled);

    /**
     * @brief 设置清理间隔
     * @param intervalMs 清理间隔（毫秒）
     *
     * @details 设置自动清理过期缓存的时间间隔
     * - 默认：5分钟（300000ms）
     * - 设置为0禁用自动清理
     *
     * @note 清理操作在后台定时执行
     *
     * @example
     * @code
     * // 每分钟清理一次
     * cache.setCleanupInterval(60000);
     * @endcode
     *
     * @see cleanup
     */
    void setCleanupInterval(int intervalMs);

    // ========================================================================
    // 统计信息
    // ========================================================================

    /**
     * @brief 获取缓存项数量
     * @return int 缓存项总数
     *
     * @details 返回当前存储的缓存项数量
     * - 包括内存缓存和磁盘缓存
     * - 包括已过期但未清理的项
     *
     * @example
     * @code
     * int count = cache.count();
     * qDebug() << "缓存项数量:" << count;
     * @endcode
     */
    int count() const;

    /**
     * @brief 获取内存缓存大小
     * @return qint64 内存缓存大小（字节）
     *
     * @details 返回当前内存缓存占用的内存大小
     *
     * @example
     * @code
     * qint64 memSize = cache.memorySize();
     * qDebug() << "内存缓存:" << memSize / 1024 << "KB";
     * @endcode
     *
     * @see diskSize, totalSize
     */
    qint64 memorySize() const;

    /**
     * @brief 获取磁盘缓存大小
     * @return qint64 磁盘缓存大小（字节）
     *
     * @details 返回当前磁盘缓存占用的磁盘空间
     *
     * @example
     * @code
     * qint64 diskSize = cache.diskSize();
     * qDebug() << "磁盘缓存:" << diskSize / 1024 / 1024 << "MB";
     * @endcode
     *
     * @see memorySize, totalSize
     */
    qint64 diskSize() const;

    /**
     * @brief 获取总缓存大小
     * @return qint64 总缓存大小（字节）
     *
     * @details 返回内存缓存和磁盘缓存的总大小
     *
     * @example
     * @code
     * qint64 total = cache.totalSize();
     * qDebug() << "总缓存:" << total / 1024 / 1024 << "MB";
     * @endcode
     *
     * @see memorySize, diskSize
     */
    qint64 totalSize() const;

    /**
     * @brief 获取所有缓存键
     * @return QStringList 所有缓存键列表
     *
     * @details 返回当前所有有效缓存的键列表
     * - 不包括已过期的项
     *
     * @example
     * @code
     * QStringList keys = cache.keys();
     * for (const QString& key : keys) {
     *     qDebug() << "缓存键:" << key;
     * }
     * @endcode
     */
    QStringList keys() const;

    /**
     * @brief 获取统计信息
     * @return QString 格式化的统计信息字符串
     *
     * @details 返回详细的缓存统计信息
     * - 缓存项数量
     * - 内存/磁盘使用情况
     * - 命中率统计
     * - 热点数据
     *
     * @example
     * @code
     * QString stats = cache.statistics();
     * qDebug() << stats;
     * @endcode
     */
    QString statistics() const;

signals:
    /**
     * @brief 缓存更新信号
     * @param key 被更新的缓存键
     *
     * @details 当缓存项被set()时发出
     */
    void cacheUpdated(const QString& key);

    /**
     * @brief 缓存移除信号
     * @param key 被移除的缓存键
     *
     * @details 当缓存项被remove()时发出
     */
    void cacheRemoved(const QString& key);

    /**
     * @brief 缓存清空信号
     *
     * @details 当所有缓存被clear()时发出
     */
    void cacheCleared();

private:
    /**
     * @brief 私有构造函数
     * @param parent 父对象
     *
     * @details 单例模式，禁止外部创建实例
     */
    explicit CacheManager(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     *
     * @details 保存缓存索引并清理资源
     */
    ~CacheManager();

    /**
     * @brief 禁用拷贝构造
     */
    CacheManager(const CacheManager&) = delete;

    /**
     * @brief 禁用赋值操作
     */
    CacheManager& operator=(const CacheManager&) = delete;

    // ========================================================================
    // 磁盘操作（私有方法）
    // ========================================================================

    /**
     * @brief 初始化缓存目录
     *
     * @details 创建磁盘缓存所需的目录结构
     */
    void initializeCacheDirectory();

    /**
     * @brief 获取缓存文件路径
     * @param key 缓存键
     * @return QString 磁盘缓存文件的完整路径
     */
    QString getCacheFilePath(const QString& key) const;

    /**
     * @brief 保存到磁盘
     * @param key 缓存键
     * @param item 缓存项
     * @return bool 成功返回true
     */
    bool saveToDisk(const QString& key, const CacheItem& item);

    /**
     * @brief 从磁盘加载
     * @param key 缓存键
     * @return QVariant 缓存值
     */
    QVariant loadFromDisk(const QString& key) const;

    /**
     * @brief 从磁盘删除
     * @param key 缓存键
     */
    void removeFromDisk(const QString& key);

    /**
     * @brief 加载缓存索引
     *
     * @details 启动时从磁盘加载缓存元数据
     */
    void loadCacheIndex();

    /**
     * @brief 保存缓存索引
     *
     * @details 退出时保存缓存元数据到磁盘
     */
    void saveCacheIndex();

    // ========================================================================
    // 缓存清理（私有方法）
    // ========================================================================

    /**
     * @brief 淘汰内存缓存（内部方法，调用者必须持有锁）
     * @param targetSize 需要释放的目标大小
     * @return QStringList 被移除的缓存键列表
     *
     * @details 使用LRU算法淘汰内存缓存至目标大小
     */
    QStringList evictMemoryCacheInternal(qint64 targetSize);

    /**
     * @brief 淘汰磁盘缓存（内部方法，调用者必须持有锁）
     * @param targetSize 需要释放的目标大小
     * @return QStringList 被移除的缓存键列表
     *
     * @details 使用LRU算法淘汰磁盘缓存至目标大小
     */
    QStringList evictDiskCacheInternal(qint64 targetSize);

    /**
     * @brief 移除缓存（内部方法，调用者必须持有锁）
     * @param key 缓存键
     * @return bool 是否成功移除
     */
    bool removeInternal(const QString& key);

private:
    // ========================================================================
    // 成员变量
    // ========================================================================

    // 缓存存储
    mutable QMap<QString, CacheItem> m_memoryCache; ///< 内存缓存映射
    mutable QMutex m_mutex;                         ///< 线程安全互斥锁

    // 配置
    qint64 m_maxMemoryCacheSize;     ///< 最大内存缓存大小
    qint64 m_maxDiskCacheSize;       ///< 最大磁盘缓存大小
    mutable qint64 m_currentMemorySize; ///< 当前内存缓存大小
    mutable qint64 m_currentDiskSize;   ///< 当前磁盘缓存大小
    bool m_diskCacheEnabled;         ///< 是否启用磁盘缓存

    // 磁盘缓存
    QString m_cacheDir;              ///< 缓存目录路径

    // 定时器
    QTimer* m_cleanupTimer;          ///< 自动清理定时器
};

#endif // CACHEMANAGER_H
