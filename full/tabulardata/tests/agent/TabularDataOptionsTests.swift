import TabularData
import Foundation

func testCSVReadingOptionsDefaults() {
    let options = CSVReadingOptions()
    precondition(options.hasHeaderRow)
    precondition(options.nilEncodings.contains("NA"))
    precondition(options.trueEncodings.contains("true"))
    precondition(options.falseEncodings.contains("false"))
    precondition(options.floatingPointType == .double)
    precondition(options.ignoresEmptyLines)
    precondition(options.usesQuoting)
    precondition(!options.usesEscaping)
    precondition(options.delimiter == ",")
    precondition(options.escapeCharacter == "\\")
    precondition(options.dateParsers.isEmpty)
}

func testCSVReadingOptionsDateStrategy() {
    var options = CSVReadingOptions()
    options.addDateParseStrategy(Date.ISO8601FormatStyle())
    precondition(!options.dateParsers.isEmpty)
    let parsed = options.dateParsers[0]("2020-01-02T00:00:00Z")
    _ = parsed
}

func testCSVWritingOptions() {
    let options = CSVWritingOptions()
    precondition(options.includesHeader)
    precondition(options.nilEncoding == "")
    precondition(options.trueEncoding == "true")
    precondition(options.falseEncoding == "false")
    precondition(options.newline == "\n")
    precondition(options.delimiter == ",")
    precondition(options.dateFormat == nil)
    let formatted = options.dateFormatter(Date(timeIntervalSince1970: 0))
    precondition(!formatted.isEmpty)
    let withFormat = CSVWritingOptions(
        includesHeader: false,
        dateFormat: "yyyy",
        nilEncoding: "NA",
        trueEncoding: "Y",
        falseEncoding: "N",
        newline: "\r\n",
        delimiter: ";"
    )
    precondition(withFormat.dateFormat == "yyyy")
    precondition(!withFormat.includesHeader)
}

func testJSONReadingWritingOptions() {
    var reading = JSONReadingOptions()
    precondition(reading.dateParsers.isEmpty)
    reading.addDateParseStrategy(Date.ISO8601FormatStyle())
    precondition(!reading.dateParsers.isEmpty)
    var writing = JSONWritingOptions()
    precondition(!writing.prettyPrint)
    precondition(!writing.sortKeys)
    writing.prettyPrint = true
    writing.sortKeys = true
    _ = writing.dateFormatter(Date(timeIntervalSince1970: 0))
}

func testFormattingOptions() {
    var options = FormattingOptions()
    precondition(options.maximumLineWidth == 120)
    precondition(options.maximumCellWidth == 50)
    precondition(options.maximumRowCount == 20)
    precondition(options.includesColumnTypes)
    _ = options.dateFormatStyle
    _ = options.integerFormatStyle
    _ = options.floatingPointFormatStyle
    _ = options.includesRowIndices
    _ = options.includesRowAndColumnCounts
    options.locale = Locale(identifier: "en_US")
    let wide = FormattingOptions(maximumLineWidth: 40, maximumCellWidth: 8, maximumRowCount: 2, includesColumnTypes: false)
    precondition(wide.maximumLineWidth == 40)
    let localized = FormattingOptions(locale: Locale(identifier: "en_GB"))
    _ = localized.locale
}

func testNumericSummary() {
    let empty = NumericSummary<Double>()
    precondition(empty.totalCount == 0)
    let summary = NumericSummary<Double>(
        someCount: 4, noneCount: 1, mean: 2.5, standardDeviation: 1,
        min: 1, max: 4, median: 2.5, firstQuartile: 1.5, thirdQuartile: 3.5
    )
    precondition(summary.totalCount == 5)
    precondition(summary == summary)
    precondition(summary != empty)
    _ = summary.debugDescription
    var hasher = Hasher()
    summary.hash(into: &hasher)
    _ = summary.hashValue
}

func testCategoricalSummary() {
    let empty = CategoricalSummary<String>()
    let summary = CategoricalSummary(someCount: 3, noneCount: 1, uniqueCount: 2, mode: ["a"])
    precondition(summary.totalCount == 4)
    precondition(summary == summary)
    precondition(summary != empty)
    _ = summary.debugDescription
    var hasher = Hasher()
    summary.hash(into: &hasher)
    _ = summary.hashValue
    let any = AnyCategoricalSummary(summary)
    precondition(any.someCount == 3)
    precondition(any.noneCount == 1)
    precondition(any.uniqueCount == 2)
    precondition(!any.mode.isEmpty)
    _ = any.totalCount
    _ = any.debugDescription
    _ = any.modeType
    let hashed = AnyCategoricalSummary(CategoricalSummary<AnyHashable>(someCount: 1, noneCount: 0, uniqueCount: 1, mode: [AnyHashable("x")]))
    precondition(hashed != any)
}
