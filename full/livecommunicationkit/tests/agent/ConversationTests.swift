import Foundation
@_spi(OpenUIKitHost) import LiveCommunicationKit

func testConversationUpdateDefaultInit() {
    let update = Conversation.Update()
    precondition(update.localMember == nil)
    precondition(update.members == nil)
    precondition(update.activeRemoteMembers == nil)
    precondition(update.capabilities == nil)
}

func testConversationUpdateStoresFields() {
    let handle = Handle(type: .phoneNumber, value: "+1")
    var update = Conversation.Update(
        localMember: handle,
        members: [handle],
        activeRemoteMembers: [handle],
        capabilities: .video
    )
    precondition(update.localMember == handle)
    precondition(update.members == [handle])
    precondition(update.activeRemoteMembers == [handle])
    precondition(update.capabilities == .video)
    update.localMember = nil
    precondition(update.localMember == nil)
    update.members = []
    precondition(update.members?.isEmpty == true)
    update.activeRemoteMembers = []
    precondition(update.activeRemoteMembers?.isEmpty == true)
    update.capabilities = .pausing
    precondition(update.capabilities == .pausing)
}

func testConversationUpdateEquality() {
    let handle = Handle(type: .generic, value: "x")
    let a = Conversation.Update(localMember: handle, capabilities: .video)
    let b = Conversation.Update(localMember: handle, capabilities: .video)
    let c = Conversation.Update(localMember: handle, capabilities: .merging)
    precondition(a == b)
    precondition(a != c)
}

func testConversationUpdateHashableAndCodable() {
    let original = Conversation.Update(
        members: [Handle(type: .emailAddress, value: "a@b.c")],
        capabilities: [.video, .pausing]
    )
    var hasherA = Hasher()
    var hasherB = Hasher()
    original.hash(into: &hasherA)
    original.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(original.hashValue == original.hashValue)
    let data = try! JSONEncoder().encode(original)
    let restored = try! JSONDecoder().decode(Conversation.Update.self, from: data)
    precondition(restored == original)
}

func testConversationEventCasesAndEquality() {
    let now = Date(timeIntervalSince1970: 100)
    let update = Conversation.Update(capabilities: .video)
    let a = Conversation.Event.conversationUpdated(update)
    let b = Conversation.Event.conversationUpdated(update)
    let started = Conversation.Event.conversationStartedConnecting(now)
    let connected = Conversation.Event.conversationConnected(now)
    let ended = Conversation.Event.conversationEnded(now, .remoteEnded)
    precondition(a == b)
    precondition(a != started)
    precondition(started != connected)
    precondition(connected != ended)
    precondition(ended != a)
}

func testConversationEventHashableAndCodable() {
    let event = Conversation.Event.conversationEnded(
        Date(timeIntervalSince1970: 50),
        .unanswered
    )
    var hasherA = Hasher()
    var hasherB = Hasher()
    event.hash(into: &hasherA)
    event.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(event.hashValue == event.hashValue)
    let data = try! JSONEncoder().encode(event)
    let restored = try! JSONDecoder().decode(Conversation.Event.self, from: data)
    precondition(restored == event)
}

func testConversationHostProperties() {
    let uuid = UUID()
    let member = Handle(type: .phoneNumber, value: "+1555")
    let conversation = LiveCommunicationKitHost.conversation(
        uuid: uuid,
        state: .idle,
        localMember: member
    )
    precondition(conversation.uuid == uuid)
    precondition(conversation.state == .idle)
    precondition(conversation.localMember == member)
    precondition(type(of: conversation) == Conversation.self)
}

func testConversationDebugDescriptionContainsUUIDAndState() {
    let uuid = UUID()
    let conversation = LiveCommunicationKitHost.conversation(uuid: uuid, state: .joined)
    precondition(conversation.debugDescription.contains(uuid.uuidString))
    precondition(conversation.debugDescription.contains("joined"))
}

func testConversationEventStartedConnectingSetsJoining() {
    let conversation = LiveCommunicationKitHost.conversation(state: .idle)
    let manager = ConversationManager(
        configuration: ConversationManager.Configuration(
            ringtoneName: nil,
            iconTemplateImageData: nil,
            maximumConversationGroups: 1,
            maximumConversationsPerConversationGroup: 1,
            includesConversationInRecents: false,
            supportsVideo: false,
            supportedHandleTypes: []
        )
    )
    manager.reportConversationEvent(
        .conversationStartedConnecting(Date(timeIntervalSince1970: 1)),
        for: conversation
    )
    precondition(conversation.state == .joining)
}

func testConversationEventConnectedSetsJoined() {
    let conversation = LiveCommunicationKitHost.conversation(state: .joining)
    let manager = ConversationManager(
        configuration: ConversationManager.Configuration(
            ringtoneName: nil,
            iconTemplateImageData: nil,
            maximumConversationGroups: 1,
            maximumConversationsPerConversationGroup: 1,
            includesConversationInRecents: false,
            supportsVideo: false,
            supportedHandleTypes: []
        )
    )
    manager.reportConversationEvent(
        .conversationConnected(Date(timeIntervalSince1970: 2)),
        for: conversation
    )
    precondition(conversation.state == .joined)
}

func testConversationEventEndedSetsLeft() {
    let conversation = LiveCommunicationKitHost.conversation(state: .joined)
    let manager = ConversationManager(
        configuration: ConversationManager.Configuration(
            ringtoneName: nil,
            iconTemplateImageData: nil,
            maximumConversationGroups: 1,
            maximumConversationsPerConversationGroup: 1,
            includesConversationInRecents: false,
            supportsVideo: false,
            supportedHandleTypes: []
        )
    )
    manager.reportConversationEvent(
        .conversationEnded(Date(timeIntervalSince1970: 3), .remoteEnded),
        for: conversation
    )
    precondition(conversation.state == .left)
}

func testConversationEventUpdatedAppliesLocalMember() {
    let conversation = LiveCommunicationKitHost.conversation(state: .idle)
    let member = Handle(type: .generic, value: "me")
    let manager = ConversationManager(
        configuration: ConversationManager.Configuration(
            ringtoneName: nil,
            iconTemplateImageData: nil,
            maximumConversationGroups: 1,
            maximumConversationsPerConversationGroup: 1,
            includesConversationInRecents: false,
            supportsVideo: false,
            supportedHandleTypes: []
        )
    )
    manager.reportConversationEvent(
        .conversationUpdated(Conversation.Update(localMember: member, capabilities: .video)),
        for: conversation
    )
    precondition(conversation.localMember == member)
}
