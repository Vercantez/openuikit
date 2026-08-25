// 012-responds -- respondsToSelector / instancesRespondToSelector /
// class_respondsToSelector across the class/metaclass split.
//
// The classic confusion this pins down: class_respondsToSelector(cls, sel)
// asks about INSTANCE methods of cls. To ask about class methods you pass the
// metaclass. A port that conflates the two passes most other tests.
#include "testsupport.h"

@interface RBase : TestRoot
- (void)baseInstance;
+ (void)baseClass;
@end
@implementation RBase
- (void)baseInstance { }
+ (void)baseClass { }
@end

@interface RSub : RBase
- (void)subInstance;
+ (void)subClass;
@end
@implementation RSub
- (void)subInstance { }
+ (void)subClass { }
@end

@interface RSub (Cat)
- (void)catInstance;
@end
@implementation RSub (Cat)
- (void)catInstance { }
@end

static void probe(const char *label, Class cls, SEL sel) {
    Class meta = object_getClass(cls);
    say("%s.instance=%s", label, YN(class_respondsToSelector(cls, sel)));
    say("%s.class=%s", label, YN(class_respondsToSelector(meta, sel)));
}

int main(void) {
    Class base = objc_getClass("RBase");
    Class sub  = objc_getClass("RSub");

    probe("base.baseInstance", base, @selector(baseInstance));
    probe("base.baseClass",    base, @selector(baseClass));
    probe("base.subInstance",  base, @selector(subInstance));
    probe("sub.baseInstance",  sub,  @selector(baseInstance));
    probe("sub.baseClass",     sub,  @selector(baseClass));
    probe("sub.subInstance",   sub,  @selector(subInstance));
    probe("sub.subClass",      sub,  @selector(subClass));
    probe("sub.catInstance",   sub,  @selector(catInstance));
    probe("sub.missing",       sub,  sel_registerName("noSuchSelectorAnywhere"));

    // nil class, nil selector.
    say("nilclass=%s", YN(class_respondsToSelector(Nil, @selector(baseInstance))));
    say("nilsel=%s", YN(class_respondsToSelector(base, (SEL)0)));

    // Methods TestRoot supplies to everything.
    probe("sub.init", sub, @selector(init));
    probe("sub.alloc", sub, @selector(alloc));

    // class_getInstanceMethod vs class_getClassMethod on the same name.
    say("getInstanceMethod.baseClass=%s",
        NULLNESS(class_getInstanceMethod(base, @selector(baseClass))));
    say("getClassMethod.baseClass=%s",
        NULLNESS(class_getClassMethod(base, @selector(baseClass))));
    say("getInstanceMethod.baseInstance=%s",
        NULLNESS(class_getInstanceMethod(base, @selector(baseInstance))));
    say("getClassMethod.baseInstance=%s",
        NULLNESS(class_getClassMethod(base, @selector(baseInstance))));

    // class_getClassMethod(cls, s) == class_getInstanceMethod(metaclass, s)
    say("classMethod.equals.metaInstanceMethod=%s",
        YN(class_getClassMethod(base, @selector(baseClass)) ==
           class_getInstanceMethod(object_getClass(base), @selector(baseClass))));
    return 0;
}
