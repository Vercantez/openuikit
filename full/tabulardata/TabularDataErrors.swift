/// Errors thrown while parsing CSV bytes or files.
public enum CSVReadingError: Error, LocalizedError, CustomStringConvertible {
    case badEncoding(row: Int, column: Int, cellContents: Data)
    case outOfBounds(requested: Int, actual: Int)
    case failedToParse(row: Int, column: Int, type: CSVType, cellContents: Data)
    case missingColumn(columnName: String)
    case misplacedQuote(row: Int, column: Int)
    case unsupportedEncoding(String)
    case wrongNumberOfColumns(row: Int, columns: Int, expected: Int)
    case unsupportedColumnType(columnIndex: Int, columnName: String, type: String)

    public var row: Int {
        switch self {
        case .badEncoding(let row, _, _),
             .failedToParse(let row, _, _, _),
             .misplacedQuote(let row, _),
             .wrongNumberOfColumns(let row, _, _):
            return row
        case .outOfBounds(let requested, _):
            return requested
        case .missingColumn, .unsupportedEncoding, .unsupportedColumnType:
            return -1
        }
    }

    public var column: Int? {
        switch self {
        case .badEncoding(_, let column, _),
             .failedToParse(_, let column, _, _),
             .misplacedQuote(_, let column):
            return column
        case .unsupportedColumnType(let columnIndex, _, _):
            return columnIndex
        default:
            return nil
        }
    }

    public var description: String { errorDescription ?? "CSVReadingError" }

    public var errorDescription: String? {
        switch self {
        case .badEncoding(let row, let column, _):
            return "Bad encoding at row \(row), column \(column)"
        case .outOfBounds(let requested, let actual):
            return "Requested row \(requested) is out of bounds for \(actual) rows"
        case .failedToParse(let row, let column, let type, _):
            return "Failed to parse \(type) at row \(row), column \(column)"
        case .missingColumn(let columnName):
            return "Missing column \(columnName)"
        case .misplacedQuote(let row, let column):
            return "Misplaced quote at row \(row), column \(column)"
        case .unsupportedEncoding(let name):
            return "Unsupported encoding \(name)"
        case .wrongNumberOfColumns(let row, let columns, let expected):
            return "Row \(row) has \(columns) columns, expected \(expected)"
        case .unsupportedColumnType(let columnIndex, let columnName, let type):
            return "Unsupported column type \(type) for \(columnName) at \(columnIndex)"
        }
    }

    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

/// Errors thrown while encoding CSV.
public enum CSVWritingError: Error, Equatable, CustomStringConvertible {
    case badEncoding(row: Int, column: String, Data)

    public var row: Int {
        switch self {
        case .badEncoding(let row, _, _):
            return row
        }
    }

    public var column: String? {
        switch self {
        case .badEncoding(_, let column, _):
            return column
        }
    }

    public var description: String {
        switch self {
        case .badEncoding(let row, let column, _):
            return "Bad encoding at row \(row), column \(column)"
        }
    }

    public var localizedDescription: String { description }
}

/// Errors thrown while parsing JSON tables.
public enum JSONReadingError: Error, LocalizedError, CustomStringConvertible {
    case failedToParse(row: Int, column: String, type: JSONType, contents: String)
    case incompatibleValues(column: String)
    case unsupportedStructure
    case wrongType(row: Int, column: String, expectedType: JSONType, value: any Sendable)

    public var description: String { errorDescription ?? "JSONReadingError" }

    public var errorDescription: String? {
        switch self {
        case .failedToParse(let row, let column, let type, let contents):
            return "Failed to parse \(type) at row \(row), column \(column): \(contents)"
        case .incompatibleValues(let column):
            return "Incompatible values in column \(column)"
        case .unsupportedStructure:
            return "Unsupported JSON table structure"
        case .wrongType(let row, let column, let expectedType, _):
            return "Wrong type at row \(row), column \(column); expected \(expectedType)"
        }
    }

    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

/// Errors thrown while reading a Turi Create SFrame directory.
///
/// Linux does not include Apple's SFrame decoder. Construction fails closed
/// rather than inventing a successful archive parse.
public enum SFrameReadingError: Error, LocalizedError, CustomStringConvertible {
    case badArchive(String)
    case badEncoding(String)
    case missingColumn(String)
    case missingArchive
    case unsupportedType(Int)
    case unsupportedLayout(String)
    case unsupportedArchive(String)

    public var description: String { errorDescription ?? "SFrameReadingError" }

    public var errorDescription: String? {
        switch self {
        case .badArchive(let message):
            return "Bad SFrame archive: \(message)"
        case .badEncoding(let message):
            return "Bad SFrame encoding: \(message)"
        case .missingColumn(let name):
            return "Missing SFrame column \(name)"
        case .missingArchive:
            return "SFrame archive is missing"
        case .unsupportedType(let code):
            return "Unsupported SFrame type \(code)"
        case .unsupportedLayout(let layout):
            return "Unsupported SFrame layout \(layout)"
        case .unsupportedArchive(let message):
            return "Unsupported SFrame archive: \(message)"
        }
    }

    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

/// A `DecodingError` localized to a column and row.
public struct ColumnDecodingError: Error, LocalizedError, CustomDebugStringConvertible {
    public var columnName: String
    public var rowIndex: Int
    public var decodingError: DecodingError

    public init(columnName: String, rowIndex: Int, decodingError: DecodingError) {
        self.columnName = columnName
        self.rowIndex = rowIndex
        self.decodingError = decodingError
    }

    public var errorDescription: String? {
        "Decoding failed in column \(columnName) at row \(rowIndex): \(decodingError)"
    }

    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
    public var debugDescription: String { errorDescription ?? "ColumnDecodingError" }
}

/// An `EncodingError` localized to a column and row.
public struct ColumnEncodingError: Error, LocalizedError, CustomDebugStringConvertible {
    public var columnName: String
    public var rowIndex: Int
    public var encodingError: EncodingError

    public init(columnName: String, rowIndex: Int, encodingError: EncodingError) {
        self.columnName = columnName
        self.rowIndex = rowIndex
        self.encodingError = encodingError
    }

    public var errorDescription: String? {
        "Encoding failed in column \(columnName) at row \(rowIndex): \(encodingError)"
    }

    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
    public var debugDescription: String { errorDescription ?? "ColumnEncodingError" }
}
