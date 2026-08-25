// 028-arc-custom-rr -- objc_retain() does not always inline.
//
// objc4 marks a class "custom RR" when it (or an ancestor) implements
// -retain/-release/-autorelease/-retainCount, and then routes objc_retain()
// through objc_msgSend instead of touching the refcount directly. Crucially,
// scanAddedClassImpl in objc-runtime-new.mm gives EVERY non-NSObject root class
// the custom bits unconditionally, so every class in this corpus is custom-RR.
//
// That is not a curiosity: it means a Linux port whose flag propagation is
// wrong will still pass the simple retain/release tests (the message just goes
// to the same code) and fail only here.
#include "testsupport.h"

static int g_retain, g_release, g_autorelease, g_retainCount, g_dealloc;

@interface Counting : TestRoot @end
@implementation Counting
- (id)retain          { g_retain++; return [super retain]; }
- (oneway void)release { g_release++; [super release]; }
- (id)autorelease     { g_autorelease++; return [super autorelease]; }
- (uintptr_t)retainCount { g_retainCount++; return [super retainCount]; }
- (void)dealloc       { g_dealloc++; [super dealloc]; }
@end

// No RR overrides of its own; inherits TestRoot's, which are themselves
// overrides, so it is custom-RR by inheritance.
@interface Plain : TestRoot @end
@implementation Plain @end

int main(void) {
    void *pool = objc_autoreleasePoolPush();

    Counting *o = [Counting new];
    say("start=%d%d%d%d", g_retain, g_release, g_autorelease, g_dealloc);

    // Each C entry point must land in the corresponding method.
    objc_retain(o);
    say("objc_retain.calls.method=%s", YN(g_retain == 1));

    objc_release(o);
    say("objc_release.calls.method=%s", YN(g_release == 1));

    objc_autorelease(objc_retain(o));   // balanced: the pool owns this one
    say("objc_autorelease.calls.method=%s", YN(g_autorelease == 1));

    (void)[o retainCount];
    say("retainCount.calls.method=%s", YN(g_retainCount == 1));

    // objc_retainAutorelease is retain-then-autorelease.
    int r0 = g_retain, a0 = g_autorelease;
    (void)objc_autorelease(objc_retain(o));
    say("retainAutorelease.retains=%s", YN(g_retain == r0 + 1));
    say("retainAutorelease.autoreleases=%s", YN(g_autorelease == a0 + 1));

    // objc_storeStrong is release-old / retain-new through the same methods.
    id slot = nil;
    int r1 = g_retain, rel1 = g_release;
    objc_storeStrong(&slot, o);
    say("storeStrong.assigns=%s", YN(slot == (id)o));
    say("storeStrong.retains=%s", YN(g_retain == r1 + 1));
    Counting *o2 = [Counting new];
    objc_storeStrong(&slot, o2);
    say("storeStrong.replaces=%s", YN(slot == (id)o2));
    say("storeStrong.releases.old=%s", YN(g_release > rel1));
    objc_storeStrong(&slot, nil);
    say("storeStrong.nil.clears=%s", NULLNESS(slot));

    // A subclass with no overrides still routes through the inherited ones.
    Plain *p = [Plain new];
    say("plain.retainCount=%lu", (unsigned long)[p retainCount]);
    objc_retain(p);
    say("plain.retainCount.after=%lu", (unsigned long)[p retainCount]);
    objc_release(p);

    // Class objects: +retain/+release are no-ops that return self.
    say("class.retain.returns.self=%s",
        YN(objc_retain((id)objc_getClass("Plain")) == (id)objc_getClass("Plain")));
    say("class.retainCount=%lu", (unsigned long)[Plain retainCount]);

    objc_release(o2);
    objc_release(p);
    objc_release(o);
    objc_autoreleasePoolPop(pool);
    say("final.dealloc=%d", g_dealloc);
    return 0;
}
