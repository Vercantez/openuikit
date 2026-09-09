// Chain probe: an Objective-C leaf under a SWIFT (non-@implementation)
// subclass of the @implementation class. The generated header marks every
// Swift class objc_subclassing_restricted; probe1 (simplenote-launch3)
// lifted it the same way and crashed in UIView.init(). Here the middle
// classes are Swift subclasses of an Objective-C-declared class.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Portable across macOS and the iOS simulator (NSStringFromRect is AppKit-only).
static NSString *OUIRectString(CGRect r) {
    return [NSString stringWithFormat:@"{{%g, %g}, {%g, %g}}", r.origin.x, r.origin.y, r.size.width, r.size.height];
}
#define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#import <OUIProbeView.h>   // the generated header @imports it, which -fno-modules cannot
#import "OUIProbeImpl-Swift.h"
#import "OUIProbeSubview.h"

// Leaf A: middle class OUISwiftSubview has a non-final `public var`
// (Swift vtable entries for its accessors).
@interface OUIProbeLeafA : OUISwiftSubview
@property (nonatomic) NSInteger leafLayouts;
@end
@implementation OUIProbeLeafA
- (void)layoutSubviews { [super layoutSubviews]; self.leafLayouts += 1; }
@end

// Leaf B: middle class OUISwiftFinalMid has no Swift vtable entries.
@interface OUIProbeLeafB : OUISwiftFinalMid
@property (nonatomic) NSInteger leafLayouts;
@end
@implementation OUIProbeLeafB
- (void)layoutSubviews { [super layoutSubviews]; self.leafLayouts += 1; }
@end

NSString *OUIProbeRunChainScenario(NSString *which) {
    OUIProbeView *root = [[OUIProbeView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    OUIProbeView *leaf = nil;
    NSInteger leafLayouts = -1;
    if ([which isEqualToString:@"A"]) {
        OUIProbeLeafA *a = [[OUIProbeLeafA alloc] initWithFrame:CGRectMake(1, 1, 2, 2)];
        [root addSubview:a];
        [root layoutIfNeeded];
        leafLayouts = a.leafLayouts;
        leaf = a;
    } else {
        OUIProbeLeafB *b = [[OUIProbeLeafB alloc] initWithFrame:CGRectMake(1, 1, 2, 2)];
        [root addSubview:b];
        [root layoutIfNeeded];
        leafLayouts = b.leafLayouts;
        leaf = b;
    }
    return [NSString stringWithFormat:@"chain %@: leaf=%s super=%s frame=%@ layoutCount=%ld leafLayouts=%ld instanceSize(mid)=%zu instanceSize(leaf)=%zu",
            which, class_getName(object_getClass(leaf)),
            class_getName(class_getSuperclass(object_getClass(leaf))),
            OUIRectString((leaf.frame)),
            (long)leaf.layoutCount, (long)leafLayouts,
            class_getInstanceSize(class_getSuperclass(object_getClass(leaf))),
            class_getInstanceSize(object_getClass(leaf))];
}
