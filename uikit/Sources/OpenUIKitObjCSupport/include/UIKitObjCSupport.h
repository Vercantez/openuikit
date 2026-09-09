/* UIKitObjCSupport.h — route (b) declarations that OpenUIKit's compiler-generated
 * `OpenUIKit-Swift.h` cannot carry: C enums, C structs, Objective-C protocols,
 * typed-string keys and notification names.
 *
 * Route (b) (Apple toolchain, Mach-O guest) gives an Objective-C translation
 * unit `<UIKit/UIKit.h>` = `OpenUIKit-Swift.h` (SwiftPM emits it for every
 * Swift target that a Clang target depends on) + this header. Everything here
 * is a PURE DECLARATION: no behaviour, no class, nothing that a Swift class
 * would already export. The raw values are read off the iOS 26.1 simulator SDK
 * headers (iPhoneSimulator26.1.sdk UIKit.framework, MEASURED 2026-09-07) and
 * the string constants off OpenUIKit's own Swift raw values, so an Objective-C
 * caller and a Swift caller of OpenUIKit agree on the same integers and
 * strings.
 *
 * Protocols carry NS_SWIFT_NAME(...ObjC): the bridging header that hands these
 * to the app's Swift half must not shadow OpenUIKit's Swift protocols of the
 * same name (MEASURED probe1: `'UITableViewDataSource' is ambiguous for type
 * lookup` when both are visible).
 *
 * Objective-C classes CANNOT subclass the classes in OpenUIKit-Swift.h: the
 * header marks them objc_subclassing_restricted, and lifting the attribute
 * jumps to a null Swift vtable slot at UIView.init() (MEASURED probe1,
 * docs/agent_reports/simplenote-launch3.md). This header does not pretend
 * otherwise. */

#ifndef OPENUIKIT_OBJC_SUPPORT_H
#define OPENUIKIT_OBJC_SUPPORT_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@class UIView, UIViewController, UINavigationController, UITableView, UITableViewCell,
       UIScrollView, UITextView, UITextField, UIGestureRecognizer, UIPickerView,
       UIApplication, UIApplicationShortcutItem, UITraitCollection;
/* Classes OpenUIKit does not derive from NSObject, so the generated header
 * cannot export them. A forward declaration lets an app header be parsed;
 * every member use is a measured wall (class ABI change in OpenUIKit). */
@class UIColor, UIFont, UIBarButtonItem, UIAlertAction, UIScreen, UIDevice, UIActivity,
       UIPercentDrivenInteractiveTransition, UIViewPropertyAnimator, UISpringTimingParameters,
       UIPresentationController, CALayer;

#pragma mark - Geometry (UIGeometry.h)

/* UIEdgeInsets / UIEdgeInsetsMake now come from the OpenUIKitObjC declaration
 * module (objc-impl-chain1): on Darwin that C struct IS OpenUIKit's Swift
 * `UIEdgeInsets`, so this header must not define a second one. */
#import <UIGeometry.h>
/* AppKit declares NSDirectionalEdgeInsets(Make/Zero) too. Any Swift module
 * that imports this one has AppKit loaded (OpenUIKit imports it on macOS) and
 * reports `different definitions in different modules` (MEASURED
 * OpenUIKitObjCBridgeTests, with and without a -D rename: the rename hits
 * AppKit's inline function too). An Objective-C translation unit does not
 * load AppKit, so only the ObjC side (OPENUIKIT_OBJC_SIDE=1, emitted by the
 * ingest tool) gets this copy: AppKit's four CGFloats. A Swift-side parse of
 * an app header that uses the type reports it unknown (Simplenote
 * SPTextField.h:13, one property on a class Objective-C cannot subclass
 * anyway). */
#if OPENUIKIT_OBJC_SIDE
typedef struct NSDirectionalEdgeInsets { CGFloat top, leading, bottom, trailing; } NSDirectionalEdgeInsets;
static inline NSDirectionalEdgeInsets NSDirectionalEdgeInsetsMake(CGFloat top, CGFloat leading, CGFloat bottom, CGFloat trailing) {
    NSDirectionalEdgeInsets i = {top, leading, bottom, trailing}; return i;
}
extern const NSDirectionalEdgeInsets NSDirectionalEdgeInsetsZero;
#endif
extern const UIEdgeInsets UIEdgeInsetsZero;

typedef NS_OPTIONS(NSUInteger, UIRectEdge) {
    UIRectEdgeNone = 0, UIRectEdgeTop = 1 << 0, UIRectEdgeLeft = 1 << 1,
    UIRectEdgeBottom = 1 << 2, UIRectEdgeRight = 1 << 3,
    UIRectEdgeAll = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight,
};

#pragma mark - Enumerations (raw values: iOS 26.1 SDK)

typedef NS_ENUM(NSInteger, UITableViewStyle) {
    UITableViewStylePlain, UITableViewStyleGrouped, UITableViewStyleInsetGrouped,
} NS_SWIFT_NAME(UITableViewStyleObjC);
typedef NS_ENUM(NSInteger, UITableViewCellStyle) {
    UITableViewCellStyleDefault, UITableViewCellStyleValue1, UITableViewCellStyleValue2, UITableViewCellStyleSubtitle,
} NS_SWIFT_NAME(UITableViewCellStyleObjC);
typedef NS_ENUM(NSInteger, UITableViewCellSelectionStyle) {
    UITableViewCellSelectionStyleNone, UITableViewCellSelectionStyleBlue,
    UITableViewCellSelectionStyleGray, UITableViewCellSelectionStyleDefault,
} NS_SWIFT_NAME(UITableViewCellSelectionStyleObjC);
typedef NS_ENUM(NSInteger, UITableViewCellEditingStyle) {
    UITableViewCellEditingStyleNone, UITableViewCellEditingStyleDelete, UITableViewCellEditingStyleInsert,
} NS_SWIFT_NAME(UITableViewCellEditingStyleObjC);
typedef NS_ENUM(NSInteger, UITableViewCellAccessoryType) {
    UITableViewCellAccessoryNone, UITableViewCellAccessoryDisclosureIndicator,
    UITableViewCellAccessoryDetailDisclosureButton, UITableViewCellAccessoryCheckmark,
    UITableViewCellAccessoryDetailButton,
} NS_SWIFT_NAME(UITableViewCellAccessoryTypeObjC);
typedef NS_ENUM(NSInteger, UITableViewRowAnimation) {
    UITableViewRowAnimationFade, UITableViewRowAnimationRight, UITableViewRowAnimationLeft,
    UITableViewRowAnimationTop, UITableViewRowAnimationBottom, UITableViewRowAnimationNone,
    UITableViewRowAnimationMiddle, UITableViewRowAnimationAutomatic = 100,
} NS_SWIFT_NAME(UITableViewRowAnimationObjC);
typedef NS_OPTIONS(NSUInteger, UIViewAutoresizing) {
    UIViewAutoresizingNone = 0,
    UIViewAutoresizingFlexibleLeftMargin = 1 << 0, UIViewAutoresizingFlexibleWidth = 1 << 1,
    UIViewAutoresizingFlexibleRightMargin = 1 << 2, UIViewAutoresizingFlexibleTopMargin = 1 << 3,
    UIViewAutoresizingFlexibleHeight = 1 << 4, UIViewAutoresizingFlexibleBottomMargin = 1 << 5,
} NS_SWIFT_NAME(UIViewAutoresizingObjC);
typedef NS_OPTIONS(NSUInteger, UIViewAnimationOptions) {
    UIViewAnimationOptionLayoutSubviews = 1 << 0, UIViewAnimationOptionAllowUserInteraction = 1 << 1,
    UIViewAnimationOptionBeginFromCurrentState = 1 << 2, UIViewAnimationOptionRepeat = 1 << 3,
    UIViewAnimationOptionAutoreverse = 1 << 4, UIViewAnimationOptionOverrideInheritedDuration = 1 << 5,
    UIViewAnimationOptionOverrideInheritedCurve = 1 << 6, UIViewAnimationOptionAllowAnimatedContent = 1 << 7,
    UIViewAnimationOptionShowHideTransitionViews = 1 << 8, UIViewAnimationOptionOverrideInheritedOptions = 1 << 9,
    UIViewAnimationOptionCurveEaseInOut = 0 << 16, UIViewAnimationOptionCurveEaseIn = 1 << 16,
    UIViewAnimationOptionCurveEaseOut = 2 << 16, UIViewAnimationOptionCurveLinear = 3 << 16,
    UIViewAnimationOptionTransitionNone = 0 << 20, UIViewAnimationOptionTransitionCrossDissolve = 5 << 20,
} NS_SWIFT_NAME(UIViewAnimationOptionsObjC);
typedef NS_ENUM(NSInteger, UIModalPresentationStyle) {
    UIModalPresentationFullScreen = 0, UIModalPresentationPageSheet, UIModalPresentationFormSheet,
    UIModalPresentationCurrentContext, UIModalPresentationCustom, UIModalPresentationOverFullScreen,
    UIModalPresentationOverCurrentContext, UIModalPresentationPopover, UIModalPresentationBlurOverFullScreen,
    UIModalPresentationNone = -1, UIModalPresentationAutomatic = -2,
} NS_SWIFT_NAME(UIModalPresentationStyleObjC);
typedef NS_OPTIONS(NSUInteger, UIControlEvents) {
    UIControlEventTouchDown = 1 << 0, UIControlEventTouchDownRepeat = 1 << 1,
    UIControlEventTouchDragInside = 1 << 2, UIControlEventTouchDragOutside = 1 << 3,
    UIControlEventTouchDragEnter = 1 << 4, UIControlEventTouchDragExit = 1 << 5,
    UIControlEventTouchUpInside = 1 << 6, UIControlEventTouchUpOutside = 1 << 7,
    UIControlEventTouchCancel = 1 << 8, UIControlEventValueChanged = 1 << 12,
    UIControlEventPrimaryActionTriggered = 1 << 13, UIControlEventMenuActionTriggered = 1 << 14,
    UIControlEventEditingDidBegin = 1 << 16, UIControlEventEditingChanged = 1 << 17,
    UIControlEventEditingDidEnd = 1 << 18, UIControlEventEditingDidEndOnExit = 1 << 19,
    UIControlEventAllTouchEvents = 0x00000FFF, UIControlEventAllEditingEvents = 0x000F0000,
    UIControlEventAllEvents = 0xFFFFFFFF,
} NS_SWIFT_NAME(UIControlEventsObjC);
typedef NS_OPTIONS(NSUInteger, UIControlState) {
    UIControlStateNormal = 0, UIControlStateHighlighted = 1 << 0, UIControlStateDisabled = 1 << 1,
    UIControlStateSelected = 1 << 2, UIControlStateFocused = 1 << 3,
} NS_SWIFT_NAME(UIControlStateObjC);
typedef NS_ENUM(NSInteger, UIGestureRecognizerState) {
    UIGestureRecognizerStatePossible, UIGestureRecognizerStateBegan, UIGestureRecognizerStateChanged,
    UIGestureRecognizerStateEnded, UIGestureRecognizerStateCancelled, UIGestureRecognizerStateFailed,
    UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded,
} NS_SWIFT_NAME(UIGestureRecognizerStateObjC);
typedef NS_ENUM(NSInteger, UINavigationControllerOperation) {
    UINavigationControllerOperationNone, UINavigationControllerOperationPush, UINavigationControllerOperationPop,
} NS_SWIFT_NAME(UINavigationControllerOperationObjC);
typedef NS_ENUM(NSInteger, UITextLayoutDirection) {
    UITextLayoutDirectionRight = 2, UITextLayoutDirectionLeft, UITextLayoutDirectionUp, UITextLayoutDirectionDown,
} NS_SWIFT_NAME(UITextLayoutDirectionObjC);
typedef NS_ENUM(NSInteger, UIAlertControllerStyle) {
    UIAlertControllerStyleActionSheet = 0, UIAlertControllerStyleAlert,
} NS_SWIFT_NAME(UIAlertControllerStyleObjC);
typedef NS_ENUM(NSInteger, UIAlertActionStyle) {
    UIAlertActionStyleDefault = 0, UIAlertActionStyleCancel, UIAlertActionStyleDestructive,
} NS_SWIFT_NAME(UIAlertActionStyleObjC);
typedef NS_ENUM(NSInteger, UIStatusBarStyle) {
    UIStatusBarStyleDefault = 0, UIStatusBarStyleLightContent = 1, UIStatusBarStyleDarkContent = 3,
} NS_SWIFT_NAME(UIStatusBarStyleObjC);
typedef NS_ENUM(NSInteger, UIBarStyle) {
    UIBarStyleDefault = 0, UIBarStyleBlack = 1,
} NS_SWIFT_NAME(UIBarStyleObjC);
typedef NS_ENUM(NSInteger, UIBarButtonItemStyle) {
    UIBarButtonItemStylePlain, UIBarButtonItemStyleBordered = 1, UIBarButtonItemStyleProminent = 2,
    UIBarButtonItemStyleDone = UIBarButtonItemStyleProminent,
} NS_SWIFT_NAME(UIBarButtonItemStyleObjC);
typedef NS_ENUM(NSInteger, UIBarButtonSystemItem) {
    UIBarButtonSystemItemDone, UIBarButtonSystemItemCancel, UIBarButtonSystemItemEdit, UIBarButtonSystemItemSave,
    UIBarButtonSystemItemAdd, UIBarButtonSystemItemFlexibleSpace, UIBarButtonSystemItemFixedSpace,
    UIBarButtonSystemItemCompose, UIBarButtonSystemItemReply, UIBarButtonSystemItemAction,
    UIBarButtonSystemItemOrganize, UIBarButtonSystemItemBookmarks, UIBarButtonSystemItemSearch,
    UIBarButtonSystemItemRefresh, UIBarButtonSystemItemStop, UIBarButtonSystemItemCamera,
    UIBarButtonSystemItemTrash, UIBarButtonSystemItemPlay, UIBarButtonSystemItemPause,
    UIBarButtonSystemItemRewind, UIBarButtonSystemItemFastForward, UIBarButtonSystemItemUndo,
    UIBarButtonSystemItemRedo, UIBarButtonSystemItemPageCurl, UIBarButtonSystemItemClose,
} NS_SWIFT_NAME(UIBarButtonSystemItemObjC);
typedef NS_ENUM(NSInteger, UIButtonType) {
    UIButtonTypeCustom = 0, UIButtonTypeSystem, UIButtonTypeDetailDisclosure, UIButtonTypeInfoLight,
    UIButtonTypeInfoDark, UIButtonTypeContactAdd, UIButtonTypePlain, UIButtonTypeClose,
    UIButtonTypeRoundedRect = UIButtonTypeSystem,
} NS_SWIFT_NAME(UIButtonTypeObjC);
typedef NS_ENUM(NSInteger, UIActivityIndicatorViewStyle) {
    UIActivityIndicatorViewStyleMedium = 100, UIActivityIndicatorViewStyleLarge = 101,
} NS_SWIFT_NAME(UIActivityIndicatorViewStyleObjC);
/* UIUserInterfaceLayoutDirection: exported by OpenUIKit-Swift.h itself since
 * objc-impl-chain1 (the Swift enum is `@objc`), same name and raw values. */
typedef NS_ENUM(NSInteger, UIAccessibilityContrast) {
    UIAccessibilityContrastUnspecified = -1, UIAccessibilityContrastNormal, UIAccessibilityContrastHigh,
} NS_SWIFT_NAME(UIAccessibilityContrastObjC);
typedef NS_ENUM(NSInteger, UITextAutocapitalizationType) {
    UITextAutocapitalizationTypeNone, UITextAutocapitalizationTypeWords,
    UITextAutocapitalizationTypeSentences, UITextAutocapitalizationTypeAllCharacters,
} NS_SWIFT_NAME(UITextAutocapitalizationTypeObjC);
typedef NS_ENUM(NSInteger, UITextAutocorrectionType) {
    UITextAutocorrectionTypeDefault, UITextAutocorrectionTypeNo, UITextAutocorrectionTypeYes,
} NS_SWIFT_NAME(UITextAutocorrectionTypeObjC);
typedef NS_ENUM(NSInteger, UIKeyboardType) {
    UIKeyboardTypeDefault, UIKeyboardTypeASCIICapable, UIKeyboardTypeNumbersAndPunctuation, UIKeyboardTypeURL,
    UIKeyboardTypeNumberPad, UIKeyboardTypePhonePad, UIKeyboardTypeNamePhonePad, UIKeyboardTypeEmailAddress,
    UIKeyboardTypeDecimalPad, UIKeyboardTypeTwitter, UIKeyboardTypeWebSearch, UIKeyboardTypeASCIICapableNumberPad,
} NS_SWIFT_NAME(UIKeyboardTypeObjC);
typedef NS_ENUM(NSInteger, UIKeyboardAppearance) {
    UIKeyboardAppearanceDefault, UIKeyboardAppearanceDark, UIKeyboardAppearanceLight,
} NS_SWIFT_NAME(UIKeyboardAppearanceObjC);
typedef NS_ENUM(NSInteger, UIReturnKeyType) {
    UIReturnKeyDefault, UIReturnKeyGo, UIReturnKeyGoogle, UIReturnKeyJoin, UIReturnKeyNext, UIReturnKeyRoute,
    UIReturnKeySearch, UIReturnKeySend, UIReturnKeyYahoo, UIReturnKeyDone, UIReturnKeyEmergencyCall, UIReturnKeyContinue,
} NS_SWIFT_NAME(UIReturnKeyTypeObjC);
typedef NS_ENUM(NSInteger, UITextFieldViewMode) {
    UITextFieldViewModeNever, UITextFieldViewModeWhileEditing, UITextFieldViewModeUnlessEditing, UITextFieldViewModeAlways,
} NS_SWIFT_NAME(UITextFieldViewModeObjC);
typedef NS_ENUM(NSInteger, NSTextAlignment) {
    NSTextAlignmentLeft = 0, NSTextAlignmentCenter = 1, NSTextAlignmentRight = 2,
    NSTextAlignmentJustified = 3, NSTextAlignmentNatural = 4,
} NS_SWIFT_NAME(NSTextAlignmentObjC);
typedef NS_OPTIONS(NSUInteger, NSTextStorageEditActions) {
    NSTextStorageEditedAttributes = (1 << 0), NSTextStorageEditedCharacters = (1 << 1),
} NS_SWIFT_NAME(NSTextStorageEditActionsObjC);

#pragma mark - Typed strings, keys and notification names

typedef NSString * UIApplicationLaunchOptionsKey NS_TYPED_ENUM NS_SWIFT_NAME(UIApplicationLaunchOptionsKeyObjC);
typedef NSString * UIApplicationOpenURLOptionsKey NS_TYPED_ENUM NS_SWIFT_NAME(UIApplicationOpenURLOptionsKeyObjC);
typedef NSString * UITransitionContextViewControllerKey NS_TYPED_ENUM NS_SWIFT_NAME(UITransitionContextViewControllerKeyObjC);
typedef NSString * UITransitionContextViewKey NS_TYPED_ENUM NS_SWIFT_NAME(UITransitionContextViewKeyObjC);
typedef NSString * UIFontTextStyle NS_TYPED_ENUM NS_SWIFT_NAME(UIFontTextStyleObjC);
/* NSAttributedStringKey is Foundation's typedef on macOS; the UIKit-side
 * attribute-name constants are not (AppKit declares those), so they are here. */

/* Values equal OpenUIKit's Swift raw values (UIViewControllerTransitioning.swift:32-41,
 * UIFontMetrics.swift:96-98, NSAttributedString.swift:52-83, UIApplication.swift:394-447). */
extern UITransitionContextViewControllerKey const UITransitionContextFromViewControllerKey;
extern UITransitionContextViewControllerKey const UITransitionContextToViewControllerKey;
extern UITransitionContextViewKey const UITransitionContextFromViewKey;
extern UITransitionContextViewKey const UITransitionContextToViewKey;
extern UIFontTextStyle const UIFontTextStyleHeadline;
extern UIFontTextStyle const UIFontTextStyleSubheadline;
extern UIFontTextStyle const UIFontTextStyleBody;
extern NSAttributedStringKey const NSFontAttributeName;
extern NSAttributedStringKey const NSForegroundColorAttributeName;
extern NSAttributedStringKey const NSParagraphStyleAttributeName;
extern NSAttributedStringKey const NSLinkAttributeName;
extern NSAttributedStringKey const NSAttachmentAttributeName;
extern NSNotificationName const UIApplicationDidEnterBackgroundNotification;
extern NSNotificationName const UIApplicationWillEnterForegroundNotification;
extern NSNotificationName const UIContentSizeCategoryDidChangeNotification;
extern NSNotificationName const UIKeyboardWillShowNotification;
extern NSNotificationName const UIKeyboardWillChangeFrameNotification;
extern NSNotificationName const UITextViewTextDidEndEditingNotification;
extern NSString * const UIKeyboardFrameEndUserInfoKey;
extern NSString * const UIKeyInputUpArrow;
extern NSString * const UIKeyInputDownArrow;

#pragma mark - Protocols

@protocol UIApplicationDelegate <NSObject>
@optional
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;
- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler;
- (BOOL)application:(UIApplication *)application shouldSaveSecureApplicationState:(NSCoder *)coder;
- (BOOL)application:(UIApplication *)application shouldRestoreSecureApplicationState:(NSCoder *)coder;
@end

@protocol UIUserActivityRestoring <NSObject>
- (void)restoreUserActivityState:(NSUserActivity *)userActivity;
@end

@protocol UIScrollViewDelegate <NSObject>
@optional
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
@end

@protocol UITableViewDataSource <NSObject>
@required
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UITableViewDelegate <NSObject, UIScrollViewDelegate>
@optional
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UITextViewDelegate <NSObject, UIScrollViewDelegate>
@optional
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView;
- (void)textViewDidBeginEditing:(UITextView *)textView;
- (void)textViewDidEndEditing:(UITextView *)textView;
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)textViewDidChange:(UITextView *)textView;
- (void)textViewDidChangeSelection:(UITextView *)textView;
@end

@protocol UITextFieldDelegate <NSObject>
@optional
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;
- (void)textFieldDidBeginEditing:(UITextField *)textField;
@end

@protocol UIGestureRecognizerDelegate <NSObject>
@optional
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
@end

@protocol UIViewControllerTransitionCoordinatorContext <NSObject>
- (BOOL)isAnimated;
- (NSTimeInterval)transitionDuration;
- (nullable UIViewController *)viewControllerForKey:(UITransitionContextViewControllerKey)key;
- (nullable UIView *)viewForKey:(UITransitionContextViewKey)key;
@end
@protocol UIViewControllerTransitionCoordinator <UIViewControllerTransitionCoordinatorContext>
- (BOOL)animateAlongsideTransition:(void (^ _Nullable)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                        completion:(void (^ _Nullable)(id<UIViewControllerTransitionCoordinatorContext> context))completion;
@end
@protocol UIViewControllerContextTransitioning <NSObject>
- (nullable UIView *)containerView;
- (BOOL)isAnimated;
- (BOOL)isInteractive;
- (BOOL)transitionWasCancelled;
- (void)updateInteractiveTransition:(CGFloat)percentComplete;
- (void)finishInteractiveTransition;
- (void)cancelInteractiveTransition;
- (void)completeTransition:(BOOL)didComplete;
- (nullable UIViewController *)viewControllerForKey:(UITransitionContextViewControllerKey)key;
- (nullable UIView *)viewForKey:(UITransitionContextViewKey)key;
@end
@protocol UIViewControllerAnimatedTransitioning <NSObject>
- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext;
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext;
@end
@protocol UIViewControllerInteractiveTransitioning <NSObject>
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext;
@end
@protocol UINavigationControllerDelegate <NSObject>
@optional
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (nullable id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController;
- (nullable id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC;
@end
@protocol UIPickerViewDataSource <NSObject>
@required
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
@end
@protocol UIPickerViewDelegate <NSObject>
@optional
- (nullable NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;
@end

NS_ASSUME_NONNULL_END

#endif /* OPENUIKIT_OBJC_SUPPORT_H */
