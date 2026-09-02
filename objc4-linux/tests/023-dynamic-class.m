// 023-dynamic-class -- objc_allocateClassPair / class_addIvar /
// objc_registerClassPair, the runtime-only class construction path.
#include "testsupport.h"

static int dyn_answer(id self, SEL _cmd) { (void)self; (void)_cmd; return 4242; }
static int dyn_classAnswer(Class self, SEL _cmd) { (void)self; (void)_cmd; return 8484; }

@protocol T4LDynProto
- (int)answer;
@end

int main(void) {
    Class root = objc_getClass("TestRoot");

    say("before.lookup=%s", NULLNESS(objc_lookUpClass("DynamicOne")));

    Class dyn = objc_allocateClassPair(root, "DynamicOne", 0);
    say("allocate=%s", NULLNESS(dyn));
    say("allocated.name=%s", class_getName(dyn));
    say("allocated.superclass==root=%s", YN(class_getSuperclass(dyn) == root));
    say("allocated.meta.superclass==rootmeta=%s",
        YN(class_getSuperclass(object_getClass(dyn)) == object_getClass(root)));
    say("allocated.meta.isa==rootmeta=%s",
        YN(object_getClass(object_getClass(dyn)) == object_getClass(root)));

    // An unregistered class is not yet visible to lookup.
    say("unregistered.lookUpClass=%s", NULLNESS(objc_lookUpClass("DynamicOne")));

    // Ivars may only be added before registration. alignment is log2.
    say("addIvar.int=%s", YN(class_addIvar(dyn, "count", sizeof(int), 2, "i")));
    say("addIvar.obj=%s", YN(class_addIvar(dyn, "ref", sizeof(id), 3, "@")));
    say("addIvar.duplicate=%s", YN(class_addIvar(dyn, "count", sizeof(int), 2, "i")));

    say("addMethod=%s", YN(class_addMethod(dyn, sel_registerName("answer"), (IMP)dyn_answer, "i@:")));
    say("addClassMethod=%s",
        YN(class_addMethod(object_getClass(dyn), sel_registerName("classAnswer"),
                           (IMP)dyn_classAnswer, "i@:")));
    say("addProtocol=%s", YN(class_addProtocol(dyn, @protocol(T4LDynProto))));

    // A second pair with the same name while the first is still UNREGISTERED
    // succeeds -- the duplicate check is against the registered class table,
    // not against pending pairs. Measured, and worth pinning: it is the kind of
    // detail a reimplementation would "fix".
    Class shadow = objc_allocateClassPair(root, "DynamicOne", 0);
    say("allocate.duplicate.while.unregistered=%s", NULLNESS(shadow));

    objc_registerClassPair(dyn);

    // Once registered, the name is taken.
    say("allocate.duplicate.after.register=%s",
        NULLNESS(objc_allocateClassPair(root, "DynamicOne", 0)));
    say("registered.lookUpClass=%s", YN(objc_lookUpClass("DynamicOne") == dyn));
    say("registered.getClass=%s", YN(objc_getClass("DynamicOne") == dyn));
    say("registered.metaclass=%s", YN(objc_getMetaClass("DynamicOne") == object_getClass(dyn)));
    say("registered.conformsTo=%s", YN(class_conformsToProtocol(dyn, @protocol(T4LDynProto))));

    // Ivars after registration must be refused.
    say("addIvar.after.register=%s", YN(class_addIvar(dyn, "late", sizeof(int), 2, "i")));
    // Methods after registration are still allowed.
    say("addMethod.after.register=%s",
        YN(class_addMethod(dyn, sel_registerName("lateAnswer"), (IMP)dyn_answer, "i@:")));

    say("instanceSize=%zu", (size_t)class_getInstanceSize(dyn));
    say("instanceSize.grew=%s", YN(class_getInstanceSize(dyn) > class_getInstanceSize(root)));

    Ivar cv = class_getInstanceVariable(dyn, "count");
    Ivar rv = class_getInstanceVariable(dyn, "ref");
    say("ivar.count.found=%s", NULLNESS(cv));
    say("ivar.ref.found=%s", NULLNESS(rv));
    say("ivar.count.type=%s", SAFESTR(ivar_getTypeEncoding(cv)));
    say("ivar.offsets.distinct=%s", YN(ivar_getOffset(cv) != ivar_getOffset(rv)));

    id o = class_createInstance(dyn, 0);
    say("instance=%s", NULLNESS(o));
    say("instance.class=%s", object_getClassName(o));
    say("dispatch.answer=%d", ((int (*)(id, SEL))objc_msgSend)(o, sel_registerName("answer")));
    say("dispatch.lateAnswer=%d", ((int (*)(id, SEL))objc_msgSend)(o, sel_registerName("lateAnswer")));
    say("dispatch.classAnswer=%d",
        ((int (*)(Class, SEL))objc_msgSend)(dyn, sel_registerName("classAnswer")));

    // Inherited from TestRoot.
    say("inherited.self=%s", YN(((id (*)(id, SEL))objc_msgSend)(o, @selector(self)) == o));

    id ref = [TestRoot new];
    object_setIvar(o, rv, ref);
    say("ivar.set=%s", YN(object_getIvar(o, rv) == ref));

    object_dispose(o);
    objc_release(ref);

    // A registered class with no live instances may be disposed.
    Class throwaway = objc_allocateClassPair(root, "DynamicThrowaway", 0);
    objc_registerClassPair(throwaway);
    say("throwaway.registered=%s", NULLNESS(objc_lookUpClass("DynamicThrowaway")));
    objc_disposeClassPair(throwaway);
    say("throwaway.after.dispose=%s", NULLNESS(objc_lookUpClass("DynamicThrowaway")));

    // extraBytes reserves space past the ivars.
    Class extra = objc_allocateClassPair(root, "DynamicExtra", 16);
    objc_registerClassPair(extra);
    say("extra.instanceSize=%zu", (size_t)class_getInstanceSize(extra));
    return 0;
}
