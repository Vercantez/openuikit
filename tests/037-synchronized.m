// 037-synchronized -- @synchronized and the objc_sync_* entry points.
// Single-threaded on purpose: contention is not deterministic, but recursion,
// nesting, nil handling and the return codes are.
#include "testsupport.h"

@interface Lockable : TestRoot @end
@implementation Lockable @end

static int g_depth;
static int g_maxDepth;

static void recurse(id obj, int n) {
    if (n == 0) return;
    @synchronized (obj) {
        g_depth++;
        if (g_depth > g_maxDepth) g_maxDepth = g_depth;
        recurse(obj, n - 1);
        g_depth--;
    }
}

int main(void) {
    Lockable *a = [Lockable new];
    Lockable *b = [Lockable new];

    // Raw entry points return OBJC_SYNC_SUCCESS (0).
    say("enter=%d", objc_sync_enter(a));
    say("exit=%d", objc_sync_exit(a));

    // Recursive on the same object, same thread.
    say("enter1=%d", objc_sync_enter(a));
    say("enter2=%d", objc_sync_enter(a));
    say("enter3=%d", objc_sync_enter(a));
    say("exit3=%d", objc_sync_exit(a));
    say("exit2=%d", objc_sync_exit(a));
    say("exit1=%d", objc_sync_exit(a));

    // Two different objects nest independently.
    say("a.enter=%d", objc_sync_enter(a));
    say("b.enter=%d", objc_sync_enter(b));
    say("a.exit=%d", objc_sync_exit(a));
    say("b.exit=%d", objc_sync_exit(b));

    // Unbalanced exit is reported, not fatal.
    say("unbalanced.exit=%d", objc_sync_exit(a));

    // nil is a no-op that succeeds.
    say("nil.enter=%d", objc_sync_enter(nil));
    say("nil.exit=%d", objc_sync_exit(nil));

    // @synchronized recursion through the language construct.
    recurse(a, 5);
    say("recursion.maxDepth=%d", g_maxDepth);
    say("recursion.balanced=%s", YN(g_depth == 0));

    // @synchronized on a class object.
    @synchronized ((id)objc_getClass("Lockable")) {
        say("sync.on.class=ok");
    }

    // @synchronized with an early return still unlocks: entering again after
    // must succeed immediately.
    @synchronized (a) { }
    say("after.block.enter=%d", objc_sync_enter(a));
    say("after.block.exit=%d", objc_sync_exit(a));

    // Locking many distinct objects exercises the sync-data cache eviction
    // path (objc4 keeps a small per-thread cache and spills to a global list).
    enum { N = 64 };
    Lockable *many[N];
    for (int i = 0; i < N; i++) many[i] = [Lockable new];
    int rc = 0;
    for (int i = 0; i < N; i++) rc |= objc_sync_enter(many[i]);
    for (int i = N - 1; i >= 0; i--) rc |= objc_sync_exit(many[i]);
    say("bulk.rc=%d", rc);
    for (int i = 0; i < N; i++) objc_release(many[i]);

    objc_release(a); objc_release(b);
    return 0;
}
