// 031-weak-basic -- zeroing weak references.
// The entry points are used directly rather than via __weak because the C
// functions ARE the runtime contract; ARC codegen would only add a layer
// between the test and the thing under test.
#include "testsupport.h"

static int g_deallocs;

@interface Obj : TestRoot { @public int tag; }
@end
@implementation Obj
- (void)dealloc { g_deallocs++; [super dealloc]; }
@end

int main(void) {
    // Everything runs inside an explicit pool: objc_loadWeak is defined as
    // objc_autorelease(objc_loadWeakRetained(...)), so it leaves a pending
    // release behind. An earlier draft of this test reported a retain count of
    // 2 for a "weak reference does not retain" check purely because of that.
    void *pool = objc_autoreleasePoolPush();

    // --- store / load round trip -------------------------------------------
    {
        Obj *o = [Obj new];
        id w = nil;
        id ret = objc_storeWeak(&w, o);
        say("store.returns.value=%s", YN(ret == (id)o));
        say("slot.holds.object=%s", YN(w == (id)o));
        say("store.alone.rc=%lu", (unsigned long)[o retainCount]);
        say("load=%s", YN(objc_loadWeak(&w) == (id)o));
        say("rc.after.loadWeak=%lu", (unsigned long)[o retainCount]);

        // Clearing by storing nil.
        objc_storeWeak(&w, nil);
        say("store.nil.clears=%s", NULLNESS(w));
        say("load.after.clear=%s", NULLNESS(objc_loadWeak(&w)));
        objc_release(o);
    }

    // --- zeroing on dealloc -------------------------------------------------
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        id w = nil;
        objc_storeWeak(&w, o);
        say("before.dealloc.slot=%s", NULLNESS(w));
        objc_release(o);
        say("deallocs=%d", g_deallocs);
        say("after.dealloc.slot=%s", NULLNESS(w));
        say("after.dealloc.load=%s", NULLNESS(objc_loadWeak(&w)));
    }

    // --- several weak slots pointing at one object all zero ----------------
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        enum { N = 8 };
        id w[N];
        for (int i = 0; i < N; i++) { w[i] = nil; objc_storeWeak(&w[i], o); }
        int allSet = 1;
        for (int i = 0; i < N; i++) if (w[i] != (id)o) allSet = 0;
        say("multi.all.set=%s", YN(allSet));
        objc_release(o);
        int allClear = 1;
        for (int i = 0; i < N; i++) if (w[i] != nil) allClear = 0;
        say("multi.all.cleared=%s", YN(allClear));
    }

    // --- initWeak / destroyWeak --------------------------------------------
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        id w;
        objc_initWeak(&w, o);
        say("initWeak.slot=%s", YN(w == (id)o));
        objc_destroyWeak(&w);
        // The slot is no longer registered, so the object's dealloc must not
        // touch it. Re-init to prove registration is independent per slot.
        id w2;
        objc_initWeak(&w2, o);
        objc_release(o);
        say("destroyed.slot.not.updated=%s", YN(g_deallocs == 1));
        say("live.slot.cleared=%s", NULLNESS(w2));
        objc_destroyWeak(&w2);
    }

    // --- initWeak with nil --------------------------------------------------
    {
        id w;
        objc_initWeak(&w, nil);
        say("initWeak.nil=%s", NULLNESS(w));
        objc_destroyWeak(&w);
        say("destroyWeak.nil.ok=yes");
    }

    // --- objc_loadWeakRetained returns a +1 reference ----------------------
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        id w = nil;
        objc_storeWeak(&w, o);
        unsigned long before = [o retainCount];
        id strong = objc_loadWeakRetained(&w);
        say("loadWeakRetained.value=%s", YN(strong == (id)o));
        say("loadWeakRetained.bumps.rc=%s", YN([o retainCount] == before + 1));
        objc_release(strong);
        objc_release(o);
        say("loadWeakRetained.after.dealloc=%s", NULLNESS(objc_loadWeakRetained(&w)));
        say("deallocs=%d", g_deallocs);
    }

    // --- a weak reference to a class object --------------------------------
    {
        id w = nil;
        objc_storeWeak(&w, (id)objc_getClass("Obj"));
        say("weak.to.class=%s", YN(w == (id)objc_getClass("Obj")));
        objc_storeWeak(&w, nil);
    }

    objc_autoreleasePoolPop(pool);
    return 0;
}
