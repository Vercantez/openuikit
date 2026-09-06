import Foundation

/// Call-history facade. Linux has no Call History database; query and
/// mark-read methods throw `CocoaError.featureUnsupported`.
/// `RecentConversation` is a Codable value type. Notification identity is
/// process-local.
public final class ConversationHistoryManager: @unchecked Sendable {
    public static let sharedInstance = ConversationHistoryManager()

    public struct RecentConversation: Identifiable, Hashable, Codable, Sendable {
        public typealias ID = UUID

        public enum Status: Hashable, Codable, Sendable {
            case connected
            case missed
            case answeredElsewhere
            case cancelled
            case unknown
        }

        public enum Direction: Hashable, Codable, Sendable {
            case outgoing
            case incoming
        }

        public let id: UUID
        public let handles: [Handle]
        public let date: Date
        public let duration: TimeInterval
        public let status: Status
        public let direction: Direction
        public let isRead: Bool
    }

    /// Posted locally when tests or a future host implementation want to
    /// announce a recents refresh. Linux never posts this as a result of
    /// Apple call-history mutation.
    public struct ConversationHistoryDidUpdate: Sendable {
        public typealias Subject = ConversationHistoryManager

        public static var name: Notification.Name {
            Notification.Name("LiveCommunicationKit.ConversationHistoryDidUpdate")
        }

        public init() {}

        public static func makeMessage(
            _ notification: Notification
        ) -> ConversationHistoryManager.ConversationHistoryDidUpdate? {
            guard notification.name == name else { return nil }
            return ConversationHistoryDidUpdate()
        }

        public static func makeNotification(
            _ message: ConversationHistoryManager.ConversationHistoryDidUpdate
        ) -> Notification {
            _ = message
            return Notification(name: name)
        }
    }

    private init() {}

    public func recentConversations(
        matching request: Predicate<ConversationHistoryManager.RecentConversation>
    ) async throws -> [ConversationHistoryManager.RecentConversation] {
        _ = request
        throw LiveCommunicationKitSupport.unsupported(
            "ConversationHistoryManager.recentConversations"
        )
    }

    public func markConversationAsRead(
        _ recentConversation: ConversationHistoryManager.RecentConversation
    ) async throws {
        _ = recentConversation
        throw LiveCommunicationKitSupport.unsupported(
            "ConversationHistoryManager.markConversationAsRead"
        )
    }

    public func markConversationsAsRead(
        _ recentConversations: [ConversationHistoryManager.RecentConversation]
    ) async throws {
        _ = recentConversations
        throw LiveCommunicationKitSupport.unsupported(
            "ConversationHistoryManager.markConversationsAsRead"
        )
    }
}
