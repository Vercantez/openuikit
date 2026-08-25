// 038-exceptions -- @throw/@try/@catch/@finally.
// On Darwin objc4 rides the Itanium C++ ABI (__cxa_*, _Unwind_*), which Linux
// also provides; what is NOT free is unwinding THROUGH objc_msgSend, which
// needs correct .cfi directives in the hand-written assembly. Several cases
// below deliberately throw from inside a message send several frames deep.
#include "testsupport.h"

@interface Err : TestRoot { @public int code; }
@end
@implementation Err @end

@interface OtherErr : TestRoot @end
@implementation OtherErr @end

@interface Thrower : TestRoot
- (void)throwCode:(int)c;
- (int)deep:(int)n;
@end
@implementation Thrower
- (void)throwCode:(int)c {
    Err *e = [Err new];
    e->code = c;
    @throw e;
}
- (int)deep:(int)n {
    if (n == 0) { [self throwCode:99]; return -1; }
    return [self deep:n - 1] + 1;
}
@end

int main(void) {
    Thrower *t = [Thrower new];

    // --- catch by class ----------------------------------------------------
    @try {
        [t throwCode:1];
        say("unreachable=1");
    } @catch (Err *e) {
        say("caught.class=%s", object_getClassName(e));
        say("caught.code=%d", e->code);
    }

    // --- @finally runs on both paths ---------------------------------------
    int finallyRuns = 0;
    @try {
        finallyRuns += 0;
    } @finally {
        finallyRuns++;
    }
    say("finally.normal=%d", finallyRuns);

    @try {
        @try { [t throwCode:2]; }
        @finally { finallyRuns++; say("finally.during.throw=%d", finallyRuns); }
    } @catch (id e) {
        say("outer.caught=%s", object_getClassName(e));
    }

    // --- non-matching @catch falls through to the next -----------------------
    @try {
        [t throwCode:3];
    } @catch (OtherErr *e) {
        (void)e;
        say("wrong.handler=yes");
    } @catch (Err *e) {
        say("right.handler.code=%d", e->code);
    } @catch (id e) {
        (void)e;
        say("catchall=yes");
    }

    // --- @catch(id) catches anything -----------------------------------------
    @try {
        [t throwCode:4];
    } @catch (id e) {
        say("catchall.class=%s", object_getClassName(e));
    }

    // --- rethrow --------------------------------------------------------------
    @try {
        @try {
            [t throwCode:5];
        } @catch (Err *e) {
            say("inner.code=%d", e->code);
            @throw;
        }
    } @catch (Err *e) {
        say("rethrown.code=%d", e->code);
    }

    // --- throwing a different object from a handler ---------------------------
    @try {
        @try {
            [t throwCode:6];
        } @catch (Err *e) {
            (void)e;
            @throw [OtherErr new];
        }
    } @catch (id e) {
        say("replacement.class=%s", object_getClassName(e));
    }

    // --- unwinding through many objc_msgSend frames ---------------------------
    @try {
        say("deep.result=%d", [t deep:20]);
    } @catch (Err *e) {
        say("deep.caught.code=%d", e->code);
    }

    // --- nested try/catch with finally at every level -------------------------
    int order = 0;
    @try {
        @try {
            @try {
                [t throwCode:7];
            } @finally { order = order * 10 + 1; }
        } @finally { order = order * 10 + 2; }
    } @catch (Err *e) {
        (void)e;
        order = order * 10 + 3;
    } @finally {
        order = order * 10 + 4;
    }
    say("finally.order=%d", order);

    // --- @try with no exception at all ---------------------------------------
    @try { say("normal.path=ok"); } @catch (id e) { (void)e; say("normal.path=bad"); }

    // --- exception state does not leak: dispatch still works afterwards -----
    @try {
        [t throwCode:8];
    } @catch (Err *e) {
        say("after.exceptions.code=%d", e->code);
    }
    say("after.exceptions.class=%s", object_getClassName(t));

    objc_release(t);
    say("done=yes");
    return 0;
}
