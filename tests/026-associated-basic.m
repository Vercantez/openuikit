// 026-associated-basic -- objc_setAssociatedObject / getAssociatedObject.
// Keys are compared by pointer identity, never by value.
#include "testsupport.h"

@interface Host : TestRoot @end
@implementation Host @end

@interface Value : TestRoot { @public int tag; }
@end
@implementation Value @end

static char kKeyA;
static char kKeyB;
static const char kKeyC[] = "these bytes are never dereferenced";

static Value *mkvalue(int tag) {
    Value *v = [Value new];
    v->tag = tag;
    return v;
}

int main(void) {
    Host *h1 = [Host new];
    Host *h2 = [Host new];

    say("empty.get=%s", NULLNESS(objc_getAssociatedObject(h1, &kKeyA)));

    Value *a = mkvalue(1);
    objc_setAssociatedObject(h1, &kKeyA, a, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    say("set.then.get=%s", YN(objc_getAssociatedObject(h1, &kKeyA) == a));
    say("get.tag=%d", ((Value *)objc_getAssociatedObject(h1, &kKeyA))->tag);

    // Distinct keys are distinct slots, even when adjacent in memory.
    Value *b = mkvalue(2);
    objc_setAssociatedObject(h1, &kKeyB, b, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    say("keyA.unchanged=%s", YN(objc_getAssociatedObject(h1, &kKeyA) == a));
    say("keyB=%s", YN(objc_getAssociatedObject(h1, &kKeyB) == b));

    // Keys are pointers, not strings.
    objc_setAssociatedObject(h1, kKeyC, a, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    say("keyC=%s", YN(objc_getAssociatedObject(h1, kKeyC) == a));
    say("keyC.copy.of.string.differs=%s",
        NULLNESS(objc_getAssociatedObject(h1, "these bytes are never dereferenced")));

    // Associations are per-object.
    say("other.host.keyA=%s", NULLNESS(objc_getAssociatedObject(h2, &kKeyA)));

    // Overwriting replaces.
    Value *c = mkvalue(3);
    objc_setAssociatedObject(h1, &kKeyA, c, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    say("overwrite=%s", YN(objc_getAssociatedObject(h1, &kKeyA) == c));

    // Setting nil removes the association.
    objc_setAssociatedObject(h1, &kKeyA, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    say("set.nil.removes=%s", NULLNESS(objc_getAssociatedObject(h1, &kKeyA)));
    say("sibling.key.survives=%s", YN(objc_getAssociatedObject(h1, &kKeyB) == b));

    // objc_removeAssociatedObjects clears every key at once.
    objc_setAssociatedObject(h1, &kKeyA, a, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_removeAssociatedObjects(h1);
    say("removeAll.keyA=%s", NULLNESS(objc_getAssociatedObject(h1, &kKeyA)));
    say("removeAll.keyB=%s", NULLNESS(objc_getAssociatedObject(h1, &kKeyB)));
    say("removeAll.keyC=%s", NULLNESS(objc_getAssociatedObject(h1, kKeyC)));

    // Classes are objects too, and can carry associations.
    objc_setAssociatedObject((id)objc_getClass("Host"), &kKeyA, a,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    say("class.association=%s",
        YN(objc_getAssociatedObject((id)objc_getClass("Host"), &kKeyA) == a));
    objc_setAssociatedObject((id)objc_getClass("Host"), &kKeyA, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // nil object: get is tolerated, and so is set-nil-to-nil. Setting a
    // NON-nil value on a nil object is not -- objc4 explicitly handles only
    // the (!object && !value) case (rdar://44094390) and segfaults otherwise.
    // Measured: an earlier draft of this test crashed here on macOS.
    say("nil.object.get=%s", NULLNESS(objc_getAssociatedObject(nil, &kKeyA)));
    objc_setAssociatedObject(nil, &kKeyA, nil, OBJC_ASSOCIATION_ASSIGN);
    say("nil.object.nil.value.set.survived=yes");

    objc_release(a); objc_release(b); objc_release(c);
    objc_release(h1); objc_release(h2);
    say("dealloc.count=%d", g_dealloc_count);
    return 0;
}
