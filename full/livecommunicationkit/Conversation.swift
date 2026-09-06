import Foundation

/// A process-local conversation object.
///
/// Apple's type is not publicly constructible. Linux tests obtain instances
/// through `LiveCommunicationKitHost.conversation` (`@_spi(OpenUIKitHost)`).
/// `reportNewIncomingConversation` does not invent a system incoming-call UI.
public final class Conversation: @unchecked Sendable, CustomDebugStringConvertible {
    public enum State: Int, Hashable, Codable, Sendable {
        case idle = 0
        case joining = 1
        case joined = 2
        case paused = 3
        case leaving = 4
        case left = 5
    }

    /// End reasons follow Swift sequential `Int` assignment from the
    /// API-digester child order. CallKit `CXCallEndedReason` starts at 1 and
    /// uses `answeredElsewhere` instead of `joinedElsewhere`.
    public enum EndedReason: Int, Hashable, Codable, Sendable {
        case failed = 0
        case remoteEnded = 1
        case unanswered = 2
        case joinedElsewhere = 3
        case declinedElsewhere = 4
    }

    public struct Update: Hashable, Codable, Sendable {
        public var localMember: Handle?
        public var members: Set<Handle>?
        public var activeRemoteMembers: Set<Handle>?
        public var capabilities: Conversation.Capabilities?

        public init(
            localMember: Handle? = nil,
            members: Set<Handle>? = nil,
            activeRemoteMembers: Set<Handle>? = nil,
            capabilities: Conversation.Capabilities? = nil
        ) {
            self.localMember = localMember
            self.members = members
            self.activeRemoteMembers = activeRemoteMembers
            self.capabilities = capabilities
        }
    }

    /// Capability bits follow API-digester stored-property order:
    /// pausing, merging, unmerging, video, playingTones.
    public struct Capabilities: OptionSet, Hashable, Codable, Sendable {
        public typealias RawValue = Int
        public typealias ArrayLiteralElement = Conversation.Capabilities
        public typealias Element = Conversation.Capabilities

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let pausing = Capabilities(rawValue: 1 << 0)
        public static let merging = Capabilities(rawValue: 1 << 1)
        public static let unmerging = Capabilities(rawValue: 1 << 2)
        public static let video = Capabilities(rawValue: 1 << 3)
        public static let playingTones = Capabilities(rawValue: 1 << 4)
    }

    public enum Event: Hashable, Codable, Sendable {
        case conversationUpdated(Conversation.Update)
        case conversationStartedConnecting(Date)
        case conversationConnected(Date)
        case conversationEnded(Date, Conversation.EndedReason)
    }

    public let uuid: UUID

    private let lock = NSLock()
    private var _state: State
    private var _localMember: Handle?
    private var _members: Set<Handle>
    private var _activeRemoteMembers: Set<Handle>
    private var _capabilities: Capabilities

    public var state: State {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    public var localMember: Handle? {
        lock.lock()
        defer { lock.unlock() }
        return _localMember
    }

    public var debugDescription: String {
        lock.lock()
        let current = _state
        lock.unlock()
        return "Conversation(uuid: \(uuid.uuidString), state: \(current))"
    }

    init(uuid: UUID, state: State, localMember: Handle?) {
        self.uuid = uuid
        self._state = state
        self._localMember = localMember
        self._members = []
        self._activeRemoteMembers = []
        self._capabilities = []
    }

    func apply(_ event: Event) {
        lock.lock()
        defer { lock.unlock() }
        switch event {
        case .conversationUpdated(let update):
            if let member = update.localMember {
                _localMember = member
            }
            if let members = update.members {
                _members = members
            }
            if let active = update.activeRemoteMembers {
                _activeRemoteMembers = active
            }
            if let capabilities = update.capabilities {
                _capabilities = capabilities
            }
        case .conversationStartedConnecting:
            _state = .joining
        case .conversationConnected:
            _state = .joined
        case .conversationEnded:
            _state = .left
        }
    }

    func apply(update: Update) {
        apply(.conversationUpdated(update))
    }
}
