/**
 * @file FileUtils.h
 * @brief 文件工具类头文件
 * @details 提供文件和目录操作的实用工具函数，包括读写、复制、移动和路径管理
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef FILEUTILS_H
#define FILEUTILS_H

#include <QString>
#include <QStringList>

/**
 * @class FileUtils
 * @brief 文件和目录操作工具类
 *
 * @details 提供常用的文件系统操作功能，包括：
 * - 文件读写（文本和二进制）
 * - 文件和目录管理（创建、删除、复制、移动）
 * - 文件信息查询（大小、扩展名、存在性）
 * - 路径处理（提取文件名、目录路径）
 * - 目录遍历（列出文件）
 * - 应用程序路径管理（数据、配置、日志、缓存）
 *
 * 主要功能：
 * - 文件IO：读写文本和二进制文件
 * - 文件操作：复制、移动、删除文件和目录
 * - 路径工具：提取和处理文件路径
 * - 应用目录：获取标准应用数据目录
 *
 * 使用场景：
 * - 配置管理：读写配置文件
 * - 日志记录：管理日志文件
 * - 缓存管理：清理和管理缓存文件
 * - 数据存储：保存用户数据和应用状态
 *
 * @note
 * - 所有方法都是静态的，无需实例化
 * - 线程安全：大部分方法是线程安全的（依赖Qt的文件API）
 * - 工具类：禁止实例化和拷贝
 * - 错误处理：失败时返回false或空值
 *
 * @example 使用示例
 * @code
 * // 读写文本文件
 * QString content = FileUtils::readTextFile("/path/to/file.txt");
 * bool ok = FileUtils::writeTextFile("/path/to/output.txt", content);
 *
 * // 检查文件存在
 * if (FileUtils::fileExists("/path/to/file.txt")) {
 *     qint64 size = FileUtils::fileSize("/path/to/file.txt");
 * }
 *
 * // 获取应用目录
 * QString configDir = FileUtils::configPath();
 * QString logDir = FileUtils::logPath();
 * @endcode
 */
class FileUtils
{
public:
    // ========================================================================
    // 文件读写
    // ========================================================================

    /**
     * @brief 读取文本文件内容
     * @param filePath 文件路径（绝对或相对路径）
     * @return QString 文件内容，失败返回空字符串
     *
     * @details 读取文本文件的全部内容
     * - 自动检测文件编码（UTF-8优先）
     * - 适用于配置文件、日志文件等
     * - 大文件可能消耗大量内存
     *
     * @note
     * - 如果文件不存在或无读取权限，返回空字符串
     * - 建议用于小于10MB的文件
     *
     * @example
     * @code
     * QString config = FileUtils::readTextFile("/etc/config.json");
     * if (!config.isEmpty()) {
     *     // 解析配置
     * }
     * @endcode
     *
     * @see writeTextFile, readBinaryFile
     */
    static QString readTextFile(const QString& filePath);

    /**
     * @brief 写入文本文件
     * @param filePath 文件路径（绝对或相对路径）
     * @param content 要写入的文本内容
     * @return bool 成功返回true，失败返回false
     *
     * @details 将文本内容写入文件
     * - 使用UTF-8编码
     * - 如果文件已存在，会被覆盖
     * - 如果目录不存在，写入会失败
     *
     * @note
     * - 需要有写入权限
     * - 建议先检查目录是否存在
     *
     * @example
     * @code
     * QString config = "{\"key\": \"value\"}";
     * if (FileUtils::writeTextFile("/path/config.json", config)) {
     *     qDebug() << "配置已保存";
     * }
     * @endcode
     *
     * @see readTextFile, writeBinaryFile
     */
    static bool writeTextFile(const QString& filePath, const QString& content);

    /**
     * @brief 读取二进制文件
     * @param filePath 文件路径（绝对或相对路径）
     * @return QByteArray 文件内容，失败返回空数组
     *
     * @details 读取二进制文件的全部内容
     * - 适用于图片、压缩包、加密数据等
     * - 不进行任何编码转换
     * - 大文件可能消耗大量内存
     *
     * @note
     * - 如果文件不存在或无读取权限，返回空数组
     * - 建议用于小于50MB的文件
     *
     * @example
     * @code
     * QByteArray data = FileUtils::readBinaryFile("/path/image.png");
     * if (!data.isEmpty()) {
     *     // 处理二进制数据
     * }
     * @endcode
     *
     * @see writeBinaryFile, readTextFile
     */
    static QByteArray readBinaryFile(const QString& filePath);

    /**
     * @brief 写入二进制文件
     * @param filePath 文件路径（绝对或相对路径）
     * @param data 要写入的二进制数据
     * @return bool 成功返回true，失败返回false
     *
     * @details 将二进制数据写入文件
     * - 不进行任何编码转换
     * - 如果文件已存在，会被覆盖
     * - 适用于保存图片、加密数据等
     *
     * @note 需要有写入权限
     *
     * @example
     * @code
     * QByteArray imageData = downloadImage();
     * FileUtils::writeBinaryFile("/path/avatar.png", imageData);
     * @endcode
     *
     * @see readBinaryFile, writeTextFile
     */
    static bool writeBinaryFile(const QString& filePath, const QByteArray& data);

    // ========================================================================
    // 文件和目录检查
    // ========================================================================

    /**
     * @brief 检查文件是否存在
     * @param filePath 文件路径
     * @return bool 存在返回true，不存在返回false
     *
     * @details 检查指定路径的文件是否存在
     * - 不检查是否是目录
     * - 不检查读写权限
     *
     * @note 如果路径是目录，也返回true
     *
     * @example
     * @code
     * if (FileUtils::fileExists("/path/to/file.txt")) {
     *     QString content = FileUtils::readTextFile("/path/to/file.txt");
     * }
     * @endcode
     *
     * @see dirExists
     */
    static bool fileExists(const QString& filePath);

    /**
     * @brief 检查目录是否存在
     * @param dirPath 目录路径
     * @return bool 存在返回true，不存在返回false
     *
     * @details 检查指定路径的目录是否存在
     * - 仅检查目录，不检查文件
     * - 不检查读写权限
     *
     * @example
     * @code
     * if (!FileUtils::dirExists("/path/to/dir")) {
     *     FileUtils::createDir("/path/to/dir");
     * }
     * @endcode
     *
     * @see fileExists, createDir
     */
    static bool dirExists(const QString& dirPath);

    // ========================================================================
    // 文件和目录操作
    // ========================================================================

    /**
     * @brief 创建目录
     * @param dirPath 目录路径
     * @return bool 成功返回true，失败返回false
     *
     * @details 创建目录，如果父目录不存在会自动创建
     * - 等价于 mkdir -p
     * - 如果目录已存在，返回true
     * - 递归创建所有父目录
     *
     * @note 需要有创建权限
     *
     * @example
     * @code
     * if (FileUtils::createDir("/app/data/logs")) {
     *     qDebug() << "日志目录已创建";
     * }
     * @endcode
     *
     * @see dirExists, deleteDir
     */
    static bool createDir(const QString& dirPath);

    /**
     * @brief 删除文件
     * @param filePath 文件路径
     * @return bool 成功返回true，失败返回false
     *
     * @details 删除指定的文件
     * - 仅删除文件，不删除目录
     * - 如果文件不存在，返回false
     *
     * @note
     * - 需要有删除权限
     * - 删除操作不可恢复
     *
     * @example
     * @code
     * if (FileUtils::deleteFile("/tmp/cache.dat")) {
     *     qDebug() << "缓存文件已删除";
     * }
     * @endcode
     *
     * @see deleteDir, fileExists
     */
    static bool deleteFile(const QString& filePath);

    /**
     * @brief 删除目录
     * @param dirPath 目录路径
     * @return bool 成功返回true，失败返回false
     *
     * @details 递归删除目录及其所有内容
     * - 等价于 rm -rf
     * - 删除目录下的所有文件和子目录
     * - 如果目录不存在，返回false
     *
     * @warning
     * - 此操作不可恢复，请谨慎使用
     * - 确保路径正确，避免误删重要数据
     *
     * @example
     * @code
     * if (FileUtils::deleteDir("/tmp/cache")) {
     *     qDebug() << "缓存目录已清空";
     * }
     * @endcode
     *
     * @see deleteFile, createDir
     */
    static bool deleteDir(const QString& dirPath);

    /**
     * @brief 复制文件
     * @param sourcePath 源文件路径
     * @param destPath 目标文件路径
     * @return bool 成功返回true，失败返回false
     *
     * @details 将文件从源路径复制到目标路径
     * - 如果目标文件已存在，会被覆盖
     * - 保留文件属性和时间戳
     * - 源文件保持不变
     *
     * @note
     * - 需要有读取源文件和写入目标位置的权限
     * - 目标目录必须已存在
     *
     * @example
     * @code
     * if (FileUtils::copyFile("/path/config.json", "/backup/config.json")) {
     *     qDebug() << "配置文件已备份";
     * }
     * @endcode
     *
     * @see moveFile, deleteFile
     */
    static bool copyFile(const QString& sourcePath, const QString& destPath);

    /**
     * @brief 移动文件
     * @param sourcePath 源文件路径
     * @param destPath 目标文件路径
     * @return bool 成功返回true，失败返回false
     *
     * @details 将文件从源路径移动到目标路径
     * - 如果目标文件已存在，会被覆盖
     * - 源文件会被删除
     * - 可用于重命名文件
     *
     * @note
     * - 需要有读取源文件和写入目标位置的权限
     * - 目标目录必须已存在
     * - 跨文件系统移动可能较慢
     *
     * @example
     * @code
     * // 移动文件
     * FileUtils::moveFile("/tmp/data.db", "/app/data/data.db");
     *
     * // 重命名文件
     * FileUtils::moveFile("/app/old_name.txt", "/app/new_name.txt");
     * @endcode
     *
     * @see copyFile, deleteFile
     */
    static bool moveFile(const QString& sourcePath, const QString& destPath);

    // ========================================================================
    // 文件信息
    // ========================================================================

    /**
     * @brief 获取文件大小
     * @param filePath 文件路径
     * @return qint64 文件大小（字节），失败返回-1
     *
     * @details 获取文件的字节大小
     * - 不适用于目录
     * - 如果文件不存在，返回-1
     *
     * @example
     * @code
     * qint64 size = FileUtils::fileSize("/path/file.dat");
     * if (size > 0) {
     *     qDebug() << "文件大小:" << size << "字节";
     * }
     * @endcode
     *
     * @see fileExists
     */
    static qint64 fileSize(const QString& filePath);

    /**
     * @brief 获取文件扩展名
     * @param filePath 文件路径
     * @return QString 扩展名（不含点），无扩展名返回空字符串
     *
     * @details 提取文件的扩展名
     * - 返回不含点的扩展名
     * - 例如："file.txt" 返回 "txt"
     * - 例如："archive.tar.gz" 返回 "gz"
     *
     * @example
     * @code
     * QString ext = FileUtils::fileExtension("/path/image.png");
     * // ext = "png"
     * @endcode
     *
     * @see fileName
     */
    static QString fileExtension(const QString& filePath);

    /**
     * @brief 获取文件名（不含路径）
     * @param filePath 文件路径
     * @return QString 文件名（含扩展名）
     *
     * @details 从完整路径中提取文件名
     * - 包含扩展名
     * - 例如："/path/to/file.txt" 返回 "file.txt"
     *
     * @example
     * @code
     * QString name = FileUtils::fileName("/home/user/document.pdf");
     * // name = "document.pdf"
     * @endcode
     *
     * @see dirPath, fileExtension
     */
    static QString fileName(const QString& filePath);

    /**
     * @brief 获取目录路径（不含文件名）
     * @param filePath 文件路径
     * @return QString 目录路径
     *
     * @details 从完整路径中提取目录部分
     * - 不含文件名
     * - 例如："/path/to/file.txt" 返回 "/path/to"
     *
     * @example
     * @code
     * QString dir = FileUtils::dirPath("/home/user/document.pdf");
     * // dir = "/home/user"
     * @endcode
     *
     * @see fileName
     */
    static QString dirPath(const QString& filePath);

    // ========================================================================
    // 目录遍历
    // ========================================================================

    /**
     * @brief 列出目录下的文件
     * @param dirPath 目录路径
     * @param filters 文件过滤器列表（例如：["*.txt", "*.json"]），空列表表示不过滤
     * @return QStringList 文件路径列表，失败返回空列表
     *
     * @details 列出目录下的所有文件（不递归子目录）
     * - 仅返回文件，不包含子目录
     * - 支持通配符过滤（*.txt, *.json等）
     * - 返回相对路径或绝对路径（取决于输入）
     *
     * @note
     * - 不递归遍历子目录
     * - 需要有读取目录的权限
     *
     * @example
     * @code
     * // 列出所有文件
     * QStringList files = FileUtils::listFiles("/path/to/dir");
     *
     * // 仅列出文本文件
     * QStringList textFiles = FileUtils::listFiles("/path/to/dir", {"*.txt", "*.md"});
     * @endcode
     *
     * @see dirExists
     */
    static QStringList listFiles(const QString& dirPath, const QStringList& filters = QStringList());

    // ========================================================================
    // 应用程序路径
    // ========================================================================

    /**
     * @brief 获取应用数据目录
     * @return QString 应用数据目录路径
     *
     * @details 获取应用程序的数据存储目录
     * - Windows: C:/Users/用户名/AppData/Local/JinGo
     * - macOS: ~/Library/Application Support/JinGo
     * - Linux: ~/.local/share/JinGo
     * - 如果目录不存在会自动创建
     *
     * @note 用于存储应用程序运行时数据
     *
     * @example
     * @code
     * QString dataPath = FileUtils::appDataPath();
     * QString dbPath = dataPath + "/database.db";
     * @endcode
     *
     * @see configPath, logPath, cachePath
     */
    static QString appDataPath();

    /**
     * @brief 获取配置文件目录
     * @return QString 配置文件目录路径
     *
     * @details 获取应用程序的配置文件存储目录
     * - Windows: C:/Users/用户名/AppData/Local/JinGo/config
     * - macOS: ~/Library/Preferences/JinGo
     * - Linux: ~/.config/JinGo
     * - 如果目录不存在会自动创建
     *
     * @note 用于存储配置文件（settings.json等）
     *
     * @example
     * @code
     * QString configDir = FileUtils::configPath();
     * QString configFile = configDir + "/settings.json";
     * @endcode
     *
     * @see appDataPath, logPath
     */
    static QString configPath();

    /**
     * @brief 获取日志文件目录
     * @return QString 日志文件目录路径
     *
     * @details 获取应用程序的日志文件存储目录
     * - 通常在应用数据目录下的logs子目录
     * - 如果目录不存在会自动创建
     *
     * @note 用于存储应用程序日志文件
     *
     * @example
     * @code
     * QString logDir = FileUtils::logPath();
     * QString logFile = logDir + "/app.log";
     * @endcode
     *
     * @see appDataPath, configPath
     */
    static QString logPath();

    /**
     * @brief 获取缓存目录
     * @return QString 缓存目录路径
     *
     * @details 获取应用程序的缓存文件存储目录
     * - Windows: C:/Users/用户名/AppData/Local/JinGo/cache
     * - macOS: ~/Library/Caches/JinGo
     * - Linux: ~/.cache/JinGo
     * - 如果目录不存在会自动创建
     *
     * @note 用于存储临时缓存文件，可以安全删除
     *
     * @example
     * @code
     * QString cacheDir = FileUtils::cachePath();
     * QString iconCache = cacheDir + "/icons/";
     * @endcode
     *
     * @see appDataPath, deleteDir
     */
    static QString cachePath();

    // ========================================================================
    // GeoIP 数据文件路径
    // ========================================================================

    /**
     * @brief 获取 GeoIP 数据文件目录
     * @return QString GeoIP 数据文件目录路径
     *
     * @details 获取 geoip.dat 和 geosite.dat 文件所在的目录
     * - macOS: App Bundle Resources/dat 或 Application Support
     * - iOS: App Bundle 根目录
     * - Android: App files 目录（从 assets 自动复制）
     * - Windows/Linux: 可执行文件目录的 dat 子目录
     * - 自动处理文件从 bundle/assets 到运行时目录的复制
     *
     * @note
     * - 首次调用时会自动从 bundle/assets 复制文件（如需要）
     * - 返回的目录已确保存在
     * - geoip.dat 和 geosite.dat 文件应该在此目录中
     *
     * @example
     * @code
     * QString datDir = FileUtils::geoipDataPath();
     * QString geoipFile = datDir + "/geoip.dat";
     * QString geositeFile = datDir + "/geosite.dat";
     * @endcode
     *
     * @see ensureGeoipFiles
     */
    static QString geoipDataPath();

    /**
     * @brief 确保 GeoIP 文件存在并返回目录路径
     * @return QString GeoIP 文件所在目录，失败返回空字符串
     *
     * @details 确保 geoip.dat 和 geosite.dat 文件已从资源复制到运行时目录
     * - 检查文件是否已存在于目标目录
     * - 如果不存在，从 App Bundle/Assets 复制
     * - 验证文件复制成功
     *
     * @note 此函数会在首次调用时进行文件复制，可能需要一些时间
     *
     * @example
     * @code
     * QString datDir = FileUtils::ensureGeoipFiles();
     * if (!datDir.isEmpty()) {
     *     qDebug() << "GeoIP 文件准备就绪";
     * }
     * @endcode
     *
     * @see geoipDataPath
     */
    static QString ensureGeoipFiles();

private:
    /**
     * @brief 私有构造函数
     * @details 工具类，禁止实例化
     */
    FileUtils() = delete;

    /**
     * @brief 禁用拷贝构造
     */
    FileUtils(const FileUtils&) = delete;

    /**
     * @brief 禁用赋值操作
     */
    FileUtils& operator=(const FileUtils&) = delete;
};

#endif // FILEUTILS_H
