/**
 * @file LanguageManager.h
 * @brief 语言管理器头文件
 * @details 管理应用程序的多语言支持，包括语言切换、翻译加载等功能
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef LANGUAGEMANAGER_H
#define LANGUAGEMANAGER_H

#include <QObject>
#include <QString>
#include <QLocale>
#include <QTranslator>
#include <QQmlEngine>

/**
 * @class LanguageManager
 * @brief 语言管理器
 * @details 提供语言切换和翻译加载功能，支持：
 * - 中文 (zh_CN)
 * - 英文 (en_US)
 * - 波斯语 (fa_IR)
 * - 俄语 (ru_RU)
 */
class LanguageManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    /// 当前语言代码 (zh_CN, en_US, fa_IR, ru_RU)
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY currentLanguageChanged)

    /// 当前语言的显示名称
    Q_PROPERTY(QString currentLanguageName READ currentLanguageName NOTIFY currentLanguageChanged)

public:
    /**
     * @brief 获取单例实例
     * @return LanguageManager单例引用
     */
    static LanguageManager& instance();

    /**
     * @brief QML单例工厂方法
     * @param engine QML引擎
     * @param scriptEngine JS引擎
     * @return LanguageManager实例指针
     */
    static LanguageManager* create(QQmlEngine *engine, QJSEngine *scriptEngine);

    /**
     * @brief 获取当前语言代码
     * @return 语言代码字符串 (zh_CN, en_US, fa_IR, ru_RU)
     */
    QString currentLanguage() const { return m_currentLanguage; }

    /**
     * @brief 获取当前语言的显示名称
     * @return 显示名称 (简体中文, English, فارسی, Русский)
     */
    QString currentLanguageName() const;

    /**
     * @brief 设置当前语言
     * @param language 语言代码 (zh_CN, en_US, fa_IR, ru_RU)
     */
    void setCurrentLanguage(const QString& language);

    /**
     * @brief 初始化语言设置
     * @details 从配置文件读取用户设置的语言，如果没有则使用系统语言
     */
    void initialize();

public slots:
    /**
     * @brief 获取所有支持的语言列表
     * @return 语言列表，每项包含 code 和 name
     */
    Q_INVOKABLE QVariantList availableLanguages() const;

    /**
     * @brief 切换到指定语言
     * @param languageCode 语言代码
     * @return 切换是否成功
     */
    Q_INVOKABLE bool switchLanguage(const QString& languageCode);

    /**
     * @brief 获取语言的显示名称
     * @param languageCode 语言代码
     * @return 显示名称
     */
    Q_INVOKABLE QString getLanguageName(const QString& languageCode) const;

    /**
     * @brief 获取系统默认语言
     * @return 系统语言代码
     */
    Q_INVOKABLE QString getSystemLanguage() const;

    /**
     * @brief 检查指定语言是否是RTL（从右到左）语言
     * @param languageCode 语言代码
     * @return true表示是RTL语言
     */
    Q_INVOKABLE bool isRightToLeft(const QString& languageCode) const;

    /**
     * @brief 设置 QML 引擎（用于重新翻译）
     * @param engine QML引擎指针
     */
    void setQmlEngine(QQmlEngine* engine);

signals:
    /**
     * @brief 当前语言变化信号
     */
    void currentLanguageChanged();

    /**
     * @brief 语言切换完成信号
     * @param success 是否成功
     * @param language 新的语言代码
     */
    void languageSwitched(bool success, const QString& language);

private:
    /**
     * @brief 构造函数（单例模式，私有）
     * @param parent 父对象
     */
    explicit LanguageManager(QObject* parent = nullptr);

    /**
     * @brief 禁用拷贝构造
     */
    LanguageManager(const LanguageManager&) = delete;

    /**
     * @brief 禁用赋值运算符
     */
    LanguageManager& operator=(const LanguageManager&) = delete;

    /**
     * @brief 加载翻译文件
     * @param languageCode 语言代码
     * @return 是否加载成功
     */
    bool loadTranslation(const QString& languageCode);

    /**
     * @brief 移除当前翻译
     */
    void removeCurrentTranslation();

    /**
     * @brief 保存语言设置到配置文件
     */
    void saveLanguageSettings();

    /**
     * @brief 从配置文件加载语言设置
     * @return 保存的语言代码，如果没有则返回空字符串
     */
    QString loadLanguageSettings() const;

    /**
     * @brief 获取翻译文件路径
     * @param languageCode 语言代码
     * @return 翻译文件的完整路径
     */
    QString getTranslationPath(const QString& languageCode) const;

    QString m_currentLanguage;          ///< 当前语言代码
    QTranslator* m_translator;          ///< Qt翻译器
    QTranslator* m_qtTranslator;        ///< Qt基础组件翻译器
    QQmlEngine* m_qmlEngine;            ///< QML引擎指针（用于重新翻译）

    /// 支持的语言映射 (code -> name)
    static const QMap<QString, QString> s_supportedLanguages;
};

#endif // LANGUAGEMANAGER_H
