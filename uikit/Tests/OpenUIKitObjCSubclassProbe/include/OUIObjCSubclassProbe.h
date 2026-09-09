// The chain-rule gate for the first `@objc @implementation` chain
// (UIResponder → UIView → UIWindow, docs/agent_reports/objc-impl-chain1.md):
// Objective-C subclasses of UIView and UIWindow that init, override header
// members AND plain-extension `@objc open` members, and call super. Nothing
// at compile time catches a plain Swift class left in the middle of such a
// chain (the spike's chain A is a runtime SIGSEGV), so this runs at runtime,
// from an XCTest on the host and from `objcsubclassprobe` in the simulator.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <OpenUIKitObjC.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface OUIObjCView : UIView
@property (nonatomic) NSInteger objcLayouts;
@property (nonatomic) NSInteger objcTouches;
@property (nonatomic) NSInteger objcTraitChanges;
@property (nonatomic, copy) NSString *label;
- (instancetype)initWithFrame:(CGRect)frame label:(NSString *)label;
@end

NS_SWIFT_UI_ACTOR
@interface OUIObjCWindow : UIWindow
@property (nonatomic) NSInteger objcLayouts;
@end

/// Runs every check from Objective-C; each line is "PASS <what>" or
/// "FAIL <what>: <detail>".
NSArray<NSString *> *OUIObjCSubclassScenario(void);

NS_ASSUME_NONNULL_END
