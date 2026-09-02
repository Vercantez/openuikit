/* pthread_attr.c -- the `pthread_attr` rung: the pthread_attr surface, where the
 * SAFE-LOOKING direction is the broken one.
 *
 * These ten symbols arrived late, and how they arrived is worth a line here
 * because it is a measurement failure rather than an oversight. ld64.lld stops
 * after 20 diagnostics; every "20 undefined symbols" reading was the CEILING,
 * not the count. Two independent links both returned exactly 20, and that
 * stability was offered as evidence the number was sound. A saturated
 * measurement is perfectly reproducible -- a metric pinned at its limit looks
 * exactly like one that has converged. The whole pthread_attr family was
 * invisible underneath it.
 *
 * THE DETACH STATE IS OFF BY ONE, which is the same worst-case spacing as
 * SIG_BLOCK and fails the same way:
 *
 *     PTHREAD_CREATE_JOINABLE   Darwin 1   glibc 0
 *     PTHREAD_CREATE_DETACHED   Darwin 2   glibc 1
 *
 * A forwarded JOINABLE (1) is read by glibc as DETACHED. The guest asks for a
 * thread it can join and gets one it cannot -- and the pthread_join that
 * follows either fails or reaps a thread that has already gone. DETACHED (2)
 * is out of glibc's range and merely returns EINVAL, so the ONLY direction
 * that fails loudly is the one that was already going to be noticed.
 *
 * THE SCHEDULING POLICY IS THE OTHER HALF:
 *
 *     SCHED_OTHER   Darwin 1   glibc 0
 *     SCHED_FIFO    Darwin 4   glibc 1
 *     SCHED_RR      Darwin 2   glibc 2      <- the only one that agrees
 *
 * Darwin's SCHED_OTHER IS glibc's SCHED_FIFO, so a forwarded request for the
 * ORDINARY scheduler makes the thread real-time. On a machine running a test
 * suite that is a hang, not a slowdown.
 *
 * Both are round-tripped below through set/get pairs and printed BY NAME, so
 * an untranslated wrapper produces a different word rather than a different
 * number. The thread that actually runs is the behavioural half: it proves the
 * attribute reached pthread_create rather than merely surviving our tables.
 *
 * pthread_setschedparam on a live thread is NOT here: setting a real-time
 * policy needs privilege, so it fails on an unprivileged Linux container and
 * succeeds on macOS. That is an environment difference rather than a
 * translation one, and it cannot live in a fixture that must match its oracle.
 */
#include <stdio.h>
#include <pthread.h>
#include <sched.h>
#include <string.h>

static const char *detachname(int d)
{
    return d == PTHREAD_CREATE_JOINABLE ? "PTHREAD_CREATE_JOINABLE" :
           d == PTHREAD_CREATE_DETACHED ? "PTHREAD_CREATE_DETACHED" : "OTHER";
}

static const char *polname(int p)
{
    return p == SCHED_OTHER ? "SCHED_OTHER" :
           p == SCHED_FIFO  ? "SCHED_FIFO"  :
           p == SCHED_RR    ? "SCHED_RR"    : "OTHER";
}

static void *worker(void *arg)
{
    *(int *)arg = 1;
    return NULL;
}

int main(void)
{
    pthread_attr_t a;
    struct sched_param sp;
    int rc, got, ran = 0;
    pthread_t t;
    size_t ss;

    puts("== detach state round trip");
    rc = pthread_attr_init(&a);
    printf("  init rc=%d\n", rc);

    /* The load-bearing case. Untranslated, glibc stores DETACHED here and the
     * read-back reports it -- a different NAME, not a different number. */
    rc = pthread_attr_setdetachstate(&a, PTHREAD_CREATE_JOINABLE);
    got = -1;
    pthread_attr_getdetachstate(&a, &got);
    printf("  set JOINABLE rc=%d  read back %s\n", rc, detachname(got));

    rc = pthread_attr_setdetachstate(&a, PTHREAD_CREATE_DETACHED);
    got = -1;
    pthread_attr_getdetachstate(&a, &got);
    printf("  set DETACHED rc=%d  read back %s\n", rc, detachname(got));

    puts("== and that JOINABLE really reached pthread_create");
    /* The behavioural half. If the attribute was stored as DETACHED, this
     * pthread_join has nothing to join and fails -- which is the consequence
     * the name round trip only implies. */
    pthread_attr_setdetachstate(&a, PTHREAD_CREATE_JOINABLE);
    rc = pthread_create(&t, &a, worker, &ran);
    printf("  create rc=%d\n", rc);
    if (rc == 0) {
        rc = pthread_join(t, NULL);
        printf("  join rc=%d  worker ran=%d\n", rc, ran);
    }

    puts("== scheduling policy round trip");
    rc = pthread_attr_setschedpolicy(&a, SCHED_RR);
    got = -1;
    pthread_attr_getschedpolicy(&a, &got);
    printf("  set SCHED_RR    rc=%d  read back %s\n", rc, polname(got));

    /* SCHED_OTHER is the dangerous one: Darwin's 1 is glibc's SCHED_FIFO. */
    rc = pthread_attr_setschedpolicy(&a, SCHED_OTHER);
    got = -1;
    pthread_attr_getschedpolicy(&a, &got);
    printf("  set SCHED_OTHER rc=%d  read back %s\n", rc, polname(got));

    rc = pthread_attr_setschedpolicy(&a, SCHED_FIFO);
    got = -1;
    pthread_attr_getschedpolicy(&a, &got);
    printf("  set SCHED_FIFO  rc=%d  read back %s\n", rc, polname(got));

    puts("== sched_param: 8 bytes here, 4 on Linux, and the OUT direction");
    memset(&sp, 0, sizeof sp);
    sp.sched_priority = 17;
    rc = pthread_attr_setschedparam(&a, &sp);
    memset(&sp, 0xEE, sizeof sp);          /* poison, so a short write shows */
    got = pthread_attr_getschedparam(&a, &sp);
    printf("  set rc=%d  get rc=%d  priority read back=%d\n",
           rc, got, sp.sched_priority);

    puts("== stack size");
    rc = pthread_attr_setstacksize(&a, 512 * 1024);
    ss = 0;
    pthread_attr_getstacksize(&a, &ss);
    printf("  set rc=%d  read back %s\n", rc,
           ss == 512 * 1024 ? "512 KiB" : "DIFFERENT");

    rc = pthread_attr_destroy(&a);
    printf("  destroy rc=%d\n", rc);

    puts("done");
    return 0;
}
