/* UIGeometry.h — the C struct UIKit declares for edge insets. On Darwin this
 * IS OpenUIKit's `UIEdgeInsets` (UIScrollView.swift adds `.zero`, Equatable and
 * the defaulted initializer as an extension), so an internal override point
 * such as `-_defaultBaseLayoutMargins` can be declared in a header. Linux
 * keeps the Swift struct of the same shape. */
#ifndef OPENUIKIT_OBJC_UIGEOMETRY_H
#define OPENUIKIT_OBJC_UIGEOMETRY_H

#import <CoreGraphics/CoreGraphics.h>

typedef struct UIEdgeInsets {
    CGFloat top, left, bottom, right;
} UIEdgeInsets;

static inline UIEdgeInsets UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
    UIEdgeInsets i = {top, left, bottom, right};
    return i;
}

#endif
