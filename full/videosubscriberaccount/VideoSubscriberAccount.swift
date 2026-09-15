@_exported import Foundation

/// Portable Linux starting point for Apple's public `VideoSubscriberAccount`
/// module, reconstructed from the Xcode 26.1 iPhoneOS symbol graph.
///
/// Isolated host compilation imports Foundation only. Enum raw values, string
/// newtypes, in-process request/account storage, and OptionSet algebra are
/// real. There is no TV-provider daemon, Apple entitlement, SAML/API identity
/// service, or UIKit presentation host: those paths throw or complete with
/// `VSError.unsupported` and never fabricate a signed-in provider.

/// Apple `NS_ERROR_ENUM` domain. The string matches pinned `dotnet/macios`
/// `[ErrorDomain ("VSErrorDomain")]` and TBD export `_VSErrorDomain`.
public let VSErrorDomain = "VSErrorDomain"

/// User-info key for a SAML response payload. The string equals the ObjC
/// field name (TBD `_VSErrorInfoKeySAMLResponse`); Darwin's archive layout is
/// unobserved.
public let VSErrorInfoKeySAMLResponse = "VSErrorInfoKeySAMLResponse"

/// User-info key for a SAML response status string.
public let VSErrorInfoKeySAMLResponseStatus = "VSErrorInfoKeySAMLResponseStatus"

/// User-info key naming an unsupported provider identifier.
public let VSErrorInfoKeyUnsupportedProviderIdentifier =
    "VSErrorInfoKeyUnsupportedProviderIdentifier"

/// User-info key for an account-provider response object.
public let VSErrorInfoKeyAccountProviderResponse =
    "VSErrorInfoKeyAccountProviderResponse"

/// URL string used on Darwin to open TV Provider settings. The ObjC export
/// name is recorded here until an Apple-oracle probe captures the live
/// payload; see `oracle-questions.tsv`.
public let VSOpenTVProviderSettingsURLString = "VSOpenTVProviderSettingsURLString"

enum VideoSubscriberAccountLinux {
    static func unsupportedError(userInfo: [String: Any] = [:]) -> VSError {
        var info = userInfo
        if info[NSLocalizedDescriptionKey] == nil {
            info[NSLocalizedDescriptionKey] =
                "Linux has no Video Subscriber Account daemon, TV provider, or Apple entitlement (\(VSError.Code.unsupported))."
        }
        return VSError(.unsupported, userInfo: info)
    }
}

/// Linux host-test control. Hidden from ordinary `import VideoSubscriberAccount`
/// clients and not part of Apple's public VideoSubscriberAccount surface.
@_spi(OpenUIKitHost)
public enum VideoSubscriberAccountHostControl {
    /// Same fail-closed error the public query/update/auto-sign-in APIs surface.
    public static var linuxUnsupportedError: VSError {
        VSError(.unsupported)
    }

    /// Synchronous twin of `VSUserAccountManager.userAccounts(options:)`.
    /// The async method never suspends; it always throws this error.
    public static func userAccountsSync(
        _ manager: VSUserAccountManager,
        options: VSUserAccountManager.QueryOptions = []
    ) throws -> [VSUserAccount] {
        try manager.linuxUserAccounts(options: options)
    }

    /// Synchronous twin of `VSUserAccountManager.autoSignInToken`.
    /// The async getter never suspends; it always throws this error and
    /// never invents a token.
    public static func autoSignInTokenSync(
        _ manager: VSUserAccountManager
    ) throws -> VSUserAccountManager.AutoSignInToken {
        try manager.linuxAutoSignInToken()
    }

    /// Synchronous twin of `VSUserAccountManager.deleteAutoSignInToken()`.
    public static func deleteAutoSignInTokenSync(
        _ manager: VSUserAccountManager
    ) throws {
        try manager.linuxDeleteAutoSignInToken()
    }

    /// Synchronous twin of
    /// `VSUserAccountManager.updateAutoSignInToken(_:updateContext:)`.
    public static func updateAutoSignInTokenSync(
        _ manager: VSUserAccountManager,
        _ newToken: String,
        updateContext: VSUserAccountManager.AutoSignInTokenUpdateContext
    ) throws {
        try manager.linuxUpdateAutoSignInToken(newToken, updateContext: updateContext)
    }

    /// Synchronous twin of
    /// `VSUserAccountManager.requestAutoSignInAuthorization()`.
    public static func requestAutoSignInAuthorizationSync(
        _ manager: VSUserAccountManager
    ) throws -> VSUserAccountManager.AutoSignInTokenUpdateContext {
        try manager.linuxRequestAutoSignInAuthorization()
    }

    /// Synchronous twin of `VSUserAccountManager.update(_:)`.
    public static func updateSync(
        _ manager: VSUserAccountManager,
        _ account: VSUserAccount
    ) throws {
        try manager.linuxUpdate(account)
    }
}

/// Access the app has been granted to the user's TV-provider account.
///
/// Raw values match pinned `dotnet/macios` `[Native]`:
/// `notDetermined = 0`, `restricted = 1`, `denied = 2`, `granted = 3`.
public enum VSAccountAccessStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case granted = 3
}

/// Deprecated subscription access level (use `VSUserAccount.AccountType`).
///
/// Raw values match pinned `dotnet/macios` `[Native]` order:
/// `unknown = 0`, `freeWithAccount = 1`, `paid = 2`.
public enum VSSubscriptionAccessLevel: Int, Hashable, Sendable {
    case unknown = 0
    case freeWithAccount = 1
    case paid = 2
}

/// NS_STRING_ENUM for account-provider authentication schemes.
///
/// Raw strings equal the ObjC field names until an Apple-oracle probe
/// records Darwin's live payload.
public struct VSAccountProviderAuthenticationScheme: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let saml = VSAccountProviderAuthenticationScheme(
        rawValue: "VSAccountProviderAuthenticationSchemeSAML"
    )

    public static let api = VSAccountProviderAuthenticationScheme(
        rawValue: "VSAccountProviderAuthenticationSchemeAPI"
    )
}

/// NS_STRING_ENUM key for `VSAccountManager.checkAccessStatus` options.
public struct VSCheckAccessOption: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let prompt = VSCheckAccessOption(rawValue: "VSCheckAccessOptionPrompt")
}
