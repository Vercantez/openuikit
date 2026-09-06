@_exported import Foundation

/// Module-local stand-ins for undeclared modules (UIKit, Contacts). Isolated
/// host sources import Foundation only. Real UIKit/Contacts types are used on
/// the later EC2 integration build; this file must not substitute Foundation.

#if !canImport(UIKit) && !canImport(OpenUIKit)
open class UIViewController: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(Contacts)
open class CNPostalAddress: NSObject, @unchecked Sendable {
    public var street: String = ""
    public var city: String = ""
    public var state: String = ""
    public var postalCode: String = ""
    public var country: String = ""
    public var isoCountryCode: String = ""

    public override init() {
        super.init()
    }
}
#endif
