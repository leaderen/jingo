/**
 * @file SuperRayPtr.h
 * @brief SuperRay C API 的 RAII 包装器
 * @details 自动管理 SuperRay 返回的字符串内存，防止内存泄漏
 *
 * @author JinGo VPN Team
 * @date 2025
 */

#ifndef SUPERRAYPTR_H
#define SUPERRAYPTR_H

#include <utility>  // for std::exchange

// 前向声明 SuperRay_Free 函数
extern "C" {
    void SuperRay_Free(char* str);
}

/**
 * @class SuperRayPtr
 * @brief SuperRay C API 返回值的 RAII 包装器
 *
 * @details
 * SuperRay C API 函数（如 SuperRay_Run, SuperRay_GetVersion 等）返回的字符串
 * 需要调用 SuperRay_Free 释放。此类自动管理这些内存，防止泄漏。
 *
 * 使用示例:
 * @code
 * SuperRayPtr result(SuperRay_Run(configJson));
 * if (result) {
 *     QString str = QString::fromUtf8(result.get());
 *     // 自动释放，无需手动调用 SuperRay_Free
 * }
 * @endcode
 */
class SuperRayPtr {
public:
    /**
     * @brief 构造函数
     * @param ptr SuperRay C API 返回的字符串指针，默认为 nullptr
     */
    explicit SuperRayPtr(char* ptr = nullptr) noexcept
        : m_ptr(ptr)
    {
    }

    /**
     * @brief 析构函数 - 自动调用 SuperRay_Free
     */
    ~SuperRayPtr()
    {
        reset();
    }

    /**
     * @brief 移动构造函数
     * @param other 要移动的对象
     */
    SuperRayPtr(SuperRayPtr&& other) noexcept
        : m_ptr(std::exchange(other.m_ptr, nullptr))
    {
    }

    /**
     * @brief 移动赋值运算符
     * @param other 要移动的对象
     * @return 对当前对象的引用
     */
    SuperRayPtr& operator=(SuperRayPtr&& other) noexcept
    {
        if (this != &other) {
            reset();
            m_ptr = std::exchange(other.m_ptr, nullptr);
        }
        return *this;
    }

    // 禁止拷贝
    SuperRayPtr(const SuperRayPtr&) = delete;
    SuperRayPtr& operator=(const SuperRayPtr&) = delete;

    /**
     * @brief 获取原始指针
     * @return 内部持有的字符串指针
     */
    char* get() const noexcept
    {
        return m_ptr;
    }

    /**
     * @brief 布尔转换运算符
     * @return true 如果指针非空，false 如果为空
     */
    explicit operator bool() const noexcept
    {
        return m_ptr != nullptr;
    }

    /**
     * @brief 释放当前持有的指针并接管新指针
     * @param ptr 新的指针，默认为 nullptr
     */
    void reset(char* ptr = nullptr) noexcept
    {
        if (m_ptr) {
            SuperRay_Free(m_ptr);
        }
        m_ptr = ptr;
    }

    /**
     * @brief 释放所有权并返回原始指针
     * @return 原始指针（调用者负责释放）
     */
    char* release() noexcept
    {
        return std::exchange(m_ptr, nullptr);
    }

private:
    char* m_ptr;  ///< SuperRay 返回的字符串指针
};

#endif // SUPERRAYPTR_H
