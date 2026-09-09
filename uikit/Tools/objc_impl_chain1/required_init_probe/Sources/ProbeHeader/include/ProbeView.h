// UIView's initializer shape, exactly as UIKit.h declares it.
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
NS_ASSUME_NONNULL_BEGIN
NS_SWIFT_UI_ACTOR
@interface ProbeView : NSObject <NSCoding>
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)init;
@property (nonatomic) CGRect frame;
@end
NS_ASSUME_NONNULL_END
