import Foundation
import PermissionKit

func testCommunicationLimitsButtonStoresQuestion() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "button@example.com", kind: .emailAddress)
    )
    let button = CommunicationLimitsButton(question: question) {
        EmptyView()
    }
    precondition(button.question.id == question.id)
    precondition(button.question.topic.personInformation[0].handle.value == "button@example.com")
}

func testCommunicationLimitsButtonBodyIsLabel() {
    let question = PermissionQuestion(
        communicationTopic: CommunicationTopic(personInformation: [])
    )
    let button = CommunicationLimitsButton(question: question) {
        EmptyView()
    }
    _ = button.body
}

func testCommunicationLimitsButtonBodyTypealias() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "body", kind: .custom)
    )
    let button = CommunicationLimitsButton(question: question) {
        EmptyView()
    }
    let _: CommunicationLimitsButton<EmptyView>.Body = button.body
}
