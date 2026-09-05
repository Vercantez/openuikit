@_spi(OpenUIKitHost) import GroupActivities
import Foundation

func testBroadcastOptionsMirroredVideo() {
    gaRequire(BroadcastOptions.mirroredVideo.rawValue == 1 << 0, "bit 0")
    gaRequire(BroadcastOptions(rawValue: 1) == .mirroredVideo, "raw init")
    gaRequire(BroadcastOptions.RawValue.self == Int.self, "RawValue")
    gaRequire(BroadcastOptions.Element.self == BroadcastOptions.self, "Element")
    gaRequire(
        BroadcastOptions.ArrayLiteralElement.self == BroadcastOptions.self,
        "ArrayLiteralElement"
    )
}

func testBroadcastOptionsInitEmpty() {
    let empty = BroadcastOptions()
    gaRequire(empty.rawValue == 0, "empty raw")
    gaRequire(empty.isEmpty, "isEmpty")
}

func testBroadcastOptionsInitSequence() {
    let options = BroadcastOptions([.mirroredVideo, .mirroredVideo])
    gaRequire(options == .mirroredVideo, "sequence uniquing")
}

func testBroadcastOptionsArrayLiteral() {
    let options: BroadcastOptions = [.mirroredVideo]
    gaRequire(options.contains(.mirroredVideo), "literal")
}

func testBroadcastOptionsContains() {
    gaRequire(BroadcastOptions.mirroredVideo.contains(.mirroredVideo), "contains self")
    gaRequire(!BroadcastOptions().contains(.mirroredVideo), "empty does not contain")
}

func testBroadcastOptionsUnion() {
    let union = BroadcastOptions().union(.mirroredVideo)
    gaRequire(union == .mirroredVideo, "union")
}

func testBroadcastOptionsFormUnion() {
    var options = BroadcastOptions()
    options.formUnion(.mirroredVideo)
    gaRequire(options == .mirroredVideo, "formUnion")
}

func testBroadcastOptionsIntersection() {
    gaRequire(
        BroadcastOptions.mirroredVideo.intersection(.mirroredVideo) == .mirroredVideo,
        "intersection"
    )
    gaRequire(BroadcastOptions.mirroredVideo.intersection([]).isEmpty, "empty intersection")
}

func testBroadcastOptionsFormIntersection() {
    var options = BroadcastOptions.mirroredVideo
    options.formIntersection([])
    gaRequire(options.isEmpty, "formIntersection")
}

func testBroadcastOptionsSymmetricDifference() {
    gaRequire(
        BroadcastOptions.mirroredVideo.symmetricDifference(.mirroredVideo).isEmpty,
        "symmetricDifference same"
    )
    gaRequire(
        BroadcastOptions().symmetricDifference(.mirroredVideo) == .mirroredVideo,
        "symmetricDifference empty"
    )
}

func testBroadcastOptionsFormSymmetricDifference() {
    var options = BroadcastOptions.mirroredVideo
    options.formSymmetricDifference(.mirroredVideo)
    gaRequire(options.isEmpty, "formSymmetricDifference")
}

func testBroadcastOptionsInsert() {
    var options = BroadcastOptions()
    let result = options.insert(.mirroredVideo)
    gaRequire(result.inserted, "inserted")
    gaRequire(result.memberAfterInsert == .mirroredVideo, "member")
    let again = options.insert(.mirroredVideo)
    gaRequire(!again.inserted, "already present")
}

func testBroadcastOptionsRemove() {
    var options = BroadcastOptions.mirroredVideo
    gaRequire(options.remove(.mirroredVideo) == .mirroredVideo, "removed")
    gaRequire(options.remove(.mirroredVideo) == nil, "already gone")
}

func testBroadcastOptionsUpdate() {
    var options = BroadcastOptions()
    gaRequire(options.update(with: .mirroredVideo) == nil, "insert via update")
    gaRequire(options.update(with: .mirroredVideo) == .mirroredVideo, "existing update")
}

func testBroadcastOptionsIsSubset() {
    gaRequire(BroadcastOptions().isSubset(of: .mirroredVideo), "empty subset")
    gaRequire(BroadcastOptions.mirroredVideo.isSubset(of: .mirroredVideo), "equal subset")
}

func testBroadcastOptionsIsSuperset() {
    gaRequire(BroadcastOptions.mirroredVideo.isSuperset(of: []), "superset of empty")
    gaRequire(BroadcastOptions.mirroredVideo.isSuperset(of: .mirroredVideo), "equal superset")
}

func testBroadcastOptionsIsStrictSubset() {
    gaRequire(BroadcastOptions().isStrictSubset(of: .mirroredVideo), "strict subset")
    gaRequire(!BroadcastOptions.mirroredVideo.isStrictSubset(of: .mirroredVideo), "not strict")
}

func testBroadcastOptionsIsStrictSuperset() {
    gaRequire(BroadcastOptions.mirroredVideo.isStrictSuperset(of: []), "strict superset")
    gaRequire(!BroadcastOptions.mirroredVideo.isStrictSuperset(of: .mirroredVideo), "not strict")
}

func testBroadcastOptionsIsDisjoint() {
    gaRequire(BroadcastOptions().isDisjoint(with: .mirroredVideo), "disjoint")
    gaRequire(!BroadcastOptions.mirroredVideo.isDisjoint(with: .mirroredVideo), "not disjoint")
}

func testBroadcastOptionsSubtract() {
    var options = BroadcastOptions.mirroredVideo
    options.subtract(.mirroredVideo)
    gaRequire(options.isEmpty, "subtract")
}

func testBroadcastOptionsSubtracting() {
    gaRequire(BroadcastOptions.mirroredVideo.subtracting(.mirroredVideo).isEmpty, "subtracting")
}

func testBroadcastOptionsInequality() {
    gaRequire(BroadcastOptions.mirroredVideo != BroadcastOptions(), "options !=")
    gaRequire(!(BroadcastOptions.mirroredVideo != .mirroredVideo), "equal not !=")
}
