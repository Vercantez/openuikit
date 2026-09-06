import Foundation
import Assignables

func testCorrectMarkTypeCases() {
    let cases: [AssignableDocument.CorrectMarkType] = [
        .checkmark, .star, .numeric, .unknown,
    ]
    assignablesExpect(
        AssignableDocument.CorrectMarkType.allCases == cases,
        "allCases digester order"
    )
    assignablesExpect(AssignableDocument.CorrectMarkType.checkmark.id == .checkmark, "id")
    assignablesExpect(AssignableDocument.CorrectMarkType.star.debugDescription == "star", "star desc")
    assignablesExpect(AssignableDocument.CorrectMarkType.numeric.debugDescription == "numeric", "numeric desc")
    assignablesExpect(AssignableDocument.CorrectMarkType.unknown.debugDescription == "unknown", "unknown desc")
    assignablesExpect(AssignableDocument.CorrectMarkType.checkmark.debugDescription == "checkmark", "check desc")
    assignablesExpect(AssignableDocument.CorrectMarkType.checkmark != .star, "neq")
    assignablesExpect(AssignableDocument.CorrectMarkType.checkmark == .checkmark, "eq")
    _ = AssignableDocument.CorrectMarkType.star.hashValue
    var hasher = Hasher()
    AssignableDocument.CorrectMarkType.numeric.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignableDocument.CorrectMarkType.ID = AssignableDocument.CorrectMarkType.checkmark
    let _: AssignableDocument.CorrectMarkType.AllCases = AssignableDocument.CorrectMarkType.allCases
}

func testScoreAnnotationKindRawValues() {
    let cases: [(AssignedWorkDocument.ScoreAnnotation.Kind, Int)] = [
        (.unknown, 0), (.incorrect, 1), (.correct, 2), (.bonus, 3),
    ]
    for (value, raw) in cases {
        assignablesExpect(value.rawValue == raw, "raw \(raw)")
        assignablesExpect(
            AssignedWorkDocument.ScoreAnnotation.Kind(rawValue: raw) == value,
            "init \(raw)"
        )
    }
    assignablesExpect(AssignedWorkDocument.ScoreAnnotation.Kind(rawValue: 99) == nil, "invalid")
    assignablesExpect(
        AssignedWorkDocument.ScoreAnnotation.Kind.allCases == [.unknown, .incorrect, .correct, .bonus],
        "allCases"
    )
    assignablesExpect(
        AssignedWorkDocument.ScoreAnnotation.Kind.unknown.debugDescription == "unknown",
        "unknown desc"
    )
    assignablesExpect(
        AssignedWorkDocument.ScoreAnnotation.Kind.incorrect.debugDescription == "incorrect",
        "incorrect desc"
    )
    assignablesExpect(
        AssignedWorkDocument.ScoreAnnotation.Kind.correct.debugDescription == "correct",
        "correct desc"
    )
    assignablesExpect(
        AssignedWorkDocument.ScoreAnnotation.Kind.bonus.debugDescription == "bonus",
        "bonus desc"
    )
    assignablesExpect(
        AssignedWorkDocument.ScoreAnnotation.Kind.correct != .bonus,
        "kind neq"
    )
    _ = AssignedWorkDocument.ScoreAnnotation.Kind.correct.hashValue
    var hasher = Hasher()
    AssignedWorkDocument.ScoreAnnotation.Kind.bonus.hash(into: &hasher)
    _ = hasher.finalize()
    let _: AssignedWorkDocument.ScoreAnnotation.Kind.RawValue =
        AssignedWorkDocument.ScoreAnnotation.Kind.correct.rawValue
    let _: AssignedWorkDocument.ScoreAnnotation.Kind.AllCases =
        AssignedWorkDocument.ScoreAnnotation.Kind.allCases
}

func testMergeablePartDataCases() {
    let bytes = MergeablePartData.data(Data([0x01, 0x02]))
    let file = MergeablePartData.fileURL(URL(fileURLWithPath: "/tmp/assignables-part"))
    assignablesExpect(bytes != file, "distinct cases")
    if case .data(let data) = bytes {
        assignablesExpect(data.count == 2, "data payload")
    } else {
        assignablesExpect(false, "data case")
    }
    if case .fileURL(let url) = file {
        assignablesExpect(url.path == "/tmp/assignables-part", "file payload")
    } else {
        assignablesExpect(false, "file case")
    }
    assignablesExpect(bytes == MergeablePartData.data(Data([0x01, 0x02])), "data eq")
}
