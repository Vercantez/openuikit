// See include/OUKPodSurfaceScenario.h. Every line is something the pods'
// Objective-C observes or relies on; run.sh records Apple's answer and
// Tests/PodSurfaceTests compares OpenUIKit's line for line.
#import "OUKPodSurfaceScenario.h"
#import <objc/runtime.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#if OUK_OPENUIKIT
@import CoreGraphics;
#import "UIKitObjCSupport.h"
#import "OpenUIKit-Swift.h"
#import "OpenUIKitObjCBridge-Swift.h"
#else
#import <UIKit/UIKit.h>
#endif

static OUKPodSurfaceSink gSink;
static void *gContext;

static void emit(const char *format, ...) __attribute__((format(printf, 1, 2)));
static void emit(const char *format, ...) {
    char line[512];
    va_list args;
    va_start(args, format);
    vsnprintf(line, sizeof line, format, args);
    va_end(args);
    gSink(line, gContext);
}

static const char *B(BOOL b) { return b ? "YES" : "NO"; }
static const char *S(NSString *_Nullable s) { return s ? s.UTF8String : "nil"; }
static const char *E(UIEdgeInsets i) {
    static char buf[4][80];
    static int n;
    char *s = buf[n++ & 3];
    snprintf(s, 80, "{%g, %g, %g, %g}", i.top, i.left, i.bottom, i.right);
    return s;
}

static const char *const kSections[] = {
    "view", "constraint", "label", "paragraph", "attributes", "button", "activity", "image", "imageview",
    "appdelegate", "vfl", "webview", "activity2", "pasteboard", "windowlevel", NULL,
};

// FLKAutoLayout (translatesAutoresizingMaskIntoConstraints), Artsy+UILabels
// ARLabel (opaque), NJKWebViewProgress (…delegate.window), Artsy-UIButtons
// ARButton (-intrinsicContentSize returning UIViewNoIntrinsicMetric).
static void viewSection(void) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
    emit("UIView translatesAutoresizingMaskIntoConstraints=%s", B(view.translatesAutoresizingMaskIntoConstraints));
    view.translatesAutoresizingMaskIntoConstraints = NO;
    emit("set NO -> %s", B(view.translatesAutoresizingMaskIntoConstraints));
    emit("opaque UIView=%s UILabel=%s UIButton=%s UIImageView=%s", B(view.opaque),
         B([[UILabel alloc] initWithFrame:CGRectZero].opaque),
         B([UIButton buttonWithType:UIButtonTypeCustom].opaque),
         B([[UIImageView alloc] initWithImage:nil].opaque));
    view.opaque = YES;
    emit("set opaque YES -> %s", B(view.opaque));
    emit("window before=%s", view.window ? "window" : "nil");
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [window addSubview:view];
    emit("window after addSubview identical=%s", B(view.window == window));
    [view removeFromSuperview];
    emit("window after removeFromSuperview=%s", view.window ? "window" : "nil");
    emit("UIViewNoIntrinsicMetric=%g", UIViewNoIntrinsicMetric);
}

// FLKAutoLayout: `constraint.priority = priority` after +constraintWithItem:….
static void constraintSection(void) {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1 constant:10];
    emit("priority default=%g", c.priority);
    c.priority = UILayoutPriorityDefaultHigh;
    emit("priority set DefaultHigh -> %g", c.priority);
    c.priority = 999;
    emit("priority set 999 -> %g", c.priority);
}

// Artsy+UILabels: textAlignment, lineBreakMode = NSLineBreakByWordWrapping.
static void labelSection(void) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    emit("UILabel textAlignment=%ld lineBreakMode=%ld", (long)label.textAlignment, (long)label.lineBreakMode);
    label.textAlignment = NSTextAlignmentCenter;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    emit("set center/wordWrapping -> textAlignment=%ld lineBreakMode=%ld", (long)label.textAlignment,
         (long)label.lineBreakMode);
    label.lineBreakMode = NSLineBreakByTruncatingMiddle;
    emit("set truncatingMiddle -> %ld", (long)label.lineBreakMode);
    emit("NSLineBreakBy WordWrapping=%ld CharWrapping=%ld Clipping=%ld Head=%ld Tail=%ld Middle=%ld",
         (long)NSLineBreakByWordWrapping, (long)NSLineBreakByCharWrapping, (long)NSLineBreakByClipping,
         (long)NSLineBreakByTruncatingHead, (long)NSLineBreakByTruncatingTail, (long)NSLineBreakByTruncatingMiddle);
}

// Artsy+UILabels (-setLineSpacing:, -setAlignment:), XNGMarkdownParser.
static void paragraphSection(void) {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    emit("defaults lineSpacing=%g alignment=%ld paragraphSpacing=%g paragraphSpacingBefore=%g "
         "firstLineHeadIndent=%g headIndent=%g", style.lineSpacing, (long)style.alignment, style.paragraphSpacing,
         style.paragraphSpacingBefore, style.firstLineHeadIndent, style.headIndent);
    [style setLineSpacing:4];
    [style setAlignment:NSTextAlignmentCenter];
    style.paragraphSpacing = 2;
    style.paragraphSpacingBefore = 3;
    style.firstLineHeadIndent = 5;
    style.headIndent = 6;
    emit("set lineSpacing=%g alignment=%ld paragraphSpacing=%g paragraphSpacingBefore=%g "
         "firstLineHeadIndent=%g headIndent=%g", style.lineSpacing, (long)style.alignment, style.paragraphSpacing,
         style.paragraphSpacingBefore, style.firstLineHeadIndent, style.headIndent);
    NSParagraphStyle *copy = [style copy];
    emit("copy lineSpacing=%g alignment=%ld headIndent=%g", copy.lineSpacing, (long)copy.alignment, copy.headIndent);
}

// Artsy-UIButtons, XNGMarkdownParser attribute keys and underline values.
static void attributesSection(void) {
    emit("NSUnderlineStyleAttributeName=%s NSStrikethroughStyleAttributeName=%s",
         S(NSUnderlineStyleAttributeName), S(NSStrikethroughStyleAttributeName));
    emit("NSUnderlineStyleNone=%ld NSUnderlineStyleSingle=%ld", (long)NSUnderlineStyleNone,
         (long)NSUnderlineStyleSingle);
}

// Artsy-UIButtons ARHeroUnitButton: `self.contentEdgeInsets = …`.
static void buttonSection(void) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    emit("contentEdgeInsets default=%s", E(button.contentEdgeInsets));
    button.contentEdgeInsets = UIEdgeInsetsMake(1, 2, 3, 4);
    emit("contentEdgeInsets set -> %s", E(button.contentEdgeInsets));
}

// SDWebImage UIImageView+WebCache: -initWithActivityIndicatorStyle:.
static void activitySection(void) {
    const UIActivityIndicatorViewStyle styles[] = {
        UIActivityIndicatorViewStyleWhiteLarge, UIActivityIndicatorViewStyleWhite,
        UIActivityIndicatorViewStyleGray, UIActivityIndicatorViewStyleMedium, UIActivityIndicatorViewStyleLarge,
    };
    for (unsigned i = 0; i < sizeof styles / sizeof styles[0]; i++) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:styles[i]];
        emit("style %ld -> activityIndicatorViewStyle=%ld size={%g, %g} animating=%s hidesWhenStopped=%s",
             (long)styles[i], (long)spinner.activityIndicatorViewStyle, spinner.frame.size.width,
             spinner.frame.size.height, B(spinner.isAnimating), B(spinner.hidesWhenStopped));
        CGFloat r = -1, g = -1, b = -1, a = -1;
        BOOL rgb = [spinner.color getRed:&r green:&g blue:&b alpha:&a];
        emit("style %ld color rgb=%s {%.3f, %.3f, %.3f, %.3f}", (long)styles[i], B(rgb), r, g, b, a);
    }
}

/* 2x3 and 4x4 opaque red PNGs. */
static UIImage *PNG(BOOL big) {
    NSString *b64 = big ? @"iVBORw0KGgoAAAANSUhEUgAAAAQAAAAECAYAAACp8Z5+AAAAEklEQVR4nGP4z8DwHxkzkC4AADxAH+HggXe0AAAAAElFTkSuQmCC"
                        : @"iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAYAAAC56t6BAAAAEUlEQVR4nGP4z8DwH4QZMBgAoXkL9U3EmgcAAAAASUVORK5CYII=";
    return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:b64 options:0]];
}
static const char *SZ(CGSize s) {
    static char buf[4][48];
    static int n;
    char *out = buf[n++ & 3];
    snprintf(out, 48, "{%g, %g}", s.width, s.height);
    return out;
}

// SDWebImage UIImage+GIF / SDWebImageCompat: +animatedImageWithImages:duration:,
// `.images`, `.duration`.
static void imageSection(void) {
    UIImage *a = PNG(NO), *b = PNG(YES);
    emit("still images=%s duration=%g size=%s", a.images ? "array" : "nil", a.duration, SZ(a.size));
    UIImage *anim = [UIImage animatedImageWithImages:@[a, b] duration:0.5];
    emit("animated images.count=%lu duration=%g size=%s scale=%g first-is-a=%s",
         (unsigned long)anim.images.count, anim.duration, SZ(anim.size), anim.scale, B(anim.images[0] == a));
    UIImage *one = [UIImage animatedImageWithImages:@[b] duration:0];
    emit("single images.count=%lu duration=%g size=%s", (unsigned long)one.images.count, one.duration, SZ(one.size));
    UIImage *zero = [UIImage animatedImageWithImages:@[a, b, a] duration:0];
    emit("three frames duration 0 -> duration=%g", zero.duration);
    UIImage *mixed = [UIImage animatedImageWithImages:@[b, a] duration:1];
    emit("mixed sizes -> size=%s", SZ(mixed.size));
    UIImage *none = [UIImage animatedImageWithImages:@[] duration:1];
    emit("empty -> %s", none ? "image" : "nil");
}

// SDWebImage UIImageView+WebCache / +HighlightedWebCache, UIImageViewAligned.
static void imageViewSection(void) {
    UIImage *a = PNG(NO), *b = PNG(YES);
    UIImageView *view = [[UIImageView alloc] initWithImage:a];
    emit("highlighted=%s highlightedImage=%s animationImages=%s isAnimating=%s duration=%g repeat=%ld",
         B(view.highlighted), view.highlightedImage ? "image" : "nil", view.animationImages ? "array" : "nil",
         B(view.isAnimating), view.animationDuration, (long)view.animationRepeatCount);
    [view startAnimating];
    emit("startAnimating without images -> isAnimating=%s", B(view.isAnimating));
    view.animationImages = @[a, b];
    emit("animationImages set -> count=%lu isAnimating=%s duration=%g", (unsigned long)view.animationImages.count,
         B(view.isAnimating), view.animationDuration);
    [view startAnimating];
    emit("startAnimating -> isAnimating=%s image-is-a=%s", B(view.isAnimating), B(view.image == a));
    [view stopAnimating];
    emit("stopAnimating -> isAnimating=%s", B(view.isAnimating));
    view.animationImages = nil;
    view.highlightedImage = b;
    emit("highlightedImage set -> identical=%s image-is-a=%s frame=%g,%g", B(view.highlightedImage == b),
         B(view.image == a), view.frame.size.width, view.frame.size.height);
    view.highlighted = YES;
    emit("setHighlighted YES -> highlighted=%s image-is-a=%s", B(view.highlighted), B(view.image == a));
    UIImageView *both = [[UIImageView alloc] initWithImage:a highlightedImage:b];
    emit("initWithImage:highlightedImage: image-is-a=%s highlighted-is-b=%s highlighted=%s frame=%g,%g",
         B(both.image == a), B(both.highlightedImage == b), B(both.highlighted), both.frame.size.width,
         both.frame.size.height);
    UIImageView *animated = [[UIImageView alloc] initWithImage:[UIImage animatedImageWithImages:@[a, b] duration:2]];
    emit("animated image -> isAnimating=%s animationImages=%s image.images.count=%lu",
         B(animated.isAnimating), animated.animationImages ? "array" : "nil",
         (unsigned long)animated.image.images.count);
}

// NJKWebViewProgressView: `[UIApplication sharedApplication].delegate.window`
// is typed through id<UIApplicationDelegate>.
static void appDelegateSection(void) {
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    emit("delegate=%s", delegate ? "object" : "nil");
}

static const char *AttrName(NSLayoutAttribute a) {
    switch (a) {
    case NSLayoutAttributeLeft: return "left"; case NSLayoutAttributeRight: return "right";
    case NSLayoutAttributeTop: return "top"; case NSLayoutAttributeBottom: return "bottom";
    case NSLayoutAttributeLeading: return "leading"; case NSLayoutAttributeTrailing: return "trailing";
    case NSLayoutAttributeWidth: return "width"; case NSLayoutAttributeHeight: return "height";
    case NSLayoutAttributeCenterX: return "centerX"; case NSLayoutAttributeCenterY: return "centerY";
    case NSLayoutAttributeLastBaseline: return "lastBaseline"; case NSLayoutAttributeFirstBaseline: return "firstBaseline";
    case NSLayoutAttributeNotAnAttribute: return "none";
    default: return "other";
    }
}

// ORStackView: +constraintsWithVisualFormat:options:metrics:views: with
// NSDictionaryOfVariableBindings. Each constraint as items/attributes/
// relation/multiplier/constant/priority, in the order UIKit returns them.
static void vflSection(void) {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    UIView *view = [UIView new], *other = [UIView new], *third = [UIView new];
    [container addSubview:view];
    [container addSubview:other];
    [container addSubview:third];
    NSDictionary *views = NSDictionaryOfVariableBindings(view, other, third);
    emit("bindings keys=%s", [[[views allKeys] sortedArrayUsingSelector:@selector(compare:)]
                                 componentsJoinedByString:@","].UTF8String);
    NSDictionary *names = @{ [NSValue valueWithNonretainedObject:view]: @"view",
                             [NSValue valueWithNonretainedObject:other]: @"other",
                             [NSValue valueWithNonretainedObject:third]: @"third",
                             [NSValue valueWithNonretainedObject:container]: @"super",
                             [NSValue valueWithNonretainedObject:container.layoutMarginsGuide]: @"superMargins" };
    NSArray<NSString *> *formats = @[
        @"V:[other]-0-[view]", @"V:[other]-20-[view]", @"H:|-[view]-|", @"H:|[view]|",
        @"H:|-8-[view(>=50)]-(<=12)-[other(==view)]", @"V:[view(44@750)]", @"H:[view]-[other]-[third]",
        @"H:|-(pad)-[view(w)]", @"V:|-(>=10,<=30)-[view]", @"[view]-(==5@250)-[other]",
        @"H:|-[view]", @"V:|-[view]-|", @"H:[view]-(>=0)-|", @"H:|-0-[view]-0-|", @"[view(>=other)]",
        @"V:[view]-8-|", @"H:[view(==other@500)]", @"H:|[view][other]|", @"V:[view]-(-4)-[other]",
    ];
    for (NSString *format in formats) {
        NSArray<NSLayoutConstraint *> *cs = nil;
        @try {
            cs = [NSLayoutConstraint constraintsWithVisualFormat:format options:0
                                                         metrics:@{@"pad": @7, @"w": @33} views:views];
        } @catch (NSException *e) {
            emit("%s -> exception %s", format.UTF8String, e.name.UTF8String);
            continue;
        }
        emit("%s -> %lu", format.UTF8String, (unsigned long)cs.count);
        for (NSLayoutConstraint *c in cs) {
            NSString *first = names[[NSValue valueWithNonretainedObject:c.firstItem]] ?: @"?";
            NSString *second = c.secondItem ? (names[[NSValue valueWithNonretainedObject:c.secondItem]] ?: @"?") : @"nil";
            emit("  %s.%s %s %s.%s x%g %+g @%g", first.UTF8String, AttrName(c.firstAttribute),
                 c.relation == NSLayoutRelationEqual ? "==" : c.relation == NSLayoutRelationLessThanOrEqual ? "<=" : ">=",
                 second.UTF8String, AttrName(c.secondAttribute), c.multiplier, c.constant, c.priority);
        }
    }
    NSArray *leading = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[view]-[other]"
        options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:views];
    emit("DirectionLeadingToTrailing option=%lu -> %lu", (unsigned long)NSLayoutFormatDirectionLeadingToTrailing,
         (unsigned long)leading.count);
    @try {
        [NSLayoutConstraint constraintsWithVisualFormat:@"H:[missing]" options:0 metrics:nil views:views];
        emit("unknown view -> no exception");
    } @catch (NSException *e) { emit("unknown view -> exception %s", e.name.UTF8String); }
}

// NJKWebViewProgress / DZNWebViewController / Eidolon's AppDelegate: UIWebView.
@interface OUKWebDelegate : NSObject <UIWebViewDelegate>
@end
@implementation OUKWebDelegate
- (BOOL)webView:(UIWebView *)w shouldStartLoadWithRequest:(NSURLRequest *)r navigationType:(UIWebViewNavigationType)t {
    emit("shouldStartLoad url=%s navigationType=%ld mainDocument=%s", r.URL.absoluteString.UTF8String, (long)t,
         r.mainDocumentURL ? r.mainDocumentURL.absoluteString.UTF8String : "nil");
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)w { emit("didStartLoad loading=%s", B(w.loading)); }
- (void)webViewDidFinishLoad:(UIWebView *)w { emit("didFinishLoad loading=%s", B(w.loading)); }
- (void)webView:(UIWebView *)w didFailLoadWithError:(NSError *)e { emit("didFail %s %ld", e.domain.UTF8String, (long)e.code); }
@end

static void webViewSection(void) {
    UIWebView *web = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 100, 80)];
    emit("superclass=%s scrollView isKindOfUIScrollView=%s frame=%g,%g", class_getName(class_getSuperclass([UIWebView class])),
         B([web.scrollView isKindOfClass:[UIScrollView class]]), web.scrollView.frame.size.width,
         web.scrollView.frame.size.height);
    emit("delegate=%s request=%s loading=%s canGoBack=%s canGoForward=%s scalesPageToFit=%s", web.delegate ? "set" : "nil",
         web.request ? "set" : "nil", B(web.loading), B(web.canGoBack), B(web.canGoForward), B(web.scalesPageToFit));
    emit("UIWebViewNavigationType LinkClicked=%ld FormSubmitted=%ld BackForward=%ld Reload=%ld FormResubmitted=%ld Other=%ld",
         (long)UIWebViewNavigationTypeLinkClicked, (long)UIWebViewNavigationTypeFormSubmitted,
         (long)UIWebViewNavigationTypeBackForward, (long)UIWebViewNavigationTypeReload,
         (long)UIWebViewNavigationTypeFormResubmitted, (long)UIWebViewNavigationTypeOther);
    OUKWebDelegate *delegate = [OUKWebDelegate new];
    web.delegate = delegate;
    [web loadHTMLString:@"<p>x</p>" baseURL:nil];
    emit("after loadHTMLString (same turn) loading=%s request=%s", B(web.loading),
         web.request ? web.request.URL.absoluteString.UTF8String : "nil");
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:2];
    while (web.loading || !web.request) {
        if ([until timeIntervalSinceNow] < 0) break;
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    }
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    emit("settled loading=%s request=%s", B(web.loading), web.request ? web.request.URL.absoluteString.UTF8String : "nil");
    web.delegate = nil;
}

// DZNPolyActivity : UIActivity (no overrides of the queried members).
@interface OUKPlainActivity : UIActivity
@end
@implementation OUKPlainActivity
@end

static void activity2Section(void) {
    OUKPlainActivity *activity = [[OUKPlainActivity alloc] init];
    emit("superclass=%s activityCategory=%ld UIActivityCategoryAction=%ld UIActivityCategoryShare=%ld",
         class_getName(class_getSuperclass([OUKPlainActivity class])), (long)[OUKPlainActivity activityCategory],
         (long)UIActivityCategoryAction, (long)UIActivityCategoryShare);
    emit("activityType=%s activityTitle=%s activityImage=%s activityViewController=%s canPerform=%s",
         S(activity.activityType), S(activity.activityTitle), activity.activityImage ? "image" : "nil",
         activity.activityViewController ? "vc" : "nil", B([activity canPerformWithActivityItems:@[@"x"]]));
    [activity prepareWithActivityItems:@[@"x"]];
    [activity activityDidFinish:YES];
    emit("activityDidFinish: returned");
}

// DZNPolyActivity: [[UIPasteboard generalPasteboard] setURL:].
static void pasteboardSection(void) {
    UIPasteboard *board = [UIPasteboard pasteboardWithUniqueName];
    emit("unique name empty=%s", B(board.name.length == 0));
    board.URL = [NSURL URLWithString:@"https://artsy.net/x"];
    emit("URL=%s string=%s numberOfItems=%ld hasURLs=%s hasStrings=%s", board.URL.absoluteString.UTF8String,
         S(board.string), (long)board.numberOfItems, B(board.hasURLs), B(board.hasStrings));
    board.string = @"hello";
    emit("string=%s URL=%s numberOfItems=%ld", S(board.string), board.URL ? board.URL.absoluteString.UTF8String : "nil",
         (long)board.numberOfItems);
    [UIPasteboard removePasteboardWithName:board.name];
}

// SVProgressHUD: UIWindowLevel.
static void windowLevelSection(void) {
    emit("UIWindowLevelNormal=%g StatusBar=%g Alert=%g", UIWindowLevelNormal, UIWindowLevelStatusBar, UIWindowLevelAlert);
    UIWindow *w = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    emit("new window level=%g", w.windowLevel);
    w.windowLevel = UIWindowLevelAlert + 1;
    emit("set Alert+1 -> %g", w.windowLevel);
}

const char *OUKPodSurfaceSection(int index) {
    return index >= 0 && index < (int)(sizeof kSections / sizeof kSections[0]) ? kSections[index] : NULL;
}

void OUKPodSurfaceRun(const char *name, OUKPodSurfaceSink sink, void *context) {
    gSink = sink;
    gContext = context;
    if (!strcmp(name, "view")) viewSection();
    else if (!strcmp(name, "constraint")) constraintSection();
    else if (!strcmp(name, "label")) labelSection();
    else if (!strcmp(name, "paragraph")) paragraphSection();
    else if (!strcmp(name, "attributes")) attributesSection();
    else if (!strcmp(name, "button")) buttonSection();
    else if (!strcmp(name, "activity")) activitySection();
    else if (!strcmp(name, "image")) imageSection();
    else if (!strcmp(name, "imageview")) imageViewSection();
    else if (!strcmp(name, "appdelegate")) appDelegateSection();
    else if (!strcmp(name, "vfl")) vflSection();
    else if (!strcmp(name, "webview")) webViewSection();
    else if (!strcmp(name, "activity2")) activity2Section();
    else if (!strcmp(name, "pasteboard")) pasteboardSection();
    else if (!strcmp(name, "windowlevel")) windowLevelSection();
}

#if OUK_OPENUIKIT
unsigned long OUKPodSurfaceStateRawValue(UIControlState state) { return (unsigned long)state; }
#endif
