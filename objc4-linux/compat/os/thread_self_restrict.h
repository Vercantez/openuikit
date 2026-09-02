/* compat/os/thread_self_restrict.h -- objc4-linux.
 * TPRO (per-thread read-only memory) is Apple silicon hardware. No Linux
 * equivalent exists; the runtime's tproEnabled() path stays false. */
#ifndef _OBJC4LINUX_OS_THREAD_SELF_RESTRICT_H
#define _OBJC4LINUX_OS_THREAD_SELF_RESTRICT_H
#define OS_THREAD_SELF_RESTRICT_TPRO_SUPPORTED 0
static inline void os_thread_self_restrict_tpro_to_rw(void) {}
static inline void os_thread_self_restrict_tpro_to_ro(void) {}
static inline int  os_thread_self_restrict_tpro_is_writeable(void) { return 1; }
#endif
