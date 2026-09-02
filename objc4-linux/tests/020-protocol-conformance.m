// 020-protocol-conformance -- who conforms to what.
// Note the asymmetry this pins down: class_conformsToProtocol reports only
// protocols listed on that exact class, NOT protocols reached through the
// protocol's own inheritance, and NOT protocols on the superclass.
#include "testsupport.h"

@protocol T4LBase
- (void)baseRequired;
@optional
- (void)baseOptional;
@end

@protocol T4LDerived <T4LBase>
- (void)derivedRequired;
@end

@protocol T4LOther
- (void)otherRequired;
@end

@protocol T4LNeverReferenced
- (void)never;
@end

@interface Conformer : TestRoot <T4LDerived>
- (void)baseRequired;
- (void)derivedRequired;
@end
@implementation Conformer
- (void)baseRequired { }
- (void)derivedRequired { }
@end

@interface ConformerSub : Conformer @end
@implementation ConformerSub @end

@interface Conformer (AddsProtocol) <T4LOther>
- (void)otherRequired;
@end
@implementation Conformer (AddsProtocol)
- (void)otherRequired { }
@end

@interface Unrelated : TestRoot @end
@implementation Unrelated @end

int main(void) {
    Protocol *base    = objc_getProtocol("T4LBase");
    Protocol *derived = objc_getProtocol("T4LDerived");
    Protocol *other   = objc_getProtocol("T4LOther");

    say("base.found=%s", NULLNESS(base));
    say("derived.found=%s", NULLNESS(derived));
    say("base.name=%s", protocol_getName(base));
    say("derived.name=%s", protocol_getName(derived));
    say("missing.protocol=%s", NULLNESS(objc_getProtocol("T4LNoSuchProtocol")));
    say("neverReferenced.found=%s", NULLNESS(objc_getProtocol("T4LNeverReferenced")));

    // @protocol(X) and objc_getProtocol("X") must agree.
    say("atprotocol.matches.lookup=%s", YN(@protocol(T4LDerived) == derived));
    say("protocol_isEqual.self=%s", YN(protocol_isEqual(derived, derived)));
    say("protocol_isEqual.other=%s", YN(protocol_isEqual(derived, base)));

    // Protocol-to-protocol.
    say("derived.conformsTo.base=%s", YN(protocol_conformsToProtocol(derived, base)));
    say("base.conformsTo.derived=%s", YN(protocol_conformsToProtocol(base, derived)));
    say("derived.conformsTo.self=%s", YN(protocol_conformsToProtocol(derived, derived)));
    say("derived.conformsTo.other=%s", YN(protocol_conformsToProtocol(derived, other)));

    Class conf = objc_getClass("Conformer");
    Class sub  = objc_getClass("ConformerSub");
    Class unrelated = objc_getClass("Unrelated");

    say("class.conformsTo.derived=%s", YN(class_conformsToProtocol(conf, derived)));
    say("class.conformsTo.base=%s", YN(class_conformsToProtocol(conf, base)));
    say("class.conformsTo.other.viaCategory=%s", YN(class_conformsToProtocol(conf, other)));
    say("sub.conformsTo.derived=%s", YN(class_conformsToProtocol(sub, derived)));
    say("unrelated.conformsTo.base=%s", YN(class_conformsToProtocol(unrelated, base)));
    say("nilclass.conformsTo=%s", YN(class_conformsToProtocol(Nil, base)));

    // The class's own protocol list, sorted.
    unsigned n = 0;
    Protocol * __unsafe_unretained *ps = class_copyProtocolList(conf, &n);
    const char *names[32];
    unsigned kept = 0;
    for (unsigned i = 0; i < n && kept < 32; i++) names[kept++] = protocol_getName(ps[i]);
    print_sorted_strings("conformer.protocols", names, kept);
    free(ps);

    unsigned sn = 0;
    Protocol * __unsafe_unretained *sps = class_copyProtocolList(sub, &sn);
    say("sub.ownProtocolCount=%u", sn);
    free(sps);

    // Protocols reachable from a protocol.
    unsigned pn = 0;
    Protocol * __unsafe_unretained *pps = protocol_copyProtocolList(derived, &pn);
    const char *pnames[32];
    unsigned pkept = 0;
    for (unsigned i = 0; i < pn && pkept < 32; i++) pnames[pkept++] = protocol_getName(pps[i]);
    print_sorted_strings("derived.parents", pnames, pkept);
    free(pps);

    // class_addProtocol at runtime.
    say("unrelated.before.add=%s", YN(class_conformsToProtocol(unrelated, other)));
    say("addProtocol=%s", YN(class_addProtocol(unrelated, other)));
    say("unrelated.after.add=%s", YN(class_conformsToProtocol(unrelated, other)));
    say("addProtocol.again=%s", YN(class_addProtocol(unrelated, other)));
    return 0;
}
