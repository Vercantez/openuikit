import Foundation
import PermissionKit

func testCommunicationTopicIDString() {
    precondition(CommunicationTopic.id == "CommunicationTopic")
    let topicID: String = CommunicationTopic.id
    precondition(!topicID.isEmpty)
}

func testCommunicationTopicQuestionTopicConformance() {
    func readID<T: QuestionTopic>(_ type: T.Type) -> String { type.id }
    precondition(readID(CommunicationTopic.self) == CommunicationTopic.id)
}

func testCommunicationTopicPersonInformationDefaults() {
    let handle = CommunicationHandle(value: "+15555550111", kind: .phoneNumber)
    let person = CommunicationTopic.PersonInformation(handle: handle)
    precondition(person.handle == handle)
    precondition(person.nameComponents == nil)
    precondition(person.avatarImage == nil)
}

func testCommunicationTopicPersonInformationStoresHandle() {
    var components = PersonNameComponents()
    components.givenName = "Ada"
    components.familyName = "Lovelace"
    let handle = CommunicationHandle(value: "ada@example.com", kind: .emailAddress)
    let person = CommunicationTopic.PersonInformation(
        handle: handle,
        nameComponents: components,
        avatarImage: nil
    )
    precondition(person.handle.value == "ada@example.com")
    precondition(person.nameComponents?.givenName == "Ada")
    precondition(person.nameComponents?.familyName == "Lovelace")
}

func testCommunicationTopicPersonInformationCodableOmitsAvatar() {
    var components = PersonNameComponents()
    components.nickname = "Al"
    let person = CommunicationTopic.PersonInformation(
        handle: CommunicationHandle(value: "al", kind: .custom),
        nameComponents: components,
        avatarImage: nil
    )
    let encoded = try! JSONEncoder().encode(person)
    let restored = try! JSONDecoder().decode(
        CommunicationTopic.PersonInformation.self, from: encoded
    )
    precondition(restored.handle == person.handle)
    precondition(restored.nameComponents?.nickname == "Al")
    precondition(restored.avatarImage == nil)
}

func testCommunicationTopicInitPersonInformationOnly() {
    let person = CommunicationTopic.PersonInformation(
        handle: CommunicationHandle(value: "1", kind: .phoneNumber)
    )
    let topic = CommunicationTopic(personInformation: [person])
    precondition(topic.personInformation.count == 1)
    precondition(topic.actions.isEmpty)
}

func testCommunicationTopicInitWithActions() {
    let person = CommunicationTopic.PersonInformation(
        handle: CommunicationHandle(value: "2", kind: .emailAddress)
    )
    let topic = CommunicationTopic(
        personInformation: [person],
        actions: [.message, .call]
    )
    precondition(topic.actions.contains(.message))
    precondition(topic.actions.contains(.call))
    precondition(!topic.actions.contains(.videoCall))
}

func testCommunicationTopicCodableRoundTrip() {
    let topic = CommunicationTopic(
        personInformation: [
            CommunicationTopic.PersonInformation(
                handle: CommunicationHandle(value: "c", kind: .custom)
            )
        ],
        actions: [.chat, .connect]
    )
    let encoded = try! JSONEncoder().encode(topic)
    let restored = try! JSONDecoder().decode(CommunicationTopic.self, from: encoded)
    precondition(restored.personInformation.count == 1)
    precondition(restored.personInformation[0].handle.value == "c")
    precondition(restored.actions == [.chat, .connect])
}

func testCommunicationTopicActionCases() {
    let actions: [CommunicationTopic.Action] = [
        .friend, .follow, .beFollowed, .call, .message,
        .videoCall, .audioCall, .communicate, .chat, .connect
    ]
    precondition(actions.count == 10)
    precondition(Set(actions).count == 10)
}

func testCommunicationTopicActionInequality() {
    precondition(CommunicationTopic.Action.friend != .follow)
    precondition(CommunicationTopic.Action.call != .message)
    precondition(CommunicationTopic.Action.videoCall != .audioCall)
    precondition(CommunicationTopic.Action.friend == .friend)
}

func testCommunicationTopicActionHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    CommunicationTopic.Action.connect.hash(into: &hasherA)
    CommunicationTopic.Action.connect.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(CommunicationTopic.Action.chat.hashValue == CommunicationTopic.Action.chat.hashValue)
}

func testCommunicationTopicActionCodableRoundTrip() {
    let encoded = try! JSONEncoder().encode(CommunicationTopic.Action.beFollowed)
    let restored = try! JSONDecoder().decode(CommunicationTopic.Action.self, from: encoded)
    precondition(restored == .beFollowed)
}
