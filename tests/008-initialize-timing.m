// 008-initialize-timing -- exactly which runtime calls trigger +initialize.
//
// +load fires at image load; +initialize fires lazily, on the first message.
// But "message" is fuzzier than it sounds: several introspection entry points
// initialize the class as a side effect and several deliberately do not. Each
// probe below gets its own class so the previous probe cannot contaminate it.
#include "testsupport.h"

#define PROBE_CLASS(NAME)                                                    \
    static int NAME##_initialized;                                           \
    @interface NAME : TestRoot                                               \
    + (int)ping;                                                             \
    @end                                                                     \
    @implementation NAME                                                     \
    + (void)load { event(#NAME ".load"); }                                   \
    + (void)initialize { NAME##_initialized++; event(#NAME ".initialize"); }  \
    + (int)ping { return 1; }                                                \
    @end

PROBE_CLASS(PGetClass)
PROBE_CLASS(PResponds)
PROBE_CLASS(PGetInstanceMethod)
PROBE_CLASS(PGetMethodImplementation)
PROBE_CLASS(PCreateInstance)
PROBE_CLASS(PMessage)
PROBE_CLASS(PCopyMethodList)
PROBE_CLASS(PGetName)
PROBE_CLASS(PAddMethod)

static int dummy_imp(id self, SEL _cmd) { (void)self; (void)_cmd; return 0; }

int main(void) {
    event("main");

    // Nothing may have initialized before the first message.
    say("before.any=%d%d%d%d%d%d%d%d%d",
        PGetClass_initialized, PResponds_initialized,
        PGetInstanceMethod_initialized, PGetMethodImplementation_initialized,
        PCreateInstance_initialized, PMessage_initialized,
        PCopyMethodList_initialized, PGetName_initialized,
        PAddMethod_initialized);

    Class c;

    c = objc_getClass("PGetClass");
    say("objc_getClass.initializes=%s", YN(PGetClass_initialized));

    say("class_getName.result=%s", class_getName(objc_getClass("PGetName")));
    say("class_getName.initializes=%s", YN(PGetName_initialized));

    c = objc_getClass("PResponds");
    (void)class_respondsToSelector(c, @selector(ping));
    say("class_respondsToSelector.initializes=%s", YN(PResponds_initialized));

    c = objc_getClass("PGetInstanceMethod");
    (void)class_getInstanceMethod(c, @selector(ping));
    say("class_getInstanceMethod.initializes=%s", YN(PGetInstanceMethod_initialized));

    c = objc_getClass("PGetMethodImplementation");
    (void)class_getMethodImplementation(c, @selector(ping));
    say("class_getMethodImplementation.initializes=%s",
        YN(PGetMethodImplementation_initialized));

    c = objc_getClass("PCreateInstance");
    id inst = class_createInstance(c, 0);
    say("class_createInstance.initializes=%s", YN(PCreateInstance_initialized));
    object_dispose(inst);

    c = objc_getClass("PCopyMethodList");
    unsigned n = 0;
    free(class_copyMethodList(c, &n));
    say("class_copyMethodList.initializes=%s", YN(PCopyMethodList_initialized));

    c = objc_getClass("PAddMethod");
    class_addMethod(object_getClass(c), sel_registerName("addedProbe"), (IMP)dummy_imp, "i@:");
    say("class_addMethod.initializes=%s", YN(PAddMethod_initialized));

    // The unambiguous case.
    say("message.result=%d", [PMessage ping]);
    say("message.initializes=%s", YN(PMessage_initialized));

    // ... and exactly once, no matter how many messages follow.
    [PMessage ping]; [PMessage ping]; [PMessage ping];
    say("message.initialize.count=%d", PMessage_initialized);

    // +load always precedes +initialize for the same class.
    say_order("PMessage.load", "PMessage.initialize");
    say_order("PMessage.load", "main");
    say_order("main", "PMessage.initialize");

    print_events("ev");
    return 0;
}
