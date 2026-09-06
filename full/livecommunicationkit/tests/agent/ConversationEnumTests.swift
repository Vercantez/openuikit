import Foundation
import LiveCommunicationKit

func testConversationEndedReasonRawValues() {
    precondition(Conversation.EndedReason.failed.rawValue == 0)
    precondition(Conversation.EndedReason.remoteEnded.rawValue == 1)
    precondition(Conversation.EndedReason.unanswered.rawValue == 2)
    precondition(Conversation.EndedReason.joinedElsewhere.rawValue == 3)
    precondition(Conversation.EndedReason.declinedElsewhere.rawValue == 4)
    precondition(Conversation.EndedReason(rawValue: 0) == .failed)
    precondition(Conversation.EndedReason(rawValue: 4) == .declinedElsewhere)
    precondition(Conversation.EndedReason(rawValue: 5) == nil)
    precondition(Conversation.EndedReason.failed != .remoteEnded)
    precondition(Conversation.EndedReason.joinedElsewhere != .declinedElsewhere)
}

func testConversationEndedReasonRawValueTypealias() {
    let raw: Conversation.EndedReason.RawValue = Conversation.EndedReason.unanswered.rawValue
    precondition(raw == 2)
}

func testConversationEndedReasonHashableAndCodable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    Conversation.EndedReason.remoteEnded.hash(into: &hasherA)
    Conversation.EndedReason.remoteEnded.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(Conversation.EndedReason.failed.hashValue == Conversation.EndedReason.failed.hashValue)
    let data = try! JSONEncoder().encode(Conversation.EndedReason.unanswered)
    let restored = try! JSONDecoder().decode(Conversation.EndedReason.self, from: data)
    precondition(restored == .unanswered)
}

func testConversationStateRawValues() {
    precondition(Conversation.State.idle.rawValue == 0)
    precondition(Conversation.State.joining.rawValue == 1)
    precondition(Conversation.State.joined.rawValue == 2)
    precondition(Conversation.State.paused.rawValue == 3)
    precondition(Conversation.State.leaving.rawValue == 4)
    precondition(Conversation.State.left.rawValue == 5)
    precondition(Conversation.State(rawValue: 0) == .idle)
    precondition(Conversation.State(rawValue: 5) == .left)
    precondition(Conversation.State(rawValue: 6) == nil)
    precondition(Conversation.State.idle != .joined)
    precondition(Conversation.State.joining != .leaving)
}

func testConversationStateRawValueTypealias() {
    let raw: Conversation.State.RawValue = Conversation.State.paused.rawValue
    precondition(raw == 3)
}

func testConversationStateHashableAndCodable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    Conversation.State.joined.hash(into: &hasherA)
    Conversation.State.joined.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(Conversation.State.left.hashValue == Conversation.State.left.hashValue)
    let data = try! JSONEncoder().encode(Conversation.State.joining)
    let restored = try! JSONDecoder().decode(Conversation.State.self, from: data)
    precondition(restored == .joining)
}

func testPlayToneActionToneRawValues() {
    precondition(PlayToneAction.Tone.single.rawValue == 0)
    precondition(PlayToneAction.Tone.softPause.rawValue == 1)
    precondition(PlayToneAction.Tone.hardPause.rawValue == 2)
    precondition(PlayToneAction.Tone(rawValue: 0) == .single)
    precondition(PlayToneAction.Tone(rawValue: 2) == .hardPause)
    precondition(PlayToneAction.Tone(rawValue: 3) == nil)
    precondition(PlayToneAction.Tone.single != .softPause)
    precondition(PlayToneAction.Tone.softPause != .hardPause)
}

func testPlayToneActionToneRawValueTypealias() {
    let raw: PlayToneAction.Tone.RawValue = PlayToneAction.Tone.hardPause.rawValue
    precondition(raw == 2)
}

func testPlayToneActionToneHashableAndCodable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    PlayToneAction.Tone.softPause.hash(into: &hasherA)
    PlayToneAction.Tone.softPause.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(PlayToneAction.Tone.single.hashValue == PlayToneAction.Tone.single.hashValue)
    let data = try! JSONEncoder().encode(PlayToneAction.Tone.hardPause)
    let restored = try! JSONDecoder().decode(PlayToneAction.Tone.self, from: data)
    precondition(restored == .hardPause)
}

func testTranslationEngineCasesAndInequality() {
    precondition(SetTranslatingAction.TranslationEngine.default != .custom)
    precondition(SetTranslatingAction.TranslationEngine.custom == .custom)
    precondition(SetTranslatingAction.TranslationEngine.default == .default)
}

func testTranslationEngineHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    SetTranslatingAction.TranslationEngine.custom.hash(into: &hasherA)
    SetTranslatingAction.TranslationEngine.custom.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        SetTranslatingAction.TranslationEngine.default.hashValue
            == SetTranslatingAction.TranslationEngine.default.hashValue
    )
}

func testRecentConversationStatusCases() {
    precondition(
        ConversationHistoryManager.RecentConversation.Status.connected != .missed
    )
    precondition(
        ConversationHistoryManager.RecentConversation.Status.missed != .answeredElsewhere
    )
    precondition(
        ConversationHistoryManager.RecentConversation.Status.cancelled != .unknown
    )
    precondition(
        ConversationHistoryManager.RecentConversation.Status.unknown == .unknown
    )
}

func testRecentConversationStatusHashableAndCodable() {
    var hasher = Hasher()
    ConversationHistoryManager.RecentConversation.Status.missed.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        ConversationHistoryManager.RecentConversation.Status.connected.hashValue
            == ConversationHistoryManager.RecentConversation.Status.connected.hashValue
    )
    let data = try! JSONEncoder().encode(
        ConversationHistoryManager.RecentConversation.Status.answeredElsewhere
    )
    let restored = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.Status.self,
        from: data
    )
    precondition(restored == .answeredElsewhere)
}

func testRecentConversationDirectionCases() {
    precondition(
        ConversationHistoryManager.RecentConversation.Direction.outgoing != .incoming
    )
    precondition(
        ConversationHistoryManager.RecentConversation.Direction.incoming == .incoming
    )
}

func testRecentConversationDirectionHashableAndCodable() {
    var hasher = Hasher()
    ConversationHistoryManager.RecentConversation.Direction.incoming.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        ConversationHistoryManager.RecentConversation.Direction.outgoing.hashValue
            == ConversationHistoryManager.RecentConversation.Direction.outgoing.hashValue
    )
    let data = try! JSONEncoder().encode(
        ConversationHistoryManager.RecentConversation.Direction.outgoing
    )
    let restored = try! JSONDecoder().decode(
        ConversationHistoryManager.RecentConversation.Direction.self,
        from: data
    )
    precondition(restored == .outgoing)
}
