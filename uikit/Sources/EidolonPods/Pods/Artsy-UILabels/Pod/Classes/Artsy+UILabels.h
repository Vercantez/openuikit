#import <UIKit/UIKit.h>

@interface ARLabel : UILabel
@end

@interface ARLabelWithChevron : ARLabel
@property (nonatomic, assign) CGFloat chevronDelta;
@property (nonatomic, assign) BOOL chevronHidden;
@end

@interface ARSerifLabel : ARLabel
@end

@interface ARSerifLabelWithChevron : ARLabelWithChevron
@end

@interface ARSansSerifLabel : ARLabel
@end

@interface ARSansSerifLabelWithChevron : ARLabelWithChevron
@end

@interface ARItalicsSerifLabel : ARLabel
@end

@interface ARItalicsSerifLabelWithChevron : ARLabelWithChevron
@end

/// Will convert the text into an attributed string with the correct line height.
@interface ARSerifLineHeightLabel : ARSerifLabel
- (instancetype)initWithLineSpacing:(CGFloat)lineHeight;
@property (nonatomic, assign) CGFloat lineHeight;
@end

@interface ARBorderLabel : ARSerifLineHeightLabel
@end
