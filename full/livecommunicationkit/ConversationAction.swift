import Foundation

/// Base conversation action. `fulfill()` and `fail()` are a local state
/// machine; they do not contact a telephony daemon.
///
/// `fail()` records `ConversationAction.State.failed(reason: "")` because
/// the public selector has no reason parameter. Apple's payload is
/// unobserved.
public class ConversationAction: @unchecked Sendable {
    public enum State: Hashable, Codable, Sendable {
        case idle
        case running
        case complete
        case failed(reason: String)
    }

    public let uuid: UUID
    public let conversationUUID: UUID
    public let timeoutDate: Date

    private let lock = NSLock()
    private var _state: State = .idle

    public var state: State {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    public init(
        conversationUUID: UUID,
        timeoutDate: Date = Date(timeIntervalSinceNow: 30)
    ) {
        self.uuid = UUID()
        self.conversationUUID = conversationUUID
        self.timeoutDate = timeoutDate
    }

    public func fulfill() {
        lock.lock()
        defer { lock.unlock() }
        switch _state {
        case .complete, .failed:
            return
        case .idle, .running:
            _state = .complete
        }
    }

    public func fail() {
        lock.lock()
        defer { lock.unlock() }
        switch _state {
        case .complete, .failed:
            return
        case .idle, .running:
            _state = .failed(reason: "")
        }
    }

    func hostMarkRunning() {
        lock.lock()
        defer { lock.unlock() }
        if case .idle = _state {
            _state = .running
        }
    }
}

public final class PlayToneAction: ConversationAction, @unchecked Sendable {
    public enum Tone: Int, Hashable, Codable, Sendable {
        case single = 0
        case softPause = 1
        case hardPause = 2
    }

    public let digits: String
    public let tone: Tone

    public init(conversationUUID: UUID, digits: String, tone: Tone) {
        self.digits = digits
        self.tone = tone
        super.init(conversationUUID: conversationUUID)
    }
}

public final class SetTranslatingAction: ConversationAction, @unchecked Sendable {
    public enum TranslationEngine: Hashable, Sendable {
        case `default`
        case custom
    }

    public let isTranslating: Bool
    public let localLanguage: Locale.Language
    public let remoteLanguage: Locale.Language
    var hostTranslationEngine: TranslationEngine?

    public init(
        conversationID: UUID,
        isTranslating: Bool,
        localLanguage: Locale.Language,
        remoteLanguage: Locale.Language
    ) {
        self.isTranslating = isTranslating
        self.localLanguage = localLanguage
        self.remoteLanguage = remoteLanguage
        super.init(conversationUUID: conversationID)
    }

    public func fulfill(using translationEngine: TranslationEngine) {
        hostTranslationEngine = translationEngine
        fulfill()
    }
}

public final class EndConversationAction: ConversationAction, @unchecked Sendable {
    var hostDateEnded: Date?

    public init(conversationUUID: UUID) {
        super.init(conversationUUID: conversationUUID)
    }

    public func fulfill(dateEnded: Date) {
        hostDateEnded = dateEnded
        fulfill()
    }
}

public final class JoinConversationAction: ConversationAction, @unchecked Sendable {
    var hostDateConnected: Date?

    public init(conversationUUID: UUID) {
        super.init(conversationUUID: conversationUUID)
    }

    public func fulfill(dateConnected: Date) {
        hostDateConnected = dateConnected
        fulfill()
    }
}

public final class MuteConversationAction: ConversationAction, @unchecked Sendable {
    public let isMuted: Bool

    public init(conversationUUID: UUID, isMuted: Bool) {
        self.isMuted = isMuted
        super.init(conversationUUID: conversationUUID)
    }
}

public final class MergeConversationAction: ConversationAction, @unchecked Sendable {
    public let conversationUUIDToMergeWith: UUID

    public init(conversationUUID: UUID, conversationUUIDToMergeWith: UUID) {
        self.conversationUUIDToMergeWith = conversationUUIDToMergeWith
        super.init(conversationUUID: conversationUUID)
    }
}

public final class PauseConversationAction: ConversationAction, @unchecked Sendable {
    public let isPaused: Bool

    public init(conversationUUID: UUID, isPaused: Bool) {
        self.isPaused = isPaused
        super.init(conversationUUID: conversationUUID)
    }
}

public final class StartConversationAction: ConversationAction, @unchecked Sendable {
    public let handles: [Handle]
    public let isVideo: Bool
    var hostDateStarted: Date?

    public init(conversationUUID: UUID, handles: [Handle], isVideo: Bool) {
        self.handles = handles
        self.isVideo = isVideo
        super.init(conversationUUID: conversationUUID)
    }

    public func fulfill(dateStarted: Date) {
        hostDateStarted = dateStarted
        fulfill()
    }
}

public final class UnmergeConversationAction: ConversationAction, @unchecked Sendable {
    public init(conversationUUID: UUID) {
        super.init(conversationUUID: conversationUUID)
    }
}
