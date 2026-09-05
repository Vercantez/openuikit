import Foundation

/// A person in a group session.
///
/// Linux has no Nearby Interaction or Continuity pipeline, so
/// ``isNearbyWithLocalParticipant`` is always `false`.
public struct Participant: Hashable, Sendable, Identifiable, CustomStringConvertible {
    public typealias ID = UUID

    public let id: UUID

    public var isNearbyWithLocalParticipant: Bool { false }

    public var description: String {
        "Participant(id: \(id.uuidString))"
    }

    @_spi(OpenUIKitHost)
    public init(id: UUID) {
        self.id = id
    }
}

/// Recipients of a ``GroupSessionMessenger`` payload.
public enum Participants: Equatable, Sendable {
    case all
    case only(Set<Participant>)

    public static func only(_ participant: Participant) -> Participants {
        .only(Set([participant]))
    }
}
