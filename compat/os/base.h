/* compat/os/base.h -- objc4-linux */
#ifndef _OBJC4LINUX_OS_BASE_H
#define _OBJC4LINUX_OS_BASE_H
#define OS_EXPORT           extern __attribute__((visibility("default")))
#define OS_INLINE           static inline
#define OS_ALWAYS_INLINE    __attribute__((always_inline))
#define OS_NOINLINE         __attribute__((noinline))
#define OS_NORETURN         __attribute__((noreturn))
#define OS_NOTHROW          __attribute__((nothrow))
#define OS_WARN_RESULT      __attribute__((warn_unused_result))
#define OS_CONST            __attribute__((const))
#define OS_PURE             __attribute__((pure))
#define OS_UNUSED           __attribute__((unused))
#define os_fastpath(x)      ((__typeof__(x))__builtin_expect((long)(x), ~0l))
#define os_slowpath(x)      ((__typeof__(x))__builtin_expect((long)(x), 0l))
#define os_likely(x)        __builtin_expect(!!(x), 1)
#define os_unlikely(x)      __builtin_expect(!!(x), 0)
#endif
