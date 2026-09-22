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
NSNotificationName const UIApplicationDidEnterBackgroundNotification = @"UIApplicationDidEnterBackgroundNotification";
NSNotificationName const UIApplicationWillEnterForegroundNotification = @"UIApplicationWillEnterForegroundNotification";
NSNotificationName const UIContentSizeCategoryDidChangeNotification = @"UIContentSizeCategoryDidChangeNotification";
NSNotificationName const UIKeyboardWillShowNotification = @"UIKeyboardWillShowNotification";
NSNotificationName const UIKeyboardWillChangeFrameNotification = @"UIKeyboardWillChangeFrameNotification";
NSNotificationName const UITextViewTextDidEndEditingNotification = @"UITextViewTextDidEndEditingNotification";
NSString * const UIKeyboardFrameEndUserInfoKey = @"UIKeyboardFrameEndUserInfoKey";
NSString * const UIKeyInputUpArrow = @"UIKeyInputUpArrow";
NSString * const UIKeyInputDownArrow = @"UIKeyInputDownArrow";
