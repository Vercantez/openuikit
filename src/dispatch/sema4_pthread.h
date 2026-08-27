/* Patch 4 for swift-corelibs-libdispatch: a fourth `_dispatch_sema4_t` backend.
 *
 * PROPOSED — not yet applied to the port's tree. See docs/DISPATCH_PATCH4.md.
 *
 * Upstream's chain in src/shims/lock.h is USE_MACH_SEM / USE_POSIX_SEM /
 * USE_WIN32_SEM and then `#error "port has to implement _dispatch_sema4_t"`.
 * We are a Darwin target without Mach IPC, which upstream does not model, so
 * this is a fourth branch rather than a config flag.
 *
 * WHY NOT USE_POSIX_SEM, which looks like a one-line fix:
 *
 *   - `_dispatch_sema4_t` is embedded BY VALUE in libdispatch's structures, and
 *     `typedef sem_t _dispatch_sema4_t` would put Darwin's 4-byte sem_t where
 *     glibc's `sem_init` writes 32. Clean link, `0` return, 28 bytes gone. It is
 *     one of the eight overflowing types in the opaque-pointer audit, and this
 *     would have been the audit's first live instance.
 *   - Darwin does not implement unnamed POSIX semaphores at all: measured on
 *     macOS 26 arm64, `sem_init` returns -1 / ENOSYS. Selecting USE_POSIX_SEM
 *     for a Darwin target emulates a configuration Apple's platform never has.
 *   - Darwin's sem_t is 4 bytes, so the pointer-handle trick that fixes
 *     posix_spawnattr_t cannot apply — 4 bytes cannot hold a pointer.
 *
 * WHY THE MUTEX+CONDVAR PAIR IS SAFE HERE, measured rather than assumed:
 *
 *   - Both types are adopted by machorun's libSystem through a HANDLE, not by
 *     overlaying: `cond_glibc()` stores a pointer to a heap glibc cond in the
 *     first 8 bytes of Darwin's opaque area (darwin/src/libsystem.c), and the
 *     mutex path does the same via `adopt()`. Nothing is written past the
 *     guest's allocation regardless of the size disagreement.
 *   - Every pthread return crosses `mr_pthread_rc()`, which maps Linux error
 *     numbers to Darwin's. That matters most for ETIMEDOUT (Darwin 60, Linux
 *     110): without it a timed wait that expired returns 110, the guest
 *     compares against 60, and concludes the wait SUCCEEDED. Verified at the
 *     call site — libsystem.c wraps glibc_pthread_cond_timedwait in
 *     mr_pthread_rc — not merely asserted in a comment.
 *
 * TWO CONSTRAINTS THIS CODE MUST RESPECT, both from machorun's forwarder:
 *
 *   - Attributes must be NULL. `pthread_cond_init` with a non-NULL attr bails
 *     by design ("Darwin's pthread_condattr_t layout is not glibc's"), so there
 *     is no CLOCK_MONOTONIC condattr available. That is fine and not a
 *     compromise: `_dispatch_sema4_timedwait` is handed nanoseconds since the
 *     EPOCH by `_dispatch_time_nanoseconds_since_epoch`, which is the realtime
 *     clock the default cond already uses.
 *   - No static initialisers. `PTHREAD_MUTEX_INITIALIZER` carries Darwin's
 *     field layout as a compile-time constant, and no size check can catch a
 *     content mismatch. libdispatch creates every semaphore at runtime, which
 *     dispatch_patches.py asserts on each run; this backend keeps that true by
 *     initialising only in `_dispatch_sema4_init`.
 */

#ifndef _DISPATCH_SEMA4_PTHREAD_H
#define _DISPATCH_SEMA4_PTHREAD_H

#include <pthread.h>
#include <errno.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct _dispatch_sema4_s {
	pthread_mutex_t dsema_mutex;
	pthread_cond_t  dsema_cond;
	long            dsema_value;
} _dispatch_sema4_t;

/* Upstream's two policies are FIFO and LIFO wakeup ordering. A condition
 * variable does not let us choose, and dispatch does not depend on it: the
 * Linux POSIX and Win32 backends both define these to 0 for the same reason.
 * Matching them keeps this branch honest rather than pretending to a guarantee.
 */
#define _DSEMA4_POLICY_FIFO 0
#define _DSEMA4_POLICY_LIFO 0

void _dispatch_sema4_init(_dispatch_sema4_t *sema, int policy);

/* Creation is eager, as in the POSIX branch: _dispatch_sema4_init does the
 * work, so the lazy create_slow path is a no-op and is_created is always true.
 */
#define _dispatch_sema4_is_created(sema) ((void)sema, 1)
#define _dispatch_sema4_create_slow(sema, policy) ((void)sema, (void)policy)

#endif /* _DISPATCH_SEMA4_PTHREAD_H */
