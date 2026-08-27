/* threadprobe.c -- DIAGNOSTIC. Does the guest ever create a thread?
 *
 * The objc::allocatedClasses DenseMap is guarded by objc4's runtimeLock. If
 * that lock is ineffective, two threads registering classes concurrently can
 * leave one holding a bucket array the other has freed -- which is exactly
 * what the failure looks like: buckets all NULL instead of EmptyKey, and
 * malloc_size(buckets) == 0.
 *
 * That story requires a SECOND THREAD. Apple's libswift_Concurrency imports
 * dispatch_async/dispatch_get_global_queue where ours imports neither, so it
 * is the plausible source -- but my dispatch stubs are loud aborts and never
 * fired, which argues the other way. Rather than reason about it, count.
 */
#include <stddef.h>
extern long write(int, const void *, unsigned long);
extern int glibc_pthread_create(void *, const void *, void *(*)(void *), void *)
    __asm__("_glibc_pthread_create");

static int nthreads;

int pthread_create(void *t, const void *a, void *(*fn)(void *), void *arg);
int pthread_create(void *t, const void *a, void *(*fn)(void *), void *arg)
{
    static const char m[] = "threadprobe: pthread_create #";
    char b[8];
    int n = ++nthreads;
    b[0] = (char)('0' + (n / 10) % 10);
    b[1] = (char)('0' + n % 10);
    b[2] = '\n';
    write(2, m, sizeof(m) - 1);
    write(2, b, 3);
    return glibc_pthread_create(t, a, fn, arg);
}
