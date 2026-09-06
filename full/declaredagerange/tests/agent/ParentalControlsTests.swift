import Foundation
import DeclaredAgeRange

func testParentalControlsType() {
    let controls: AgeRangeService.ParentalControls = []
    precondition(type(of: controls) == AgeRangeService.ParentalControls.self)
}

func testParentalControlsCommunicationLimits() {
    let flag = AgeRangeService.ParentalControls.communicationLimits
    precondition(flag.rawValue == 1)
    precondition(AgeRangeService.ParentalControls(rawValue: 1) == flag)
    precondition(flag.contains(.communicationLimits))
}

func testParentalControlsRawValue() {
    let empty = AgeRangeService.ParentalControls()
    precondition(empty.rawValue == 0)
    precondition(AgeRangeService.ParentalControls.communicationLimits.rawValue == 1)
    precondition(AgeRangeService.ParentalControls(rawValue: 4).rawValue == 4)
}

func testParentalControlsInitRawValue() {
    let fromZero = AgeRangeService.ParentalControls(rawValue: 0)
    precondition(fromZero.isEmpty)
    let fromOne = AgeRangeService.ParentalControls(rawValue: 1)
    precondition(fromOne == .communicationLimits)
    let unknown = AgeRangeService.ParentalControls(rawValue: 8)
    precondition(unknown.rawValue == 8)
    precondition(!unknown.contains(.communicationLimits))
}

func testParentalControlsInitEmpty() {
    let empty = AgeRangeService.ParentalControls()
    precondition(empty.rawValue == 0)
    precondition(empty.isEmpty)
}

func testParentalControlsDescription() {
    precondition(AgeRangeService.ParentalControls().description == "0")
    precondition(AgeRangeService.ParentalControls.communicationLimits.description == "1")
    precondition(AgeRangeService.ParentalControls(rawValue: 3).description == "3")
}

func testParentalControlsArrayLiteralElement() {
    typealias Element = AgeRangeService.ParentalControls.ArrayLiteralElement
    let value: Element = .communicationLimits
    precondition(type(of: value) == AgeRangeService.ParentalControls.self)
}

func testParentalControlsElement() {
    typealias Element = AgeRangeService.ParentalControls.Element
    let value: Element = .communicationLimits
    precondition(type(of: value) == AgeRangeService.ParentalControls.self)
}

func testParentalControlsRawValueAlias() {
    typealias Raw = AgeRangeService.ParentalControls.RawValue
    let raw: Raw = AgeRangeService.ParentalControls.communicationLimits.rawValue
    precondition(raw == 1)
    precondition(type(of: raw) == Int.self)
}

func testParentalControlsArrayLiteral() {
    let fromLiteral: AgeRangeService.ParentalControls = [.communicationLimits]
    precondition(fromLiteral == .communicationLimits)
    let empty: AgeRangeService.ParentalControls = []
    precondition(empty.isEmpty)
}

func testParentalControlsInitSequence() {
    let fromArray = AgeRangeService.ParentalControls([.communicationLimits])
    precondition(fromArray == .communicationLimits)
    let fromEmpty = AgeRangeService.ParentalControls(
        [AgeRangeService.ParentalControls]()
    )
    precondition(fromEmpty.isEmpty)
}

func testParentalControlsInequality() {
    precondition(
        AgeRangeService.ParentalControls.communicationLimits != AgeRangeService.ParentalControls()
    )
    precondition(
        !(AgeRangeService.ParentalControls.communicationLimits != .communicationLimits)
    )
}

func testParentalControlsIsEmpty() {
    precondition(AgeRangeService.ParentalControls().isEmpty)
    precondition(!AgeRangeService.ParentalControls.communicationLimits.isEmpty)
}

func testParentalControlsContains() {
    precondition(AgeRangeService.ParentalControls.communicationLimits.contains(.communicationLimits))
    precondition(!AgeRangeService.ParentalControls().contains(.communicationLimits))
    precondition(AgeRangeService.ParentalControls(rawValue: 3).contains(.communicationLimits))
}

func testParentalControlsInsert() {
    var controls = AgeRangeService.ParentalControls()
    let first = controls.insert(.communicationLimits)
    precondition(first.inserted)
    precondition(first.memberAfterInsert == .communicationLimits)
    precondition(controls.contains(.communicationLimits))
    let second = controls.insert(.communicationLimits)
    precondition(!second.inserted)
    precondition(second.memberAfterInsert == .communicationLimits)
}

func testParentalControlsRemove() {
    var controls: AgeRangeService.ParentalControls = [.communicationLimits]
    let removed = controls.remove(.communicationLimits)
    precondition(removed == .communicationLimits)
    precondition(controls.isEmpty)
    precondition(controls.remove(.communicationLimits) == nil)
}

func testParentalControlsUpdate() {
    var controls = AgeRangeService.ParentalControls()
    let inserted = controls.update(with: .communicationLimits)
    precondition(inserted == nil)
    precondition(controls == .communicationLimits)
    let replaced = controls.update(with: .communicationLimits)
    precondition(replaced == .communicationLimits)
}

func testParentalControlsUnion() {
    let empty = AgeRangeService.ParentalControls()
    let limits = AgeRangeService.ParentalControls.communicationLimits
    precondition(empty.union(limits) == limits)
    precondition(limits.union(empty) == limits)
    precondition(limits.union(limits) == limits)
}

func testParentalControlsFormUnion() {
    var controls = AgeRangeService.ParentalControls()
    controls.formUnion(.communicationLimits)
    precondition(controls == .communicationLimits)
    controls.formUnion(.communicationLimits)
    precondition(controls == .communicationLimits)
}

func testParentalControlsIntersection() {
    let limits = AgeRangeService.ParentalControls.communicationLimits
    let extra = AgeRangeService.ParentalControls(rawValue: 3)
    precondition(limits.intersection(extra) == limits)
    precondition(limits.intersection(AgeRangeService.ParentalControls()) == [])
}

func testParentalControlsFormIntersection() {
    var controls = AgeRangeService.ParentalControls(rawValue: 3)
    controls.formIntersection(.communicationLimits)
    precondition(controls == .communicationLimits)
    controls.formIntersection([])
    precondition(controls.isEmpty)
}

func testParentalControlsSymmetricDifference() {
    let limits = AgeRangeService.ParentalControls.communicationLimits
    let extra = AgeRangeService.ParentalControls(rawValue: 2)
    let mixed = limits.symmetricDifference(extra)
    precondition(mixed.rawValue == 3)
    precondition(limits.symmetricDifference(limits).isEmpty)
}

func testParentalControlsFormSymmetricDifference() {
    var controls = AgeRangeService.ParentalControls.communicationLimits
    controls.formSymmetricDifference(.communicationLimits)
    precondition(controls.isEmpty)
    controls.formSymmetricDifference(.communicationLimits)
    precondition(controls == .communicationLimits)
}

func testParentalControlsSubtract() {
    var controls = AgeRangeService.ParentalControls(rawValue: 3)
    controls.subtract(.communicationLimits)
    precondition(controls.rawValue == 2)
    precondition(!controls.contains(.communicationLimits))
}

func testParentalControlsSubtracting() {
    let extra = AgeRangeService.ParentalControls(rawValue: 3)
    let result = extra.subtracting(.communicationLimits)
    precondition(result.rawValue == 2)
    precondition(
        AgeRangeService.ParentalControls.communicationLimits
            .subtracting(.communicationLimits)
            .isEmpty
    )
}

func testParentalControlsIsSubset() {
    let empty = AgeRangeService.ParentalControls()
    let limits = AgeRangeService.ParentalControls.communicationLimits
    precondition(empty.isSubset(of: limits))
    precondition(limits.isSubset(of: limits))
    precondition(!limits.isSubset(of: empty))
}

func testParentalControlsIsSuperset() {
    let empty = AgeRangeService.ParentalControls()
    let limits = AgeRangeService.ParentalControls.communicationLimits
    precondition(limits.isSuperset(of: empty))
    precondition(limits.isSuperset(of: limits))
    precondition(!empty.isSuperset(of: limits))
}

func testParentalControlsIsStrictSubset() {
    let empty = AgeRangeService.ParentalControls()
    let limits = AgeRangeService.ParentalControls.communicationLimits
    precondition(empty.isStrictSubset(of: limits))
    precondition(!limits.isStrictSubset(of: limits))
    precondition(!limits.isStrictSubset(of: empty))
}

func testParentalControlsIsStrictSuperset() {
    let empty = AgeRangeService.ParentalControls()
    let limits = AgeRangeService.ParentalControls.communicationLimits
    precondition(limits.isStrictSuperset(of: empty))
    precondition(!limits.isStrictSuperset(of: limits))
    precondition(!empty.isStrictSuperset(of: limits))
}

func testParentalControlsIsDisjoint() {
    let empty = AgeRangeService.ParentalControls()
    let limits = AgeRangeService.ParentalControls.communicationLimits
    let other = AgeRangeService.ParentalControls(rawValue: 2)
    precondition(empty.isDisjoint(with: limits))
    precondition(limits.isDisjoint(with: other))
    precondition(!limits.isDisjoint(with: limits))
}
