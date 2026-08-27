/* #47 verification bar: a dispatch semaphore that GENUINELY BLOCKS and is
 * signalled from another thread. The `signalled` flag is the teeth -- if
 * dispatch_semaphore_wait returns without blocking, the flag is still 0 and
 * the test fails, so a no-op wait cannot pass. */
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

static dispatch_semaphore_t sem;
static volatile int signalled = 0;

static void *worker(void *arg) {
    (void)arg;
    usleep(300000);                 /* the wait must outlast this */
    signalled = 1;
    dispatch_semaphore_signal(sem);
    return 0;
}

/* LIBDISPATCH IS NEVER INITIALISED UNLESS SOMEBODY CALLS THIS.
 *
 * libdispatch_init() is DISPATCH_EXPORT -- an ordinary exported function, not a
 * constructor. Measured: the built dylib has NO __mod_init_func and NO
 * __init_offsets section, while libswiftCore, libSystem and libquartz each have
 * one, so the tool can see them where they exist.
 *
 * On Darwin, libSystem's own initialiser calls libdispatch_init(). Nothing in
 * this stack does, so every function pointer that init sets stays NULL. The
 * symptom was a SIGSEGV at pc 0x0 inside _dispatch_time+0xbc -- a call through
 * the null _dispatch_host_time_mach2nano, which _dispatch_time_init assigns
 * (time.c:76, reached from queue.c:7288 inside libdispatch_init).
 *
 * The call below is a DIAGNOSIS PROBE standing in for libSystem, not the fix.
 * The fix belongs in machorun's libSystem initialiser, where Darwin puts it --
 * otherwise every other consumer of libdispatch hits this same null pointer,
 * and the crash points at dispatch_time rather than at the missing init. */
extern void libdispatch_init(void);

int main(void) {
    libdispatch_init();
    int rc = 0;
    sem = dispatch_semaphore_create(0);
    if (!sem) { printf("FAIL create\n"); return 1; }

    pthread_t t;
    if (pthread_create(&t, 0, worker, 0) != 0) { printf("FAIL spawn\n"); return 1; }

    long r = dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    if (r != 0)      { printf("FAIL wait returned %ld\n", r); rc = 1; }
    else if (!signalled) {
        printf("FAIL wait did NOT block -- returned before the signal\n"); rc = 1;
    } else printf("ok   blocking wait, signalled cross-thread\n");
    pthread_join(t, 0);

    /* timeout must actually time out, and report it */
    dispatch_semaphore_t s2 = dispatch_semaphore_create(0);
    long r2 = dispatch_semaphore_wait(s2, dispatch_time(DISPATCH_TIME_NOW, 100000000));
    if (r2 == 0) { printf("FAIL timeout wait succeeded on an unsignalled semaphore\n"); rc = 1; }
    else printf("ok   timed wait timed out (%ld)\n", r2);

    /* a semaphore already at 1 must NOT block */
    dispatch_semaphore_t s3 = dispatch_semaphore_create(1);
    if (dispatch_semaphore_wait(s3, DISPATCH_TIME_FOREVER) != 0) {
        printf("FAIL pre-signalled semaphore blocked\n"); rc = 1;
    } else printf("ok   pre-signalled wait passed straight through\n");

    printf(rc ? "T7 FAIL\n" : "T7 PASS\n");
    return rc;
}
