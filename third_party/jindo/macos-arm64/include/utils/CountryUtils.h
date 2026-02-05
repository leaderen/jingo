/**
 * @file CountryUtils.h
 * @brief 国家识别和分类工具
 * @details 通过服务器名称识别国家，提供洲分类和国旗显示
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef COUNTRYUTILS_H
#define COUNTRYUTILS_H

#include <QString>
#include <QMap>
#include <QStringList>

/**
 * @class CountryUtils
 * @brief 国家识别和分类工具类
 *
 * @details 功能：
 * - 从服务器名称中识别国家/地区（支持简体中文、繁体中文、英文）
 * - 提供国家到洲的映射
 * - 提供国家到国旗 emoji 的映射
 */
class CountryUtils
{
public:
    /**
     * @brief 从服务器名称中识别国家代码
     * @param name 服务器名称
     * @return 两位字母国家代码（ISO 3166-1 alpha-2），未识别返回空字符串
     */
    static QString detectCountryCode(const QString& name);

    /**
     * @brief 获取国家的洲
     * @param countryCode 两位字母国家代码
     * @return 洲名称（中文）
     */
    static QString getContinent(const QString& countryCode);

    /**
     * @brief 获取国家的国旗 emoji
     * @param countryCode 两位字母国家代码
     * @return 国旗 emoji 字符串
     */
    static QString getCountryFlag(const QString& countryCode);

    /**
     * @brief 获取国家的中文名称
     * @param countryCode 两位字母国家代码
     * @return 国家中文名称
     */
    static QString getCountryName(const QString& countryCode);

    /**
     * @brief 获取从用户所在国家到目标大洲的距离值
     * @param userCountryCode 用户所在国家代码
     * @param targetContinent 目标大洲名称（中文）
     * @return 距离值（0=同洲，1=邻近，2=中等，3=较远，4=最远）
     */
    static int getContinentDistance(const QString& userCountryCode, const QString& targetContinent);

    /**
     * @brief 获取按距离排序的大洲列表
     * @param userCountryCode 用户所在国家代码
     * @return 按距离从近到远排序的大洲列表
     */
    static QStringList getSortedContinents(const QString& userCountryCode);

    /**
     * @brief 初始化国家数据
     * @details 在首次使用时自动调用
     */
    static void initialize();

private:
    CountryUtils() = delete;

    // 国家关键词映射表（简体中文、繁体中文、英文关键词 -> 国家代码）
    static QMap<QString, QString> s_countryKeywords;

    // 国家到洲的映射
    static QMap<QString, QString> s_countryToContinent;

    // 国家到中文名称的映射
    static QMap<QString, QString> s_countryNames;

    // 是否已初始化
    static bool s_initialized;

    // 初始化国家关键词映射
    static void initCountryKeywords();

    // 初始化洲映射
    static void initContinentMapping();

    // 初始化国家名称
    static void initCountryNames();
};

#endif // COUNTRYUTILS_H
