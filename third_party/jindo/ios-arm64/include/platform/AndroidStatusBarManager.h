/**
 * @file AndroidStatusBarManager.h
 * @brief Android 系统状态栏和导航栏管理器
 * @details 提供 Android 系统 UI 图标颜色控制功能
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef ANDROIDSTATUSBARMANAGER_H
#define ANDROIDSTATUSBARMANAGER_H

#include <QtGlobal>

// 仅在 Android 平台编译
#ifdef Q_OS_ANDROID

#include <QObject>

/**
 * @class AndroidStatusBarManager
 * @brief Android 系统栏管理器
 * @details 管理 Android 系统状态栏和导航栏的图标颜色
 *
 * 功能：
 * - 设置状态栏图标为深色或浅色
 * - 设置导航栏图标为深色或浅色
 * - 仅在 Android 平台有效
 */
class AndroidStatusBarManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int navigationBarHeight READ navigationBarHeight NOTIFY navigationBarHeightChanged)
    Q_PROPERTY(int statusBarHeight READ statusBarHeight NOTIFY statusBarHeightChanged)

public:
    /**
     * @brief 构造函数
     * @param parent 父对象
     */
    explicit AndroidStatusBarManager(QObject *parent = nullptr);

    /**
     * @brief 析构函数
     */
    ~AndroidStatusBarManager() override = default;

    /**
     * @brief 获取系统导航栏高度
     * @return 导航栏高度（像素），如果没有导航栏则返回0
     */
    int navigationBarHeight() const;

    /**
     * @brief 获取系统状态栏高度
     * @return 状态栏高度（像素）
     */
    int statusBarHeight() const;

signals:
    void navigationBarHeightChanged();
    void statusBarHeightChanged();

public slots:
    /**
     * @brief 设置状态栏图标颜色
     * @param useLightIcons true = 使用浅色图标（深色背景），false = 使用深色图标（浅色背景）
     *
     * @details Android API 23+ 支持
     * - true: 浅色图标，适合深色状态栏背景
     * - false: 深色图标，适合浅色状态栏背景
     */
    void setStatusBarIconsLight(bool useLightIcons);

    /**
     * @brief 设置导航栏图标颜色
     * @param useLightIcons true = 使用浅色图标（深色背景），false = 使用深色图标（浅色背景）
     *
     * @details Android API 26+ 支持
     * - true: 浅色图标，适合深色导航栏背景
     * - false: 深色图标，适合浅色导航栏背景
     */
    void setNavigationBarIconsLight(bool useLightIcons);

    /**
     * @brief 同时设置状态栏和导航栏图标颜色
     * @param statusBarLight 状态栏是否使用浅色图标
     * @param navBarLight 导航栏是否使用浅色图标
     */
    void setSystemBarIconsColor(bool statusBarLight, bool navBarLight);

private:
#ifdef Q_OS_ANDROID
    /**
     * @brief 设置系统 UI 可见性标志（Android JNI 实现）
     * @param statusBarDark 状态栏使用深色图标
     * @param navBarDark 导航栏使用深色图标
     */
    void setSystemBarIconColorImpl(bool statusBarDark, bool navBarDark);
#endif
};

#endif // Q_OS_ANDROID

#endif // ANDROIDSTATUSBARMANAGER_H
