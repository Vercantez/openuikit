// 044-exception-through-uncached -- throwing from inside the runtime's own
// assembly frames.
//
// 038 throws from ordinary methods, which unwind through objc_msgSend's fast
// path. That path is a `NoFrame` function: it never moves SP and never spills
// LR, so the default CFI rule is correct for it by construction.
//
// The frames this test targets are the other kind. When the method cache
// misses, objc_msgSend tail-calls _objc_msgSend_uncached, which runs the
// SAVE_REGS macro: it subtracts from SP and spills x0-x8, q0-q7, fp and lr.
// Everything reached from there -- +initialize, +resolveInstanceMethod:,
// +resolveClassMethod:, and a class's first-ever
// realization -- runs on top of that frame. An exception thrown there has to
// unwind through it, and that needs CFI the generated ELF assembly does not
// currently emit inside SAVE_REGS (docs/UNIMPLEMENTED.md C1).
//
// This test exists to say precisely whether that matters in practice.
#include "testsupport.h"

@interface Boom : TestRoot @end
@implementation Boom @end

// ---------------------------------------------------------------------------
// 1. Throw from +initialize. +initialize is called from the uncached path the
//    first time any message reaches the class.
// ---------------------------------------------------------------------------
static int g_initializeRan;

@interface ThrowsInInitialize : TestRoot
+ (int)touch;
@end
@implementation ThrowsInInitialize
+ (void)initialize {
    g_initializeRan++;
    @throw [Boom new];
}
+ (int)touch { return 1; }
@end

// ---------------------------------------------------------------------------
// 2. Throw from +resolveInstanceMethod:, which runs on the uncached frame
//    after a cache miss AND a method-list miss.
// ---------------------------------------------------------------------------
@interface ThrowsInResolve : TestRoot
- (int)neverImplemented;
@end
@implementation ThrowsInResolve
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    @throw [Boom new];
}
@end

// ---------------------------------------------------------------------------
// 3. @finally on the intermediate frames must still run while the exception
//    passes through the runtime's assembly.
// ---------------------------------------------------------------------------
static int g_finallyCount;

@interface Deep : TestRoot
- (int)level:(int)n;
@end
@implementation Deep
- (int)level:(int)n {
    if (n == 0) { [ThrowsInResolve new]; return [(id)[ThrowsInResolve new] neverImplemented]; }
    @try {
        return [self level:n - 1];
    } @finally {
        g_finallyCount++;
    }
}
@end

int main(void) {
    // 1. +initialize
    int caught = 0;
    @try {
        [ThrowsInInitialize touch];
    } @catch (id e) {
        caught = (object_getClass(e) == objc_getClass("Boom"));
    }
    say("initialize.threw.caught=%s", YN(caught));
    say("initialize.ran=%d", g_initializeRan);

    // 2. +resolveInstanceMethod:
    caught = 0;
    id r = [ThrowsInResolve new];
    @try {
        (void)[r neverImplemented];
    } @catch (id e) {
        caught = (object_getClass(e) == objc_getClass("Boom"));
    }
    say("resolve.threw.caught=%s", YN(caught));

    // 3. @finally through a stack of message sends
    caught = 0;
    g_finallyCount = 0;
    id d = [Deep new];
    @try {
        (void)[d level:6];
    } @catch (id e) {
        caught = (object_getClass(e) == objc_getClass("Boom"));
    }
    say("deep.threw.caught=%s", YN(caught));
    say("deep.finally.count=%d", g_finallyCount);

    // 4. The runtime must still be usable afterwards.
    id b = [Boom new];
    say("after.alive=%s", YN(b != nil && object_getClass(b) == objc_getClass("Boom")));
    say("after.dispatch=%s", YN([b self] == b));
    return 0;
}
