// 021-protocol-methods -- protocol_getMethodDescription across the
// required/optional x instance/class matrix. A protocol stores four separate
// method lists and the two booleans select between them; getting the selection
// backwards is invisible until someone asks for an optional class method.
#include "testsupport.h"

@protocol T4LMatrix
- (int)reqInstance:(int)a;
+ (int)reqClass:(int)a;
@optional
- (double)optInstance;
+ (double)optClass;
@end

@interface MatrixUser : TestRoot <T4LMatrix>
@end
@implementation MatrixUser
- (int)reqInstance:(int)a { return a; }
+ (int)reqClass:(int)a { return a; }
@end

static void desc(Protocol *p, const char *selname, BOOL required, BOOL instance) {
    SEL s = sel_registerName(selname);
    struct objc_method_description d =
        protocol_getMethodDescription(p, s, required, instance);
    say("%s.req%d.inst%d.name=%s", selname, (int)required, (int)instance,
        d.name ? sel_getName(d.name) : "(none)");
    say("%s.req%d.inst%d.types=%s", selname, (int)required, (int)instance,
        SAFESTR(d.types));
}

static void dumplist(Protocol *p, BOOL required, BOOL instance) {
    unsigned n = 0;
    struct objc_method_description *d =
        protocol_copyMethodDescriptionList(p, required, instance, &n);
    char buf[32][160];
    const char *ptrs[32];
    unsigned kept = 0;
    for (unsigned i = 0; i < n && kept < 32; i++) {
        snprintf(buf[kept], sizeof buf[0], "%s|%s",
                 d[i].name ? sel_getName(d[i].name) : "(none)", SAFESTR(d[i].types));
        ptrs[kept] = buf[kept];
        kept++;
    }
    free(d);
    sort_strings(ptrs, kept);
    for (unsigned i = 0; i < kept; i++)
        say("list.req%d.inst%d[%u]=%s", (int)required, (int)instance, i, ptrs[i]);
    say("list.req%d.inst%d.count=%u", (int)required, (int)instance, n);
}

int main(void) {
    Protocol *p = objc_getProtocol("T4LMatrix");
    say("protocol.found=%s", NULLNESS(p));
    say("protocol.name=%s", protocol_getName(p));

    // Each of the four methods, queried in all four ways.
    static const char *const kSels[] = {"reqInstance:", "reqClass:", "optInstance", "optClass"};
    for (unsigned i = 0; i < 4; i++) {
        desc(p, kSels[i], YES, YES);
        desc(p, kSels[i], YES, NO);
        desc(p, kSels[i], NO,  YES);
        desc(p, kSels[i], NO,  NO);
    }

    // A selector the protocol does not declare at all.
    desc(p, "notInProtocol", YES, YES);

    dumplist(p, YES, YES);
    dumplist(p, YES, NO);
    dumplist(p, NO,  YES);
    dumplist(p, NO,  NO);

    // The conforming class implements the required ones and not the optional.
    Class cls = objc_getClass("MatrixUser");
    say("class.responds.reqInstance=%s",
        YN(class_respondsToSelector(cls, @selector(reqInstance:))));
    say("class.responds.optInstance=%s",
        YN(class_respondsToSelector(cls, sel_registerName("optInstance"))));
    say("meta.responds.reqClass=%s",
        YN(class_respondsToSelector(object_getClass(cls), @selector(reqClass:))));

    MatrixUser *o = [MatrixUser new];
    say("dispatch.reqInstance=%d", [o reqInstance:7]);
    say("dispatch.reqClass=%d", [MatrixUser reqClass:9]);
    objc_release(o);
    return 0;
}
