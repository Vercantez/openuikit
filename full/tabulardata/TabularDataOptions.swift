/// Options that control CSV parsing.
public struct CSVReadingOptions {
    public var dateParsers: [(String) -> Date?]
    public var usesQuoting: Bool
    public var hasHeaderRow: Bool
    public var nilEncodings: Set<String>
    public var usesEscaping: Bool
    public var trueEncodings: Set<String>
    public var falseEncodings: Set<String>
    public private(set) var escapeCharacter: Character
    public var floatingPointType: CSVType
    public var ignoresEmptyLines: Bool
    public private(set) var delimiter: Character

    public init(
        hasHeaderRow: Bool = true,
        nilEncodings: Set<String> = [
            "", "#N/A", "#N/A N/A", "#NA", "N/A", "NA", "NULL", "n/a", "nil", "null"
        ],
        trueEncodings: Set<String> = ["1", "True", "TRUE", "true"],
        falseEncodings: Set<String> = ["0", "False", "FALSE", "false"],
        floatingPointType: CSVType = .double,
        ignoresEmptyLines: Bool = true,
        usesQuoting: Bool = true,
        usesEscaping: Bool = false,
        delimiter: Character = Character(","),
        escapeCharacter: Character = Character("\\")
    ) {
        self.hasHeaderRow = hasHeaderRow
        self.nilEncodings = nilEncodings
        self.trueEncodings = trueEncodings
        self.falseEncodings = falseEncodings
        self.floatingPointType = floatingPointType
        self.ignoresEmptyLines = ignoresEmptyLines
        self.usesQuoting = usesQuoting
        self.usesEscaping = usesEscaping
        self.delimiter = delimiter
        self.escapeCharacter = escapeCharacter
        self.dateParsers = []
    }

    public mutating func addDateParseStrategy<T>(_ strategy: T)
    where T: ParseStrategy, T.ParseInput == String, T.ParseOutput == Date {
        dateParsers.append { text in
            try? strategy.parse(text)
        }
    }
}

/// Options that control CSV writing.
public struct CSVWritingOptions {
    public var dateFormat: String?
    public var nilEncoding: String
    public var trueEncoding: String
    public var dateFormatter: (Date) -> String
    public var falseEncoding: String
    public var includesHeader: Bool
    public var newline: String
    public var delimiter: Character

    public init(
        includesHeader: Bool = true,
        dateFormat: String?,
        nilEncoding: String = "",
        trueEncoding: String = "true",
        falseEncoding: String = "false",
        newline: String = "\n",
        delimiter: Character = ","
    ) {
        self.includesHeader = includesHeader
        self.dateFormat = dateFormat
        self.nilEncoding = nilEncoding
        self.trueEncoding = trueEncoding
        self.falseEncoding = falseEncoding
        self.newline = newline
        self.delimiter = delimiter
        if let dateFormat {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = dateFormat
            self.dateFormatter = { formatter.string(from: $0) }
        } else {
            self.dateFormatter = { ISO8601DateFormatter().string(from: $0) }
        }
    }

    public init(
        includesHeader: Bool = true,
        nilEncoding: String = "",
        trueEncoding: String = "true",
        falseEncoding: String = "false",
        newline: String = "\n",
        delimiter: Character = ","
    ) {
        self.init(
            includesHeader: includesHeader,
            dateFormat: nil,
            nilEncoding: nilEncoding,
            trueEncoding: trueEncoding,
            falseEncoding: falseEncoding,
            newline: newline,
            delimiter: delimiter
        )
    }

    public init() {
        self.init(includesHeader: true)
    }
}

/// Options that control textual table rendering.
public struct FormattingOptions {
    public var dateFormatStyle: Date.FormatStyle
    public var maximumRowCount: Int
    public var maximumCellWidth: Int
    public var maximumLineWidth: Int
    public var includesRowIndices: Bool
    public var integerFormatStyle: IntegerFormatStyle<Int>
    public var includesColumnTypes: Bool
    public var floatingPointFormatStyle: FloatingPointFormatStyle<Double>
    public var includesRowAndColumnCounts: Bool
    public var locale: Locale {
        didSet { applyLocale() }
    }

    public init(
        maximumLineWidth: Int,
        maximumCellWidth: Int = 50,
        maximumRowCount: Int = 20,
        includesColumnTypes: Bool = true
    ) {
        self.maximumLineWidth = maximumLineWidth
        self.maximumCellWidth = maximumCellWidth
        self.maximumRowCount = maximumRowCount
        self.includesColumnTypes = includesColumnTypes
        self.includesRowIndices = false
        self.includesRowAndColumnCounts = true
        self.locale = .current
        self.dateFormatStyle = Date.FormatStyle(date: .abbreviated, time: .omitted)
        self.integerFormatStyle = IntegerFormatStyle<Int>()
        self.floatingPointFormatStyle = FloatingPointFormatStyle<Double>()
        applyLocale()
    }

    public init(locale: Locale) {
        self.init(maximumLineWidth: 120)
        self.locale = locale
        applyLocale()
    }

    public init() {
        self.init(maximumLineWidth: 120)
    }

    private mutating func applyLocale() {
        dateFormatStyle = dateFormatStyle.locale(locale)
        integerFormatStyle = integerFormatStyle.locale(locale)
        floatingPointFormatStyle = floatingPointFormatStyle.locale(locale)
    }
}

/// Options that control JSON table parsing.
public struct JSONReadingOptions {
    public var dateParsers: [(String) -> Date?]

    public init() {
        self.dateParsers = []
    }

    public mutating func addDateParseStrategy<T>(_ strategy: T)
    where T: ParseStrategy, T.ParseInput == String, T.ParseOutput == Date {
        dateParsers.append { text in
            try? strategy.parse(text)
        }
    }
}

/// Options that control JSON table writing.
public struct JSONWritingOptions {
    public var prettyPrint: Bool
    public var dateFormatter: (Date) -> String
    public var sortKeys: Bool

    public init() {
        self.prettyPrint = false
        self.sortKeys = false
        self.dateFormatter = { ISO8601DateFormatter().string(from: $0) }
    }
}
