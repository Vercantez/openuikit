/* Acceptance test for patch 4's semaphore backend.
 *
 * The bar is real scheduling, not compilation: a semaphore that GENUINELY
 * BLOCKS and is signalled from another thread. Anything that completes inline
 * proves nothing, so case 1 fails if the waiter returns before the signaller
 * has run.
 *
 * Both halves of the timed wait are checked, and that pairing is the point.
 * A `_dispatch_sema4_timedwait` that always returned true would pass case 2
 * alone -- and case 2 is exactly the shape that caught machorun's ETIMEDOUT
 * defect ("waited=yes timedout=NO"), so it is the case most worth not
 * mis-scoring. Case 3 is its negative control: a timed wait that IS signalled
 * must report false. Neither case alone has teeth.
 *
 * Output is designed to be diffed between macOS-native and machorun/Linux.
 */

#include "../src/dispatch/sema4_pthread.h"

#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>

extern void _dispatch_sema4_init(_dispatch_sema4_t *, int);
extern void _dispatch_sema4_dispose_slow(_dispatch_sema4_t *, int);
extern void _dispatch_sema4_signal(_dispatch_sema4_t *, long);
extern void _dispatch_sema4_wait(_dispatch_sema4_t *);
extern bool _dispatch_sema4_timedwait(_dispatch_sema4_t *, uint64_t);

static int failures = 0;

static void check(const char *name, bool ok, const char *detail)
{
	printf("%-34s %s%s%s\n", name, ok ? "PASS" : "FAIL",
			detail && *detail ? "  " : "", detail ? detail : "");
	if (!ok) failures++;
}

static uint64_t now_nsec(void)
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (uint64_t)tv.tv_sec * 1000000000ull + (uint64_t)tv.tv_usec * 1000ull;
}

static void sleep_ms(long ms)
{
	struct timespec ts = { ms / 1000, (ms % 1000) * 1000000L };
	nanosleep(&ts, NULL);
}

/* ---------------------------------------------------------------- case 1 */
/* A semaphore that genuinely blocks, signalled from another thread. */

static _dispatch_sema4_t c1_sema;
static volatile int c1_signaller_ran = 0;
static volatile int c1_waiter_returned_early = 0;

static void *c1_signaller(void *unused __attribute__((unused)))
{
	sleep_ms(120);
	c1_signaller_ran = 1;
	_dispatch_sema4_signal(&c1_sema, 1);
	return NULL;
}

static void case1_blocks_until_signalled(void)
{
	pthread_t th;
	_dispatch_sema4_init(&c1_sema, _DSEMA4_POLICY_FIFO);
	pthread_create(&th, NULL, c1_signaller, NULL);

	uint64_t t0 = now_nsec();
	_dispatch_sema4_wait(&c1_sema);
	uint64_t elapsed_ms = (now_nsec() - t0) / 1000000ull;

	/* The claim is not "it returned" -- it is "it did not return until the
	 * other thread ran". A no-op wait would satisfy the first and fail this. */
	if (!c1_signaller_ran) c1_waiter_returned_early = 1;

	char d[96];
	snprintf(d, sizeof d, "blocked %llums, signaller ran first: %s",
			(unsigned long long)elapsed_ms, c1_signaller_ran ? "yes" : "NO");
	check("1 wait blocks until signalled",
			c1_signaller_ran && !c1_waiter_returned_early && elapsed_ms >= 100, d);

	pthread_join(th, NULL);
	_dispatch_sema4_dispose_slow(&c1_sema, _DSEMA4_POLICY_FIFO);
}

/* ---------------------------------------------------------------- case 2 */
/* NEGATIVE CONTROL: a timed wait nobody signals must report TIMED OUT. */

static void case2_timedwait_expires(void)
{
	_dispatch_sema4_t s;
	_dispatch_sema4_init(&s, _DSEMA4_POLICY_FIFO);

	uint64_t t0 = now_nsec();
	bool timed_out = _dispatch_sema4_timedwait(&s, now_nsec() + 150000000ull);
	uint64_t elapsed_ms = (now_nsec() - t0) / 1000000ull;

	char d[96];
	snprintf(d, sizeof d, "returned %s after %llums (want true)",
			timed_out ? "true" : "FALSE", (unsigned long long)elapsed_ms);
	/* It must also actually have waited: returning true instantly would mean
	 * the deadline maths is wrong, not that the timeout works. */
	check("2 timedwait expires  [NEG CTRL]", timed_out && elapsed_ms >= 130, d);

	_dispatch_sema4_dispose_slow(&s, _DSEMA4_POLICY_FIFO);
}

/* ---------------------------------------------------------------- case 3 */
/* The other half: a timed wait that IS signalled must report NOT timed out. */

static _dispatch_sema4_t c3_sema;

static void *c3_signaller(void *unused __attribute__((unused)))
{
	sleep_ms(60);
	_dispatch_sema4_signal(&c3_sema, 1);
	return NULL;
}

static void case3_timedwait_acquires(void)
{
	pthread_t th;
	_dispatch_sema4_init(&c3_sema, _DSEMA4_POLICY_FIFO);
	pthread_create(&th, NULL, c3_signaller, NULL);

	bool timed_out = _dispatch_sema4_timedwait(&c3_sema, now_nsec() + 2000000000ull);

	char d[80];
	snprintf(d, sizeof d, "returned %s (want false)", timed_out ? "TRUE" : "false");
	check("3 timedwait acquires", !timed_out, d);

	pthread_join(th, NULL);
	_dispatch_sema4_dispose_slow(&c3_sema, _DSEMA4_POLICY_FIFO);
}

/* ---------------------------------------------------------------- case 4 */
/* signal(count>1) takes the broadcast path and must release exactly count. */

static _dispatch_sema4_t c4_sema;
static volatile int c4_woken = 0;
static pthread_mutex_t c4_lock = PTHREAD_MUTEX_INITIALIZER;

static void *c4_waiter(void *unused __attribute__((unused)))
{
	_dispatch_sema4_wait(&c4_sema);
	pthread_mutex_lock(&c4_lock);
	c4_woken++;
	pthread_mutex_unlock(&c4_lock);
	return NULL;
}

static void case4_signal_count(void)
{
	pthread_t th[3];
	_dispatch_sema4_init(&c4_sema, _DSEMA4_POLICY_FIFO);
	for (int i = 0; i < 3; i++) pthread_create(&th[i], NULL, c4_waiter, NULL);
	sleep_ms(80);                       /* let all three reach the wait */

	int woken_before = c4_woken;
	_dispatch_sema4_signal(&c4_sema, 3);
	for (int i = 0; i < 3; i++) pthread_join(th[i], NULL);

	char d[96];
	snprintf(d, sizeof d, "woken before signal %d (want 0), after %d (want 3)",
			woken_before, c4_woken);
	check("4 signal(3) releases three", woken_before == 0 && c4_woken == 3, d);

	_dispatch_sema4_dispose_slow(&c4_sema, _DSEMA4_POLICY_FIFO);
}

int main(void)
{
	printf("sizeof(_dispatch_sema4_t) = %zu\n", sizeof(_dispatch_sema4_t));
	case1_blocks_until_signalled();
	case2_timedwait_expires();
	case3_timedwait_acquires();
	case4_signal_count();
	printf("%s (%d failure%s)\n", failures ? "FAILED" : "OK",
			failures, failures == 1 ? "" : "s");
	return failures != 0;
}
