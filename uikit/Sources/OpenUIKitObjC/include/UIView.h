/* UIView — declared here, implemented in Sources/OpenUIKit/UIView.swift.
 * This is the spike's H bucket: every member whose types are Foundation /
 * CoreGraphics types or classes declared in this module. Members typed with
 * UIColor, CALayer, UIGestureRecognizer, UIEvent, Canvas, UITraitCollection or
 * the layout-direction enums are `@objc open` in a plain Swift extension. */
#ifndef OPENUIKIT_OBJC_UIVIEW_H
#define OPENUIKIT_OBJC_UIVIEW_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "UIResponder.h"

NS_ASSUME_NONNULL_BEGIN

@class UIWindow;

NS_SWIFT_UI_ACTOR
@interface UIView : UIResponder <NSCoding>

/// UIKit's `+layerClass`; the lazy backing layer is that class.
@property (class, nonatomic, readonly) Class layerClass;
/// Process-wide base-view appearance proxy.
+ (instancetype)appearance;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

// Geometry: center/bounds are the source of truth, frame is derived.
@property (nonatomic) CGPoint center;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGRect frame;

@property (nonatomic) CGFloat alpha;
@property (nonatomic, getter=isHidden) BOOL hidden NS_SWIFT_NAME(isHidden);
@property (nonatomic, getter=isOpaque) BOOL opaque NS_SWIFT_NAME(isOpaque);
@property (nonatomic, getter=isUserInteractionEnabled) BOOL userInteractionEnabled NS_SWIFT_NAME(isUserInteractionEnabled);
@property (nonatomic) BOOL clipsToBounds;
@property (nonatomic) NSInteger tag;
@property (nonatomic) BOOL autoresizesSubviews;
@property (nonatomic) BOOL translatesAutoresizingMaskIntoConstraints;
@property (nonatomic) BOOL insetsLayoutMarginsFromSafeArea;
@property (nonatomic) BOOL preservesSuperviewLayoutMargins;

// Hierarchy. `superview` is readonly (not weak) exactly as UIKit declares it;
// the weak reference is the Swift backing ivar.
@property (nonatomic, readonly, nullable) UIView *superview;
@property (nonatomic, copy, readonly) NSArray<UIView *> *subviews;
@property (nonatomic, readonly, nullable) UIWindow *window;

- (void)addSubview:(UIView *)view;
- (void)insertSubview:(UIView *)view atIndex:(NSInteger)index NS_SWIFT_NAME(insertSubview(_:at:));
- (void)insertSubview:(UIView *)view belowSubview:(UIView *)siblingSubview;
- (void)insertSubview:(UIView *)view aboveSubview:(UIView *)siblingSubview;
- (void)removeFromSuperview;
- (void)bringSubviewToFront:(UIView *)view NS_SWIFT_NAME(bringSubviewToFront(_:));
- (void)sendSubviewToBack:(UIView *)view NS_SWIFT_NAME(sendSubviewToBack(_:));
- (BOOL)isDescendantOfView:(UIView *)view NS_SWIFT_NAME(isDescendant(of:));
- (BOOL)endEditing:(BOOL)force;
- (nullable UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;

// Hierarchy lifecycle override points.
- (void)willMoveToSuperview:(nullable UIView *)newSuperview NS_SWIFT_NAME(willMove(toSuperview:));
- (void)didMoveToSuperview;
- (void)willMoveToWindow:(nullable UIWindow *)newWindow NS_SWIFT_NAME(willMove(toWindow:));
- (void)didMoveToWindow;

// Layout.
- (void)setNeedsLayout;
- (void)layoutIfNeeded;
- (void)layoutSubviews;
- (void)setNeedsUpdateConstraints;
- (BOOL)needsUpdateConstraints;
- (void)updateConstraintsIfNeeded;
- (void)updateConstraints;
- (void)safeAreaInsetsDidChange;
- (void)layoutMarginsDidChange;

// Sizing.
- (CGSize)sizeThatFits:(CGSize)size;
- (void)sizeToFit;
@property (nonatomic, readonly) CGSize intrinsicContentSize;

// Coordinate conversion. (The Swift implementations carry explicit
// `@objc(convertPoint:toView:)` selectors: the four import as two
// overloaded `convert(_:to:)` / `convert(_:from:)` names.)
- (CGPoint)convertPoint:(CGPoint)point toView:(nullable UIView *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(nullable UIView *)view;
- (CGRect)convertRect:(CGRect)rect toView:(nullable UIView *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(nullable UIView *)view;

// Drawing.
- (void)setNeedsDisplay;
- (void)drawRect:(CGRect)rect NS_SWIFT_NAME(draw(_:));

@end

NS_ASSUME_NONNULL_END

#endif
