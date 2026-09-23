/* Definitions for the extern constants declared in UIKitObjCSupport.h. Every
 * string equals OpenUIKit's Swift raw value for the same name, so a value
 * written by Objective-C is the value OpenUIKit's Swift side reads back:
 *   UITransitionContext*Key  UIViewControllerTransitioning.swift:32-41
 *   UIFontTextStyle*         UIFontMetrics.swift:96-98
 *   NS*AttributeName         NSAttributedString.swift:52-83
 *   UI*Notification          UIApplication.swift:394-447 */

#import "UIKitObjCSupport.h"

/* Build-time check that UI_APPEARANCE_SELECTOR is defined the way Objective-C
 * pods use it (a property annotation); without the macro this is a parse
 * error, as it was for SVProgressHUD 2.2.3's 42 declarations. */
@interface _OUKAppearanceSelectorCheck : NSObject
@property (nonatomic) NSInteger value UI_APPEARANCE_SELECTOR;
@end
@implementation _OUKAppearanceSelectorCheck
@end

const UIEdgeInsets UIEdgeInsetsZero = {0, 0, 0, 0};
const UIOffset UIOffsetZero = {0, 0};
const CGFloat UITableViewAutomaticDimension = -1;

const UIFontWeight UIFontWeightUltraLight = -0.8;
const UIFontWeight UIFontWeightThin = -0.6;
const UIFontWeight UIFontWeightLight = -0.4;
const UIFontWeight UIFontWeightRegular = 0;
const UIFontWeight UIFontWeightMedium = 0.23;
const UIFontWeight UIFontWeightSemibold = 0.3;
const UIFontWeight UIFontWeightBold = 0.4;
const UIFontWeight UIFontWeightHeavy = 0.56;
const UIFontWeight UIFontWeightBlack = 0.62;
const NSDirectionalEdgeInsets NSDirectionalEdgeInsetsZero = {0, 0, 0, 0};

UITransitionContextViewControllerKey const UITransitionContextFromViewControllerKey = @"UITransitionContextFromViewController";
UITransitionContextViewControllerKey const UITransitionContextToViewControllerKey = @"UITransitionContextToViewController";
UITransitionContextViewKey const UITransitionContextFromViewKey = @"UITransitionContextFromView";
UITransitionContextViewKey const UITransitionContextToViewKey = @"UITransitionContextToView";
UIFontTextStyle const UIFontTextStyleHeadline = @"headline";
UIFontTextStyle const UIFontTextStyleSubheadline = @"subheadline";
UIFontTextStyle const UIFontTextStyleBody = @"body";
NSAttributedStringKey const NSFontAttributeName = @"NSFont";
NSAttributedStringKey const NSForegroundColorAttributeName = @"NSColor";
NSAttributedStringKey const NSParagraphStyleAttributeName = @"NSParagraphStyle";
NSAttributedStringKey const NSLinkAttributeName = @"NSLink";
NSAttributedStringKey const NSAttachmentAttributeName = @"NSAttachment";
NSAttributedStringKey const NSUnderlineStyleAttributeName = @"NSUnderline";          /* NSAttributedString.swift underlineStyle */
NSAttributedStringKey const NSStrikethroughStyleAttributeName = @"NSStrikethrough";  /* NSAttributedString.swift strikethroughStyle */
const CGFloat UIViewNoIntrinsicMetric = -1;                                          /* UIView.noIntrinsicMetric */
NSNotificationName const UIApplicationDidEnterBackgroundNotification = @"UIApplicationDidEnterBackgroundNotification";
NSNotificationName const UIApplicationDidBecomeActiveNotification = @"UIApplicationDidBecomeActiveNotification";
NSNotificationName const UIApplicationDidReceiveMemoryWarningNotification = @"UIApplicationDidReceiveMemoryWarningNotification";
NSNotificationName const UIApplicationWillEnterForegroundNotification = @"UIApplicationWillEnterForegroundNotification";
NSNotificationName const UIContentSizeCategoryDidChangeNotification = @"UIContentSizeCategoryDidChangeNotification";
NSNotificationName const UIKeyboardWillShowNotification = @"UIKeyboardWillShowNotification";
NSNotificationName const NSTextStorageWillProcessEditingNotification = @"NSTextStorageWillProcessEditingNotification";
NSNotificationName const NSTextStorageDidProcessEditingNotification = @"NSTextStorageDidProcessEditingNotification";
NSNotificationName const UIKeyboardWillChangeFrameNotification = @"UIKeyboardWillChangeFrameNotification";
NSNotificationName const UITextViewTextDidEndEditingNotification = @"UITextViewTextDidEndEditingNotification";
NSString * const UICollectionElementKindSectionHeader = @"UICollectionElementKindSectionHeader";
NSString * const UICollectionElementKindSectionFooter = @"UICollectionElementKindSectionFooter";
NSString * const UIKeyboardFrameEndUserInfoKey = @"UIKeyboardFrameEndUserInfoKey";
NSString * const UIKeyInputUpArrow = @"UIKeyInputUpArrow";
NSString * const UIKeyInputDownArrow = @"UIKeyInputDownArrow";

/* NSDictionaryOfVariableBindings(view, other) -> @{@"view": view, @"other": other}
 * (MEASURED iOS 26.1, podsurfaceprobe "## vfl": the keys are the argument
 * spellings, whitespace dropped). */
#if TARGET_OS_IPHONE || !__swift__
NSDictionary<NSString *, id> *_NSDictionaryOfVariableBindings(NSString *commaSeparatedKeysString, id firstValue, ...) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSArray<NSString *> *keys = [commaSeparatedKeysString componentsSeparatedByString:@","];
    va_list args;
    va_start(args, firstValue);
    id value = firstValue;
    for (NSString *raw in keys) {
        if (!value) break;
        NSString *key = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        result[key] = value;
        value = va_arg(args, id);
    }
    va_end(args);
    return [result copy];
}
#endif

/* UIWindow.Level (UIEvent.swift), MEASURED iOS 26.1 podsurfaceprobe "## windowlevel". */
const UIWindowLevel UIWindowLevelNormal = 0;
const UIWindowLevel UIWindowLevelStatusBar = 1000;
const UIWindowLevel UIWindowLevelAlert = 2000;

/* Eidolon Kiosk rows, MEASURED iOS 26.1 (Tools/oracle2/kioskrowsprobe
 * transcript-ios26.1.txt `## application`, `## activity`, `## font`). */
const UIBackgroundTaskIdentifier UIBackgroundTaskInvalid = 0;
NSNotificationName const UIApplicationWillTerminateNotification = @"UIApplicationWillTerminateNotification";
UIActivityType const UIActivityTypePostToFacebook = @"com.apple.UIKit.activity.PostToFacebook";
UIActivityType const UIActivityTypePostToTwitter = @"com.apple.UIKit.activity.PostToTwitter";
UIActivityType const UIActivityTypePostToWeibo = @"com.apple.UIKit.activity.PostToWeibo";
UIActivityType const UIActivityTypeMessage = @"com.apple.UIKit.activity.Message";
UIActivityType const UIActivityTypeMail = @"com.apple.UIKit.activity.Mail";
UIActivityType const UIActivityTypePrint = @"com.apple.UIKit.activity.Print";
UIActivityType const UIActivityTypeCopyToPasteboard = @"com.apple.UIKit.activity.CopyToPasteboard";
UIActivityType const UIActivityTypeAssignToContact = @"com.apple.UIKit.activity.AssignToContact";
UIActivityType const UIActivityTypeSaveToCameraRoll = @"com.apple.UIKit.activity.SaveToCameraRoll";
UIActivityType const UIActivityTypeAddToReadingList = @"com.apple.UIKit.activity.AddToReadingList";
UIActivityType const UIActivityTypePostToFlickr = @"com.apple.UIKit.activity.PostToFlickr";
UIActivityType const UIActivityTypePostToTencentWeibo = @"com.apple.UIKit.activity.TencentWeibo";
UIActivityType const UIActivityTypeAirDrop = @"com.apple.UIKit.activity.AirDrop";
UIFontDescriptorAttributeName const UIFontDescriptorFamilyAttribute = @"NSFontFamilyAttribute";
UIFontDescriptorAttributeName const UIFontDescriptorNameAttribute = @"NSFontNameAttribute";
UIFontDescriptorAttributeName const UIFontDescriptorSizeAttribute = @"NSFontSizeAttribute";
UIFontDescriptorAttributeName const UIFontDescriptorFeatureSettingsAttribute = @"NSCTFontFeatureSettingsAttribute";
UIFontDescriptorFeatureKey const UIFontFeatureTypeIdentifierKey = @"CTFeatureTypeIdentifier";
UIFontDescriptorFeatureKey const UIFontFeatureSelectorIdentifierKey = @"CTFeatureSelectorIdentifier";

/* Round 2, MEASURED kioskrowsprobe `## hud` (iOS 26.1). */
UIAccessibilityNotifications UIAccessibilityScreenChangedNotification = 1000;
UIAccessibilityNotifications UIAccessibilityAnnouncementNotification = 1008;
NSNotificationName const UIApplicationDidChangeStatusBarOrientationNotification = @"UIApplicationDidChangeStatusBarOrientationNotification";
NSNotificationName const UIKeyboardWillHideNotification = @"UIKeyboardWillHideNotification";
NSNotificationName const UIKeyboardDidHideNotification = @"UIKeyboardDidHideNotification";
NSNotificationName const UIKeyboardDidShowNotification = @"UIKeyboardDidShowNotification";
NSString * const UIKeyboardFrameBeginUserInfoKey = @"UIKeyboardFrameBeginUserInfoKey";
NSString * const UIKeyboardAnimationDurationUserInfoKey = @"UIKeyboardAnimationDurationUserInfoKey";
