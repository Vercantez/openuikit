import Foundation
@_spi(OpenUIKitHost) import LiveCommunicationKit

private final class ManagerDelegateProbe: ConversationManagerDelegate {
    var began = 0
    var reset = 0
    var changed = 0
    var performed = 0
    var timedOut = 0
    var activated = 0
    var deactivated = 0
    var lastConversation: Conversation?
    var lastAction: ConversationAction?

    func conversationManager(_ manager: ConversationManager, conversationChanged conversation: Conversation) {
        _ = manager
        changed += 1
        lastConversation = conversation
    }

    func conversationManagerDidBegin(_ manager: ConversationManager) {
        _ = manager
        began += 1
    }

    func conversationManagerDidReset(_ manager: ConversationManager) {
        _ = manager
        reset += 1
    }

    func conversationManager(_ manager: ConversationManager, perform action: ConversationAction) {
        _ = manager
        performed += 1
        lastAction = action
    }

    func conversationManager(_ manager: ConversationManager, timedOutPerforming action: ConversationAction) {
        _ = manager
        timedOut += 1
        lastAction = action
    }

    func conversationManager(_ manager: ConversationManager, didActivate audioSession: AVAudioSession) {
        _ = manager
        _ = audioSession
        activated += 1
    }

    func conversationManager(_ manager: ConversationManager, didDeactivate audioSession: AVAudioSession) {
        _ = manager
        _ = audioSession
        deactivated += 1
    }
}

private func sampleConfiguration(
    translation: Bool = false
) -> ConversationManager.Configuration {
    ConversationManager.Configuration(
        ringtoneName: "ringtone",
        iconTemplateImageData: Data([0x01]),
        maximumConversationGroups: 2,
        maximumConversationsPerConversationGroup: 5,
        includesConversationInRecents: true,
        supportsVideo: true,
        supportedHandleTypes: [.phoneNumber, .emailAddress],
        supportsAudioTranslation: translation
    )
}

func testConfigurationInitWithoutAudioTranslationDefaultsFalse() {
    let configuration = ConversationManager.Configuration(
        ringtoneName: nil,
        iconTemplateImageData: nil,
        maximumConversationGroups: 1,
        maximumConversationsPerConversationGroup: 1,
        includesConversationInRecents: false,
        supportsVideo: false,
        supportedHandleTypes: [.generic]
    )
    precondition(configuration.ringtoneName == nil)
    precondition(configuration.iconTemplateImageData == nil)
    precondition(configuration.maximumConversationGroups == 1)
    precondition(configuration.maximumConversationsPerConversationGroup == 1)
    precondition(!configuration.includesConversationInRecents)
    precondition(!configuration.supportsVideo)
    precondition(configuration.supportedHandleTypes == [.generic])
    precondition(!configuration.supportsAudioTranslation)
}

func testConfigurationInitWithAudioTranslation() {
    let data = Data([0xAA, 0xBB])
    var configuration = sampleConfiguration(translation: true)
    precondition(configuration.ringtoneName == "ringtone")
    precondition(configuration.iconTemplateImageData == data || configuration.iconTemplateImageData == Data([0x01]))
    precondition(configuration.supportsAudioTranslation)
    configuration.supportsAudioTranslation = false
    configuration.supportsVideo = false
    configuration.ringtoneName = nil
    configuration.maximumConversationGroups = 3
    configuration.maximumConversationsPerConversationGroup = 4
    configuration.includesConversationInRecents = false
    configuration.supportedHandleTypes = [.generic]
    configuration.iconTemplateImageData = data
    precondition(!configuration.supportsAudioTranslation)
    precondition(!configuration.supportsVideo)
    precondition(configuration.ringtoneName == nil)
    precondition(configuration.maximumConversationGroups == 3)
    precondition(configuration.maximumConversationsPerConversationGroup == 4)
    precondition(!configuration.includesConversationInRecents)
    precondition(configuration.supportedHandleTypes == [.generic])
    precondition(configuration.iconTemplateImageData == data)
}

func testConversationManagerInitStoresConfigurationAndEmptyLists() {
    let configuration = sampleConfiguration()
    let manager = ConversationManager(configuration: configuration)
    precondition(manager.configuration.supportsVideo)
    precondition(manager.conversations.isEmpty)
    precondition(manager.pendingActions.isEmpty)
    precondition(manager.delegate == nil)
}

func testConversationManagerDelegateAssignment() {
    let manager = ConversationManager(configuration: sampleConfiguration())
    let probe = ManagerDelegateProbe()
    manager.delegate = probe
    precondition(manager.delegate === probe)
    manager.delegate = nil
    precondition(manager.delegate == nil)
}

func testConversationManagerInvalidateClearsStateAndNotifiesReset() {
    let manager = ConversationManager(configuration: sampleConfiguration())
    let probe = ManagerDelegateProbe()
    manager.delegate = probe
    let conversation = LiveCommunicationKitHost.conversation()
    manager.hostRegisterConversation(conversation)
    manager.hostEnqueuePending(ConversationAction(conversationUUID: conversation.uuid))
    precondition(manager.conversations.count == 1)
    precondition(manager.pendingActions.count == 1)
    manager.invalidate()
    precondition(manager.conversations.isEmpty)
    precondition(manager.pendingActions.isEmpty)
    precondition(manager.hostIsInvalidated)
    precondition(probe.reset == 1)
    precondition(probe.began == 0)
    precondition(probe.activated == 0)
    precondition(probe.deactivated == 0)
}

func testPendingConversationActionsFiltersByClassAndConversation() {
    let manager = ConversationManager(configuration: sampleConfiguration())
    let conversation = LiveCommunicationKitHost.conversation()
    let other = LiveCommunicationKitHost.conversation()
    let join = JoinConversationAction(conversationUUID: conversation.uuid)
    let mute = MuteConversationAction(conversationUUID: conversation.uuid, isMuted: true)
    let otherJoin = JoinConversationAction(conversationUUID: other.uuid)
    manager.hostEnqueuePending(join)
    manager.hostEnqueuePending(mute)
    manager.hostEnqueuePending(otherJoin)
    let pendingJoin = manager.pendingConversationActions(of: JoinConversationAction.self, for: conversation)
    precondition(pendingJoin.count == 1)
    precondition(pendingJoin.first === join)
    let pendingMute = manager.pendingConversationActions(of: MuteConversationAction.self, for: conversation)
    precondition(pendingMute.count == 1)
    precondition(pendingMute.first === mute)
    let pendingEnd = manager.pendingConversationActions(of: EndConversationAction.self, for: conversation)
    precondition(pendingEnd.isEmpty)
}

func testConversationManagerDelegateProtocolSurface() {
    let manager = ConversationManager(configuration: sampleConfiguration())
    let probe = ManagerDelegateProbe()
    let conversation = LiveCommunicationKitHost.conversation()
    let action = ConversationAction(conversationUUID: conversation.uuid)
    let session = AVAudioSession()
    probe.conversationManagerDidBegin(manager)
    probe.conversationManager(manager, conversationChanged: conversation)
    probe.conversationManager(manager, perform: action)
    probe.conversationManager(manager, timedOutPerforming: action)
    probe.conversationManager(manager, didActivate: session)
    probe.conversationManager(manager, didDeactivate: session)
    probe.conversationManagerDidReset(manager)
    precondition(probe.began == 1)
    precondition(probe.changed == 1)
    precondition(probe.performed == 1)
    precondition(probe.timedOut == 1)
    precondition(probe.activated == 1)
    precondition(probe.deactivated == 1)
    precondition(probe.reset == 1)
    precondition(probe.lastConversation === conversation)
    precondition(probe.lastAction === action)
    _ = type(of: session) == AVAudioSession.self
}
