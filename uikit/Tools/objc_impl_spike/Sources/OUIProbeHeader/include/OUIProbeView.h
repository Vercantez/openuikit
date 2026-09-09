// The Objective-C declaration of a UIView-shaped class whose implementation
// lives in Swift (`@objc @implementation extension OUIProbeView`, in the
// OUIProbeImpl target). Shape: UIView's hierarchy/geometry core.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface OUIProbeView : NSObject

// center/bounds are the source of truth, frame is derived (like UIView).
@property (nonatomic) CGPoint center;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGRect frame;
// Real UIView.h declares superview `readonly` without `weak`; a `weak` header
// property cannot be implemented by a computed getter (ownership mismatch).
@property (nonatomic, readonly, nullable) OUIProbeView *superview;
@property (nonatomic, copy, readonly) NSArray<OUIProbeView *> *subviews;
@property (nonatomic, readonly) NSInteger layoutCount;

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (void)addSubview:(OUIProbeView *)view;
- (void)removeFromSuperview;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;
/// Override point; the base implementation records the call.
- (void)layoutSubviews;

@end

NS_ASSUME_NONNULL_END
