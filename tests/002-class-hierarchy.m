// 002-class-hierarchy -- inheritance chains for classes and metaclasses.
// The parallel-hierarchy rule (metaclass chain mirrors the class chain, then
// hops to the root CLASS) is the single most load-bearing structural invariant
// in the runtime; a port that gets it wrong still "works" until +initialize.
#include "testsupport.h"

@interface A : TestRoot @end
@implementation A @end
@interface B : A @end
@implementation B @end
@interface C : B @end
@implementation C @end

static void print_chain(const char *label, Class c) {
    char buf[512];
    buf[0] = '\0';
    int steps = 0;
    while (c && steps < 16) {
        if (buf[0]) strcat(buf, "->");
        strcat(buf, class_getName(c));
        strcat(buf, class_isMetaClass(c) ? "(meta)" : "(cls)");
        c = class_getSuperclass(c);
        steps++;
    }
    say("%s=%s", label, buf);
    say("%s.length=%d", label, steps);
}

int main(void) {
    Class a = objc_getClass("A"), b = objc_getClass("B"), c = objc_getClass("C");

    print_chain("chain.C", c);
    print_chain("chain.Cmeta", object_getClass(c));

    say("C.super==B=%s", YN(class_getSuperclass(c) == b));
    say("B.super==A=%s", YN(class_getSuperclass(b) == a));
    say("A.super==TestRoot=%s", YN(class_getSuperclass(a) == objc_getClass("TestRoot")));

    // Every metaclass in a chain has the ROOT metaclass as its isa, not its
    // own class's metaclass.
    Class rootMeta = object_getClass(objc_getClass("TestRoot"));
    say("Ameta.isa==rootMeta=%s", YN(object_getClass(object_getClass(a)) == rootMeta));
    say("Cmeta.isa==rootMeta=%s", YN(object_getClass(object_getClass(c)) == rootMeta));

    // Instances of every class in the chain are distinct classes.
    id ia = [A new], ib = [B new], ic = [C new];
    say("ia.class=%s", object_getClassName(ia));
    say("ib.class=%s", object_getClassName(ib));
    say("ic.class=%s", object_getClassName(ic));
    say("ia.class!=ib.class=%s", YN(object_getClass(ia) != object_getClass(ib)));

    // Manual isKindOf walk -- no NSObject to ask.
    Class walk = object_getClass(ic);
    int found = 0;
    while (walk) { if (walk == a) { found = 1; break; } walk = class_getSuperclass(walk); }
    say("C.isKindOf.A=%s", YN(found));

    walk = object_getClass(ia);
    found = 0;
    while (walk) { if (walk == c) { found = 1; break; } walk = class_getSuperclass(walk); }
    say("A.isKindOf.C=%s", YN(found));

    objc_release(ia); objc_release(ib); objc_release(ic);
    say("dealloc.count=%d", g_dealloc_count);
    return 0;
}
