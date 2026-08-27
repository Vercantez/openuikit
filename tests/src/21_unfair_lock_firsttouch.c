/*
 * 21_unfair_lock_firsttouch -- does taking an os_unfair_lock ALLOCATE?
 *
 * Darwin's os_unfair_lock_lock never allocates. It is a compare-and-swap on
 * four bytes, and callers are entitled to rely on that: it is usable from
 * inside an allocator, and from any context where malloc is not reentrant.
 *
 * machorun's used to. os_unfair_lock_lock -> unfair_token -> mr_thread_token
 * -> dtsd_slots, and dtsd_slots CALLOCS the per-thread direct-TSD array on a
 * thread's first call. glibc's arena mutex is not recursive, so a thread
 * already inside malloc that first-touched a lock deadlocks against a mutex it
 * already holds.
 *
 * WHY stress_unfair_lock.sh CANNOT CATCH THIS, which is the reason this file
 * exists rather than another loop count. That script runs three existing objc44
 * fixtures (004-dispatch-basic, 043-threads, 037-synchronized) 2000 times, and
 * its stated purpose is to catch a token derived from an ADDRESS -- it is a
 * distribution test for collision probability. Those fixtures create their
 * threads and then contend, so every thread's first-touch happens BEFORE
 * contention begins. 2000 clean runs of the wrong shape say nothing about this.
 *
 * The three shapes it misses, one per case below:
 *   A  a thread created DURING contention
 *   B  a thread whose FIRST-EVER acquisition happens while another holds it
 *   C  a lock first-touched from INSIDE an allocation path   <-- the deadlock
 *
 * THIS FIXTURE HAS NO TEETH FOR THE ALLOCATION BUG, AND SAYS SO.
 * Measured: it passes identically with and without the trampoline priming.
 * Case C stages "allocate, THEN lock" -- but malloc has already RETURNED by
 * then, so glibc's arena mutex is released and there is nothing to deadlock
 * against. To be inside the allocator while taking a lock you need allocator
 * INTERPOSITION (a malloc hook, or a replaced allocator that locks), and
 * machorun forwards malloc straight to glibc with no hooks. On the evidence,
 * the deadlock is not reachable in machorun as it stands.
 *
 * So what this file IS: coverage for three lock-acquisition shapes the existing
 * gate cannot reach (stress_unfair_lock.sh runs three fixtures whose threads
 * are all created before contention begins). That coverage has independent
 * value -- it would catch a token-uniqueness or init-ordering regression on
 * first-touch-under-contention. It is NOT a regression test for
 * "os_unfair_lock_lock allocates", because nothing here can fail when it does.
 *
 * If allocator interposition is ever added, revisit case C: it becomes live.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <os/lock.h>

static os_unfair_lock g_lock = OS_UNFAIR_LOCK_INIT;   /* statically initialised on purpose */
static os_unfair_lock g_alloc_lock = OS_UNFAIR_LOCK_INIT;

static volatile int contention_running;
static volatile int a_threads_done;

/* ---- A: threads created DURING contention -------------------------------- */
static void *a_worker(void *arg)
{
    (void)arg;
    for (int i = 0; i < 200; i++) {
        os_unfair_lock_lock(&g_lock);
        os_unfair_lock_unlock(&g_lock);
    }
    __sync_fetch_and_add(&a_threads_done, 1);
    return NULL;
}

static void *a_spinner(void *arg)
{
    (void)arg;
    while (contention_running) {
        os_unfair_lock_lock(&g_lock);
        os_unfair_lock_unlock(&g_lock);
    }
    return NULL;
}

/* ---- B: first-ever acquisition while the lock is HELD by someone else ----- */
static volatile int b_lock_held;
static volatile int b_may_finish;

static void *b_late(void *arg)
{
    (void)arg;
    while (!b_lock_held) usleep(200);
    /* This thread has never taken a lock before. Its first acquisition is
     * contended, so it goes down the yield path with an unprimed TSD. */
    os_unfair_lock_lock(&g_lock);
    os_unfair_lock_unlock(&g_lock);
    return NULL;
}

static void *b_holder(void *arg)
{
    (void)arg;
    os_unfair_lock_lock(&g_lock);
    b_lock_held = 1;
    while (!b_may_finish) usleep(200);
    os_unfair_lock_unlock(&g_lock);
    return NULL;
}

/* ---- C: a lock first-touched from INSIDE an allocation path --------------- *
 * The shape that deadlocks. A brand-new thread whose very first os_unfair_lock
 * acquisition happens while it is inside an allocator critical section --
 * exactly what objc4 and the Swift runtime do on allocation-adjacent paths.
 * We stage it with a lock taken between a malloc and its free, on a thread
 * that has touched no lock before, repeated so the unprimed window is hit. */
static void *c_alloc_then_lock(void *arg)
{
    (void)arg;
    for (int i = 0; i < 64; i++) {
        void *p = malloc(4096);          /* enter the allocator */
        if (!p) return (void *)1;
        os_unfair_lock_lock(&g_alloc_lock);   /* first touch, allocator-adjacent */
        memset(p, i, 64);
        os_unfair_lock_unlock(&g_alloc_lock);
        free(p);
    }
    return NULL;
}

int main(void)
{
    pthread_t spin[4], late[8], alloc[8], t;
    int rc = 0;

    /* A: start contention, THEN create threads into it. */
    contention_running = 1;
    for (int i = 0; i < 4; i++) pthread_create(&spin[i], NULL, a_spinner, NULL);
    usleep(2000);
    for (int i = 0; i < 8; i++) pthread_create(&late[i], NULL, a_worker, NULL);
    for (int i = 0; i < 8; i++) pthread_join(late[i], NULL);
    contention_running = 0;
    for (int i = 0; i < 4; i++) pthread_join(spin[i], NULL);
    if (a_threads_done != 8) { printf("A FAIL: %d/8 finished\n", a_threads_done); rc = 1; }
    else printf("A ok: 8 threads created during contention\n");

    /* B: first-ever acquisition on a held lock. */
    b_lock_held = b_may_finish = 0;
    pthread_create(&t, NULL, b_holder, NULL);
    while (!b_lock_held) usleep(200);
    for (int i = 0; i < 8; i++) pthread_create(&late[i], NULL, b_late, NULL);
    usleep(4000);
    b_may_finish = 1;
    for (int i = 0; i < 8; i++) pthread_join(late[i], NULL);
    pthread_join(t, NULL);
    printf("B ok: 8 first-ever acquisitions on a held lock\n");

    /* C: lock first-touched inside an allocation path. */
    for (int i = 0; i < 8; i++) pthread_create(&alloc[i], NULL, c_alloc_then_lock, NULL);
    for (int i = 0; i < 8; i++) {
        void *r = NULL;
        pthread_join(alloc[i], &r);
        if (r) { printf("C FAIL: worker %d reported failure\n", i); rc = 1; }
    }
    printf("C ok: 8 threads locked from inside an allocation path\n");

    printf(rc == 0 ? "PASS\n" : "FAIL\n");
    return rc;
}
