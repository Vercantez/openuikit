// Swift 4 spellings of UIKit MEMBERS and functions (Swift4Names.swift has the
// type names), for app source built in Swift 4 mode (Eidolon). Each entry is
// one the iPhoneSimulator26.1 SDK imports under this name in Swift 4 mode:
// UIKit.apinotes `SwiftVersions: Version 4` (Classes / Enumerators /
// Functions) or, for the deceleration constants, UIScrollView.h's C globals
// that Swift 4 imports unrenamed. Tools/ingest/test_uikit_swift4_names.py
// checks every entry against the SDK. `obsoleted: 4.2` hides them from Swift
// 4.2+ clients, as UIKit does. Only members Eidolon's source reaches are here.

@available(swift, obsoleted: 4.2, renamed: "UIEdgeInsets.init(top:left:bottom:right:)")
public func UIEdgeInsetsMake(_ top: CGFloat, _ left: CGFloat, _ bottom: CGFloat, _ right: CGFloat) -> UIEdgeInsets {
    UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
}

extension UIViewController {
    @available(swift, obsoleted: 4.2, renamed: "children")
    public final var childViewControllers: [UIViewController] { children }
}

extension UIView {
    @available(swift, obsoleted: 4.2, renamed: "bringSubviewToFront(_:)")
    public final func bringSubview(toFront view: UIView) { bringSubviewToFront(view) }
    @available(swift, obsoleted: 4.2, renamed: "sendSubviewToBack(_:)")
    public final func sendSubview(toBack view: UIView) { sendSubviewToBack(view) }
}

extension NSUnderlineStyle {
    @available(swift, obsoleted: 4.2, renamed: "single")
    public static var styleSingle: NSUnderlineStyle { .single }
    @available(swift, obsoleted: 4.2, renamed: "thick")
    public static var styleThick: NSUnderlineStyle { .thick }
    @available(swift, obsoleted: 4.2, renamed: "double")
    public static var styleDouble: NSUnderlineStyle { .double }
    @available(swift, obsoleted: 4.2)
    public static var styleNone: NSUnderlineStyle { [] }
}

@available(swift, obsoleted: 4.2, renamed: "UIScrollView.DecelerationRate.fast")
@MainActor public var UIScrollViewDecelerationRateFast: UIScrollView.DecelerationRate { .fast }
@available(swift, obsoleted: 4.2, renamed: "UIScrollView.DecelerationRate.normal")
@MainActor public var UIScrollViewDecelerationRateNormal: UIScrollView.DecelerationRate { .normal }
