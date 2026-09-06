import Foundation
import PermissionKit

func testPermissionQuestionCommunicationTopicInitializer() {
    let topic = CommunicationTopic(personInformation: [])
    let question = PermissionQuestion(communicationTopic: topic)
    precondition(question.topic.personInformation.isEmpty)
    precondition(question.choices == [.approve, .decline])
}

func testPermissionQuestionHandleInitializer() {
    let handle = CommunicationHandle(value: "+15555550999", kind: .phoneNumber)
    let question = PermissionQuestion(handle: handle)
    precondition(question.topic.personInformation.count == 1)
    precondition(question.topic.personInformation[0].handle == handle)
}

func testPermissionQuestionHandlesInitializer() {
    let handles = [
        CommunicationHandle(value: "a@example.com", kind: .emailAddress),
        CommunicationHandle(value: "b@example.com", kind: .emailAddress)
    ]
    let question = PermissionQuestion(handles: handles)
    precondition(question.topic.personInformation.count == 2)
    precondition(question.topic.personInformation[0].handle.value == "a@example.com")
    precondition(question.topic.personInformation[1].handle.value == "b@example.com")
}

func testPermissionQuestionDefaultChoiceIsApprove() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "x", kind: .custom)
    )
    precondition(question.defaultChoice == .approve)
}

func testPermissionQuestionChoicesAreApproveAndDecline() {
    let question = PermissionQuestion(
        communicationTopic: CommunicationTopic(personInformation: [])
    )
    precondition(question.choices.count == 2)
    precondition(question.choices[0] == .approve)
    precondition(question.choices[1] == .decline)
}

func testPermissionQuestionExpirationDateDefaultsNil() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "exp", kind: .custom)
    )
    precondition(question.expirationDate == nil)
    let deadline = Date(timeIntervalSince1970: 1_800_000_000)
    question.expirationDate = deadline
    precondition(question.expirationDate == deadline)
}

func testPermissionQuestionIDTypealiasIsUUID() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "id", kind: .custom)
    )
    let identifier: PermissionQuestion<CommunicationTopic>.ID = question.id
    precondition(identifier == question.id)
}

func testPermissionQuestionIdentifiableIDStable() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "stable", kind: .custom)
    )
    precondition(question.id == question.id)
}

func testPermissionQuestionCodableRoundTrip() {
    let original = PermissionQuestion(
        handle: CommunicationHandle(value: "round", kind: .emailAddress)
    )
    original.title = "May they contact you?"
    original.subtitle = "Communication Limits"
    let encoded = try! JSONEncoder().encode(original)
    let restored = try! JSONDecoder().decode(
        PermissionQuestion<CommunicationTopic>.self, from: encoded
    )
    precondition(restored.id == original.id)
    precondition(restored.title == "May they contact you?")
    precondition(restored.subtitle == "Communication Limits")
    precondition(restored.choices == original.choices)
    precondition(restored.defaultChoice == original.defaultChoice)
    precondition(restored.topic.personInformation[0].handle.value == "round")
}

func testPermissionQuestionTitleAndSubtitleHostStorage() {
    let question = PermissionQuestion(
        communicationTopic: CommunicationTopic(personInformation: [])
    )
    precondition(question.title.isEmpty)
    precondition(question.subtitle.isEmpty)
    question.title = "Title"
    question.subtitle = "Subtitle"
    precondition(question.title == "Title")
    precondition(question.subtitle == "Subtitle")
}
