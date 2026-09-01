import Foundation
import FoundationNetworking

/// Linux starting point for Apple's public `Social` module.
///
/// Share-extension compose state, configuration items, and unsigned
/// `URLRequest` assembly are real. Apple account services, OAuth signing,
/// and system compose UI are fail-closed: availability is `false` and
/// `SLRequest.perform(handler:)` never contacts a social network.
///
/// UIKit is a declared dependency. This leaf compile does not receive the
/// shared UIKit module, so `SocialHostTypes.swift` supplies local
/// `UIViewController` / `UIImage` / `UITextView` stand-ins until central
/// review links OpenUIKit.

/// Identifies Facebook as an `SLRequest` / compose service type.
///
/// Long-standing public constant value; confirm on an Apple runtime before
/// treating byte-for-byte equality with a hardcoded string as ABI.
public let SLServiceTypeFacebook = "com.apple.social.facebook"

/// Identifies LinkedIn as an `SLRequest` / compose service type.
public let SLServiceTypeLinkedIn = "com.apple.social.linkedin"

/// Identifies Sina Weibo as an `SLRequest` / compose service type.
public let SLServiceTypeSinaWeibo = "com.apple.social.sinaweibo"

/// Identifies Tencent Weibo as an `SLRequest` / compose service type.
public let SLServiceTypeTencentWeibo = "com.apple.social.tencentweibo"

/// Identifies Twitter as an `SLRequest` / compose service type.
public let SLServiceTypeTwitter = "com.apple.social.twitter"

/// HTTP verb used by `SLRequest`. Raw values follow the historical
/// `NS_ENUM` order in `SLRequest.h` (`GET`, `POST`, `DELETE`, `PUT`).
public enum SLRequestMethod: Int, Sendable, Equatable, Hashable {
    case GET = 0
    case POST = 1
    case DELETE = 2
    case PUT = 3
}

/// Result delivered to `SLComposeViewController.completionHandler`.
///
/// Linux never reports `.done` as a successful Apple-network post. Hosts
/// may invoke the handler with `.cancelled` after local draft dismissal.
public enum SLComposeViewControllerResult: Int, Sendable, Equatable, Hashable {
    case cancelled = 0
    case done = 1
}

/// Completion callback for the in-app compose sheet.
public typealias SLComposeViewControllerCompletionHandler =
    (SLComposeViewControllerResult) -> Void

/// Tap action for a share-extension configuration row.
public typealias SLComposeSheetConfigurationItemTapHandler = () -> Void

/// Completion callback for `SLRequest.perform(handler:)`.
///
/// On Linux the handler is invoked synchronously with `nil` data, `nil`
/// response, and `SocialServiceError.accountServiceUnavailable`.
public typealias SLRequestHandler = (Data?, HTTPURLResponse?, (any Error)?) -> Void

/// Portable fail-closed error for Social account and request services.
///
/// This is not Apple's `_SLErrorDomain` payload; that string is not in the
/// public Swift surface and is queued for an Apple-oracle probe.
public struct SocialServiceError: Error, Equatable, Hashable, Sendable {
    public enum Code: Int, Sendable, Equatable, Hashable {
        case accountServiceUnavailable = 1
        case missingRequestHandler = 2
        case missingURL = 3
    }

    public let code: Code

    public init(code: Code) {
        self.code = code
    }

    public static let accountServiceUnavailable = SocialServiceError(
        code: .accountServiceUnavailable
    )
}

/// Service-type strings known to this starting point.
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
