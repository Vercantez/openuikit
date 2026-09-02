// 014-replace-method -- class_replaceMethod is add-or-replace, and its return
// value distinguishes the two cases in a way callers depend on.
#include "testsupport.h"

@interface Replaceable : TestRoot
- (int)target;
- (int)untouched;
@end
@implementation Replaceable
- (int)target { return 1; }
- (int)untouched { return 7; }
@end

@interface RepSub : Replaceable @end
@implementation RepSub @end

static int new_imp(id self, SEL _cmd) { (void)self; (void)_cmd; return 500; }
static int alt_imp(id self, SEL _cmd) { (void)self; (void)_cmd; return 501; }

int main(void) {
    Class cls = objc_getClass("Replaceable");
    Class sub = objc_getClass("RepSub");
    id o  = [Replaceable new];
    id so = [RepSub new];

    IMP originalTarget = class_getMethodImplementation(cls, @selector(target));

    // Replacing an existing method returns the OLD implementation.
    IMP prev = class_replaceMethod(cls, @selector(target), (IMP)new_imp, "i@:");
    say("replace.existing.returns.old=%s", YN(prev == originalTarget));
    say("replace.existing.returns.nonnull=%s", NULLNESS((void *)prev));
    say("after.replace=%d", [o target]);
    say("sibling.untouched=%d", [o untouched]);

    // Replacing a selector the class does not have acts as an add and returns
    // NULL -- even when the SUPERCLASS has it.
    SEL brandNew = sel_registerName("neverSeenBefore");
    IMP prev2 = class_replaceMethod(cls, brandNew, (IMP)alt_imp, "i@:");
    say("replace.fresh.returns=%s", NULLNESS((void *)prev2));
    say("dispatch.fresh=%d", ((int (*)(id, SEL))objc_msgSend)(o, brandNew));

    IMP prev3 = class_replaceMethod(sub, @selector(untouched), (IMP)alt_imp, "i@:");
    say("replace.inherited.returns=%s", NULLNESS((void *)prev3));
    say("sub.after=%d", [so untouched]);
    say("super.after=%d", [o untouched]);

    // Replace twice: the second call sees the first one's IMP.
    IMP prev4 = class_replaceMethod(cls, @selector(target), (IMP)alt_imp, "i@:");
    say("replace.again.returns.new_imp=%s", YN(prev4 == (IMP)new_imp));
    say("after.second.replace=%d", [o target]);

    // The cache must have been flushed: a value cached before the replace must
    // not survive it.
    say("cache.flushed=%s", YN([o target] == 501));

    // nil handling.
    say("replace.nilclass=%s", NULLNESS((void *)class_replaceMethod(Nil, @selector(target), (IMP)new_imp, "i@:")));

    objc_release(o); objc_release(so);
    return 0;
}
