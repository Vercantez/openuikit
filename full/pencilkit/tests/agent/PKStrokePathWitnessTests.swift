import PencilKit
import Foundation

func testPKStrokePathDifferenceFromBy() {
    let base = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(1, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let extended = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(1, 0), pkMakePoint(2, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let diff = extended.difference(from: base, by: ==)
    pkExpectEqual(diff.insertions.count, 1, "difference insertions")
    pkExpect(diff.removals.isEmpty, "difference no removals")
}

func testPKStrokePathTrimmingPrefixWhile() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(0, 1), pkMakePoint(2, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let trimmed = path.trimmingPrefix(while: { $0.location.x == 0 })
    pkExpectEqual(trimmed.count, 1, "trimmingPrefix count")
    pkExpectEqual(trimmed.first?.location.x, 2, "trimmingPrefix first")
}

func testPKStrokePathRemovingSubranges() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(1, 0), pkMakePoint(2, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let kept = path.removingSubranges(RangeSet(1 ..< 2))
    pkExpectEqual(kept.count, 2, "removingSubranges count")
    pkExpectEqual(kept.map { $0.location.x }, [0, 2], "removingSubranges kept")
}

func testPKStrokePathIndicesWhereRangeSet() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(1, 0), pkMakePoint(2, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let set = path.indices(where: { $0.location.x > 0 })
    pkExpect(!set.contains(0), "indices excludes 0")
    pkExpect(set.contains(1) && set.contains(2), "indices contains 1,2")
}

func testPKStrokePathSliceContiguousStorage() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(2, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let slice = path.interpolatedPoints(in: 0 ... 1, by: .parametricStep(0.5))
    let result: Int? = slice.withContiguousStorageIfAvailable { $0.count }
    pkExpect(result == nil, "slice has no contiguous storage")
}

func testPKStrokePathSliceDropWhile() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(2, 0), pkMakePoint(4, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let slice = path.interpolatedPoints(in: 0 ... 2, by: .parametricStep(1))
    let dropped = slice.drop(while: { $0.location.x < 2 })
    let first = dropped.first(where: { _ in true })
    pkExpectEqual(first?.location.x, 2, "slice drop while")
}

func testPKStrokePathSliceSplitSeparator() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(2, 0), pkMakePoint(4, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let slice = path.interpolatedPoints(in: 0 ... 2, by: .parametricStep(1))
    let parts = slice.split(
        maxSplits: 1,
        omittingEmptySubsequences: true,
        whereSeparator: { $0.location.x == 2 }
    )
    pkExpectEqual(parts.count, 2, "slice split count")
    pkExpectEqual(parts.first?.first?.location.x, 0, "slice split head")
}

func testPKStrokePathSlicePrefixWhile() {
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(2, 0), pkMakePoint(4, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
    let slice = path.interpolatedPoints(in: 0 ... 2, by: .parametricStep(1))
    let head = slice.prefix(while: { $0.location.x < 4 })
    pkExpectEqual(head.count, 2, "slice prefix while")
}
