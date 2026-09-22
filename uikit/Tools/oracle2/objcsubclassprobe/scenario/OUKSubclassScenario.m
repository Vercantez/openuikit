// See include/OUKSubclassScenario.h. Every line appended to the trace is
// something the scenario can observe from Objective-C; the oracle run
// (Tools/oracle2/objcsubclassprobe/run.sh) records Apple's answer and the
// OpenUIKit test compares against it line for line.
#import "OUKSubclassScenario.h"
#import <objc/runtime.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
#import "OpenUIKit-Swift.h"
#import "OpenUIKitObjCBridge-Swift.h"
#else
#import <UIKit/UIKit.h>
#endif

NSMutableArray<NSString *> *OUKTrace(void) {
    static NSMutableArray<NSString *> *trace;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ trace = [NSMutableArray array]; });
    return trace;
}

static void OUKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void OUKLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    [OUKTrace() addObject:[[NSString alloc] initWithFormat:format arguments:args]];
    va_end(args);
}

static NSString *R(CGRect r) {
    return [NSString stringWithFormat:@"{{%g, %g}, {%g, %g}}", r.origin.x, r.origin.y, r.size.width, r.size.height];
}
static NSString *S(CGSize s) { return [NSString stringWithFormat:@"{%g, %g}", s.width, s.height]; }
static NSString *N(id _Nullable o) { return o ? NSStringFromClass([o class]) : @"nil"; }

// MARK: - UIView subclass

@interface OUKObjCView : UIView
@property (nonatomic) NSInteger layoutCount;
@property (nonatomic, copy) NSString *tagName;
@end

@implementation OUKObjCView
- (instancetype)initWithFrame:(CGRect)frame {
    OUKLog(@"%@ -initWithFrame: %@ (enter)", NSStringFromClass([self class]), R(frame));
    self = [super initWithFrame:frame];
    if (self) {
        _tagName = @"objc";
        OUKLog(@"%@ -initWithFrame: bounds=%@ (exit)", NSStringFromClass([self class]), R(self.bounds));
    }
    return self;
}
- (void)layoutSubviews {
    OUKLog(@"%@ -layoutSubviews (enter) bounds=%@", NSStringFromClass([self class]), R(self.bounds));
    [super layoutSubviews];
    self.layoutCount += 1;
    OUKLog(@"%@ -layoutSubviews (exit) count=%ld", NSStringFromClass([self class]), (long)self.layoutCount);
}
- (CGSize)sizeThatFits:(CGSize)size {
    OUKLog(@"%@ -sizeThatFits: %@", NSStringFromClass([self class]), S(size));
    return CGSizeMake(77, 33);
}
- (void)willMoveToSuperview:(UIView *)newSuperview {
    OUKLog(@"%@ -willMoveToSuperview: %@", NSStringFromClass([self class]), N(newSuperview));
    [super willMoveToSuperview:newSuperview];
}
- (void)didMoveToSuperview {
    OUKLog(@"%@ -didMoveToSuperview superview=%@", NSStringFromClass([self class]), N(self.superview));
    [super didMoveToSuperview];
}
@end

@interface OUKObjCLeafView : OUKObjCView
@end

@implementation OUKObjCLeafView
- (void)layoutSubviews {
    OUKLog(@"OUKObjCLeafView -layoutSubviews (enter)");
    [super layoutSubviews];
    OUKLog(@"OUKObjCLeafView -layoutSubviews (exit)");
}
@end

id OUKMakeObjCView(void) {
    return [[OUKObjCView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
}

// MARK: - Driver

NSArray<NSString *> *OUKRunSubclassScenarios(void) {
    [OUKTrace() removeAllObjects];

    OUKLog(@"-- 1 designated initializer");
    OUKObjCView *a = [[OUKObjCView alloc] initWithFrame:CGRectMake(1, 2, 30, 40)];
    OUKLog(@"a frame=%@ bounds=%@ class=%@ super=%@", R(a.frame), R(a.bounds),
           NSStringFromClass([a class]), NSStringFromClass(class_getSuperclass([a class])));

    OUKLog(@"-- 2 -init reaches the subclass's -initWithFrame:");
    OUKObjCView *b = [[OUKObjCView alloc] init];
    OUKLog(@"b frame=%@", R(b.frame));

    OUKLog(@"-- 3 hierarchy callbacks");
    UIView *host = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [host addSubview:a];
    OUKLog(@"a.superview=%@ host.subviews=%lu", N(a.superview), (unsigned long)host.subviews.count);

    OUKLog(@"-- 4 layout");
    [a layoutIfNeeded];
    OUKLog(@"after first layoutIfNeeded count=%ld", (long)a.layoutCount);
    [a layoutIfNeeded];
    OUKLog(@"after second layoutIfNeeded count=%ld", (long)a.layoutCount);
    [a setNeedsLayout];
    [a layoutIfNeeded];
    OUKLog(@"after setNeedsLayout+layoutIfNeeded count=%ld", (long)a.layoutCount);
    a.bounds = CGRectMake(0, 0, 50, 60);
    [a layoutIfNeeded];
    OUKLog(@"after bounds change count=%ld", (long)a.layoutCount);

    OUKLog(@"-- 5 sizeToFit uses the override");
    [a sizeToFit];
    OUKLog(@"a frame after sizeToFit=%@", R(a.frame));

    OUKLog(@"-- 6 Objective-C subclass of the Objective-C subclass");
    OUKObjCLeafView *leaf = [[OUKObjCLeafView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
    [leaf setNeedsLayout];
    [leaf layoutIfNeeded];
    OUKLog(@"leaf count=%ld", (long)leaf.layoutCount);

    OUKLog(@"-- 7 removal");
    [a removeFromSuperview];
    OUKLog(@"a.superview=%@", N(a.superview));

    OUKLog(@"-- 8 runtime shape");
    OUKLog(@"isKindOfClass UIView=%d UIResponder=%d", [a isKindOfClass:[UIView class]], [a isKindOfClass:[UIResponder class]]);
    OUKLog(@"respondsToSelector layoutSubviews=%d drawRect:=%d initWithFrame:=%d",
           [a respondsToSelector:@selector(layoutSubviews)], [a respondsToSelector:@selector(drawRect:)],
           [a respondsToSelector:@selector(initWithFrame:)]);
    OUKLog(@"UIView class name=%@ UIResponder class name=%@",
           NSStringFromClass([UIView class]), NSStringFromClass([UIResponder class]));
    return [OUKTrace() copy];
}

/// UIKit's class name for a class object: OpenUIKit classes that keep their
/// Swift runtime name print as "OpenUIKit.UIEvent" (or the mangled
/// "_TtC9OpenUIKit7UIEvent"); the fact compared is the class, not the module.
static NSString *UIKitName(Class c) {
    NSString *n = NSStringFromClass(c);
    NSRange dot = [n rangeOfString:@"." options:NSBackwardsSearch];
    if (dot.location != NSNotFound) return [n substringFromIndex:dot.location + 1];
    if ([n hasPrefix:@"_TtC9OpenUIKit"]) {
        NSScanner *scan = [NSScanner scannerWithString:[n substringFromIndex:14]];
        NSInteger len = 0;
        if ([scan scanInteger:&len]) return [n substringFromIndex:14 + scan.scanLocation];
    }
    return n;
}

NSArray<NSString *> *OUKSuperclassFacts(void) {
    NSMutableArray *out = [NSMutableArray array];
    NSArray<Class> *classes = @[ [UIResponder class], [UIView class], [UITouch class], [UIEvent class],
                                 [UIPress class], [UIPressesEvent class], [UIColor class],
                                 [UITraitCollection class] ];
    for (Class c in classes) {
        [out addObject:[NSString stringWithFormat:@"%@:%@", UIKitName(c), UIKitName(class_getSuperclass(c))]];
    }
    return out;
}
