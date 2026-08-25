// 032-weak-ops -- copyWeak/moveWeak, reassignment, and weak slots that live in
// heap storage. These are the operations ARC emits for weak struct/array
// members, and they are where a side-table implementation with a wrong
// referrer list shows up.
#include "testsupport.h"

static int g_deallocs;

@interface Obj : TestRoot { @public int tag; }
@end
@implementation Obj
- (void)dealloc { g_deallocs++; [super dealloc]; }
@end

int main(void) {
    // --- copyWeak duplicates the registration -------------------------------
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        id src; objc_initWeak(&src, o);
        id dst;
        objc_copyWeak(&dst, &src);
        say("copy.dst=%s", YN(dst == (id)o));
        say("copy.src.intact=%s", YN(src == (id)o));
        objc_release(o);
        say("copy.both.cleared=%s", YN(src == nil && dst == nil));
        objc_destroyWeak(&src);
        objc_destroyWeak(&dst);
        say("copy.deallocs=%d", g_deallocs);
    }

    // --- moveWeak transfers it ----------------------------------------------
    g_deallocs = 0;
    {
        Obj *o = [Obj new];
        id src; objc_initWeak(&src, o);
        id dst;
        objc_moveWeak(&dst, &src);
        say("move.dst=%s", YN(dst == (id)o));
        objc_release(o);
        say("move.dst.cleared=%s", NULLNESS(dst));
        objc_destroyWeak(&dst);
        say("move.deallocs=%d", g_deallocs);
    }

    // --- reassigning a slot from one object to another ----------------------
    g_deallocs = 0;
    {
        Obj *a = [Obj new]; a->tag = 1;
        Obj *b = [Obj new]; b->tag = 2;
        id w = nil;
        objc_storeWeak(&w, a);
        say("reassign.first=%d", ((Obj *)w)->tag);
        objc_storeWeak(&w, b);
        say("reassign.second=%d", ((Obj *)w)->tag);

        // a is no longer referenced by the slot, so a's dealloc must leave it.
        objc_release(a);
        say("reassign.after.a.dies=%d", ((Obj *)w)->tag);
        objc_release(b);
        say("reassign.after.b.dies=%s", NULLNESS(w));
        say("reassign.deallocs=%d", g_deallocs);
    }

    // --- many weak slots in heap storage, cleared en masse ------------------
    g_deallocs = 0;
    {
        enum { N = 200 };
        Obj *o = [Obj new];
        id *slots = (id *)calloc(N, sizeof(id));
        for (int i = 0; i < N; i++) objc_storeWeak(&slots[i], o);
        int set = 0;
        for (int i = 0; i < N; i++) if (slots[i] == (id)o) set++;
        say("bulk.set=%d", set);
        objc_release(o);
        int cleared = 0;
        for (int i = 0; i < N; i++) if (slots[i] == nil) cleared++;
        say("bulk.cleared=%d", cleared);
        say("bulk.deallocs=%d", g_deallocs);
        free(slots);
    }

    // --- one slot, many objects over time -----------------------------------
    g_deallocs = 0;
    {
        id w = nil;
        for (int i = 0; i < 100; i++) {
            Obj *o = [Obj new];
            o->tag = i;
            objc_storeWeak(&w, o);
            objc_release(o);
            if (w != nil) { say("churn.slot.not.cleared.at=%d", i); break; }
        }
        say("churn.deallocs=%d", g_deallocs);
        say("churn.final.slot=%s", NULLNESS(w));
    }

    // --- weak slot and association on the same object ------------------------
    g_deallocs = 0;
    {
        static char key;
        Obj *host = [Obj new];
        Obj *val  = [Obj new];
        id w = nil;
        objc_storeWeak(&w, val);
        objc_setAssociatedObject(host, &key, val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_release(val);
        say("assoc.keeps.weak.alive=%s", YN(w != nil));
        objc_release(host);
        say("assoc.teardown.clears.weak=%s", NULLNESS(w));
        say("assoc.deallocs=%d", g_deallocs);
    }
    return 0;
}
