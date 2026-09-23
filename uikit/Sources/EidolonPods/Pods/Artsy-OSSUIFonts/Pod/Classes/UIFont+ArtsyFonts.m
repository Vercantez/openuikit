#import "UIFont+ArtsyFonts.h"
#import <CoreText/CoreText.h>

// Based on https://github.com/CocoaPods-Fonts/OpenSans/blob/874e65bc21abe54284e195484d2259b2fe858680/UIFont%2BOpenSans.m

// This is changed by the pre-install hook

static BOOL useClosedFonts = false;

@interface ARFontLoader: NSObject

+ (void)loadFontWithFileName:(NSString *)fontFileName extension:(NSString *)extension;

@end

@implementation ARFontLoader

+ (void)loadFontWithFileName:(NSString *)fontFileName extension:(NSString *)extension {
    NSBundle *bundle = [NSBundle bundleForClass:self];
    NSURL *fontURL = [bundle URLForResource:fontFileName withExtension:extension];
    NSData *fontData = [NSData dataWithContentsOfURL:fontURL];

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
    CGFontRef font = CGFontCreateWithDataProvider(provider);

    if (font) {
        CFErrorRef errorRef = NULL;
        if (CTFontManagerRegisterGraphicsFont(font, &errorRef) == NO) {
            NSError *error = (__bridge NSError *)errorRef;
            if (error.code == kCTFontManagerErrorAlreadyRegistered) {
                // nop - the font must have been registered by someone else already.
            } else {
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:error.localizedDescription userInfo:@{ NSUnderlyingErrorKey: error }];
            }
        }

        CFRelease(font);
    }
    if (provider) {
        CFRelease(provider);
    }
}

@end

@implementation UIFont (ArtsyFonts)

+ (instancetype)ar_LoadAndReturnFont:(NSString *)fontName extension:(NSString *)extension size:(CGFloat)fontSize onceToken:(dispatch_once_t *)onceToken {
    // Overload to default to fontName for fontFileName
    return [self ar_LoadAndReturnFont:fontName extension:extension size:fontSize onceToken:onceToken fontFileName:fontName];
}

+ (instancetype)ar_LoadAndReturnFont:(NSString *)fontName extension:(NSString *)extension size:(CGFloat)fontSize onceToken:(dispatch_once_t *)onceToken fontFileName:(NSString *)fontFileName {

    dispatch_once(onceToken, ^{
        [ARFontLoader loadFontWithFileName:fontFileName extension:extension];
    });

    return [self fontWithName:fontName size:fontSize];
}


+ (UIFont *)serifBoldItalicFontWithSize:(CGFloat)size
{
    static dispatch_once_t onceToken;
    NSString *fontFile = useClosedFonts ? @"AGaramondPro-BoldItalic" : @"EBGaramond08-Italic";
    NSString *type = useClosedFonts ? @"otf" : @"ttf";
    return [self ar_LoadAndReturnFont:@"AGaramondPro-BoldItalic" extension:type size:size onceToken:&onceToken fontFileName:fontFile];
}

+ (UIFont *)serifBoldFontWithSize:(CGFloat)size
{
    static dispatch_once_t onceToken;
    NSString *fontFile = useClosedFonts ? @"AGaramondPro-Bold" : @"EBGaramond08-Regular";
    NSString *type = useClosedFonts ? @"otf" : @"ttf";
    return [self ar_LoadAndReturnFont:@"AGaramondPro-Bold" extension:type size:size onceToken:&onceToken fontFileName:fontFile];
}

+ (UIFont *)serifSemiBoldFontWithSize:(CGFloat)size
{
    // This does not have corresponding OSS variant, so we re-use the bold one
    static dispatch_once_t onceToken;
    NSString *fontName = useClosedFonts ? @"AGaramondPro-Semibold" : @"EBGaramond08-Regular";
    NSString *font = useClosedFonts ? @"AGaramondPro-Semibold" : @"AGaramondPro-Bold";
    NSString *type = useClosedFonts ? @"otf" : @"ttf";
    return [self ar_LoadAndReturnFont:font extension:type size:size onceToken:&onceToken fontFileName:fontName];
}

+ (UIFont *)serifFontWithSize:(CGFloat)size
{
    static dispatch_once_t onceToken;
    NSString *font = useClosedFonts ? @"AGaramondPro-Regular" : @"EBGaramond12-Regular";
    NSString *type = useClosedFonts ? @"otf" : @"ttf";
    return [self ar_LoadAndReturnFont:@"AGaramondPro-Regular" extension:type size:size onceToken:&onceToken fontFileName:font];
}

+ (UIFont *)serifItalicFontWithSize:(CGFloat)size
{
    static dispatch_once_t onceToken;
    NSString *fontName = useClosedFonts ? @"AGaramondPro-Italic" : @"EBGaramond12-Italic";
    NSString *type = useClosedFonts ? @"otf" : @"ttf";
    return [self ar_LoadAndReturnFont:@"AGaramondPro-Italic" extension:type size:size onceToken:&onceToken fontFileName:fontName];
}

+ (UIFont *)sansSerifFontWithSize:(CGFloat)size
{
    static dispatch_once_t onceToken;
    NSString *fontFilename = useClosedFonts ? @"AVG65lig" : @"texgyreadventor-regular";

    NSString *type = useClosedFonts ? @"otf" : @"ttf";
    return [self ar_LoadAndReturnFont:@"AvantGardeGothicITC" extension:type size:size onceToken:&onceToken fontFileName:fontFilename];
}

+ (UIFont *)smallCapsSerifFontWithSize:(CGFloat)size
{
    // Force font to be loaded into CoreText system first.
    __unused UIFont *font = [self serifFontWithSize:size];
    
    NSArray *fontFeatureSettings = @[ @{ UIFontFeatureTypeIdentifierKey: @(38),
                                         UIFontFeatureSelectorIdentifierKey : @(1) } ];

    NSDictionary *fontAttributes = @{ UIFontDescriptorFeatureSettingsAttribute: fontFeatureSettings,
                                      UIFontDescriptorNameAttribute: @"AGaramondPro-Regular",
                                      UIFontDescriptorSizeAttribute: @(size)};

    UIFontDescriptor *fontDescriptor = [[UIFontDescriptor alloc] initWithFontAttributes: fontAttributes];
    return [UIFont fontWithDescriptor:fontDescriptor size:size];
}

@end
