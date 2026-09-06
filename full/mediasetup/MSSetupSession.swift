import Foundation

/// A Media Setup session that would present Apple's HomePod / Apple TV
/// service-sign-in UI on Darwin.
///
/// Apple graph: `open class MSSetupSession` inheriting `NSObject`, iOS 14.
/// `init(serviceAccount:)` retains the account. `presentationContext` is weak.
/// `start()` is `throws` (ObjC `startWithError:`). Linux has no media-setup
/// daemon or authentication sheet: `start()` always throws
/// `MediaSetup.linux.unavailable` / code 1, even when a presentation context
/// is assigned. Darwin's NSError domain and code are unobserved.
open class MSSetupSession: NSObject {
    private let storedAccount: MSServiceAccount

    /// The account passed to the designated initializer. Strong identity.
    open var account: MSServiceAccount { storedAccount }

    /// Weak presentation context. Defaults to `nil`. Assigning it does not
    /// present UI.
    open weak var presentationContext: (any MSAuthenticationPresentationContext)?

    /// Designated initializer. Retains `serviceAccount` by object identity.
    public init(serviceAccount: MSServiceAccount) {
        storedAccount = serviceAccount
        super.init()
    }

    @available(*, unavailable, message: "Use init(serviceAccount:)")
    public override init() {
        storedAccount = MSServiceAccount(serviceName: "", accountName: "")
        super.init()
    }

    /// Always throws. Does not invent a successful media-service setup sheet.
    open func start() throws {
        throw mediaSetupUnavailableError(operation: "MSSetupSession.start")
    }
}
