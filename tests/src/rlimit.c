/* rlimit.c -- resource limits, writev and thread scope: two rotations and one
 * genuine plain forward.
 *
 * THE RLIMIT NUMBERS ARE ROTATED AND ONLY TWO OF SEVEN MOVE, which is what
 * makes them look safe. Measured both sides:
 *
 *     CPU 0  FSIZE 1  DATA 2  STACK 3  CORE 4     agree
 *     RLIMIT_NOFILE   Darwin 8   Linux 7          differ
 *     RLIMIT_AS       Darwin 5   Linux 9          differ
 *
 * And the collisions are with LIVE limits, not unused slots: Darwin's NOFILE
 * (8) is Linux's RLIMIT_MEMLOCK, and Darwin's AS (5) is Linux's RLIMIT_RSS. A
 * forwarded getrlimit(RLIMIT_NOFILE) therefore does not fail -- it returns how
 * much memory the process may LOCK, as a file-descriptor count. CoreFoundation
 * asks for NOFILE, so this is the live case.
 *
 * WHAT THIS FIXTURE CAN ASSERT. Not the limit VALUES: a container and a Mac
 * have wildly different file-descriptor and address-space limits, and two Macs
 * differ. What holds everywhere is the SHAPE of the answer, and it is enough to
 * catch the rotation:
 *
 *   NOFILE must be a plausible descriptor count -- comfortably below the
 *   billions that a memory limit reports. A forwarded NOFILE returns
 *   RLIMIT_MEMLOCK, which on Linux is bytes and is either enormous or
 *   RLIM_INFINITY. Either fails the range check while every true answer passes.
 *
 *   the soft limit never exceeds the hard limit, for every resource. That is
 *   invariant on both systems and is the check that catches a resource number
 *   landing on a limit whose two halves are unrelated to each other.
 *
 * struct rlimit needs no translation -- 16 bytes on both with rlim_t 8 on both
 * -- so this is a constants problem wearing a struct's clothes, and the
 * fixture is written to test the constants rather than the layout.
 */
#include <stdio.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/uio.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

static const struct { const char *n; int r; } R[] = {
    { "RLIMIT_CPU",    RLIMIT_CPU },   { "RLIMIT_FSIZE", RLIMIT_FSIZE },
    { "RLIMIT_DATA",   RLIMIT_DATA },  { "RLIMIT_STACK", RLIMIT_STACK },
    { "RLIMIT_CORE",   RLIMIT_CORE },  { "RLIMIT_NOFILE", RLIMIT_NOFILE },
    { "RLIMIT_AS",     RLIMIT_AS },
};
#define NR (sizeof R / sizeof R[0])

int main(void)
{
    struct rlimit rl;
    size_t i;
    int rc, soft_over_hard = 0, failed = 0;

    puts("== every resource answers, and soft never exceeds hard");
    for (i = 0; i < NR; i++) {
        memset(&rl, 0xAB, sizeof rl);
        rc = getrlimit(R[i].r, &rl);
        if (rc != 0) { failed++; continue; }
        /* RLIM_INFINITY compares greater than anything, so the invariant holds
         * for an unlimited resource too. */
        if (rl.rlim_cur != RLIM_INFINITY && rl.rlim_max != RLIM_INFINITY &&
            rl.rlim_cur > rl.rlim_max) soft_over_hard++;
    }
    printf("  resources that failed to answer: %d\n", failed);
    printf("  resources where soft > hard: %d\n", soft_over_hard);

    puts("== RLIMIT_NOFILE is a descriptor count, not a byte count");
    /* THE DISCRIMINATING CHECK. A forwarded NOFILE returns Linux's
     * RLIMIT_MEMLOCK, which is a byte figure -- either RLIM_INFINITY or a
     * number far above any plausible descriptor limit. Both fail this; every
     * true NOFILE on either system passes it. */
    rc = getrlimit(RLIMIT_NOFILE, &rl);
    /* NOT INFINITY is the whole discriminator, and it is measured rather than
     * guessed: with the translation, both systems report 1048576 here. Without
     * it, Linux answers RLIMIT_MEMLOCK, which in this container is
     * RLIM_INFINITY. A descriptor limit is never unlimited on either system --
     * the kernel has to size a table -- so "finite and at least 16" passes
     * every true answer and fails the forwarded one.
     *
     * My first version bounded it above by 1000000 and macOS reports 1048576,
     * so the check failed against its own oracle. The upper bound was doing no
     * work the infinity test does not do, and was inventing a ceiling. */
    printf("  rc=%d  soft is a plausible fd count: %s\n", rc,
           (rl.rlim_cur != RLIM_INFINITY && rl.rlim_cur >= 16) ? "yes" : "NO");
    /* And it must actually describe THIS process: opening a descriptor below
     * the reported soft limit has to succeed. */
    {
        int fd = open("/dev/null", O_RDONLY);
        printf("  a descriptor below it opens: %s\n", fd >= 0 ? "yes" : "NO");
        if (fd >= 0) close(fd);
    }

    puts("== an UNLIMITED resource must read as RLIM_INFINITY");
    /* THE SENTINEL, which is a second translation inside a struct whose LAYOUT
     * needs none. RLIM_INFINITY is 0x7fffffffffffffff on Darwin and
     * 0xffffffffffffffff on Linux, so an untranslated unlimited limit reads as
     * a specific enormous FINITE number and every "is this capped?" test in the
     * guest answers wrongly.
     *
     * RLIMIT_AS is unlimited on both systems here -- measured -- which is what
     * makes it the case that discriminates. Nothing else in this fixture reads
     * an unlimited resource, and without this line the sentinel bug is
     * invisible: I found that by removing the translation and watching the
     * fixture stay green. */
    rc = getrlimit(RLIMIT_AS, &rl);
    printf("  RLIMIT_AS rc=%d  reads as RLIM_INFINITY: %s\n", rc,
           rl.rlim_cur == RLIM_INFINITY ? "yes" : "NO");
    printf("  and its hard limit too: %s\n",
           rl.rlim_max == RLIM_INFINITY ? "yes" : "NO");

    puts("== setrlimit round trip on the soft limit");
    {
        struct rlimit save, probe;
        getrlimit(RLIMIT_NOFILE, &save);
        probe = save;
        probe.rlim_cur = 128;                  /* well under any hard limit */
        rc = setrlimit(RLIMIT_NOFILE, &probe);
        memset(&probe, 0, sizeof probe);
        getrlimit(RLIMIT_NOFILE, &probe);
        printf("  set rc=%d  read back 128: %s\n", rc,
               probe.rlim_cur == 128 ? "yes" : "NO");
        setrlimit(RLIMIT_NOFILE, &save);       /* restore */
    }

    puts("== writev, where struct iovec agrees on both systems");
    {
        int p[2];
        char buf[16];
        struct iovec v[3];
        long n;

        if (pipe(p) != 0) { puts("  pipe failed"); return 1; }
        v[0].iov_base = (void *)"ab"; v[0].iov_len = 2;
        v[1].iov_base = (void *)"cd"; v[1].iov_len = 2;
        v[2].iov_base = (void *)"ef"; v[2].iov_len = 2;
        n = writev(p[1], v, 3);
        memset(buf, 0, sizeof buf);
        (void)!read(p[0], buf, sizeof buf - 1);
        printf("  wrote %ld bytes, read back \"%s\"\n", n, buf);
        close(p[0]); close(p[1]);
    }

    puts("== PTHREAD_SCOPE is off by one, and Linux supports only SYSTEM");
    {
        pthread_attr_t a;
        int got = -1;
        pthread_attr_init(&a);
        /* Untranslated, Darwin's SCOPE_SYSTEM (1) arrives as glibc's
         * SCOPE_PROCESS and is refused -- the guest asks for the one scope
         * Linux implements and is told it is unsupported. */
        rc = pthread_attr_setscope(&a, PTHREAD_SCOPE_SYSTEM);
        pthread_attr_getscope(&a, &got);
        printf("  set SCOPE_SYSTEM rc=%d  read back SYSTEM: %s\n", rc,
               got == PTHREAD_SCOPE_SYSTEM ? "yes" : "NO");
        pthread_attr_destroy(&a);
    }

    puts("done");
    return 0;
}
