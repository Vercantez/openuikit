import TabularData
import Foundation

func testDataFrameColumnTypeAliases() {
    func columnsOf<Frame: DataFrameProtocol>(_ frame: Frame) -> [Frame.ColumnType] {
        frame.columns
    }
    let frame = sampleFrame()
    let frameColumns: [DataFrame.ColumnType] = columnsOf(frame)
    precondition(!frameColumns.isEmpty)
    let first: DataFrame.ColumnType = frameColumns[0]
    precondition(first.name == "name" || first.count == frame.shape.rows)
    let sliceColumns: [DataFrame.Slice.ColumnType] = columnsOf(frame[0..<1])
    precondition(!sliceColumns.isEmpty)
}

func testDataFrameDictionaryTypeAliases() {
    let key: DataFrame.Key = "n"
    let value: DataFrame.Value = [1, 2]
    let frame: DataFrame = [key: value]
    precondition(frame.shape == (2, 1))
    precondition(frame.columns[0].name == "n")
}

func testDataFrameRowTypeAliases() {
    let row = sampleFrame()[row: 0]
    let index: DataFrame.Row.Index = row.startIndex
    let element: DataFrame.Row.Element = row[index]
    precondition(element != nil)
    let indices: DataFrame.Row.Indices = row.indices
    precondition(indices.contains(index))
    var iterator: DataFrame.Row.Iterator = row.makeIterator()
    precondition(iterator.next() != nil)
    let sub: DataFrame.Row.SubSequence = row[0..<1]
    precondition(sub.count == 1)
}

func testDataFrameRowsTypeAliases() {
    let rows = sampleFrame().rows
    let index: DataFrame.Rows.Index = rows.startIndex
    let element: DataFrame.Rows.Element = rows[index]
    precondition(element.count == 2)
    let indices: DataFrame.Rows.Indices = rows.indices
    precondition(indices.contains(index))
    var iterator: DataFrame.Rows.Iterator = rows.makeIterator()
    precondition(iterator.next() != nil)
    let sub: DataFrame.Rows.SubSequence = rows[0..<1]
    precondition(sub.count == 1)
}

func testColumnTypeAliases() {
    let column = Column<Int>(name: "n", contents: [1, 2])
    let index: Column<Int>.Index = column.startIndex
    let element: Column<Int>.Element = column[index]
    precondition(element == 1)
    let indices: Column<Int>.Indices = column.indices
    precondition(indices.contains(index))
    var iterator: Column<Int>.Iterator = column.makeIterator()
    precondition(iterator.next() == 1)
    let sub: Column<Int>.SubSequence = column[0..<1]
    precondition(sub.count == 1)
}

func testColumnSliceTypeAliases() {
    let slice = ColumnSlice(Column<Int>(name: "n", contents: [4, 5]))
    let index: ColumnSlice<Int>.Index = slice.startIndex
    let element: ColumnSlice<Int>.Element = slice[index]
    precondition(element == 4)
    let indices: ColumnSlice<Int>.Indices = slice.indices
    precondition(indices.contains(index))
    var iterator: ColumnSlice<Int>.Iterator = slice.makeIterator()
    precondition(iterator.next() == 4)
    let sub: ColumnSlice<Int>.SubSequence = slice[0..<1]
    precondition(sub.count == 1)
}

func testDiscontiguousColumnSliceTypeAliases() {
    let slice = DiscontiguousColumnSlice(Column<Int>(name: "n", contents: [8, 9]))
    let index: DiscontiguousColumnSlice<Int>.Index = slice.startIndex
    let element: DiscontiguousColumnSlice<Int>.Element = slice[index]
    precondition(element == 8)
    let indices: DiscontiguousColumnSlice<Int>.Indices = slice.indices
    precondition(indices.contains(index))
    var iterator: DiscontiguousColumnSlice<Int>.Iterator = slice.makeIterator()
    precondition(iterator.next() == 8)
    let sub: DiscontiguousColumnSlice<Int>.SubSequence = slice[0..<1]
    precondition(sub.count == 1)
}

func testAnyColumnTypeAliases() {
    let column = AnyColumn(Column<Int>(name: "n", contents: [2, 3]))
    let index: AnyColumn.Index = column.startIndex
    let element: AnyColumn.Element = column[index]
    precondition(element as? Int == 2)
    let indices: AnyColumn.Indices = column.indices
    precondition(indices.contains(index))
    var iterator: AnyColumn.Iterator = column.makeIterator()
    precondition(iterator.next() as? Int == 2)
    let sub: AnyColumn.SubSequence = column[0..<1]
    precondition(sub.count == 1)
}

func testAnyColumnSliceTypeAliases() {
    let slice = AnyColumnSlice(AnyColumn(Column<Int>(name: "n", contents: [6, 7])))
    let index: AnyColumnSlice.Index = slice.startIndex
    let element: AnyColumnSlice.Element = slice[index]
    precondition(element as? Int == 6)
    let indices: AnyColumnSlice.Indices = slice.indices
    precondition(indices.contains(index))
    var iterator: AnyColumnSlice.Iterator = slice.makeIterator()
    precondition(iterator.next() as? Int == 6)
    let sub: AnyColumnSlice.SubSequence = slice[0..<1]
    precondition(sub.count == 1)
}

func testFilledColumnTypeAliases() {
    let filled = Column<Int>(name: "n", contents: [Optional(1), nil]).filled(with: 0)
    let fill: FilledColumn<Column<Int>>.WrappedElement = 0
    let index: FilledColumn<Column<Int>>.Index = filled.startIndex
    let element: FilledColumn<Column<Int>>.Element = filled[index]
    precondition(element == 1)
    let indices: FilledColumn<Column<Int>>.Indices = filled.indices
    precondition(indices.contains(index))
    var iterator: FilledColumn<Column<Int>>.Iterator = filled.makeIterator()
    precondition(iterator.next() == 1)
    let sub: FilledColumn<Column<Int>>.SubSequence = filled[0..<1]
    precondition(sub.count == 1)
    precondition(filled[filled.index(after: index)] == fill)
}

func testRowGroupingTypeAliases() {
    let frame = DataFrame(columns: [
        AnyColumn(Column<String>(name: "g", contents: ["a", "b", "a"]))
    ])
    let grouping: RowGrouping<String> = frame.grouped(by: ColumnID("g", String.self))
    let index: RowGrouping<String>.Index = grouping.startIndex
    let element: RowGrouping<String>.Element = grouping[index]
    precondition(element.group.shape.rows >= 1)
    let indices: RowGrouping<String>.Indices = grouping.indices
    precondition(indices.contains(index))
    var iterator: RowGrouping<String>.Iterator = grouping.makeIterator()
    precondition(iterator.next() != nil)
    let sub: RowGrouping<String>.SubSequence = grouping[0..<1]
    precondition(sub.count == 1)
}

func testOptionalColumnProtocolWrappedElement() {
    func firstWrapped<C: OptionalColumnProtocol>(_ column: C) -> C.WrappedElement? {
        for value in column {
            if let value { return value }
        }
        return nil
    }
    let got: Int? = firstWrapped(Column<Int>(name: "n", contents: [7, nil]))
    precondition(got == 7)
}
