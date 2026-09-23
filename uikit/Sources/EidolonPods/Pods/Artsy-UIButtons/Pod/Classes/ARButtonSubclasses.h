#import <UIKit/UIKit.h>

@interface ARCircularActionButton : UIButton
+ (CGFloat)buttonSize;
- (instancetype)initWithImageName:(NSString *)imageName;
@end

@interface ARButton : UIButton
@property (nonatomic, readwrite) BOOL shouldDimWhenDisabled;
@property (nonatomic, readwrite) BOOL shouldAnimateStateChange;
- (void)setup;
- (void)setEnabled:(BOOL)enabled animated:(BOOL)animated;
@end

@interface ARUnderlineButton : ARButton
- (void)setUnderlinedTitle:(NSString *)title underlineRange:(NSRange)range forState:(UIControlState)state;
@end

@interface ARInquireButton : ARUnderlineButton
@end

@interface ARUppercaseButton : ARButton
@end

@interface ARModalMenuButton : ARUppercaseButton
@end

@interface ARNavigationTabButton : ARUppercaseButton
@end

// ARFlatButton is effectively an abstract class. It provides no colors for text, background or border.
// The only time you might want to instantiate and customize a one-off ARFlatButton is when none of
// the generic subclasses is suitable.

@interface ARFlatButton : ARUppercaseButton
- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state;
- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state animated:(BOOL)animated;

- (void)setBorderColor:(UIColor *)borderColor forState:(UIControlState)state;
- (void)setBorderColor:(UIColor *)borderColor forState:(UIControlState)state animated:(BOOL)animated;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
@end

@interface ARMenuButton : ARFlatButton
@end

@interface ARClearFlatButton : ARFlatButton
@end

@interface ARWhiteFlatButton : ARFlatButton
@end

@interface ARBlackFlatButton : ARFlatButton
@end

// A transparent button for hero units. Color specifies border and text `color`. When active,
// button background becomes opaque with `color` and text becomes `inverseColor`
@interface ARHeroUnitButton : ARFlatButton
- (void)setColor:(UIColor *)color;
- (void)setColor:(UIColor *)color animated:(BOOL)animated;
- (void)setInverseColor:(UIColor *)inverseColor;
@end
