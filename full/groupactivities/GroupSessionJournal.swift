import Foundation

/// Shared attachments for a group session. Linux has no `CoreTransferable`
/// pipeline; `add`/`load` Transferable overloads are omitted, and
/// ``remove(attachment:)`` / ``Attachment/loadMetadata(of:)`` throw
/// ``GroupActivitiesHostError/journalUnavailable``.
public final class GroupSessionJournal {
    public struct Attachment: Hashable, Sendable, Identifiable {
        public typealias ID = UUID
        public var id: UUID

        @_spi(OpenUIKitHost)
        public init(id: UUID) {
            self.id = id
        }

        public func loadMetadata<MetadataType: Decodable & Encodable>(
            of: MetadataType.Type
        ) async throws -> MetadataType {
            _ = of
            throw GroupActivitiesHostError.journalUnavailable
        }
    }

    public struct Attachments: AsyncSequence {
        public typealias Element = [Attachment]
        public typealias AsyncIterator = Iterator

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = [Attachment]

            public mutating func next() async -> [Attachment]? {
                nil
            }
        }
    }

    public var attachments: Attachments

    public init<Activity: GroupActivity>(session: GroupSession<Activity>) {
        _ = session.id
        self.attachments = Attachments()
    }

    public func remove(attachment: Attachment) async throws {
        _ = attachment
        throw GroupActivitiesHostError.journalUnavailable
    }
}
