/// A labeled table of columns with equal length.
@dynamicMemberLookup
public struct DataFrame: DataFrameProtocol, ExpressibleByDictionaryLiteral, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable {
    public typealias ColumnType = AnyColumn
    public typealias Key = String
    public typealias Value = [Any?]

    var _columns: [AnyColumn]
    var _aliases: [String: String]

    public init() {
        self._columns = []
        self._aliases = [:]
    }

    public init<S>(columns: S) where S: Sequence, S.Element == AnyColumn {
        self._columns = Array(columns)
        self._aliases = [:]
        let height = _columns.first?.count ?? 0
        for index in _columns.indices {
            if _columns[index].count < height {
                while _columns[index].count < height {
                    _columns[index].append(nil)
                }
            } else if _columns[index].count > height {
                _columns[index].values = Array(_columns[index].values.prefix(height))
            }
        }
    }

    public init(_ other: DataFrame.Slice) {
        self.init(columns: other.materializedColumns())
    }

    public init(dictionaryLiteral elements: (String, [Any?])...) {
        self._aliases = [:]
        self._columns = elements.map { name, values in
            AnyColumn(
                name: name,
                wrappedElementType: Any.self,
                values: values,
                prototype: TypedColumnPrototype<AnyHashable>(name: name)
            )
        }
    }

    public var base: DataFrame { self }
    public var columns: [AnyColumn] { _columns }
    public var shape: (rows: Int, columns: Int) { (rows: rowCount, columns: _columns.count) }
    public var isEmpty: Bool { rowCount == 0 || _columns.isEmpty }
    var rowCount: Int { _columns.first?.count ?? 0 }

    public var rows: DataFrame.Rows {
        get { Rows(frame: self, indices: Array(0..<rowCount)) }
        set {
            guard !newValue.indicesMap.isEmpty else {
                for i in _columns.indices { _columns[i].values = [] }
                return
            }
            var rebuilt: [AnyColumn] = []
            for column in _columns {
                var values: [Any?] = []
                values.reserveCapacity(newValue.indicesMap.count)
                for row in newValue.indicesMap {
                    if row < column.count {
                        values.append(column[row])
                    } else {
                        values.append(nil)
                    }
                }
                rebuilt.append(
                    AnyColumn(
                        name: column.name,
                        wrappedElementType: column.wrappedElementType,
                        values: values,
                        prototype: column.prototypeStorage
                    )
                )
            }
            _columns = rebuilt
        }
    }

    public var description: String { description(options: FormattingOptions()) }
    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["rows": shape.rows, "columns": shape.columns])
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_columns.count)
        hasher.combine(rowCount)
        for column in _columns {
            hasher.combine(column)
        }
    }

    public static func == (lhs: DataFrame, rhs: DataFrame) -> Bool {
        lhs._columns == rhs._columns
    }

    func resolvedName(_ name: String) -> String {
        _aliases[name] ?? name
    }

    func indexOfResolvedColumn(_ columnName: String) -> Int? {
        let resolved = resolvedName(columnName)
        return _columns.firstIndex { $0.name == resolved || $0.name == columnName }
    }

    public func indexOfColumn(_ columnName: String) -> Int? {
        indexOfResolvedColumn(columnName)
    }

    public func containsColumn(_ name: String) -> Bool {
        indexOfResolvedColumn(name) != nil
    }

    public func containsColumn<T>(_ id: ColumnID<T>) -> Bool {
        containsColumn(id.name)
    }

    public func containsColumn<T>(_ name: String, _ type: T.Type) -> Bool {
        guard let index = indexOfResolvedColumn(name) else { return false }
        return _columns[index].wrappedElementType == type
    }

    public func columnNames(forAlias alias: String) -> [String] {
        _aliases.filter { $0.key == alias }.map(\.value)
    }

    public mutating func addAlias(_ alias: String, forColumn columnName: String) {
        _aliases[alias] = columnName
    }

    public mutating func removeAlias(_ alias: String) {
        _aliases[alias] = nil
    }

    public subscript(dynamicMember columnName: String) -> AnyColumn {
        get { self[columnName] }
        set { self[columnName] = newValue }
    }

    public subscript(columnName: String) -> AnyColumn {
        get {
            guard let index = indexOfResolvedColumn(columnName) else {
                return AnyColumn(Column<AnyHashable>(name: columnName, capacity: rowCount))
            }
            return _columns[index]
        }
        set {
            if let index = indexOfResolvedColumn(columnName) {
                var column = newValue
                column.name = _columns[index].name
                _columns[index] = column
            } else {
                _columns.append(newValue)
            }
        }
    }

    public subscript<T>(id: ColumnID<T>) -> Column<T> {
        get { typedColumn(id.name, T.self) }
        set { self[id.name] = AnyColumn(newValue) }
    }

    public subscript<T>(columnName: String, type: T.Type) -> Column<T> {
        get {
            self[columnName].assumingType(type)
        }
        set {
            self[columnName] = AnyColumn(newValue)
        }
    }

    public subscript<T>(columnName: String, type: T.Type = T.self) -> [T?] {
        get { self[columnName].assumingType(type).values }
        set { self[columnName] = AnyColumn(Column<T>(name: columnName, contents: newValue)) }
    }

    func typedColumn<T>(_ name: String, _ type: T.Type) -> Column<T> {
        self[name].assumingType(type)
    }

    public subscript(column index: Int) -> AnyColumn {
        get { _columns[index] }
        set { _columns[index] = newValue }
    }

    public subscript<T>(column index: Int, type: T.Type) -> Column<T> {
        get { _columns[index].assumingType(type) }
        set { _columns[index] = AnyColumn(newValue) }
    }

    public subscript(row index: Int) -> DataFrame.Row {
        get { Row(frame: self, index: index) }
        set {
            for columnIndex in _columns.indices {
                _columns[columnIndex][index] = newValue[columnIndex]
            }
        }
    }

    public subscript<S>(columnNames: S) -> DataFrame where S: Sequence, S.Element == String {
        let names = Set(columnNames)
        return DataFrame(columns: _columns.filter { names.contains($0.name) })
    }

    public subscript<C>(mask: C) -> DataFrame.Slice where C: Collection, C.Element == Bool {
        var indices: [Int] = []
        for (index, flag) in zip(0..<rowCount, mask) where flag {
            indices.append(index)
        }
        return Slice(frame: self, indices: indices)
    }

    public subscript(range: Range<Int>) -> DataFrame.Slice {
        get { Slice(frame: self, indices: Array(range)) }
        set {
            let values = newValue
            _ = values
        }
    }

    public subscript<R>(r: R) -> DataFrame.Slice where R: RangeExpression, R.Bound == Int {
        get { self[r.relative(to: 0..<rowCount)] }
        set { self[r.relative(to: 0..<rowCount)] = newValue }
    }

    public mutating func append(column: AnyColumn) {
        var column = column
        while column.count < rowCount { column.append(nil) }
        if rowCount == 0 || column.count == rowCount {
            _columns.append(column)
        } else {
            column.values = Array(column.values.prefix(rowCount))
            _columns.append(column)
        }
    }

    public mutating func append<T>(column: Column<T>) {
        append(column: AnyColumn(column))
    }

    public mutating func appendEmptyRow() {
        if _columns.isEmpty {
            return
        }
        for index in _columns.indices {
            _columns[index].append(nil)
        }
    }

    public mutating func append(valuesByColumn dictionary: [String: Any?]) {
        if _columns.isEmpty {
            for (name, value) in dictionary {
                _columns.append(
                    AnyColumn(
                        name: name,
                        wrappedElementType: type(of: value as Any),
                        values: [value],
                        prototype: TypedColumnPrototype<AnyHashable>(name: name)
                    )
                )
            }
            return
        }
        for index in _columns.indices {
            _columns[index].append(dictionary[_columns[index].name] ?? nil)
        }
    }

    public mutating func append(row: DataFrame.Row) {
        for index in _columns.indices {
            _columns[index].append(row[_columns[index].name])
        }
    }

    public mutating func append(row: Any?...) {
        for (index, value) in row.enumerated() {
            if index < _columns.count {
                _columns[index].append(value)
            }
        }
    }

    public mutating func append(rowsOf other: DataFrame) {
        append(other)
    }

    public mutating func append(_ other: DataFrame) {
        for index in _columns.indices {
            if let match = other.indexOfResolvedColumn(_columns[index].name) {
                _columns[index].append(contentsOf: other._columns[match])
            } else {
                for _ in 0..<other.rowCount {
                    _columns[index].append(nil)
                }
            }
        }
    }

    public mutating func append(_ other: DataFrame.Slice) {
        append(DataFrame(other))
    }

    public mutating func insert(row: DataFrame.Row, at index: Int) {
        for columnIndex in _columns.indices {
            _columns[columnIndex].values.insert(row[columnIndex], at: index)
        }
    }

    public mutating func insert(column: AnyColumn, at index: Int) {
        _columns.insert(column, at: index)
    }

    public mutating func insert<T>(column: Column<T>, at index: Int) {
        insert(column: AnyColumn(column), at: index)
    }

    public mutating func removeRow(at index: Int) {
        for columnIndex in _columns.indices {
            _columns[columnIndex].remove(at: index)
        }
    }

    @discardableResult
    public mutating func removeColumn(_ name: String) -> AnyColumn {
        let index = indexOfResolvedColumn(name)!
        return _columns.remove(at: index)
    }

    @discardableResult
    public mutating func removeColumn<T>(_ id: ColumnID<T>) -> Column<T> {
        removeColumn(id.name).assumingType(T.self)
    }

    public mutating func renameColumn(_ name: String, to newName: String) {
        if let index = indexOfResolvedColumn(name) {
            _columns[index].name = newName
        }
    }

    public mutating func replaceColumn(_ name: String, with newColumn: AnyColumn) {
        if let index = indexOfResolvedColumn(name) {
            _columns[index] = newColumn
        }
    }

    public mutating func replaceColumn<T>(_ name: String, with newColumn: Column<T>) {
        replaceColumn(name, with: AnyColumn(newColumn))
    }

    public mutating func replaceColumn<T>(_ id: ColumnID<T>, with newColumn: AnyColumn) {
        replaceColumn(id.name, with: newColumn)
    }

    public mutating func replaceColumn<T, U>(_ id: ColumnID<T>, with newColumn: Column<U>) {
        replaceColumn(id.name, with: AnyColumn(newColumn))
    }

    public func selecting(columnNames: String...) -> DataFrame {
        self[columnNames]
    }

    public func selecting<S>(columnNames: S) -> DataFrame where S: Sequence, S.Element == String {
        self[columnNames]
    }

    public func prefix(_ maxLength: Int) -> DataFrame.Slice {
        Slice(frame: self, indices: Array(0..<Swift.min(maxLength, rowCount)))
    }

    public func suffix(_ maxLength: Int) -> DataFrame.Slice {
        let start = Swift.max(rowCount - maxLength, 0)
        return Slice(frame: self, indices: Array(start..<rowCount))
    }

    public func filter(_ isIncluded: (DataFrame.Row) throws -> Bool) rethrows -> DataFrame.Slice {
        var indices: [Int] = []
        for index in 0..<rowCount {
            if try isIncluded(Row(frame: self, index: index)) {
                indices.append(index)
            }
        }
        return Slice(frame: self, indices: indices)
    }

    public func filter<T>(
        on columnID: ColumnID<T>,
        _ isIncluded: (T?) throws -> Bool
    ) rethrows -> DataFrame.Slice {
        try filter(on: columnID.name, T.self, isIncluded)
    }

    public func filter<T>(
        on columnName: String,
        _ type: T.Type,
        _ isIncluded: (T?) throws -> Bool
    ) rethrows -> DataFrame.Slice {
        let column = typedColumn(columnName, type)
        var indices: [Int] = []
        for index in 0..<rowCount where try isIncluded(column[index]) {
            indices.append(index)
        }
        return Slice(frame: self, indices: indices)
    }

    public mutating func transformColumn<From, To>(
        _ id: ColumnID<From>,
        _ transform: (From) throws -> To?
    ) rethrows {
        try transformColumn(id.name, transform)
    }

    public mutating func transformColumn<From, To>(
        _ id: ColumnID<From>,
        _ transform: (From?) throws -> To?
    ) rethrows {
        try transformOptionalColumn(id.name, transform)
    }

    public mutating func transformColumn<From, To>(
        _ name: String,
        _ transform: (From) throws -> To?
    ) rethrows {
        let source = typedColumn(name, From.self)
        replaceColumn(name, with: try source.mapNonNil(transform))
    }

    public mutating func transformColumn<From, To>(
        _ name: String,
        _ transform: (From?) throws -> To?
    ) rethrows {
        try transformOptionalColumn(name, transform)
    }

    mutating func transformOptionalColumn<From, To>(
        _ name: String,
        _ transform: (From?) throws -> To?
    ) rethrows {
        let source = typedColumn(name, From.self)
        replaceColumn(name, with: try source.map(transform))
    }

    public mutating func combineColumns<E1, E2, R>(
        _ columnID1: ColumnID<E1>,
        _ columnID2: ColumnID<E2>,
        into newColumnName: String,
        transform: (E1?, E2?) throws -> R?
    ) rethrows {
        try combineColumns(columnID1.name, columnID2.name, into: newColumnName, transform: transform)
    }

    public mutating func combineColumns<E1, E2, R>(
        _ columnName1: String,
        _ columnName2: String,
        into newColumnName: String,
        transform: (E1?, E2?) throws -> R?
    ) rethrows {
        let a = typedColumn(columnName1, E1.self)
        let b = typedColumn(columnName2, E2.self)
        var result = Column<R>(name: newColumnName, capacity: rowCount)
        for index in 0..<rowCount {
            result[index] = try transform(a[index], b[index])
        }
        append(column: result)
    }

    public mutating func combineColumns<E1, E2, E3, R>(
        _ columnID1: ColumnID<E1>,
        _ columnID2: ColumnID<E2>,
        _ columnID3: ColumnID<E3>,
        into newColumnName: String,
        transform: (E1?, E2?, E3?) throws -> R?
    ) rethrows {
        try combineColumns(
            columnID1.name, columnID2.name, columnID3.name,
            into: newColumnName, transform: transform
        )
    }

    public mutating func combineColumns<E1, E2, E3, R>(
        _ columnName1: String,
        _ columnName2: String,
        _ columnName3: String,
        into newColumnName: String,
        transform: (E1?, E2?, E3?) throws -> R?
    ) rethrows {
        let a = typedColumn(columnName1, E1.self)
        let b = typedColumn(columnName2, E2.self)
        let c = typedColumn(columnName3, E3.self)
        var result = Column<R>(name: newColumnName, capacity: rowCount)
        for index in 0..<rowCount {
            result[index] = try transform(a[index], b[index], c[index])
        }
        append(column: result)
    }

    public mutating func explodeColumn<T>(_ id: ColumnID<T>) where T: Collection {
        explodeColumn(id.name, T.self)
    }

    public mutating func explodeColumn<T>(_ name: String, _ type: T.Type) where T: Collection {
        self = explodingColumn(name, type)
    }

    public func explodingColumn<T>(_ id: ColumnID<T>) -> DataFrame where T: Collection {
        explodingColumn(id.name, T.self)
    }

    public func explodingColumn<T>(_ name: String, _ type: T.Type) -> DataFrame where T: Collection {
        let source = typedColumn(name, type)
        var columns = _columns.map {
            AnyColumn(
                name: $0.name,
                wrappedElementType: $0.wrappedElementType,
                values: [],
                prototype: $0.prototypeStorage
            )
        }
        guard let explodedIndex = indexOfResolvedColumn(name) else { return self }
        for row in 0..<rowCount {
            if let collection = source[row] {
                let items = Array(collection)
                if items.isEmpty {
                    for index in columns.indices {
                        columns[index].append(index == explodedIndex ? nil : _columns[index][row])
                    }
                } else {
                    for item in items {
                        for index in columns.indices {
                            if index == explodedIndex {
                                columns[index].append(item)
                            } else {
                                columns[index].append(_columns[index][row])
                            }
                        }
                    }
                }
            } else {
                for index in columns.indices {
                    columns[index].append(_columns[index][row])
                }
            }
        }
        return DataFrame(columns: columns)
    }

    public func grouped(by columnName: String) -> any RowGroupingProtocol {
        groupedByNames([columnName])
    }

    func groupedByNames(_ names: [String]) -> RowGrouping<String> {
        var groups: [String: [Int]] = [:]
        var order: [String] = []
        for row in 0..<rowCount {
            let key = names.map { name in
                self[name][row].map { String(describing: $0) } ?? "<nil>"
            }.joined(separator: "\u{1f}")
            if groups[key] == nil {
                order.append(key)
                groups[key] = []
            }
            groups[key]!.append(row)
        }
        let pairs: [(String?, DataFrame)] = order.map { key in
            (key, DataFrame(Slice(frame: self, indices: groups[key]!)))
        }
        return RowGrouping(groups: pairs, groupKeysColumnName: names.first ?? "key")
    }

    public func summary() -> DataFrame {
        summary(of: _columns.map(\.name))
    }

    public func summary(of columnNames: String...) -> DataFrame {
        summary(of: columnNames)
    }

    public func summary(of columnNames: [String]) -> DataFrame {
        var nameCol = Column<String>(name: SummaryColumnIDs.columnName.name, contents: [String]())
        var someCol = Column<Int>(name: SummaryColumnIDs.someCount.name, contents: [Int]())
        var noneCol = Column<Int>(name: SummaryColumnIDs.noneCount.name, contents: [Int]())
        var uniqueCol = Column<Int>(name: SummaryColumnIDs.uniqueCount.name, contents: [Int]())
        var meanCol = Column<Double>(name: SummaryColumnIDs.mean.name, contents: [Double]())
        var minCol = Column<Double>(name: SummaryColumnIDs.minimum.name, contents: [Double]())
        var maxCol = Column<Double>(name: SummaryColumnIDs.maximum.name, contents: [Double]())
        var medianCol = Column<Double>(name: SummaryColumnIDs.median.name, contents: [Double]())
        var sdCol = Column<Double>(name: SummaryColumnIDs.standardDeviation.name, contents: [Double]())
        var q1Col = Column<Double>(name: SummaryColumnIDs.firstQuartile.name, contents: [Double]())
        var q3Col = Column<Double>(name: SummaryColumnIDs.thirdQuartile.name, contents: [Double]())
        for name in columnNames {
            guard containsColumn(name) else { continue }
            nameCol.append(name)
            let values = self[name].values
            let doubles = values.map { tabularDouble($0) }
            if doubles.contains(where: { $0 != nil }) {
                let numeric = tabularNumericSummary(doubles)
                someCol.append(numeric.someCount)
                noneCol.append(numeric.noneCount)
                uniqueCol.append(Set(doubles.compactMap { $0 }).count)
                meanCol.append(numeric.mean)
                minCol.append(numeric.min)
                maxCol.append(numeric.max)
                medianCol.append(numeric.median)
                sdCol.append(numeric.standardDeviation)
                q1Col.append(numeric.firstQuartile)
                q3Col.append(numeric.thirdQuartile)
            } else {
                let strings = values.map { $0.map { String(describing: $0) } }
                let categorical = tabularCategoricalSummary(strings)
                someCol.append(categorical.someCount)
                noneCol.append(categorical.noneCount)
                uniqueCol.append(categorical.uniqueCount)
                meanCol.append(nil)
                minCol.append(nil)
                maxCol.append(nil)
                medianCol.append(nil)
                sdCol.append(nil)
                q1Col.append(nil)
                q3Col.append(nil)
            }
        }
        return DataFrame(columns: [
            AnyColumn(nameCol), AnyColumn(someCol), AnyColumn(noneCol), AnyColumn(uniqueCol),
            AnyColumn(meanCol), AnyColumn(minCol), AnyColumn(maxCol), AnyColumn(medianCol),
            AnyColumn(sdCol), AnyColumn(q1Col), AnyColumn(q3Col)
        ])
    }

    public func summary(ofColumns columnIndices: Int...) -> DataFrame {
        summary(ofColumns: columnIndices)
    }

    public func summary(ofColumns columnIndices: [Int]) -> DataFrame {
        summary(of: columnIndices.map { _columns[$0].name })
    }
}

func tabularDouble(_ value: Any?) -> Double? {
    switch value {
    case let v as Double: return v
    case let v as Float: return Double(v)
    case let v as Int: return Double(v)
    case let v as Int64: return Double(v)
    default: return nil
    }
}
