// 017-ivars -- ivar lookup, offsets, and get/set through the runtime.
// Offsets are printed absolutely. They are not addresses: they are the ABI, and
// if Linux disagrees with Darwin about them the port is broken in a way that
// only shows up as memory corruption later.
#include "testsupport.h"

@interface Ivars : TestRoot {
@public
    int      i32;
    double   dbl;
    char     ch;
    void    *ptr;
    id       obj;
    long long i64;
}
@end
@implementation Ivars @end

int main(void) {
    Class cls = objc_getClass("Ivars");

    // TestRoot contributes only `isa`, so these offsets are fully determined.
    say("root.instanceSize=%zu", (size_t)class_getInstanceSize(objc_getClass("TestRoot")));
    say("ivars.instanceSize=%zu", (size_t)class_getInstanceSize(cls));

    static const char *const kIvars[] = {"i32", "dbl", "ch", "ptr", "obj", "i64"};
    for (unsigned k = 0; k < sizeof(kIvars)/sizeof(kIvars[0]); k++) {
        Ivar v = class_getInstanceVariable(cls, kIvars[k]);
        say("%s.found=%s", kIvars[k], NULLNESS(v));
        if (!v) continue;
        say("%s.name=%s", kIvars[k], ivar_getName(v));
        say("%s.offset=%ld", kIvars[k], (long)ivar_getOffset(v));
        say("%s.type=%s", kIvars[k], SAFESTR(ivar_getTypeEncoding(v)));
    }

    say("missing.ivar=%s", NULLNESS(class_getInstanceVariable(cls, "noSuchIvar")));
    say("nilclass.ivar=%s", NULLNESS(class_getInstanceVariable(Nil, "i32")));

    Ivars *o = [Ivars new];

    // Freshly allocated instances are zeroed.
    say("fresh.i32=%d", o->i32);
    say("fresh.ptr=%s", NULLNESS(o->ptr));
    say("fresh.obj=%s", NULLNESS(o->obj));

    // object_getInstanceVariable / object_setInstanceVariable operate on
    // pointer-sized slots only; that is the documented restriction.
    void *out = (void *)0x1;
    Ivar got = object_getInstanceVariable(o, "ptr", &out);
    say("getInstanceVariable.returns.ivar=%s", NULLNESS(got));
    say("getInstanceVariable.value=%s", NULLNESS(out));

    char storage[4] = {0};
    object_setInstanceVariable(o, "ptr", storage);
    object_getInstanceVariable(o, "ptr", &out);
    say("setInstanceVariable.roundtrip=%s", YN(out == (void *)storage));

    // object_getIvar / object_setIvar take an Ivar and work on object slots.
    id other = [TestRoot new];
    Ivar objIvar = class_getInstanceVariable(cls, "obj");
    say("objIvar.before=%s", NULLNESS(object_getIvar(o, objIvar)));
    object_setIvar(o, objIvar, other);
    say("objIvar.after=%s", YN(object_getIvar(o, objIvar) == other));
    say("objIvar.matches.direct=%s", YN(o->obj == other));
    object_setIvar(o, objIvar, nil);
    say("objIvar.cleared=%s", NULLNESS(object_getIvar(o, objIvar)));

    // Direct writes and runtime reads must agree on the same storage.
    o->i32 = 0x11223344;
    o->dbl = 2.5;
    o->i64 = -9007199254740993LL;
    say("direct.i32=%d", o->i32);
    say("direct.dbl=%.4f", o->dbl);
    say("direct.i64=%lld", o->i64);

    // class_getInstanceVariable is stable across calls.
    say("ivar.lookup.stable=%s",
        YN(class_getInstanceVariable(cls, "dbl") == class_getInstanceVariable(cls, "dbl")));

    objc_release(o); objc_release(other);
    return 0;
}
