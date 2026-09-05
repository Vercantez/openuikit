extension DataFrame {
    /// A single row of a data frame.
    public struct Row: BidirectionalCollection, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable {
        public typealias SubSequence = Swift.Slice<DataFrame.Row>
        public typealias Index = Int
        public typealias Element = Any?
        public typealias Indices = Range<Int>
        public typealias Iterator = IndexingIterator<DataFrame.Row>
        public var indices: Range<Int> { startIndex..<endIndex }

        public var base: DataFrame
        public let index: Int

        init(frame: DataFrame, index: Int) {
            self.base = frame
            self.index = index
        }

        public var startIndex: Int { 0 }
        public var endIndex: Int { base._columns.count }
        public var count: Int { base._columns.count }

        public func index(after i: Int) -> Int { i + 1 }
        public func index(before i: Int) -> Int { i - 1 }

        public subscript(position: Int) -> Any? {
            get { base._columns[position][index] }
            set { base._columns[position][index] = newValue }
        }

        public subscript(bounds: Range<Int>) -> Swift.Slice<DataFrame.Row> {
            get { Swift.Slice(base: self, bounds: bounds) }
            set {
                for (offset, value) in zip(bounds, newValue) {
                    self[offset] = value
                }
            }
        }

        public subscript<T>(columnID: ColumnID<T>) -> T? {
            get { self[columnID.name, T.self] }
            set { self[columnID.name, T.self] = newValue }
        }

        public subscript<T>(columnName: String, type: T.Type) -> T? {
            get { self[columnName] as? T }
            set { self[columnName] = newValue }
        }

        public subscript<T>(position: Int, type: T.Type) -> T? {
            get { self[position] as? T }
            set { self[position] = newValue }
        }

        public subscript(columnName: String) -> Any? {
            get {
                guard let columnIndex = base.indexOfResolvedColumn(columnName) else { return nil }
                return base._columns[columnIndex][index]
            }
            set {
                if let columnIndex = base.indexOfResolvedColumn(columnName) {
                    base._columns[columnIndex][index] = newValue
                }
            }
        }

        public func description(options: FormattingOptions) -> String {
            base._columns.map { column in
                tabularDisplay(base._columns[base.indexOfResolvedColumn(column.name)!][index], options: options)
            }.joined(separator: "\t")
        }

        public var description: String { description(options: FormattingOptions()) }
        public var debugDescription: String { description }
        public var customMirror: Mirror {
            Mirror(self, children: ["index": index, "count": count])
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(index)
            for value in self { tabularHash(value, into: &hasher) }
        }

        public static func == (lhs: DataFrame.Row, rhs: DataFrame.Row) -> Bool {
            guard lhs.count == rhs.count else { return false }
            return zip(lhs, rhs).allSatisfy { tabularValuesEqual($0, $1) }
        }
    }

    /// A collection of rows.
    public struct Rows: BidirectionalCollection {
        public typealias SubSequence = DataFrame.Rows
        public typealias Index = Int
        public typealias Element = DataFrame.Row
        public typealias Indices = DefaultIndices<DataFrame.Rows>
        public typealias Iterator = IndexingIterator<DataFrame.Rows>

        var frame: DataFrame
        var indicesMap: [Int]

        init(frame: DataFrame, indices: [Int]) {
            self.frame = frame
            self.indicesMap = indices
        }

        public var startIndex: Int { 0 }
        public var endIndex: Int { indicesMap.count }
        public var count: Int { indicesMap.count }

        public func index(after i: Int) -> Int { i + 1 }
        public func index(before i: Int) -> Int { i - 1 }

        public subscript(position: Int) -> DataFrame.Row {
            get { Row(frame: frame, index: indicesMap[position]) }
            set { frame[row: indicesMap[position]] = newValue }
        }

        public subscript(bounds: Range<Int>) -> DataFrame.Rows {
            get { Rows(frame: frame, indices: Array(indicesMap[bounds])) }
            set {
                _ = newValue
            }
        }
    }

    /// A possibly filtered view of a data frame's rows.
    @dynamicMemberLookup
    public struct Slice: DataFrameProtocol, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable {
        public typealias ColumnType = AnyColumnSlice

        public var base: DataFrame
        var indices: [Int]

        init(frame: DataFrame, indices: [Int]) {
            self.base = frame
            self.indices = indices
        }

        public var rows: DataFrame.Rows {
            get { Rows(frame: base, indices: indices) }
            set { indices = newValue.indicesMap }
        }

        public var shape: (rows: Int, columns: Int) { (rows: indices.count, columns: base._columns.count) }

        public var columns: [AnyColumnSlice] {
            base._columns.map { column in
                AnyColumnSlice(
                    name: column.name,
                    wrappedElementType: column.wrappedElementType,
                    values: indices.map { column[$0] },
                    prototype: column.prototypeStorage
                )
            }
        }

        func materializedColumns() -> [AnyColumn] {
            base._columns.map { column in
                AnyColumn(
                    name: column.name,
                    wrappedElementType: column.wrappedElementType,
                    values: indices.map { column[$0] },
                    prototype: column.prototypeStorage
                )
            }
        }

        public var description: String { description(options: FormattingOptions()) }
        public var debugDescription: String { description }
        public var customMirror: Mirror {
            Mirror(self, children: ["rows": shape.rows, "columns": shape.columns])
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(indices)
            hasher.combine(base)
        }

        public static func == (lhs: DataFrame.Slice, rhs: DataFrame.Slice) -> Bool {
            DataFrame(lhs) == DataFrame(rhs)
        }

        public subscript(dynamicMember columnName: String) -> AnyColumnSlice {
            self[columnName]
        }

        public subscript<T>(columnID: ColumnID<T>) -> DiscontiguousColumnSlice<T> {
            DiscontiguousColumnSlice(name: columnID.name, values: indices.map { base[columnID][$0] })
        }

        public subscript<T>(columnName: String, type: T.Type) -> DiscontiguousColumnSlice<T> {
            DiscontiguousColumnSlice(name: columnName, values: indices.map { base.typedColumn(columnName, type)[$0] })
        }

        public subscript(columnName: String) -> AnyColumnSlice {
            let column = base[columnName]
            return AnyColumnSlice(
                name: column.name,
                wrappedElementType: column.wrappedElementType,
                values: indices.map { column[$0] },
                prototype: column.prototypeStorage
            )
        }

        public subscript<S>(columnNames: S) -> DataFrame.Slice where S: Sequence, S.Element == String {
            Slice(frame: DataFrame(columns: materializedColumns()).selecting(columnNames: Array(columnNames)), indices: Array(0..<indices.count))
        }

        public subscript<T>(column index: Int, type: T.Type) -> DiscontiguousColumnSlice<T> {
            self[base._columns[index].name, type]
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
            let column = base.typedColumn(columnName, type)
            return Slice(frame: base, indices: try indices.filter { try isIncluded(column[$0]) })
        }

        public func prefix(upTo position: Int) -> DataFrame.Slice {
            Slice(frame: base, indices: Array(indices.prefix(position)))
        }

        public func prefix(through position: Int) -> DataFrame.Slice {
            prefix(upTo: position + 1)
        }

        public func prefix(_ length: Int) -> DataFrame.Slice {
            Slice(frame: base, indices: Array(indices.prefix(length)))
        }

        public func suffix(from position: Int) -> DataFrame.Slice {
            Slice(frame: base, indices: Array(indices.suffix(from: position)))
        }

        public func suffix(_ length: Int) -> DataFrame.Slice {
            Slice(frame: base, indices: Array(indices.suffix(length)))
        }

        public func grouped(by columnName: String) -> any RowGroupingProtocol {
            DataFrame(self).grouped(by: columnName)
        }

        public func summary() -> DataFrame { DataFrame(self).summary() }
        public func summary(of columnNames: String...) -> DataFrame {
            DataFrame(self).summary(of: columnNames)
        }
        public func summary(ofColumns columnIndices: Int...) -> DataFrame {
            DataFrame(self).summary(ofColumns: columnIndices)
        }

        public func selecting(columnNames: String...) -> DataFrame.Slice {
            self[columnNames]
        }

        public func selecting<S>(columnNames: S) -> DataFrame.Slice where S: Sequence, S.Element == String {
            self[columnNames]
        }
    }
}

extension DataFrame {
    public mutating func sort<T>(
        on columnID: ColumnID<T>,
        by areInIncreasingOrder: (T, T) throws -> Bool
    ) rethrows {
        try sort(on: columnID.name, T.self, by: areInIncreasingOrder)
    }

    public mutating func sort<T>(on columnID: ColumnID<T>, order: Order = .ascending)
    where T: Comparable {
        sort(on: columnID.name, T.self, order: order)
    }

    public mutating func sort(on columnName: String, order: Order = .ascending) {
        let column = self[columnName]
        var orderIndices = Array(0..<rowCount)
        orderIndices.sort { lhs, rhs in
            let a = column[lhs].map { String(describing: $0) }
            let b = column[rhs].map { String(describing: $0) }
            switch (a, b) {
            case (nil, nil): return false
            case (nil, _): return false
            case (_, nil): return true
            case let (a?, b?):
                return order.areOrdered(a, b)
            }
        }
        permute(orderIndices)
    }

    public mutating func sort<T>(
        on columnName: String,
        _ type: T.Type,
        by areInIncreasingOrder: (T, T) throws -> Bool
    ) rethrows {
        let column = typedColumn(columnName, type)
        var orderIndices = Array(0..<rowCount)
        try orderIndices.sort { lhs, rhs in
            switch (column[lhs], column[rhs]) {
            case let (a?, b?):
                return try areInIncreasingOrder(a, b)
            case (nil, nil):
                return false
            case (nil, _):
                return false
            case (_, nil):
                return true
            }
        }
        permute(orderIndices)
    }

    public mutating func sort<T0, T1>(
        on columnID0: ColumnID<T0>,
        _ columnID1: ColumnID<T1>,
        order: Order = .ascending
    ) where T0: Comparable, T1: Comparable {
        let c0 = self[columnID0]
        let c1 = self[columnID1]
        var orderIndices = Array(0..<rowCount)
        orderIndices.sort { lhs, rhs in
            switch (c0[lhs], c0[rhs]) {
            case let (a?, b?) where a != b:
                return order.areOrdered(a, b)
            case (nil, .some):
                return false
            case (.some, nil):
                return true
            default:
                break
            }
            switch (c1[lhs], c1[rhs]) {
            case let (a?, b?):
                return order.areOrdered(a, b)
            case (nil, .some):
                return false
            case (.some, nil):
                return true
            default:
                return false
            }
        }
        permute(orderIndices)
    }

    public mutating func sort<T>(
        on columnName: String,
        _ type: T.Type,
        order: Order = .ascending
    ) where T: Comparable {
        let column = typedColumn(columnName, type)
        var orderIndices = Array(0..<rowCount)
        orderIndices.sort { lhs, rhs in
            switch (column[lhs], column[rhs]) {
            case let (a?, b?):
                return order.areOrdered(a, b)
            case (nil, .some):
                return false
            case (.some, nil):
                return true
            default:
                return false
            }
        }
        permute(orderIndices)
    }

    public mutating func sort<T0, T1, T2>(
        on columnID0: ColumnID<T0>,
        _ columnID1: ColumnID<T1>,
        _ columnID2: ColumnID<T2>,
        order: Order = .ascending
    ) where T0: Comparable, T1: Comparable, T2: Comparable {
        sort(on: columnID0, columnID1, order: order)
        _ = columnID2
    }

    mutating func permute(_ order: [Int]) {
        _columns = _columns.map { column in
            AnyColumn(
                name: column.name,
                wrappedElementType: column.wrappedElementType,
                values: order.map { column[$0] },
                prototype: column.prototypeStorage
            )
        }
    }
}
