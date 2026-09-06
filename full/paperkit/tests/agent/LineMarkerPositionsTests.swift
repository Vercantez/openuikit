import PaperKit
import Foundation

func testLineMarkerPositionsMembers() {
    precondition(FeatureSet.LineMarkerPositions.plain.rawValue == 1 << 0)
    precondition(FeatureSet.LineMarkerPositions.single.rawValue == 1 << 1)
    precondition(FeatureSet.LineMarkerPositions.double.rawValue == 1 << 2)
    precondition(
        FeatureSet.LineMarkerPositions.all.rawValue
            == ((1 << 0) | (1 << 1) | (1 << 2))
    )
    let fromRaw = FeatureSet.LineMarkerPositions(rawValue: 1 << 1)
    precondition(fromRaw == .single)
    let raw: FeatureSet.LineMarkerPositions.RawValue = FeatureSet.LineMarkerPositions.plain.rawValue
    precondition(raw == 1)
    let element: FeatureSet.LineMarkerPositions.Element = .double
    precondition(element == .double)
    let literal: FeatureSet.LineMarkerPositions.ArrayLiteralElement = .plain
    precondition(literal == .plain)
}

func testLineMarkerPositionsAlgebra() {
    let empty = FeatureSet.LineMarkerPositions()
    precondition(empty.isEmpty)
    precondition(empty.isSubset(of: .all))
    precondition(!empty.contains(.plain))
    precondition(FeatureSet.LineMarkerPositions.all.contains(.plain))
    precondition(FeatureSet.LineMarkerPositions.all.contains(.single))
    precondition(FeatureSet.LineMarkerPositions.all.contains(.double))

    var positions: FeatureSet.LineMarkerPositions = [.plain, .single]
    let (inserted, after) = positions.insert(.double)
    precondition(inserted)
    precondition(after == .double)
    precondition(positions == .all)

    let removed = positions.remove(.plain)
    precondition(removed == .plain)
    precondition(!positions.contains(.plain))

    let updated = positions.update(with: .plain)
    precondition(updated == nil)
    precondition(positions.contains(.plain))

    let union = FeatureSet.LineMarkerPositions.plain.union(.single)
    precondition(union.contains(.plain) && union.contains(.single))
    let intersection = FeatureSet.LineMarkerPositions.all.intersection(.single)
    precondition(intersection == .single)
    let difference = FeatureSet.LineMarkerPositions.all.symmetricDifference(.single)
    precondition(difference.contains(.plain) && !difference.contains(.single))

    var form = FeatureSet.LineMarkerPositions.plain
    form.formUnion(.single)
    precondition(form.contains(.single))
    form.formIntersection(.plain)
    precondition(form == .plain)
    form.formSymmetricDifference(.single)
    precondition(form.contains(.single) && form.contains(.plain))

    let subtracting = FeatureSet.LineMarkerPositions.all.subtracting(.double)
    precondition(!subtracting.contains(.double))
    var mutable = FeatureSet.LineMarkerPositions.all
    mutable.subtract(.single)
    precondition(!mutable.contains(.single))

    precondition(FeatureSet.LineMarkerPositions.plain.isDisjoint(with: .double))
    precondition(FeatureSet.LineMarkerPositions.all.isSuperset(of: .single))
    precondition(FeatureSet.LineMarkerPositions.plain.isSubset(of: .all))
    precondition(FeatureSet.LineMarkerPositions.plain.isStrictSubset(of: .all))
    precondition(FeatureSet.LineMarkerPositions.all.isStrictSuperset(of: .plain))
    precondition(FeatureSet.LineMarkerPositions.plain != .single)

    var hasher = Hasher()
    FeatureSet.LineMarkerPositions.all.hash(into: &hasher)
    _ = FeatureSet.LineMarkerPositions.all.hashValue

    let fromSequence = FeatureSet.LineMarkerPositions([.plain, .double])
    precondition(fromSequence.contains(.plain) && fromSequence.contains(.double))
    let fromLiteral: FeatureSet.LineMarkerPositions = [.single]
    precondition(fromLiteral == .single)
}
