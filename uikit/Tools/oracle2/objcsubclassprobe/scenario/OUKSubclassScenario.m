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
#import "UIKitObjCSupport.h"
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

// MARK: - UILabel / UIButton / UIImageView subclasses (Eidolon's pods)

/// Shaped like Artsy+UILabels' ARLabel: configures itself in -initWithFrame:
/// and transforms text in a -setText: override.
@interface OUKObjCLabel : UILabel
@end
@implementation OUKObjCLabel
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    OUKLog(@"OUKObjCLabel -initWithFrame: text=%@ lines=%ld", self.text ?: @"nil", (long)self.numberOfLines);
    self.numberOfLines = 0;
    return self;
}
- (void)setText:(NSString *)text {
    OUKLog(@"OUKObjCLabel -setText: %@", text ?: @"nil");
    [super setText:text.uppercaseString];
}
@end

/// Shaped like Artsy-UIButtons' ARButton: a title set in -initWithFrame:, a
/// -titleRectForContentRect: override.
@interface OUKObjCButton : UIButton
@property (nonatomic) NSInteger titleRectCalls;
@end
@implementation OUKObjCButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setTitle:@"Bid" forState:UIControlStateNormal];
    OUKLog(@"OUKObjCButton -initWithFrame: title=%@", self.titleLabel.text ?: @"nil");
    return self;
}
- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    self.titleRectCalls += 1;
    return [super titleRectForContentRect:contentRect];
}
@end

/// Shaped like UIImageViewAligned: -initWithImage: and an -image override.
@interface OUKObjCImageView : UIImageView
@end
@implementation OUKObjCImageView
- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithImage:image];
    OUKLog(@"OUKObjCImageView -initWithImage: image=%@", N(image));
    return self;
}
- (void)setImage:(UIImage *)image {
    OUKLog(@"OUKObjCImageView -setImage: %@", N(image));
    [super setImage:image];
}
@end

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

    OUKLog(@"-- 9 UILabel / UIButton / UIImageView subclasses");
    OUKObjCLabel *label = [[OUKObjCLabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    label.text = @"lot 12";
    OUKLog(@"label text=%@ lines=%ld super=%@", label.text, (long)label.numberOfLines,
           NSStringFromClass(class_getSuperclass([label class])));
    OUKObjCButton *button = [[OUKObjCButton alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    [button layoutIfNeeded];
    OUKLog(@"button title=%@ titleRectCalled=%d super=%@", button.titleLabel.text ?: @"nil",
           button.titleRectCalls > 0, NSStringFromClass(class_getSuperclass([button class])));
    OUKObjCImageView *imageView = [[OUKObjCImageView alloc] initWithImage:nil];
    imageView.image = nil;
    OUKLog(@"imageView image=%@ frame=%@ super=%@", N(imageView.image), R(imageView.frame),
           NSStringFromClass(class_getSuperclass([imageView class])));
    OUKLog(@"UILabel class name=%@ UIButton class name=%@ UIImageView class name=%@",
           NSStringFromClass([UILabel class]), NSStringFromClass([UIButton class]),
           NSStringFromClass([UIImageView class]));
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
