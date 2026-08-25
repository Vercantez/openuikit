// 034-runtime-lookup -- the name->class table and its edge cases.
// Deliberately does NOT enumerate objc_getClassList: on macOS that returns
// every class in libSystem and the answer is not comparable across platforms.
// Only classes this program defines are named.
#include "testsupport.h"

@interface Findable : TestRoot @end
@implementation Findable @end

@interface FindableSub : Findable @end
@implementation FindableSub @end

int main(void) {
    // getClass / lookUpClass agree for a class that exists.
    Class a = objc_getClass("Findable");
    Class b = objc_lookUpClass("Findable");
    say("getClass=%s", NULLNESS(a));
    say("lookUpClass.matches=%s", YN(a == b));
    say("getRequiredClass.matches=%s", YN(objc_getRequiredClass("Findable") == a));
    say("name=%s", class_getName(a));

    // Metaclass lookup by name.
    say("getMetaClass=%s", YN(objc_getMetaClass("Findable") == object_getClass(a)));
    say("metaclass.name.equals.class.name=%s",
        YN(strcmp(class_getName(object_getClass(a)), class_getName(a)) == 0));

    // Missing names.
    say("missing.get=%s", NULLNESS(objc_getClass("T4LNoSuchClass")));
    say("missing.lookUp=%s", NULLNESS(objc_lookUpClass("T4LNoSuchClass")));
    say("missing.meta=%s", NULLNESS(objc_getMetaClass("T4LNoSuchClass")));
    say("empty.name=%s", NULLNESS(objc_getClass("")));
    say("null.name=%s", NULLNESS(objc_getClass(NULL)));

    // Names are case-sensitive and exact.
    say("wrongcase=%s", NULLNESS(objc_getClass("findable")));
    say("prefix=%s", NULLNESS(objc_getClass("Findabl")));
    say("suffix=%s", NULLNESS(objc_getClass("FindableX")));

    // object_getClassName on instances, classes, metaclasses and nil.
    id o = [Findable new];
    say("instance.className=%s", object_getClassName(o));
    say("class.className=%s", object_getClassName((id)a));
    say("meta.className=%s", object_getClassName((id)object_getClass(a)));
    say("nil.className=%s", object_getClassName(nil));

    // class_getName on a metaclass and on Nil.
    say("nil.class_getName=%s", class_getName(Nil));
    say("class_isMetaClass.nil=%s", YN(class_isMetaClass(Nil)));

    // object_getClass on a class returns the metaclass; on a metaclass, the
    // root metaclass.
    say("objectGetClass.class=%s", YN(object_getClass((id)a) == objc_getMetaClass("Findable")));
    say("objectGetClass.meta=%s",
        YN(object_getClass((id)object_getClass(a)) ==
           object_getClass(objc_getClass("TestRoot"))));

    // objc_duplicateClass makes an independent copy that shares the superclass.
    Class dup = objc_duplicateClass(a, "Findable_Copy", 0);
    say("duplicate=%s", NULLNESS(dup));
    say("duplicate.name=%s", class_getName(dup));
    say("duplicate.super.same=%s", YN(class_getSuperclass(dup) == class_getSuperclass(a)));
    say("duplicate.is.distinct=%s", YN(dup != a));
    say("duplicate.size.same=%s", YN(class_getInstanceSize(dup) == class_getInstanceSize(a)));
    // Measured: objc_duplicateClass DOES publish the new name in the class
    // table, unlike objc_allocateClassPair which waits for the register call.
    say("duplicate.findable.by.name=%s", NULLNESS(objc_lookUpClass("Findable_Copy")));

    // class_getSuperclass chain endpoints.
    say("sub.super=%s", class_getName(class_getSuperclass(objc_getClass("FindableSub"))));
    say("root.super=%s", NULLNESS(class_getSuperclass(objc_getClass("TestRoot"))));
    say("nil.super=%s", NULLNESS(class_getSuperclass(Nil)));

    objc_release(o);
    return 0;
}
