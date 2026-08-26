/* 09_objc -- rung (i): an Objective-C program.
 *
 * Deliberately Foundation-free: it links libobjc.A.dylib and libSystem only,
 * using a root class. That keeps the fixture aimed squarely at the piece we
 * already have (~/objc4-linux) rather than at NSObject/CoreFoundation.
 *
 * Exercises the parts of Mach-O that only ObjC uses:
 *   - __DATA_CONST,__objc_classlist / __objc_selrefs / __objc_classrefs /
 *     __objc_imageinfo / __objc_const, __DATA,__objc_data
 *   - selector uniquing: __objc_selrefs slots hold pointers into
 *     __TEXT,__objc_methname that libobjc REWRITES at map time
 *   - objc_msgSend dispatch and the runtime's image-load callback, which on
 *     Darwin is registered with dyld via _dyld_objc_register_callbacks /
 *     map_images. A loader that only does segments+fixups gets a crash here.
 *
 * Expected to FAIL under machorun until libobjc is ported and the loader
 * calls the ObjC image-notify hook. That failure is the point.
 */
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
#include <stdlib.h>

@interface Counter {
    Class isa;      /* root class: we own the isa slot */
    int value;
}
+ (id)make;
- (void)bump;
- (int)value;
- (const char *)describe;
@end

@implementation Counter

+ (id)make {
    Counter *c = (Counter *)class_createInstance(self, 0);
    return c;
}

- (void)bump { value++; }
- (int)value { return value; }
- (const char *)describe { return class_getName(object_getClass(self)); }

@end

/* A category on the same class: separate __objc_catlist entry. */
@interface Counter (Doubling)
- (void)twice;
@end

@implementation Counter (Doubling)
- (void)twice { [self bump]; [self bump]; }
@end

int main(void) {
    Counter *c = [Counter make];
    printf("class=%s\n", [c describe]);

    [c bump];
    [c twice];
    printf("value=%d\n", [c value]);

    /* selector identity: two spellings of the same name must unique to one */
    SEL a = @selector(bump);
    SEL b = sel_registerName("bump");
    printf("sel-uniqued=%d\n", a == b);
    printf("sel-name=%s\n", sel_getName(a));

    /* runtime introspection. A root class has no +class, so ask the runtime
     * for the Class object by name -- which also proves the class was
     * registered from __objc_classlist at image load. */
    Class cls = objc_getClass("Counter");
    printf("registered=%d\n", cls != NULL);
    printf("responds=%d\n", class_respondsToSelector(cls, @selector(twice)));
    printf("nosuch=%d\n", class_respondsToSelector(cls, sel_registerName("nope")));

    object_dispose((id)c);
    return 0;
}
