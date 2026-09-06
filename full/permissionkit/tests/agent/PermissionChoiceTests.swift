import Foundation
import PermissionKit

func testPermissionChoiceApproveStatic() {
    let choice = PermissionChoice.approve
    precondition(choice.id == "approve")
    precondition(choice.title == "Approve")
    precondition(choice.answer == .approval)
}

func testPermissionChoiceDeclineStatic() {
    let choice = PermissionChoice.decline
    precondition(choice.id == "decline")
    precondition(choice.title == "Decline")
    precondition(choice.answer == .denial)
}

func testPermissionChoiceApproveNotEqualDecline() {
    precondition(PermissionChoice.approve != PermissionChoice.decline)
    precondition(!(PermissionChoice.approve == PermissionChoice.decline))
}

func testPermissionChoiceIDTypealias() {
    let identifier: PermissionChoice.ID = PermissionChoice.approve.id
    precondition(identifier == "approve")
}

func testPermissionChoiceTitleMutation() {
    var choice = PermissionChoice.approve
    choice.title = "Allow"
    precondition(choice.title == "Allow")
    precondition(choice.id == "approve")
    precondition(choice.answer == .approval)
}

func testPermissionChoiceAnswerMutation() {
    var choice = PermissionChoice.approve
    choice.answer = .denial
    precondition(choice.answer == .denial)
}

func testPermissionChoiceHashableConsistency() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    PermissionChoice.approve.hash(into: &hasherA)
    PermissionChoice.approve.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(PermissionChoice.approve.hashValue == PermissionChoice.approve.hashValue)
}

func testPermissionChoiceCodableRoundTrip() {
    let encoded = try! JSONEncoder().encode(PermissionChoice.decline)
    let restored = try! JSONDecoder().decode(PermissionChoice.self, from: encoded)
    precondition(restored == PermissionChoice.decline)
}

func testPermissionChoiceAnswerApprovalAndDenial() {
    let cases: [PermissionChoice.Answer] = [.approval, .denial]
    precondition(cases.count == 2)
    precondition(PermissionChoice.Answer.approval != PermissionChoice.Answer.denial)
}

func testPermissionChoiceAnswerInequality() {
    precondition(PermissionChoice.Answer.approval != .denial)
    precondition(PermissionChoice.Answer.denial != .approval)
    precondition(PermissionChoice.Answer.approval == .approval)
}

func testPermissionChoiceAnswerHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    PermissionChoice.Answer.denial.hash(into: &hasherA)
    PermissionChoice.Answer.denial.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(PermissionChoice.Answer.approval.hashValue == PermissionChoice.Answer.approval.hashValue)
}

func testPermissionChoiceAnswerCodableRoundTrip() {
    let encoded = try! JSONEncoder().encode(PermissionChoice.Answer.approval)
    let restored = try! JSONDecoder().decode(PermissionChoice.Answer.self, from: encoded)
    precondition(restored == .approval)
}

func testPermissionChoiceStringProtocolInit() {
    let choice = PermissionChoice(id: "custom", title: Substring("Maybe"), answer: .approval)
    precondition(choice.id == "custom")
    precondition(choice.title == "Maybe")
    precondition(choice.answer == .approval)
}
