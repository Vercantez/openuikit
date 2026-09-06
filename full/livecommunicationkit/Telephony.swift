import Foundation

/// A SIM/service identity. Public construction is Codable-only; there is
/// no memberwise initializer in the pinned graph.
public struct CellularService: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = UUID

    public let id: UUID
    public let label: String
}

/// Request to place a cellular conversation. Equality, hashing, and
/// Codable round-trips are process-local. Performing the request through
/// `TelephonyConversationManager` is fail-closed.
public struct StartCellularConversationAction: Hashable, Codable, Sendable {
    let handle: Handle
    let cellularService: CellularService?

    public init(_ handle: Handle, cellularService: CellularService? = nil) {
        self.handle = handle
        self.cellularService = cellularService
    }

    /// Uses the first recent handle when the recents row has one; otherwise a
    /// generic empty handle. Apple's handle-selection rule is unobserved.
    public init(_ recentConversation: ConversationHistoryManager.RecentConversation) {
        self.handle = recentConversation.handles.first ?? Handle(type: .generic, value: "")
        self.cellularService = nil
    }
}

/// Linux has no baseband or CoreTelephony daemon. `cellularServices` is
/// always empty. `startCellularConversation` throws
/// `CocoaError.featureUnsupported`.
public final class TelephonyConversationManager: @unchecked Sendable {
    public static let sharedInstance = TelephonyConversationManager()

    public var cellularServices: [CellularService] {
        []
    }

    private init() {}

    public func startCellularConversation(
        _ action: StartCellularConversationAction
    ) async throws {
        _ = action
        throw LiveCommunicationKitSupport.unsupported(
            "TelephonyConversationManager.startCellularConversation"
        )
    }
}
