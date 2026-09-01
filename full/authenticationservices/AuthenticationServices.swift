@_exported import Foundation

/// The public error domain used by web-authentication sessions.
public let ASWebAuthenticationSessionErrorDomain =
    "com.apple.AuthenticationServices.WebAuthenticationSession"

/// Portable counterpart of AuthenticationServices' typed NSError overlay.
public struct ASWebAuthenticationSessionError:
    Error, Equatable, Sendable, CustomStringConvertible
{
    public struct Code: RawRepresentable, Equatable, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let canceledLogin = Code(rawValue: 1)
        public static let presentationContextNotProvided = Code(rawValue: 2)
        public static let presentationContextInvalid = Code(rawValue: 3)
    }

    public let code: Code
    public let reason: String

    public init(_ code: Code, reason: String? = nil) {
        self.code = code
        self.reason = reason ?? Self.defaultReason(for: code)
    }

    public var description: String { reason }

    private static func defaultReason(for code: Code) -> String {
        switch code {
        case .canceledLogin:
            return "The web authentication session was canceled"
        case .presentationContextNotProvided:
            return "No web authentication host was configured at startup"
        case .presentationContextInvalid:
            return "The web authentication request or callback was invalid"
        default:
            return "The web authentication session failed"
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
@MainActor
public enum AuthenticationServicesPortable {
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

    public typealias EventHandler = @MainActor @Sendable (Event) -> Void

    private struct ActiveRequest {
        let request: Request
        let cancellation: CancellationState
        let continuation: CheckedContinuation<URL, Error>
    }

    /// Cancellation handlers are permitted to run away from the main actor.
    /// Keep the terminal bit in a tiny locked box so cancellation is claimed
    /// synchronously, before a queued main-actor cleanup can race a callback.
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

    private static var eventHandler: EventHandler?
    private static var activeRequest: ActiveRequest?
    private static var nextRequestID: UInt64 = 0
    private static var startupConfigurationLocked = false

    public static var isHostConfigured: Bool { eventHandler != nil }
    public static var hasActiveRequest: Bool { activeRequest != nil }

    /// Install the browser boundary before the first authentication request.
    /// Returning false means startup configuration is already frozen.
    @_spi(OpenUIKitHost)
    @discardableResult
    public static func _installEventHandler(
        _ handler: EventHandler?
    ) -> Bool {
        guard !startupConfigurationLocked, activeRequest == nil else {
            return false
        }
        eventHandler = handler
        return true
    }

    @_spi(OpenUIKitHost)
    public static func _hostDidComplete(
        requestID: UInt64,
        callbackURL: URL
    ) {
        guard let active = activeRequest,
              active.request.id == requestID else { return }
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
        guard let active = activeRequest,
              active.request.id == requestID else { return }
        finish(
            active,
            with: .failure(ASWebAuthenticationSessionError(.canceledLogin))
        )
    }

    /// Test/host teardown seam. Any live waiter is resumed as canceled.
    @_spi(OpenUIKitHost)
    public static func _reset() {
        if let active = activeRequest {
            activeRequest = nil
            active.continuation.resume(
                throwing: ASWebAuthenticationSessionError(.canceledLogin)
            )
        }
        eventHandler = nil
        nextRequestID = 0
        startupConfigurationLocked = false
    }

    @_spi(OpenUIKitHost)
    public static func _authenticate(
        using url: URL,
        callbackURLScheme: String,
        prefersEphemeralBrowserSession: Bool
    ) async throws -> URL {
        startupConfigurationLocked = true
        guard isValidInitialURL(url),
              isValidCallbackScheme(callbackURLScheme) else {
            throw ASWebAuthenticationSessionError(
                .presentationContextInvalid,
                reason: "Web authentication requires HTTP(S) and a valid callback scheme"
            )
        }
        guard let eventHandler else {
            throw ASWebAuthenticationSessionError(
                .presentationContextNotProvided
            )
        }
        guard activeRequest == nil else {
            throw ASWebAuthenticationSessionError(
                .presentationContextInvalid,
                reason: "A web authentication request is already active"
            )
        }
        guard !Task.isCancelled else {
            throw ASWebAuthenticationSessionError(.canceledLogin)
        }

        nextRequestID &+= 1
        let request = Request(
            id: nextRequestID,
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
                activeRequest = ActiveRequest(
                    request: request,
                    cancellation: cancellation,
                    continuation: continuation
                )
                eventHandler(.start(request))
            }
        } onCancel: {
            cancellation.cancel()
            Task { @MainActor in
                cancel(requestID: request.id)
            }
        }
    }

    private static func cancel(requestID: UInt64) {
        guard let active = activeRequest,
              active.request.id == requestID else { return }
        // Claim and resume the terminal state before notifying the host. A
        // reentrant host callback must observe no live request and cannot turn
        // cancellation into a successful credential URL.
        activeRequest = nil
        active.continuation.resume(
            throwing: ASWebAuthenticationSessionError(.canceledLogin)
        )
        eventHandler?(.cancel(id: requestID))
    }

    private static func finish(
        _ active: ActiveRequest,
        with result: Result<URL, Error>
    ) {
        guard activeRequest?.request.id == active.request.id else { return }
        activeRequest = nil
        switch result {
        case .success(let url): active.continuation.resume(returning: url)
        case .failure(let error): active.continuation.resume(throwing: error)
        }
    }

    private static func isValidInitialURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return false }
        return url.host?.isEmpty == false
    }

    private static func isValidCallbackScheme(_ scheme: String) -> Bool {
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
