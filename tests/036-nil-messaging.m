// 036-nil-messaging -- messages to nil return zero of the right shape.
// The zero-return for floating point and for large struct returns is handled
// by the assembly entry points, not by C, so this is really a test of
// objc_msgSend's nil check on each return path.
#include "testsupport.h"

typedef struct { int a, b; }             SmallS;
typedef struct { double a, b, c, d, e; } BigS;

@interface Nilable : TestRoot
- (int)anInt;
- (long long)aLongLong;
- (float)aFloat;
- (double)aDouble;
- (id)anObject;
- (char *)aPointer;
- (SmallS)aSmall;
- (BigS)aBig;
- (void)aVoid;
@end
@implementation Nilable
- (int)anInt { return 1; }
- (long long)aLongLong { return 1; }
- (float)aFloat { return 1; }
- (double)aDouble { return 1; }
- (id)anObject { return self; }
- (char *)aPointer { return (char *)"x"; }
- (SmallS)aSmall { SmallS s = {1, 2}; return s; }
- (BigS)aBig { BigS s = {1, 2, 3, 4, 5}; return s; }
- (void)aVoid { }
@end

int main(void) {
    Nilable *n = nil;

    say("int=%d", [n anInt]);
    say("longlong=%lld", [n aLongLong]);
    say("float=%.4f", (double)[n aFloat]);
    say("double=%.4f", [n aDouble]);
    say("object=%s", NULLNESS([n anObject]));
    say("pointer=%s", NULLNESS([n aPointer]));
    [n aVoid];
    say("void=ok");

    SmallS s = [n aSmall];
    say("small=%d,%d", s.a, s.b);

    // Large struct return: the caller supplies the buffer, so the runtime must
    // leave it zeroed rather than write garbage. Pre-fill to prove it.
    BigS big = {9, 9, 9, 9, 9};
    big = [n aBig];
    say("big=%.1f,%.1f,%.1f,%.1f,%.1f", big.a, big.b, big.c, big.d, big.e);

    // A selector that no class implements, sent to nil, is still fine.
    say("unknown.to.nil=%s",
        NULLNESS(((id (*)(id, SEL))objc_msgSend)(nil, sel_registerName("noSuchThing"))));

    // nil receiver through introspection APIs.
    say("object_getClass.nil=%s", NULLNESS(object_getClass(nil)));
    say("object_getClassName.nil=%s", object_getClassName(nil));

    // Class-side nil.
    Class c = Nil;
    say("class.nil.msg=%s", NULLNESS(((id (*)(Class, SEL))objc_msgSend)(c, @selector(alloc))));

    // A real receiver still works after all that.
    Nilable *real = [Nilable new];
    say("real.int=%d", [real anInt]);
    objc_release(real);
    return 0;
}
