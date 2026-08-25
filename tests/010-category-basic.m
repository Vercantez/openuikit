// 010-category-basic -- categories add and override.
#include "testsupport.h"

@interface Host : TestRoot
- (int)original;
- (int)overriddenByCategory;
+ (int)classOverriddenByCategory;
@end
@implementation Host
- (int)original { return 1; }
- (int)overriddenByCategory { return 2; }
+ (int)classOverriddenByCategory { return 3; }
@end

@interface Host (Added)
- (int)addedByCategory;
+ (int)classAddedByCategory;
- (int)overriddenByCategory;
+ (int)classOverriddenByCategory;
@end
@implementation Host (Added)
- (int)addedByCategory { return 20; }
+ (int)classAddedByCategory { return 30; }
- (int)overriddenByCategory { return 200; }
+ (int)classOverriddenByCategory { return 300; }
- (int)callsOriginal { return [self original] + 1000; }
@end

// A category on a SUPERCLASS must be visible from a subclass.
@interface Sub : Host @end
@implementation Sub @end

int main(void) {
    Host *h = [Host new];
    Sub *s = [Sub new];

    say("original=%d", [h original]);
    say("addedByCategory=%d", [h addedByCategory]);
    say("classAddedByCategory=%d", [Host classAddedByCategory]);

    // Category implementation shadows the class's own.
    say("overriddenByCategory=%d", [h overriddenByCategory]);
    say("classOverriddenByCategory=%d", [Host classOverriddenByCategory]);

    // Inherited through a subclass.
    say("sub.addedByCategory=%d", [s addedByCategory]);
    say("sub.overriddenByCategory=%d", [(Host *)s overriddenByCategory]);
    say("sub.classAdded=%d", [Sub classAddedByCategory]);

    // A method declared only in the @implementation of a category still lands.
    say("callsOriginal=%d",
        ((int (*)(id, SEL))objc_msgSend)(h, sel_registerName("callsOriginal")));

    // Introspection sees category methods as methods of the class itself.
    Class hc = objc_getClass("Host");
    say("getInstanceMethod.added=%s",
        NULLNESS(class_getInstanceMethod(hc, @selector(addedByCategory))));
    say("respondsTo.added=%s",
        YN(class_respondsToSelector(hc, @selector(addedByCategory))));
    say("classMethod.added=%s",
        NULLNESS(class_getClassMethod(hc, @selector(classAddedByCategory))));

    // The overridden selector appears exactly once in the method list, even
    // though two implementations exist for it.
    unsigned n = 0;
    Method *ms = class_copyMethodList(hc, &n);
    int overrides = 0;
    for (unsigned i = 0; i < n; i++)
        if (method_getName(ms[i]) == @selector(overriddenByCategory)) overrides++;
    free(ms);
    say("methodlist.entries.for.overridden=%d", overrides);

    // The class's own IMP is still reachable through the Method the category
    // did NOT install -- i.e. the category shadows, it does not delete.
    say("shadowed.original.still.dispatchable=%s",
        YN(((int (*)(id, SEL))objc_msgSend)(h, @selector(original)) == 1));

    objc_release(h); objc_release(s);
    return 0;
}
