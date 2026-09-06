import Foundation
import AVKit

func testVideoFrameAnalysisIsDisjoint() {
    precondition(AVVideoFrameAnalysisType.text.isDisjoint(with: .subject))
    precondition(!AVVideoFrameAnalysisType.text.isDisjoint(with: .text))
}

func testVideoFrameAnalysisIsSuperset() {
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(combined.isSuperset(of: .text))
    precondition(!AVVideoFrameAnalysisType.text.isSuperset(of: combined))
}

func testVideoFrameAnalysisSubtracting() {
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    let subtracted = combined.subtracting(.text)
    precondition(subtracted.contains(.subject))
    precondition(!subtracted.contains(.text))
}

func testVideoFrameAnalysisIsStrictSubset() {
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(AVVideoFrameAnalysisType.text.isStrictSubset(of: combined))
    precondition(!combined.isStrictSubset(of: combined))
}

func testVideoFrameAnalysisIsStrictSuperset() {
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(combined.isStrictSuperset(of: .text))
    precondition(!combined.isStrictSuperset(of: combined))
}

func testVideoFrameAnalysisIsSubset() {
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(AVVideoFrameAnalysisType.text.isSubset(of: combined))
    precondition(!combined.isSubset(of: .text))
}

func testVideoFrameAnalysisSubtract() {
    var combined: AVVideoFrameAnalysisType = [.text, .subject]
    combined.subtract(.text)
    precondition(!combined.contains(.text))
    precondition(combined.contains(.subject))
}

func testVideoFrameAnalysisInitSequence() {
    let types = AVVideoFrameAnalysisType([AVVideoFrameAnalysisType.text, .subject, .text])
    precondition(types.contains(.text))
    precondition(types.contains(.subject))
    precondition(!types.contains(.visualSearch))
}

func testVideoFrameAnalysisInsert() {
    var types = AVVideoFrameAnalysisType()
    let first = types.insert(.text)
    precondition(first.inserted)
    precondition(first.memberAfterInsert == .text)
    let again = types.insert(.text)
    precondition(!again.inserted)
}

func testVideoFrameAnalysisRemove() {
    var types: AVVideoFrameAnalysisType = [.text, .subject]
    let removed = types.remove(.text)
    precondition(removed == .text)
    precondition(!types.contains(.text))
    precondition(types.remove(.visualSearch) == nil)
}

func testVideoFrameAnalysisIntersection() {
    let left: AVVideoFrameAnalysisType = [.text, .subject]
    let right: AVVideoFrameAnalysisType = [.subject, .visualSearch]
    let overlap = left.intersection(right)
    precondition(overlap == .subject)
}

func testVideoFrameAnalysisSymmetricDifference() {
    let left: AVVideoFrameAnalysisType = [.text, .subject]
    let right: AVVideoFrameAnalysisType = [.subject, .visualSearch]
    let difference = left.symmetricDifference(right)
    precondition(difference.contains(.text))
    precondition(difference.contains(.visualSearch))
    precondition(!difference.contains(.subject))
}

func testVideoFrameAnalysisFormIntersection() {
    var types: AVVideoFrameAnalysisType = [.text, .subject]
    types.formIntersection([.subject, .visualSearch])
    precondition(types == .subject)
}

func testVideoFrameAnalysisFormSymmetricDifference() {
    var types: AVVideoFrameAnalysisType = [.text, .subject]
    types.formSymmetricDifference([.subject, .visualSearch])
    precondition(types.contains(.text))
    precondition(types.contains(.visualSearch))
    precondition(!types.contains(.subject))
}

func testVideoFrameAnalysisFormUnion() {
    var types: AVVideoFrameAnalysisType = [.text]
    types.formUnion(.subject)
    precondition(types.contains(.text))
    precondition(types.contains(.subject))
}

func testVideoFrameAnalysisUnion() {
    let combined = AVVideoFrameAnalysisType.text.union(.subject)
    precondition(combined.contains(.text))
    precondition(combined.contains(.subject))
}

func testVideoFrameAnalysisContains() {
    let combined: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(combined.contains(.text))
    precondition(!combined.contains(.visualSearch))
}

func testVideoFrameAnalysisUpdate() {
    var types: AVVideoFrameAnalysisType = [.text]
    let missing = types.update(with: .subject)
    precondition(missing == nil)
    precondition(types.contains(.subject))
    let existing = types.update(with: .subject)
    precondition(existing == .subject)
}

func testVideoFrameAnalysisIsEmpty() {
    precondition(AVVideoFrameAnalysisType().isEmpty)
    precondition(!AVVideoFrameAnalysisType.text.isEmpty)
}

func testVideoFrameAnalysisInitArrayLiteral() {
    let types: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(types.contains(.text))
    precondition(types.contains(.subject))
}

func testVideoFrameAnalysisInitEmpty() {
    let types = AVVideoFrameAnalysisType()
    precondition(types.rawValue == 0)
    precondition(types.isEmpty)
}

func testVideoFrameAnalysisInitRawValue() {
    let types = AVVideoFrameAnalysisType(rawValue: 1 << 1)
    precondition(types == .text)
}

func testVideoFrameAnalysisNotEqual() {
    precondition(AVVideoFrameAnalysisType.text != .subject)
}
