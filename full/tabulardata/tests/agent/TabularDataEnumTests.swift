import TabularData
import Foundation

func testCSVTypeCases() {
    let cases: [CSVType] = [.data, .date, .float, .double, .string, .boolean, .integer]
    precondition(Set(cases).count == 7)
    precondition(CSVType.integer == CSVType.integer)
    precondition(CSVType.integer != CSVType.double)
    var hasher = Hasher()
    CSVType.string.hash(into: &hasher)
    _ = CSVType.boolean.hashValue
}

func testJSONTypeCases() {
    let cases: [JSONType] = [.date, .array, .double, .object, .string, .boolean, .integer]
    precondition(Set(cases).count == 7)
    precondition(JSONType.string == .string)
    precondition(JSONType.array != .object)
    var hasher = Hasher()
    JSONType.integer.hash(into: &hasher)
    _ = JSONType.object.hashValue
}

func testOrderCases() {
    precondition(Order.ascending != Order.descending)
    precondition(Order.ascending == Order.ascending)
    precondition(Order.ascending.areOrdered(1, 2))
    precondition(Order.descending.areOrdered(2, 1))
    var hasher = Hasher()
    Order.ascending.hash(into: &hasher)
    _ = Order.descending.hashValue
}

func testJoinKindCases() {
    let kinds: [JoinKind] = [.full, .left, .inner, .right]
    precondition(Set(kinds).count == 4)
    precondition(JoinKind.inner == .inner)
    precondition(JoinKind.left != .right)
    var hasher = Hasher()
    JoinKind.full.hash(into: &hasher)
    _ = JoinKind.right.hashValue
}

func testCSVReadingErrorCases() {
    let errors: [CSVReadingError] = [
        .badEncoding(row: 1, column: 2, cellContents: Data([0x80])),
        .outOfBounds(requested: 9, actual: 3),
        .failedToParse(row: 1, column: 0, type: .integer, cellContents: Data("x".utf8)),
        .missingColumn(columnName: "age"),
        .misplacedQuote(row: 2, column: 1),
        .unsupportedEncoding("latin1"),
        .wrongNumberOfColumns(row: 3, columns: 2, expected: 3),
        .unsupportedColumnType(columnIndex: 0, columnName: "x", type: "foo")
    ]
    for error in errors {
        _ = error.description
        _ = error.errorDescription
        _ = error.localizedDescription
        _ = error.failureReason
        _ = error.recoverySuggestion
        _ = error.helpAnchor
        _ = error.row
        _ = error.column
    }
    precondition(errors[3].column == nil)
}

func testCSVWritingErrorCases() {
    let error = CSVWritingError.badEncoding(row: 4, column: "name", Data())
    precondition(error.row == 4)
    precondition(error.column == "name")
    _ = error.description
    _ = error.localizedDescription
}

func testJSONReadingErrorCases() {
    let errors: [JSONReadingError] = [
        .failedToParse(row: 0, column: "a", type: .integer, contents: "x"),
        .incompatibleValues(column: "b"),
        .unsupportedStructure,
        .wrongType(row: 1, column: "c", expectedType: .boolean, value: 1)
    ]
    for error in errors {
        _ = error.description
        _ = error.errorDescription
        _ = error.localizedDescription
        _ = error.failureReason
        _ = error.recoverySuggestion
        _ = error.helpAnchor
    }
}

func testSFrameReadingErrorCases() {
    let errors: [SFrameReadingError] = [
        .badArchive("corrupt"),
        .badEncoding("utf16"),
        .missingColumn("x"),
        .missingArchive,
        .unsupportedType(9),
        .unsupportedLayout("v2"),
        .unsupportedArchive("linux")
    ]
    for error in errors {
        _ = error.description
        _ = error.errorDescription
        _ = error.localizedDescription
        _ = error.failureReason
        _ = error.recoverySuggestion
        _ = error.helpAnchor
    }
}

func testSummaryColumnIDs() {
    precondition(SummaryColumnIDs.columnName.name == "columnName")
    precondition(SummaryColumnIDs.uniqueCount.name == "uniqueCount")
    precondition(SummaryColumnIDs.firstQuartile.name == "firstQuartile")
    precondition(SummaryColumnIDs.thirdQuartile.name == "thirdQuartile")
    precondition(SummaryColumnIDs.standardDeviation.name == "standardDeviation")
    precondition(SummaryColumnIDs.mean.name == "mean")
    precondition(SummaryColumnIDs.mode.name == "mode")
    precondition(SummaryColumnIDs.median.name == "median")
    precondition(SummaryColumnIDs.maximum.name == "maximum")
    precondition(SummaryColumnIDs.minimum.name == "minimum")
    precondition(SummaryColumnIDs.noneCount.name == "noneCount")
    precondition(SummaryColumnIDs.someCount.name == "someCount")
}

func testColumnDecodingError() {
    let inner = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
    let error = ColumnDecodingError(columnName: "age", rowIndex: 2, decodingError: inner)
    precondition(error.columnName == "age")
    precondition(error.rowIndex == 2)
    _ = error.decodingError
    _ = error.errorDescription
    _ = error.debugDescription
    _ = error.localizedDescription
    _ = error.failureReason
    _ = error.recoverySuggestion
    _ = error.helpAnchor
}

func testColumnEncodingError() {
    let inner = EncodingError.invalidValue(1, .init(codingPath: [], debugDescription: "bad"))
    let error = ColumnEncodingError(columnName: "age", rowIndex: 3, encodingError: inner)
    precondition(error.columnName == "age")
    precondition(error.rowIndex == 3)
    _ = error.encodingError
    _ = error.errorDescription
    _ = error.debugDescription
    _ = error.localizedDescription
    _ = error.failureReason
    _ = error.recoverySuggestion
    _ = error.helpAnchor
}

func testShapedData() {
    let shaped = ShapedData(shape: [2, 2], strides: [2, 1], contents: [1, 2, 3, 4])
    precondition(shaped.shape == [2, 2])
    precondition(shaped.strides == [2, 1])
    precondition(shaped.contents == [1, 2, 3, 4])
    precondition(shaped[1, 0] == 3)
    precondition(shaped == ShapedData(shape: [2, 2], strides: [2, 1], contents: [1, 2, 3, 4]))
    precondition(shaped != ShapedData(shape: [2, 2], strides: [2, 1], contents: [0, 0, 0, 0]))
    var hasher = Hasher()
    shaped.hash(into: &hasher)
    _ = shaped.hashValue
}

func testColumnID() {
    let id = ColumnID("age", Int.self)
    precondition(id.name == "age")
    precondition(id.description == "age")
    _ = id.type
}
