/* compat/os/overflow.h -- objc4-linux. Apple's os_*_overflow wrap the
 * identical clang builtins. */
#ifndef _OBJC4LINUX_OS_OVERFLOW_H
#define _OBJC4LINUX_OS_OVERFLOW_H
#define os_add_overflow(a, b, res)          __builtin_add_overflow((a), (b), (res))
#define os_sub_overflow(a, b, res)          __builtin_sub_overflow((a), (b), (res))
#define os_mul_overflow(a, b, res)          __builtin_mul_overflow((a), (b), (res))
#define os_add3_overflow(a, b, c, res) ({ __typeof(*(res)) _t; \
    __builtin_add_overflow((a), (b), &_t) || __builtin_add_overflow(_t, (c), (res)); })
#define os_mul_and_add_overflow(a, b, c, res) ({ __typeof(*(res)) _t; \
    __builtin_mul_overflow((a), (b), &_t) || __builtin_add_overflow(_t, (c), (res)); })
#endif
