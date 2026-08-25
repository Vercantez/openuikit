/* compat/libkern/OSCacheControl.h -- objc4-linux.
 * sys_icache_invalidate -> the clang builtin, which on aarch64 emits the
 * IC IVAU / DSB / ISB sequence Darwin's implementation does. */
#ifndef _OBJC4LINUX_OSCACHECONTROL_H
#define _OBJC4LINUX_OSCACHECONTROL_H
#include <stddef.h>
static inline void sys_icache_invalidate(void *start, size_t len) {
    __builtin___clear_cache((char *)start, (char *)start + len);
}
static inline void sys_dcache_flush(void *start __attribute__((unused)), size_t len __attribute__((unused))) {}
#endif
