import TabularData
import Foundation

func testJoinInnerLeftRightFull() {
    let left = DataFrame(columns: [
        AnyColumn(Column<String>(name: "id", contents: ["a", "b", "c"])),
        AnyColumn(Column<Int>(name: "leftVal", contents: [1, 2, 3]))
    ])
    let right = DataFrame(columns: [
        AnyColumn(Column<String>(name: "id", contents: ["b", "c", "d"])),
        AnyColumn(Column<Int>(name: "rightVal", contents: [20, 30, 40]))
    ])
    let inner = left.joined(right, on: "id", kind: .inner)
    precondition(inner.shape.rows == 2)
    let leftJoin = left.joined(right, on: (left: "id", right: "id"), kind: .left)
    precondition(leftJoin.shape.rows == 3)
    let rightJoin = left.joined(right, on: ColumnID("id", String.self), kind: .right)
    precondition(rightJoin.shape.rows == 3)
    let full = left.joined(right, on: (left: ColumnID("id", String.self), right: ColumnID("id", String.self)), kind: .full)
    precondition(full.shape.rows == 4)
}

func testGroupedCountsAndAggregates() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "a", "b", "b", "b"])),
        AnyColumn(Column<Int>(name: "n", contents: [1, 2, 3, 4, 5]))
    ])
    let grouping = frame.grouped(by: ColumnID("g", String.self))
    _ = grouping.description
    precondition(grouping.count >= 2)
    let ungrouped = grouping.ungrouped()
    precondition(ungrouped.shape.rows == 5)
    _ = grouping.counts()
    _ = grouping.counts(order: .descending)
    _ = grouping.sums(ColumnID("n", Int.self), order: .ascending)
    _ = grouping.sums("n", Int.self, order: nil)
    _ = grouping.maximums(ColumnID("n", Int.self), order: nil)
    _ = grouping.maximums("n", Int.self)
    _ = grouping.minimums(ColumnID("n", Int.self))
    _ = grouping.minimums("n", Int.self)
    _ = grouping.summary()
    _ = grouping.summary(of: "n")
    _ = grouping.summary(of: ["n"])
    let filtered = grouping.filter { $0.shape.rows > 1 }
    _ = filtered
    let mapped = grouping.mapGroups { DataFrame($0) }
    _ = mapped
    let split = grouping.randomSplit(by: 0.5)
    _ = split
    let seeded = grouping.randomSplit(by: 0.5, seed: 1)
    _ = seeded
    _ = grouping.aggregated(on: ColumnID("n", Int.self), into: "total") { $0.sum() }
    _ = grouping.aggregated(on: "n", naming: { $0 + "_sum" }) { (slice: DiscontiguousColumnSlice<Int>) in
        slice.sum()
    }
    _ = grouping.aggregated(on: ["n"], naming: { $0 }) { (slice: DiscontiguousColumnSlice<Int>) in
        slice.sum()
    }
    _ = grouping[ "a" ]
    let doubles = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "a"])),
        AnyColumn(Column<Double>(name: "x", contents: [1.0, 3.0]))
    ]).grouped(by: ColumnID("g", String.self))
    _ = doubles.means(ColumnID("x", Double.self), order: nil)
    _ = doubles.means("x", Double.self, order: nil)
    _ = doubles.quantiles(ColumnID("x", Double.self), quantile: 0.5, order: nil)
    _ = doubles.quantiles("x", Double.self, quantile: 0.5, order: nil)
}

func testGroupedByIDsAndTime() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "b"])),
        AnyColumn(Column<Int>(name: "n", contents: [1, 2])),
        AnyColumn(Column<Date>(name: "when", contents: [
            Date(timeIntervalSince1970: 0),
            Date(timeIntervalSince1970: 86400 * 40)
        ]))
    ])
    _ = frame.grouped(by: ColumnID("g", String.self))
    _ = frame.grouped(by: ColumnID("g", String.self), ColumnID("n", Int.self))
    _ = frame.grouped(by: ColumnID("g", String.self), ColumnID("n", Int.self), ColumnID("n", Int.self))
    _ = frame.grouped(by: ColumnID("g", String.self))
    _ = frame.grouped(by: "g", "n")
    _ = frame.grouped(by: ColumnID("when", Date.self), timeUnit: .month)
    _ = frame.grouped(by: "when", timeUnit: .year)
    _ = frame.grouped(by: ColumnID("n", Int.self), transform: { (value: Int?) in value.map { $0 > 1 } })
    _ = frame.grouped(by: "n", transform: { (value: Int?) in value })
    let grouping = RowGrouping<Int>(frame: frame, columnName: "when", timeUnit: .day)
    _ = grouping.count
    let manual = RowGrouping(groups: [(Optional("a"), frame)], groupKeysColumnName: "g")
    _ = manual.count
}

func testRandomAndStratifiedSplit() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "a", "b", "b", "a", "b"])),
        AnyColumn(Column<Int>(name: "n", contents: [1, 2, 3, 4, 5, 6]))
    ])
    let (l1, r1) = frame.randomSplit(by: 0.5, seed: 7)
    precondition(l1.shape.rows + r1.shape.rows == 6)
    var rng = SystemRandomNumberGenerator()
    _ = frame.randomSplit(by: 0.5, using: &rng)
    _ = frame.randomSplit(by: 0.5)
    let (s1, s2) = frame.stratifiedSplit(on: "g", by: 0.5, randomSeed: 2)
    precondition(s1.shape.rows + s2.shape.rows == 6)
    _ = frame.stratifiedSplit(on: ColumnID("g", String.self), by: 0.5, randomSeed: 1)
    _ = frame.stratifiedSplit(on: "g", "g", by: 0.5, randomSeed: 1)
    _ = frame.stratifiedSplit(on: ColumnID("g", String.self), ColumnID("n", Int.self), by: 0.5, randomSeed: 1)
    _ = frame.stratifiedSplit(on: ColumnID("g", String.self), ColumnID("n", Int.self), ColumnID("n", Int.self), by: 0.5, randomSeed: 1)
}

func testGroupSummariesSubscript() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "a"])),
        AnyColumn(Column<Int>(name: "n", contents: [1, 2]))
    ])
    let grouping = frame.grouped(by: "g")
    let summaries = grouping.summary()
    _ = summaries.description
    _ = summaries.description(options: FormattingOptions())
    _ = summaries["a"]
}

func testSliceRandomSplit() {
    let frame = sampleFrame()
    let (a, b) = frame[0..<4].randomSplit(by: 0.5, seed: 1)
    _ = a
    _ = b
    _ = frame[0..<4].summary()
}
