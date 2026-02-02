/**
 * @file res_search_wrapper.c
 * @brief Wrapper to provide __res_search symbol for Go/CGO on Linux
 * @details Go's net package requires res_search from libresolv.
 *          Some Linux distributions don't export __res_search,
 *          so this wrapper provides it by calling res_search.
 */

#include <resolv.h>

int __res_search(const char *dname, int class, int type,
                 unsigned char *answer, int anslen) {
    return res_search(dname, class, type, answer, anslen);
}
