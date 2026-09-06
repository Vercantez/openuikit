import Foundation
import PermissionKit

func testPermissionResponseStoresQuestionAndChoice() {
    let question = PermissionQuestion(
        handle: CommunicationHandle(value: "resp@example.com", kind: .emailAddress)
    )
    let response = PermissionResponse(question: question, choice: .decline)
    precondition(response.question.id == question.id)
    precondition(response.choice == .decline)
    precondition(response.question.topic.personInformation[0].handle.value == "resp@example.com")
}
