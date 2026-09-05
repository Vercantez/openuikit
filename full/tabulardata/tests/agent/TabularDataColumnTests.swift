import TabularData
import Foundation

func testColumnInitAndAppend() {
    var column = Column<Int>(name: "n", capacity: 2)
    precondition(column.name == "n")
    precondition(column.count == 2)
    precondition(column.startIndex == 0)
    precondition(column.endIndex == 2)
    precondition(column.missingCount == 2)
    column.append(1)
    column.append(Optional(2))
    column.append(contentsOf: [3, 4])
    column.append(contentsOf: [Optional(5), nil])
    precondition(column.count == 8)
    _ = column.index(after: 0)
    _ = column.index(before: 1)
    _ = column.wrappedElementType
    _ = column.description
    _ = column.debugDescription
    _ = column.customMirror
    let fromID = Column(ColumnID("n", Int.self), capacity: 1)
    precondition(fromID.count == 1)
    let filled = Column(ColumnID("n", Int.self), contents: [1, 2])
    precondition(filled[0] == 1)
    let optionalContents = Column<Int>(name: "n", contents: [Optional(1), nil])
    precondition(optionalContents.missingCount == 1)
    let named = Column<Int>(name: "n", contents: [1, 2, 3])
    precondition(named.count == 3)
    let namedOpt = Column<Int>(name: "n", contents: [Optional(1), nil])
    precondition(namedOpt.missingCount == 1)
}

func testColumnSubscriptAndSlice() {
    var column = Column<Int>(name: "n", contents: [1, 2, 3, 4])
    precondition(column[1] == 2)
    column[1] = 9
    precondition(column[1] == 9)
    var slice = column[1..<3]
    precondition(slice.count == 2)
    slice[0] = 8
    column[1..<3] = slice
    let ranged: ColumnSlice<Int> = column[1...2]
    precondition(ranged.count == 2)
    let mask = column[[true, false, true, false]]
    precondition(mask.count == 2)
    column.remove(at: 0)
    precondition(column.count == 3)
}

func testColumnMapFilterTransform() {
    var column = Column<Int>(name: "n", contents: [1, nil, 3])
    let mapped = column.map { $0.map { $0 * 2 } }
    precondition(mapped[0] == 2)
    let nonNil = column.mapNonNil { $0 + 1 }
    precondition(nonNil[0] == 2)
    let filtered = column.filter { $0 != nil }
    precondition(filtered.count == 2)
    column.transform { $0.map { $0 * 10 } }
    precondition(column[0] == 10)
    column.transform { (value: Int) in value + 1 }
    precondition(column[0] == 11)
    let erased = column.eraseToAnyColumn()
    precondition(erased.name == "n")
}

func testColumnStatistics() {
    let ints = Column<Int>(name: "n", contents: [1, 2, 3, nil, 4])
    precondition(ints.sum() == 10)
    precondition(ints.min() == 1)
    precondition(ints.max() == 4)
    precondition(ints.argmin() == 0)
    precondition(ints.argmax() == 4)
    precondition(ints.mean() == 2.5)
    _ = ints.standardDeviation(deltaDegreesOfFreedom: 1)
    let numeric: NumericSummary<Double> = ints.numericSummary()
    precondition(numeric.someCount == 4)
    let doubles = Column<Double>(name: "x", contents: [1.0, 2.0, 3.0])
    let dsummary: NumericSummary<Double> = doubles.numericSummary()
    precondition(dsummary.mean == 2)
    _ = doubles.mean()
    _ = doubles.standardDeviation()
    let cats = Column<String>(name: "s", contents: ["a", "a", "b", nil])
    let summary = cats.summary()
    precondition(summary.uniqueCount == 2)
    let distinct = ints.distinct()
    precondition(distinct.count == 5)
}

func testColumnEquatableHashableCodable() {
    let a = Column<Int>(name: "n", contents: [1, 2])
    let b = Column<Int>(name: "n", contents: [1, 2])
    precondition(a == b)
    precondition(a != Column<Int>(name: "m", contents: [1, 2]))
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = a.hashValue
    let encoded = try! JSONEncoder().encode(a)
    let decoded = try! JSONDecoder().decode(Column<Int>.self, from: encoded)
    precondition(decoded == a)
}

func testColumnContiguousStorage() {
    var column = Column<Int>(name: "n", contents: [1, 2, 3])
    let packed = column.withContiguousStorageIfAvailable { (buf: UnsafeBufferPointer<Int>) in
        buf.count
    }
    precondition(packed == nil)
    let optionalCount = column.withContiguousStorageIfAvailable { (buf: UnsafeBufferPointer<Int?>) in
        buf.count
    }
    precondition(optionalCount == 3)
    let mutPacked = column.withContiguousMutableStorageIfAvailable { (buf: inout UnsafeMutableBufferPointer<Int>) in
        buf.count
    }
    precondition(mutPacked == nil)
    let mutOpt = column.withContiguousMutableStorageIfAvailable { (buf: inout UnsafeMutableBufferPointer<Int?>) in
        buf.count
    }
    precondition(mutOpt == 3)
    _ = column.prototype.makeColumn(capacity: 2)
}

func testColumnSliceBehavior() {
    let column = Column<Int>(name: "n", contents: [1, 2, 3, 4])
    var slice = ColumnSlice(column)
    precondition(slice.name == "n")
    precondition(slice.count == 4)
    precondition(slice.startIndex == 0)
    precondition(slice.endIndex == 4)
    _ = slice.index(after: 0)
    _ = slice.index(before: 1)
    precondition(!slice.isNil(at: 0))
    _ = slice.description
    _ = slice.debugDescription
    _ = slice.customMirror
    _ = slice.missingCount
    _ = slice.wrappedElementType
    _ = slice.prototype
    _ = slice.eraseToAnyColumn()
    let mapped = slice.map { $0 }
    precondition(mapped.count == 4)
    let filtered = slice.filter { ($0 ?? 0) > 2 }
    precondition(filtered.count == 2)
    let distinct = slice.distinct()
    precondition(distinct.count == 4)
    _ = slice.summary()
    let dsum: NumericSummary<Double> = slice.numericSummary()
    _ = dsum
    _ = slice.standardDeviation()
    _ = slice.mean()
    _ = slice.sum()
    _ = slice.min()
    _ = slice.max()
    _ = slice.argmax()
    _ = slice.argmin()
    slice[0] = 9
    slice[1..<2] = ColumnSlice(Column<Int>(name: "n", contents: [8]))
    var copy = slice
    copy[...] = slice
    precondition(slice == ColumnSlice(Column(slice)))
    var hasher = Hasher()
    slice.hash(into: &hasher)
    _ = slice.hashValue
}

func testDiscontiguousColumnSliceBehavior() {
    let column = Column<Int>(name: "n", contents: [1, 2, 3, 4, 5])
    var slice = DiscontiguousColumnSlice(column: column, ranges: [0..<2, 4..<5])
    precondition(slice.count == 3)
    let whole = DiscontiguousColumnSlice(column)
    precondition(whole.count == 5)
    _ = slice.description
    _ = slice.debugDescription
    _ = slice.customMirror
    _ = slice.missingCount
    _ = slice.wrappedElementType
    _ = slice.prototype
    _ = slice.isNil(at: 0)
    _ = slice.eraseToAnyColumn()
    _ = slice.map { $0 }
    _ = slice.filter { $0 != nil }
    _ = slice.distinct()
    _ = slice.summary()
    _ = slice.sum()
    _ = slice.min()
    _ = slice.max()
    _ = slice.argmax()
    _ = slice.argmin()
    let dsum: NumericSummary<Double> = slice.numericSummary()
    _ = dsum
    _ = slice.standardDeviation()
    _ = slice.mean()
    slice[0] = 9
    slice[0..<1] = DiscontiguousColumnSlice(Column<Int>(name: "n", contents: [1]))
    var copy = slice
    copy[...] = slice
    precondition(slice == slice)
    var hasher = Hasher()
    slice.hash(into: &hasher)
    _ = slice.hashValue
}

func testFilledColumnBehavior() {
    let column = Column<Int>(name: "n", contents: [1, nil, 3])
    let filled = column.filled(with: 0)
    precondition(filled[1] == 0)
    precondition(Array(filled) == [1, 0, 3])
    _ = filled.description
    _ = filled.debugDescription
    _ = filled.description(options: FormattingOptions())
    _ = filled.name
    _ = filled.startIndex
    _ = filled.endIndex
    _ = filled.index(after: filled.startIndex)
    _ = filled.index(before: filled.endIndex)
    _ = filled.sum()
    _ = filled.min()
    _ = filled.max()
    _ = filled.argmax()
    _ = filled.argmin()
    _ = filled.mean()
    _ = filled.standardDeviation()
    let dsum: NumericSummary<Double> = filled.numericSummary()
    _ = dsum
    _ = filled.summary()
    var named = filled
    named.name = "m"
    precondition(named.name == "m")
}

func testAnyColumnBehavior() {
    var column = AnyColumn(Column<Int>(name: "n", contents: [1, 2, nil]))
    precondition(column.name == "n")
    precondition(column.count == 3)
    precondition(column.startIndex == 0)
    precondition(column.endIndex == 3)
    _ = column.index(after: 0)
    _ = column.index(before: 1)
    _ = column.missingCount
    _ = column.wrappedElementType
    _ = column.prototype
    _ = column.description
    _ = column.debugDescription
    _ = column.customMirror
    precondition(column.isNil(at: 2))
    let typed = column.assumingType(Int.self)
    precondition(typed[0] == 1)
    column.append(4)
    column.append(contentsOf: column)
    column.append(contentsOf: AnyColumnSlice(column))
    _ = column.distinct()
    column.remove(at: 0)
    _ = column[0]
    _ = column[0..<1]
    _ = column[[true, false, true]]
    precondition(column == column)
    var hasher = Hasher()
    column.hash(into: &hasher)
    _ = column.hashValue
}

func testAnyColumnSliceBehavior() {
    let column = AnyColumn(Column<Int>(name: "n", contents: [1, 2, 3]))
    var slice = AnyColumnSlice(column)
    precondition(slice.count == 3)
    _ = AnyColumnSlice(ColumnSlice(Column<Int>(name: "n", contents: [1])))
    _ = AnyColumnSlice(DiscontiguousColumnSlice(Column<Int>(name: "n", contents: [1])))
    _ = slice.description
    _ = slice.debugDescription
    _ = slice.customMirror
    _ = slice.missingCount
    _ = slice.wrappedElementType
    _ = slice.prototype
    _ = slice.isNil(at: 0)
    _ = slice.assumingType(Int.self)
    _ = slice[0]
    _ = slice[0..<1]
    precondition(slice == slice)
    var hasher = Hasher()
    slice.hash(into: &hasher)
    _ = slice.hashValue
    slice[0] = 9
}
