/* UIGeometry.h — the CoreGraphics geometry conveniences gnustep-base does not
 * ship.
 *
 * MEASURED: <Foundation/NSGeometry.h> (gnustep-base 1.31.1) already declares
 * `CGFloat`, `struct CGPoint`, `struct CGSize` and `struct CGRect` — NSPoint,
 * NSSize and NSRect are typedefs of those very structs, and NSRectFromCGRect /
 * NSRectToCGRect are casts. So the *types* are free on Linux for ObjC exactly
 * as they are for Swift (docs/PORTABILITY.md records the Swift half).
 *
 * What is missing is the CGGeometry function family. This header adds the
 * handful the facade and its test app use. A production facade would either
 * finish the family here or link GNUstep's libs-corebase, which implements
 * CGGeometry properly.
 */

#ifndef OPENUIKIT_OBJC_UIGEOMETRY_H
#define OPENUIKIT_OBJC_UIGEOMETRY_H

#import <Foundation/NSGeometry.h>

/* On Darwin, Foundation drags in CoreGraphics and the whole CGGeometry family
 * is already declared (non-static, so a static redefinition is an error). The
 * facade itself compiles unchanged on both platforms — only this shim is
 * platform-conditional, which is a useful measurement in itself: the
 * Objective-C facade's ONE portability seam is CGGeometry's free functions. */
#if !defined(__APPLE__)

static inline CGPoint CGPointMake(CGFloat x, CGFloat y) {
    CGPoint p; p.x = x; p.y = y; return p;
}
static inline CGSize CGSizeMake(CGFloat w, CGFloat h) {
    CGSize s; s.width = w; s.height = h; return s;
}
static inline CGRect CGRectMake(CGFloat x, CGFloat y, CGFloat w, CGFloat h) {
    CGRect r; r.origin.x = x; r.origin.y = y; r.size.width = w; r.size.height = h; return r;
}
static inline CGFloat CGRectGetMinX(CGRect r) { return r.origin.x; }
static inline CGFloat CGRectGetMinY(CGRect r) { return r.origin.y; }
static inline CGFloat CGRectGetWidth(CGRect r) { return r.size.width; }
static inline CGFloat CGRectGetHeight(CGRect r) { return r.size.height; }
static inline CGFloat CGRectGetMaxX(CGRect r) { return r.origin.x + r.size.width; }
static inline CGFloat CGRectGetMaxY(CGRect r) { return r.origin.y + r.size.height; }
static inline CGRect CGRectInset(CGRect r, CGFloat dx, CGFloat dy) {
    return CGRectMake(r.origin.x + dx, r.origin.y + dy,
                      r.size.width - 2 * dx, r.size.height - 2 * dy);
}

#define CGPointZero CGPointMake(0, 0)
#define CGSizeZero  CGSizeMake(0, 0)
#define CGRectZero  CGRectMake(0, 0, 0, 0)

#else
#import <CoreGraphics/CGGeometry.h>
#endif /* !__APPLE__ */

#endif /* OPENUIKIT_OBJC_UIGEOMETRY_H */
