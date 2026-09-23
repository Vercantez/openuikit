/* Guest-only stand-in for <Foundation/Foundation.h>, used by
 * scripts/objc_surface_guest_probe.sh and nothing else.
 *
 * The Mach-O guest has objc4 and no Foundation framework headers. OpenUIKit's
 * generated OpenUIKit-Swift.h includes <Foundation/Foundation.h> under
 * __OBJC__ (MEASURED: "fatal error: 'Foundation/Foundation.h' file not found"
 * compiling the scenario against the guest header). What the guest header
 * actually uses from it — NSObject, NSInteger/NSUInteger, BOOL, SEL, and
 * forward-declared Foundation classes — objc4's own headers provide. */
#import <objc/NSObject.h>
#import <objc/NSObjCRuntime.h>
