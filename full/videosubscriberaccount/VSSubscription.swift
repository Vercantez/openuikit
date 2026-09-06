import Foundation

/// Deprecated in-process subscription record (use `VSUserAccount`).
/// `expirationDate` and `tierIdentifiers` are Darwin IUOs; Linux defaults
/// `expirationDate` to nil and `tierIdentifiers` to `[]`. The null-resettable
/// Darwin defaults are unobserved.
open class VSSubscription: NSObject {
    public var accessLevel: VSSubscriptionAccessLevel = .unknown
    public var billingIdentifier: String?
    public var expirationDate: Date!
    public var tierIdentifiers: [String]! = []
}

/// Process-local registration point. Darwin talks to a system daemon;
/// Linux only retains the last value in this process and never claims
/// Apple TV-provider registration.
open class VSSubscriptionRegistrationCenter: NSObject {
    private static let sharedInstance = VSSubscriptionRegistrationCenter()
    private var currentSubscription: VSSubscription?

    private override init() {
        super.init()
    }

    open class func `default`() -> VSSubscriptionRegistrationCenter {
        sharedInstance
    }

    open func setCurrentSubscription(_ currentSubscription: VSSubscription?) {
        self.currentSubscription = currentSubscription
    }

    /// Process-local last subscription. Not an Apple API; tests use it to
    /// observe `setCurrentSubscription` without inventing a daemon.
    public var linuxCurrentSubscription: VSSubscription? { currentSubscription }
}
