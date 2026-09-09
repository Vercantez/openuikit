#import "OUIProbeSubview.h"
#import <objc/runtime.h>

// Portable across macOS and the iOS simulator (NSStringFromRect is AppKit-only).
static NSString *OUIRectString(CGRect r) {
    return [NSString stringWithFormat:@"{{%g, %g}, {%g, %g}}", r.origin.x, r.origin.y, r.size.width, r.size.height];
}

@implementation OUIProbeSubview

- (instancetype)initWithFrame:(CGRect)frame label:(NSString *)label {
    self = [super initWithFrame:frame];
    if (self) {
        _label = [label copy];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame label:@"default"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.objcLayouts += 1;
}

@end

static NSString *R(NSString *fmt, ...) NS_FORMAT_FUNCTION(1, 2);
static NSString *R(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    return s;
}

NSArray<NSString *> *OUIProbeRunObjCScenario(void) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];

    // 1. Allocate the ObjC subclass from ObjC through the designated init.
    OUIProbeSubview *child = [[OUIProbeSubview alloc] initWithFrame:CGRectMake(10, 20, 30, 40)
                                                              label:@"child"];
    [out addObject:R(@"objc alloc subclass: %@ class=%s super=%s",
                     child ? @"ok" : @"nil",
                     class_getName(object_getClass(child)),
                     class_getName(class_getSuperclass(object_getClass(child))))];
    [out addObject:R(@"objc frame after init: %@ (expect {{10, 20}, {30, 40}})",
                     OUIRectString((child.frame)))];
    [out addObject:R(@"objc label: %@", child.label)];

    // 2. Allocate the base class from ObjC via the convenience -init.
    OUIProbeView *root = [[OUIProbeView alloc] init];
    root.frame = CGRectMake(0, 0, 100, 200);
    [out addObject:R(@"objc alloc base via -init: %@ frame=%@ class=%s",
                     root ? @"ok" : @"nil",
                     OUIRectString((root.frame)),
                     class_getName(object_getClass(root)))];

    // 3. Hierarchy + layout: base layoutSubviews runs for root, and for the
    //    child the override runs, calls super, then increments objcLayouts.
    [root addSubview:child];
    [out addObject:R(@"objc addSubview: subviews.count=%lu child.superview==root:%d",
                     (unsigned long)root.subviews.count, child.superview == root)];
    [root layoutIfNeeded];
    [out addObject:R(@"objc layout: root.layoutCount=%ld child.layoutCount=%ld child.objcLayouts=%ld (expect 1 1 1)",
                     (long)root.layoutCount, (long)child.layoutCount, (long)child.objcLayouts)];
    [root layoutIfNeeded];
    [out addObject:R(@"objc second layoutIfNeeded is a no-op: root.layoutCount=%ld (expect 1)",
                     (long)root.layoutCount)];

    // 4. Runtime introspection: the Swift-only stored properties are ivars
    //    of the ObjC class object.
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList([OUIProbeView class], &ivarCount);
    NSMutableArray *names = [NSMutableArray array];
    for (unsigned int i = 0; i < ivarCount; i++) {
        [names addObject:[NSString stringWithUTF8String:ivar_getName(ivars[i])]];
    }
    free(ivars);
    [out addObject:R(@"objc ivars of OUIProbeView (%u): %@", ivarCount,
                     [names componentsJoinedByString:@", "])];

    // 5. Removal.
    [child removeFromSuperview];
    [out addObject:R(@"objc removeFromSuperview: subviews.count=%lu superview=%@",
                     (unsigned long)root.subviews.count, child.superview)];
    return out;
}

NSString *OUIProbeDescribeFromObjC(OUIProbeView *view) {
    [view layoutSubviews];
    return R(@"objc sees %s (super %s) frame=%@ layoutCount=%ld",
             class_getName(object_getClass(view)),
             class_getName(class_getSuperclass(object_getClass(view))),
             OUIRectString((view.frame)),
             (long)view.layoutCount);
}
