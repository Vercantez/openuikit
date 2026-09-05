extension DataFrame {
    public init(
        csvData data: Data,
        columns: [String]? = nil,
        rows: Range<Int>? = nil,
        types: [String: CSVType] = [:],
        options: CSVReadingOptions = .init()
    ) throws {
        let table = try TabularCSV.read(
            data: data, columns: columns, rows: rows, types: types, options: options
        )
        self.init(columns: table)
    }

    public init<each T>(
        csvData data: Data,
        columns: repeat ColumnID<each T>,
        rows: Range<Int>? = nil,
        options: CSVReadingOptions = .init()
    ) throws {
        var names: [String] = []
        var types: [String: CSVType] = [:]
        for id in repeat each columns {
            names.append(id.name)
            if let csvType = tabularCSVType(of: id.type) {
                types[id.name] = csvType
            }
        }
        try self.init(
            csvData: data,
            columns: names.isEmpty ? nil : names,
            rows: rows,
            types: types,
            options: options
        )
    }

    public init(
        contentsOfCSVFile url: URL,
        columns: [String]? = nil,
        rows: Range<Int>? = nil,
        types: [String: CSVType] = [:],
        options: CSVReadingOptions = .init()
    ) throws {
        let data = try Data(contentsOf: url)
        try self.init(csvData: data, columns: columns, rows: rows, types: types, options: options)
    }

    public init<each T>(
        contentsOfCSVFile url: URL,
        columns: repeat ColumnID<each T>,
        rows: Range<Int>? = nil,
        options: CSVReadingOptions = .init()
    ) throws {
        let data = try Data(contentsOf: url)
        try self.init(csvData: data, columns: repeat each columns, rows: rows, options: options)
    }

    public init(
        jsonData data: Data,
        columns: [String]? = nil,
        types: [String: JSONType] = [:],
        options: JSONReadingOptions = .init()
    ) throws {
        let table = try TabularJSON.read(data: data, columns: columns, types: types, options: options)
        self.init(columns: table)
    }

    public init(
        contentsOfJSONFile url: URL,
        columns: [String]? = nil,
        types: [String: JSONType] = [:],
        options: JSONReadingOptions = .init()
    ) throws {
        let data = try Data(contentsOf: url)
        try self.init(jsonData: data, columns: columns, types: types, options: options)
    }

    public init(
        contentsOfSFrameDirectory url: URL,
        columns: [String]? = nil,
        rows: Range<Int>? = nil
    ) throws {
        _ = (url, columns, rows)
        throw SFrameReadingError.unsupportedArchive(
            "Turi Create SFrame directories are not decoded on Linux"
        )
    }
}

enum TabularCSV {
    static func read(
        data: Data,
        columns requested: [String]?,
        rows: Range<Int>?,
        types: [String: CSVType],
        options: CSVReadingOptions
    ) throws -> [AnyColumn] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw CSVReadingError.unsupportedEncoding("UTF-8")
        }
        let records = try parseRecords(text, options: options)
        guard !records.isEmpty else { return [] }

        var header: [String]
        var body: [[String]]
        if options.hasHeaderRow {
            header = records[0]
            body = Array(records.dropFirst())
        } else {
            header = records[0].indices.map { "col\($0)" }
            body = records
        }

        if options.ignoresEmptyLines {
            body = body.filter { !$0.allSatisfy { $0.isEmpty } }
        }

        if let rows {
            if rows.lowerBound < 0 || rows.upperBound > body.count {
                throw CSVReadingError.outOfBounds(requested: rows.upperBound, actual: body.count)
            }
            body = Array(body[rows])
        }

        let expected = header.count
        for (index, row) in body.enumerated() {
            if row.count != expected {
                throw CSVReadingError.wrongNumberOfColumns(
                    row: index, columns: row.count, expected: expected
                )
            }
        }

        var selected = header
        if let requested {
            for name in requested where !header.contains(name) {
                throw CSVReadingError.missingColumn(columnName: name)
            }
            selected = requested
        }

        var columns: [AnyColumn] = []
        for name in selected {
            guard let columnIndex = header.firstIndex(of: name) else {
                throw CSVReadingError.missingColumn(columnName: name)
            }
            let cells = body.map { $0[columnIndex] }
            let csvType = types[name] ?? inferType(cells, options: options)
            columns.append(try buildColumn(name: name, cells: cells, type: csvType, options: options))
        }
        return columns
    }

    static func parseRecords(_ text: String, options: CSVReadingOptions) throws -> [[String]] {
        var records: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var rowIndex = 0
        var columnIndex = 0
        let delimiter = options.delimiter
        let quote: Character = "\""
        let escape = options.escapeCharacter
        var iterator = text.makeIterator()
        var peeked: Character?

        func nextChar() -> Character? {
            if let existing = peeked {
                peeked = nil
                return existing
            }
            return iterator.next()
        }

        while let character = nextChar() {
            if inQuotes {
                if options.usesEscaping && character == escape {
                    if let escaped = nextChar() {
                        field.append(escaped)
                    }
                    continue
                }
                if options.usesQuoting && character == quote {
                    if let following = nextChar() {
                        if following == quote {
                            field.append(quote)
                        } else {
                            inQuotes = false
                            peeked = following
                        }
                    } else {
                        inQuotes = false
                    }
                    continue
                }
                field.append(character)
                continue
            }

            if options.usesQuoting && character == quote && field.isEmpty {
                inQuotes = true
                continue
            }
            if character == delimiter {
                row.append(field)
                field = ""
                columnIndex += 1
                continue
            }
            if character == "\n" || character == "\r" {
                if character == "\r" {
                    let following = nextChar()
                    if following != "\n" {
                        peeked = following
                    }
                }
                row.append(field)
                records.append(row)
                row = []
                field = ""
                rowIndex += 1
                columnIndex = 0
                continue
            }
            field.append(character)
        }
        if inQuotes {
            throw CSVReadingError.misplacedQuote(row: rowIndex, column: columnIndex)
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            records.append(row)
        }
        return records
    }

    static func inferType(_ cells: [String], options: CSVReadingOptions) -> CSVType {
        let interesting = cells.filter { !options.nilEncodings.contains($0) }
        if interesting.isEmpty { return .string }
        if interesting.allSatisfy({ Int($0) != nil }) { return .integer }
        if interesting.allSatisfy({ Double($0) != nil }) { return options.floatingPointType }
        if interesting.allSatisfy({
            options.trueEncodings.contains($0) || options.falseEncodings.contains($0)
        }) {
            return .boolean
        }
        if interesting.allSatisfy({ parseDate($0, options: options) != nil }) {
            return .date
        }
        return .string
    }

    static func parseDate(_ text: String, options: CSVReadingOptions) -> Date? {
        for parser in options.dateParsers {
            if let date = parser(text) { return date }
        }
        return ISO8601DateFormatter().date(from: text)
    }

    static func buildColumn(
        name: String,
        cells: [String],
        type: CSVType,
        options: CSVReadingOptions
    ) throws -> AnyColumn {
        switch type {
        case .string:
            let values: [String?] = cells.map { options.nilEncodings.contains($0) ? nil : $0 }
            return AnyColumn(Column(name: name, contents: values))
        case .integer:
            var values: [Int?] = []
            for (row, cell) in cells.enumerated() {
                if options.nilEncodings.contains(cell) {
                    values.append(nil)
                } else if let value = Int(cell) {
                    values.append(value)
                } else {
                    throw CSVReadingError.failedToParse(
                        row: row, column: 0, type: .integer, cellContents: Data(cell.utf8)
                    )
                }
            }
            return AnyColumn(Column(name: name, contents: values))
        case .double, .float:
            var values: [Double?] = []
            for (row, cell) in cells.enumerated() {
                if options.nilEncodings.contains(cell) {
                    values.append(nil)
                } else if let value = Double(cell) {
                    values.append(value)
                } else {
                    throw CSVReadingError.failedToParse(
                        row: row, column: 0, type: type, cellContents: Data(cell.utf8)
                    )
                }
            }
            if type == .float {
                return AnyColumn(Column<Float>(name: name, contents: values.map { $0.map { Float($0) } }))
            }
            return AnyColumn(Column(name: name, contents: values))
        case .boolean:
            var values: [Bool?] = []
            for (row, cell) in cells.enumerated() {
                if options.nilEncodings.contains(cell) {
                    values.append(nil)
                } else if options.trueEncodings.contains(cell) {
                    values.append(true)
                } else if options.falseEncodings.contains(cell) {
                    values.append(false)
                } else {
                    throw CSVReadingError.failedToParse(
                        row: row, column: 0, type: .boolean, cellContents: Data(cell.utf8)
                    )
                }
            }
            return AnyColumn(Column(name: name, contents: values))
        case .date:
            var values: [Date?] = []
            for (row, cell) in cells.enumerated() {
                if options.nilEncodings.contains(cell) {
                    values.append(nil)
                } else if let date = parseDate(cell, options: options) {
                    values.append(date)
                } else {
                    throw CSVReadingError.failedToParse(
                        row: row, column: 0, type: .date, cellContents: Data(cell.utf8)
                    )
                }
            }
            return AnyColumn(Column(name: name, contents: values))
        case .data:
            var values: [Data?] = []
            for cell in cells {
                if options.nilEncodings.contains(cell) {
                    values.append(nil)
                } else if let data = Data(base64Encoded: cell) {
                    values.append(data)
                } else {
                    values.append(Data(cell.utf8))
                }
            }
            return AnyColumn(Column(name: name, contents: values))
        }
    }

    static func write(_ frame: DataFrame, options: CSVWritingOptions) throws -> Data {
        var lines: [String] = []
        if options.includesHeader {
            lines.append(frame.columns.map(\.name).map { escape($0, options: options) }.joined(separator: String(options.delimiter)))
        }
        for row in 0..<frame.rowCount {
            var fields: [String] = []
            for column in frame.columns {
                fields.append(escape(render(column[row], options: options), options: options))
            }
            lines.append(fields.joined(separator: String(options.delimiter)))
        }
        guard let data = lines.joined(separator: options.newline).data(using: .utf8) else {
            throw CSVWritingError.badEncoding(row: 0, column: "", Data())
        }
        return data
    }

    static func render(_ value: Any?, options: CSVWritingOptions) -> String {
        guard let value else { return options.nilEncoding }
        switch value {
        case let v as Bool:
            return v ? options.trueEncoding : options.falseEncoding
        case let v as Date:
            return options.dateFormatter(v)
        default:
            return String(describing: value)
        }
    }

    static func escape(_ field: String, options: CSVWritingOptions) -> String {
        let delimiter = String(options.delimiter)
        if field.contains(delimiter) || field.contains("\"") || field.contains(options.newline) {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

enum TabularJSON {
    static func read(
        data: Data,
        columns requested: [String]?,
        types: [String: JSONType],
        options: JSONReadingOptions
    ) throws -> [AnyColumn] {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw JSONReadingError.unsupportedStructure
        }
        if let array = object as? [[String: Any]] {
            return try fromObjectArray(array, columns: requested, types: types, options: options)
        }
        if let dict = object as? [String: [Any]] {
            return try fromColumnDictionary(dict, columns: requested, types: types, options: options)
        }
        throw JSONReadingError.unsupportedStructure
    }

    static func fromObjectArray(
        _ rows: [[String: Any]],
        columns requested: [String]?,
        types: [String: JSONType],
        options: JSONReadingOptions
    ) throws -> [AnyColumn] {
        var names: [String] = []
        var seen = Set<String>()
        for row in rows {
            for key in row.keys where seen.insert(key).inserted {
                names.append(key)
            }
        }
        if let requested {
            for name in requested where !seen.contains(name) {
                throw JSONReadingError.incompatibleValues(column: name)
            }
            names = requested
        }
        var columns: [AnyColumn] = []
        for name in names {
            let cells = rows.map { $0[name] }
            columns.append(try buildColumn(name: name, cells: cells, type: types[name], options: options))
        }
        return columns
    }

    static func fromColumnDictionary(
        _ dict: [String: [Any]],
        columns requested: [String]?,
        types: [String: JSONType],
        options: JSONReadingOptions
    ) throws -> [AnyColumn] {
        var names = Array(dict.keys)
        if let requested { names = requested }
        var columns: [AnyColumn] = []
        for name in names {
            guard let cells = dict[name] else {
                throw JSONReadingError.incompatibleValues(column: name)
            }
            columns.append(try buildColumn(name: name, cells: cells, type: types[name], options: options))
        }
        return columns
    }

    static func buildColumn(
        name: String,
        cells: [Any?],
        type: JSONType?,
        options: JSONReadingOptions
    ) throws -> AnyColumn {
        let normalized = cells.map { value -> Any? in
            if value is NSNull { return nil }
            return value
        }
        switch type {
        case .integer:
            return AnyColumn(Column<Int>(name: name, contents: try normalized.enumerated().map { index, value in
                if value == nil { return nil }
                if let i = value as? Int { return i }
                if let n = value as? NSNumber { return n.intValue }
                throw JSONReadingError.failedToParse(row: index, column: name, type: .integer, contents: String(describing: value!))
            }))
        case .double:
            return AnyColumn(Column<Double>(name: name, contents: try normalized.enumerated().map { index, value in
                if value == nil { return nil }
                if let d = value as? Double { return d }
                if let i = value as? Int { return Double(i) }
                throw JSONReadingError.failedToParse(row: index, column: name, type: .double, contents: String(describing: value!))
            }))
        case .boolean:
            return AnyColumn(Column<Bool>(name: name, contents: try normalized.enumerated().map { index, value in
                if value == nil { return nil }
                if let b = value as? Bool { return b }
                throw JSONReadingError.failedToParse(row: index, column: name, type: .boolean, contents: String(describing: value!))
            }))
        case .string:
            return AnyColumn(Column<String>(name: name, contents: normalized.map { $0.map { String(describing: $0) } }))
        case .date:
            return AnyColumn(Column<Date>(name: name, contents: try normalized.enumerated().map { index, value in
                if value == nil { return nil }
                if let d = value as? Date { return d }
                if let s = value as? String {
                    for parser in options.dateParsers {
                        if let date = parser(s) { return date }
                    }
                    if let date = ISO8601DateFormatter().date(from: s) { return date }
                }
                throw JSONReadingError.failedToParse(row: index, column: name, type: .date, contents: String(describing: value!))
            }))
        case .array, .object:
            return AnyColumn(Column<AnyHashable>(name: name, contents: normalized.map { $0 as? AnyHashable }))
        case .none:
            if normalized.allSatisfy({ $0 == nil || $0 is Int || $0 is NSNumber && !($0 is Bool) })
                && normalized.contains(where: { $0 is Int })
            {
                return try buildColumn(name: name, cells: cells, type: .integer, options: options)
            }
            if normalized.allSatisfy({ $0 == nil || $0 is Double || $0 is Int }) {
                return try buildColumn(name: name, cells: cells, type: .double, options: options)
            }
            if normalized.allSatisfy({ $0 == nil || $0 is Bool }) {
                return try buildColumn(name: name, cells: cells, type: .boolean, options: options)
            }
            return try buildColumn(name: name, cells: cells, type: .string, options: options)
        }
    }

    static func write(_ frame: DataFrame, options: JSONWritingOptions) throws -> Data {
        var rows: [[String: Any]] = []
        for row in 0..<frame.rowCount {
            var object: [String: Any] = [:]
            for column in frame.columns {
                if let value = column[row] {
                    if let date = value as? Date {
                        object[column.name] = options.dateFormatter(date)
                    } else {
                        object[column.name] = value
                    }
                }
            }
            rows.append(object)
        }
        var writing: JSONSerialization.WritingOptions = []
        if options.prettyPrint { writing.insert(.prettyPrinted) }
        if options.sortKeys { writing.insert(.sortedKeys) }
        return try JSONSerialization.data(withJSONObject: rows, options: writing)
    }
}
