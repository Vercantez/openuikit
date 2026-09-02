// 015-exchange-imp -- method_exchangeImplementations, plus the trap that makes
// it a poor swizzling primitive: it exchanges the Method structs of whatever
// class each Method belongs to, so exchanging an inherited Method mutates the
// SUPERCLASS.
#include "testsupport.h"

@interface Swizzled : TestRoot
- (int)alpha;
- (int)beta;
- (int)inherited;
@end
@implementation Swizzled
- (int)alpha { return 1; }
- (int)beta { return 2; }
- (int)inherited { return 3; }
@end

@interface SwizzledSub : Swizzled
- (int)subOnly;
@end
@implementation SwizzledSub
- (int)subOnly { return 4; }
@end

int main(void) {
    Class cls = objc_getClass("Swizzled");
    Class sub = objc_getClass("SwizzledSub");
    id o  = [Swizzled new];
    id so = [SwizzledSub new];

    Method a = class_getInstanceMethod(cls, @selector(alpha));
    Method b = class_getInstanceMethod(cls, @selector(beta));

    say("before.alpha=%d", [o alpha]);
    say("before.beta=%d", [o beta]);

    method_exchangeImplementations(a, b);
    say("after.alpha=%d", [o alpha]);
    say("after.beta=%d", [o beta]);

    // The Method structs keep their own selectors; only the IMPs moved.
    say("a.name.still.alpha=%s", YN(method_getName(a) == @selector(alpha)));
    say("b.name.still.beta=%s", YN(method_getName(b) == @selector(beta)));

    // Exchanging back restores.
    method_exchangeImplementations(a, b);
    say("restored.alpha=%d", [o alpha]);
    say("restored.beta=%d", [o beta]);

    // class_getInstanceMethod on a SUBCLASS returns the superclass's Method for
    // an inherited selector, so this exchange hits Swizzled, not SwizzledSub.
    Method inh = class_getInstanceMethod(sub, @selector(inherited));
    Method own = class_getInstanceMethod(sub, @selector(subOnly));
    say("inherited.method.is.superclass.method=%s",
        YN(inh == class_getInstanceMethod(cls, @selector(inherited))));

    method_exchangeImplementations(inh, own);
    say("sub.inherited=%d", [so inherited]);
    say("sub.subOnly=%d", [so subOnly]);
    // The superclass instance sees the change too -- the trap.
    say("super.inherited.changed=%d", [o inherited]);
    say("super.responds.subOnly=%s", YN(class_respondsToSelector(cls, @selector(subOnly))));

    method_exchangeImplementations(inh, own);

    // Exchanging a Method with itself is a no-op, not a corruption.
    method_exchangeImplementations(a, a);
    say("self.exchange.alpha=%d", [o alpha]);

    // method_setImplementation returns the previous IMP.
    IMP old = method_setImplementation(a, method_getImplementation(b));
    say("setImplementation.returns.nonnull=%s", NULLNESS((void *)old));
    say("after.setImplementation.alpha=%d", [o alpha]);
    method_setImplementation(a, old);
    say("after.restore.alpha=%d", [o alpha]);

    objc_release(o); objc_release(so);
    return 0;
}
