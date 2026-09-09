#import "OUIObjCSubclassProbe.h"
#import <objc/runtime.h>
// The generated header carries the plain-extension `@objc open` members
// (tintColor, touchesBegan:withEvent:, traitCollectionDidChange:, hitTest:…)
// as categories, plus UIColor / UIEvent / UITouch as SWIFT_CLASS interfaces.
#import "OpenUIKit-Swift.h"

@implementation OUIObjCView

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

// Header member override + super.
- (void)layoutSubviews {
    [super layoutSubviews];
    self.objcLayouts += 1;
}

// Plain-extension @objc open members overridden from Objective-C + super.
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.objcTouches += (NSInteger)touches.count;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    self.objcTraitChanges += 1;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? self : hit;
}

@end

@implementation OUIObjCWindow

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

#define CHECK(cond, what, ...) \
    [out addObject:((cond) ? R(@"PASS %@", what) : R(@"FAIL %@: " __VA_ARGS__, what))]

NSArray<NSString *> *OUIObjCSubclassScenario(void) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];

    // 1. Allocate the ObjC UIWindow subclass through the designated init.
    OUIObjCWindow *w = [[OUIObjCWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    CHECK(w != nil, @"objc alloc UIWindow subclass", @"nil");
    CHECK(class_getSuperclass(object_getClass(w)) == [UIWindow class],
          @"superclass of OUIObjCWindow is UIWindow", @"%s", class_getName(class_getSuperclass(object_getClass(w))));
    CHECK(strcmp(class_getName([UIWindow class]), "UIWindow") == 0 &&
          strcmp(class_getName(class_getSuperclass([UIWindow class])), "UIView") == 0 &&
          strcmp(class_getName(class_getSuperclass([UIView class])), "UIResponder") == 0,
          @"runtime chain UIWindow -> UIView -> UIResponder", @"%s/%s",
          class_getName(class_getSuperclass([UIWindow class])), class_getName(class_getSuperclass([UIView class])));
    [w makeKey];
    CHECK(w.isKeyWindow, @"makeKey", @"not key");
    CHECK(CGRectEqualToRect(w.frame, CGRectMake(0, 0, 320, 480)), @"window frame after init", @"%@", NSStringFromRect(NSRectFromCGRect(w.frame)));

    // 2. Allocate the ObjC UIView subclass, and the base class via -init.
    OUIObjCView *child = [[OUIObjCView alloc] initWithFrame:CGRectMake(10, 20, 30, 40) label:@"child"];
    CHECK(child != nil && [child.label isEqualToString:@"child"], @"objc alloc UIView subclass (designated chain)", @"%@", child.label);
    CHECK(CGRectEqualToRect(child.frame, CGRectMake(10, 20, 30, 40)), @"child frame after init", @"%@", NSStringFromRect(NSRectFromCGRect(child.frame)));
    UIView *plain = [[UIView alloc] init];
    CHECK(plain != nil && CGRectEqualToRect(plain.frame, CGRectZero), @"objc alloc UIView via -init (the call probe1 crashed on)", @"%@", plain);

    // 3. Hierarchy + layout through header members; overrides + super run.
    [w addSubview:child];
    [w addSubview:plain];
    CHECK(child.superview == w && w.subviews.count == 2 && child.window == w, @"addSubview / superview / window", @"%lu", (unsigned long)w.subviews.count);
    [w layoutIfNeeded];
    CHECK(w.objcLayouts == 1 && child.objcLayouts == 1, @"layoutSubviews override + super (window 1, child 1)", @"%ld %ld", (long)w.objcLayouts, (long)child.objcLayouts);

    // 4. Plain-extension @objc members: tintColor (UIColor is a Swift class).
    UIColor *before = child.tintColor;
    CHECK(before != nil, @"tintColor readable from objc", @"nil");
    child.tintColor = [UIColor redColor];
    CHECK([child.tintColor isEqual:[UIColor redColor]], @"tintColor settable from objc", @"%@", child.tintColor);
    child.backgroundColor = [UIColor blackColor];
    CHECK([child.backgroundColor isEqual:[UIColor blackColor]], @"backgroundColor from objc", @"%@", child.backgroundColor);

    // 5. Touch delivery reaches the ObjC override through the window's
    //    dispatch (UIWindow.sendTouch is Swift-only; go through hitTest and
    //    the responder entry point).
    UIView *hit = [w hitTest:CGPointMake(15, 25) withEvent:nil];
    CHECK(hit == child, @"hitTest override from objc returns the child", @"%@", hit);
    [child touchesBegan:[NSSet set] withEvent:nil];
    CHECK(child.objcTouches == 0, @"touchesBegan override + super with an empty set", @"%ld", (long)child.objcTouches);

    // 6. Bridged struct: traitCollection / traitCollectionDidChange.
    UITraitCollection *traits = child.traitCollection;
    CHECK(traits != nil, @"traitCollection bridged to an objc object", @"nil");
    [child traitCollectionDidChange:nil];
    CHECK(child.objcTraitChanges == 1, @"traitCollectionDidChange override + super", @"%ld", (long)child.objcTraitChanges);

    // 7. Internal category override points resolve through the runtime.
    CHECK(child._firstResponderWindow == w, @"_firstResponderWindow (category) == window", @"%@", child._firstResponderWindow);
    UIEdgeInsets m = child._defaultBaseLayoutMargins;
    CHECK(m.top == 8 && m.left == 8 && m.bottom == 8 && m.right == 8, @"_defaultBaseLayoutMargins C struct", @"%g", m.top);

    // 8. Responder chain from objc: child -> window -> application.
    CHECK(child.nextResponder == w, @"nextResponder of a window's child is the window", @"%@", child.nextResponder);
    CHECK(child.canBecomeFirstResponder == NO, @"canBecomeFirstResponder default NO", @"YES");

    // 9. Removal.
    [child removeFromSuperview];
    CHECK(child.superview == nil && w.subviews.count == 1, @"removeFromSuperview", @"%lu", (unsigned long)w.subviews.count);

    // 10. description is the Swift override.
    CHECK([[child description] hasPrefix:@"<OUIObjCView:"], @"description override", @"%@", [child description]);
    return out;
}
