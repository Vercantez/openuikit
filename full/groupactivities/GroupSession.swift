import Foundation

/// In-process group session. Linux never receives a system SharePlay session;
/// tests construct instances through ``makeHostSession(activity:id:locallyInitiated:)``.
public final class GroupSession<ActivityType: GroupActivity> {
    public enum State: Equatable {
        case waiting
        case joined
        case invalidated(reason: any Error)

        public static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.waiting, .waiting), (.joined, .joined):
                return true
            case (.invalidated(let left), .invalidated(let right)):
                let leftError = left as NSError
                let rightError = right as NSError
                return leftError.domain == rightError.domain && leftError.code == rightError.code
            default:
                return false
            }
        }
    }

    public struct Event: Equatable {
        public let originator: Participant
        public let localizedDescription: String

        public init(originator: Participant, localizedDescription: String) {
            self.originator = originator
            self.localizedDescription = localizedDescription
        }
    }

    public struct Sessions: AsyncSequence {
        public typealias Element = GroupSession<ActivityType>
        public typealias AsyncIterator = Iterator

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }

        public struct Iterator: AsyncIteratorProtocol {
            public typealias Element = GroupSession<ActivityType>

            public mutating func next() async -> GroupSession<ActivityType>? {
                nil
            }
        }
    }

    public let id: UUID
    public let isLocallyInitiated: Bool
    public private(set) var localParticipant: Participant
    public var activity: ActivityType
    public private(set) var state: State
    public private(set) var activeParticipants: Set<Participant>
    public var sceneSessionIdentifier: String? { nil }

    public var description: String {
        "GroupSession(id: \(id.uuidString), state: \(stateLabel), locallyInitiated: \(isLocallyInitiated))"
    }

    private var lastNotice: GroupSessionEvent?
    private var lastPostedEvent: Event?
    private var didRequestForeground = false

    private var stateLabel: String {
        switch state {
        case .waiting: return "waiting"
        case .joined: return "joined"
        case .invalidated: return "invalidated"
        }
    }

    private init(activity: ActivityType, id: UUID, locallyInitiated: Bool) {
        self.activity = activity
        self.id = id
        self.isLocallyInitiated = locallyInitiated
        self.localParticipant = Participant(id: UUID())
        self.state = .waiting
        self.activeParticipants = []
    }

    /// Join this process-local session. No Apple daemon is contacted.
    public func join() {
        guard case .waiting = state else { return }
        state = .joined
        activeParticipants.insert(localParticipant)
    }

    /// Leave the local session. State becomes ``State/invalidated(reason:)`` with
    /// ``GroupActivitiesHostError/sessionLeft``.
    public func leave() {
        switch state {
        case .invalidated:
            return
        case .waiting, .joined:
            state = .invalidated(reason: GroupActivitiesHostError.sessionLeft)
            activeParticipants.remove(localParticipant)
        }
    }

    /// End the session for every recorded participant. Linux still only mutates
    /// this process; it does not notify remote devices.
    public func end() {
        switch state {
        case .invalidated:
            return
        case .waiting, .joined:
            state = .invalidated(reason: GroupActivitiesHostError.sessionEnded)
            activeParticipants.removeAll()
        }
    }

    /// Linux has no scene / SharePlay banner. The call is recorded and ignored.
    public func requestForegroundPresentation() {
        didRequestForeground = true
    }

    /// Linux has no system notice UI. The event is stored for host tests.
    public func showNotice(_ event: GroupSessionEvent) {
        lastNotice = event
    }

    /// Linux has no system event feed. The event is stored for host tests.
    public func postEvent(_ event: Event) {
        lastPostedEvent = event
    }

    @_spi(OpenUIKitHost)
    public static func makeHostSession(
        activity: ActivityType,
        id: UUID = UUID(),
        locallyInitiated: Bool = true
    ) -> GroupSession<ActivityType> {
        GroupSession(activity: activity, id: id, locallyInitiated: locallyInitiated)
    }

    @_spi(OpenUIKitHost)
    public var hostLastNotice: GroupSessionEvent? { lastNotice }

    @_spi(OpenUIKitHost)
    public var hostLastPostedEvent: Event? { lastPostedEvent }

    @_spi(OpenUIKitHost)
    public var hostDidRequestForeground: Bool { didRequestForeground }
}
