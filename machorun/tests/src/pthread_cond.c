/* pthread_cond.c -- condition variables and mutex attributes.
 *
 * These back std::mutex, std::condition_variable and std::recursive_mutex in
 * the libc++ we build, and libdispatch's semaphore shim sits on top of them.
 * A symbol-count test is worthless here: the two ways this goes wrong both
 * LINK CLEANLY and pass anything that only checks return codes.
 *
 * WAY ONE -- a cond that does not actually wait. Every test where the
 * predicate happens to be true already passes against an implementation that
 * returns immediately. So case 2 makes the predicate FALSE, has a worker set
 * it after a measurable delay, and checks BOTH that the predicate was true on
 * wake AND that real time passed. Case 1 is its negative control: the same
 * machinery with no signal ever sent must TIME OUT, which proves the test can
 * tell waiting from not-waiting rather than merely reporting success twice.
 *
 * WAY TWO -- the mutex TYPE constants are swapped between the platforms:
 *
 *      value   Darwin        glibc
 *          1   ERRORCHECK    RECURSIVE
 *          2   RECURSIVE     ERRORCHECK
 *
 * so a FORWARDED settype(PTHREAD_MUTEX_RECURSIVE) hands glibc a 2, glibc reads
 * ERRORCHECK, and the mutex returns EDEADLK the first time its owner relocks
 * it. Case 5 relocks a recursive mutex; on a forwarding implementation it
 * fails and on a translating one it does not. Nothing about sizes or symbols
 * would have caught that.
 *
 * DETERMINISM: no timings, addresses or thread ids are printed -- only
 * predicates -- so the output is a function of the semantics and comparable
 * against macOS. The delay is 120 ms and the "did it really wait" threshold
 * 50 ms, which is far outside scheduling noise on both hosts.
 */
#include <stdio.h>
#include <pthread.h>
#include <string.h>
#include <errno.h>
#include <time.h>

static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
/* Statically initialised on purpose: this is the case a size check cannot
 * catch, because PTHREAD_COND_INITIALIZER is a compile-time constant carrying
 * Darwin's field layout rather than glibc's. */
static pthread_cond_t  cnd = PTHREAD_COND_INITIALIZER;
static int ready;

static long long now_ms(void)
{
    struct timespec t;
    clock_gettime(CLOCK_REALTIME, &t);
    return (long long)t.tv_sec * 1000 + t.tv_nsec / 1000000;
}

static void *setter(void *arg)
{
    struct timespec d = { 0, 120 * 1000 * 1000 };   /* 120 ms */
    nanosleep(&d, NULL);
    pthread_mutex_lock(&mtx);
    ready = 1;
    pthread_cond_signal(&cnd);
    pthread_mutex_unlock(&mtx);
    (void)arg;
    return NULL;
}

static void *broadcaster(void *arg)
{
    struct timespec d = { 0, 120 * 1000 * 1000 };
    nanosleep(&d, NULL);
    pthread_mutex_lock(&mtx);
    ready = 1;
    pthread_cond_broadcast(&cnd);
    pthread_mutex_unlock(&mtx);
    (void)arg;
    return NULL;
}

static int woke[3];
static void *waiter(void *arg)
{
    long i = (long)arg;
    pthread_mutex_lock(&mtx);
    while (!ready) pthread_cond_wait(&cnd, &mtx);
    woke[i] = 1;
    pthread_mutex_unlock(&mtx);
    return NULL;
}

int main(void)
{
    pthread_t t, w[3];
    long long t0;
    int rc;

    /* 1. NEGATIVE CONTROL: nobody signals, so this MUST time out. If it does
     *    not, the test cannot distinguish waiting from returning early and
     *    every result below is meaningless. */
    {
        struct timespec ts;
        clock_gettime(CLOCK_REALTIME, &ts);
        ts.tv_nsec += 150 * 1000 * 1000;
        if (ts.tv_nsec >= 1000000000) { ts.tv_sec++; ts.tv_nsec -= 1000000000; }
        pthread_mutex_lock(&mtx);
        ready = 0;
        t0 = now_ms();
        rc = pthread_cond_timedwait(&cnd, &mtx, &ts);
        printf("control  timedout=%s waited=%s\n",
               rc == ETIMEDOUT ? "yes" : "NO", now_ms() - t0 >= 50 ? "yes" : "NO");
        pthread_mutex_unlock(&mtx);
    }

    /* 2. A real wait, woken by another thread. */
    pthread_mutex_lock(&mtx);
    ready = 0;
    pthread_mutex_unlock(&mtx);
    pthread_create(&t, NULL, setter, NULL);
    pthread_mutex_lock(&mtx);
    t0 = now_ms();
    while (!ready) pthread_cond_wait(&cnd, &mtx);
    printf("signal   predicate=%s waited=%s\n",
           ready ? "yes" : "NO", now_ms() - t0 >= 50 ? "yes" : "NO");
    pthread_mutex_unlock(&mtx);
    pthread_join(t, NULL);

    /* 3. Broadcast: every waiter must wake, not just one. */
    pthread_mutex_lock(&mtx);
    ready = 0;
    memset(woke, 0, sizeof woke);
    pthread_mutex_unlock(&mtx);
    for (long i = 0; i < 3; i++) pthread_create(&w[i], NULL, waiter, (void *)i);
    pthread_create(&t, NULL, broadcaster, NULL);
    for (int i = 0; i < 3; i++) pthread_join(w[i], NULL);
    pthread_join(t, NULL);
    printf("broadcast woke=%d/3\n", woke[0] + woke[1] + woke[2]);

    /* 4. A dynamically initialised cond, destroyed properly. */
    {
        pthread_cond_t c2;
        printf("dyn      init=%d destroy=%d\n",
               pthread_cond_init(&c2, NULL), pthread_cond_destroy(&c2));
    }

    /* 5. THE CONSTANT-SWAP CASE. A recursive mutex must accept a second lock
     *    from the thread that already holds it. Forwarded, Darwin's
     *    RECURSIVE (2) reaches glibc as ERRORCHECK and this returns EDEADLK. */
    {
        pthread_mutexattr_t a;
        pthread_mutex_t rm;
        int got = -1, second;
        pthread_mutexattr_init(&a);
        pthread_mutexattr_settype(&a, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutexattr_gettype(&a, &got);
        pthread_mutex_init(&rm, &a);
        pthread_mutex_lock(&rm);
        second = pthread_mutex_trylock(&rm);      /* must succeed: 0 */
        if (second == 0) pthread_mutex_unlock(&rm);
        pthread_mutex_unlock(&rm);
        printf("recursive gettype=%s relock=%s\n",
               got == PTHREAD_MUTEX_RECURSIVE ? "RECURSIVE" : "WRONG",
               second == 0 ? "ok" : "REFUSED");
        pthread_mutexattr_destroy(&a);
        pthread_mutex_destroy(&rm);
    }

    /* 6. An error-checking mutex must REFUSE the same relock -- which is how
     *    we know case 5 succeeded for the right reason rather than because
     *    every type behaves recursively. */
    {
        pthread_mutexattr_t a;
        pthread_mutex_t em;
        int second;
        pthread_mutexattr_init(&a);
        pthread_mutexattr_settype(&a, PTHREAD_MUTEX_ERRORCHECK);
        pthread_mutex_init(&em, &a);
        pthread_mutex_lock(&em);
        second = pthread_mutex_trylock(&em);      /* must NOT be 0 */
        if (second == 0) pthread_mutex_unlock(&em);
        pthread_mutex_unlock(&em);
        printf("errcheck relock=%s\n", second == 0 ? "ACCEPTED" : "refused");
        pthread_mutexattr_destroy(&a);
        pthread_mutex_destroy(&em);
    }

    printf("done\n");
    return 0;
}
