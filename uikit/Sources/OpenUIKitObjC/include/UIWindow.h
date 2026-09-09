/* UIWindow — declared here, implemented in Sources/OpenUIKit/UIEvent.swift.
 * `rootViewController`, `windowScene`, `sendEvent:` (Swift-defined classes)
 * and `initWithWindowScene:` are in a plain Swift extension. */
#ifndef OPENUIKIT_OBJC_UIWINDOW_H
#define OPENUIKIT_OBJC_UIWINDOW_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "UIView.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_UI_ACTOR
@interface UIWindow : UIView

- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

/// Current first responder (text-input focus).
@property (nonatomic, readonly, nullable) UIResponder *firstResponder;
@property (nonatomic, readonly) BOOL isKeyWindow;

- (void)makeKey;
- (void)makeKeyAndVisible;

/// Advance event time without any touch change (the host's frame loop).
- (void)tickWithTimestamp:(NSTimeInterval)timestamp NS_SWIFT_NAME(tick(timestamp:));

@end

NS_ASSUME_NONNULL_END

#endif
