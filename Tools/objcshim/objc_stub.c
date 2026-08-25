/* Minimal ObjC-runtime stand-in: enough for Swift's ObjC interop codegen to
   link on Linux. SEL is just the uniqued selector-name pointer, which is all
   a source-level (non-msgSend) dispatch scheme needs. */
#include <stddef.h>
struct objc_cache_t { unsigned long long a, b; };
struct objc_cache_t _objc_empty_cache = {0, 0};

/* Swift's root class for ObjC interop; opaque here. */
struct fake_class { void *isa, *super, *cache, *vtable, *data; };
struct fake_class OBJC_METACLASS_$__TtCs12_SwiftObject = {0,0,&_objc_empty_cache,0,0};
struct fake_class OBJC_CLASS_$__TtCs12_SwiftObject =
    {&OBJC_METACLASS_$__TtCs12_SwiftObject, 0, &_objc_empty_cache, 0, 0};

void *objc_opt_self(void *obj) { return obj; }
const char *sel_getName(const char *sel) { return sel; }
const char *sel_registerName(const char *name) { return name; }

/* swiftCore on Linux is built without ObjC interop, so these interop-only
   entry points are absent; for a pure-Swift object graph they are identity. */
void *swift_unknownObjectRetain(void *o) { return o; }
void swift_unknownObjectRelease(void *o) { (void)o; }
