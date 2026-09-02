// The companion shared library for 041-multi-image.
//
// The harness builds any tests/<name>.lib.m as a shared library and links the
// test executable against it. Nothing here includes testsupport.h: TestRoot is
// defined in that header and would then exist in both images, which is a
// different experiment (duplicate class) from the one this test is running.
#include "041-multi-image.h"

#include <stdio.h>

// Declared, not included: these are libobjc exports the root class needs.
#ifdef __cplusplus
extern "C" {
#endif
id        _objc_rootRetain(id obj);
void      _objc_rootRelease(id obj);
id        _objc_rootAutorelease(id obj);
uintptr_t _objc_rootRetainCount(id obj);
void      _objc_rootDealloc(id obj);
#ifdef __cplusplus
}
#endif

@implementation LibRoot
+ (void)load {
    printf("ev[lib]=LibRoot.load\n");
    fflush(stdout);
}
+ (id)alloc { return class_createInstance(self, 0); }
+ (Class)class { return self; }
+ (id)retain { return self; }
+ (oneway void)release { }
+ (uintptr_t)retainCount { return UINTPTR_MAX; }
- (id)self { return self; }
- (id)retain { return _objc_rootRetain(self); }
- (oneway void)release { _objc_rootRelease(self); }
- (id)autorelease { return _objc_rootAutorelease(self); }
- (uintptr_t)retainCount { return _objc_rootRetainCount(self); }
- (void)dealloc { _objc_rootDealloc(self); }
- (int)base { return 1; }
- (int)overridable { return 10; }
@end
