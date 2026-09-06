// Focus DesignSystem images. The catalog images live in
// BlockzillaPackage/Sources/DesignSystem/Images.xcassets; this module
// has no resource bundle (Hackers DesignSystem is compile/link-only).
// Named lookup goes through OpenUIKitRuntime.imageSearchPaths /
// UIImage(named:) so copied fixtures resolve; missing names fall back
// to an empty image rather than force-unwrapping nil (the upstream
// `UIImage(named:)!` would trap).

import UIKit

public extension UIImage {
    static let trackingProtectionOff = UIImage(named: "tracking_protection_off") ?? UIImage()
    static let trackingProtectionOn = UIImage(named: "tracking_protection") ?? UIImage()
    static let connectionNotSecure = UIImage(named: "connection_not_secure") ?? UIImage()
    static let connectionSecure = UIImage(named: "icon_https") ?? UIImage()
    static let defaultFavicon = UIImage(named: "icon_favicon") ?? UIImage()
    static let iconClose = UIImage(named: "icon_close") ?? UIImage()
    static let removeShortcut = UIImage(named: "icon_shortcuts_remove") ?? UIImage()
    static let renameShortcut = UIImage(named: "edit") ?? UIImage()
    static let faceid = UIImage(named: "faceid") ?? UIImage()
    static let touchid = UIImage(named: "touchid") ?? UIImage()
    static let mozilla = UIImage(named: "icon_mozilla") ?? UIImage()
    static let privateMode = UIImage(named: "icon_private_mode") ?? UIImage()
    static let history = UIImage(named: "icon_history") ?? UIImage()
    static let settings = UIImage(named: "icon_settings") ?? UIImage()
    static let clear = UIImage(named: "icon_clear") ?? UIImage()
    static let cancel = UIImage(named: "icon_cancel") ?? UIImage()
    static let backActive = UIImage(named: "icon_back_active") ?? UIImage()
    static let forwardActive = UIImage(named: "icon_forward_active") ?? UIImage()
    static let refreshMenu = UIImage(named: "icon_refresh_menu") ?? UIImage()
    static let delete = UIImage(named: "icon_delete") ?? UIImage()
    static let hamburgerMenu = UIImage(named: "icon_hamburger_menu") ?? UIImage()
    static let stopMenu = UIImage(named: "icon_stop_menu") ?? UIImage()
    static let findPrevious = UIImage(named: "find_previous") ?? UIImage()
    static let findNext = UIImage(named: "find_next") ?? UIImage()
}
