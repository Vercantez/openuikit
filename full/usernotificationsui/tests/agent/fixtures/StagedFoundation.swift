@_exported import Foundation

/// Test-only EC2 staging overlay for `Foundation.NSExtensionContext`.
/// Not part of the UserNotificationsUI product module. NotificationCenter and
/// UserNotificationsUI both extend this identity instead of owning a class.
open class NSExtensionContext: NSObject {
    public override init() {
        super.init()
    }
}
