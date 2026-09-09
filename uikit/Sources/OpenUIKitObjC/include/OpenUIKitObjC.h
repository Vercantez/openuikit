/* OpenUIKitObjC — the Objective-C DECLARATIONS of OpenUIKit's implementation
 * classes. The implementations are Swift (`@objc @implementation extension`,
 * SE-0436) in Sources/OpenUIKit; OpenUIKit re-exports this module, so a Swift
 * client sees `OpenUIKit.UIView` exactly as before and an Objective-C client
 * can subclass these classes (the spike's chain rule: every class from
 * UIResponder down to the subclassed one must be declared here).
 *
 * Rules the compiler enforces (measured, docs/agent_reports/objc-implementation-spike.md
 * and objc-impl-chain1.md):
 *   - a member of the implementation extension that is not declared here must
 *     be `final` / private; initializers not declared here must be private;
 *   - a header type can only be a Foundation/CoreGraphics type or a class
 *     declared in an Objective-C header — a forward declaration of a Swift
 *     class does NOT unify with it, the member is simply treated as absent;
 *   - overridable members typed with Swift-defined classes/structs live in a
 *     plain `extension` as `@objc open` (dynamic dispatch, no vtable), which
 *     the generated OpenUIKit-Swift.h exports as categories;
 *   - a readonly property here is get-only inside the implementation, so it
 *     is a getter over a `final` backing ivar;
 *   - `superview` is declared readonly, not weak, like UIKit's header.
 */
#ifndef OPENUIKIT_OBJC_H
#define OPENUIKIT_OBJC_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "UIGeometry.h"
#import "UIResponder.h"
#import "UIView.h"
#import "UIWindow.h"
#import "OpenUIKitInternal.h"

#endif
