@_exported import Foundation
import Dispatch

/// Darwin's `ASPresentationAnchor` is `UIWindow` on iOS and `NSWindow` on
/// macOS (`typealias ASPresentationAnchor = UIWindow` in the iPhoneOS 26.1
/// graph). Isolated Linux has no UIKit. The overlay is `NSObject` so
/// presentation-context protocols compile; supplying an anchor never presents
/// a sheet. See Apple's
/// `ASWebAuthenticationPresentationContextProviding.presentationAnchor(for:)`.
public typealias ASPresentationAnchor = NSObject

/// The public error domain used by web-authentication sessions.
/// Matches the pinned `dotnet/macios` `[ErrorDomain ("ASWebAuthenticationSessionErrorDomain")]`.
public let ASWebAuthenticationSessionErrorDomain =
    "com.apple.AuthenticationServices.WebAuthenticationSession"

/// Bridged web-authentication session error.
///
/// `Code` raw values are the pinned macios / existing IceCubes host-oracle
/// values: `canceledLogin = 1`, `presentationContextNotProvided = 2`,
/// `presentationContextInvalid = 3`. Linux Foundation's
/// `_BridgedStoredNSError` hash witnesses trap, so `hash(into:)` is provided
/// here. The portable `reason` convenience stores
/// `NSLocalizedDescriptionKey`; it is extra Linux API, not an Apple selector.
@frozen
public struct ASWebAuthenticationSessionError:
    Foundation._BridgedStoredNSError,
    CustomStringConvertible,
    @unchecked Sendable
{
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = ASWebAuthenticationSessionError

        case canceledLogin = 1
        case presentationContextNotProvided = 2
        case presentationContextInvalid = 3
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { ASWebAuthenticationSessionErrorDomain }

    public static var errorDomain: String { ASWebAuthenticationSessionErrorDomain }
    public static var canceledLogin: Code { .canceledLogin }
    public static var presentationContextNotProvided: Code { .presentationContextNotProvided }
    public static var presentationContextInvalid: Code { .presentationContextInvalid }

    public var reason: String {
        if let description = userInfo[NSLocalizedDescriptionKey] as? String,
           !description.isEmpty
        {
            return description
        }
        return Self.defaultReason(for: code)
    }

    public var description: String { reason }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    /// Portable labeled reason used by the host-driven web-auth boundary.
    public init(_ code: Code, reason: String) {
        var info: [String: Any] = [:]
        if !reason.isEmpty {
            info[NSLocalizedDescriptionKey] = reason
        }
        self.init(code, userInfo: info)
    }

    fileprivate static func defaultReason(for code: Code) -> String {
        switch code {
        case .canceledLogin:
            return "The web authentication session was canceled"
        case .presentationContextNotProvided:
            return "No web authentication host was configured at startup"
        case .presentationContextInvalid:
            return "The web authentication request or callback was invalid"
        }
    }
}

/// Startup-configured boundary between AuthenticationServices and the host's
/// real browser/callback integration.
///
/// The framework never claims authentication success on its own. A host must
/// install one handler before the first request, open the supplied HTTPS URL,
/// and return the callback through `_hostDidComplete`. Missing integration,
/// malformed requests, mismatched callback schemes, concurrent sessions and
/// cancellation all fail closed with typed errors.
///
/// State is lock-protected rather than `@MainActor`-isolated so Linux host
/// tests can wait on the main thread without deadlocking Swift concurrency.
public enum AuthenticationServicesPortable: Sendable {
    public struct Request: Equatable, Sendable {
        public let id: UInt64
        public let url: URL
        public let callbackURLScheme: String
        public let prefersEphemeralBrowserSession: Bool

        fileprivate init(
            id: UInt64,
            url: URL,
            callbackURLScheme: String,
            prefersEphemeralBrowserSession: Bool
        ) {
            self.id = id
            self.url = url
            self.callbackURLScheme = callbackURLScheme
            self.prefersEphemeralBrowserSession =
                prefersEphemeralBrowserSession
        }
    }

    public enum Event: Equatable, Sendable {
        case start(Request)
        case cancel(id: UInt64)
    }

    public typealias EventHandler = @Sendable (Event) -> Void

    private struct ActiveRequest {
        let request: Request
        let cancellation: CancellationState
        let continuation: CheckedContinuation<URL, Error>
    }

    /// Cancellation handlers are permitted to run away from the installing
    /// thread. Keep the terminal bit in a tiny locked box so cancellation is
    /// claimed synchronously, before a queued cleanup can race a callback.
    private final class CancellationState: @unchecked Sendable {
        private let lock = NSLock()
        private var cancelled = false

        var isCancelled: Bool {
            lock.withLock { cancelled }
        }

        func cancel() {
            lock.withLock { cancelled = true }
        }
    }

    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var eventHandler: EventHandler?
        var activeRequest: ActiveRequest?
        var nextRequestID: UInt64 = 0
        var startupConfigurationLocked = false
    }

    private static let state = State()

    public static var isHostConfigured: Bool {
        state.lock.withLock { state.eventHandler != nil }
    }

    public static var hasActiveRequest: Bool {
        state.lock.withLock { state.activeRequest != nil }
    }

    /// Cancel the live portable request, if any, without clearing the host handler.
    @_spi(OpenUIKitHost)
    public static func _cancelActiveIfAny() {
        let id = state.lock.withLock { state.activeRequest?.request.id }
        guard let id else { return }
        cancel(requestID: id)
    }

    /// Install the browser boundary before the first authentication request.
    /// Returning false means startup configuration is already frozen.
    @_spi(OpenUIKitHost)
    @discardableResult
    public static func _installEventHandler(
        _ handler: EventHandler?
    ) -> Bool {
        state.lock.lock()
        defer { state.lock.unlock() }
        guard !state.startupConfigurationLocked, state.activeRequest == nil else {
            return false
        }
        state.eventHandler = handler
        return true
    }

    @_spi(OpenUIKitHost)
    public static func _hostDidComplete(
        requestID: UInt64,
        callbackURL: URL
    ) {
        state.lock.lock()
        guard let active = state.activeRequest,
              active.request.id == requestID else {
            state.lock.unlock()
            return
        }
        state.lock.unlock()
        guard !active.cancellation.isCancelled else {
            cancel(requestID: requestID)
            return
        }
        guard callbackURL.scheme?.lowercased()
                == active.request.callbackURLScheme.lowercased() else {
            finish(
                active,
                with: .failure(ASWebAuthenticationSessionError(
                    .presentationContextInvalid,
                    reason: "The callback URL scheme did not match the request"
                ))
            )
            return
        }
        finish(active, with: .success(callbackURL))
    }

    @_spi(OpenUIKitHost)
    public static func _hostDidCancel(requestID: UInt64) {
        state.lock.lock()
        guard let active = state.activeRequest,
              active.request.id == requestID else {
            state.lock.unlock()
            return
        }
        state.lock.unlock()
        finish(
            active,
            with: .failure(ASWebAuthenticationSessionError(.canceledLogin))
        )
    }

    /// Test/host teardown seam. Any live waiter is resumed as canceled.
    @_spi(OpenUIKitHost)
    public static func _reset() {
        state.lock.lock()
        let active = state.activeRequest
        state.activeRequest = nil
        state.eventHandler = nil
        state.nextRequestID = 0
        state.startupConfigurationLocked = false
        state.lock.unlock()
        active?.continuation.resume(
            throwing: ASWebAuthenticationSessionError(.canceledLogin)
        )
    }

    private static func lockStartupAndSnapshot() -> (EventHandler?, Bool) {
        state.lock.lock()
        defer { state.lock.unlock() }
        state.startupConfigurationLocked = true
        return (state.eventHandler, state.activeRequest != nil)
    }

    private static func nextRequest(
        url: URL,
        callbackURLScheme: String,
        prefersEphemeralBrowserSession: Bool
    ) -> Request {
        state.lock.lock()
        defer { state.lock.unlock() }
        state.nextRequestID &+= 1
        return Request(
            id: state.nextRequestID,
            url: url,
            callbackURLScheme: callbackURLScheme,
            prefersEphemeralBrowserSession: prefersEphemeralBrowserSession
        )
    }

    private static func storeActive(_ active: ActiveRequest) {
        state.lock.lock()
        state.activeRequest = active
        state.lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public static func _authenticate(
        using url: URL,
        callbackURLScheme: String,
        prefersEphemeralBrowserSession: Bool
    ) async throws -> URL {
        guard isValidInitialURL(url),
              isValidCallbackScheme(callbackURLScheme) else {
            throw ASWebAuthenticationSessionError(
                .presentationContextInvalid,
                reason: "Web authentication requires HTTP(S) and a valid callback scheme"
            )
        }

        let (handler, hasActive) = lockStartupAndSnapshot()
        guard let handler else {
            throw ASWebAuthenticationSessionError(
                .presentationContextNotProvided
            )
        }
        guard !hasActive else {
            throw ASWebAuthenticationSessionError(
                .presentationContextInvalid,
                reason: "A web authentication request is already active"
            )
        }
        guard !Task.isCancelled else {
            throw ASWebAuthenticationSessionError(.canceledLogin)
        }

        let request = nextRequest(
            url: url,
            callbackURLScheme: callbackURLScheme,
            prefersEphemeralBrowserSession: prefersEphemeralBrowserSession
        )
        let cancellation = CancellationState()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled, !cancellation.isCancelled else {
                    continuation.resume(
                        throwing: ASWebAuthenticationSessionError(.canceledLogin)
                    )
                    return
                }
                storeActive(
                    ActiveRequest(
                        request: request,
                        cancellation: cancellation,
                        continuation: continuation
                    )
                )
                handler(.start(request))
            }
        } onCancel: {
            cancellation.cancel()
            cancel(requestID: request.id)
        }
    }

    private static func cancel(requestID: UInt64) {
        state.lock.lock()
        guard let active = state.activeRequest,
              active.request.id == requestID else {
            state.lock.unlock()
            return
        }
        // Claim and resume the terminal state before notifying the host. A
        // reentrant host callback must observe no live request and cannot turn
        // cancellation into a successful credential URL.
        state.activeRequest = nil
        let handler = state.eventHandler
        state.lock.unlock()
        active.continuation.resume(
            throwing: ASWebAuthenticationSessionError(.canceledLogin)
        )
        handler?(.cancel(id: requestID))
    }

    private static func finish(
        _ active: ActiveRequest,
        with result: Result<URL, Error>
    ) {
        state.lock.lock()
        guard state.activeRequest?.request.id == active.request.id else {
            state.lock.unlock()
            return
        }
        state.activeRequest = nil
        state.lock.unlock()
        switch result {
        case .success(let url): active.continuation.resume(returning: url)
        case .failure(let error): active.continuation.resume(throwing: error)
        }
    }

    fileprivate static func isValidInitialURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return false }
        return url.host?.isEmpty == false
    }

    fileprivate static func isValidCallbackScheme(_ scheme: String) -> Bool {
        guard let first = scheme.utf8.first,
              (first >= 65 && first <= 90) || (first >= 97 && first <= 122)
        else { return false }
        return scheme.utf8.dropFirst().allSatisfy { byte in
            (byte >= 65 && byte <= 90)
                || (byte >= 97 && byte <= 122)
                || (byte >= 48 && byte <= 57)
                || byte == 43 || byte == 45 || byte == 46
        }
    }
}

/// SwiftUI overlay `WebAuthenticationSession` type, hosted in the isolated
/// `AuthenticationServices` module so Linux can compile it without SwiftUI.
/// The Darwin `_AuthenticationServices_SwiftUI` overlay re-exports the
/// `EnvironmentValues` key; the session value itself lives here.
@available(iOS 16.4, macOS 13.3, watchOS 9.4, tvOS 16.4, *)
@MainActor
public struct WebAuthenticationSession: Sendable {
    public struct BrowserSession: Sendable, Equatable {
        fileprivate enum Storage: UInt8, Sendable {
            case shared
            case ephemeral
        }

        fileprivate let storage: Storage

        public static var ephemeral: BrowserSession {
            BrowserSession(storage: .ephemeral)
        }

        public static var shared: BrowserSession {
            BrowserSession(storage: .shared)
        }
    }

    nonisolated public init() {}

    nonisolated public func authenticate(
        using url: URL,
        callbackURLScheme: String,
        preferredBrowserSession: BrowserSession? = nil
    ) async throws -> URL {
        try await AuthenticationServicesPortable._authenticate(
            using: url,
            callbackURLScheme: callbackURLScheme,
            prefersEphemeralBrowserSession:
                preferredBrowserSession?.storage == .ephemeral
        )
    }

    nonisolated public func authenticate(
        using url: URL,
        callback: ASWebAuthenticationSession.Callback,
        preferredBrowserSession: BrowserSession? = nil,
        additionalHeaderFields: [String: String]
    ) async throws -> URL {
        _ = additionalHeaderFields
        guard let scheme = callback.customSchemeValue else {
            throw ASWebAuthenticationSessionError(
                .presentationContextInvalid,
                reason: "HTTPS callback matching is host-driven and has no Apple-oracle scheme mapping on Linux"
            )
        }
        let result = try await authenticate(
            using: url,
            callbackURLScheme: scheme,
            preferredBrowserSession: preferredBrowserSession
        )
        guard callback.matchesURL(result) else {
            throw ASWebAuthenticationSessionError(
                .presentationContextInvalid,
                reason: "The callback URL did not match the requested callback"
            )
        }
        return result
    }
}

/// Serial queue used by fail-closed Apple-service completions on Linux.
/// This is a host control, not Apple's daemon queue.
public enum AuthenticationServicesHostCallback {
    public static let queue = DispatchQueue(
        label: "org.openuikit.AuthenticationServices.host-callback"
    )
}
