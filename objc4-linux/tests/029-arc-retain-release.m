// 029-arc-retain-release -- reference counts and the dealloc boundary.
#include "testsupport.h"

static int g_deallocs;

@interface Obj : TestRoot { @public int tag; }
@end
@implementation Obj
- (void)dealloc { g_deallocs++; [super dealloc]; }
@end

int main(void) {
    // A freshly allocated object starts at 1.
    Obj *o = [Obj new];
    say("fresh.rc=%lu", (unsigned long)[o retainCount]);

    for (int i = 1; i <= 5; i++) {
        objc_retain(o);
        say("after.retain[%d].rc=%lu", i, (unsigned long)[o retainCount]);
    }
    for (int i = 5; i >= 1; i--) {
        objc_release(o);
        say("after.release[%d].rc=%lu", i, (unsigned long)[o retainCount]);
    }
    say("deallocs.before.final=%d", g_deallocs);
    objc_release(o);
    say("deallocs.after.final=%d", g_deallocs);

    // objc_retain returns the same pointer it was given.
    g_deallocs = 0;
    Obj *p = [Obj new];
    say("retain.returns.same=%s", YN(objc_retain(p) == (id)p));
    objc_release(p);

    // A high count survives without overflowing into the side table wrongly.
    for (int i = 0; i < 1000; i++) objc_retain(p);
    say("high.rc=%lu", (unsigned long)[p retainCount]);
    for (int i = 0; i < 1000; i++) objc_release(p);
    say("back.to.rc=%lu", (unsigned long)[p retainCount]);
    say("high.count.no.dealloc=%d", g_deallocs);
    objc_release(p);
    say("after.release.deallocs=%d", g_deallocs);

    // nil is a legal argument everywhere.
    say("retain.nil=%s", NULLNESS(objc_retain(nil)));
    objc_release(nil);
    say("release.nil.survived=yes");
    say("autorelease.nil=%s", NULLNESS(objc_autorelease(nil)));
    id slot = nil;
    objc_storeStrong(&slot, nil);
    say("storeStrong.nil.nil=%s", NULLNESS(slot));

    // Independent objects have independent counts.
    g_deallocs = 0;
    Obj *a = [Obj new], *b = [Obj new];
    objc_retain(a); objc_retain(a);
    say("a.rc=%lu", (unsigned long)[a retainCount]);
    say("b.rc=%lu", (unsigned long)[b retainCount]);
    objc_release(b);
    say("after.b.dies.deallocs=%d", g_deallocs);
    say("a.rc.unaffected=%lu", (unsigned long)[a retainCount]);
    objc_release(a); objc_release(a); objc_release(a);
    say("after.a.dies.deallocs=%d", g_deallocs);

    // Many objects, all released: no leaks in the counting itself.
    g_deallocs = 0;
    enum { N = 500 };
    Obj *many[N];
    for (int i = 0; i < N; i++) { many[i] = [Obj new]; many[i]->tag = i; }
    for (int i = 0; i < N; i++) objc_retain(many[i]);
    for (int i = 0; i < N; i++) objc_release(many[i]);
    say("bulk.midway.deallocs=%d", g_deallocs);
    for (int i = 0; i < N; i++) objc_release(many[i]);
    say("bulk.final.deallocs=%d", g_deallocs);
    return 0;
}
