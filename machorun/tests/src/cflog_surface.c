/* snprintf_l and pthread_threadid_np -- CFLog's signature, and the reason
 * that phrase matters.
 *
 * These two arrived together with `writev` in a CF preferences trace, and the
 * three of them in that order ARE CFLog: CoreFoundation was not failing, it
 * was trying to LOG, and until writev existed the message was the one thing
 * nobody could see. A stub abort on writev reads like a missing file
 * primitive; the finding was a diagnostic we were deaf to.
 *
 * WHAT EACH ONE IS GRADED FOR:
 *
 *   snprintf_l  that it goes through THIS library's formatter. Darwin's arm64
 *               varargs are all on the STACK with an 8-byte va_list; AAPCS64
 *               passes them in registers with a 32-byte one. Forwarding any
 *               variadic formatter to glibc hands it garbage, which is why
 *               machorun owns a formatter at all. The conversions below are
 *               chosen to fail loudly if the arguments were read from the
 *               wrong place: an int, a double, a string and a char, in an
 *               order that makes a register/stack mix-up unmissable.
 *
 *               And the LOCALE: NULL and LC_GLOBAL_LOCALE both mean C here,
 *               enforced rather than assumed -- libSystem exports `setlocale`
 *               and no other locale entry point, so a guest cannot construct
 *               a locale_t at all. Both are exercised, and both must produce
 *               the same bytes as plain snprintf.
 *
 *   pthread_    that the id is REAL and STABLE, not a placeholder. Measured on
 *   threadid_np Darwin: NULL and pthread_self() give the SAME non-zero id, a
 *               different thread gives a DIFFERENT one, and a NULL out-pointer
 *               is EINVAL (22). The cross-thread line is the one that matters
 *               -- an implementation returning a constant, or returning the
 *               caller's id for any argument, passes every other check here.
 *
 * WHAT IS NOT GRADED, said rather than omitted: the VALUE of a thread id. It
 * is a kernel-assigned number and differs between the two systems and between
 * runs, so the fixture asserts relationships (non-zero, equal, different)
 * rather than digits.
 */
#include <errno.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <xlocale.h>

static uint64_t g_other_self;      /* the child's view of its own id */

static void *child(void *arg)
{
    (void)arg;
    pthread_threadid_np(NULL, &g_other_self);
    return NULL;
}

int main(void)
{
    char a[64], b[64], c[64];
    uint64_t self_null = 0, self_explicit = 0, other = 0;
    pthread_t t;
    int n, rc;

    /* --- snprintf_l against plain snprintf, same arguments, three routes. */
    n = snprintf(a, sizeof a, "%d %.2f %s %c %ld", 42, 1.5, "str", 'z', 7L);
    printf("snprintf            n=%d [%s]\n", n, a);

    n = snprintf_l(b, sizeof b, NULL, "%d %.2f %s %c %ld", 42, 1.5, "str", 'z', 7L);
    printf("snprintf_l NULL     n=%d [%s]\n", n, b);
    printf("  same as snprintf  %d\n", strcmp(a, b) == 0);

    n = snprintf_l(c, sizeof c, LC_GLOBAL_LOCALE, "%d %.2f %s %c %ld",
                   42, 1.5, "str", 'z', 7L);
    printf("snprintf_l GLOBAL   n=%d [%s]\n", n, c);
    printf("  same as snprintf  %d\n", strcmp(a, c) == 0);

    /* Truncation: C99 says return what WOULD have been written. A formatter
     * that returned the truncated length would pass every line above. */
    memset(b, 0, sizeof b);
    n = snprintf_l(b, 5, NULL, "%d %.2f %s %c %ld", 42, 1.5, "str", 'z', 7L);
    printf("snprintf_l trunc    n=%d [%s]\n", n, b);
    printf("  returns full len  %d\n", n == (int)strlen(a));

    /* --- pthread_threadid_np. */
    rc = pthread_threadid_np(NULL, &self_null);
    printf("threadid NULL       rc=%d nonzero=%d\n", rc, self_null != 0);

    rc = pthread_threadid_np(pthread_self(), &self_explicit);
    printf("threadid self       rc=%d same as NULL=%d\n", rc,
           self_explicit == self_null);

    rc = pthread_threadid_np(NULL, NULL);
    printf("threadid no out     rc=%d is EINVAL=%d\n", rc, rc == EINVAL);

    /* The line an implementation that ignores its argument cannot pass. */
    pthread_create(&t, NULL, child, NULL);
    pthread_join(t, NULL);
    other = g_other_self;
    printf("child saw its own   nonzero=%d differs from parent=%d\n",
           other != 0, other != self_null);

    /* Stability: asking twice gives the same answer. A tid derived from
     * something per-call would drift here and nowhere else. */
    {
        uint64_t again = 0;
        pthread_threadid_np(NULL, &again);
        printf("threadid stable     %d\n", again == self_null);
    }

    puts("done");
    return 0;
}
