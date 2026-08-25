// The library 042-dlopen.m loads at run time. The harness builds this as a
// shared library and does NOT link the test against it; the path arrives in
// OBJC4_TEST_DLOPEN_LIB.
#include <objc/objc.h>
#include <objc/runtime.h>
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
void _objc_rootDealloc(id obj);
#ifdef __cplusplus
}
#endif

@interface PluginRoot {
@public
    Class isa;
}
+ (id)alloc;
- (int)answer;
@end

@implementation PluginRoot
+ (void)load {
    printf("plugin.load\n");
    fflush(stdout);
}
+ (id)alloc { return class_createInstance(self, 0); }
+ (id)retain { return self; }
+ (oneway void)release { }
- (void)dealloc { _objc_rootDealloc(self); }
- (int)answer { return 42; }
@end

@interface PluginRoot (InPlugin)
- (int)fromCategory;
@end
@implementation PluginRoot (InPlugin)
- (int)fromCategory { return 7; }
@end
