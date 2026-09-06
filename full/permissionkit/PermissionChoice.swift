import Foundation

/// A selectable answer in a `PermissionQuestion`. `approve` and `decline`
/// are the documented static choices; exact Apple localized titles are an
/// oracle question, so Linux uses stable English labels derived from the
/// property names.
public struct PermissionChoice: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = String

    public enum Answer: String, Codable, Hashable, Sendable {
        case approval
        case denial
    }

    public let id: String
    public var title: String
    public var answer: Answer

    public static let approve = PermissionChoice(
        id: "approve",
        title: "Approve",
        answer: .approval
    )

    public static let decline = PermissionChoice(
        id: "decline",
        title: "Decline",
        answer: .denial
    )

    public init(id: String, title: String, answer: Answer) {
        self.id = id
        self.title = title
        self.answer = answer
    }

    public init<S: StringProtocol>(id: String, title: S, answer: Answer) {
        self.init(id: id, title: String(title), answer: answer)
    }

    public static func == (lhs: PermissionChoice, rhs: PermissionChoice) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.answer == rhs.answer
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(answer)
    }
}

extension PermissionChoice.Answer {
    public static func == (a: PermissionChoice.Answer, b: PermissionChoice.Answer) -> Bool {
        switch (a, b) {
        case (.approval, .approval), (.denial, .denial):
            return true
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
