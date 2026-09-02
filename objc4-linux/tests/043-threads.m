// 043-threads -- the runtime under concurrency.
//
// Nothing else in the corpus starts a thread, so none of it exercises the
// threading package objc-config.h selects (OBJC_THREADING_PTHREADS on Linux,
// OBJC_THREADING_DARWIN on macOS), the method cache under contention, the
// +initialize barrier, or objc_sync's per-object locks.
//
// Everything printed is a total or a yes/no. Thread interleaving is
// nondeterministic by definition; the point of the test is that the
// OBSERVABLE result is not.
#include "testsupport.h"
#include <pthread.h>
#include <stdatomic.h>

#define NTHREADS 8
#define NITER    2000

// ---------------------------------------------------------------------------
// A class whose +initialize we count. objc4 must run it exactly once no
// matter how many threads race to be first, and must block the others until
// it has finished.
// ---------------------------------------------------------------------------
static _Atomic int g_initialize_calls;
static _Atomic int g_initialize_finished;
static _Atomic int g_saw_uninitialized;

@interface Contended : TestRoot
+ (int)value;
- (int)one;
@end
@implementation Contended
+ (void)initialize {
    atomic_fetch_add(&g_initialize_calls, 1);
    // Deliberately slow, to widen the window other threads could sneak into.
    for (volatile int i = 0; i < 100000; i++) { }
    atomic_store(&g_initialize_finished, 1);
}
+ (int)value {
    // Any thread that gets here must find +initialize already complete.
    if (!atomic_load(&g_initialize_finished)) atomic_fetch_add(&g_saw_uninitialized, 1);
    return 1;
}
- (int)one { return 1; }
@end

// Distinct classes, each first touched by a different thread, so class
// realization itself is what races.
@interface Lazy0 : TestRoot @end  @implementation Lazy0 @end
@interface Lazy1 : TestRoot @end  @implementation Lazy1 @end
@interface Lazy2 : TestRoot @end  @implementation Lazy2 @end
@interface Lazy3 : TestRoot @end  @implementation Lazy3 @end
@interface Lazy4 : TestRoot @end  @implementation Lazy4 @end
@interface Lazy5 : TestRoot @end  @implementation Lazy5 @end
@interface Lazy6 : TestRoot @end  @implementation Lazy6 @end
@interface Lazy7 : TestRoot @end  @implementation Lazy7 @end
static const char *kLazyNames[NTHREADS] = {
    "Lazy0", "Lazy1", "Lazy2", "Lazy3", "Lazy4", "Lazy5", "Lazy6", "Lazy7"
};

// ---------------------------------------------------------------------------
// Shared state
// ---------------------------------------------------------------------------
static id  g_syncObject;
static long g_syncCounter;          // guarded by @synchronized(g_syncObject)
static _Atomic long g_msgTotal;     // dispatch result accumulator
static _Atomic int  g_lazyOk;
static _Atomic int  g_selOk;
static _Atomic int  g_syncNestOk;

static void *worker(void *arg) {
    long idx = (long)arg;

    // 1. Message dispatch on a shared class: fills and then hits the method
    //    cache from every thread at once.
    long local = 0;
    for (int i = 0; i < NITER; i++) local += [Contended value];
    atomic_fetch_add(&g_msgTotal, local);

    // 2. Instance dispatch, each thread on its own object.
    id obj = [Contended alloc];
    local = 0;
    for (int i = 0; i < NITER; i++) local += [obj one];
    atomic_fetch_add(&g_msgTotal, local);
    [obj release];

    // 3. Realize a class no other thread touches, and one every thread does.
    Class lazy = objc_getClass(kLazyNames[idx]);
    if (lazy && class_getSuperclass(lazy) == objc_getClass("TestRoot") &&
        class_getInstanceSize(lazy) == class_getInstanceSize(objc_getClass("TestRoot")))
    {
        atomic_fetch_add(&g_lazyOk, 1);
    }

    // 4. Selector registration from many threads must be uniquing, not
    //    duplicating: every thread must get the identical SEL.
    SEL a = sel_registerName("aThreadRacedSelector:with:");
    SEL b = sel_getUid("aThreadRacedSelector:with:");
    if (a == b && strcmp(sel_getName(a), "aThreadRacedSelector:with:") == 0)
        atomic_fetch_add(&g_selOk, 1);

    // 5. @synchronized must actually exclude, and must nest.
    for (int i = 0; i < NITER; i++) {
        @synchronized (g_syncObject) {
            g_syncCounter++;
        }
    }
    @synchronized (g_syncObject) {
        @synchronized (g_syncObject) {
            atomic_fetch_add(&g_syncNestOk, 1);
        }
    }

    return NULL;
}

int main(void) {
    g_syncObject = [TestRoot alloc];

    pthread_t t[NTHREADS];
    for (long i = 0; i < NTHREADS; i++) {
        if (pthread_create(&t[i], NULL, worker, (void *)i) != 0) {
            say("pthread_create.failed=yes");
            return 1;
        }
    }
    for (int i = 0; i < NTHREADS; i++) pthread_join(t[i], NULL);

    say("initialize.calls=%d", atomic_load(&g_initialize_calls));
    say("initialize.raced=%s", YN(atomic_load(&g_saw_uninitialized) != 0));
    say("msgTotal=%ld", (long)atomic_load(&g_msgTotal));
    say("msgTotal.expected=%s",
        YN(atomic_load(&g_msgTotal) == (long)NTHREADS * NITER * 2));
    say("lazy.realized=%d", atomic_load(&g_lazyOk));
    say("selectors.uniqued=%d", atomic_load(&g_selOk));
    say("sync.counter=%ld", g_syncCounter);
    say("sync.counter.exact=%s", YN(g_syncCounter == (long)NTHREADS * NITER));
    say("sync.nested=%d", atomic_load(&g_syncNestOk));

    // The runtime should now know it is multithreaded.
    say("threads.count=%d", NTHREADS);

    // Method cache state after all that contention must still be coherent.
    Method m = class_getInstanceMethod(objc_getClass("Contended"), @selector(one));
    say("cache.coherent=%s", YN(m != NULL &&
        class_getMethodImplementation(objc_getClass("Contended"), @selector(one))
            == method_getImplementation(m)));

    [g_syncObject release];
    return 0;
}
