import Foundation

/// A type that can present identity documents.
///
/// Darwin is `@MainActor`. Linux omits actor isolation so the sealed runner
/// can construct conforming types. The protocol has no requirements.
public protocol IdentityDocumentPresentmentControlling {}

/// A type that supplies a window for identity-document presentment UI.
///
/// Darwin is `@MainActor` and class-bound. Linux omits `@MainActor`.
/// Returning a window never presents a sheet on this host.
public protocol IdentityDocumentPresentmentControllerPresentationContextProviding: AnyObject {
    func presentationAnchorForPresentmentController(
        _ presentmentController: any IdentityDocumentPresentmentControlling
    ) -> IdentityDocumentPresentationAnchor?
}

/// A delegate that can vend raw web-presentment requests.
///
/// Darwin is `@MainActor` and the requirement is `async`. Linux is
/// synchronous. `IdentityDocumentWebPresentmentController` never calls this
/// method: there is no Apple presentment session to populate.
public protocol IdentityDocumentWebPresentmentControllerDelegate: AnyObject {
    func rawRequestsForWebPresentmentController(
        _ webPresentmentController: IdentityDocumentWebPresentmentController
    ) -> [IdentityDocumentWebPresentmentRawRequest]
}

/// A controller that presents identity documents to a website.
///
/// Darwin is `@MainActor final`. Linux records origin/request counts and
/// always throws. It never shows UIKit chrome or talks to Wallet.
public final class IdentityDocumentWebPresentmentController: IdentityDocumentPresentmentControlling,
    @unchecked Sendable
{
    private let lock = NSLock()
    private weak var delegateStorage: (any IdentityDocumentWebPresentmentControllerDelegate)?
    private weak var presentationContextProviderStorage:
        (any IdentityDocumentPresentmentControllerPresentationContextProviding)?
    private var hostPhaseStorage: IdentityDocumentWebPresentmentHostPhase = .idle
    private var hostLastOriginStorage: URL?
    private var hostLastRequestCountStorage = 0

    public init() {}

    public weak var delegate: (any IdentityDocumentWebPresentmentControllerDelegate)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return delegateStorage
        }
        set {
            lock.lock()
            delegateStorage = newValue
            lock.unlock()
        }
    }

    public weak var presentationContextProvider:
        (any IdentityDocumentPresentmentControllerPresentationContextProviding)?
    {
        get {
            lock.lock()
            defer { lock.unlock() }
            return presentationContextProviderStorage
        }
        set {
            lock.lock()
            presentationContextProviderStorage = newValue
            lock.unlock()
        }
    }

    /// Darwin is `async throws` and returns a presentment response. Linux
    /// records the call and throws; it never invents a response or consults
    /// the delegate or presentation-context provider.
    public func performRequests(
        _ requests: [any IdentityDocumentWebPresentmentRequest],
        origin: URL
    ) throws -> any IdentityDocumentWebPresentmentResponse {
        lock.lock()
        hostLastRequestCountStorage = requests.count
        hostLastOriginStorage = origin
        hostPhaseStorage = .failed
        lock.unlock()
        throw IdentityDocumentServicesUIUnavailable.linuxHost(operation: "performRequests")
    }

    @_spi(OpenUIKitHost)
    public var hostPhase: IdentityDocumentWebPresentmentHostPhase {
        lock.lock()
        defer { lock.unlock() }
        return hostPhaseStorage
    }

    @_spi(OpenUIKitHost)
    public var hostLastOrigin: URL? {
        lock.lock()
        defer { lock.unlock() }
        return hostLastOriginStorage
    }

    @_spi(OpenUIKitHost)
    public var hostLastRequestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return hostLastRequestCountStorage
    }
}
