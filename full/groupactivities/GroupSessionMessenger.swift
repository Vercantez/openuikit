import Foundation

/// Fail-closed messenger. Completion-based `send` reports
/// ``GroupActivitiesHostError/messengerUnavailable`` immediately. Incoming
/// ``messages(of:)`` sequences complete empty; Linux has no SharePlay datagram
/// path.
public final class GroupSessionMessenger {
    public enum DeliveryMode: Hashable, Sendable {
        case unreliable
        case reliable
    }

    public struct MessageContext: Equatable {
        public var source: Participant

        @_spi(OpenUIKitHost)
        public init(source: Participant) {
            self.source = source
        }
    }

    public struct Messages<Message: Decodable & Encodable>: AsyncSequence {
        public typealias Element = (Message, MessageContext)
        public typealias AsyncIterator = Iterator

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = (Message, MessageContext)

            public mutating func next() async -> (Message, MessageContext)? {
                nil
            }
        }
    }

    public let deliveryMode: DeliveryMode

    public init<Activity: GroupActivity>(
        session: GroupSession<Activity>,
        deliveryMode: DeliveryMode
    ) {
        self.deliveryMode = deliveryMode
        _ = session.id
    }

    public init<Activity: GroupActivity>(session: GroupSession<Activity>) {
        self.deliveryMode = .reliable
        _ = session.id
    }

    public func send(
        _ value: Data,
        to participants: Participants = .all,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (value, participants)
        completion(GroupActivitiesHostError.messengerUnavailable)
    }

    public func send<Message: Decodable & Encodable>(
        _ value: Message,
        to participants: Participants = .all,
        completion: @escaping ((any Error)?) -> Void
    ) {
        _ = (value, participants)
        completion(GroupActivitiesHostError.messengerUnavailable)
    }

    public func send(
        _ value: Data,
        to participants: Participants = .all
    ) async throws {
        _ = (value, participants)
        throw GroupActivitiesHostError.messengerUnavailable
    }

    public func send<Message: Decodable & Encodable>(
        _ value: Message,
        to participants: Participants = .all
    ) async throws {
        _ = (value, participants)
        throw GroupActivitiesHostError.messengerUnavailable
    }

    public func messages(of type: Data.Type) -> Messages<Data> {
        _ = type
        return Messages<Data>()
    }

    public func messages<Message: Decodable & Encodable>(
        of type: Message.Type
    ) -> Messages<Message> {
        _ = type
        return Messages<Message>()
    }
}
