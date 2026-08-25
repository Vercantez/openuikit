// 013-add-method -- class_addMethod semantics.
#include "testsupport.h"

@interface Addable : TestRoot
- (int)existing;
+ (int)existingClass;
@end
@implementation Addable
- (int)existing { return 1; }
+ (int)existingClass { return 2; }
@end

@interface AddSub : Addable @end
@implementation AddSub @end

static int added_imp(id self, SEL _cmd)          { (void)self; (void)_cmd; return 100; }
static int replacement_imp(id self, SEL _cmd)    { (void)self; (void)_cmd; return 999; }
static int added_class_imp(Class self, SEL _cmd) { (void)self; (void)_cmd; return 200; }

int main(void) {
    Class cls  = objc_getClass("Addable");
    Class meta = object_getClass(cls);
    Class sub  = objc_getClass("AddSub");

    SEL fresh = sel_registerName("freshlyAdded");

    say("before.responds=%s", YN(class_respondsToSelector(cls, fresh)));
    BOOL ok = class_addMethod(cls, fresh, (IMP)added_imp, "i@:");
    say("add.fresh=%s", YN(ok));
    say("after.responds=%s", YN(class_respondsToSelector(cls, fresh)));

    id o = [Addable new];
    say("dispatch.added=%d", ((int (*)(id, SEL))objc_msgSend)(o, fresh));

    // Adding the same selector again must fail and must NOT change the IMP.
    BOOL again = class_addMethod(cls, fresh, (IMP)replacement_imp, "i@:");
    say("add.duplicate=%s", YN(again));
    say("dispatch.after.duplicate=%d", ((int (*)(id, SEL))objc_msgSend)(o, fresh));

    // Adding over a compiled-in method must also fail.
    BOOL overExisting = class_addMethod(cls, @selector(existing), (IMP)replacement_imp, "i@:");
    say("add.over.existing=%s", YN(overExisting));
    say("existing.unchanged=%d", [o existing]);

    // But a SUBCLASS may add a selector its superclass already implements;
    // that is an override, not a duplicate.
    BOOL overInherited = class_addMethod(sub, @selector(existing), (IMP)replacement_imp, "i@:");
    say("sub.add.over.inherited=%s", YN(overInherited));
    id so = [AddSub new];
    say("sub.existing=%d", [so existing]);
    say("super.existing.unaffected=%d", [o existing]);

    // Class methods go on the metaclass.
    SEL freshClass = sel_registerName("freshlyAddedClass");
    say("meta.add=%s", YN(class_addMethod(meta, freshClass, (IMP)added_class_imp, "i@:")));
    say("meta.dispatch=%d", ((int (*)(Class, SEL))objc_msgSend)(cls, freshClass));
    say("meta.add.on.class.side.responds=%s", YN(class_respondsToSelector(cls, freshClass)));
    say("meta.add.on.meta.side.responds=%s", YN(class_respondsToSelector(meta, freshClass)));

    // Type encoding round-trips through the Method.
    Method m = class_getInstanceMethod(cls, fresh);
    say("added.typeencoding=%s", SAFESTR(method_getTypeEncoding(m)));
    say("added.numargs=%u", method_getNumberOfArguments(m));

    // nil arguments.
    say("add.nilclass=%s", YN(class_addMethod(Nil, fresh, (IMP)added_imp, "i@:")));

    objc_release(o); objc_release(so);
    return 0;
}
