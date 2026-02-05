/**
 * @file LogManager.h
 * @brief Log management header file
 * @details Provides log export and cleanup functionality for all platforms
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef LOGMANAGER_H
#define LOGMANAGER_H

#include <QObject>
#include <QString>
#include <QStringList>

/**
 * @class LogManager
 * @brief Log management class (singleton)
 *
 * @details Provides:
 * - App log and Xray log path management for all platforms
 * - Log size and file count statistics
 * - Log export functionality (ZIP format)
 * - Log cleanup functionality (by days to keep)
 *
 * Platform-specific log paths:
 * - macOS: ~/Library/Application Support/JinGo/logs/ and
 *          ~/Library/Group Containers/group.work.opine.jingo/xray_logs/
 * - iOS: App sandbox Documents/logs/
 * - Windows: %LOCALAPPDATA%\JinGo\logs\ and %LOCALAPPDATA%\JinGo\xray_logs\
 * - Linux: ~/.local/share/JinGo/logs/ and ~/.local/share/JinGo/xray_logs/
 * - Android: Internal storage files/logs/ and files/xray_logs/
 */
class LogManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString totalLogSize READ totalLogSize NOTIFY logSizeChanged)
    Q_PROPERTY(int logFileCount READ logFileCount NOTIFY logSizeChanged)

public:
    /**
     * @brief Get LogManager singleton instance
     * @return LogManager& Global unique instance reference
     */
    static LogManager& instance();

    // ========================================================================
    // Log Paths
    // ========================================================================

    /**
     * @brief Get app log directory path
     * @return QString App log directory path (platform-specific)
     */
    Q_INVOKABLE QString appLogPath() const;

    /**
     * @brief Get Xray log directory path
     * @return QString Xray log directory path (platform-specific)
     */
    Q_INVOKABLE QString xrayLogPath() const;

    // ========================================================================
    // Log Statistics
    // ========================================================================

    /**
     * @brief Get total log size (formatted string)
     * @return QString Formatted size string (e.g., "2.5 MB")
     */
    QString totalLogSize() const;

    /**
     * @brief Get total log file count
     * @return int Number of log files
     */
    int logFileCount() const;

    /**
     * @brief Get list of all log files
     * @return QStringList List of log file paths
     */
    Q_INVOKABLE QStringList logFiles() const;

    // ========================================================================
    // Export Functionality
    // ========================================================================

    /**
     * @brief Export all logs to a ZIP file
     * @param zipPath Destination ZIP file path
     *
     * @details Exports both app logs and Xray logs to a single ZIP file.
     * Emits exportCompleted signal when done.
     */
    Q_INVOKABLE void exportLogsToZip(const QString& zipPath);

    /**
     * @brief Export logs for mobile platforms
     *
     * @details On Android, saves to Downloads folder.
     * On iOS, saves to Documents folder (accessible via Files app).
     * Emits exportCompleted signal when done.
     */
    Q_INVOKABLE void exportLogsForMobile();

    // ========================================================================
    // Cleanup Functionality
    // ========================================================================

    /**
     * @brief Clear logs older than specified days
     * @param daysToKeep Number of days to keep (0 = clear all)
     *
     * @details Clears old log files while keeping recent ones.
     * Emits clearCompleted signal when done.
     */
    Q_INVOKABLE void clearOldLogs(int daysToKeep);

    /**
     * @brief Clear all log files
     *
     * @details Clears all log files from both app and Xray log directories.
     * Emits clearCompleted signal when done.
     */
    Q_INVOKABLE void clearAllLogs();

    /**
     * @brief Refresh log statistics
     *
     * @details Recalculates log size and file count.
     * Emits logSizeChanged signal.
     */
    Q_INVOKABLE void refresh();

signals:
    /**
     * @brief Export completed signal
     * @param success Whether export was successful
     * @param message Success/error message
     */
    void exportCompleted(bool success, const QString& message);

    /**
     * @brief Clear completed signal
     * @param success Whether clear was successful
     * @param message Success/error message
     */
    void clearCompleted(bool success, const QString& message);

    /**
     * @brief Log size changed signal
     */
    void logSizeChanged();

private:
    /**
     * @brief Private constructor (singleton)
     * @param parent Parent object pointer
     */
    explicit LogManager(QObject* parent = nullptr);

    /**
     * @brief Destructor
     */
    ~LogManager() override;

    // Disable copy
    LogManager(const LogManager&) = delete;
    LogManager& operator=(const LogManager&) = delete;

    /**
     * @brief Calculate directory size
     * @param dirPath Directory path
     * @return qint64 Total size in bytes
     */
    qint64 calculateDirSize(const QString& dirPath) const;

    /**
     * @brief Format size to human-readable string
     * @param bytes Size in bytes
     * @return QString Formatted string (e.g., "2.5 MB")
     */
    QString formatSize(qint64 bytes) const;

    /**
     * @brief Get all log files from a directory
     * @param dirPath Directory path
     * @return QStringList List of log file paths
     */
    QStringList getLogFilesInDir(const QString& dirPath) const;

    /**
     * @brief Create a simple ZIP file
     * @param zipPath Output ZIP file path
     * @param files List of file paths to include
     * @param basePath Base path for relative paths in ZIP
     * @return bool Success status
     */
    bool createZipFile(const QString& zipPath, const QStringList& files, const QString& basePath) const;

private:
    mutable qint64 m_cachedSize;
    mutable int m_cachedFileCount;
    mutable bool m_cacheValid;
};

#endif // LOGMANAGER_H
