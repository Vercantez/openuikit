import Foundation

/// A recorded answer to a `PermissionQuestion`. Linux never produces this
/// from `CommunicationLimits.ask`; tests construct it directly.
public struct PermissionResponse<Topic: QuestionTopic> {
    public let question: PermissionQuestion<Topic>
    public let choice: PermissionChoice

    public init(question: PermissionQuestion<Topic>, choice: PermissionChoice) {
        self.question = question
        self.choice = choice
    }
}
