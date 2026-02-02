// src/core/Logger.h
/**
 * @file Logger.h
 * @brief 日志管理系统头文件
 * @details 提供完整的日志管理功能，包括：
 *          - 多级别日志（Debug/Info/Warning/Error/Critical）
 *          - 文件输出和控制台输出
 *          - 日志文件自动轮转和清理
 *          - 线程安全的日志记录
 *          - 彩色控制台输出
 *          - Qt消息系统集成
 *          - 便捷的日志宏定义
 * @author Your Name
 * @date 2024
 */

#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QFile>
#include <QTextStream>
#include <QMutex>
#include <QDateTime>
#include <QElapsedTimer>

/**
 * @class Logger
 * @brief 日志管理器类（单例模式）
 * @details 管理应用程序的所有日志输出，提供以下功能：
 *
 *          主要特性：
 *          - 单例模式：全局唯一实例，通过Logger::instance()访问
 *          - 多级别日志：支持5个级别（Debug、Info、Warning、Error、Critical）
 *          - 双重输出：可同时输出到控制台和文件
 *          - 自动轮转：文件大小超过限制时自动创建新文件
 *          - 自动清理：保留指定数量的日志文件，自动删除过期文件
 *          - 线程安全：使用互斥锁保护，支持多线程环境
 *          - 彩色输出：控制台输出支持ANSI颜色（Linux/macOS/Windows 10+）
 *          - 详细信息：记录时间戳、线程ID、文件位置等
 *          - 信号通知：发出信号供UI实时显示日志
 *
 *          使用示例：
 *          @code
 *          // 初始化日志系统
 *          Logger::instance().initialize();
 *
 *          // 使用便捷方法记录日志
 *          Logger::instance().info("Application started");
 *          Logger::instance().warning("Low memory warning");
 *          Logger::instance().error("Failed to connect");
 *
 *          // 或使用宏（推荐，会自动记录文件名和行号）
 *          LOG_INFO("User logged in");
 *          LOG_ERROR_F("Connection failed: %1", errorMsg);
 *
 *          // 作用域日志（自动记录进入和退出时间）
 *          LOG_SCOPE("ProcessData");
 *          @endcode
 */
class Logger : public QObject
{
    Q_OBJECT

public:
    /**
     * @enum LogLevel
     * @brief 日志级别枚举
     * @details 级别从低到高排列，设置日志级别后，只有该级别及更高级别的日志会被记录
     */
    enum LogLevel {
        Debug = 0,      ///< 调试信息：详细的调试信息，用于开发和调试
        Info = 1,       ///< 一般信息：重要的运行时信息
        Warning = 2,    ///< 警告信息：可能的问题，但不影响运行
        Error = 3,      ///< 错误信息：发生错误但程序可以继续
        Critical = 4    ///< 严重错误：严重问题，可能导致程序崩溃
    };
    Q_ENUM(LogLevel)

    /**
     * @brief 获取Logger单例实例
     * @return Logger& Logger的全局唯一实例引用
     * @details 线程安全的单例实现，首次调用时创建实例
     */
    static Logger& instance();

    /**
     * @brief 初始化日志系统
     * @param logFilePath 日志文件路径，为空则自动生成
     * @return bool 初始化是否成功
     * @details 初始化过程：
     *          1. 如果未指定路径，则在AppDataLocation/logs下创建日志文件
     *          2. 日志文件名格式：jingo_YYYYMMDD_HHMMSS.log
     *          3. 创建必要的目录结构
     *          4. 打开文件并写入启动信息
     *          5. 清理超过保留数量的旧日志文件
     */
    bool initialize(const QString& logFilePath = QString());

    /**
     * @brief 关闭日志系统
     * @details 写入关闭信息并关闭日志文件，释放资源
     */
    void shutdown();

    /**
     * @brief 设置日志级别
     * @param level 日志级别
     * @details 只有大于等于此级别的日志才会被记录
     *          例如设置为Warning后，Debug和Info级别的日志将被忽略
     */
    void setLogLevel(LogLevel level);

    /**
     * @brief 获取当前日志级别
     * @return LogLevel 当前的日志级别
     */
    LogLevel logLevel() const;

    /**
     * @brief 设置是否输出到控制台
     * @param enabled true启用控制台输出，false禁用
     * @details 控制台输出支持彩色显示（需要终端支持ANSI颜色）
     */
    void setConsoleOutput(bool enabled);

    /**
     * @brief 设置是否输出到文件
     * @param enabled true启用文件输出，false禁用
     */
    void setFileOutput(bool enabled);

    /**
     * @brief 获取是否启用控制台输出
     * @return bool true表示已启用
     */
    bool consoleOutputEnabled() const;

    /**
     * @brief 获取是否启用文件输出
     * @return bool true表示已启用
     */
    bool fileOutputEnabled() const;

    /**
     * @brief 记录日志
     * @param level 日志级别
     * @param message 日志消息
     * @param file 源文件名（可选，通常使用__FILE__宏）
     * @param line 行号（可选，通常使用__LINE__宏）
     * @param function 函数名（可选，通常使用__FUNCTION__宏）
     * @details 这是核心的日志记录方法，会：
     *          1. 检查日志级别是否符合要求
     *          2. 格式化日志消息（添加时间戳、线程ID等）
     *          3. 根据设置输出到控制台和/或文件
     *          4. 检查文件大小，必要时进行轮转
     *          5. 发出logMessageReceived信号
     */
    void log(LogLevel level, const QString& message,
             const char* file = nullptr, int line = 0, const char* function = nullptr);

    /**
     * @brief 便捷方法：记录调试日志
     * @param message 日志消息
     * @param file 源文件名（可选）
     * @param line 行号（可选）
     */
    void debug(const QString& message, const char* file = nullptr, int line = 0);

    /**
     * @brief 便捷方法：记录信息日志
     * @param message 日志消息
     * @param file 源文件名（可选）
     * @param line 行号（可选）
     */
    void info(const QString& message, const char* file = nullptr, int line = 0);

    /**
     * @brief 便捷方法：记录警告日志
     * @param message 日志消息
     * @param file 源文件名（可选）
     * @param line 行号（可选）
     */
    void warning(const QString& message, const char* file = nullptr, int line = 0);

    /**
     * @brief 便捷方法：记录错误日志
     * @param message 日志消息
     * @param file 源文件名（可选）
     * @param line 行号（可选）
     */
    void error(const QString& message, const char* file = nullptr, int line = 0);

    /**
     * @brief 便捷方法：记录严重错误日志
     * @param message 日志消息
     * @param file 源文件名（可选）
     * @param line 行号（可选）
     */
    void critical(const QString& message, const char* file = nullptr, int line = 0);

    /**
     * @brief 获取日志文件路径
     * @return QString 当前日志文件的完整路径
     */
    QString logFilePath() const;

    /**
     * @brief 清空日志文件
     * @details 关闭并重新打开文件，清除所有内容，然后写入清空标记
     */
    void clearLogFile();

    /**
     * @brief 获取是否已初始化
     * @return bool true表示已初始化
     */
    bool isInitialized() const;

    /**
     * @brief 设置日志文件最大大小
     * @param size 最大大小（字节），默认10MB
     * @details 当日志文件超过此大小时，会自动进行轮转（创建新文件）
     */
    void setMaxFileSize(qint64 size);

    /**
     * @brief 设置保留的最大日志文件数量
     * @param count 最大数量，默认5
     * @details 超过此数量的旧日志文件会被自动删除
     */
    void setMaxFileCount(int count);

    /**
     * @brief 获取日志目录路径
     * @return QString 日志目录的完整路径
     * @details 各平台路径：
     *          - Windows: %APPDATA%/Opine Work/JinGo/logs/
     *          - macOS: ~/Library/Application Support/JinGo/logs/
     *          - iOS: <App Sandbox>/Library/Application Support/JinGo/logs/
     *          - Linux: ~/.local/share/JinGo/logs/
     *          - Android: /data/data/work.opine.jingo/files/logs/
     */
    Q_INVOKABLE QString logDirectory() const;

    /**
     * @brief 清理所有平台的日志文件
     * @details 清理主应用日志和平台特定日志：
     *          - iOS: 同时清理 App Group 中的 Extension 日志
     *          - Android: 清理 JNI 日志文件
     */
    Q_INVOKABLE void cleanupAllPlatformLogs();

    /**
     * @brief 获取所有日志文件列表
     * @return QStringList 所有日志文件的路径列表
     */
    Q_INVOKABLE QStringList allLogFiles() const;

signals:
    /**
     * @brief 日志消息信号
     * @param level 日志级别
     * @param message 日志消息
     * @details 每次记录日志时都会发出此信号，可用于实时更新UI显示日志
     */
    void logMessageReceived(LogLevel level, const QString& message);

private:
    /**
     * @brief 私有构造函数（单例模式）
     * @param parent 父对象指针
     * @details 初始化成员变量，在Windows上配置UTF-8和ANSI颜色支持
     */
    explicit Logger(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     * @details 调用shutdown()清理资源
     */
    ~Logger() override;

    // 禁用拷贝构造和赋值操作（单例模式）
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

    /**
     * @brief 格式化日志消息
     * @param level 日志级别
     * @param message 原始消息
     * @param file 源文件名
     * @param line 行号
     * @param function 函数名
     * @return QString 格式化后的完整日志消息
     * @details 格式：[时间戳] [级别] [线程ID] 消息 (文件:行号) [函数名]
     *          例如：[2024-01-15 10:30:45.123] [INFO    ] [0x12345678] Application started
     */
    QString formatMessage(LogLevel level, const QString& message,
                          const char* file, int line, const char* function);

    /**
     * @brief 日志级别转字符串
     * @param level 日志级别
     * @return QString 级别字符串（DEBUG/INFO/WARN/ERROR/CRITICAL）
     */
    QString logLevelToString(LogLevel level) const;

    /**
     * @brief 写入文件
     * @param message 格式化后的日志消息
     * @details 将消息写入日志文件并立即刷新缓冲区
     */
    void writeToFile(const QString& message);

    /**
     * @brief 写入控制台
     * @param level 日志级别
     * @param message 格式化后的日志消息
     * @details 根据日志级别使用不同颜色输出到stdout或stderr，
     *          错误级别（Error/Critical）输出到stderr，其他输出到stdout
     */
    void writeToConsole(LogLevel level, const QString& message);

    /**
     * @brief 日志文件轮转
     * @details 轮转过程：
     *          1. 关闭当前日志文件
     *          2. 将当前文件重命名为带时间戳的文件
     *          3. 创建新的日志文件
     *          4. 写入轮转标记
     *          5. 清理超过数量限制的旧文件
     */
    void rotateLogFile();

    /**
     * @brief 清理旧日志文件
     * @details 扫描日志目录，删除超过保留数量的最旧日志文件，
     *          不会删除当前正在使用的日志文件
     */
    void cleanupOldLogFiles();

private:
    // ========== 成员变量 ==========

    QFile m_logFile;              ///< 日志文件对象
    QTextStream m_logStream;      ///< 文本流，用于写入日志文件
    QString m_logFilePath;        ///< 当前日志文件的完整路径
    mutable QMutex m_mutex;       ///< 互斥锁，保证线程安全

    LogLevel m_logLevel;          ///< 当前日志级别
    bool m_consoleOutput;         ///< 是否启用控制台输出
    bool m_fileOutput;            ///< 是否启用文件输出
    bool m_initialized;           ///< 是否已初始化

    qint64 m_maxFileSize;         ///< 日志文件最大大小（字节）
    int m_maxFileCount;           ///< 保留的最大日志文件数量
};

// ============================================================================
// 全局日志处理函数
// ============================================================================

/**
 * @brief Qt消息处理函数
 * @param type Qt消息类型
 * @param context 消息上下文（包含文件名、行号、函数名等）
 * @param msg 消息内容
 * @details 将Qt的日志系统（qDebug/qInfo/qWarning/qCritical）重定向到Logger，
 *          实现统一的日志管理。处理QtFatalMsg时会终止程序。
 */
void customMessageHandler(QtMsgType type, const QMessageLogContext& context, const QString& msg);

/**
 * @brief 安装自定义消息处理器
 * @details 调用此函数后，所有通过qDebug/qInfo/qWarning/qCritical输出的消息
 *          都会通过Logger进行记录，实现统一的日志格式和输出控制
 */
void installLoggerMessageHandler();

// ============================================================================
// 便捷宏定义
// ============================================================================

/**
 * @def LOG_DEBUG
 * @brief 调试日志宏
 * @param msg 日志消息字符串
 * @details 自动传入文件名和行号，例如：LOG_DEBUG("Variable x = 5")
 *          在 Release 模式下（定义了 QT_NO_DEBUG 或 NDEBUG）不输出，与 qDebug() 行为一致
 */
#if defined(QT_NO_DEBUG) || defined(NDEBUG)
    #define LOG_DEBUG(msg)    do {} while (0)
#else
    #define LOG_DEBUG(msg)    Logger::instance().debug(msg, __FILE__, __LINE__)
#endif

/**
 * @def LOG_INFO
 * @brief 信息日志宏
 * @param msg 日志消息字符串
 * @details 自动传入文件名和行号，例如：LOG_INFO("User logged in")
 */
#define LOG_INFO(msg)     Logger::instance().info(msg, __FILE__, __LINE__)

/**
 * @def LOG_WARNING
 * @brief 警告日志宏
 * @param msg 日志消息字符串
 * @details 自动传入文件名和行号，例如：LOG_WARNING("Low memory")
 */
#define LOG_WARNING(msg)  Logger::instance().warning(msg, __FILE__, __LINE__)

/**
 * @def LOG_ERROR
 * @brief 错误日志宏
 * @param msg 日志消息字符串
 * @details 自动传入文件名和行号，例如：LOG_ERROR("Connection failed")
 */
#define LOG_ERROR(msg)    Logger::instance().error(msg, __FILE__, __LINE__)

/**
 * @def LOG_CRITICAL
 * @brief 严重错误日志宏
 * @param msg 日志消息字符串
 * @details 自动传入文件名和行号，例如：LOG_CRITICAL("Database corrupted")
 */
#define LOG_CRITICAL(msg) Logger::instance().critical(msg, __FILE__, __LINE__)

// 格式化日志宏（支持QString::arg）

/**
 * @def LOG_DEBUG_F
 * @brief 格式化调试日志宏
 * @param fmt 格式字符串（支持%1、%2等占位符）
 * @param ... 可变参数列表
 * @details 使用示例：LOG_DEBUG_F("Value = %1, Status = %2", value, status)
 *          在 Release 模式下（定义了 QT_NO_DEBUG 或 NDEBUG）不输出，与 qDebug() 行为一致
 */
#if defined(QT_NO_DEBUG) || defined(NDEBUG)
    #define LOG_DEBUG_F(fmt, ...)    do {} while (0)
#else
    #define LOG_DEBUG_F(fmt, ...)    LOG_DEBUG(QString(fmt).arg(__VA_ARGS__))
#endif

/**
 * @def LOG_INFO_F
 * @brief 格式化信息日志宏
 * @param fmt 格式字符串
 * @param ... 可变参数列表
 * @details 使用示例：LOG_INFO_F("User %1 logged in from %2", username, ip)
 */
#define LOG_INFO_F(fmt, ...)     LOG_INFO(QString(fmt).arg(__VA_ARGS__))

/**
 * @def LOG_WARNING_F
 * @brief 格式化警告日志宏
 * @param fmt 格式字符串
 * @param ... 可变参数列表
 * @details 使用示例：LOG_WARNING_F("Memory usage: %1%", percentage)
 */
#define LOG_WARNING_F(fmt, ...)  LOG_WARNING(QString(fmt).arg(__VA_ARGS__))

/**
 * @def LOG_ERROR_F
 * @brief 格式化错误日志宏
 * @param fmt 格式字符串
 * @param ... 可变参数列表
 * @details 使用示例：LOG_ERROR_F("Failed to open file: %1", fileName)
 */
#define LOG_ERROR_F(fmt, ...)    LOG_ERROR(QString(fmt).arg(__VA_ARGS__))

/**
 * @def LOG_CRITICAL_F
 * @brief 格式化严重错误日志宏
 * @param fmt 格式字符串
 * @param ... 可变参数列表
 * @details 使用示例：LOG_CRITICAL_F("Fatal error: %1", errorMsg)
 */
#define LOG_CRITICAL_F(fmt, ...) LOG_CRITICAL(QString(fmt).arg(__VA_ARGS__))

/**
 * @def INIT_LOGGER
 * @brief 初始化日志系统并记录应用启动信息
 * @param appName 应用程序名称
 * @details 使用示例：INIT_LOGGER("JinGo VPN")
 *          会自动记录应用名称、版本号、操作系统等信息
 */
#define INIT_LOGGER(appName) \
    do { \
        Logger::instance().initialize(); \
        LOG_INFO(QString("========== %1 Started ==========").arg(appName)); \
        LOG_INFO(QString("Version: %1").arg(QCoreApplication::applicationVersion())); \
        LOG_INFO(QString("Platform: %1").arg(QSysInfo::prettyProductName())); \
    } while(0)

/**
 * @def LOG_IF
 * @brief 条件日志宏
 * @param condition 条件表达式
 * @param level 日志级别（Debug/Info/Warning/Error/Critical）
 * @param msg 日志消息
 * @details 使用示例：LOG_IF(errorCode != 0, Error, "Operation failed")
 */
#define LOG_IF(condition, level, msg) \
    do { \
        if (condition) { \
            Logger::instance().log(Logger::level, msg, __FILE__, __LINE__); \
        } \
    } while(0)

/**
 * @def LOG_SCOPE
 * @brief 作用域日志宏
 * @param name 作用域名称
 * @details 在作用域开始时记录进入，结束时记录退出和耗时
 *          使用示例：
 *          @code
 *          void processData() {
 *              LOG_SCOPE("processData");
 *              // ... 处理逻辑 ...
 *          } // 自动记录 "Leaving processData (took 123 ms)"
 *          @endcode
 *          在 Release 模式下（定义了 QT_NO_DEBUG 或 NDEBUG）不输出，与 qDebug() 行为一致
 */
#if defined(QT_NO_DEBUG) || defined(NDEBUG)
    #define LOG_SCOPE(name)    do {} while (0)
#else
    #define LOG_SCOPE(name)    ScopeLogger __scope_logger__(name, __FILE__, __LINE__)
#endif

// ============================================================================
// 辅助类：作用域日志
// ============================================================================

/**
 * @class ScopeLogger
 * @brief 作用域日志辅助类
 * @details RAII模式的日志记录类，在构造时记录进入作用域，
 *          在析构时记录离开作用域和执行耗时。
 *          通常不直接使用，而是通过LOG_SCOPE宏使用。
 *
 *          工作原理：
 *          1. 构造时启动计时器并记录"进入"日志
 *          2. 析构时计算耗时并记录"离开"日志
 *          3. 利用C++的RAII特性自动管理生命周期
 */
class ScopeLogger
{
public:
    /**
     * @brief 构造函数
     * @param name 作用域名称
     * @param file 源文件名
     * @param line 行号
     * @details 记录进入作用域的日志并启动计时器
     */
    ScopeLogger(const QString& name, const char* file, int line)
        : m_name(name)
        , m_file(file)
        , m_line(line)
    {
        Logger::instance().debug(QString(">>> Entering %1").arg(m_name), m_file, m_line);
        m_timer.start();
    }

    /**
     * @brief 析构函数
     * @details 记录离开作用域的日志和执行耗时
     */
    ~ScopeLogger()
    {
        qint64 elapsed = m_timer.elapsed();
        Logger::instance().debug(
            QString("<<< Leaving %1 (took %2 ms)").arg(m_name).arg(elapsed),
            m_file, m_line
        );
    }

private:
    QString m_name;           ///< 作用域名称
    const char* m_file;       ///< 源文件名
    int m_line;               ///< 行号
    QElapsedTimer m_timer;    ///< 计时器，用于测量执行时间
};

#endif // LOGGER_H