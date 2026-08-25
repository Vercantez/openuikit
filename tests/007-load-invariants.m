// 007-load-invariants -- the parts of +load ordering that are contractual
// rather than incidental. 006 records the absolute order; this one records only
// the relations objc4 documents, so it stays meaningful even if ELF section
// ordering differs from Mach-O.
#include "testsupport.h"

@interface Gp : TestRoot @end
@implementation Gp + (void)load { event("Gp.load"); } @end

@interface Pa : Gp @end
@implementation Pa + (void)load { event("Pa.load"); } @end

@interface Ch : Pa @end
@implementation Ch + (void)load { event("Ch.load"); } @end

@interface Ch (Ext) @end
@implementation Ch (Ext) + (void)load { event("Ch(Ext).load"); } @end

// Does +load see a fully realized class? Everything in it must already work.
@interface Probe : TestRoot
+ (int)answer;
@end
@implementation Probe
+ (int)answer { return 42; }
+ (void)load {
    event("Probe.load");
    eventf("Probe.load.self=%s", class_getName(self));
    eventf("Probe.load.canDispatch=%s", YN([self answer] == 42));
    eventf("Probe.load.classLookupWorks=%s",
           YN(objc_getClass("Probe") == self));
    // Is a class that has not yet had +load run still findable by name?
    eventf("Probe.load.otherClassVisible=%s",
           NULLNESS(objc_getClass("Ch")));
}
@end

__attribute__((constructor)) static void ctor(void) { event("c-constructor"); }

int main(void) {
    event("main");

    // Every +load must precede main and precede the C constructor? -- measured,
    // not assumed. Print the relation rather than asserting it.
    say_order("Gp.load", "main");
    say_order("Ch(Ext).load", "main");
    say_order("c-constructor", "main");

    // Superclass before subclass. This one objc4 does guarantee.
    say_order("Gp.load", "Pa.load");
    say_order("Pa.load", "Ch.load");
    say_order("Gp.load", "Ch.load");

    // A category's +load runs after its class's own +load.
    say_order("Ch.load", "Ch(Ext).load");

    // Where does an ordinary C constructor sit relative to +load?
    say_order("Gp.load", "c-constructor");
    say_order("Probe.load", "c-constructor");

    print_events("ev");
    return 0;
}
