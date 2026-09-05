import TabularData
import Foundation

private struct OptionalIntComparator: SortComparator {
    typealias Compared = Int?
    var order: SortOrder = .forward

    func compare(_ lhs: Int?, _ rhs: Int?) -> ComparisonResult {
        switch (lhs, rhs) {
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        case (let left?, let right?):
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
            return .orderedSame
        }
    }
}

private struct IntComparator: SortComparator {
    typealias Compared = Int
    var order: SortOrder = .forward

    func compare(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }
}

func testColumnCollectionInherited() {
    var column = Column<Int>(name: "n", contents: [3, 1, nil, 2])
    precondition(!column.isEmpty)
    _ = column.lazy
    _ = column.last
    _ = column.last(where: { $0 != nil })
    _ = column.first
    _ = column.first(where: { $0 == 1 })
    _ = column.dropLast(1)
    _ = column.dropFirst(1)
    _ = column.suffix(1)
    _ = column.prefix(1)
    _ = column.reversed()
    _ = column.enumerated()
    _ = column.allSatisfy { _ in true }
    _ = column.compactMap { $0 }
    _ = column.flatMap { $0.map { [$0] } ?? [] }
    let columnMapped: [Int?] = column.map { $0 }
    _ = columnMapped
    _ = column.reduce(0) { $0 + ($1 ?? 0) }
    _ = column.reduce(into: 0) { $0 += $1 ?? 0 }
    _ = column.sorted { ($0 ?? 0) < ($1 ?? 0) }
    _ = column.sorted(using: OptionalIntComparator())
    _ = column.sorted(using: [OptionalIntComparator()])
    _ = column.min(by: { ($0 ?? 0) < ($1 ?? 0) })
    _ = column.max(by: { ($0 ?? 0) < ($1 ?? 0) })
    _ = column.contains(where: { $0 == 1 })
    _ = column.contains(1)
    _ = column.count(where: { $0 != nil })
    _ = column.firstIndex(where: { $0 == 1 })
    _ = column.lastIndex(where: { $0 == 2 })
    _ = column.firstIndex(of: 1)
    _ = column.randomElement()
    var rng = SystemRandomNumberGenerator()
    _ = column.randomElement(using: &rng)
    _ = column.shuffled()
    _ = column.shuffled(using: &rng)
    _ = column.elementsEqual([Optional(3), 1, nil, 2], by: ==)
    _ = column.starts(with: [Optional(3)], by: ==)
    _ = column.lexicographicallyPrecedes([Optional(4)], by: { ($0 ?? 0) < ($1 ?? 0) })
    _ = column.difference(from: column, by: ==)
    _ = column.trimmingPrefix(while: { $0 == nil })
    _ = column.underestimatedCount
    _ = column.makeIterator()
    column.forEach { _ in }
    var index = column.endIndex
    column.formIndex(before: &index)
    _ = column.index(column.startIndex, offsetBy: 1, limitedBy: column.endIndex)
    let contiguous: Int? = column.withContiguousStorageIfAvailable { (buf: UnsafeBufferPointer<Int?>) in buf.count }
    _ = contiguous
    column.sort(using: OptionalIntComparator())
    column.sort(using: [OptionalIntComparator()])
    var partitioned = Column<Int>(name: "n", contents: [1, 9, 2])
    _ = partitioned.partition(by: { ($0 ?? 0) > 5 })
}

func testColumnSliceCollectionInherited() {
    var slice = ColumnSlice(Column<Int>(name: "n", contents: [4, 2, 6]))
    precondition(!slice.isEmpty)
    _ = slice.lazy
    _ = slice.last
    _ = slice.first
    let sliceMapped: [Int?] = slice.map { $0 }
    _ = sliceMapped
    _ = slice.flatMap { $0.map { [$0] } ?? [] }
    _ = slice.compactMap { $0 }
    _ = slice.sorted(using: OptionalIntComparator())
    slice.sort(using: OptionalIntComparator())
    _ = slice.partition(by: { ($0 ?? 0) > 3 })
    _ = slice.reversed()
    _ = slice.dropLast(1)
    _ = slice.suffix(1)
    _ = slice.contains(2)
    _ = slice.firstIndex(of: 2)
    _ = slice.removeLast()
    _ = slice.popLast()
    _ = slice.removeFirst()
    _ = slice.popFirst()
    try! slice.trimPrefix(while: { $0 == nil })
}

func testDiscontiguousCollectionInherited() {
    var slice = DiscontiguousColumnSlice(Column<Int>(name: "n", contents: [1, 2, 3]))
    precondition(!slice.isEmpty)
    _ = slice.lazy
    _ = slice.last
    _ = slice.first
    let discMapped: [Int?] = slice.map { $0 }
    _ = discMapped
    _ = slice.sorted(using: OptionalIntComparator())
    _ = slice.reversed()
    _ = slice.dropLast(1)
    _ = slice.contains(1)
    _ = slice.partition(by: { ($0 ?? 0) > 1 })
    _ = slice.indices
    _ = slice.removeLast()
    _ = slice.popLast()
}

func testFilledColumnCollectionInherited() {
    let filled = Column<Int>(name: "n", contents: [3, nil, 1]).filled(with: 0)
    precondition(!filled.isEmpty)
    _ = filled.lazy
    _ = filled.last
    _ = filled.first
    let filledMapped: [Int] = filled.map { $0 }
    _ = filledMapped
    _ = filled.flatMap { [$0] }
    _ = filled.sorted()
    _ = filled.sorted(using: IntComparator())
    _ = filled.reversed()
    _ = filled.contains(1)
    _ = filled.min()
    _ = filled.max()
    _ = filled.lexicographicallyPrecedes([0])
    _ = filled.indices
    _ = filled.count
    let strings = Column<String>(name: "s", contents: ["b", "a"]).filled(with: "")
    _ = strings.joined()
    _ = strings.joined(separator: ",")
    _ = strings.formatted()
}

func testAnyColumnCollectionInherited() {
    var column = AnyColumn(Column<Int>(name: "n", contents: [2, 1, 3]))
    precondition(!column.isEmpty)
    _ = column.lazy
    _ = column.first
    _ = column.last
    let anyMapped: [Any?] = column.map { $0 }
    _ = anyMapped
    _ = column.sorted(by: { String(describing: $0) < String(describing: $1) })
    column.sort { String(describing: $0) < String(describing: $1) }
    _ = column.partition(by: { ($0 as? Int ?? 0) > 1 })
    _ = column.reversed()
}

func testAnyColumnSliceCollectionInherited() {
    var slice = AnyColumnSlice(AnyColumn(Column<Int>(name: "n", contents: [1, 2, 3])))
    precondition(!slice.isEmpty)
    _ = slice.lazy
    _ = slice.first
    _ = slice.last
    let anySliceMapped: [Any?] = slice.map { $0 }
    _ = anySliceMapped
    _ = slice.sorted(by: { String(describing: $0) < String(describing: $1) })
    slice.sort { String(describing: $0) < String(describing: $1) }
    _ = slice.reversed()
    _ = slice.removeLast()
    _ = slice.popFirst()
}

func testRowCollectionInherited() {
    var row = sampleFrame()[row: 0]
    precondition(!row.isEmpty)
    _ = row.lazy
    _ = row.first
    let rowMapped: [Any?] = row.map { $0 }
    _ = rowMapped
    _ = row.reversed()
    _ = row.dropLast(0)
    _ = row.last
    row[0] = "z"
}

func testRowsCollectionInherited() {
    let rows = sampleFrame().rows
    precondition(!rows.isEmpty)
    _ = rows.lazy
    _ = rows.first
    let rowsMapped: [DataFrame.Row] = rows.map { $0 }
    _ = rowsMapped
    _ = rows.reversed()
    _ = rows.dropLast(1)
    _ = rows.last
    _ = rows.indices
    _ = rows.count
    var copy = rows
    copy[0] = rows[1]
}

func testRowGroupingCollectionInherited() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "b", "a"]))
    ])
    let grouping = frame.grouped(by: ColumnID("g", String.self))
    precondition(!grouping.isEmpty)
    _ = grouping.lazy
    _ = grouping.first
    let groupingMapped: [(key: String?, group: DataFrame.Slice)] = grouping.map { $0 }
    _ = groupingMapped
    _ = grouping.reversed()
    _ = grouping.count
    _ = grouping.last
    _ = grouping.sorted(by: { ($0.key ?? "") < ($1.key ?? "") })
}

func testCategoricalSummaryModeType() {
    let summary = CategoricalSummary(someCount: 2, noneCount: 0, uniqueCount: 1, mode: ["a"])
    let any = AnyCategoricalSummary(summary)
    precondition(any.modeType == String.self)
}
