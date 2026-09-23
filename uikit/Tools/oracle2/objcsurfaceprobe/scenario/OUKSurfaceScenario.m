// See include/OUKSurfaceScenario.h. Every line is something Objective-C code
// can observe; run.sh records Apple's answer (transcript-ios26.1.txt) and
// OpenUIKit's tests compare against it line for line. Values that are not
// part of the contract (hash numbers, object addresses, the concrete font
// subclass iOS returns) are printed as relations, never raw.
#import "OUKSurfaceScenario.h"
#import <objc/runtime.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#if OUK_OPENUIKIT
#ifdef OUK_NO_FOUNDATION
/* The Foundation-hidden guest has objc4's headers and no CoreGraphics; the
 * generated header spells CGFloat members as C double (ObjCSurface.swift). */
typedef double CGFloat;
#else
@import CoreGraphics;
#import "UIKitObjCSupport.h"
#endif
#import "OpenUIKit-Swift.h"
#ifndef OUK_NO_FOUNDATION
#import "OpenUIKitObjCBridge-Swift.h"
#endif
#else
#import <UIKit/UIKit.h>
#endif

static OUKSurfaceSink gSink;
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
static const char *C(id _Nullable o) { return o ? class_getName(object_getClass(o)) : "nil"; }
#ifndef OUK_NO_FOUNDATION
/* Four rotating buffers so one emit() can format several geometries. */
static const char *R(CGRect r) {
    static char buf[4][96];
    static int i;
    char *s = buf[i++ & 3];
    snprintf(s, 96, "{{%g, %g}, {%g, %g}}", r.origin.x, r.origin.y, r.size.width, r.size.height);
    return s;
}
static const char *P(CGPoint p) {
    static char buf[4][64];
    static int i;
    char *s = buf[i++ & 3];
    snprintf(s, 64, "{%g, %g}", p.x, p.y);
    return s;
}
#endif

// MARK: - A category on UIFont (Artsy+UIFonts shape: class factories)

@interface UIFont (OUKSurfaceProbe)
+ (UIFont *)ouk_serifFontWithSize:(CGFloat)size;
#ifndef OUK_NO_FOUNDATION
+ (UIFont *)ouk_missingFontWithSize:(CGFloat)size;
#endif
- (UIFont *)ouk_doubledFont;
@end

@implementation UIFont (OUKSurfaceProbe)
+ (UIFont *)ouk_serifFontWithSize:(CGFloat)size {
#ifndef OUK_NO_FOUNDATION
    // Artsy+OSSUIFonts falls back the same way when its face is absent.
    UIFont *font = [self fontWithName:@"OUKNoSuchSerif" size:size];
    return font ?: [self boldSystemFontOfSize:size];
#else
    return [self boldSystemFontOfSize:size];
#endif
}
#ifndef OUK_NO_FOUNDATION
+ (UIFont *)ouk_missingFontWithSize:(CGFloat)size {
    return [self fontWithName:@"OUKNoSuchSerif" size:size];
}
#endif
- (UIFont *)ouk_doubledFont {
    return [self fontWithSize:self.pointSize * 2];
}
@end

void OUKSurfaceSuperclassFacts(OUKSurfaceSink sink, void *context) {
    gSink = sink; gContext = context;
#ifndef OUK_NO_FOUNDATION
    Class classes[] = { [UIFont class], [CALayer class], [UIAlertAction class] };
#else
    Class classes[] = { [UIFont class], [CALayer class] };
#endif
    for (unsigned i = 0; i < sizeof classes / sizeof classes[0]; i++) {
        emit("%s:%s", class_getName(classes[i]), class_getName(class_getSuperclass(classes[i])));
    }
}

static void fontLine(const char *label, UIFont *font) {
#ifndef OUK_NO_FOUNDATION
    emit("%s pointSize=%g fontName=%s familyName=%s kind=%s", label, font.pointSize,
         font.fontName.UTF8String, font.familyName.UTF8String, B([font isKindOfClass:[UIFont class]]));
#else
    emit("%s pointSize=%g kind=%s", label, font.pointSize, B([font isKindOfClass:[UIFont class]]));
#endif
}

static void equalityLine(const char *label, UIFont *a, UIFont *b) {
    BOOL equal = [a isEqual:b];
    emit("%s isEqual=%s sameHash=%s", label, B(equal), B(equal ? [a hash] == [b hash] : YES));
}

void OUKSurfaceFontScenario(OUKSurfaceSink sink, void *context) {
    gSink = sink; gContext = context;
    UIFont *sys17 = [UIFont systemFontOfSize:17];
    UIFont *sys17b = [UIFont systemFontOfSize:17];
    UIFont *bold17 = [UIFont boldSystemFontOfSize:17];
    UIFont *sys18 = [UIFont systemFontOfSize:18];
    fontLine("systemFontOfSize:17", sys17);
    fontLine("boldSystemFontOfSize:17", bold17);
    fontLine("systemFontOfSize:18", sys18);
    fontLine("fontWithSize:34", [sys17 fontWithSize:34]);
    equalityLine("sys17~sys17", sys17, sys17b);
    equalityLine("sys17~bold17", sys17, bold17);
    equalityLine("sys17~sys18", sys17, sys18);
    equalityLine("sys17~[sys18 fontWithSize:17]", sys17, [sys18 fontWithSize:17]);
    equalityLine("sys17~[sys17 fontWithSize:17]", sys17, [sys17 fontWithSize:17]);
#ifndef OUK_NO_FOUNDATION
    emit("fontWithName:OUKNoSuchSerif -> %s", C([UIFont fontWithName:@"OUKNoSuchSerif" size:12]));
#endif
    // The category's class methods are found on UIFont and on its instances' class.
    fontLine("+ouk_serifFontWithSize:21", [UIFont ouk_serifFontWithSize:21]);
#ifndef OUK_NO_FOUNDATION
    emit("+ouk_missingFontWithSize:21 -> %s", C([UIFont ouk_missingFontWithSize:21]));
#endif
    fontLine("-ouk_doubledFont(10)", [[UIFont systemFontOfSize:10] ouk_doubledFont]);
    emit("respondsToSelector ouk_serifFontWithSize: %s",
         B([UIFont respondsToSelector:@selector(ouk_serifFontWithSize:)]));
#ifndef OUK_NO_FOUNDATION
    UIFont *semibold = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    fontLine("systemFontOfSize:17 weight:Semibold", semibold);
    equalityLine("sys17~weight:Regular", sys17, [UIFont systemFontOfSize:17 weight:UIFontWeightRegular]);
    equalityLine("bold17~weight:Bold", bold17, [UIFont systemFontOfSize:17 weight:UIFontWeightBold]);
    equalityLine("bold17~weight:Semibold", bold17, semibold);
    emit("UIFontWeight regular=%g medium=%g semibold=%g bold=%g heavy=%g",
         UIFontWeightRegular, UIFontWeightMedium, UIFontWeightSemibold, UIFontWeightBold, UIFontWeightHeavy);
    equalityLine("copy", sys17, [sys17 copy]);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    fontLine("UILabel.font default", label.font);
    label.font = bold17;
    equalityLine("UILabel.font set", label.font, bold17);
    NSDictionary *attributes = @{NSFontAttributeName: sys17};
    equalityLine("attributes[NSFontAttributeName]", attributes[NSFontAttributeName], sys17);
    // A font as an attribute value of Foundation's NSAttributedString.
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:@"Font"
                                                               attributes:@{NSFontAttributeName: bold17}];
    UIFont *back = [text attribute:NSFontAttributeName atIndex:2 effectiveRange:NULL];
    emit("NSAttributedString font identical=%s", B(back == bold17));
    equalityLine("NSAttributedString font", back, bold17);
    NSMutableAttributedString *mutable = [text mutableCopy];
    [mutable addAttribute:NSFontAttributeName value:sys18 range:NSMakeRange(0, 2)];
    NSRange range;
    UIFont *first = [mutable attribute:NSFontAttributeName atIndex:0 effectiveRange:&range];
    emit("addAttribute range={%lu, %lu} pointSize=%g", (unsigned long)range.location, (unsigned long)range.length,
         first.pointSize);
    __block int runs = 0;
    [mutable enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, mutable.length) options:0
                     usingBlock:^(id value, NSRange r, BOOL *stop) { runs += 1; }];
    emit("font runs=%d", runs);
    [mutable addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:18] range:NSMakeRange(2, 2)];
    runs = 0;
    [mutable enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, mutable.length) options:0
                     usingBlock:^(id value, NSRange r, BOOL *stop) { runs += 1; }];
    emit("equal fonts coalesce runs=%d", runs);
    emit("copy isEqual=%s", B([[mutable copy] isEqual:mutable]));
    NSMutableAttributedString *other = [[NSMutableAttributedString alloc] initWithString:@"Font"
        attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]}];
    emit("equal-font strings isEqual=%s", B([other isEqual:mutable]));
#endif
}

// MARK: - CALayer

void OUKSurfaceLayerScenario(OUKSurfaceSink sink, void *context) {
    gSink = sink; gContext = context;
    CALayer *layer = [CALayer layer];
    emit("+layer class=%s", C(layer));
#ifndef OUK_NO_FOUNDATION
    emit("defaults bounds=%s position=%s anchorPoint=%s frame=%s", R(layer.bounds), P(layer.position),
         P(layer.anchorPoint), R(layer.frame));
#endif
    emit("defaults cornerRadius=%g borderWidth=%g opacity=%g hidden=%s masksToBounds=%s opaque=%s",
         layer.cornerRadius, layer.borderWidth, layer.opacity, B(layer.hidden), B(layer.masksToBounds),
         B(layer.opaque));
#ifndef OUK_NO_FOUNDATION
    emit("defaults contentsScale=%g shadowOpacity=%g shadowRadius=%g shadowOffset={%g, %g}",
         layer.contentsScale, layer.shadowOpacity, layer.shadowRadius, layer.shadowOffset.width,
         layer.shadowOffset.height);
    emit("defaults sublayers=%s superlayer=%s mask=%s needsLayout=%s", (layer.sublayers ? "array" : "nil"), C(layer.superlayer),
         C(layer.mask), B([layer needsLayout]));
    layer.frame = CGRectMake(10, 20, 30, 40);
    emit("frame set bounds=%s position=%s frame=%s", R(layer.bounds), P(layer.position), R(layer.frame));
    layer.anchorPoint = CGPointMake(0, 0);
    emit("anchorPoint {0,0} position=%s frame=%s", P(layer.position), R(layer.frame));
    layer.bounds = CGRectMake(0, 0, 50, 60);
    layer.position = CGPointMake(5, 6);
    emit("bounds/position set frame=%s", R(layer.frame));
#else
    emit("defaults contentsScale=%g shadowOpacity=%g shadowRadius=%g", layer.contentsScale,
         layer.shadowOpacity, layer.shadowRadius);
    emit("defaults superlayer=%s mask=%s needsLayout=%s", C(layer.superlayer), C(layer.mask),
         B([layer needsLayout]));
#endif
    layer.cornerRadius = 4;
    layer.borderWidth = 1.5;
    layer.opacity = 0.25f;
    layer.hidden = YES;
    layer.masksToBounds = YES;
    emit("set cornerRadius=%g borderWidth=%g opacity=%g hidden=%s masksToBounds=%s", layer.cornerRadius,
         layer.borderWidth, layer.opacity, B(layer.isHidden), B(layer.masksToBounds));
    CALayer *a = [CALayer layer];
    CALayer *b = [[CALayer alloc] init];
    [layer addSublayer:a];
    [layer insertSublayer:b atIndex:0];
#ifndef OUK_NO_FOUNDATION
    emit("sublayers count=%lu first=%s superlayer=%s", (unsigned long)layer.sublayers.count,
         B(layer.sublayers.firstObject == b), B(a.superlayer == layer));
#else
    emit("superlayer a=%s b=%s", B(a.superlayer == layer), B(b.superlayer == layer));
#endif
    [a removeFromSuperlayer];
    [b removeFromSuperlayer];
#ifndef OUK_NO_FOUNDATION
    emit("after remove sublayers=%s a.superlayer=%s", (layer.sublayers ? "array" : "nil"), C(a.superlayer));
#else
    emit("after remove a.superlayer=%s", C(a.superlayer));
#endif
}

// MARK: - An Objective-C CALayer subclass

@interface OUKTraceLayer : CALayer
@property (nonatomic) int layoutCount;
@end

@implementation OUKTraceLayer
- (instancetype)init {
    self = [super init];
    if (self) emit("OUKTraceLayer -init class=%s", C(self));
    return self;
}
- (void)layoutSublayers {
    self.layoutCount += 1;
#ifndef OUK_NO_FOUNDATION
    emit("OUKTraceLayer -layoutSublayers #%d bounds=%s", self.layoutCount, R(self.bounds));
#else
    emit("OUKTraceLayer -layoutSublayers #%d", self.layoutCount);
#endif
    [super layoutSublayers];
}
@end

#ifndef OUK_NO_FOUNDATION
@interface OUKLayerHostView : UIView
@end

@implementation OUKLayerHostView
+ (Class)layerClass { return [OUKTraceLayer class]; }
- (void)layoutSubviews {
    emit("OUKLayerHostView -layoutSubviews bounds=%s", R(self.bounds));
    [super layoutSubviews];
}
@end
#endif

void OUKSurfaceLayerSubclassScenario(OUKSurfaceSink sink, void *context) {
    gSink = sink; gContext = context;
    emit("-- 1 +layer on the subclass");
    OUKTraceLayer *layer = [OUKTraceLayer layer];
    emit("isKindOfClass CALayer=%s super=%s", B([layer isKindOfClass:[CALayer class]]),
         class_getName(class_getSuperclass(object_getClass(layer))));
    emit("-- 2 layout");
    emit("needsLayout=%s", B([layer needsLayout]));
    [layer layoutIfNeeded];
    [layer layoutIfNeeded];
#ifndef OUK_NO_FOUNDATION
    layer.bounds = CGRectMake(0, 0, 20, 10);
    emit("after bounds change needsLayout=%s", B([layer needsLayout]));
    [layer layoutIfNeeded];
#endif
    [layer setNeedsLayout];
    [layer layoutIfNeeded];
    emit("-- 3 sublayers");
    OUKTraceLayer *child = [[OUKTraceLayer alloc] init];
    [layer addSublayer:child];
    emit("after addSublayer parent.needsLayout=%s child.needsLayout=%s", B([layer needsLayout]),
         B([child needsLayout]));
    [layer layoutIfNeeded];
    emit("count parent=%d child=%d", layer.layoutCount, child.layoutCount);
#ifndef OUK_NO_FOUNDATION
    emit("-- 4 +layerClass of an Objective-C UIView subclass");
    OUKLayerHostView *view = [[OUKLayerHostView alloc] initWithFrame:CGRectMake(0, 0, 50, 60)];
    emit("view.layer class=%s delegate=%s bounds=%s", C(view.layer), B(view.layer.delegate == (id)view),
         R(view.layer.bounds));
    [view layoutIfNeeded];
    [view setNeedsLayout];
    [view layoutIfNeeded];
    view.frame = CGRectMake(0, 0, 70, 80);
    [view.layer layoutIfNeeded];
    emit("layer count=%d", ((OUKTraceLayer *)view.layer).layoutCount);
#endif
}

// MARK: - UIColor.CGColor

#ifndef OUK_NO_FOUNDATION
static const char *G(CGColorRef c) {
    static char buf[4][128];
    static int i;
    char *s = buf[i++ & 3];
    if (!c) { snprintf(s, 128, "NULL"); return s; }
    size_t n = CGColorGetNumberOfComponents(c);
    const CGFloat *k = CGColorGetComponents(c);
    int used = snprintf(s, 128, "n=%zu [", n);
    for (size_t j = 0; j < n && used < 120; j++) used += snprintf(s + used, 128 - used, j ? " %.4g" : "%.4g", k[j]);
    snprintf(s + used, 128 - used, "] alpha=%.4g", CGColorGetAlpha(c));
    return s;
}

void OUKSurfaceColorScenario(OUKSurfaceSink sink, void *context) {
    gSink = sink; gContext = context;
    emit("redColor %s", G(UIColor.redColor.CGColor));
    emit("whiteColor %s", G(UIColor.whiteColor.CGColor));
    emit("clearColor %s", G(UIColor.clearColor.CGColor));
    emit("colorWithRed:0.2 green:0.4 blue:0.6 alpha:0.8 %s",
         G([UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:0.8].CGColor));
    emit("colorWithWhite:0.5 alpha:0.25 %s", G([UIColor colorWithWhite:0.5 alpha:0.25].CGColor));
    emit("colorWithAlphaComponent:0.5 %s", G([UIColor.blueColor colorWithAlphaComponent:0.5].CGColor));
    emit("CGColorEqualToColor(red, red)=%s",
         B(CGColorEqualToColor(UIColor.redColor.CGColor, [UIColor colorWithRed:1 green:0 blue:0 alpha:1].CGColor)));
    CALayer *layer = [CALayer layer];
    emit("layer defaults borderColor %s backgroundColor %s shadowColor %s", G(layer.borderColor),
         G(layer.backgroundColor), G(layer.shadowColor));
    layer.borderColor = UIColor.redColor.CGColor;
    layer.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1].CGColor;
    layer.shadowColor = UIColor.blueColor.CGColor;
    emit("layer set borderColor %s backgroundColor %s shadowColor %s", G(layer.borderColor),
         G(layer.backgroundColor), G(layer.shadowColor));
    layer.backgroundColor = NULL;
    emit("layer backgroundColor NULL -> %s", G(layer.backgroundColor));
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    emit("view.layer.backgroundColor default %s", G(view.layer.backgroundColor));
    view.backgroundColor = UIColor.greenColor;
    emit("view.backgroundColor=green -> layer %s", G(view.layer.backgroundColor));
    view.layer.backgroundColor = UIColor.redColor.CGColor;
    emit("view.layer.backgroundColor=red -> view.backgroundColor %s",
         G(view.backgroundColor.CGColor));
}
#endif
