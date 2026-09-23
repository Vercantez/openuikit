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
    "view", "constraint", "label", "paragraph", "attributes", "button", "activity", NULL,
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
}
