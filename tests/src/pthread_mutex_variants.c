/* Darwin's three PUBLIC static mutex initialisers, and the semantics each one
 * promises.
 *
 * THE CONSTANTS FAMILY WEARING THE ABI'S OWN CLOTHES. The value that decides
 * the behaviour is not a flag anyone passes: it is the first eight bytes of an
 * object the GUEST'S COMPILER laid down from Apple's header. Nothing at any
 * call site names it, so nothing at any call site can be reviewed for it.
 *
 *      PTHREAD_MUTEX_INITIALIZER              0x32AAABA7
 *      PTHREAD_ERRORCHECK_MUTEX_INITIALIZER   0x32AAABA1
 *      PTHREAD_RECURSIVE_MUTEX_INITIALIZER    0x32AAABA2
 *
 * machorun accepted only the first, and the second is the one that mattered:
 * CoreFoundation's `CFLock_t` is `pthread_mutex_t` and `CFLockInit` is
 * `PTHREAD_ERRORCHECK_MUTEX_INITIALIZER`, so it is CF's lock EVERYWHERE. The
 * first CFPreferences call died inside pthread_mutex_lock before touching a
 * file; the CFString and CFDictionary paths exercised until then never take
 * one, which is why it stayed hidden.
 *
 * ACCEPTING THE SIGNATURE IS ONLY HALF, AND THE EASY HALF. Adopting an
 * errorcheck mutex as a DEFAULT one would make every line below print `0` and
 * exit 0 -- it would lock and unlock perfectly well, and silently drop the
 * error checking upstream asked for. So this fixture asserts the SEMANTICS,
 * and it asserts them by the RETURN VALUE, which is where pthread reports
 * errors:
 *
 *      errorcheck  relock by the owner -> EDEADLK, unlock unowned -> EPERM
 *      recursive   relock by the owner -> 0, and needs as many unlocks
 *      default     unlock unowned -> 0     (measured: Darwin does NOT complain)
 *
 * AND THE NUMBERS THEMSELVES CROSS BADLY, which is why the returns are printed
 * as `is EDEADLK` rather than as integers: EDEADLK is 11 on Darwin and 35 on
 * Linux, and Darwin's 11 is Linux's EAGAIN -- the two are exactly each other's.
 * A missing return translation would print a plausible number here. The mutex
 * TYPE constants are swapped too (Darwin ERRORCHECK 1 / RECURSIVE 2 against
 * glibc RECURSIVE 1 / ERRORCHECK 2), so an implementation that mapped the
 * signature straight to glibc's number would turn CF's errorcheck lock into a
 * recursive one -- passing the relock line for the wrong reason, which is why
 * the unlock-unowned line is here as well.
 *
 * FIRSTFIT IS NOT TESTED, and that is a measurement: Apple has a
 * _PTHREAD_FIRSTFIT_MUTEX_SIG_init internally but publishes no
 * PTHREAD_FIRSTFIT_MUTEX_INITIALIZER, verified by compiling this file against
 * Apple's SDK with #ifdef. A guest cannot statically initialise one, so it
 * cannot reach the loader's adoption path at all.
 */
#include <errno.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>

static pthread_mutex_t g_plain = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t g_err   = PTHREAD_ERRORCHECK_MUTEX_INITIALIZER;
static pthread_mutex_t g_rec   = PTHREAD_RECURSIVE_MUTEX_INITIALIZER;

/* The signature as the GUEST'S compiler laid it down. Printed because it is
 * the thing under test: if these three ever stop differing, every check below
 * would pass while testing one mutex three times. */
static unsigned long sig_of(const void *p)
{
    unsigned long v;
    memcpy(&v, p, sizeof v);
    return v;
}

static void *other_thread_lock(void *arg)
{
    pthread_mutex_lock((pthread_mutex_t *)arg);
    return NULL;
}

int main(void)
{
    int rc;

    printf("sizeof pthread_mutex_t   %zu\n", sizeof(pthread_mutex_t));
    printf("plain      sig           0x%08lX\n", sig_of(&g_plain));
    printf("errorcheck sig           0x%08lX\n", sig_of(&g_err));
    printf("recursive  sig           0x%08lX\n", sig_of(&g_rec));
    printf("the three differ         %d\n",
           sig_of(&g_plain) != sig_of(&g_err) &&
           sig_of(&g_err)   != sig_of(&g_rec) &&
           sig_of(&g_plain) != sig_of(&g_rec));

#ifdef PTHREAD_FIRSTFIT_MUTEX_INITIALIZER
    printf("firstfit initializer     PUBLIC -- this fixture's scope is stale\n");
#else
    printf("firstfit initializer     not public\n");
#endif

    /* --- default: locks, unlocks, and does NOT complain about an unowned
     * unlock. That last line is what separates a real default mutex from an
     * errorcheck one adopted by mistake. */
    printf("-- default\n");
    printf("  lock                   %d\n", pthread_mutex_lock(&g_plain));
    printf("  unlock                 %d\n", pthread_mutex_unlock(&g_plain));
    printf("  unlock unowned         %d\n", pthread_mutex_unlock(&g_plain));

    /* --- errorcheck: CF's lock. */
    printf("-- errorcheck (CF's CFLockInit)\n");
    printf("  lock                   %d\n", pthread_mutex_lock(&g_err));
    rc = pthread_mutex_lock(&g_err);
    printf("  relock is EDEADLK      %d\n", rc == EDEADLK);
    rc = pthread_mutex_trylock(&g_err);
    printf("  trylock is EBUSY       %d\n", rc == EBUSY);
    printf("  unlock                 %d\n", pthread_mutex_unlock(&g_err));
    rc = pthread_mutex_unlock(&g_err);
    printf("  unlock unowned EPERM   %d\n", rc == EPERM);

    /* --- recursive: relocks, and needs one unlock per lock. */
    printf("-- recursive\n");
    printf("  lock                   %d\n", pthread_mutex_lock(&g_rec));
    printf("  relock                 %d\n", pthread_mutex_lock(&g_rec));
    printf("  unlock                 %d\n", pthread_mutex_unlock(&g_rec));
    printf("  unlock                 %d\n", pthread_mutex_unlock(&g_rec));
    rc = pthread_mutex_unlock(&g_rec);
    printf("  unlock unowned EPERM   %d\n", rc == EPERM);

    /* --- a real second thread, so the adoption is exercised the way it is
     * reached in practice: the double-checked publish in the loader's adopt()
     * is what makes the FIRST touch by any thread safe, and a fixture that
     * only ever touches these from main never leaves the fast path. */
    {
        pthread_t t;
        pthread_mutex_lock(&g_err);
        pthread_create(&t, NULL, other_thread_lock, &g_err);
        pthread_mutex_unlock(&g_err);
        pthread_join(t, NULL);
        rc = pthread_mutex_unlock(&g_err);
        printf("-- cross-thread\n");
        printf("  owner unlocks EPERM    %d\n", rc == EPERM);
    }

    puts("done");
    return 0;
}
