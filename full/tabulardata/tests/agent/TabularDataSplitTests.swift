import TabularData
import Foundation

func testColumnSplitInherited() {
    let column = Column<Int>(name: "n", contents: [1, 0, 2, 0, 3])
    _ = column.split(separator: 0)
    _ = column.split(separator: Optional(0), maxSplits: 2, omittingEmptySubsequences: true)
    _ = column.split(maxSplits: 2, omittingEmptySubsequences: true) { $0 == 0 }
    let slice = ColumnSlice(column)
    _ = slice.split(separator: Optional(0))
    _ = slice.split(maxSplits: 1, omittingEmptySubsequences: true) { $0 == nil }
    let disc = DiscontiguousColumnSlice(column)
    _ = disc.split(separator: Optional(0))
    _ = disc.split(maxSplits: 1, omittingEmptySubsequences: false) { $0 == 0 }
    let any = AnyColumn(column)
    _ = any.split(maxSplits: 1, omittingEmptySubsequences: true) { $0 == nil }
    let anySlice = AnyColumnSlice(AnyColumn(column))
    _ = anySlice.split(maxSplits: 1, omittingEmptySubsequences: true) { _ in false }
    let filled = column.filled(with: 0)
    _ = filled.split(separator: 0)
    _ = filled.split(maxSplits: 1, omittingEmptySubsequences: true) { $0 == 0 }
}

func testRowGroupingSplit() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "b", "a"]))
    ])
    let grouping = frame.grouped(by: ColumnID("g", String.self))
    _ = grouping.split(maxSplits: 1, omittingEmptySubsequences: true) { $0.key == nil }
}
