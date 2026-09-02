// 030-autorelease-pool -- pool push/pop nesting and the deferred release.
// The pool is a per-thread stack of pages with sentinels; popping an outer
// token must drain everything pushed after it.
#include "testsupport.h"

static int g_deallocs;

@interface Obj : TestRoot { @public int tag; }
@end
@implementation Obj
- (void)dealloc { g_deallocs++; [super dealloc]; }
@end

int main(void) {
    // A pool token is opaque but non-null.
    void *outer = objc_autoreleasePoolPush();
    say("token=%s", NULLNESS(outer));

    // Autorelease defers the release to pop.
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        objc_autorelease(o);
        say("after.autorelease.deallocs=%d", g_deallocs);
        say("after.autorelease.rc=%lu", (unsigned long)[o retainCount]);
    }
    void *inner = objc_autoreleasePoolPush();
    say("inner.token.differs=%s", YN(inner != outer));
    objc_autoreleasePoolPop(inner);
    say("after.inner.pop.deallocs=%d", g_deallocs);
    objc_autoreleasePoolPop(outer);
    say("after.outer.pop.deallocs=%d", g_deallocs);

    // Nesting: objects go to whichever pool was innermost at autorelease time.
    g_deallocs = 0;
    {
        void *p1 = objc_autoreleasePoolPush();
        objc_autorelease([Obj new]);            // belongs to p1
        void *p2 = objc_autoreleasePoolPush();
        objc_autorelease([Obj new]);            // belongs to p2
        objc_autorelease([Obj new]);            // belongs to p2
        say("nest.before.any.pop=%d", g_deallocs);
        objc_autoreleasePoolPop(p2);
        say("nest.after.inner.pop=%d", g_deallocs);
        objc_autoreleasePoolPop(p1);
        say("nest.after.outer.pop=%d", g_deallocs);
    }

    // Popping an OUTER token drains the inner pools too.
    g_deallocs = 0;
    {
        void *p1 = objc_autoreleasePoolPush();
        objc_autorelease([Obj new]);
        void *p2 = objc_autoreleasePoolPush();
        objc_autorelease([Obj new]);
        (void)p2;
        void *p3 = objc_autoreleasePoolPush();
        objc_autorelease([Obj new]);
        (void)p3;
        say("cascade.before=%d", g_deallocs);
        objc_autoreleasePoolPop(p1);
        say("cascade.after=%d", g_deallocs);
    }

    // The same object autoreleased N times gets N releases.
    g_deallocs = 0;
    {
        void *p = objc_autoreleasePoolPush();
        Obj *o = [Obj new];
        objc_retain(o); objc_retain(o);
        say("multi.rc=%lu", (unsigned long)[o retainCount]);
        objc_autorelease(o); objc_autorelease(o); objc_autorelease(o);
        say("multi.before.pop=%d", g_deallocs);
        objc_autoreleasePoolPop(p);
        say("multi.after.pop=%d", g_deallocs);
    }

    // An empty pool pops cleanly, and so does an immediately-popped pair.
    {
        void *p = objc_autoreleasePoolPush();
        objc_autoreleasePoolPop(p);
        say("empty.pool=ok");
        void *q = objc_autoreleasePoolPush();
        void *r = objc_autoreleasePoolPush();
        objc_autoreleasePoolPop(r);
        objc_autoreleasePoolPop(q);
        say("empty.nested=ok");
    }

    // Enough objects to spill past one pool page (objc4 uses 4096-byte pages,
    // so ~500 pointers per page). This is the path where a port that gets the
    // page-chaining wrong fails.
    g_deallocs = 0;
    {
        void *p = objc_autoreleasePoolPush();
        enum { N = 4000 };
        for (int i = 0; i < N; i++) objc_autorelease([Obj new]);
        say("spill.before.pop=%d", g_deallocs);
        objc_autoreleasePoolPop(p);
        say("spill.after.pop=%d", g_deallocs);
    }

    // Autoreleasing from inside a dealloc that the pool itself triggered.
    g_deallocs = 0;
    {
        void *p = objc_autoreleasePoolPush();
        Obj *keeper = [Obj new];
        objc_autorelease(keeper);
        void *q = objc_autoreleasePoolPush();
        objc_autorelease(objc_retain(keeper));
        objc_autoreleasePoolPop(q);
        say("reentrant.mid=%d", g_deallocs);
        objc_autoreleasePoolPop(p);
        say("reentrant.end=%d", g_deallocs);
    }
    return 0;
}
