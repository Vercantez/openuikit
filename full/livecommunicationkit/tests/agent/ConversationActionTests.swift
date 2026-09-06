import Foundation
@_spi(OpenUIKitHost) import LiveCommunicationKit

func testConversationActionInitTimeoutAndUUID() {
    let conversationUUID = UUID()
    let before = Date()
    let action = ConversationAction(conversationUUID: conversationUUID)
    let after = Date()
    precondition(action.conversationUUID == conversationUUID)
    precondition(action.uuid != conversationUUID)
    precondition(action.state == .idle)
    let interval = action.timeoutDate.timeIntervalSince(before)
    precondition(interval >= 29)
    precondition(action.timeoutDate.timeIntervalSince(after) <= 31)
}

func testConversationActionExplicitTimeoutDate() {
    let date = Date(timeIntervalSince1970: 1_234)
    let action = ConversationAction(conversationUUID: UUID(), timeoutDate: date)
    precondition(action.timeoutDate == date)
}

func testConversationActionFulfillTransitionsToComplete() {
    let action = ConversationAction(conversationUUID: UUID())
    precondition(action.state == .idle)
    action.fulfill()
    precondition(action.state == .complete)
    action.fulfill()
    precondition(action.state == .complete)
    action.fail()
    precondition(action.state == .complete)
}

func testConversationActionFailTransitionsToFailed() {
    let action = ConversationAction(conversationUUID: UUID())
    action.fail()
    precondition(action.state == .failed(reason: ""))
    action.fail()
    precondition(action.state == .failed(reason: ""))
    action.fulfill()
    precondition(action.state == .failed(reason: ""))
}

func testConversationActionStateEquality() {
    precondition(ConversationAction.State.idle == .idle)
    precondition(ConversationAction.State.running == .running)
    precondition(ConversationAction.State.complete == .complete)
    precondition(ConversationAction.State.failed(reason: "x") == .failed(reason: "x"))
    precondition(ConversationAction.State.idle != .running)
    precondition(ConversationAction.State.failed(reason: "a") != .failed(reason: "b"))
    precondition(ConversationAction.State.complete != .failed(reason: ""))
}

func testConversationActionStateHashableAndCodable() {
    let state = ConversationAction.State.failed(reason: "timeout")
    var hasherA = Hasher()
    var hasherB = Hasher()
    state.hash(into: &hasherA)
    state.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(ConversationAction.State.idle.hashValue == ConversationAction.State.idle.hashValue)
    let data = try! JSONEncoder().encode(state)
    let restored = try! JSONDecoder().decode(ConversationAction.State.self, from: data)
    precondition(restored == state)
    let runningData = try! JSONEncoder().encode(ConversationAction.State.running)
    let running = try! JSONDecoder().decode(ConversationAction.State.self, from: runningData)
    precondition(running == .running)
}

func testPlayToneActionStoresDigitsAndTone() {
    let uuid = UUID()
    let action = PlayToneAction(conversationUUID: uuid, digits: "123#", tone: .softPause)
    precondition(action.conversationUUID == uuid)
    precondition(action.digits == "123#")
    precondition(action.tone == .softPause)
    precondition(action.state == .idle)
    action.fulfill()
    precondition(action.state == .complete)
}

func testMuteConversationActionStoresMutedFlag() {
    let action = MuteConversationAction(conversationUUID: UUID(), isMuted: true)
    precondition(action.isMuted)
    let unmuted = MuteConversationAction(conversationUUID: UUID(), isMuted: false)
    precondition(!unmuted.isMuted)
}

func testPauseConversationActionStoresPausedFlag() {
    let paused = PauseConversationAction(conversationUUID: UUID(), isPaused: true)
    precondition(paused.isPaused)
    let resumed = PauseConversationAction(conversationUUID: UUID(), isPaused: false)
    precondition(!resumed.isPaused)
}

func testMergeConversationActionStoresPeerUUID() {
    let a = UUID()
    let b = UUID()
    let action = MergeConversationAction(conversationUUID: a, conversationUUIDToMergeWith: b)
    precondition(action.conversationUUID == a)
    precondition(action.conversationUUIDToMergeWith == b)
}

func testUnmergeConversationActionInit() {
    let uuid = UUID()
    let action = UnmergeConversationAction(conversationUUID: uuid)
    precondition(action.conversationUUID == uuid)
    action.fulfill()
    precondition(action.state == .complete)
}

func testJoinConversationActionFulfillDateConnected() {
    let action = JoinConversationAction(conversationUUID: UUID())
    let date = Date(timeIntervalSince1970: 9)
    action.fulfill(dateConnected: date)
    precondition(action.state == .complete)
    precondition(LiveCommunicationKitHost.dateConnected(on: action) == date)
}

func testEndConversationActionFulfillDateEnded() {
    let action = EndConversationAction(conversationUUID: UUID())
    let date = Date(timeIntervalSince1970: 10)
    action.fulfill(dateEnded: date)
    precondition(action.state == .complete)
    precondition(LiveCommunicationKitHost.dateEnded(on: action) == date)
}

func testStartConversationActionStoresHandlesAndVideo() {
    let handles = [Handle(type: .phoneNumber, value: "+1")]
    let action = StartConversationAction(
        conversationUUID: UUID(),
        handles: handles,
        isVideo: true
    )
    precondition(action.handles == handles)
    precondition(action.isVideo)
    let started = Date(timeIntervalSince1970: 11)
    action.fulfill(dateStarted: started)
    precondition(action.state == .complete)
    precondition(LiveCommunicationKitHost.dateStarted(on: action) == started)
}

func testSetTranslatingActionStoresLanguages() {
    let local = Locale.Language(identifier: "en")
    let remote = Locale.Language(identifier: "es")
    let uuid = UUID()
    let action = SetTranslatingAction(
        conversationID: uuid,
        isTranslating: true,
        localLanguage: local,
        remoteLanguage: remote
    )
    precondition(action.conversationUUID == uuid)
    precondition(action.isTranslating)
    precondition(action.localLanguage == local)
    precondition(action.remoteLanguage == remote)
}

func testSetTranslatingActionFulfillUsingEngine() {
    let language = Locale.Language(identifier: "fr")
    let action = SetTranslatingAction(
        conversationID: UUID(),
        isTranslating: false,
        localLanguage: language,
        remoteLanguage: language
    )
    action.fulfill(using: .custom)
    precondition(action.state == .complete)
    precondition(LiveCommunicationKitHost.translationEngine(on: action) == .custom)
}
