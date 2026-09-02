// 019-properties -- property attribute strings.
// The attribute string is a wire format Swift, KVC and every serializer read.
// Its exact spelling and the ORDER of its components are the specification.
#include "testsupport.h"

typedef struct { int x, y; } Point;

@interface Props : TestRoot
@property                        int       plain;
@property (readonly)             int       ro;
@property (nonatomic)            int       nonatomicInt;
@property (nonatomic, readonly)  double    nonatomicRo;
@property (assign)               id        assigned;
@property (retain)               id        retained;
@property (copy)                 id        copied;
@property (retain, nonatomic)    id        retainedNonatomic;
@property (getter=isFlagged)     BOOL      flagged;
@property (setter=assignName:)   char     *name;
@property                        SEL       selector;
@property                        Class     klass;
@property                        Point     point;
@property                        char     *cstring;
@property                        const char *constCstring;
@property (readonly, getter=customGetter) int bothCustom;
@property (class, readonly)      int       classProp;
@end

@implementation Props
@synthesize plain, ro, nonatomicInt, nonatomicRo, assigned, retained, copied;
@synthesize retainedNonatomic, flagged, name, selector, klass, point, cstring;
@synthesize constCstring, bothCustom;
+ (int)classProp { return 5; }
@end

// A property added by a category, and one on a subclass.
@interface Props (Cat)
@property (nonatomic) int fromCategory;
@end
@implementation Props (Cat)
- (int)fromCategory { return 1; }
- (void)setFromCategory:(int)v { (void)v; }
@end

@interface PropsSub : Props
@property int subOnly;
@end
@implementation PropsSub
@synthesize subOnly;
@end

static void show(Class cls, const char *name) {
    objc_property_t p = class_getProperty(cls, name);
    if (!p) { say("%s=absent", name); return; }
    say("%s.name=%s", name, property_getName(p));
    say("%s.attrs=%s", name, SAFESTR(property_getAttributes(p)));
    // The parsed form, sorted, so component order in the list cannot leak.
    unsigned n = 0;
    objc_property_attribute_t *list = property_copyAttributeList(p, &n);
    char buf[32][96];
    const char *ptrs[32];
    unsigned kept = 0;
    for (unsigned i = 0; i < n && kept < 32; i++) {
        snprintf(buf[kept], sizeof buf[0], "%s=%s",
                 SAFESTR(list[i].name), SAFESTR(list[i].value));
        ptrs[kept] = buf[kept];
        kept++;
    }
    free(list);
    sort_strings(ptrs, kept);
    for (unsigned i = 0; i < kept; i++) say("%s.attr[%u]=%s", name, i, ptrs[i]);
}

int main(void) {
    Class cls = objc_getClass("Props");

    static const char *const kProps[] = {
        "plain", "ro", "nonatomicInt", "nonatomicRo", "assigned", "retained",
        "copied", "retainedNonatomic", "flagged", "name", "selector", "klass",
        "point", "cstring", "constCstring", "bothCustom", "fromCategory",
    };
    for (unsigned i = 0; i < sizeof(kProps)/sizeof(kProps[0]); i++)
        show(cls, kProps[i]);

    // Class properties live on the metaclass.
    say("classProp.on.class=%s", NULLNESS(class_getProperty(cls, "classProp")));
    say("classProp.on.meta=%s", NULLNESS(class_getProperty(object_getClass(cls), "classProp")));
    show(object_getClass(cls), "classProp");

    // Whole list, sorted.
    unsigned n = 0;
    objc_property_t *ps = class_copyPropertyList(cls, &n);
    const char *names[64];
    unsigned kept = 0;
    for (unsigned i = 0; i < n && kept < 64; i++) names[kept++] = property_getName(ps[i]);
    print_sorted_strings("props", names, kept);
    free(ps);

    // Subclass lists only its own; lookup still finds inherited ones.
    Class sub = objc_getClass("PropsSub");
    unsigned sn = 0;
    objc_property_t *sps = class_copyPropertyList(sub, &sn);
    say("sub.ownPropertyCount=%u", sn);
    free(sps);
    say("sub.finds.inherited=%s", NULLNESS(class_getProperty(sub, "plain")));

    // Single-attribute lookups.
    objc_property_t p = class_getProperty(cls, "retained");
    char *t = property_copyAttributeValue(p, "T");
    char *amp = property_copyAttributeValue(p, "&");
    char *v = property_copyAttributeValue(p, "V");
    char *absent = property_copyAttributeValue(p, "Z");
    say("retained.T=%s", SAFESTR(t));
    say("retained.&=[%s]", SAFESTR(amp));
    say("retained.V=%s", SAFESTR(v));
    say("retained.Z=%s", SAFESTR(absent));
    free(t); free(amp); free(v); free(absent);

    say("missing.property=%s", NULLNESS(class_getProperty(cls, "noSuchProperty")));
    return 0;
}
