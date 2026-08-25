/*
 * compat/os/lock_private.h  --  objc4-linux
 *
 * os_unfair_lock is a futex-backed adaptive lock. Linux's direct analogue is
 * a PTHREAD_MUTEX_NORMAL pthread_mutex_t, which is also futex-backed.
 *
 * NOTE: objc4 on Linux selects OBJC_THREADING_PTHREADS, and Apple already
 * wrote that back-end (runtime/Threading/pthreads.h). So the runtime does not
 * actually use these; this header exists for the handful of declarations that
 * mention os_unfair_lock in guarded code, and to keep runtime/Threading/
 * darwin.h parseable if anyone includes it by accident.
 *
 * The semantics are NOT identical: os_unfair_lock records the owning thread
 * and traps on unlock-by-wrong-thread; a NORMAL pthread mutex has undefined
 * behaviour there. Do not rely on it for correctness diagnostics.
 */
#ifndef _OBJC4LINUX_OS_LOCK_PRIVATE_H
#define _OBJC4LINUX_OS_LOCK_PRIVATE_H

#include <pthread.h>
#include <stdint.h>
#include <stdbool.h>
#include <os/base.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct os_unfair_lock_s {
    pthread_mutex_t _mtx;
} os_unfair_lock, *os_unfair_lock_t;

#define OS_UNFAIR_LOCK_INIT ((os_unfair_lock){ PTHREAD_MUTEX_INITIALIZER })

static inline void os_unfair_lock_lock(os_unfair_lock_t l)    { pthread_mutex_lock(&l->_mtx); }
static inline bool os_unfair_lock_trylock(os_unfair_lock_t l) { return pthread_mutex_trylock(&l->_mtx) == 0; }
static inline void os_unfair_lock_unlock(os_unfair_lock_t l)  { pthread_mutex_unlock(&l->_mtx); }
static inline void os_unfair_lock_assert_owner(os_unfair_lock_t l)     { (void)l; }
static inline void os_unfair_lock_assert_not_owner(os_unfair_lock_t l) { (void)l; }

typedef uint32_t os_unfair_lock_options_t;
#define OS_UNFAIR_LOCK_NONE            0x00000000u
#define OS_UNFAIR_LOCK_DATA_SYNCHRONIZATION 0x00010000u
#define OS_UNFAIR_LOCK_ADAPTIVE_SPIN   0x00040000u
static inline void os_unfair_lock_lock_with_options(os_unfair_lock_t l, os_unfair_lock_options_t o) {
    (void)o; pthread_mutex_lock(&l->_mtx);
}

typedef struct os_unfair_recursive_lock_s {
    pthread_mutex_t _mtx;
} os_unfair_recursive_lock, *os_unfair_recursive_lock_t;

#define OS_UNFAIR_RECURSIVE_LOCK_INIT \
    ((os_unfair_recursive_lock){ PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP })

static inline void os_unfair_recursive_lock_lock(os_unfair_recursive_lock_t l)   { pthread_mutex_lock(&l->_mtx); }
static inline void os_unfair_recursive_lock_unlock(os_unfair_recursive_lock_t l) { pthread_mutex_unlock(&l->_mtx); }
static inline bool os_unfair_recursive_lock_trylock(os_unfair_recursive_lock_t l){ return pthread_mutex_trylock(&l->_mtx) == 0; }
static inline void os_unfair_recursive_lock_lock_with_options(os_unfair_recursive_lock_t l, os_unfair_lock_options_t o) {
    (void)o; pthread_mutex_lock(&l->_mtx);
}
static inline bool os_unfair_recursive_lock_owned(os_unfair_recursive_lock_t l)  { (void)l; return true; }

/* os_lock_handoff_s: only mentioned in a comment in NSObject.mm. */
typedef struct os_lock_handoff_s { pthread_mutex_t _mtx; } os_lock_handoff_s;

#ifdef __cplusplus
}
#endif

#endif
