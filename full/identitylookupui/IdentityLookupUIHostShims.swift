import Foundation

#if canImport(IdentityLookup)
import IdentityLookup
#endif
#if canImport(UIKit)
import UIKit
#endif

// Isolated-host stand-ins for IdentityLookup and UIKit types named by the
// public IdentityLookupUI surface. The sealed host gate compiles this module
// alone. When a real `IdentityLookup` / `UIKit` module is on the link line,
// these blocks compile out. They are not a Linux IdentityLookup or UIKit
// port and must not be cited as proof of those identities.

#if !canImport(IdentityLookup)
/// IdentityLookup-owned classification action. Isolation stand-in only.
/// Raw values match the Linux `IdentityLookup` / pinned macios `[Native]`
/// order: none, reportNotJunk, reportJunk, reportJunkAndBlockSender.
public enum ILClassificationAction: Int, Hashable, Sendable {
    case none = 0
    case reportNotJunk = 1
    case reportJunk = 2
    case reportJunkAndBlockSender = 3
}

/// IdentityLookup-owned classification request. Isolation stand-in only.
open class ILClassificationRequest: NSObject {
    public override init() {
        super.init()
    }
}

/// IdentityLookup-owned classification response. Isolation stand-in only.
open class ILClassificationResponse: NSObject {
    public private(set) var action: ILClassificationAction

    public init(action: ILClassificationAction) {
        self.action = action
        super.init()
    }
}
#endif

#if !canImport(UIKit)
/// UIKit-owned view-controller base. Isolation stand-in only.
open class UIViewController: NSObject {
    public override init() {
        super.init()
    }
}
#endif
