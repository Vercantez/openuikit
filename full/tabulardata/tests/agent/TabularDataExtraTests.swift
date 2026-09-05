import TabularData
import Foundation

func testCSVReadingOptionsMutability() {
    var options = CSVReadingOptions(
        hasHeaderRow: false,
        nilEncodings: ["x"],
        trueEncodings: ["yes"],
        falseEncodings: ["no"],
        floatingPointType: .float,
        ignoresEmptyLines: false,
        usesQuoting: false,
        usesEscaping: true,
        delimiter: ";",
        escapeCharacter: "/"
    )
    options.hasHeaderRow = true
    options.usesQuoting = true
    options.nilEncodings.insert("NA")
    options.usesEscaping = false
    options.trueEncodings.insert("Y")
    options.falseEncodings.insert("N")
    options.floatingPointType = .float
    options.ignoresEmptyLines = true
    precondition(options.delimiter == ";")
    precondition(options.escapeCharacter == "/")
}

func testProtocolRandomSplitUsing() {
    let frame = sampleFrame()
    var rng = SystemRandomNumberGenerator()
    let (a, b) = frame.randomSplit(by: 0.5, using: &rng)
    precondition(a.shape.rows + b.shape.rows == frame.shape.rows)
    _ = try! frame.csvRepresentation(options: CSVWritingOptions())
    _ = try! frame.jsonRepresentation(options: JSONWritingOptions())
}

func testAnyColumnPrototypeMake() {
    let proto = Column<Int>(name: "n", capacity: 0).prototype
    var named = proto
    named.name = "m"
    let made = named.makeColumn(capacity: 3)
    precondition(made.count == 3)
}

func testColumnDescriptionOptions() {
    let column = Column<Int>(name: "n", contents: [1, nil])
    _ = column.description(options: FormattingOptions(maximumLineWidth: 40))
}

func testCSVDateAndDataTypes() {
    let csv = "when,blob\n2020-01-01T00:00:00Z,YQ==\n"
    var options = CSVReadingOptions()
    options.addDateParseStrategy(Date.ISO8601FormatStyle())
    let frame = try! DataFrame(
        csvData: Data(csv.utf8),
        types: ["when": .date, "blob": .data]
    )
    precondition(frame.shape.rows == 1)
}

func testCSVFloatType() {
    let csv = "x\n1.5\n"
    let frame = try! DataFrame(csvData: Data(csv.utf8), types: ["x": .float])
    precondition(frame.shape.rows == 1)
}

func testJSONIntegerAndBool() {
    let json = """
    [{"n":1,"ok":true},{"n":2,"ok":false}]
    """
    let frame = try! DataFrame(
        jsonData: Data(json.utf8),
        types: ["n": .integer, "ok": .boolean]
    )
    precondition(frame.shape.rows == 2)
}

func testWriteCSVCustomDelimiter() {
    let frame = sampleFrame()
    let data = try! frame.csvRepresentation(
        options: CSVWritingOptions(includesHeader: false, delimiter: ";")
    )
    precondition(String(data: data, encoding: .utf8)!.contains(";"))
}

func testDataFrameRowsMutation() {
    var frame = sampleFrame()
    var rows = frame.rows
    var row = rows[0]
    row["age"] = 99
    rows[0] = row
    frame.rows = rows
}
