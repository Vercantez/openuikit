/* Internal override points of the implementation classes. A member of an
 * `@objc @implementation` extension that is not declared in a header must be
 * `final`, so the hooks OpenUIKit's own subclasses override live in these
 * categories (implemented by `@objc(OpenUIKitInternal) @implementation`
 * extensions). Objective-C has no `internal`: an override of one of these is
 * necessarily `public` (measured: "overriding property must be as accessible
 * as the declaration it overrides"). Not UIKit API. */
#ifndef OPENUIKIT_OBJC_INTERNAL_H
#define OPENUIKIT_OBJC_INTERNAL_H

#import "UIGeometry.h"
#import "UIResponder.h"
#import "UIView.h"
#import "UIWindow.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIResponder (OpenUIKitInternal)
/// The window this responder takes first-responder status in, or nil.
@property (nonatomic, readonly, nullable) UIWindow *_firstResponderWindow;
@end

@interface UIView (OpenUIKitInternal)
/// UIKit's default base margins (8 pt); UITableViewCell's follow the window.
@property (nonatomic, readonly) UIEdgeInsets _defaultBaseLayoutMargins;
@end

NS_ASSUME_NONNULL_END

#endif
