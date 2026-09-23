// Fail-closed ASWebAuthenticationSession for NetNewsWire
// Account/Feedly/OAuthAccountAuthorizationOperation.swift (the Feedly /
// Inoreader OAuth sign-in). The curated iOS SDK drops Apple's
// AuthenticationServices because it imports UIKit (ASPresentationAnchor is a
// UIWindow), so route (b) on the iOS target needs this module.
//
// MEASURED iPhone 16 / iOS 26.1 (Tools/oracle2/webauthsessionprobe,
// transcript-ios26.1.txt): error domain
// com.apple.AuthenticationServices.WebAuthenticationSession, codes
// canceledLogin 1 / presentationContextNotProvided 2 /
// presentationContextInvalid 3; ASPresentationAnchor == UIWindow;
// prefersEphemeralWebBrowserSession false; a session that cannot present
// reports canStart false, and start() calls the completion SYNCHRONOUSLY
// (code 2 without a provider, 3 when it cannot present into the anchor)
// and returns false; a second start() returns false with no callback;
// cancel() delivers nothing.
//
// The port has no web-authentication sheet, so every session is one that
// cannot present: no sign-in ever succeeds and no URL is ever returned.
// The full clean-room port under full/authenticationservices is Linux-only
// and has no UIKit anchor; it is not used here.

import Foundation
@_exported import UIKit

public typealias ASPresentationAnchor = UIWindow

public let ASWebAuthenticationSessionErrorDomain = "com.apple.AuthenticationServices.WebAuthenticationSession"

public struct ASWebAuthenticationSessionError: Error, CustomNSError, Hashable, Sendable {
    public enum Code: Int, Sendable {
        case canceledLogin = 1
        case presentationContextNotProvided = 2
        case presentationContextInvalid = 3
    }

    public let code: Code
    public init(_ code: Code) { self.code = code }

    public static var errorDomain: String { ASWebAuthenticationSessionErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { [:] }

    public static var canceledLogin: Code { .canceledLogin }
    public static var presentationContextNotProvided: Code { .presentationContextNotProvided }
    public static var presentationContextInvalid: Code { .presentationContextInvalid }
}

public protocol ASWebAuthenticationPresentationContextProviding: NSObjectProtocol {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor
}

open class ASWebAuthenticationSession: NSObject {
    public typealias CompletionHandler = (URL?, (any Error)?) -> Void

    private let completionHandler: CompletionHandler
    private var attempted = false

    public weak var presentationContextProvider: (any ASWebAuthenticationPresentationContextProviding)?
    public var prefersEphemeralWebBrowserSession = false
    public var additionalHeaderFields: [String: String]?

    public init(url URL: URL, callbackURLScheme: String?, completionHandler: @escaping CompletionHandler) {
        _ = (URL, callbackURLScheme)
        self.completionHandler = completionHandler
        super.init()
    }

    /// Measured false for a session that cannot present; the port never can.
    public var canStart: Bool { false }

    public func start() -> Bool {
        guard !attempted else { return false }
        attempted = true
        let code: ASWebAuthenticationSessionError.Code =
            presentationContextProvider == nil ? .presentationContextNotProvided : .presentationContextInvalid
        completionHandler(nil, ASWebAuthenticationSessionError(code))
        return false
    }

    public func cancel() {}
}
