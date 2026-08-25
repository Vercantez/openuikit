// arc_nsobject.m -- differential probe for docs/STATUS.md 4.4.
//
// The 44-test corpus compiles -fno-objc-arc and never touches NSObject, so
// real ARC codegen over objc4's own NSObject was entirely uncovered. This
// exercises strong/copy/weak/assign properties, @autoreleasepool, __weak,
// isKindOfClass:, respondsToSelector: and -dealloc counting.
//
// RESULT: byte-identical on macOS 26.1/arm64 and Ubuntu 24.04/aarch64.
// Compile with -fobjc-arc -fobjc-exceptions on both sides.

// Differential probe: real ARC codegen over objc4's own NSObject.
// The 44-test corpus is entirely -fno-objc-arc and never uses NSObject.
#include <stdio.h>
#include <objc/NSObject.h>
#include <objc/runtime.h>
@interface Node : NSObject
@property (nonatomic, strong) id child;
@property (nonatomic, copy)   id copied;
@property (nonatomic, weak)   id parent;
@property (nonatomic, assign) int n;
@end
static int g_dealloc;
@implementation Node
- (void)dealloc { g_dealloc++; }
- (id)copyWithZone:(void *)z { (void)z; return self; }
@end
int main(void){ setvbuf(stdout,NULL,_IONBF,0);
    @autoreleasepool {
        Node *a = [Node new];
        Node *b = [Node new];
        a.child = b;
        b.parent = a;
        a.n = 7;
        printf("child.set=%d\n", a.child == b);
        printf("parent.set=%d\n", b.parent == a);
        printf("n=%d\n", a.n);
        a.copied = b;
        printf("copied.set=%d\n", a.copied == b);
        __weak Node *w = b;
        printf("weak.alive=%d\n", w != nil);
        printf("isKindOf=%d\n", [a isKindOfClass:[NSObject class]]);
        printf("respondsTo=%d\n", [a respondsToSelector:@selector(child)]);
        a.child = nil;
        printf("child.cleared=%d\n", a.child == nil);
    }
    printf("deallocs=%d\n", g_dealloc);
    printf("done\n");
    return 0;
}
