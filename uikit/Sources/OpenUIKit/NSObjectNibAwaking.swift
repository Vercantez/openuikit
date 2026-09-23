// NSObject (UINibLoadingAdditions) and NSObject (UINibDesignable): UIKit
// declares `awakeFromNib` and `prepareForInterfaceBuilder` on NSObject, not
// on a view class, so an Interface Builder custom OBJECT overrides them.
// Eidolon's ListingsCountdownManager is such an object (an NSObject in
// Auction.storyboard with outlets, `override func awakeFromNib()`), and
// KeypadContainerView overrides `prepareForInterfaceBuilder()`.
//
// MEASURED kioskrowsprobe `## nib` (iPad Pro 11-inch M4 / iOS 26.1): a
// plain NSObject responds to both selectors; an NSObject subclass's
// `-awakeFromNib` calling super runs once.
//
// Where AppKit is present (the macOS host) AppKit's NSNibAwaking and
// NSNibLoading categories already declare both on NSObject. Elsewhere on an
// Objective-C runtime (the iOS triple, the Mach-O guest) OpenUIKit declares
// them here, `@objc`, so an override in any subclass is an Objective-C
// override and the nib loader's message reaches it. Linux ELF has no
// Objective-C runtime: UIResponder declares awakeFromNib itself there.

#if _runtime(_ObjC) && !canImport(AppKit)
#if canImport(Foundation)
import class Foundation.NSObject
#else
import class ObjectiveC.NSObject
#endif

extension NSObject {
    @objc open func awakeFromNib() {}
    @objc open func prepareForInterfaceBuilder() {}
}
#endif
