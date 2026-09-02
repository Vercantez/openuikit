/* UIKit.h — the Objective-C facade over OpenUIKit. Prototype scope: UIView,
 * UILabel, UIButton, UIViewController (docs/OBJC_FACADE.md).
 *
 * These are REAL Objective-C classes: real @interface, real ivars, real
 * `objc_msgSend` dispatch, compiled by clang against libobjc2 and
 * gnustep-base. Nothing here is Swift, and nothing here knows Swift exists —
 * each object holds an opaque OUKHandle and forwards over the C ABI in
 * OpenUIKitABI.h. That is what makes the whole thing work on Linux, where
 * Swift's ObjC interop does not exist (docs/OBJC_RUNTIME.md).
 *
 * NOTE ON GEOMETRY: `CGFloat`, `struct CGPoint`, `struct CGSize` and
 * `struct CGRect` are NOT declared here — gnustep-base's <Foundation/NSGeometry.h>
 * already declares all four (NSPoint/NSSize/NSRect are typedefs OF them). So
 * the ObjC side gets CoreGraphics geometry from Foundation for free on Linux,
 * exactly as the Swift side does from corelibs-foundation. Only the
 * CGRectMake-family conveniences are missing, and UIGeometry.h adds those.
 */

#ifndef OPENUIKIT_OBJC_UIKIT_H
#define OPENUIKIT_OBJC_UIKIT_H

#import <Foundation/Foundation.h>
#import "OpenUIKitABI.h"
#import "UIGeometry.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIColor

/* A value type over RGBA, resolved on the Swift side. Deliberately minimal:
 * UIColor's real surface (dynamic providers, colour spaces, system colours)
 * is a whole cluster, and this prototype only needs to prove the boundary. */
@interface UIColor : NSObject
@property (nonatomic, readonly) CGFloat red, green, blue, alpha;
+ (instancetype)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a;
+ (instancetype)colorWithWhite:(CGFloat)w alpha:(CGFloat)a;
+ (instancetype)whiteColor;
+ (instancetype)blackColor;
+ (instancetype)clearColor;
/* UIKit's implicit-fill-colour API, so -drawRect: bodies read like UIKit. */
- (void)setFill;
@end

/* UIKit's UIRectFill(), filling with the current fill colour. */
void UIRectFill(CGRect rect);

#pragma mark - UIResponder

@interface UIResponder : NSObject
@end

#pragma mark - UIView

@interface UIView : UIResponder {
@protected
    OUKHandle _handle;                             /* +1, owned; released in dealloc */
    NSMutableArray<UIView *> *_subviewsOwned;      /* STRONG — mirrors Swift's `subviews` */
    __unsafe_unretained UIView *_superviewUnowned; /* UIKit's weak backlink */
    BOOL _ownsHandle;
}

/* The bridge handle. Public so an app can drop to the C ABI for anything the
 * facade has not wrapped yet — the escape hatch that keeps a partial facade
 * usable. BORROWED: do not release it. */
@property (nonatomic, readonly) OUKHandle openuikitHandle;

- (instancetype)initWithFrame:(CGRect)frame;
- (instancetype)init;

@property (nonatomic) CGRect frame;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGPoint center;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic) CGFloat alpha;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, getter=isOpaque) BOOL opaque;
@property (nonatomic) BOOL clipsToBounds;
@property (nonatomic) CGFloat cornerRadius;   /* view.layer.cornerRadius */
@property (nonatomic) NSInteger tag;

/* OWNERSHIP: -addSubview: RETAINS, mirroring Swift's `subviews` array. This is
 * not a convenience — it is the rule that keeps the Swift->ObjC back-pointer
 * from dangling. See docs/OBJC_FACADE.md, "the domination rule". */
- (void)addSubview:(UIView *)view;
- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index;
- (void)removeFromSuperview;
@property (nonatomic, readonly, nullable) UIView *superview;
@property (nonatomic, readonly) NSArray<UIView *> *subviews;

- (void)setNeedsLayout;
- (void)layoutIfNeeded;
- (void)setNeedsDisplay;
- (void)sizeToFit;
- (CGSize)sizeThatFits:(CGSize)size;

/* THE OVERRIDE POINTS. Subclass and override either; call super from your
 * override and it reaches OpenUIKit's Swift implementation. */
- (void)layoutSubviews;
- (void)drawRect:(CGRect)rect;

/* Render this view (after laying it out) to a PNG file, through exactly the
 * renderer the oracle suite uses. Returns YES on success. */
- (BOOL)renderToPNGAtPath:(NSString *)path scale:(CGFloat)scale;
@end

#pragma mark - UILabel

@interface UILabel : UIView
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic) NSInteger numberOfLines;
- (void)setFontOfSize:(CGFloat)size weight:(int32_t)weight;
- (void)setTextAlignment:(int32_t)alignment;
@end

#pragma mark - UIControl / UIButton

enum {
    UIControlEventTouchDown              = OUKControlEventTouchDown,
    UIControlEventTouchUpInside          = OUKControlEventTouchUpInside,
    UIControlEventTouchUpOutside         = OUKControlEventTouchUpOutside,
    UIControlEventValueChanged           = OUKControlEventValueChanged,
    UIControlEventPrimaryActionTriggered = OUKControlEventPrimaryActionTriggered,
    UIControlEventAllEvents              = OUKControlEventAllEvents
};
enum {
    UIControlStateNormal      = OUKControlStateNormal,
    UIControlStateHighlighted = OUKControlStateHighlighted,
    UIControlStateDisabled    = OUKControlStateDisabled,
    UIControlStateSelected    = OUKControlStateSelected
};

@interface UIControl : UIView
/* Real @selector target-action. No dispatch table: the ObjC runtime resolves
 * the selector, which is the one place this facade is a BETTER story than the
 * Swift API (docs/OBJC_RUNTIME.md makes Swift targets write an ActionTable).
 * The target is held UNOWNED, as in UIKit. */
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(uint32_t)events;
- (void)sendActionsForControlEvents:(uint32_t)events;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@end

typedef NS_ENUM(int32_t, UIButtonType) {
    UIButtonTypeCustom = OUKButtonTypeCustom,
    UIButtonTypeSystem = OUKButtonTypeSystem
};

@interface UIButton : UIControl
+ (instancetype)buttonWithType:(UIButtonType)type;
- (void)setTitle:(nullable NSString *)title forState:(uint32_t)state;
- (nullable NSString *)titleForState:(uint32_t)state;
- (void)setTitleColor:(UIColor *)color forState:(uint32_t)state;
@end

#pragma mark - UIViewController

@interface UIViewController : UIResponder {
@protected
    OUKHandle _handle;
    UIView *_view;           /* strong: dominates the Swift controller->view edge */
}
@property (nonatomic, readonly) OUKHandle openuikitHandle;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, copy, nullable) NSString *title;
- (void)loadView;            /* override point */
- (void)viewDidLoad;         /* override point */
- (void)loadViewIfNeeded;
@end

#pragma mark - Runtime setup

/* Install the ObjC callback vtable and point the engine at its resources.
 * Called automatically by +[UIView load]; exposed so a host can re-point the
 * resource root before building any views. */
void OpenUIKitObjCBootstrap(void);
void OpenUIKitSetResourceRoot(NSString *path);
void OpenUIKitSetFontDirectory(NSString *path);
void OpenUIKitUseQuartzBackend(BOOL quartz);

NS_ASSUME_NONNULL_END

#endif /* OPENUIKIT_OBJC_UIKIT_H */
