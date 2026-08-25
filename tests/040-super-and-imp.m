// 040-super-and-imp -- the dispatch entry points below the language syntax:
// objc_msgSendSuper2, method_invoke, and IMP caching.
//
// [super foo] compiles to objc_msgSendSuper2 with a struct objc_super whose
// `super_class` field is the class the method was compiled in -- NOT its
// superclass. Getting that off by one produces infinite recursion, and only
// against a real runtime is the convention checkable.
#include "testsupport.h"

// objc_msgSendSuper2 is the one dispatch entry point clang emits but does not
// declare in <objc/message.h>; declare it the way clang references it.
OBJC_EXPORT id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);

@interface A : TestRoot
- (int)v;
- (const char *)who;
@end
@implementation A
- (int)v { return 1; }
- (const char *)who { return "A"; }
@end

@interface B : A
- (int)v;
- (const char *)who;
@end
@implementation B
- (int)v { return [super v] + 10; }
- (const char *)who { return "B"; }
@end

@interface C : B
- (int)v;
- (const char *)who;
@end
@implementation C
- (int)v { return [super v] + 100; }
- (const char *)who { return "C"; }
@end

int main(void) {
    C *c = [C new];
    B *b = [B new];

    say("c.v=%d", [c v]);
    say("b.v=%d", [b v]);

    // Hand-built super dispatch. objc_msgSendSuper2 takes the class the caller
    // was compiled in and starts the search at ITS superclass.
    struct objc_super sup;
    sup.receiver = c;
    sup.super_class = objc_getClass("C");
    const char *(*sendSuper)(struct objc_super *, SEL) =
        (const char *(*)(struct objc_super *, SEL))objc_msgSendSuper2;
    say("super2.from.C=%s", sendSuper(&sup, @selector(who)));

    sup.super_class = objc_getClass("B");
    say("super2.from.B=%s", sendSuper(&sup, @selector(who)));

    // Starting from A sends -who to TestRoot, which does not implement it.
    // That reaches the forwarding trampoline and aborts, so instead use a
    // selector TestRoot does have, to show the search really did leave A.
    sup.super_class = objc_getClass("A");
    id (*sendSuperSelf)(struct objc_super *, SEL) =
        (id (*)(struct objc_super *, SEL))objc_msgSendSuper2;
    say("super2.from.A.reaches.root=%s", YN(sendSuperSelf(&sup, @selector(self)) == (id)c));

    // objc_msgSendSuper (the non-"2" form) starts at super_class ITSELF.
    struct objc_super sup1;
    sup1.receiver = c;
    sup1.super_class = objc_getClass("B");
    const char *(*sendSuper1)(struct objc_super *, SEL) =
        (const char *(*)(struct objc_super *, SEL))objc_msgSendSuper;
    say("super1.at.B=%s", sendSuper1(&sup1, @selector(who)));
    sup1.super_class = objc_getClass("A");
    say("super1.at.A=%s", sendSuper1(&sup1, @selector(who)));

    // method_invoke calls a Method's IMP with its own selector.
    Method m = class_getInstanceMethod(objc_getClass("A"), @selector(who));
    const char *(*invoke)(id, Method) = (const char *(*)(id, Method))method_invoke;
    say("method_invoke=%s", invoke(c, m));

    // A cached IMP keeps working after the class's method list is grown.
    IMP cached = class_getMethodImplementation(objc_getClass("C"), @selector(who));
    say("cached.before=%s", ((const char *(*)(id, SEL))cached)(c, @selector(who)));
    class_addMethod(objc_getClass("C"), sel_registerName("brandNew"),
                    (IMP)method_getImplementation(m), "*@:");
    say("cached.after.addMethod=%s", ((const char *(*)(id, SEL))cached)(c, @selector(who)));
    say("dispatch.after.addMethod=%s", [c who]);

    // Replacing a method must invalidate what dispatch sees, though the old IMP
    // pointer itself is still callable.
    IMP old = class_replaceMethod(objc_getClass("C"), @selector(who),
                                  method_getImplementation(m), "*@:");
    say("replaced.dispatch=%s", [c who]);
    say("old.imp.still.callable=%s", ((const char *(*)(id, SEL))old)(c, @selector(who)));
    class_replaceMethod(objc_getClass("C"), @selector(who), old, "*@:");
    say("restored.dispatch=%s", [c who]);

    // Repeated sends across a hierarchy: fills and hits the caches.
    int total = 0;
    for (int i = 0; i < 1000; i++) total += [c v] + [b v];
    say("hot.loop.total=%d", total);

    objc_release(c); objc_release(b);
    return 0;
}
