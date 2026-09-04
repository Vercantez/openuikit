@_exported import Foundation

/// Apple's public WebKit error domain. Observed from WebKit's `WKError.h`
/// (`WKErrorDomain`).
public let WKErrorDomain = "WKErrorDomain"

/// Typed WebKit failure. Codes and domain match the Xcode 26.1 / WebKit
/// `WKErrorCode` overlay (`WKErrorUnknown = 1` through
/// `WKErrorCredentialNotFound = 17`). Linux has no renderer, network fetch, or
/// Web Content process; every OS/network/engine boundary fails closed with one
/// of these codes instead of inventing a successful load.
public struct WKError: Error, Equatable, Hashable, Sendable, CustomStringConvertible {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 1
        case webContentProcessTerminated = 2
        case webViewInvalidated = 3
        case javaScriptExceptionOccurred = 4
        case javaScriptResultTypeIsUnsupported = 5
        case contentRuleListStoreCompileFailed = 6
        case contentRuleListStoreLookUpFailed = 7
        case contentRuleListStoreRemoveFailed = 8
        case contentRuleListStoreVersionMismatch = 9
        case attributedStringContentFailedToLoad = 10
        case attributedStringContentLoadTimedOut = 11
        case javaScriptInvalidFrameTarget = 12
        case navigationAppBoundDomain = 13
        case javaScriptAppBoundDomain = 14
        case duplicateCredential = 15
        case malformedCredential = 16
        case credentialNotFound = 17
    }

    public let code: Code
    public let userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo.mapValues { String(describing: $0) }
    }

    public init(code: Code, operation: String, requestedURL: URL? = nil) {
        var info: [String: Any] = ["WKPortableOperation": operation]
        if let requestedURL {
            info["NSErrorFailingURLStringKey"] = requestedURL.absoluteString
        }
        self.init(code, userInfo: info)
    }

    public var description: String {
        let operation = userInfo["WKPortableOperation"].map { " operation=\($0)" } ?? ""
        let url = userInfo["NSErrorFailingURLStringKey"].map { " url=\($0)" } ?? ""
        return "\(WKErrorDomain) \(code.rawValue)\(operation)\(url)"
    }

    public static let unknown = Code.unknown
    public static let webContentProcessTerminated = Code.webContentProcessTerminated
    public static let webViewInvalidated = Code.webViewInvalidated
    public static let javaScriptExceptionOccurred = Code.javaScriptExceptionOccurred
    public static let javaScriptResultTypeIsUnsupported =
        Code.javaScriptResultTypeIsUnsupported
    public static let contentRuleListStoreCompileFailed =
        Code.contentRuleListStoreCompileFailed
    public static let contentRuleListStoreLookUpFailed =
        Code.contentRuleListStoreLookUpFailed
    public static let contentRuleListStoreRemoveFailed =
        Code.contentRuleListStoreRemoveFailed
    public static let contentRuleListStoreVersionMismatch =
        Code.contentRuleListStoreVersionMismatch
    public static let attributedStringContentFailedToLoad =
        Code.attributedStringContentFailedToLoad
    public static let attributedStringContentLoadTimedOut =
        Code.attributedStringContentLoadTimedOut
    public static let javaScriptInvalidFrameTarget = Code.javaScriptInvalidFrameTarget
    public static let navigationAppBoundDomain = Code.navigationAppBoundDomain
    public static let javaScriptAppBoundDomain = Code.javaScriptAppBoundDomain
    public static let duplicateCredential = Code.duplicateCredential
    public static let malformedCredential = Code.malformedCredential
    public static let credentialNotFound = Code.credentialNotFound

    public var localizedDescription: String { description }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(WKErrorDomain)
        hasher.combine(code)
    }
}

extension WKError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? WKError)?.code == match
    }
}

extension WKError: CustomNSError {
    public static var errorDomain: String { WKErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] {
        Dictionary(uniqueKeysWithValues: userInfo.map { ($0, $1 as Any) })
    }
}

/// In-memory back-forward snapshot used by host tests. Not an Apple type.
@_spi(WebKitHost)
public struct WKBackForwardListState: Equatable, Sendable {
    public let currentURL: URL?
    public let backURLs: [URL]
    public let forwardURLs: [URL]
}

/// Host-only control seams. Ordinary `import WebKit` clients cannot see this
/// API; it is not part of Apple's public WebKit surface.
@_spi(WebKitHost)
public enum WebKitHostControl {
    /// Records a committed history entry in process memory. This does not
    /// fetch, render, or claim that `load` succeeded; it only exercises the
    /// real in-memory list used by `canGoBack` / `go(to:)`.
    @MainActor
    public static func recordCommittedItem(
        on webView: WKWebView,
        url: URL,
        title: String? = nil
    ) {
        webView._portableRecordCommittedItem(url: url, title: title)
    }

    @MainActor
    public static func backForwardState(
        of webView: WKWebView
    ) -> WKBackForwardListState {
        webView.backForwardList._portableState()
    }

    @MainActor
    public static func lastError(on webView: WKWebView) -> WKError? {
        webView._portableLastError
    }
}

/// Host-test observer for string-keypath KVO. Ordinary imports do not need
/// this type; Focus compiles against `addObserver(_:forKeyPath:options:context:)`.
@_spi(WebKitHost)
@MainActor
public protocol WebKitHostKeyValueObserver: AnyObject {
    func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [String: Any]?,
        context: UnsafeMutableRawPointer?
    )
}
