/* Patch 4 implementation — see sema4_pthread.h for why this backend exists.
 *
 * PROPOSED — not yet applied to the port's tree.
 *
 * These five functions are the whole contract src/shims/lock.h declares:
 * init, dispose_slow, signal, wait, timedwait.
 *
 * THE ONE RETURN VALUE THAT IS EASY TO GET BACKWARDS:
 * `_dispatch_sema4_timedwait` returns **true when it TIMED OUT** and false when
 * the semaphore was acquired. Upstream's POSIX branch reads
 * `if (ret == -1 && errno == ETIMEDOUT) return true;`. Inverting it would make
 * every timed wait report success, which is the silent-pass shape this project
 * keeps getting caught by, so the negative control in the test covers exactly
 * this and nothing else.
 */

#include "sema4_pthread.h"

#include <stdlib.h>

/* pthread reports errors through its RETURN VALUE, not errno -- unlike the
 * POSIX-semaphore branch upstream, whose macro checks `== -1` and reads errno.
 * Reusing that macro here would test the wrong thing and silently never fire.
 */
#ifndef DISPATCH_INTERNAL_CRASH
#define DISPATCH_INTERNAL_CRASH(c, msg) do { \
		fprintf(stderr, "dispatch: %s (%d)\n", (msg), (int)(c)); \
		abort(); \
	} while (0)
#include <stdio.h>
#endif

#define DISPATCH_PTHREAD_VERIFY(rc) do { \
		int _rc = (rc); \
		if (__builtin_expect(_rc != 0, 0)) { \
			DISPATCH_INTERNAL_CRASH(_rc, "pthread semaphore API failure"); \
		} \
	} while (0)

void
_dispatch_sema4_init(_dispatch_sema4_t *sema, int policy __attribute__((unused)))
{
	sema->dsema_value = 0;
	/* NULL attributes deliberately: machorun's forwarder bails on a non-NULL
	 * pthread_condattr_t, and the mutex TYPE constants differ between Darwin
	 * and glibc, so requesting a type would be requesting a different one. A
	 * counting semaphore needs neither. */
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_init(&sema->dsema_mutex, NULL));
	DISPATCH_PTHREAD_VERIFY(pthread_cond_init(&sema->dsema_cond, NULL));
}

void
_dispatch_sema4_dispose_slow(_dispatch_sema4_t *sema, int policy __attribute__((unused)))
{
	DISPATCH_PTHREAD_VERIFY(pthread_cond_destroy(&sema->dsema_cond));
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_destroy(&sema->dsema_mutex));
}

void
_dispatch_sema4_signal(_dispatch_sema4_t *sema, long count)
{
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_lock(&sema->dsema_mutex));
	sema->dsema_value += count;
	/* Signalling under the lock rather than after unlocking: it costs a
	 * possible extra context switch and removes the window where a waiter
	 * could be added between the count bump and the wake. */
	if (count == 1) {
		DISPATCH_PTHREAD_VERIFY(pthread_cond_signal(&sema->dsema_cond));
	} else {
		DISPATCH_PTHREAD_VERIFY(pthread_cond_broadcast(&sema->dsema_cond));
	}
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
}

void
_dispatch_sema4_wait(_dispatch_sema4_t *sema)
{
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_lock(&sema->dsema_mutex));
	/* while, not if: a broadcast wakes every waiter but only `count` of them
	 * may proceed, and pthread_cond_wait is permitted to wake spuriously. */
	while (sema->dsema_value == 0) {
		DISPATCH_PTHREAD_VERIFY(pthread_cond_wait(&sema->dsema_cond,
				&sema->dsema_mutex));
	}
	sema->dsema_value--;
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
}

bool
_dispatch_sema4_timedwait(_dispatch_sema4_t *sema, uint64_t nsec_since_epoch)
{
	struct timespec ts;
	ts.tv_sec  = (__typeof__(ts.tv_sec))(nsec_since_epoch / 1000000000ull);
	ts.tv_nsec = (__typeof__(ts.tv_nsec))(nsec_since_epoch % 1000000000ull);

	DISPATCH_PTHREAD_VERIFY(pthread_mutex_lock(&sema->dsema_mutex));
	while (sema->dsema_value == 0) {
		int rc = pthread_cond_timedwait(&sema->dsema_cond,
				&sema->dsema_mutex, &ts);
		if (rc == ETIMEDOUT) {
			/* TRUE MEANS TIMED OUT. Matching upstream's POSIX branch. */
			DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
			return true;
		}
		/* EINTR is not a documented pthread_cond_timedwait return, but the
		 * loop condition re-checks the predicate anyway, so a spurious wake
		 * costs one iteration rather than a wrong answer. */
		if (rc != 0) {
			DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
			DISPATCH_INTERNAL_CRASH(rc, "pthread semaphore API failure");
		}
	}
	sema->dsema_value--;
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
	return false;
}
