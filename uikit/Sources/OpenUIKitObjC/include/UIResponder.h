/* UIResponder — declared here, implemented in Sources/OpenUIKit/UIResponder.swift.
 * Members typed with Swift-defined classes (the touch / press entry points,
 * keyCommands, inputAssistantItem) are `@objc open` in a plain Swift extension
 * and reach Objective-C through the generated OpenUIKit-Swift.h. */
#ifndef OPENUIKIT_OBJC_UIRESPONDER_H
#define OPENUIKIT_OBJC_UIRESPONDER_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface UIResponder : NSObject

// No `-init` redeclaration: an initializer implemented by the Swift
// `@implementation` is a second Swift declaration next to the imported one
// (measured: `UIApplication()` became "ambiguous use of 'init()'"), and
// NSObject's `-init` is all UIResponder ever did.

/// Called once a nib-loaded object's outlets are all connected.
- (void)awakeFromNib;
/// UIKit's UIAccessibilityAction hook.
- (BOOL)accessibilityActivate;
@property (nonatomic, copy, nullable) NSString *accessibilityValue;

/// The next responder, or nil at the end of the chain.
@property (nonatomic, readonly, nullable) UIResponder *nextResponder NS_SWIFT_NAME(next);

@property (nonatomic, readonly) BOOL canBecomeFirstResponder;
@property (nonatomic, readonly) BOOL canResignFirstResponder;
@property (nonatomic, readonly) BOOL isFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

- (void)selectAll:(nullable id)sender;
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender;

@property (nonatomic, strong, nullable) NSUserActivity *userActivity;

@end

NS_ASSUME_NONNULL_END

#endif
