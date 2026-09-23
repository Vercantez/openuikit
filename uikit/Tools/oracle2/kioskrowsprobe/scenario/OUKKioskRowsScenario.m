// See include/OUKKioskRowsScenario.h. Every line is something Kiosk or one of
// its pods observes or relies on; run.sh records Apple's answer inside a
// UIApplicationMain app and Tests/KioskRowsTests compares OpenUIKit's line for
// line. Values that depend on glyph advances are printed as the facts the
// callers use (fits / line count), not as raw widths.
#import "OUKKioskRowsScenario.h"
#import <objc/runtime.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
@import CoreText;
@import QuartzCore;
#import "UIKitObjCSupport.h"
#import "OpenUIKit-Swift.h"
#import "OpenUIKitObjCBridge-Swift.h"
#import "OpenUIKitObjCClasses.h"
#else
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#endif

static OUKKioskRowsSink gSink;
static void *gContext;
static char gFontPath[1024];

static void emit(const char *format, ...) __attribute__((format(printf, 1, 2)));
static void emit(const char *format, ...) {
    char line[768];
    va_list args;
    va_start(args, format);
    vsnprintf(line, sizeof line, format, args);
    va_end(args);
    gSink(line, gContext);
}

static const char *B(BOOL b) { return b ? "YES" : "NO"; }
static const char *S(NSString *_Nullable s) { return s ? s.UTF8String : "nil"; }

static const char *const kSections[] = {
    "viewcontroller", "navigation", "barbutton", "navbar", "activity", "application", "value", "image",
    "font", "bezier", "paragraph", "label", "button", "textfield", "textview", "nib", "longpress", "motion",
    "alertview", "scroll2", "bars", "hud", NULL,
};

// DZNWebViewController: `[self init]`, the toolbar items, memory warnings.
@interface OUKInitController : UIViewController
@property (nonatomic, copy) NSString *trace;
@end
@implementation OUKInitController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _trace = [NSString stringWithFormat:@"initWithNibName:%@ bundle:%@", nibNameOrNil ?: @"nil",
              nibBundleOrNil ? @"set" : @"nil"];
    return self;
}
@end

static void viewControllerSection(void) {
    UIViewController *vc = [[UIViewController alloc] init];
    emit("init -> nibName=%s isViewLoaded=%s", S(vc.nibName), B(vc.isViewLoaded));
    OUKInitController *sub = [[OUKInitController alloc] init];
    emit("subclass init -> %s", S(sub.trace));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    emit("automaticallyAdjustsScrollViewInsets default=%s", B(vc.automaticallyAdjustsScrollViewInsets));
    vc.automaticallyAdjustsScrollViewInsets = NO;
    emit("set NO -> %s", B(vc.automaticallyAdjustsScrollViewInsets));
#pragma clang diagnostic pop
    emit("navigationItem identical=%s title=%s", B(vc.navigationItem == vc.navigationItem), S(vc.navigationItem.title));
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"A" style:UIBarButtonItemStylePlain target:nil action:nil];
    [vc setToolbarItems:@[item] animated:NO];
    emit("setToolbarItems:animated: -> count=%lu identical=%s", (unsigned long)vc.toolbarItems.count,
         B(vc.toolbarItems.firstObject == item));
    emit("responds didReceiveMemoryWarning=%s viewDidUnload=%s", B([vc respondsToSelector:@selector(didReceiveMemoryWarning)]),
         B([vc respondsToSelector:NSSelectorFromString(@"viewDidUnload")]));
    (void)vc.view;
    [vc didReceiveMemoryWarning];
    emit("didReceiveMemoryWarning -> isViewLoaded=%s", B(vc.isViewLoaded));
}

static void navigationSection(void) {
    UIViewController *root = [[UIViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    // (UIKit loads a navigation controller's view inside
    // -initWithRootViewController:; this section does not depend on it.)
    emit("toolbarHidden default=%s toolbar isUIToolbar=%s", B(nav.toolbarHidden), B([nav.toolbar isKindOfClass:[UIToolbar class]]));
    [nav setToolbarHidden:NO];
    emit("setToolbarHidden:NO -> %s toolbar.hidden=%s", B(nav.toolbarHidden), B(nav.toolbar.hidden));
    [nav setToolbarHidden:YES animated:NO];
    emit("setToolbarHidden:YES animated:NO -> %s", B(nav.toolbarHidden));
    UIGestureRecognizer *pop = nav.interactivePopGestureRecognizer;
    emit("interactivePopGestureRecognizer isGestureRecognizer=%s enabled=%s",
         B([pop isKindOfClass:[UIGestureRecognizer class]]), B(pop.enabled));
}

static void barButtonSection(void) {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"A" style:UIBarButtonItemStylePlain target:nil action:nil];
    emit("enabled default=%s width=%g", B(item.enabled), item.width);
    item.enabled = NO;
    item.width = 12;
    emit("set enabled NO width 12 -> enabled=%s width=%g", B(item.enabled), item.width);
    UIView *custom = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIBarButtonItem *customItem = [[UIBarButtonItem alloc] initWithCustomView:custom];
    emit("initWithCustomView: identical=%s enabled=%s title=%s", B(customItem.customView == custom), B(customItem.enabled),
         S(customItem.title));
}

static void navBarSection(void) {
    UINavigationBar *bar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    emit("titleTextAttributes default=%s", bar.titleTextAttributes ? "dict" : "nil");
    UIColor *red = [UIColor redColor];
    bar.titleTextAttributes = @{NSForegroundColorAttributeName: red};
    emit("set -> count=%lu color identical=%s", (unsigned long)bar.titleTextAttributes.count,
         B(bar.titleTextAttributes[NSForegroundColorAttributeName] == red));
}

static void activitySection(void) {
    emit("CopyToPasteboard=%s", S(UIActivityTypeCopyToPasteboard));
    emit("SaveToCameraRoll=%s", S(UIActivityTypeSaveToCameraRoll));
    emit("PostToFlickr=%s", S(UIActivityTypePostToFlickr));
    emit("Print=%s", S(UIActivityTypePrint));
    emit("AssignToContact=%s", S(UIActivityTypeAssignToContact));
    emit("Mail=%s", S(UIActivityTypeMail));
    emit("Message=%s", S(UIActivityTypeMessage));
    emit("PostToFacebook=%s", S(UIActivityTypePostToFacebook));
    emit("PostToTwitter=%s", S(UIActivityTypePostToTwitter));
    emit("PostToWeibo=%s", S(UIActivityTypePostToWeibo));
    emit("PostToTencentWeibo=%s", S(UIActivityTypePostToTencentWeibo));
    emit("AirDrop=%s", S(UIActivityTypeAirDrop));
    emit("AddToReadingList=%s", S(UIActivityTypeAddToReadingList));
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[@"x"] applicationActivities:nil];
    emit("excludedActivityTypes default=%s", avc.excludedActivityTypes ? "array" : "nil");
    avc.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypePrint];
    emit("set -> count=%lu first=%s", (unsigned long)avc.excludedActivityTypes.count, S(avc.excludedActivityTypes.firstObject));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    emit("completionHandler default=%s", avc.completionHandler ? "block" : "nil");
    __block NSString *seen = @"none";
    avc.completionHandler = ^(UIActivityType type, BOOL completed) { seen = type; };
    emit("completionHandler set -> %s withItemsHandler=%s", avc.completionHandler ? "block" : "nil",
         avc.completionWithItemsHandler ? "block" : "nil");
#pragma clang diagnostic pop
}

static void applicationSection(void) {
    UIApplication *app = [UIApplication sharedApplication];
    emit("idleTimerDisabled default=%s", B(app.idleTimerDisabled));
    app.idleTimerDisabled = YES;
    emit("set YES -> %s", B(app.isIdleTimerDisabled));
    app.idleTimerDisabled = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    emit("networkActivityIndicatorVisible default=%s", B(app.networkActivityIndicatorVisible));
    app.networkActivityIndicatorVisible = YES;
    emit("set YES -> %s", B(app.isNetworkActivityIndicatorVisible));
    app.networkActivityIndicatorVisible = NO;
#pragma clang diagnostic pop
    emit("UIApplicationWillTerminateNotification=%s", S(UIApplicationWillTerminateNotification));
    emit("UIBackgroundTaskInvalid=%lu", (unsigned long)UIBackgroundTaskInvalid);
    UIBackgroundTaskIdentifier task = [app beginBackgroundTaskWithExpirationHandler:^{}];
    emit("beginBackgroundTask valid=%s", B(task != UIBackgroundTaskInvalid));
    [app endBackgroundTask:task];
    emit("UIInterfaceOrientationMaskAll=%lu Portrait=%ld LandscapeLeft=%ld LandscapeRight=%ld IsPortrait(Up)=%s",
         (unsigned long)UIInterfaceOrientationMaskAll, (long)UIInterfaceOrientationPortrait,
         (long)UIInterfaceOrientationLandscapeLeft, (long)UIInterfaceOrientationLandscapeRight,
         B(UIInterfaceOrientationIsPortrait(UIInterfaceOrientationPortraitUpsideDown)));
}

static void valueSection(void) {
    NSValue *v = [NSValue valueWithCGPoint:CGPointMake(1.5, -2)];
    CGPoint p = v.CGPointValue;
    emit("valueWithCGPoint -> %g,%g objCType=%s", p.x, p.y, v.objCType);
    NSValue *r = [NSValue valueWithCGRect:CGRectMake(1, 2, 3, 4)];
    emit("valueWithCGRect -> %g,%g,%g,%g", r.CGRectValue.origin.x, r.CGRectValue.origin.y, r.CGRectValue.size.width,
         r.CGRectValue.size.height);
}

// RGBA of the pixel at (x, y) of a CGImage, 8-bit premultiplied, sRGB.
static void pixel(CGImageRef image, size_t x, size_t y, unsigned char out[4]) {
    size_t w = CGImageGetWidth(image), h = CGImageGetHeight(image);
    unsigned char *buf = calloc(w * h, 4);
    CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef ctx = CGBitmapContextCreate(buf, w, h, 8, w * 4, space, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), image);
    memcpy(out, buf + ((h - 1 - y) * w + x) * 4, 4);
    CGContextRelease(ctx);
    CGColorSpaceRelease(space);
    free(buf);
}

static void imageSection(void) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(3, 2), NO, 2);
    [[UIColor redColor] setFill];
    UIRectFill(CGRectMake(0, 0, 3, 2));
    UIImage *red = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    emit("UIGraphicsBeginImageContextWithOptions(3x2, NO, 2) -> size=%gx%g scale=%g cg=%zux%zu", red.size.width,
         red.size.height, red.scale, CGImageGetWidth(red.CGImage), CGImageGetHeight(red.CGImage));
    emit("after End current=%s", UIGraphicsGetCurrentContext() ? "context" : "NULL");
    NSData *png = UIImagePNGRepresentation(red);
    const unsigned char *b = png.bytes;
    emit("UIImagePNGRepresentation -> %s signature=%02x%02x%02x%02x", png.length > 8 ? "data" : "nil",
         png.length ? b[0] : 0, png.length ? b[1] : 0, png.length ? b[2] : 0, png.length ? b[3] : 0);
    UIImage *back = [UIImage imageWithData:png];
    emit("decoded -> size=%gx%g scale=%g", back.size.width, back.size.height, back.scale);
    NSData *jpeg = UIImageJPEGRepresentation(red, 0.9);
    const unsigned char *j = jpeg.bytes;
    emit("UIImageJPEGRepresentation -> %s soi=%02x%02x", jpeg.length > 2 ? "data" : "nil", jpeg.length ? j[0] : 0,
         jpeg.length ? j[1] : 0);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(4, 4), YES, 1);
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, 4, 4));
    [red drawInRect:CGRectMake(0, 0, 4, 4) blendMode:kCGBlendModeNormal alpha:0.5];
    UIImage *blended = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    unsigned char px[4];
    pixel(blended.CGImage, 2, 2, px);
    emit("drawInRect:blendMode:Normal alpha:0.5 over white -> rgba=%d,%d,%d,%d", px[0], px[1], px[2], px[3]);
}

// Artsy+UIFonts' ARFontLoader, verbatim in shape: CGFont from the file's
// bytes, CTFontManagerRegisterGraphicsFont, then +[UIFont fontWithName:size:].
static void fontSection(void) {
    NSData *data = [NSData dataWithContentsOfFile:@(gFontPath)];
    emit("font file bytes=%lu", (unsigned long)data.length);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGFontRef cgFont = CGFontCreateWithDataProvider(provider);
    NSString *ps = CFBridgingRelease(CGFontCopyPostScriptName(cgFont));
    emit("CGFont postScriptName=%s", S(ps));
    emit("before register fontWithName=%s", [UIFont fontWithName:ps size:20] ? "font" : "nil");
    CFErrorRef error = NULL;
    BOOL ok = CTFontManagerRegisterGraphicsFont(cgFont, &error);
    emit("CTFontManagerRegisterGraphicsFont=%s error=%ld", B(ok), error ? (long)CFErrorGetCode(error) : 0L);
    if (error) { CFRelease(error); error = NULL; }
    BOOL again = CTFontManagerRegisterGraphicsFont(cgFont, &error);
    emit("again=%s error=%ld", B(again), error ? (long)CFErrorGetCode(error) : 0L);
    if (error) CFRelease(error);
    CGFontRelease(cgFont);
    CGDataProviderRelease(provider);
    UIFont *font = [UIFont fontWithName:ps size:20];
    emit("fontWithName:%s size:20 -> fontName=%s familyName=%s pointSize=%g", ps.UTF8String, S(font.fontName),
         S(font.familyName), font.pointSize);
    emit("metrics ascender=%.4f descender=%.4f lineHeight=%.4f capHeight=%.4f leading=%.4f", font.ascender,
         font.descender, font.lineHeight, font.capHeight, font.leading);
    UIFont *family = [UIFont fontWithName:font.familyName size:12];
    emit("by family name -> fontName=%s", S(family.fontName));
    emit("UIFontFeatureTypeIdentifierKey=%s UIFontFeatureSelectorIdentifierKey=%s", S(UIFontFeatureTypeIdentifierKey),
         S(UIFontFeatureSelectorIdentifierKey));
    emit("UIFontDescriptorFeatureSettingsAttribute=%s NameAttribute=%s SizeAttribute=%s",
         S(UIFontDescriptorFeatureSettingsAttribute), S(UIFontDescriptorNameAttribute), S(UIFontDescriptorSizeAttribute));
    // Artsy+UIFonts +smallCapsSerifFontWithSize: (small caps: type 38 selector 1).
    NSArray *features = @[ @{ UIFontFeatureTypeIdentifierKey: @(38), UIFontFeatureSelectorIdentifierKey: @(1) } ];
    NSDictionary *attributes = @{ UIFontDescriptorFeatureSettingsAttribute: features,
                                  UIFontDescriptorNameAttribute: ps,
                                  UIFontDescriptorSizeAttribute: @(15) };
    UIFontDescriptor *descriptor = [[UIFontDescriptor alloc] initWithFontAttributes:attributes];
    emit("descriptor postscriptName=%s pointSize=%g", S(descriptor.postscriptName), descriptor.pointSize);
    UIFont *smallCaps = [UIFont fontWithDescriptor:descriptor size:15];
    emit("fontWithDescriptor:size:15 -> fontName=%s pointSize=%g", S(smallCaps.fontName), smallCaps.pointSize);
    UIFont *zero = [UIFont fontWithDescriptor:descriptor size:0];
    emit("fontWithDescriptor:size:0 -> pointSize=%g", zero.pointSize);
}

// SVProgressHUD's indefinite ring; XNGMarkdownParser; SVRadialGradientLayer.
static void bezierSection(void) {
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(24, 24) radius:18
                                                    startAngle:(CGFloat)(M_PI * 3 / 2)
                                                      endAngle:(CGFloat)(M_PI / 2 + M_PI * 5) clockwise:YES];
    CGRect box = CGPathGetPathBoundingBox(path.CGPath);
    emit("arc bounding box=%.3f,%.3f,%.3f,%.3f empty=%s", box.origin.x, box.origin.y, box.size.width, box.size.height,
         B(path.isEmpty));
    CAShapeLayer *shape = [CAShapeLayer layer];
    shape.path = path.CGPath;
    shape.lineCap = kCALineCapRound;
    emit("CAShapeLayer isCALayer=%s path=%s lineCap=%s", B([shape isKindOfClass:[CALayer class]]),
         shape.path ? "set" : "NULL", S(shape.lineCap));
    UIBezierPath *rect = [UIBezierPath bezierPathWithRect:CGRectMake(1, 2, 3, 4)];
    CGRect rb = CGPathGetBoundingBox(rect.CGPath);
    emit("bezierPathWithRect -> %g,%g,%g,%g", rb.origin.x, rb.origin.y, rb.size.width, rb.size.height);
}

static void paragraphSection(void) {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    NSArray<NSTextTab *> *defaults = style.tabStops;
    emit("default tabStops count=%lu first=%g last=%g", (unsigned long)defaults.count, defaults.firstObject.location,
         defaults.lastObject.location);
    NSTextTab *tab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:24 options:@{}];
    emit("NSTextTab location=%g alignment=%ld options=%lu", tab.location, (long)tab.alignment, (unsigned long)tab.options.count);
    style.tabStops = @[tab];
    emit("set -> count=%lu location=%g", (unsigned long)style.tabStops.count, style.tabStops.firstObject.location);
    NSParagraphStyle *copy = [style copy];
    emit("copy tabStops count=%lu", (unsigned long)copy.tabStops.count);
}

static void labelSection(void) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    emit("preferredMaxLayoutWidth default=%g", label.preferredMaxLayoutWidth);
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:17];
    label.text = @"The quick brown fox jumps over the lazy dog and keeps on running";
    CGSize one = label.intrinsicContentSize;
    label.preferredMaxLayoutWidth = 120;
    CGSize wrapped = label.intrinsicContentSize;
    emit("preferredMaxLayoutWidth=120 -> width<=120=%s lines=%d (unbounded lines=%d)", B(wrapped.width <= 120),
         (int)lround(wrapped.height / label.font.lineHeight), (int)lround(one.height / label.font.lineHeight));
    emit("read back=%g", label.preferredMaxLayoutWidth);
}

static void buttonSection(void) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"BID" forState:UIControlStateNormal];
    emit("titleShadowColor normal default=%s", [button titleShadowColorForState:UIControlStateNormal] ? "color" : "nil");
    UIColor *white = [UIColor whiteColor], *clear = [UIColor clearColor];
    [button setTitleShadowColor:white forState:UIControlStateNormal];
    [button setTitleShadowColor:clear forState:UIControlStateDisabled];
    emit("normal identical=%s highlighted->normal=%s disabled identical=%s selected->normal=%s",
         B([button titleShadowColorForState:UIControlStateNormal] == white),
         B([button titleShadowColorForState:UIControlStateHighlighted] == white),
         B([button titleShadowColorForState:UIControlStateDisabled] == clear),
         B([button titleShadowColorForState:UIControlStateSelected] == white));
    emit("currentTitleShadowColor identical=%s", B(button.currentTitleShadowColor == white));
    button.frame = CGRectMake(0, 0, 100, 40);
    [button layoutIfNeeded];
    CGFloat r = -1, g = -1, bl = -1, a = -1;
    [button.titleLabel.shadowColor getRed:&r green:&g blue:&bl alpha:&a];
    emit("titleLabel.shadowColor -> %g,%g,%g,%g offset=%g,%g", r, g, bl, a, button.titleLabel.shadowOffset.width,
         button.titleLabel.shadowOffset.height);
    button.enabled = NO;
    [button layoutIfNeeded];
    r = g = bl = a = -1;
    [button.titleLabel.shadowColor getRed:&r green:&g blue:&bl alpha:&a];
    emit("disabled -> titleLabel.shadowColor %g,%g,%g,%g", r, g, bl, a);
}

static UIWindow *OUKRowsWindow(void) {
    static UIWindow *window;
    if (!window) {
        window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        window.rootViewController = [[UIViewController alloc] init];
        [window makeKeyAndVisible];
    }
    return window;
}

static void textFieldSection(void) {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 200, 30)];
    emit("clearsOnBeginEditing default=%s", B(field.clearsOnBeginEditing));
    [OUKRowsWindow().rootViewController.view addSubview:field];
    field.text = @"abc";
    field.clearsOnBeginEditing = YES;
    BOOL became = [field becomeFirstResponder];
    emit("set YES, becomeFirstResponder=%s -> text='%s'", B(became), S(field.text));
    [field resignFirstResponder];
    field.text = @"def";
    field.clearsOnBeginEditing = NO;
    [field becomeFirstResponder];
    emit("NO, becomeFirstResponder -> text='%s'", S(field.text));
    [field resignFirstResponder];
    [field removeFromSuperview];
}

static void textViewSection(void) {
    // Kiosk's AdminLogViewController: scrollRangeToVisible(end) after text is
    // set, on a view that is on screen and laid out (outside the safe area).
    UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 200, 200, 100)];
    view.font = [UIFont systemFontOfSize:14];
    NSMutableString *text = [NSMutableString string];
    for (int i = 0; i < 40; i++) [text appendFormat:@"line %d\n", i];
    view.text = text;
    [OUKRowsWindow().rootViewController.view addSubview:view];
    [view layoutIfNeeded];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    emit("before offset.y=%g inset.top=%g", view.contentOffset.y, view.adjustedContentInset.top);
    [view scrollRangeToVisible:NSMakeRange(text.length, 0)];
    // Measured: UIKit scrolls on a later turn, not inside the call.
    emit("scrollRangeToVisible(end), same turn -> scrolled=%s", B(view.contentOffset.y > 0));
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    emit("next turn -> scrolled=%s", B(view.contentOffset.y > 0));
    [view removeFromSuperview];
}

// Kiosk's ListingsCountdownManager: an NSObject in the storyboard that
// overrides -awakeFromNib; KeypadContainerView overrides
// -prepareForInterfaceBuilder.
@interface OUKNibObject : NSObject
@property (nonatomic) int awakened;
@end
@implementation OUKNibObject
- (void)awakeFromNib { [super awakeFromNib]; self.awakened++; }
@end

static void nibSection(void) {
    NSObject *plain = [NSObject new];
    emit("NSObject responds awakeFromNib=%s prepareForInterfaceBuilder=%s", B([plain respondsToSelector:@selector(awakeFromNib)]),
         B([plain respondsToSelector:@selector(prepareForInterfaceBuilder)]));
    OUKNibObject *object = [OUKNibObject new];
    [object awakeFromNib];
    [plain prepareForInterfaceBuilder];
    emit("subclass awakeFromNib -> awakened=%d", object.awakened);
}

@interface OUKLongPress : UILongPressGestureRecognizer
@end
@implementation OUKLongPress
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventing { return NO; }
@end

static void longPressSection(void) {
    OUKLongPress *press = [[OUKLongPress alloc] initWithTarget:nil action:NULL];
    emit("subclass class=%s allowableMovement=%g minimumPressDuration=%g", class_getName([press class]),
         press.allowableMovement, press.minimumPressDuration);
    press.allowableMovement = 20;
    press.minimumPressDuration = 0.25;
    emit("set -> allowableMovement=%g minimumPressDuration=%g", press.allowableMovement, press.minimumPressDuration);
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:NULL];
    emit("canBePreventedByGestureRecognizer override -> %s", B([press canBePreventedByGestureRecognizer:tap]));
}

// SVProgressHUD -updateMotionEffectForXMotionEffectType:yMotionEffectType:.
static void motionSection(void) {
    UIInterpolatingMotionEffect *x = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
        type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    x.minimumRelativeValue = @(-10);
    x.maximumRelativeValue = @(10);
    emit("keyPath=%s type=%ld min=%s max=%s TiltAlongVerticalAxis=%ld", S(x.keyPath), (long)x.type,
         S([x.minimumRelativeValue description]), S([x.maximumRelativeValue description]),
         (long)UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis);
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[x];
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    [view addMotionEffect:group];
    emit("addMotionEffect -> count=%lu", (unsigned long)view.motionEffects.count);
    [view removeMotionEffect:group];
    emit("removeMotionEffect -> count=%lu", (unsigned long)view.motionEffects.count);
}

// DZNWebViewController -webView:didFailLoadWithError: (not shown here).
static void alertViewSection(void) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed" delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:@"Retry", @"More", nil];
    emit("title=%s message=%s numberOfButtons=%ld cancelButtonIndex=%ld firstOtherButtonIndex=%ld visible=%s",
         S(alert.title), S(alert.message), (long)alert.numberOfButtons, (long)alert.cancelButtonIndex,
         (long)alert.firstOtherButtonIndex, B(alert.visible));
    emit("buttonTitleAtIndex 0=%s 1=%s 2=%s", S([alert buttonTitleAtIndex:0]), S([alert buttonTitleAtIndex:1]),
         S([alert buttonTitleAtIndex:2]));
    UIAlertView *bare = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:nil cancelButtonTitle:nil
                                         otherButtonTitles:nil];
    emit("no buttons -> numberOfButtons=%ld cancelButtonIndex=%ld firstOtherButtonIndex=%ld", (long)bare.numberOfButtons,
         (long)bare.cancelButtonIndex, (long)bare.firstOtherButtonIndex);
#pragma clang diagnostic pop
}

// --- Round 2 (the pods' next walls once round 1 compiled) ---

// ARTiledImageView 1.1.1: ARTiledImageScrollView / ARTiledImageView.
@interface OUKKioskZoomDelegate : NSObject <UIScrollViewDelegate>
@property (nonatomic, strong) UIView *zoomed;
@end
@implementation OUKKioskZoomDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.zoomed; }
@end

static void scroll2Section(void) {
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    UIView *a = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)];
    UIView *b = [[UIView alloc] initWithFrame:CGRectZero];
    [scroll addSubview:a];
    [scroll insertSubview:b belowSubview:a];
    emit("insertSubview:belowSubview: -> b before a=%s", B([scroll.subviews indexOfObject:b] < [scroll.subviews indexOfObject:a]));
    UIPanGestureRecognizer *pan = scroll.panGestureRecognizer;
    emit("panGestureRecognizer isPan=%s view is scroll=%s", B([pan isKindOfClass:[UIPanGestureRecognizer class]]),
         B(pan.view == scroll));
    scroll.contentSize = CGSizeMake(400, 400);
    OUKKioskZoomDelegate *delegate = [OUKKioskZoomDelegate new];
    delegate.zoomed = a;
    scroll.delegate = delegate;
    scroll.minimumZoomScale = 1;
    scroll.maximumZoomScale = 4;
    [scroll zoomToRect:CGRectMake(100, 100, 50, 50) animated:NO];
    emit("zoomToRect:{100,100,50,50} animated:NO -> zoomScale=%g offset=%g,%g", scroll.zoomScale, scroll.contentOffset.x,
         scroll.contentOffset.y);
    scroll.delegate = nil;
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    emit("contentScaleFactor default==screen scale=%s", B(v.contentScaleFactor == UIScreen.mainScreen.scale));
    v.contentScaleFactor = 1;
    emit("set 1 -> %g", v.contentScaleFactor);
    [v setNeedsDisplayInRect:CGRectMake(0, 0, 5, 5)];
    emit("setNeedsDisplayInRect: returned");
}

// DZNWebViewController: its toolbar and navigation item.
static void barsSection(void) {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    emit("UIToolbar barTintColor default=%s translucent=%s", toolbar.barTintColor ? "color" : "nil", B(toolbar.translucent));
    UIColor *red = [UIColor redColor];
    toolbar.barTintColor = red;
    toolbar.translucent = NO;
    emit("set -> barTintColor identical=%s translucent=%s", B(toolbar.barTintColor == red), B(toolbar.translucent));
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"T"];
    emit("UINavigationItem titleView=%s rightBarButtonItem=%s", item.titleView ? "view" : "nil",
         item.rightBarButtonItem ? "item" : "nil");
    UIView *title = [[UIView alloc] initWithFrame:CGRectZero];
    item.titleView = title;
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"R" style:UIBarButtonItemStylePlain target:nil action:nil];
    [item setRightBarButtonItem:right];
    emit("set -> titleView identical=%s rightBarButtonItem identical=%s rightBarButtonItems=%lu", B(item.titleView == title),
         B(item.rightBarButtonItem == right), (unsigned long)item.rightBarButtonItems.count);
}

// SVProgressHUD 2.2.3.
static void hudSection(void) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    emit("UILabel baselineAdjustment default=%ld AlignBaselines=%ld AlignCenters=%ld None=%ld", (long)label.baselineAdjustment,
         (long)UIBaselineAdjustmentAlignBaselines, (long)UIBaselineAdjustmentAlignCenters, (long)UIBaselineAdjustmentNone);
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    emit("set AlignCenters -> %ld", (long)label.baselineAdjustment);
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    emit("UIWindow screen is mainScreen=%s", B(window.screen == UIScreen.mainScreen));
    UINotificationFeedbackGenerator *haptics = [[UINotificationFeedbackGenerator alloc] init];
    [haptics prepare];
    [haptics notificationOccurred:UINotificationFeedbackTypeWarning];
    emit("UINotificationFeedbackType Success=%ld Warning=%ld Error=%ld; prepare/notificationOccurred: returned",
         (long)UINotificationFeedbackTypeSuccess, (long)UINotificationFeedbackTypeWarning, (long)UINotificationFeedbackTypeError);
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    emit("accessibilityIdentifier=%s isAccessibilityElement=%s", S(view.accessibilityIdentifier), B(view.isAccessibilityElement));
    view.accessibilityIdentifier = @"SVProgressHUD";
    view.isAccessibilityElement = YES;
    emit("set -> accessibilityIdentifier=%s isAccessibilityElement=%s", S(view.accessibilityIdentifier),
         B(view.isAccessibilityElement));
    emit("NSStringDrawing UsesLineFragmentOrigin=%ld UsesFontLeading=%ld TruncatesLastVisibleLine=%ld",
         (long)NSStringDrawingUsesLineFragmentOrigin, (long)NSStringDrawingUsesFontLeading,
         (long)NSStringDrawingTruncatesLastVisibleLine);
    NSStringDrawingOptions options = NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine |
                                     NSStringDrawingUsesLineFragmentOrigin;
    CGRect r = [@"Loading" boundingRectWithSize:CGSizeMake(200, 300) options:options
                                    attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]} context:nil];
    emit("boundingRectWithSize \"Loading\" 16pt -> origin=%g,%g height=%.3f fits=%s", r.origin.x, r.origin.y, r.size.height,
         B(r.size.width > 0 && r.size.width < 200));
    emit("UIApplicationDidChangeStatusBarOrientationNotification=%s", S(UIApplicationDidChangeStatusBarOrientationNotification));
    emit("UIKeyboardWillHideNotification=%s UIKeyboardDidHideNotification=%s UIKeyboardDidShowNotification=%s",
         S(UIKeyboardWillHideNotification), S(UIKeyboardDidHideNotification), S(UIKeyboardDidShowNotification));
    emit("UIKeyboardFrameBeginUserInfoKey=%s UIKeyboardAnimationDurationUserInfoKey=%s", S(UIKeyboardFrameBeginUserInfoKey),
         S(UIKeyboardAnimationDurationUserInfoKey));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIApplication *app = UIApplication.sharedApplication;
    CGRect screen = UIScreen.mainScreen.bounds;
    emit("statusBarOrientation landscape==wide screen=%s statusBarFrame width==screen width=%s",
         B(UIInterfaceOrientationIsLandscape(app.statusBarOrientation) == (screen.size.width > screen.size.height)),
         B(app.statusBarFrame.size.width == screen.size.width));
#pragma clang diagnostic pop
    emit("UIEvent allTouches=%s UITouch locationInView:=%s", B([UIEvent instancesRespondToSelector:@selector(allTouches)]),
         B([UITouch instancesRespondToSelector:@selector(locationInView:)]));
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    emit("UIAccessibilityScreenChangedNotification=%u UIAccessibilityAnnouncementNotification=%u; post returned",
         (unsigned)UIAccessibilityScreenChangedNotification, (unsigned)UIAccessibilityAnnouncementNotification);
}

const char *OUKKioskRowsSection(int index) {
    return index >= 0 && index < (int)(sizeof kSections / sizeof kSections[0]) ? kSections[index] : NULL;
}

void OUKKioskRowsSetFontPath(const char *path) { snprintf(gFontPath, sizeof gFontPath, "%s", path); }

void OUKKioskRowsRun(const char *name, OUKKioskRowsSink sink, void *context) {
    gSink = sink;
    gContext = context;
    if (!strcmp(name, "viewcontroller")) viewControllerSection();
    else if (!strcmp(name, "navigation")) navigationSection();
    else if (!strcmp(name, "barbutton")) barButtonSection();
    else if (!strcmp(name, "navbar")) navBarSection();
    else if (!strcmp(name, "activity")) activitySection();
    else if (!strcmp(name, "application")) applicationSection();
    else if (!strcmp(name, "value")) valueSection();
    else if (!strcmp(name, "image")) imageSection();
    else if (!strcmp(name, "font")) fontSection();
    else if (!strcmp(name, "bezier")) bezierSection();
    else if (!strcmp(name, "paragraph")) paragraphSection();
    else if (!strcmp(name, "label")) labelSection();
    else if (!strcmp(name, "button")) buttonSection();
    else if (!strcmp(name, "textfield")) textFieldSection();
    else if (!strcmp(name, "textview")) textViewSection();
    else if (!strcmp(name, "nib")) nibSection();
    else if (!strcmp(name, "longpress")) longPressSection();
    else if (!strcmp(name, "motion")) motionSection();
    else if (!strcmp(name, "alertview")) alertViewSection();
    else if (!strcmp(name, "scroll2")) scroll2Section();
    else if (!strcmp(name, "bars")) barsSection();
    else if (!strcmp(name, "hud")) hudSection();
}
