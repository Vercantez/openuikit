// 016-method-introspection -- what a Method tells you about itself.
#include "testsupport.h"

typedef struct { int a; double b; } Rec;

@interface Introspect : TestRoot
- (void)noArgs;
- (int)oneInt:(int)a;
- (Rec)mixed:(id)obj sel:(SEL)s ptr:(char *)p flt:(float)f;
- (double)many:(int)a b:(long)b c:(char)c d:(unsigned)d;
+ (void)aClassMethod;
@end
@implementation Introspect
- (void)noArgs { }
- (int)oneInt:(int)a { return a; }
- (Rec)mixed:(id)obj sel:(SEL)s ptr:(char *)p flt:(float)f {
    (void)obj; (void)s; (void)p; Rec r = {1, f}; return r;
}
- (double)many:(int)a b:(long)b c:(char)c d:(unsigned)d {
    return a + b + c + d;
}
+ (void)aClassMethod { }
@end

static void describe(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    const char *name = sel_getName(sel);
    if (!m) { say("%s=absent", name); return; }
    say("%s.name=%s", name, sel_getName(method_getName(m)));
    say("%s.types=%s", name, SAFESTR(method_getTypeEncoding(m)));
    say("%s.nargs=%u", name, method_getNumberOfArguments(m));
    char *ret = method_copyReturnType(m);
    say("%s.ret=%s", name, SAFESTR(ret));
    free(ret);
    for (unsigned i = 0; i < method_getNumberOfArguments(m); i++) {
        char *at = method_copyArgumentType(m, i);
        say("%s.arg[%u]=%s", name, i, SAFESTR(at));
        free(at);
    }
    // Out-of-range argument index.
    char *oob = method_copyArgumentType(m, method_getNumberOfArguments(m) + 5);
    say("%s.arg.oob=%s", name, SAFESTR(oob));
    free(oob);
}

int main(void) {
    Class cls = objc_getClass("Introspect");

    describe(cls, @selector(noArgs));
    describe(cls, @selector(oneInt:));
    describe(cls, @selector(mixed:sel:ptr:flt:));
    describe(cls, @selector(many:b:c:d:));

    // The class method lives on the metaclass.
    Method cm = class_getClassMethod(cls, @selector(aClassMethod));
    say("classMethod.types=%s", SAFESTR(method_getTypeEncoding(cm)));

    // The whole instance-method list of this class, sorted (emission order is
    // a linker artifact, not a semantic guarantee).
    unsigned n = 0;
    Method *ms = class_copyMethodList(cls, &n);
    const char *names[64];
    unsigned kept = 0;
    for (unsigned i = 0; i < n && kept < 64; i++)
        names[kept++] = sel_getName(method_getName(ms[i]));
    print_sorted_strings("methods", names, kept);
    free(ms);

    // A class with no methods of its own reports an empty list and NULL.
    Class root = objc_getClass("TestRoot");
    (void)root;
    unsigned zero = 12345;
    Method *none = class_copyMethodList(object_getClass(cls), &zero);
    say("metaclass.methodcount=%u", zero);
    free(none);

    // Missing selector: no Method, but class_getMethodImplementation still
    // returns something (the forwarding trampoline).
    SEL missing = sel_registerName("definitelyNotImplemented");
    say("missing.getInstanceMethod=%s", NULLNESS(class_getInstanceMethod(cls, missing)));
    say("missing.getMethodImplementation=%s",
        NULLNESS((void *)class_getMethodImplementation(cls, missing)));
    say("missing.imp.differs.from.real=%s",
        YN(class_getMethodImplementation(cls, missing) !=
           class_getMethodImplementation(cls, @selector(noArgs))));

    // Two different missing selectors get the same forwarding IMP.
    say("forward.imp.shared=%s",
        YN(class_getMethodImplementation(cls, missing) ==
           class_getMethodImplementation(cls, sel_registerName("alsoNotImplemented"))));
    return 0;
}
