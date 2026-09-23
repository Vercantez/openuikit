#import "Artsy+UILabels.h"
#import "UIView+ARDrawing.h"
#import "NSNumberFormatter+ARCurrency.h"

#if __has_include(<Artsy_UIColors/UIColor+ArtsyColors.h>)
#import <Artsy_UIColors/UIColor+ArtsyColors.h>
#endif

#if __has_include(<Artsy_UIFonts/UIFont+ArtsyFonts.h>)
#import <Artsy_UIFonts/UIFont+ArtsyFonts.h>
#endif

#if __has_include(<Artsy+UIColors/UIColor+ArtsyColors.h>)
#import <Artsy+UIColors/UIColor+ArtsyColors.h>
#endif

#if __has_include(<Artsy+UIFonts/UIFont+ArtsyFonts.h>)
#import <Artsy+UIFonts/UIFont+ArtsyFonts.h>
#endif

static const CGSize ChevronSize = { 8, 13 };

@interface ARLabelWithChevron ()
@property (readonly, nonatomic, strong) UIImageView *chevron;
@end

@implementation ARLabel

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self setup];

    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    self.numberOfLines = 0;
    self.backgroundColor = [UIColor whiteColor];
    self.opaque = YES;
}

@end


@implementation ARLabelWithChevron

- (void)setup
{
    [super setup];
    self.chevronDelta = 6;
    self.clipsToBounds = NO;
}

- (void)setText:(NSString *)text
{
    [super setText:text];

    if (!self.chevron) {
        NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:@"Chevron_Black" ofType:@"png"];
        UIImage *chevronImage = [UIImage imageWithContentsOfFile:path];
        UIImageView *chevron = [[UIImageView alloc] initWithImage:chevronImage];
        [self addSubview:chevron];
        _chevron = chevron;
    }
}

- (void)drawTextInRect:(CGRect)rect
{
    rect = UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(0, 0, 0, ChevronSize.width + 8));
    [super drawTextInRect:rect];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize totalSize = self.bounds.size;
    CGFloat yPosition = (totalSize.height / 2) - self.chevronDelta;
    // Default to positioning the chevron immediately after the text.
    CGFloat chevronWidth = self.intrinsicContentSize.width + 8;
    // But always cap width before expected start of chevron so that the chevron is never clipped.
    if (chevronWidth + ChevronSize.width > totalSize.width) {
        chevronWidth = totalSize.width - ChevronSize.width;
    }
    self.chevron.frame = CGRectMake(chevronWidth, yPosition, ChevronSize.width, ChevronSize.height);
}

- (void)setChevronHidden:(BOOL)chevronHidden
{
    self.chevron.hidden = chevronHidden;
}

- (BOOL)chevronHidden
{
    return self.chevron.hidden;
}

@end

@implementation ARSerifLabel

- (void)setup
{
    [super setup];
    self.font = [UIFont serifFontWithSize:self.font.pointSize];
}

@end

@implementation ARItalicsSerifLabel

- (void)setup
{
    [super setup];
    self.font = [UIFont serifItalicFontWithSize:self.font.pointSize];
}

@end

@implementation ARSansSerifLabel

- (void)setup
{
    [super setup];
    self.font = [UIFont sansSerifFontWithSize:self.font.pointSize];
}

- (void)setText:(NSString *)text
{
    [super setText:text.uppercaseString];
}

@end

@implementation ARItalicsSerifLabelWithChevron

- (void)setup
{
    [super setup];
    self.font = [UIFont serifItalicFontWithSize:self.font.pointSize];
}

@end

@interface ARSerifLineHeightLabel()

@end

@implementation ARSerifLineHeightLabel

- (instancetype)initWithLineSpacing:(CGFloat)lineHeight
{
    self = [super init];
    if (!self) { return nil; }

    _lineHeight = lineHeight;

    return self;
}

- (void)setText:(NSString *)text
{
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:self.lineHeight];
    [paragraphStyle setAlignment:self.textAlignment];

    [attr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [text length])];

    self.numberOfLines = 0;
    self.attributedText = attr;
}

@end

static const CGFloat ARBorderLabelInset = 10;

@implementation ARBorderLabel

- (id)init
{
    if ((self = [super initWithLineSpacing:4])) {
        self.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self drawSolidBordersWithColor:self.textColor];
}

- (void)drawTextInRect:(CGRect)rect
{
    UIEdgeInsets insets = {ARBorderLabelInset, 0, ARBorderLabelInset, 0};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    return CGSizeMake(size.width, size.height + ARBorderLabelInset * 2);
}

@end

@implementation ARSerifLabelWithChevron

- (void)setup
{
    [super setup];
    self.font = [UIFont serifFontWithSize:self.font.pointSize];
}

@end

@implementation ARSansSerifLabelWithChevron

- (void)setup
{
    [super setup];
    self.font = [UIFont sansSerifFontWithSize:self.font.pointSize];
}

- (void)setText:(NSString *)text
{
    [super setText:[text uppercaseString]];
}

@end
