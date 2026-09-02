/*
 * compat/libkern/OSAtomic.h  --  objc4-linux
 *
 * Deprecated Darwin atomics. objc4 names them only from the legacy GC-era
 * declarations in <objc/objc-auto.h>. Mapped onto the C11 builtins clang
 * already lowers OSAtomic* to on Darwin.
 */
#ifndef _OBJC4LINUX_OSATOMIC_H
#define _OBJC4LINUX_OSATOMIC_H

#include <stdbool.h>
#include <stdint.h>

static inline void OSMemoryBarrier(void) { __sync_synchronize(); }

static inline bool OSAtomicCompareAndSwapPtr(void *o, void *n, void *volatile *p) {
    return __atomic_compare_exchange_n(p, &o, n, false, __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}
static inline bool OSAtomicCompareAndSwapPtrBarrier(void *o, void *n, void *volatile *p) {
    return __atomic_compare_exchange_n(p, &o, n, false, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED);
}
static inline bool OSAtomicCompareAndSwapLong(long o, long n, volatile long *p) {
    return __atomic_compare_exchange_n(p, &o, n, false, __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}
static inline bool OSAtomicCompareAndSwapLongBarrier(long o, long n, volatile long *p) {
    return __atomic_compare_exchange_n(p, &o, n, false, __ATOMIC_SEQ_CST, __ATOMIC_RELAXED);
}
static inline int32_t OSAtomicIncrement32(volatile int32_t *p) { return __atomic_add_fetch(p, 1, __ATOMIC_SEQ_CST); }
static inline int32_t OSAtomicDecrement32(volatile int32_t *p) { return __atomic_sub_fetch(p, 1, __ATOMIC_SEQ_CST); }

#endif
