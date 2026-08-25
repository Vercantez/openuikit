// 027-associated-policies -- the five policies differ in three separate ways:
// what the SETTER does to the value, what the GETTER does to it, and what
// happens at host dealloc. objc4 encodes all three in the policy word:
//
//   OBJC_ASSOCIATION_ASSIGN            = 0
//   OBJC_ASSOCIATION_RETAIN_NONATOMIC  = SETTER_RETAIN
//   OBJC_ASSOCIATION_COPY_NONATOMIC    = SETTER_COPY
//   OBJC_ASSOCIATION_RETAIN            = SETTER_RETAIN|GETTER_RETAIN|GETTER_AUTORELEASE|ATOMIC
//   OBJC_ASSOCIATION_COPY              = SETTER_COPY  |GETTER_RETAIN|GETTER_AUTORELEASE|ATOMIC
//
// The getter-autorelease on the ATOMIC policies is the part everyone forgets,
// and it is measurable: an earlier draft of this test reported "value never
// deallocated" purely because there was no autorelease pool around the reads.
//
// Also measured here: the COPY policies send -copy, NOT -copyWithZone:.
#include "testsupport.h"

static int g_valueDeallocs;
static int g_copyCalls;
static int g_copyWithZoneCalls;

@interface Host : TestRoot @end
@implementation Host @end

@interface Counted : TestRoot { @public int tag; }
@end
@implementation Counted
- (void)dealloc { g_valueDeallocs++; [super dealloc]; }
@end

@interface Copyable : Counted
- (id)copy;
- (id)copyWithZone:(void *)zone;
@end
@implementation Copyable
- (id)copy {
    g_copyCalls++;
    Copyable *c = [Copyable new];
    c->tag = tag + 100;
    return c;
}
- (id)copyWithZone:(void *)zone {
    (void)zone;
    g_copyWithZoneCalls++;
    Copyable *c = [Copyable new];
    c->tag = tag + 200;
    return c;
}
@end

static Counted *mk(int tag) { Counted *c = [Counted new]; c->tag = tag; return c; }

static char kA, kB, kC, kD, kE;

int main(void) {
    // --- ASSIGN: setter does nothing to the value. -------------------------
    g_valueDeallocs = 0;
    {
        void *pool = objc_autoreleasePoolPush();
        Host *h = [Host new];
        Counted *v = mk(1);
        say("assign.rc.before=%lu", (unsigned long)[v retainCount]);
        objc_setAssociatedObject(h, &kA, v, OBJC_ASSOCIATION_ASSIGN);
        say("assign.rc.after.set=%lu", (unsigned long)[v retainCount]);
        say("assign.get=%s", YN(objc_getAssociatedObject(h, &kA) == v));
        say("assign.rc.after.get=%lu", (unsigned long)[v retainCount]);
        objc_setAssociatedObject(h, &kA, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_release(v);
        say("assign.deallocs=%d", g_valueDeallocs);
        objc_release(h);
        objc_autoreleasePoolPop(pool);
    }

    // --- RETAIN_NONATOMIC: setter retains, getter does nothing. -----------
    g_valueDeallocs = 0;
    {
        void *pool = objc_autoreleasePoolPush();
        Host *h = [Host new];
        Counted *v = mk(2);
        objc_setAssociatedObject(h, &kB, v, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        say("retainNA.rc.after.set=%lu", (unsigned long)[v retainCount]);
        unsigned long before = [v retainCount];
        (void)objc_getAssociatedObject(h, &kB);
        say("retainNA.getter.changes.rc=%s", YN([v retainCount] != before));
        objc_release(v);
        say("retainNA.after.caller.release.deallocs=%d", g_valueDeallocs);
        say("retainNA.still.readable=%s", YN(objc_getAssociatedObject(h, &kB) == v));
        objc_setAssociatedObject(h, &kB, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        say("retainNA.after.clear.deallocs=%d", g_valueDeallocs);
        objc_release(h);
        objc_autoreleasePoolPop(pool);
    }

    // --- RETAIN (atomic): setter retains, getter retain+autoreleases. -----
    g_valueDeallocs = 0;
    {
        Host *h = [Host new];
        Counted *v = mk(3);
        objc_setAssociatedObject(h, &kC, v, OBJC_ASSOCIATION_RETAIN);
        say("retain.rc.after.set=%lu", (unsigned long)[v retainCount]);

        void *pool = objc_autoreleasePoolPush();
        unsigned long before = [v retainCount];
        (void)objc_getAssociatedObject(h, &kC);
        say("retain.getter.bumps.rc=%s", YN([v retainCount] > before));
        objc_autoreleasePoolPop(pool);
        say("retain.rc.restored.by.pool=%s", YN([v retainCount] == before));

        objc_release(v);
        say("retain.after.caller.release.deallocs=%d", g_valueDeallocs);
        objc_setAssociatedObject(h, &kC, nil, OBJC_ASSOCIATION_RETAIN);
        say("retain.after.clear.deallocs=%d", g_valueDeallocs);
        objc_release(h);
    }

    // --- COPY_NONATOMIC: setter sends -copy and stores the result. --------
    g_valueDeallocs = 0; g_copyCalls = 0; g_copyWithZoneCalls = 0;
    {
        void *pool = objc_autoreleasePoolPush();
        Host *h = [Host new];
        Copyable *v = [Copyable new];
        v->tag = 4;
        objc_setAssociatedObject(h, &kD, v, OBJC_ASSOCIATION_COPY_NONATOMIC);
        say("copyNA.copyCalls=%d", g_copyCalls);
        say("copyNA.copyWithZoneCalls=%d", g_copyWithZoneCalls);
        id stored = objc_getAssociatedObject(h, &kD);
        say("copyNA.stored.is.different.object=%s", YN(stored != (id)v));
        say("copyNA.stored.tag=%d", ((Counted *)stored)->tag);
        say("copyNA.original.rc=%lu", (unsigned long)[v retainCount]);
        objc_release(v);
        say("copyNA.after.original.release.deallocs=%d", g_valueDeallocs);
        objc_setAssociatedObject(h, &kD, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        say("copyNA.after.clear.deallocs=%d", g_valueDeallocs);
        objc_release(h);
        objc_autoreleasePoolPop(pool);
    }

    // --- COPY (atomic). ---------------------------------------------------
    g_valueDeallocs = 0; g_copyCalls = 0; g_copyWithZoneCalls = 0;
    {
        Host *h = [Host new];
        Copyable *v = [Copyable new];
        v->tag = 5;
        objc_setAssociatedObject(h, &kE, v, OBJC_ASSOCIATION_COPY);
        say("copy.copyCalls=%d", g_copyCalls);
        say("copy.copyWithZoneCalls=%d", g_copyWithZoneCalls);
        objc_release(v);
        say("copy.original.deallocs=%d", g_valueDeallocs);
        objc_release(h);                        // host dies, copy dies with it
        say("copy.after.host.dealloc.deallocs=%d", g_valueDeallocs);
    }

    // --- Host dealloc tears down every association it owns. ---------------
    g_valueDeallocs = 0;
    {
        Host *h = [Host new];
        Counted *v1 = mk(6), *v2 = mk(7);
        objc_setAssociatedObject(h, &kB, v1, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(h, &kC, v2, OBJC_ASSOCIATION_RETAIN);
        objc_release(v1);
        objc_release(v2);
        say("teardown.before=%d", g_valueDeallocs);
        objc_release(h);
        say("teardown.after=%d", g_valueDeallocs);
    }
    return 0;
}
