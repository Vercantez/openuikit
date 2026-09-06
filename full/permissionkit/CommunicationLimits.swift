import Foundation

/// Process-local Communication Limits facade. Linux has no Screen Time
/// daemon or known-contact store, so queries are empty and `ask` throws
/// `AskError.communicationLimitsNotEnabled`.
public final class CommunicationLimits {
    public static let current = CommunicationLimits()

    private init() {}

    public var updates: AsyncStream<PermissionResponse<CommunicationTopic>> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    public func isKnownHandle(_ handle: CommunicationHandle) async -> Bool {
        _ = handle
        return false
    }

    public func knownHandles(in handles: Set<CommunicationHandle>) async -> Set<CommunicationHandle> {
        _ = handles
        return []
    }

    public func ask(_ question: PermissionQuestion<CommunicationTopic>) async throws {
        _ = question
        throw AskError.communicationLimitsNotEnabled
    }

    public func ask(
        _ question: PermissionQuestion<CommunicationTopic>,
        in viewController: UIViewController
    ) async throws {
        _ = viewController
        try await ask(question)
    }
}
