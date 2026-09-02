// 022-protocol-properties -- protocols carry property lists too, and the
// required/optional and instance/class splits apply to them as well.
#include "testsupport.h"

@protocol T4LPropProto
@property (nonatomic) int reqProp;
@property (readonly) id  reqObjProp;
@optional
@property double optProp;
@property (class, readonly) int classProp;
@end

@interface PropProtoUser : TestRoot <T4LPropProto>
@end
@implementation PropProtoUser
@synthesize reqProp;
@synthesize reqObjProp;
@end

static void one(Protocol *p, const char *name, BOOL required, BOOL instance) {
    objc_property_t prop = protocol_getProperty(p, name, required, instance);
    say("%s.req%d.inst%d=%s", name, (int)required, (int)instance,
        prop ? SAFESTR(property_getAttributes(prop)) : "(none)");
}

static void dumplist(Protocol *p, BOOL required, BOOL instance) {
    unsigned n = 0;
    objc_property_t *ps = protocol_copyPropertyList2(p, &n, required, instance);
    char buf[32][160];
    const char *ptrs[32];
    unsigned kept = 0;
    for (unsigned i = 0; i < n && kept < 32; i++) {
        snprintf(buf[kept], sizeof buf[0], "%s|%s",
                 property_getName(ps[i]), SAFESTR(property_getAttributes(ps[i])));
        ptrs[kept] = buf[kept];
        kept++;
    }
    free(ps);
    sort_strings(ptrs, kept);
    for (unsigned i = 0; i < kept; i++)
        say("plist.req%d.inst%d[%u]=%s", (int)required, (int)instance, i, ptrs[i]);
    say("plist.req%d.inst%d.count=%u", (int)required, (int)instance, n);
}

int main(void) {
    Protocol *p = objc_getProtocol("T4LPropProto");
    say("protocol.found=%s", NULLNESS(p));

    static const char *const kNames[] = {"reqProp", "reqObjProp", "optProp", "classProp"};
    for (unsigned i = 0; i < 4; i++) {
        one(p, kNames[i], YES, YES);
        one(p, kNames[i], NO,  YES);
        one(p, kNames[i], YES, NO);
        one(p, kNames[i], NO,  NO);
    }
    one(p, "notAProperty", YES, YES);

    dumplist(p, YES, YES);
    dumplist(p, NO,  YES);
    dumplist(p, YES, NO);
    dumplist(p, NO,  NO);

    // protocol_copyPropertyList is the legacy spelling: required + instance.
    unsigned n = 0;
    objc_property_t *legacy = protocol_copyPropertyList(p, &n);
    say("legacy.count=%u", n);
    free(legacy);

    // The conforming class synthesised the required ones.
    Class cls = objc_getClass("PropProtoUser");
    say("class.has.reqProp=%s", NULLNESS(class_getProperty(cls, "reqProp")));
    say("class.has.optProp=%s", NULLNESS(class_getProperty(cls, "optProp")));
    return 0;
}
