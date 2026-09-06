import Foundation

/// Value-type TV-provider user account (Swift overlay; macios still models
/// the ObjC class). Equality hashes every public stored field. Darwin's
/// exact equality set is unobserved.
public struct VSUserAccount: Hashable, Sendable {
    public enum AccountType: Int, Hashable, Sendable {
        case free = 0
        case paid = 1
    }

    /// Originating device family. Raw values match pinned `dotnet/macios`
    /// `[Native]`: `mobile = 0`, `other = 1`.
    public enum OriginatingDeviceCategory: Int, Hashable, Sendable {
        case mobile = 0
        case other = 1
    }

    public var identifier: String?
    public var accountType: AccountType
    public var isSignedOut: Bool
    public private(set) var deviceCategory: OriginatingDeviceCategory
    public var tierIdentifiers: [String]?
    public var appleSubscription: VSAppleSubscription?
    public var billingIdentifier: String?
    public var authenticationData: String?
    public private(set) var isFromCurrentDevice: Bool
    public var requiresSystemTrust: Bool
    public var accountProviderIdentifier: String?
    public var subscriptionBillingCycleEndDate: Date?
    public var updateURL: URL?

    /// Linux initializer matching the Swift overlay. `accountType` defaults
    /// to `.free`. `deviceCategory` is `.other` (Linux is not an Apple mobile
    /// device) and `isFromCurrentDevice` is `true` for a locally constructed
    /// value; both Darwin defaults are unobserved.
    public init(accountType: AccountType = .free, updateURL: URL?) {
        self.accountType = accountType
        self.updateURL = updateURL
        self.isSignedOut = false
        self.requiresSystemTrust = false
        self.isFromCurrentDevice = true
        self.deviceCategory = .other
    }

    public static func == (a: VSUserAccount, b: VSUserAccount) -> Bool {
        a.identifier == b.identifier
            && a.accountType == b.accountType
            && a.isSignedOut == b.isSignedOut
            && a.deviceCategory == b.deviceCategory
            && a.tierIdentifiers == b.tierIdentifiers
            && a.appleSubscription == b.appleSubscription
            && a.billingIdentifier == b.billingIdentifier
            && a.authenticationData == b.authenticationData
            && a.isFromCurrentDevice == b.isFromCurrentDevice
            && a.requiresSystemTrust == b.requiresSystemTrust
            && a.accountProviderIdentifier == b.accountProviderIdentifier
            && a.subscriptionBillingCycleEndDate == b.subscriptionBillingCycleEndDate
            && a.updateURL == b.updateURL
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(accountType)
        hasher.combine(isSignedOut)
        hasher.combine(deviceCategory)
        hasher.combine(tierIdentifiers)
        hasher.combine(appleSubscription)
        hasher.combine(billingIdentifier)
        hasher.combine(authenticationData)
        hasher.combine(isFromCurrentDevice)
        hasher.combine(requiresSystemTrust)
        hasher.combine(accountProviderIdentifier)
        hasher.combine(subscriptionBillingCycleEndDate)
        hasher.combine(updateURL)
    }
}

/// Apple subscription identifiers attached to a `VSUserAccount`.
public struct VSAppleSubscription: Hashable, Sendable {
    public var customerID: String
    public var productCodes: [String]

    public init(customerID: String, productCodes: [String]) {
        self.customerID = customerID
        self.productCodes = productCodes
    }

    public static func == (a: VSAppleSubscription, b: VSAppleSubscription) -> Bool {
        a.customerID == b.customerID && a.productCodes == b.productCodes
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(customerID)
        hasher.combine(productCodes)
    }
}

/// Shared manager for `VSUserAccount` records. Linux has no account-sync
/// daemon: every mutating/query API throws `VSError.unsupported`.
open class VSUserAccountManager: NSObject {
    private static let sharedInstance = VSUserAccountManager()

    private override init() {
        super.init()
    }

    open class var shared: VSUserAccountManager { sharedInstance }

    /// Query options. `allDevices` is `1 << 0` (macios `Flags` `AllDevices`
    /// after `None = 0x0`).
    public struct QueryOptions: OptionSet, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let allDevices = QueryOptions(rawValue: 1)
    }

    /// Auto sign-in authorization. Raw values match pinned `dotnet/macios`
    /// `[Native]`: `notDetermined = 0`, `granted = 1`, `denied = 2`. The
    /// Swift overlay does not publish `RawRepresentable` in the census; the
    /// integers remain so tests can lock them.
    public enum AutoSignInAuthorization: Int, Hashable, Sendable {
        case notDetermined = 0
        case granted = 1
        case denied = 2

        public static func == (
            a: VSUserAccountManager.AutoSignInAuthorization,
            b: VSUserAccountManager.AutoSignInAuthorization
        ) -> Bool {
            a.rawValue == b.rawValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }
    }

    /// Auto sign-in token produced by Apple's daemon. Darwin has no public
    /// initializer; Linux supplies one so the value type can be tested.
    public struct AutoSignInToken: Hashable, Sendable {
        public let authorization: VSUserAccountManager.AutoSignInAuthorization
        public let value: String?

        public init(
            authorization: VSUserAccountManager.AutoSignInAuthorization,
            value: String? = nil
        ) {
            self.authorization = authorization
            self.value = value
        }
    }

    /// Context returned when requesting auto sign-in authorization.
    public struct AutoSignInTokenUpdateContext: Hashable, Sendable {
        public let authorization: VSUserAccountManager.AutoSignInAuthorization

        public init(authorization: VSUserAccountManager.AutoSignInAuthorization) {
            self.authorization = authorization
        }
    }

    open func userAccounts(
        options: VSUserAccountManager.QueryOptions = []
    ) async throws -> [VSUserAccount] {
        _ = options
        throw VideoSubscriberAccountLinux.unsupportedError()
    }

    open var autoSignInToken: VSUserAccountManager.AutoSignInToken {
        get async throws {
            throw VideoSubscriberAccountLinux.unsupportedError()
        }
    }

    open func deleteAutoSignInToken() async throws {
        throw VideoSubscriberAccountLinux.unsupportedError()
    }

    open func updateAutoSignInToken(
        _ newToken: String,
        updateContext: VSUserAccountManager.AutoSignInTokenUpdateContext
    ) async throws {
        _ = newToken
        _ = updateContext
        throw VideoSubscriberAccountLinux.unsupportedError()
    }

    open func requestAutoSignInAuthorization() async throws
        -> VSUserAccountManager.AutoSignInTokenUpdateContext
    {
        throw VideoSubscriberAccountLinux.unsupportedError()
    }

    open func update(_ account: VSUserAccount) async throws {
        _ = account
        throw VideoSubscriberAccountLinux.unsupportedError()
    }
}
