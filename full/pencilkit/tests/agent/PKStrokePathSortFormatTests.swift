import PencilKit
import Foundation

/// Test-local adapter: orders stroke points by location.x.
/// Foundation's `Sequence.sorted(using:)` only needs a caller-provided
/// `SortComparator` whose `Compared == Element`; no product change required.
struct PKPointXSortComparator: SortComparator {
    typealias Compared = PKStrokePoint
    var order: SortOrder = .forward
    func compare(_ lhs: PKStrokePoint, _ rhs: PKStrokePoint) -> ComparisonResult {
        let left = lhs.location.x
        let right = rhs.location.x
        if left == right { return .orderedSame }
        let ascending = left < right
        if order == .forward {
            return ascending ? .orderedAscending : .orderedDescending
        }
        return ascending ? .orderedDescending : .orderedAscending
    }
}

/// Test-local style whose input is a whole stroke path.
struct PKStrokePathJoinStyle: FormatStyle {
    typealias FormatInput = PKStrokePath
    typealias FormatOutput = String
    func format(_ value: PKStrokePath) -> String {
        "points=" + value.map { String(Int($0.location.x)) }.joined(separator: ",")
    }
}

/// Test-local style whose input is a whole interpolated slice.
struct PKStrokeSliceJoinStyle: FormatStyle {
    typealias FormatInput = PKStrokePath.InterpolatedSlice
    typealias FormatOutput = String
    func format(_ value: PKStrokePath.InterpolatedSlice) -> String {
        "points=" + value.map { String(Int($0.location.x)) }.joined(separator: ",")
    }
}

private func pkSortFixturePath() -> PKStrokePath {
    PKStrokePath(
        controlPoints: [pkMakePoint(2, 0), pkMakePoint(0, 0), pkMakePoint(1, 0)],
        creationDate: Date(timeIntervalSince1970: 0)
    )
}

func testPKStrokePathSortedUsingComparator() {
    let path = pkSortFixturePath()
    let sortedPath = path.sorted(using: PKPointXSortComparator())
    pkExpectEqual(sortedPath.map { $0.location.x }, [0, 1, 2], "path sorted using comparator")
    let slice = path.interpolatedPoints(in: 0 ... 2, by: .parametricStep(1))
    let sortedSlice = slice.sorted(using: PKPointXSortComparator())
    pkExpectEqual(sortedSlice.map { $0.location.x }, [0, 1, 2], "slice sorted using comparator")
}

func testPKStrokePathSortedUsingComparatorSequence() {
    let path = pkSortFixturePath()
    let sortedPath = path.sorted(using: [PKPointXSortComparator()])
    pkExpectEqual(sortedPath.map { $0.location.x }, [0, 1, 2], "path sorted using comparator sequence")
    let slice = path.interpolatedPoints(in: 0 ... 2, by: .parametricStep(1))
    let sortedSlice = slice.sorted(using: [PKPointXSortComparator()])
    pkExpectEqual(sortedSlice.map { $0.location.x }, [0, 1, 2], "slice sorted using comparator sequence")
}

func testPKStrokePathFormattedSequenceStyle() {
    let path = pkSortFixturePath()
    let formattedPath: String = path.formatted(PKStrokePathJoinStyle())
    pkExpectEqual(formattedPath, "points=2,0,1", "path formatted sequence style")
    let slice = path.interpolatedPoints(in: 0 ... 2, by: .parametricStep(1))
    let formattedSlice: String = slice.formatted(PKStrokeSliceJoinStyle())
    pkExpectEqual(formattedSlice, "points=2,0,1", "slice formatted sequence style")
}
