/* osatomic.c -- rung (ak): OSAtomic and OSSpinLock, where the ONE-OFF is
 * the whole risk.
 *
 * These look like the safest things in the boundary: no struct, no constant,
 * no variadic argument, no differing width. What is easy to get wrong is a
 * RETURN VALUE that is off by exactly one operation.
 *
 *   OSAtomicIncrement32 / Decrement32 / Add64 return the NEW value, not the
 *   old one. Darwin's do. So they are __atomic_add_fetch, not
 *   __atomic_fetch_add -- names that differ by a word order and results that
 *   differ by exactly the amount added. A caller testing the result against
 *   zero takes the wrong branch every single time, and CoreFoundation's
 *   retain/release paths do exactly that.
 *
 * That is the whole point of this fixture: every assertion below is written so
 * that a fetch_add implementation FAILS it. Testing only "the counter reaches
 * the right total" would pass with either, which is the shape that has been
 * costing us all day.
 *
 * The compare-and-swap forms must be STRONG -- no spurious failure -- which is
 * what Darwin promises and what a retain loop assumes. A weak CAS would pass a
 * single-threaded fixture and fail rarely under contention, so this exercises
 * both the success and failure returns and the value left behind on failure.
 *
 * OSSpinLock is backed by os_unfair_lock here: both are a 4-byte word whose
 * unlocked state is zero, so a lock initialised through either spelling is
 * valid for the other. What is graded is mutual exclusion under real threads,
 * because a lock that does not lock still passes every single-threaded check.
 *
 * Deliberately NOT graded: recursive acquisition. It aborts under machorun and
 * HANGS FOREVER on Darwin -- Apple deprecated OSSpinLock precisely because it
 * has no owner tracking -- so no oracle-matching fixture can contain it.
 * docs/UNIMPLEMENTED.md#osspinlock-recursive has it instead.
 */
#include <stdio.h>
#include <stdint.h>
#include <pthread.h>
#include <libkern/OSAtomic.h>

static volatile int32_t shared;
static volatile int32_t spin;     /* OSSpinLock, zero-initialised */
static int32_t          plain;    /* guarded by `spin`, deliberately not atomic */

#define THREADS 8
#define BUMPS   20000

static void *worker(void *unused)
{
    (void)unused;
    for (int i = 0; i < BUMPS; i++) {
        OSAtomicIncrement32(&shared);
        OSSpinLockLock(&spin);
        plain++;                  /* a data race unless the lock really locks */
        OSSpinLockUnlock(&spin);
    }
    return NULL;
}

int main(void)
{
    puts("== the increment family returns the NEW value, not the old");
    {
        int32_t v = 10;
        /* If these were fetch_add, the first would print 10 and the second 11.
         * Printing the RETURN rather than the variable is what discriminates. */
        printf("  from 10, increment returns %d\n", OSAtomicIncrement32(&v));
        printf("  from 11, decrement returns %d\n", OSAtomicDecrement32(&v));
        printf("  variable ended at %d\n", v);
    }
    {
        int64_t w = 100;
        printf("  from 100, Add64(+7) returns %lld\n",
               (long long)OSAtomicAdd64(7, &w));
        printf("  from 107, Add64(-7) returns %lld\n",
               (long long)OSAtomicAdd64(-7, &w));
    }

    puts("== compare-and-swap, both outcomes and what is left behind");
    {
        int32_t v = 5;
        int ok  = OSAtomicCompareAndSwap32Barrier(5, 9, &v);
        int bad = OSAtomicCompareAndSwap32Barrier(5, 11, &v);   /* v is 9 now */
        printf("  matching swap returned %s, value now %d\n", ok ? "true" : "false", v);
        printf("  mismatched swap returned %s, value still %d\n",
               bad ? "true" : "false", v);
    }
    {
        int a = 1, b = 2;
        void *p = &a;
        int ok  = OSAtomicCompareAndSwapPtrBarrier(&a, &b, &p);
        int bad = OSAtomicCompareAndSwapPtrBarrier(&a, &b, &p);
        printf("  ptr matching swap: %s, now points at b: %s\n",
               ok ? "true" : "false", p == &b ? "yes" : "NO");
        printf("  ptr mismatched swap: %s, unchanged: %s\n",
               bad ? "true" : "false", p == &b ? "yes" : "NO");
    }

    OSMemoryBarrier();   /* no observable result; graded by not crashing */

    puts("== under real contention");
    {
        pthread_t t[THREADS];
        int i, made = 0;
        for (i = 0; i < THREADS; i++)
            if (pthread_create(&t[i], NULL, worker, NULL) == 0) made++;
        for (i = 0; i < made; i++) pthread_join(t[i], NULL);

        /* The atomic counter must be exact. A non-atomic increment loses
         * updates under eight threads and would land short. */
        printf("  atomic counter exact: %s\n",
               shared == (int32_t)(made * BUMPS) ? "yes" : "NO");
        /* And the spin-locked plain counter must ALSO be exact -- that is the
         * only thing here that proves the lock excludes. */
        printf("  spinlock-guarded counter exact: %s\n",
               plain == (int32_t)(made * BUMPS) ? "yes" : "NO");
        printf("  lock released: %s\n", spin == 0 ? "yes" : "NO");
    }

    puts("done");
    return 0;
}
