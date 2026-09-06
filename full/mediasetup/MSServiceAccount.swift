import Foundation

/// An OAuth-style media service account used to start a Media Setup session.
///
/// Apple graph: `open class MSServiceAccount` inheriting `NSObject`, iOS 14.
/// Designated `init(serviceName:accountName:)` stores the two readonly
/// strings. Optional client/token fields default to `nil` (ObjC nil); Darwin
/// defaults are unobserved. URL properties are Swift `URL` values (macios
/// annotates them `Copy`). Linux never contacts Apple's media-service
/// configuration backend.
open class MSServiceAccount: NSObject {
    private let storedServiceName: String
    private let storedAccountName: String

    /// Service display name supplied to the designated initializer.
    open var serviceName: String { storedServiceName }

    /// Account name supplied to the designated initializer.
    open var accountName: String { storedAccountName }

    /// OAuth client identifier. `nil` until set.
    open var clientID: String?

    /// OAuth client secret. `nil` until set.
    open var clientSecret: String?

    /// Service configuration endpoint. `nil` until set.
    open var configurationURL: URL?

    /// Token endpoint. `nil` until set.
    open var authorizationTokenURL: URL?

    /// OAuth scope string. `nil` until set.
    open var authorizationScope: String?

    /// Designated initializer. Both names are stored as given, including empty
    /// strings. Optional fields start as `nil`.
    public init(serviceName: String, accountName: String) {
        storedServiceName = serviceName
        storedAccountName = accountName
        super.init()
    }

    @available(*, unavailable, message: "Use init(serviceName:accountName:)")
    public override init() {
        storedServiceName = ""
        storedAccountName = ""
        super.init()
    }
}
