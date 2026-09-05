import Foundation
import Dispatch

open class ASWebAuthenticationSession: NSObject {
    public typealias CompletionHandler = (URL?, (any Error)?) -> Void

    public final class Callback: NSObject {
        fileprivate enum Kind {
            case customScheme(String)
            case https(host: String, path: String)
        }

        fileprivate let kind: Kind

        fileprivate init(kind: Kind) {
            self.kind = kind
            super.init()
        }

        public class func customScheme(_ customScheme: String) -> Self {
            Self(kind: .customScheme(customScheme))
        }

        public class func https(host: String, path: String) -> Self {
            Self(kind: .https(host: host, path: path))
        }

        public func matchesURL(_ url: URL) -> Bool {
            // Linux overlay: custom-scheme compares `url.scheme` case-insensitively
            // to the requested scheme. HTTPS compares scheme `https`, host
            // case-insensitively, and path equal-or-prefix (a `/cb` callback
            // matches `/cb` and `/cb/extra`). Apple's exact HTTPS path rule is
            // an oracle question; this is the rule tests lock.
            switch kind {
            case .customScheme(let scheme):
                return url.scheme?.lowercased() == scheme.lowercased()
            case .https(let host, let path):
                guard url.scheme?.lowercased() == "https" else { return false }
                guard url.host?.lowercased() == host.lowercased() else { return false }
                let wanted = path.hasPrefix("/") ? path : "/" + path
                return url.path == wanted
                    || url.path.hasPrefix(wanted.hasSuffix("/") ? wanted : wanted + "/")
            }
        }

        var customSchemeValue: String? {
            if case .customScheme(let scheme) = kind { return scheme }
            return nil
        }
    }

    public var additionalHeaderFields: [String: String]?
    public var prefersEphemeralWebBrowserSession = false
    public private(set) var canStart = true
    /// Darwin requires this before `start()`; missing it is
    /// `ASWebAuthenticationSessionError.presentationContextNotProvided`
    /// (Apple `ASWebAuthenticationSessionError.Code.presentationContextNotProvided`).
    public weak var presentationContextProvider:
        (any ASWebAuthenticationPresentationContextProviding)?

    /// Documented Linux test hook. When set before `start()`, and a
    /// presentation context provider is present, the session delivers this
    /// URL (or `.canceledLogin` when `nil` and no portable host is installed)
    /// instead of opening a browser. Matching uses `Callback.matchesURL`.
    @_spi(OpenUIKitHost)
    public var _testCallbackURL: URL?

    private let url: URL
    private let callbackURLScheme: String?
    private let callback: Callback?
    private let completionHandler: CompletionHandler
    private let lock = NSLock()
    private var started = false
    private var cancelled = false
    private var finished = false

    public init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping CompletionHandler
    ) {
        self.url = URL
        self.callbackURLScheme = callbackURLScheme
        self.callback = callbackURLScheme.map { Callback.customScheme($0) }
        self.completionHandler = completionHandler
        super.init()
    }

    public init(
        URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping CompletionHandler
    ) {
        self.url = URL
        self.callbackURLScheme = callbackURLScheme
        self.callback = callbackURLScheme.map { Callback.customScheme($0) }
        self.completionHandler = completionHandler
        super.init()
    }

    public init(
        url URL: URL,
        callback: Callback,
        completionHandler: @escaping CompletionHandler
    ) {
        self.url = URL
        self.callback = callback
        self.callbackURLScheme = callback.customSchemeValue
        self.completionHandler = completionHandler
        super.init()
    }

    public init(
        URL: URL,
        callback: Callback,
        completionHandler: @escaping CompletionHandler
    ) {
        self.url = URL
        self.callback = callback
        self.callbackURLScheme = callback.customSchemeValue
        self.completionHandler = completionHandler
        super.init()
    }

    @discardableResult
    public func start() -> Bool {
        lock.lock()
        if started || cancelled {
            lock.unlock()
            return false
        }
        started = true
        lock.unlock()

        Task {
            self.startOnMain()
        }
        return true
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        canStart = false
        let alreadyFinished = finished
        lock.unlock()
        AuthenticationServicesPortable._cancelActiveIfAny()
        if !alreadyFinished {
            deliver(nil, ASWebAuthenticationSessionError(.canceledLogin))
        }
    }

    private func startOnMain() {
        if snapshotCancelled() {
            deliver(nil, ASWebAuthenticationSessionError(.canceledLogin))
            return
        }
        // Apple: start() without a presentationContextProvider completes with
        // presentationContextNotProvided. Linux keeps that gate even when a
        // portable host is installed.
        guard presentationContextProvider != nil else {
            canStart = false
            deliver(nil, ASWebAuthenticationSessionError(.presentationContextNotProvided))
            return
        }
        canStart = false

        if let testURL = _testCallbackURL {
            if let callback = self.callback, !callback.matchesURL(testURL) {
                deliver(
                    nil,
                    ASWebAuthenticationSessionError(
                        .presentationContextInvalid,
                        reason: "The callback URL did not match the requested callback"
                    )
                )
                return
            }
            deliver(testURL, nil)
            return
        }

        guard AuthenticationServicesPortable.isHostConfigured else {
            // Provider present, no browser, no test hook: fail closed.
            deliver(nil, ASWebAuthenticationSessionError(.canceledLogin))
            return
        }
        guard let scheme = callbackURLScheme, !scheme.isEmpty else {
            deliver(
                nil,
                ASWebAuthenticationSessionError(
                    .presentationContextInvalid,
                    reason: "HTTPS-only callbacks require a host scheme mapping that Linux does not invent"
                )
            )
            return
        }
        Task {
            do {
                let result = try await AuthenticationServicesPortable._authenticate(
                    using: self.url,
                    callbackURLScheme: scheme,
                    prefersEphemeralBrowserSession: self.prefersEphemeralWebBrowserSession
                )
                if self.snapshotCancelled() { return }
                if let callback = self.callback, !callback.matchesURL(result) {
                    self.deliver(
                        nil,
                        ASWebAuthenticationSessionError(
                            .presentationContextInvalid,
                            reason: "The callback URL did not match the requested callback"
                        )
                    )
                    return
                }
                self.deliver(result, nil)
            } catch {
                if self.snapshotCancelled() { return }
                self.deliver(nil, error)
            }
        }
    }

    private func snapshotCancelled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    private func deliver(_ url: URL?, _ error: (any Error)?) {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        finished = true
        lock.unlock()
        AuthenticationServicesHostCallback.queue.async {
            self.completionHandler(url, error)
        }
    }
}

/// Darwin is `@MainActor`. Linux omits the isolation so host tests can assign
/// a provider off the main actor; the protocol identity is the ObjC USR
/// `ASWebAuthenticationPresentationContextProviding`.
public protocol ASWebAuthenticationPresentationContextProviding: NSObjectProtocol {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor
}
