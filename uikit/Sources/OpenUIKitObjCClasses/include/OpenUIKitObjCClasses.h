/* OpenUIKitObjCClasses — UIKit classes whose Objective-C API cannot be
 * written in Swift, implemented in Objective-C over OpenUIKit (route b,
 * Apple toolchain). Today: UIAlertView, whose designated initializer is
 * variadic (`otherButtonTitles:(NSString *)…, ... NS_REQUIRES_NIL_TERMINATION`),
 * which a Swift `@objc` member cannot implement. DZNWebViewController (Eidolon)
 * shows one when a page fails to load (docs/agent_reports/eidolon-kiosk.md).
 *
 * Values MEASURED on the iOS 26.1 simulator
 * (Tools/oracle2/kioskrowsprobe/transcript-ios26.1.txt `## alertview`). */
#ifndef OPENUIKIT_OBJC_CLASSES_H
#define OPENUIKIT_OBJC_CLASSES_H

#import <Foundation/Foundation.h>
#import "OpenUIKit-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@class UIAlertView;

NS_SWIFT_NAME(UIAlertViewDelegateObjC) @protocol UIAlertViewDelegate <NSObject>
@optional
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
@end

API_DEPRECATED("UIAlertView is deprecated. Use UIAlertController with a preferredStyle of UIAlertControllerStyleAlert instead", ios(2.0, 9.0))
@interface UIAlertView : UIView

- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message
                     delegate:(nullable id)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle
            otherButtonTitles:(nullable NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@property (nullable, nonatomic, weak) id delegate;
@property (nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSString *message;
@property (nonatomic, readonly) NSInteger numberOfButtons;
@property (nonatomic) NSInteger cancelButtonIndex;
@property (nonatomic, readonly) NSInteger firstOtherButtonIndex;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

- (NSInteger)addButtonWithTitle:(nullable NSString *)title;
- (nullable NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;
- (void)show;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
#endif
