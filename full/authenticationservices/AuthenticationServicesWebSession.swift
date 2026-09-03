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

        let work = {
            MainActor.assumeIsolated {
                self.startOnMain()
            }
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
        return true
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        canStart = false
        let alreadyFinished = finished
        lock.unlock()
        let hop = {
            MainActor.assumeIsolated {
                AuthenticationServicesPortable._cancelActiveIfAny()
            }
        }
        if Thread.isMainThread {
            hop()
        } else {
            DispatchQueue.main.sync(execute: hop)
        }
        if !alreadyFinished {
            deliver(nil, ASWebAuthenticationSessionError(.canceledLogin))
        }
    }

    @MainActor
    private func startOnMain() {
        if snapshotCancelled() {
            deliver(nil, ASWebAuthenticationSessionError(.canceledLogin))
            return
        }
        guard AuthenticationServicesPortable.isHostConfigured else {
            canStart = false
            deliver(nil, ASWebAuthenticationSessionError(.presentationContextNotProvided))
            return
        }
        guard let scheme = callbackURLScheme, !scheme.isEmpty else {
            canStart = false
            deliver(
                nil,
                ASWebAuthenticationSessionError(
                    .presentationContextInvalid,
                    reason: "HTTPS-only callbacks require a host scheme mapping that Linux does not invent"
                )
            )
            return
        }
        canStart = false
        Task { @MainActor in
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
