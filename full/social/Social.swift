import Foundation

/// Linux starting point for Apple's public `Social` module.
///
/// Share-extension compose state, configuration items, and unsigned
/// `URLRequest` assembly (when no account is attached) are real. Apple
/// account posting, OAuth signing, extension-host completion, and system
/// compose UI are fail-closed or partial host hooks.
///
/// Production Social imports the canonical `UIKit` module and `Accounts`.
/// `-D SOCIAL_STANDALONE_TEST_FIXTURES` emits standalone-unit-fixture-only
/// types: UIKit fallbacks only when UIKit is absent, and fixture `ACAccount`
/// even if `canImport(Accounts)` is true, so Apple hosts do not import the
/// deprecated system Accounts module. Ordinary production compilation
/// without those modules is a dependency blocker and must not publish
/// Social-owned UIKit or Accounts identities.

#if SOCIAL_STANDALONE_TEST_FIXTURES
/// Present only in the isolated fixture compile. Not production Social ABI.
public enum SocialStandaloneUnitFixture {
    public static let marker = "standalone-unit-fixture-only"
}
#endif

/// Identifies Facebook as an `SLRequest` / compose service type.
///
/// Declared pending an Apple-runtime dump of the exact constant string.
public let SLServiceTypeFacebook = "com.apple.social.facebook"

/// Identifies LinkedIn as an `SLRequest` / compose service type.
///
/// Declared pending an Apple-runtime dump of the exact constant string.
public let SLServiceTypeLinkedIn = "com.apple.social.linkedin"

/// Identifies Sina Weibo as an `SLRequest` / compose service type.
///
/// Declared pending an Apple-runtime dump of the exact constant string.
public let SLServiceTypeSinaWeibo = "com.apple.social.sinaweibo"

/// Identifies Tencent Weibo as an `SLRequest` / compose service type.
///
/// Declared pending an Apple-runtime dump of the exact constant string.
public let SLServiceTypeTencentWeibo = "com.apple.social.tencentweibo"

/// Identifies Twitter as an `SLRequest` / compose service type.
///
/// Declared pending an Apple-runtime dump of the exact constant string.
public let SLServiceTypeTwitter = "com.apple.social.twitter"

/// HTTP verb used by `SLRequest`. Raw values follow historical `NS_ENUM`
/// declaration order (`GET`, `POST`, `DELETE`, `PUT`).
public enum SLRequestMethod: Int, Sendable, Equatable, Hashable {
    case GET = 0
    case POST = 1
    case DELETE = 2
    case PUT = 3
}

/// Result delivered to `SLComposeViewController.completionHandler`.
///
/// Linux never reports `.done` as a successful Apple-network post.
public enum SLComposeViewControllerResult: Int, Sendable, Equatable, Hashable {
    case cancelled = 0
    case done = 1
}

/// Completion callback for the in-app compose sheet.
public typealias SLComposeViewControllerCompletionHandler =
    (SLComposeViewControllerResult) -> Void

/// Tap action for a share-extension configuration row.
public typealias SLComposeSheetConfigurationItemTapHandler = () -> Void

/// Host-only fail-closed error for Social account and request services.
///
/// This is not Apple's `_SLErrorDomain` payload.
@_spi(OpenUIKitHost)
public struct SocialServiceError: Error, Equatable, Hashable, Sendable {
    public enum Code: Int, Sendable, Equatable, Hashable {
        case accountServiceUnavailable = 1
    }

    public let code: Code

    public init(code: Code) {
        self.code = code
    }

    public static let accountServiceUnavailable = SocialServiceError(
        code: .accountServiceUnavailable
    )
}

/// Host-only service-type helpers. Not Apple surface.
@_spi(OpenUIKitHost)
public enum SocialServiceType {
    public static let all: [String] = [
        SLServiceTypeTwitter,
        SLServiceTypeFacebook,
        SLServiceTypeSinaWeibo,
        SLServiceTypeTencentWeibo,
        SLServiceTypeLinkedIn,
    ]

    public static func isKnown(_ serviceType: String?) -> Bool {
        guard let serviceType else { return false }
        return all.contains(serviceType)
    }
}

/// Partial host completion for share-extension cancel/post. Not an
/// Apple-equivalent `NSExtensionContext` completion.
@_spi(OpenUIKitHost)
public enum SocialHostExtensionCompletion: Equatable, Sendable {
    case none
    case cancelledWithoutExtensionContext
    case postedWithoutExtensionContext
}
