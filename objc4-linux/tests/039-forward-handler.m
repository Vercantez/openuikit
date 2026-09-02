// 039-forward-handler -- the end of the lookup chain.
//
// objc4 alone has no forwarding machinery: -forwardingTargetForSelector: and
// -forwardInvocation: live in CoreFoundation/Foundation, and with neither
// present an unhandled selector reaches objc_defaultForwardHandler, which
// aborts. What objc4 DOES provide is objc_setForwardHandler, and installing one
// is the only way to observe the forwarding path in a Foundation-less program.
//
// Because the handler is process-global and replaces the abort, this test does
// the destructive part last.
#include "testsupport.h"

@interface Fwd : TestRoot
- (int)implemented;
@end
@implementation Fwd
- (int)implemented { return 1; }
@end

static int g_forwards;
static char g_lastSel[64];
static int g_receiverWasFwd;

static id my_forward(id self, SEL sel) {
    g_forwards++;
    snprintf(g_lastSel, sizeof g_lastSel, "%s", sel_getName(sel));
    g_receiverWasFwd = (object_getClass(self) == objc_getClass("Fwd"));
    return (id)0;
}

int main(void) {
    Class cls = objc_getClass("Fwd");
    Fwd *o = [Fwd new];

    // The forwarding IMP is observable before anything is installed.
    SEL missing = sel_registerName("notImplementedAnywhere");
    IMP fwdImp = class_getMethodImplementation(cls, missing);
    say("forward.imp=%s", NULLNESS((void *)fwdImp));
    say("forward.imp.not.real=%s",
        YN(fwdImp != class_getMethodImplementation(cls, @selector(implemented))));
    say("forward.imp.stable=%s",
        YN(fwdImp == class_getMethodImplementation(cls, missing)));
    say("respondsToSelector.missing=%s", YN(class_respondsToSelector(cls, missing)));

    // Normal dispatch is unaffected.
    say("implemented=%d", [o implemented]);

    // Install our own handler and drive the forwarding path.
    objc_setForwardHandler((void *)my_forward, (void *)my_forward);
    say("installed=yes");

    id r = ((id (*)(id, SEL))objc_msgSend)(o, missing);
    say("forward.count=%d", g_forwards);
    say("forward.selector=%s", g_lastSel);
    say("forward.receiver.correct=%s", YN(g_receiverWasFwd));
    say("forward.return=%s", NULLNESS(r));

    // A second, different selector goes through the same handler.
    ((id (*)(id, SEL))objc_msgSend)(o, sel_registerName("alsoMissing:"));
    say("forward.count2=%d", g_forwards);
    say("forward.selector2=%s", g_lastSel);

    // Class-side forwarding.
    ((id (*)(Class, SEL))objc_msgSend)(cls, sel_registerName("missingClassMethod"));
    say("forward.count3=%d", g_forwards);
    say("forward.selector3=%s", g_lastSel);

    // Implemented selectors still never reach the handler.
    int before = g_forwards;
    say("implemented.again=%d", [o implemented]);
    say("implemented.did.not.forward=%s", YN(g_forwards == before));

    objc_release(o);
    return 0;
}
