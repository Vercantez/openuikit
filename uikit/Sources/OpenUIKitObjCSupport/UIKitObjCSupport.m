/* Definitions for the extern constants declared in UIKitObjCSupport.h. Every
 * string equals OpenUIKit's Swift raw value for the same name, so a value
 * written by Objective-C is the value OpenUIKit's Swift side reads back:
 *   UITransitionContext*Key  UIViewControllerTransitioning.swift:32-41
 *   UIFontTextStyle*         UIFontMetrics.swift:96-98
 *   NS*AttributeName         NSAttributedString.swift:52-83
 *   UI*Notification          UIApplication.swift:394-447 */

#import "UIKitObjCSupport.h"

const UIEdgeInsets UIEdgeInsetsZero = {0, 0, 0, 0};
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
