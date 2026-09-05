import TabularData
import Foundation

func sampleFrame() -> DataFrame {
    DataFrame(columns: [
        AnyColumn(Column<String>(name: "name", contents: ["a", "b", "c", "a"])),
        AnyColumn(Column<Int>(name: "age", contents: [10, 20, 30, 40]))
    ])
}

func testDataFrameEmptyAndColumns() {
    var frame = DataFrame()
    precondition(frame.shape.rows == 0)
    precondition(frame.isEmpty)
    precondition(frame.columns.isEmpty)
    frame.append(column: Column<Int>(name: "n", contents: [1, 2]))
    precondition(frame.shape == (2, 1))
    precondition(frame.containsColumn("n"))
    precondition(frame.containsColumn(ColumnID("n", Int.self)))
    precondition(frame.containsColumn("n", Int.self))
    precondition(frame.indexOfColumn("n") == 0)
    _ = frame.description
    _ = frame.debugDescription
    _ = frame.customMirror
    _ = frame.description(options: FormattingOptions())
}

func testDataFrameDictionaryLiteral() {
    let frame: DataFrame = ["n": [1, 2], "s": ["x", "y"]]
    precondition(frame.shape.columns == 2)
    precondition(frame.shape.rows == 2)
}

func testDataFrameAppendAndRows() {
    var frame = sampleFrame()
    frame.appendEmptyRow()
    precondition(frame.shape.rows == 5)
    frame.append(valuesByColumn: ["name": "d", "age": 50])
    frame.append(row: frame[row: 0])
    frame.append(row: "e", 60)
    let extra = DataFrame(columns: [
        AnyColumn(Column<String>(name: "name", contents: ["z"])),
        AnyColumn(Column<Int>(name: "age", contents: [1]))
    ])
    frame.append(extra)
    frame.append(extra[0..<1])
    frame.append(rowsOf: extra)
    precondition(frame.shape.rows > 4)
    frame.insert(row: frame[row: 0], at: 0)
    frame.insert(column: Column<Int>(name: "id", contents: Array(repeating: 0, count: frame.shape.rows)), at: 0)
    frame.removeRow(at: 0)
}

func testDataFrameColumnMutation() {
    var frame = sampleFrame()
    _ = frame.removeColumn("name")
    frame = sampleFrame()
    _ = frame.removeColumn(ColumnID("age", Int.self))
    frame = sampleFrame()
    frame.renameColumn("name", to: "label")
    precondition(frame.containsColumn("label"))
    frame.replaceColumn("age", with: Column<Int>(name: "age", contents: [1, 2, 3, 4]))
    frame.replaceColumn("age", with: AnyColumn(Column<Int>(name: "age", contents: [0, 0, 0, 0])))
    frame.replaceColumn(ColumnID("age", Int.self), with: AnyColumn(Column<Int>(name: "age", contents: [1, 1, 1, 1])))
    frame.replaceColumn(ColumnID("age", Int.self), with: Column<Int>(name: "age", contents: [9, 9, 9, 9]))
    frame.addAlias("n", forColumn: "label")
    _ = frame.columnNames(forAlias: "n")
    frame.removeAlias("n")
    _ = frame["label"]
    frame["label"] = frame["label"]
    frame[dynamicMember: "label"] = frame[dynamicMember: "label"]
    _ = frame[column: 0]
    _ = frame[column: 1, Int.self]
}

func testDataFrameSelectFilterSort() {
    var frame = sampleFrame()
    let selected = frame.selecting(columnNames: "age")
    precondition(selected.shape.columns == 1)
    let selectedSeq = frame.selecting(columnNames: ["name", "age"])
    precondition(selectedSeq.shape.columns == 2)
    let sliced = frame["age"]
    _ = sliced
    let byNames: DataFrame = frame[["name"]]
    precondition(byNames.shape.columns == 1)
    let filtered = frame.filter { ($0["age"] as? Int ?? 0) > 15 }
    precondition(filtered.shape.rows == 3)
    let byID = frame.filter(on: ColumnID("age", Int.self)) { ($0 ?? 0) > 10 }
    precondition(byID.shape.rows == 3)
    let byName = frame.filter(on: "age", Int.self) { ($0 ?? 0) > 10 }
    precondition(byName.shape.rows == 3)
    let mask = frame[[true, false, true, false]]
    precondition(mask.shape.rows == 2)
    frame.sort(on: "age", order: .descending)
    frame.sort(on: ColumnID("age", Int.self), order: .ascending)
    frame.sort(on: "age", Int.self, order: .ascending)
    frame.sort(on: ColumnID("age", Int.self), by: <)
    frame.sort(on: "age", Int.self, by: <)
    frame.sort(on: ColumnID("age", Int.self), ColumnID("name", String.self), order: .ascending)
    frame.sort(on: ColumnID("age", Int.self), ColumnID("name", String.self), ColumnID("name", String.self), order: .ascending)
    let sorted = frame.sorted(on: "age", order: .ascending)
    _ = frame.sorted(on: ColumnID("age", Int.self), order: .descending)
    _ = frame.sorted(on: "age", Int.self, order: .ascending)
    _ = frame.sorted(on: ColumnID("age", Int.self), by: <)
    _ = frame.sorted(on: "age", Int.self, by: <)
    _ = frame.sorted(on: ColumnID("age", Int.self), ColumnID("name", String.self))
    _ = frame.sorted(on: ColumnID("age", Int.self), ColumnID("name", String.self), ColumnID("name", String.self))
    _ = sorted
}

func testDataFramePrefixSuffixRange() {
    let frame = sampleFrame()
    precondition(frame.prefix(2).shape.rows == 2)
    precondition(frame.suffix(1).shape.rows == 1)
    let slice = frame[0..<2]
    precondition(slice.shape.rows == 2)
    _ = frame[0...1]
    _ = frame.base
    _ = frame.rows
    _ = frame.rows.count
    _ = frame.rows.startIndex
    _ = frame.rows.endIndex
    _ = frame.rows.index(after: 0)
    _ = frame.rows.index(before: 1)
    _ = frame.rows[0]
    _ = frame.rows[0..<2]
}

func testDataFrameRowAccess() {
    var frame = sampleFrame()
    var row = frame[row: 0]
    precondition(row.index == 0)
    precondition(row.count == 2)
    _ = row.startIndex
    _ = row.endIndex
    _ = row.index(after: 0)
    _ = row.index(before: 1)
    _ = row.description
    _ = row.debugDescription
    _ = row.customMirror
    _ = row.description(options: FormattingOptions())
    _ = row.base
    _ = row[0]
    _ = row["name"]
    _ = row["age", Int.self]
    _ = row[ColumnID("age", Int.self)]
    _ = row[1, Int.self]
    row[0] = "z"
    frame[row: 0] = row
    precondition(frame[row: 0] == frame[row: 0])
    precondition(frame[row: 0] != frame[row: 1])
    var hasher = Hasher()
    row.hash(into: &hasher)
    _ = row.hashValue
    _ = row[0..<1]
}

func testDataFrameSliceAccess() {
    let frame = sampleFrame()
    var slice = frame[1..<3]
    precondition(slice.shape.rows == 2)
    _ = slice.description
    _ = slice.debugDescription
    _ = slice.customMirror
    _ = slice.base
    _ = slice.columns
    _ = slice.rows
    _ = slice[dynamicMember: "age"]
    _ = slice[ColumnID("age", Int.self)]
    _ = slice["age", Int.self]
    _ = slice["age"]
    _ = slice[["name"]]
    _ = slice[column: 1, Int.self]
    _ = slice.filter(on: ColumnID("age", Int.self)) { ($0 ?? 0) > 0 }
    _ = slice.filter(on: "age", Int.self) { ($0 ?? 0) > 0 }
    _ = slice.prefix(upTo: 1)
    _ = slice.prefix(through: 0)
    _ = slice.prefix(1)
    _ = slice.suffix(from: 0)
    _ = slice.suffix(1)
    _ = slice.selecting(columnNames: "age")
    _ = slice.selecting(columnNames: ["name"])
    _ = slice.summary()
    _ = slice.summary(of: "age")
    _ = slice.summary(ofColumns: 1)
    _ = slice.grouped(by: "name")
    precondition(slice == slice)
    var hasher = Hasher()
    slice.hash(into: &hasher)
    _ = slice.hashValue
    slice.rows = slice.rows
}

func testDataFrameCombineTransformExplode() {
    var frame = sampleFrame()
    frame.combineColumns("name", "age", into: "label") { (name: String?, age: Int?) in
        "\(name ?? ""):\(age ?? 0)"
    }
    frame.combineColumns(ColumnID("name", String.self), ColumnID("age", Int.self), into: "label2") { n, a in
        "\(n ?? "")-\(a ?? 0)"
    }
    frame.combineColumns("name", "age", "age", into: "triple") { (n: String?, a: Int?, b: Int?) in
        (a ?? 0) + (b ?? 0)
    }
    frame.combineColumns(ColumnID("age", Int.self), ColumnID("age", Int.self), ColumnID("age", Int.self), into: "sum3") { a, b, c in
        (a ?? 0) + (b ?? 0) + (c ?? 0)
    }
    frame.transformColumn("age") { (value: Int) in value * 2 }
    frame.transformColumn("age") { (value: Int?) in (value ?? 0) + 1 }
    frame.transformColumn(ColumnID("age", Int.self)) { (value: Int) in value + 1 }
    frame.transformColumn(ColumnID("age", Int.self)) { (value: Int?) in value }
    var nested = DataFrame(columns: [
        AnyColumn(Column<[Int]>(name: "vals", contents: [[1, 2], [3]]))
    ])
    _ = nested.explodingColumn("vals", [Int].self)
    _ = nested.explodingColumn(ColumnID("vals", [Int].self))
    nested.explodeColumn("vals", [Int].self)
    nested = DataFrame(columns: [AnyColumn(Column<[Int]>(name: "vals", contents: [[1], [2, 3]]))])
    nested.explodeColumn(ColumnID("vals", [Int].self))
}

func testDataFrameHashable() {
    let a = sampleFrame()
    let b = sampleFrame()
    precondition(a == b)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = a.hashValue
}

func testDataFrameInitFromSlice() {
    let frame = DataFrame(sampleFrame()[0..<2])
    precondition(frame.shape.rows == 2)
}
