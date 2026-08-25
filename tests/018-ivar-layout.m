// 018-ivar-layout -- non-fragile ivar layout across an inheritance chain.
// class_copyIvarList reports only a class's OWN ivars; a subclass's ivars must
// begin at or after the superclass's instance size.
#include "testsupport.h"

@interface LBase : TestRoot { @public int baseA; char baseB; }
@end
@implementation LBase @end

@interface LMid : LBase { @public double midA; }
@end
@implementation LMid @end

@interface LLeaf : LMid { @public id leafA; short leafB; }
@end
@implementation LLeaf @end

@interface LEmpty : LLeaf @end
@implementation LEmpty @end

static void dump(const char *label, Class cls) {
    say("%s.instanceSize=%zu", label, (size_t)class_getInstanceSize(cls));
    unsigned n = 0;
    Ivar *v = class_copyIvarList(cls, &n);
    say("%s.ownIvarCount=%u", label, n);
    // Sort by name so emission order cannot leak into the output, then print
    // each ivar's offset -- the offsets themselves are the ABI.
    const char *names[32];
    for (unsigned i = 0; i < n && i < 32; i++) names[i] = ivar_getName(v[i]);
    sort_strings(names, n < 32 ? n : 32);
    for (unsigned i = 0; i < n && i < 32; i++) {
        Ivar iv = class_getInstanceVariable(cls, names[i]);
        say("%s.ivar[%s].offset=%ld", label, names[i], (long)ivar_getOffset(iv));
        say("%s.ivar[%s].type=%s", label, names[i], SAFESTR(ivar_getTypeEncoding(iv)));
    }
    free(v);
}

int main(void) {
    Class base = objc_getClass("LBase");
    Class mid  = objc_getClass("LMid");
    Class leaf = objc_getClass("LLeaf");
    Class empty = objc_getClass("LEmpty");

    dump("base", base);
    dump("mid", mid);
    dump("leaf", leaf);
    dump("empty", empty);

    // Superclass ivars are not in the subclass's own list ...
    say("mid.owns.baseA=%s",
        YN(class_getInstanceVariable(mid, "baseA") ==
           class_getInstanceVariable(base, "baseA")));
    unsigned n = 0;
    Ivar *v = class_copyIvarList(mid, &n);
    int sawBaseA = 0;
    for (unsigned i = 0; i < n; i++)
        if (strcmp(ivar_getName(v[i]), "baseA") == 0) sawBaseA = 1;
    free(v);
    say("mid.ownList.contains.baseA=%s", YN(sawBaseA));

    // ... but they are still reachable by lookup from the subclass.
    say("leaf.finds.baseA=%s", NULLNESS(class_getInstanceVariable(leaf, "baseA")));
    say("leaf.finds.midA=%s", NULLNESS(class_getInstanceVariable(leaf, "midA")));

    // Sizes are monotonic; an ivar-less subclass adds nothing.
    say("size.base<=mid=%s", YN(class_getInstanceSize(base) <= class_getInstanceSize(mid)));
    say("size.mid<=leaf=%s", YN(class_getInstanceSize(mid) <= class_getInstanceSize(leaf)));
    say("size.leaf==empty=%s", YN(class_getInstanceSize(leaf) == class_getInstanceSize(empty)));

    // Subclass ivars start at or after the superclass's instance size.
    Ivar midA = class_getInstanceVariable(mid, "midA");
    say("midA.after.base=%s",
        YN((size_t)ivar_getOffset(midA) >= class_getInstanceSize(base)));
    Ivar leafA = class_getInstanceVariable(leaf, "leafA");
    say("leafA.after.mid=%s",
        YN((size_t)ivar_getOffset(leafA) >= class_getInstanceSize(mid)));

    // Writing every ivar through the full chain must not alias.
    LLeaf *o = [LLeaf new];
    o->baseA = 11; o->baseB = 'x'; o->midA = 3.5; o->leafB = 77;
    say("noalias.baseA=%d", o->baseA);
    say("noalias.baseB=%c", o->baseB);
    say("noalias.midA=%.2f", o->midA);
    say("noalias.leafB=%d", (int)o->leafB);
    say("noalias.leafA=%s", NULLNESS(o->leafA));

    objc_release(o);
    return 0;
}
