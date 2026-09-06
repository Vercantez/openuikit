import Foundation

public protocol ConversationManagerDelegate: AnyObject {
    func conversationManager(_ manager: ConversationManager, conversationChanged conversation: Conversation)
    func conversationManagerDidBegin(_ manager: ConversationManager)
    func conversationManagerDidReset(_ manager: ConversationManager)
    func conversationManager(_ manager: ConversationManager, perform action: ConversationAction)
    func conversationManager(_ manager: ConversationManager, timedOutPerforming action: ConversationAction)
    func conversationManager(_ manager: ConversationManager, didActivate audioSession: AVAudioSession)
    func conversationManager(_ manager: ConversationManager, didDeactivate audioSession: AVAudioSession)
}

/// Process-local conversation manager. Construction, configuration, the
/// in-process conversation list, `invalidate()`, pending-action queries, and
/// `reportConversationEvent(_:for:)` are real. Methods that would talk to
/// CallKit, PushKit, or a telephony daemon throw
/// `CocoaError.featureUnsupported`. Delegate audio-session callbacks are
/// never delivered.
public final class ConversationManager: @unchecked Sendable {
    public struct Configuration {
        public var ringtoneName: String?
        public var iconTemplateImageData: Data?
        public var maximumConversationGroups: Int
        public var maximumConversationsPerConversationGroup: Int
        public var includesConversationInRecents: Bool
        public var supportsVideo: Bool
        public var supportedHandleTypes: Set<Handle.Kind>
        public var supportsAudioTranslation: Bool

        public init(
            ringtoneName: String?,
            iconTemplateImageData: Data?,
            maximumConversationGroups: Int,
            maximumConversationsPerConversationGroup: Int,
            includesConversationInRecents: Bool,
            supportsVideo: Bool,
            supportedHandleTypes: Set<Handle.Kind>
        ) {
            self.init(
                ringtoneName: ringtoneName,
                iconTemplateImageData: iconTemplateImageData,
                maximumConversationGroups: maximumConversationGroups,
                maximumConversationsPerConversationGroup: maximumConversationsPerConversationGroup,
                includesConversationInRecents: includesConversationInRecents,
                supportsVideo: supportsVideo,
                supportedHandleTypes: supportedHandleTypes,
                supportsAudioTranslation: false
            )
        }

        public init(
            ringtoneName: String?,
            iconTemplateImageData: Data?,
            maximumConversationGroups: Int,
            maximumConversationsPerConversationGroup: Int,
            includesConversationInRecents: Bool,
            supportsVideo: Bool,
            supportedHandleTypes: Set<Handle.Kind>,
            supportsAudioTranslation: Bool
        ) {
            self.ringtoneName = ringtoneName
            self.iconTemplateImageData = iconTemplateImageData
            self.maximumConversationGroups = maximumConversationGroups
            self.maximumConversationsPerConversationGroup = maximumConversationsPerConversationGroup
            self.includesConversationInRecents = includesConversationInRecents
            self.supportsVideo = supportsVideo
            self.supportedHandleTypes = supportedHandleTypes
            self.supportsAudioTranslation = supportsAudioTranslation
        }
    }

    public let configuration: Configuration
    public weak var delegate: (any ConversationManagerDelegate)?

    private let lock = NSLock()
    private var _conversations: [Conversation] = []
    private var _pending: [ConversationAction] = []
    private var invalidated = false

    public var conversations: [Conversation] {
        lock.lock()
        defer { lock.unlock() }
        return _conversations
    }

    public var pendingActions: [ConversationAction] {
        lock.lock()
        defer { lock.unlock() }
        return _pending
    }

    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    public func perform(_ actions: [ConversationAction]) async throws {
        _ = actions
        throw LiveCommunicationKitSupport.unsupported("ConversationManager.perform")
    }

    public func reportNewIncomingConversation(uuid: UUID, update: Conversation.Update) async throws {
        _ = uuid
        _ = update
        throw LiveCommunicationKitSupport.unsupported("ConversationManager.reportNewIncomingConversation")
    }

    public func reportConversationEvent(_ event: Conversation.Event, for conversation: Conversation) {
        conversation.apply(event)
    }

    public class func reportNewIncomingVoIPPushPayload(_ payload: [AnyHashable: Any]) async throws {
        _ = payload
        throw LiveCommunicationKitSupport.unsupported("ConversationManager.reportNewIncomingVoIPPushPayload")
    }

    public func invalidate() {
        lock.lock()
        _conversations = []
        _pending = []
        invalidated = true
        lock.unlock()
        delegate?.conversationManagerDidReset(self)
    }

    public func pendingConversationActions(
        of conversationActionClass: ConversationAction.Type,
        for conversation: Conversation
    ) -> [ConversationAction] {
        lock.lock()
        let snapshot = _pending
        lock.unlock()
        return snapshot.filter { action in
            type(of: action) == conversationActionClass
                && action.conversationUUID == conversation.uuid
        }
    }

    @_spi(OpenUIKitHost)
    public func hostRegisterConversation(_ conversation: Conversation) {
        lock.lock()
        _conversations.append(conversation)
        lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func hostEnqueuePending(_ action: ConversationAction) {
        lock.lock()
        _pending.append(action)
        lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public var hostIsInvalidated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return invalidated
    }
}
