// 004-dispatch-basic -- inherited, overridden and super dispatch.
#include "testsupport.h"

@interface Base : TestRoot
- (int)onlyBase;
- (int)overridden;
- (int)callsOverridden;   // virtual dispatch from inside the superclass
+ (int)classOnlyBase;
+ (int)classOverridden;
@end
@implementation Base
- (int)onlyBase { return 1; }
- (int)overridden { return 10; }
- (int)callsOverridden { return [self overridden] + 100; }
+ (int)classOnlyBase { return 2; }
+ (int)classOverridden { return 20; }
@end

@interface Mid : Base
- (int)overridden;
+ (int)classOverridden;
- (int)superOverridden;
@end
@implementation Mid
- (int)overridden { return 11; }
+ (int)classOverridden { return 21; }
- (int)superOverridden { return [super overridden] + 1000; }
@end

@interface Leaf : Mid
- (int)overridden;
- (int)superSuper;
@end
@implementation Leaf
- (int)overridden { return 12; }
- (int)superSuper { return [super overridden]; }
@end

int main(void) {
    Base *b = [Base new];
    Mid  *m = [Mid new];
    Leaf *l = [Leaf new];

    say("base.onlyBase=%d", [b onlyBase]);
    say("mid.onlyBase.inherited=%d", [m onlyBase]);
    say("leaf.onlyBase.inherited=%d", [l onlyBase]);

    say("base.overridden=%d", [b overridden]);
    say("mid.overridden=%d", [m overridden]);
    say("leaf.overridden=%d", [l overridden]);

    // Dispatch from inside Base must find the most-derived override.
    say("base.callsOverridden=%d", [b callsOverridden]);
    say("mid.callsOverridden=%d", [m callsOverridden]);
    say("leaf.callsOverridden=%d", [l callsOverridden]);

    // super starts the search at the superclass of the class the method is
    // COMPILED in, not the receiver's class.
    say("mid.superOverridden=%d", [m superOverridden]);
    say("leaf.superOverridden=%d", [l superOverridden]);
    say("leaf.superSuper=%d", [l superSuper]);

    say("class.onlyBase=%d", [Base classOnlyBase]);
    say("class.onlyBase.inherited=%d", [Leaf classOnlyBase]);
    say("class.overridden.base=%d", [Base classOverridden]);
    say("class.overridden.mid=%d", [Mid classOverridden]);
    say("class.overridden.leaf.inherited=%d", [Leaf classOverridden]);

    // Same message sent twice: exercises the method cache fill then hit.
    say("cache.repeat=%d", [l overridden] + [l overridden] + [l overridden]);

    // Dispatch via an explicitly-obtained IMP must equal normal dispatch.
    IMP imp = class_getMethodImplementation(object_getClass(l), @selector(overridden));
    int viaImp = ((int (*)(id, SEL))imp)(l, @selector(overridden));
    say("imp.matches.msgSend=%s", YN(viaImp == [l overridden]));

    objc_release(b); objc_release(m); objc_release(l);
    return 0;
}
