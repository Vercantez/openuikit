// 024-dynamic-subclass -- building a subclass of a compiled class at runtime,
// which is the shape KVO and every proxy library depends on.
#include "testsupport.h"

@interface Observed : TestRoot {
@public
    int compiled;
}
- (int)value;
- (int)untouched;
@end
@implementation Observed
- (int)value { return 1; }
- (int)untouched { return 99; }
@end

static IMP g_superValue;

static int overridden_value(id self, SEL _cmd) {
    return ((int (*)(id, SEL))g_superValue)(self, _cmd) + 1000;
}

int main(void) {
    Class base = objc_getClass("Observed");

    Class sub = objc_allocateClassPair(base, "Observed_Dynamic", 0);
    say("allocate=%s", NULLNESS(sub));
    say("super==base=%s", YN(class_getSuperclass(sub) == base));
    say("meta.super==base.meta=%s",
        YN(class_getSuperclass(object_getClass(sub)) == object_getClass(base)));
    say("meta.isa==rootmeta=%s",
        YN(object_getClass(object_getClass(sub)) ==
           object_getClass(objc_getClass("TestRoot"))));

    // Capture the superclass IMP before overriding, the way a proxy would.
    g_superValue = class_getMethodImplementation(base, @selector(value));
    say("superImp=%s", NULLNESS((void *)g_superValue));

    say("addMethod.override=%s",
        YN(class_addMethod(sub, @selector(value), (IMP)overridden_value, "i@:")));

    objc_registerClassPair(sub);

    // Inherited ivars keep their offsets; the subclass adds none.
    say("instanceSize.equal=%s", YN(class_getInstanceSize(sub) == class_getInstanceSize(base)));
    Ivar iv = class_getInstanceVariable(sub, "compiled");
    say("inherited.ivar.found=%s", NULLNESS(iv));
    say("inherited.ivar.same.offset=%s",
        YN(ivar_getOffset(iv) == ivar_getOffset(class_getInstanceVariable(base, "compiled"))));

    Observed *plain = [Observed new];
    id dynamic = class_createInstance(sub, 0);

    say("plain.value=%d", [plain value]);
    say("dynamic.value=%d", ((int (*)(id, SEL))objc_msgSend)(dynamic, @selector(value)));
    say("dynamic.untouched=%d", ((int (*)(id, SEL))objc_msgSend)(dynamic, @selector(untouched)));
    say("base.value.unaffected=%d", [plain value]);

    // Reparenting an existing object into the dynamic subclass -- isa-swizzling.
    Class old = object_setClass(plain, sub);
    say("setClass.returns.old=%s", YN(old == base));
    say("swizzled.class=%s", object_getClassName(plain));
    say("swizzled.value=%d", [plain value]);
    plain->compiled = 5;
    say("swizzled.ivar.still.works=%d", plain->compiled);
    object_setClass(plain, base);
    say("restored.class=%s", object_getClassName(plain));
    say("restored.value=%d", [plain value]);

    object_dispose(dynamic);
    objc_release(plain);
    return 0;
}
