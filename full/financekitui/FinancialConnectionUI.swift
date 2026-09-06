import Foundation

/// Parameters supplied by the system when authorizing a financial connection.
public typealias FinancialConnectionExtensionAuthorizationParams = [String: String]

/// Result returned by a financial-connection UI extension after authorization.
///
/// Linux implements `Codable` with a keyed `params` field. Apple's exact
/// coding keys are unobserved (see `oracle-questions.tsv`).
public struct FinancialConnectionExtensionAuthorizationResult: Equatable, Sendable {
    public let params: FinancialConnectionExtensionAuthorizationParams

    public init(params: FinancialConnectionExtensionAuthorizationParams) {
        self.params = params
    }
}

extension FinancialConnectionExtensionAuthorizationResult: Codable {
    enum CodingKeys: String, CodingKey {
        case params
    }
}

/// A system-created authorization request delivered to a UI extension.
///
/// Darwin constructs this from the bank-connection daemon. Linux exposes a
/// host initializer. Completing twice is fail-closed: the first result is
/// delivered, later calls are counted and ignored.
public struct FinancialConnectionExtensionAuthorizationRequest {
    public typealias CompletionHandlerResult =
        Result<FinancialConnectionExtensionAuthorizationResult, any Error>
    public typealias CompletionHandler = (CompletionHandlerResult) -> Void

    public var params: FinancialConnectionExtensionAuthorizationParams

    private let box: AuthorizationRequestBox

    @_spi(OpenUIKitHost)
    public init(
        params: FinancialConnectionExtensionAuthorizationParams,
        completion: CompletionHandler? = nil
    ) {
        self.params = params
        self.box = AuthorizationRequestBox(completion: completion)
    }

    /// Completes the request with an authorization result.
    ///
    /// The completion runs synchronously on the calling thread. Linux has no
    /// extension host queue.
    public func complete(authorizationResult: FinancialConnectionExtensionAuthorizationResult) {
        box.complete(.success(authorizationResult))
    }

    /// Completes the request with an error.
    ///
    /// Linux delivers the error synchronously. A second complete is ignored.
    public func complete(error: any Error) {
        box.complete(.failure(error))
    }

    @_spi(OpenUIKitHost)
    public var hostCompleted: Bool {
        box.completed
    }

    @_spi(OpenUIKitHost)
    public var hostDuplicateCompletes: Int {
        box.duplicateCompletes
    }
}

final class AuthorizationRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private let completion: FinancialConnectionExtensionAuthorizationRequest.CompletionHandler?
    private(set) var completed = false
    private(set) var duplicateCompletes = 0

    init(completion: FinancialConnectionExtensionAuthorizationRequest.CompletionHandler?) {
        self.completion = completion
    }

    func complete(
        _ result: FinancialConnectionExtensionAuthorizationRequest.CompletionHandlerResult
    ) {
        lock.lock()
        if completed {
            duplicateCompletes += 1
            lock.unlock()
            FinanceKitUIHostState.shared.noteAuthorizationComplete(duplicate: true)
            return
        }
        completed = true
        let handler = completion
        lock.unlock()
        FinanceKitUIHostState.shared.noteAuthorizationComplete(duplicate: false)
        handler?(result)
    }
}

/// Provides authorization UI for a financial-connection extension.
public protocol FinancialConnectionUIExtensionProviding {
    func authorize(_ request: FinancialConnectionExtensionAuthorizationRequest)
}

/// Scene protocol for financial-connection UI extensions.
///
/// Darwin is `@MainActor`. Linux omits `@MainActor` so the sealed runner can
/// construct conforming types without a run loop.
public protocol FinancialConnectionUIExtensionScene: AppExtensionScene {}

/// Process-local leaf scene. Does not present bank-login UI.
public struct FinanceKitUIHostExtensionScene: FinancialConnectionUIExtensionScene, Sendable {
    public typealias Body = Never

    public init() {}

    public var body: Never {
        fatalError("FinanceKitUIHostExtensionScene is a leaf AppExtensionScene")
    }
}

/// Scene that hosts authorization content for a financial-connection extension.
///
/// Linux stores the content closure and does not render it.
public struct FinancialConnectionUIExtensionAuthorizationScene<Content: View>:
    FinancialConnectionUIExtensionScene
{
    public typealias Body = FinanceKitUIHostExtensionScene

    private let content: () -> Content

    public init(content: @escaping () -> Content) {
        self.content = content
    }

    public var body: FinanceKitUIHostExtensionScene {
        FinanceKitUIHostExtensionScene()
    }

    @_spi(OpenUIKitHost)
    public func hostRenderContent() -> Content {
        content()
    }
}

/// A financial-connection UI extension.
///
/// Darwin is `@MainActor` and inherits ExtensionFoundation `AppExtension`.
/// Linux omits `@MainActor`. `configuration` never launches an `appex`.
public protocol FinancialConnectionUIExtension: AppExtension, FinancialConnectionUIExtensionProviding
where Configuration == AppExtensionSceneConfiguration {
    associatedtype Body: FinancialConnectionUIExtensionScene
    var body: Self.Body { get }
}

extension FinancialConnectionUIExtension {
    /// A read-only configuration wrapping `body`.
    ///
    /// Linux vends an isolation `AppExtensionSceneConfiguration`. It does not
    /// register an ExtensionKit scene with a host.
    public var configuration: AppExtensionSceneConfiguration {
        AppExtensionSceneConfiguration(body)
    }
}
