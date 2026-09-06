import Foundation
import AutomaticAssessmentConfiguration

func testAutocorrectModeType() {
    let mode: AEAssessmentConfiguration.AutocorrectMode = []
    aacExpect(type(of: mode) == AEAssessmentConfiguration.AutocorrectMode.self, "type")
}

func testAutocorrectModeRawValues() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode.spelling.rawValue == 1, "spelling")
    aacExpect(AEAssessmentConfiguration.AutocorrectMode.punctuation.rawValue == 2, "punctuation")
    aacExpect(
        AEAssessmentConfiguration.AutocorrectMode([.spelling, .punctuation]).rawValue == 3,
        "union raw"
    )
}

func testAutocorrectModeInit() {
    let empty = AEAssessmentConfiguration.AutocorrectMode()
    aacExpect(empty.rawValue == 0, "empty init")
    aacExpect(empty.isEmpty, "empty isEmpty")
}

func testAutocorrectModeInitRawValue() {
    let mode = AEAssessmentConfiguration.AutocorrectMode(rawValue: 3)
    aacExpect(mode.contains(.spelling), "bit 0")
    aacExpect(mode.contains(.punctuation), "bit 1")
}

func testAutocorrectModeInitArrayLiteral() {
    let mode: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    aacExpect(mode.contains(.spelling) && mode.contains(.punctuation), "literal")
}

func testAutocorrectModeInitSequence() {
    let mode = AEAssessmentConfiguration.AutocorrectMode([
        AEAssessmentConfiguration.AutocorrectMode.spelling,
        .punctuation,
    ])
    aacExpect(mode.rawValue == 3, "sequence init")
}

func testAutocorrectModeIsEmpty() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode().isEmpty, "empty")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode.spelling.isEmpty, "spelling")
}

func testAutocorrectModeContains() {
    let both: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    aacExpect(both.contains(.spelling), "contains spelling")
    aacExpect(both.contains(.punctuation), "contains punctuation")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode.spelling.contains(.punctuation), "not punctuation")
}

func testAutocorrectModeInsert() {
    var mode = AEAssessmentConfiguration.AutocorrectMode()
    let first = mode.insert(.spelling)
    aacExpect(first.inserted, "first insert")
    aacExpect(first.memberAfterInsert == .spelling, "member")
    let second = mode.insert(.spelling)
    aacExpect(!second.inserted, "duplicate")
    aacExpect(mode.contains(.spelling), "retained")
}

func testAutocorrectModeRemove() {
    var mode: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    let removed = mode.remove(.spelling)
    aacExpect(removed == .spelling, "removed")
    aacExpect(!mode.contains(.spelling), "gone")
    aacExpect(mode.contains(.punctuation), "kept")
    aacExpect(mode.remove(.spelling) == nil, "already gone")
}

func testAutocorrectModeUpdate() {
    var mode = AEAssessmentConfiguration.AutocorrectMode.spelling
    let previous = mode.update(with: .punctuation)
    aacExpect(previous == nil, "new member")
    aacExpect(mode.contains(.punctuation), "inserted")
    let again = mode.update(with: .punctuation)
    aacExpect(again == .punctuation, "existing")
}

func testAutocorrectModeUnion() {
    let union = AEAssessmentConfiguration.AutocorrectMode.spelling.union(.punctuation)
    aacExpect(union.rawValue == 3, "union")
}

func testAutocorrectModeIntersection() {
    let both: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    aacExpect(both.intersection(.spelling) == .spelling, "intersection")
    aacExpect(both.intersection([]).isEmpty, "empty intersection")
}

func testAutocorrectModeSymmetricDifference() {
    let left: AEAssessmentConfiguration.AutocorrectMode = [.spelling]
    let right: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    aacExpect(left.symmetricDifference(right) == .punctuation, "symmetric")
}

func testAutocorrectModeSubtracting() {
    let both: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    aacExpect(both.subtracting(.spelling) == .punctuation, "subtracting")
}

func testAutocorrectModeSubtract() {
    var mode: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    mode.subtract(.punctuation)
    aacExpect(mode == .spelling, "subtract")
}

func testAutocorrectModeFormUnion() {
    var mode = AEAssessmentConfiguration.AutocorrectMode.spelling
    mode.formUnion(.punctuation)
    aacExpect(mode.rawValue == 3, "formUnion")
}

func testAutocorrectModeFormIntersection() {
    var mode: AEAssessmentConfiguration.AutocorrectMode = [.spelling, .punctuation]
    mode.formIntersection(.spelling)
    aacExpect(mode == .spelling, "formIntersection")
}

func testAutocorrectModeFormSymmetricDifference() {
    var mode = AEAssessmentConfiguration.AutocorrectMode.spelling
    mode.formSymmetricDifference(.punctuation)
    aacExpect(mode.rawValue == 3, "formSymmetricDifference")
}

func testAutocorrectModeIsSubset() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode.spelling.isSubset(of: [.spelling, .punctuation]), "subset")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode([.spelling, .punctuation]).isSubset(of: .spelling), "not subset")
}

func testAutocorrectModeIsSuperset() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode([.spelling, .punctuation]).isSuperset(of: .spelling), "superset")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode.spelling.isSuperset(of: [.spelling, .punctuation]), "not superset")
}

func testAutocorrectModeIsDisjoint() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode.spelling.isDisjoint(with: .punctuation), "disjoint")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode.spelling.isDisjoint(with: [.spelling, .punctuation]), "overlap")
}

func testAutocorrectModeIsStrictSubset() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode.spelling.isStrictSubset(of: [.spelling, .punctuation]), "strict subset")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode.spelling.isStrictSubset(of: .spelling), "equal not strict")
}

func testAutocorrectModeIsStrictSuperset() {
    aacExpect(AEAssessmentConfiguration.AutocorrectMode([.spelling, .punctuation]).isStrictSuperset(of: .spelling), "strict super")
    aacExpect(!AEAssessmentConfiguration.AutocorrectMode.spelling.isStrictSuperset(of: .spelling), "equal not strict")
}

func testAutocorrectModeInequality() {
    aacExpect(
        AEAssessmentConfiguration.AutocorrectMode.spelling
            != AEAssessmentConfiguration.AutocorrectMode.punctuation,
        "inequality"
    )
    aacExpect(
        !(AEAssessmentConfiguration.AutocorrectMode.spelling
            != AEAssessmentConfiguration.AutocorrectMode.spelling),
        "equal"
    )
}
