// An Objective-C subclass of the Swift-implemented OUIProbeView: exactly the
// shape of Simplenote's SPModalActivityIndicator : UIView.
#import <Foundation/Foundation.h>
#import <OUIProbeView.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface OUIProbeSubview : OUIProbeView
@property (nonatomic) NSInteger objcLayouts;
@property (nonatomic, copy) NSString *label;
- (instancetype)initWithFrame:(CGRect)frame label:(NSString *)label;
@end

/// Objective-C driver: allocates the subclass from Objective-C, builds a
/// two-level tree, runs layout, and returns a line-per-check report.
NSArray<NSString *> *OUIProbeRunObjCScenario(void);

/// Objective-C-side exercise of any view handed in from Swift (a Swift
/// subclass instance, for example): sends -layoutSubviews and -frame.
NSString *OUIProbeDescribeFromObjC(OUIProbeView *view);

NS_ASSUME_NONNULL_END

NS_ASSUME_NONNULL_BEGIN
/// Chain probe (OUIProbeLeaf.m): "A" = ObjC leaf under a Swift middle class
/// with vtable entries, "B" = ObjC leaf under a vtable-free Swift middle.
NSString *OUIProbeRunChainScenario(NSString *which);
NS_ASSUME_NONNULL_END
