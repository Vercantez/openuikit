import Foundation

/// A scene that can appear in an identity-document provider extension.
///
/// Darwin is `@MainActor @preconcurrency` and inherits ExtensionKit
/// `AppExtensionScene`. Linux omits `@MainActor`.
public protocol IdentityDocumentRequestScene: AppExtensionScene {}

/// Process-local leaf scene returned by `ISO18013MobileDocumentRequestScene.body`.
/// Does not present identity-document UI.
public struct IdentityDocumentHostRequestScene: IdentityDocumentRequestScene, Sendable {
    public typealias Body = Never

    public var body: Never {
        fatalError("IdentityDocumentHostRequestScene is a leaf AppExtensionScene")
    }
}

/// Linux composition of two request scenes. Not an Apple public type;
/// Darwin's two-argument `buildBlock` opaque result is unobserved.
public struct IdentityDocumentRequestScenePair<
    First: IdentityDocumentRequestScene,
    Second: IdentityDocumentRequestScene
>: IdentityDocumentRequestScene {
    public typealias Body = Never

    public let first: First
    public let second: Second

    public var body: Never {
        fatalError("IdentityDocumentRequestScenePair is a leaf AppExtensionScene")
    }
}

/// Linux optional request scene. Not an Apple public type.
public struct IdentityDocumentOptionalRequestScene<Scene: IdentityDocumentRequestScene>:
    IdentityDocumentRequestScene
{
    public typealias Body = Never

    public let scene: Scene?

    public var body: Never {
        fatalError("IdentityDocumentOptionalRequestScene is a leaf AppExtensionScene")
    }
}

/// A result builder that composes identity-document request scenes.
///
/// Darwin is `@MainActor @resultBuilder`. Linux omits `@MainActor`.
/// Composition is process-local and never registers ExtensionKit scenes.
@resultBuilder
public struct IdentityDocumentRequestSceneBuilder: Sendable {
    public init() {}

    public static func buildBlock<Scene: IdentityDocumentRequestScene>(
        _ scene: Scene
    ) -> Scene {
        scene
    }

    public static func buildBlock<
        First: IdentityDocumentRequestScene,
        Second: IdentityDocumentRequestScene
    >(
        _ s0: First,
        _ s1: Second
    ) -> IdentityDocumentRequestScenePair<First, Second> {
        IdentityDocumentRequestScenePair(first: s0, second: s1)
    }

    public static func buildOptional<Scene: IdentityDocumentRequestScene>(
        _ scene: Scene?
    ) -> IdentityDocumentOptionalRequestScene<Scene> {
        IdentityDocumentOptionalRequestScene(scene: scene)
    }

    public static func buildLimitedAvailability<Scene: IdentityDocumentRequestScene>(
        _ scene: Scene
    ) -> Scene {
        scene
    }
}

/// A protocol that creates an identity-document provider extension.
///
/// Darwin is `@MainActor` and inherits ExtensionFoundation `AppExtension`.
/// Linux omits `@MainActor`. `configuration` never launches an `appex`.
public protocol IdentityDocumentProvider: AppExtension
where Configuration == AppExtensionSceneConfiguration {
    associatedtype Body: IdentityDocumentRequestScene
    @IdentityDocumentRequestSceneBuilder var body: Self.Body { get }
    func performRegistrationUpdates()
}

extension IdentityDocumentProvider {
    /// A read-only, computed configuration for the identity-document provider.
    ///
    /// Linux vends an isolation `AppExtensionSceneConfiguration`. It does not
    /// register an ExtensionKit scene with a host.
    public var configuration: AppExtensionSceneConfiguration {
        AppExtensionSceneConfiguration(body)
    }
}

/// Context passed to an ISO 18013 mobile-document request scene.
///
/// Darwin has no public initializer; the system creates the value. Linux
/// vends a process-local boxed struct so `cancel()` and `sendResponse(_:)`
/// can be non-mutating. `sendResponse` never invokes the handler.
public struct ISO18013MobileDocumentRequestContext: Sendable {
    private final class Storage: @unchecked Sendable {
        let request: ISO18013MobileDocumentRequest
        let requestingWebsiteOrigin: URL?
        let lock = NSLock()
        var phase: ISO18013MobileDocumentRequestHostPhase = .idle
        var sendAttemptCount = 0
        var cancelCount = 0

        init(
            request: ISO18013MobileDocumentRequest,
            requestingWebsiteOrigin: URL?
        ) {
            self.request = request
            self.requestingWebsiteOrigin = requestingWebsiteOrigin
        }
    }

    private let storage: Storage

    public var request: ISO18013MobileDocumentRequest {
        storage.request
    }

    public var requestingWebsiteOrigin: URL? {
        storage.requestingWebsiteOrigin
    }

    public func cancel() {
        storage.lock.lock()
        storage.phase = .cancelled
        storage.cancelCount += 1
        storage.lock.unlock()
    }

    /// Darwin is `async throws` and invokes the handler with a raw request
    /// from the presentment session. Linux never invents a raw request:
    /// the handler is not called, and the method throws.
    public func sendResponse(
        _ responseHandler: @escaping @Sendable (
            IdentityDocumentWebPresentmentRawRequest
        ) throws -> ISO18013MobileDocumentResponse
    ) throws {
        storage.lock.lock()
        let phase = storage.phase
        if phase == .idle {
            storage.sendAttemptCount += 1
            storage.phase = .sendAttempted
        }
        storage.lock.unlock()
        _ = responseHandler
        switch phase {
        case .cancelled:
            throw IdentityDocumentServicesUIUnavailable.linuxHost(
                operation: "sendResponse.cancelled"
            )
        case .sendAttempted:
            throw IdentityDocumentServicesUIUnavailable.linuxHost(
                operation: "sendResponse.requestInProgress"
            )
        case .idle:
            throw IdentityDocumentServicesUIUnavailable.linuxHost(operation: "sendResponse")
        }
    }

    @_spi(OpenUIKitHost)
    public var hostPhase: ISO18013MobileDocumentRequestHostPhase {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.phase
    }

    @_spi(OpenUIKitHost)
    public var hostSendAttemptCount: Int {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.sendAttemptCount
    }

    @_spi(OpenUIKitHost)
    public var hostCancelCount: Int {
        storage.lock.lock()
        defer { storage.lock.unlock() }
        return storage.cancelCount
    }

    @_spi(OpenUIKitHost)
    public static func hostMakeContext(
        request: ISO18013MobileDocumentRequest = ISO18013MobileDocumentRequest(
            presentmentRequests: [],
            requestAuthentications: []
        ),
        requestingWebsiteOrigin: URL? = nil
    ) -> ISO18013MobileDocumentRequestContext {
        ISO18013MobileDocumentRequestContext(
            request: request,
            requestingWebsiteOrigin: requestingWebsiteOrigin
        )
    }

    private init(
        request: ISO18013MobileDocumentRequest,
        requestingWebsiteOrigin: URL?
    ) {
        self.storage = Storage(
            request: request,
            requestingWebsiteOrigin: requestingWebsiteOrigin
        )
    }
}

/// A SwiftUI scene for an ISO 18013 mobile-document request.
///
/// Linux stores the content closure and a process-local context. The
/// closure is not rendered by SwiftUI or ExtensionKit.
public struct ISO18013MobileDocumentRequestScene<Content>: IdentityDocumentRequestScene,
    @unchecked Sendable
where Content: Sendable, Content: View {
    public typealias Body = IdentityDocumentHostRequestScene

    private let content: (ISO18013MobileDocumentRequestContext) -> Content
    private let storedContext: ISO18013MobileDocumentRequestContext

    public init(
        content: @escaping (ISO18013MobileDocumentRequestContext) -> Content
    ) {
        self.content = content
        self.storedContext = ISO18013MobileDocumentRequestContext.hostMakeContext()
    }

    public var body: IdentityDocumentHostRequestScene {
        IdentityDocumentHostRequestScene()
    }

    @_spi(OpenUIKitHost)
    public func hostRenderContent() -> Content {
        content(storedContext)
    }

    @_spi(OpenUIKitHost)
    public var hostContext: ISO18013MobileDocumentRequestContext {
        storedContext
    }
}
