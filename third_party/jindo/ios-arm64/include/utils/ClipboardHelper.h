/**
 * @file ClipboardHelper.h
 * @brief 剪贴板辅助工具头文件
 * @details 提供简单的剪贴板操作接口供 QML 使用
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef CLIPBOARDHELPER_H
#define CLIPBOARDHELPER_H

#include <QObject>
#include <QString>

/**
 * @class ClipboardHelper
 * @brief 剪贴板辅助工具类
 *
 * @details
 * 提供简单的剪贴板操作接口：
 * - 复制文本到剪贴板
 * - 从剪贴板读取文本
 * - 清空剪贴板
 *
 * @note 此类设计为在 QML 中使用
 */
class ClipboardHelper : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief 构造函数
     * @param parent 父对象指针
     */
    explicit ClipboardHelper(QObject* parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~ClipboardHelper() override;

    /**
     * @brief 复制文本到剪贴板
     * @param text 要复制的文本
     * @return bool 成功返回 true，失败返回 false
     */
    Q_INVOKABLE bool setText(const QString& text);

    /**
     * @brief 从剪贴板读取文本
     * @return QString 剪贴板中的文本内容
     */
    Q_INVOKABLE QString getText() const;

    /**
     * @brief 清空剪贴板
     */
    Q_INVOKABLE void clear();

    /**
     * @brief 检查剪贴板是否包含文本
     * @return bool 包含文本返回 true
     */
    Q_INVOKABLE bool hasText() const;
};

#endif // CLIPBOARDHELPER_H
