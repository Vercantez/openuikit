// 035-method-resolution -- +resolveInstanceMethod / +resolveClassMethod.
// This is the last hook before forwarding, it runs inside lookUpImpOrForward,
// and it must be asked exactly once per unresolved selector per class.
#include "testsupport.h"

static int g_resolveInstanceCalls;
static int g_resolveClassCalls;
static char g_lastResolveInstance[64];
static char g_lastResolveClass[64];

static int resolved_instance_imp(id self, SEL _cmd) { (void)self; (void)_cmd; return 777; }
static int resolved_class_imp(Class self, SEL _cmd) { (void)self; (void)_cmd; return 888; }

@interface Resolver : TestRoot
+ (BOOL)resolveInstanceMethod:(SEL)sel;
+ (BOOL)resolveClassMethod:(SEL)sel;
@end

@implementation Resolver
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    g_resolveInstanceCalls++;
    snprintf(g_lastResolveInstance, sizeof g_lastResolveInstance, "%s", sel_getName(sel));
    if (strcmp(sel_getName(sel), "dynamicInstance") == 0) {
        class_addMethod(self, sel, (IMP)resolved_instance_imp, "i@:");
        return YES;
    }
    return NO;
}
+ (BOOL)resolveClassMethod:(SEL)sel {
    g_resolveClassCalls++;
    snprintf(g_lastResolveClass, sizeof g_lastResolveClass, "%s", sel_getName(sel));
    if (strcmp(sel_getName(sel), "dynamicClass") == 0) {
        class_addMethod(object_getClass(self), sel, (IMP)resolved_class_imp, "i@:");
        return YES;
    }
    return NO;
}
@end

@interface ResolverSub : Resolver @end
@implementation ResolverSub @end

int main(void) {
    Class cls = objc_getClass("Resolver");
    Resolver *o = [Resolver new];

    // Not resolved yet.
    say("before.responds=%s", YN(class_respondsToSelector(cls, sel_registerName("dynamicInstance"))));
    say("before.calls=%d", g_resolveInstanceCalls);

    // class_respondsToSelector does NOT invoke the resolver.
    say("respondsToSelector.triggers.resolver=%s", YN(g_resolveInstanceCalls > 0));

    SEL dyn = sel_registerName("dynamicInstance");
    int r = ((int (*)(id, SEL))objc_msgSend)(o, dyn);
    say("dispatch.result=%d", r);
    say("after.dispatch.calls=%d", g_resolveInstanceCalls);
    say("resolved.selector=%s", g_lastResolveInstance);
    say("after.responds=%s", YN(class_respondsToSelector(cls, dyn)));

    // The resolver must not be asked again once the method exists.
    ((int (*)(id, SEL))objc_msgSend)(o, dyn);
    ((int (*)(id, SEL))objc_msgSend)(o, dyn);
    say("repeat.calls=%d", g_resolveInstanceCalls);

    // Class-side resolution goes through +resolveClassMethod:.
    SEL dync = sel_registerName("dynamicClass");
    say("classside.result=%d", ((int (*)(Class, SEL))objc_msgSend)(cls, dync));
    say("classside.calls=%d", g_resolveClassCalls);
    say("classside.selector=%s", g_lastResolveClass);
    say("classside.responds=%s", YN(class_respondsToSelector(object_getClass(cls), dync)));

    // A subclass inherits the resolver, and the method it adds lands on the
    // subclass (self inside +resolveInstanceMethod: is the subclass).
    int before = g_resolveInstanceCalls;
    SEL dyn2 = sel_registerName("dynamicInstance");
    ResolverSub *so = [ResolverSub new];
    say("sub.inherits.resolved=%d", ((int (*)(id, SEL))objc_msgSend)(so, dyn2));
    say("sub.did.not.reresolve=%s", YN(g_resolveInstanceCalls == before));

    // class_getMethodImplementation on an unresolvable selector still returns
    // the forwarding trampoline, and it DOES consult the resolver first.
    int b2 = g_resolveInstanceCalls;
    IMP fwd = class_getMethodImplementation(cls, sel_registerName("neverResolvable"));
    say("unresolvable.imp=%s", NULLNESS((void *)fwd));
    say("unresolvable.asked.resolver=%s", YN(g_resolveInstanceCalls > b2));
    say("unresolvable.last=%s", g_lastResolveInstance);

    // ... and it is asked again on the next lookup, because nothing was cached.
    int b3 = g_resolveInstanceCalls;
    (void)class_getMethodImplementation(cls, sel_registerName("neverResolvable"));
    say("unresolvable.asked.again=%s", YN(g_resolveInstanceCalls > b3));

    objc_release(o); objc_release(so);
    return 0;
}
