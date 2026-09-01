@_exported import Foundation

// MARK: - Public constants
//
// String payloads follow Apple's published Accounts identifiers. They are
// recorded here so Linux callers can match existing source, not because this
// module talks to Apple's account daemon.

/// Apple's public Accounts error domain.
public let ACErrorDomain = "com.apple.accounts"

public let ACAccountTypeIdentifierTwitter = "com.apple.twitter"
public let ACAccountTypeIdentifierFacebook = "com.apple.facebook"
public let ACAccountTypeIdentifierSinaWeibo = "com.apple.sinaweibo"
public let ACAccountTypeIdentifierTencentWeibo = "com.apple.tencentweibo"

public let ACFacebookAppIdKey = "ACFacebookAppIdKey"
public let ACFacebookPermissionsKey = "ACFacebookPermissionsKey"
public let ACFacebookAudienceKey = "ACFacebookAudienceKey"
public let ACFacebookAudienceEveryone = "everyone"
public let ACFacebookAudienceFriends = "friends"
public let ACFacebookAudienceOnlyMe = "only_me"
public let ACTencentWeiboAppIdKey = "ACTencentWeiboAppIdKey"

extension NSNotification.Name {
    /// Posted by Apple's account store when the account database changes.
    /// Linux never posts this name: the local store is empty and fail-closed.
    public static let ACAccountStoreDidChange = NSNotification.Name(
        "ACAccountStoreDidChangeNotification"
    )
}

// MARK: - Error codes

/// Bridged `NS_ENUM` overlay for `ACErrorCode`. Raw values follow the public
/// `ACError.h` numbering (`unknown = 1` through `credentialItemNotExpired = 23`).
public struct ACErrorCode: RawRepresentable, Hashable, Equatable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var ACErrorUnknown: ACErrorCode { ACErrorCode(1) }
public var ACErrorAccountMissingRequiredProperty: ACErrorCode { ACErrorCode(2) }
public var ACErrorAccountAuthenticationFailed: ACErrorCode { ACErrorCode(3) }
public var ACErrorAccountTypeInvalid: ACErrorCode { ACErrorCode(4) }
public var ACErrorAccountAlreadyExists: ACErrorCode { ACErrorCode(5) }
public var ACErrorAccountNotFound: ACErrorCode { ACErrorCode(6) }
public var ACErrorPermissionDenied: ACErrorCode { ACErrorCode(7) }
public var ACErrorAccessInfoInvalid: ACErrorCode { ACErrorCode(8) }
public var ACErrorClientPermissionDenied: ACErrorCode { ACErrorCode(9) }
public var ACErrorAccessDeniedByProtectionPolicy: ACErrorCode { ACErrorCode(10) }
public var ACErrorCredentialNotFound: ACErrorCode { ACErrorCode(11) }
public var ACErrorFetchCredentialFailed: ACErrorCode { ACErrorCode(12) }
public var ACErrorStoreCredentialFailed: ACErrorCode { ACErrorCode(13) }
public var ACErrorRemoveCredentialFailed: ACErrorCode { ACErrorCode(14) }
public var ACErrorUpdatingNonexistentAccount: ACErrorCode { ACErrorCode(15) }
public var ACErrorInvalidClientBundleID: ACErrorCode { ACErrorCode(16) }
public var ACErrorDeniedByPlugin: ACErrorCode { ACErrorCode(17) }
public var ACErrorCoreDataSaveFailed: ACErrorCode { ACErrorCode(18) }
public var ACErrorFailedSerializingAccountInfo: ACErrorCode { ACErrorCode(19) }
public var ACErrorInvalidCommand: ACErrorCode { ACErrorCode(20) }
public var ACErrorMissingTransportMessageID: ACErrorCode { ACErrorCode(21) }
public var ACErrorCredentialItemNotFound: ACErrorCode { ACErrorCode(22) }
public var ACErrorCredentialItemNotExpired: ACErrorCode { ACErrorCode(23) }

/// Result of an Apple credential-renewal attempt. Linux never reports `.renewed`.
public enum ACAccountCredentialRenewResult: Int, Sendable, Hashable {
    case renewed = 0
    case rejected = 1
    case failed = 2
}

public typealias ACAccountStoreSaveCompletionHandler = (Bool, (any Error)?) -> Void
public typealias ACAccountStoreRequestAccessCompletionHandler = (Bool, (any Error)?) -> Void
public typealias ACAccountStoreRemoveCompletionHandler = (Bool, (any Error)?) -> Void
public typealias ACAccountStoreCredentialRenewalHandler = (
    ACAccountCredentialRenewResult, (any Error)?
) -> Void

private func _accountsServiceUnavailableError() -> NSError {
    NSError(
        domain: ACErrorDomain,
        code: Int(ACErrorPermissionDenied.rawValue),
        userInfo: nil
    )
}

// MARK: - Account type

/// Linux has no Apple account daemon. `accessGranted` is therefore always
/// `false`. Constructed type objects are local descriptors only.
open class ACAccountType: NSObject {
    private let storedIdentifier: String?
    private let storedDescription: String?

    init(identifier: String) {
        self.storedIdentifier = identifier
        self.storedDescription = identifier
        super.init()
    }

    open var accountTypeDescription: String! { storedDescription }
    open var identifier: String! { storedIdentifier }
    open var accessGranted: Bool { false }
}

// MARK: - Credential

/// Local credential holder. Values are stored in-process only; they are never
/// sent to Apple or written to a system keychain.
open class ACAccountCredential: NSObject {
    open var oauthToken: String!
    private var storedRefreshToken: String?
    private var storedExpiryDate: Date?
    private var storedTokenSecret: String?

    public init!(oAuthToken token: String!, tokenSecret secret: String!) {
        self.oauthToken = token
        self.storedTokenSecret = secret
        super.init()
    }

    public convenience init!(OAuthToken token: String!, tokenSecret secret: String!) {
        self.init(oAuthToken: token, tokenSecret: secret)
    }

    public init!(
        oAuth2Token token: String!,
        refreshToken: String!,
        expiryDate: Date!
    ) {
        self.oauthToken = token
        self.storedRefreshToken = refreshToken
        self.storedExpiryDate = expiryDate
        super.init()
    }

    public convenience init!(
        OAuth2Token token: String!,
        refreshToken: String!,
        expiryDate: Date!
    ) {
        self.init(oAuth2Token: token, refreshToken: refreshToken, expiryDate: expiryDate)
    }
}

// MARK: - Account

/// In-memory account object. Properties can be set locally, but
/// `ACAccountStore` never persists them and `identifier` stays `nil`.
open class ACAccount: NSObject {
    open var accountType: ACAccountType!
    open var accountDescription: String!
    open var username: String!
    open var credential: ACAccountCredential!

    public init!(accountType type: ACAccountType!) {
        self.accountType = type
        super.init()
    }

    open var identifier: NSString! { nil }
    open var userFullName: String! { nil }
}

// MARK: - Account store

/// Fail-closed account store. Queries return empty results. Mutation, access,
/// and credential renewal complete once with `ACErrorPermissionDenied` and
/// never fabricate Apple accounts or tokens.
open class ACAccountStore: NSObject {
    open var accounts: NSArray! { NSArray() }

    open func account(withIdentifier identifier: String!) -> ACAccount! {
        _ = identifier
        return nil
    }

    open func accountType(withAccountTypeIdentifier typeIdentifier: String!) -> ACAccountType! {
        guard let typeIdentifier else { return nil }
        return ACAccountType(identifier: typeIdentifier)
    }

    open func accounts(with accountType: ACAccountType!) -> [Any]! {
        _ = accountType
        return []
    }

    open func saveAccount(
        _ account: ACAccount!,
        withCompletionHandler completionHandler: ACAccountStoreSaveCompletionHandler!
    ) {
        _ = account
        completionHandler?(false, _accountsServiceUnavailableError())
    }

    open func saveAccount(_ account: ACAccount!) async throws -> Bool {
        _ = account
        throw _accountsServiceUnavailableError()
    }

    open func requestAccessToAccounts(
        with accountType: ACAccountType!,
        options: [AnyHashable: Any]! = [:],
        completion: ACAccountStoreRequestAccessCompletionHandler!
    ) {
        _ = (accountType, options)
        completion?(false, _accountsServiceUnavailableError())
    }

    open func requestAccessToAccounts(
        with accountType: ACAccountType!,
        options: [AnyHashable: Any]! = [:]
    ) async throws -> Bool {
        _ = (accountType, options)
        throw _accountsServiceUnavailableError()
    }

    open func renewCredentials(
        for account: ACAccount!,
        completion completionHandler: ACAccountStoreCredentialRenewalHandler!
    ) {
        _ = account
        completionHandler?(.failed, _accountsServiceUnavailableError())
    }

    open func renewCredentials(
        for account: ACAccount!
    ) async throws -> ACAccountCredentialRenewResult {
        _ = account
        throw _accountsServiceUnavailableError()
    }

    open func removeAccount(
        _ account: ACAccount!,
        withCompletionHandler completionHandler: ACAccountStoreRemoveCompletionHandler!
    ) {
        _ = account
        completionHandler?(false, _accountsServiceUnavailableError())
    }

    open func removeAccount(_ account: ACAccount!) async throws -> Bool {
        _ = account
        throw _accountsServiceUnavailableError()
    }
}
