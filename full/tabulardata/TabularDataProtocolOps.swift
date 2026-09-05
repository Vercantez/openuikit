extension DataFrameProtocol {
    public var isEmpty: Bool { shape.rows == 0 || shape.columns == 0 }

    public func description(options: FormattingOptions) -> String {
        let frame = self.base
        var lines: [String] = []
        if options.includesRowAndColumnCounts {
            lines.append("\(shape.rows) rows, \(shape.columns) columns")
        }
        let names = columns.map(\.name)
        var header = names
        if options.includesColumnTypes {
            header = zip(names, columns).map { name, column in
                "\(name)<\(column.wrappedElementType)>"
            }
        }
        lines.append(header.joined(separator: "\t"))
        let limit = min(shape.rows, options.maximumRowCount)
        for row in 0..<limit {
            var cells: [String] = []
            if options.includesRowIndices {
                cells.append(String(row))
            }
            for column in columns {
                let text = tabularDisplay(column[row], options: options)
                cells.append(String(text.prefix(options.maximumCellWidth)))
            }
            var line = cells.joined(separator: "\t")
            if line.count > options.maximumLineWidth {
                line = String(line.prefix(options.maximumLineWidth))
            }
            lines.append(line)
        }
        _ = frame
        return lines.joined(separator: "\n")
    }

    public func csvRepresentation(options: CSVWritingOptions = .init()) throws -> Data {
        try TabularCSV.write(self.base, options: options)
    }

    public func jsonRepresentation(options: JSONWritingOptions = .init()) throws -> Data {
        try TabularJSON.write(self.base, options: options)
    }

    public func writeCSV(to url: URL, options: CSVWritingOptions = .init()) throws {
        try csvRepresentation(options: options).write(to: url)
    }

    public func writeJSON(to url: URL, options: JSONWritingOptions = .init()) throws {
        try jsonRepresentation(options: options).write(to: url)
    }

    public func randomSplit(by proportion: Double, seed: Int? = nil) -> (DataFrame.Slice, DataFrame.Slice) {
        var generator: any RandomNumberGenerator
        if let seed {
            var seeded = TabularSeededGenerator(seed: seed)
            return randomSplit(by: proportion, using: &seeded)
        } else {
            generator = SystemRandomNumberGenerator()
            return randomSplit(by: proportion, using: &generator)
        }
    }

    public func randomSplit<G>(
        by proportion: Double,
        using generator: inout G
    ) -> (DataFrame.Slice, DataFrame.Slice) where G: RandomNumberGenerator {
        var left: [Int] = []
        var right: [Int] = []
        for index in 0..<shape.rows {
            if Double.random(in: 0..<1, using: &generator) < proportion {
                left.append(index)
            } else {
                right.append(index)
            }
        }
        return (
            DataFrame.Slice(frame: base, indices: left),
            DataFrame.Slice(frame: base, indices: right)
        )
    }

    public func stratifiedSplit<T>(
        on columnID: ColumnID<T>,
        by proportion: Double,
        randomSeed: Int? = nil
    ) -> (DataFrame, DataFrame) where T: Hashable {
        stratifiedSplit(on: columnID.name, by: proportion, randomSeed: randomSeed)
    }

    public func stratifiedSplit(
        on columnName: String,
        by proportion: Double,
        randomSeed: Int? = nil
    ) -> (DataFrame, DataFrame) {
        stratifiedSplit(on: [columnName], by: proportion, randomSeed: randomSeed)
    }

    public func stratifiedSplit(
        on columnNames: String...,
        by proportion: Double,
        randomSeed: Int? = nil
    ) -> (DataFrame, DataFrame) {
        stratifiedSplit(on: columnNames, by: proportion, randomSeed: randomSeed)
    }

    public func stratifiedSplit<T0, T1>(
        on columnID0: ColumnID<T0>,
        _ columnID1: ColumnID<T1>,
        by proportion: Double,
        randomSeed: Int? = nil
    ) -> (DataFrame, DataFrame) where T0: Hashable, T1: Hashable {
        stratifiedSplit(on: [columnID0.name, columnID1.name], by: proportion, randomSeed: randomSeed)
    }

    public func stratifiedSplit<T0, T1, T2>(
        on columnID0: ColumnID<T0>,
        _ columnID1: ColumnID<T1>,
        _ columnID2: ColumnID<T2>,
        by proportion: Double,
        randomSeed: Int? = nil
    ) -> (DataFrame, DataFrame) where T0: Hashable, T1: Hashable, T2: Hashable {
        stratifiedSplit(on: [columnID0.name, columnID1.name, columnID2.name], by: proportion, randomSeed: randomSeed)
    }

    func stratifiedSplit(
        on columnNames: [String],
        by proportion: Double,
        randomSeed: Int? = nil
    ) -> (DataFrame, DataFrame) {
        var generator: any RandomNumberGenerator = randomSeed.map { TabularSeededGenerator(seed: $0) } ?? SystemRandomNumberGenerator()
        var buckets: [String: [Int]] = [:]
        var order: [String] = []
        for row in 0..<shape.rows {
            let key = columnNames.map { name in
                base[name][row].map { String(describing: $0) } ?? "<nil>"
            }.joined(separator: "\u{1f}")
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]!.append(row)
        }
        var left: [Int] = []
        var right: [Int] = []
        for key in order {
            let rows = buckets[key]!
            let split = Int((Double(rows.count) * proportion).rounded())
            var shuffled = rows
            shuffled.shuffle(using: &generator)
            left.append(contentsOf: shuffled.prefix(split))
            right.append(contentsOf: shuffled.dropFirst(split))
        }
        return (
            DataFrame(DataFrame.Slice(frame: base, indices: left.sorted())),
            DataFrame(DataFrame.Slice(frame: base, indices: right.sorted()))
        )
    }

    public func joined<R, T>(
        _ other: R,
        on columnIDs: (left: ColumnID<T>, right: ColumnID<T>),
        kind: JoinKind = .inner
    ) -> DataFrame where R: DataFrameProtocol, T: Hashable {
        joined(other, on: (left: columnIDs.left.name, right: columnIDs.right.name), kind: kind)
    }

    public func joined<R, T>(
        _ other: R,
        on columnID: ColumnID<T>,
        kind: JoinKind = .inner
    ) -> DataFrame where R: DataFrameProtocol, T: Hashable {
        joined(other, on: (left: columnID.name, right: columnID.name), kind: kind)
    }

    public func joined<R>(
        _ other: R,
        on columnName: String,
        kind: JoinKind = .inner
    ) -> DataFrame where R: DataFrameProtocol {
        joined(other, on: (left: columnName, right: columnName), kind: kind)
    }

    public func joined<R>(
        _ other: R,
        on columnNames: (left: String, right: String),
        kind: JoinKind = .inner
    ) -> DataFrame where R: DataFrameProtocol {
        tabularJoin(left: base, right: other.base, on: columnNames, kind: kind)
    }

    public func sorted<T>(
        on columnID: ColumnID<T>,
        by areInIncreasingOrder: (T, T) throws -> Bool
    ) rethrows -> DataFrame {
        var copy = base
        try copy.sort(on: columnID, by: areInIncreasingOrder)
        return copy
    }

    public func sorted<T>(on columnID: ColumnID<T>, order: Order = .ascending) -> DataFrame
    where T: Comparable {
        var copy = base
        copy.sort(on: columnID, order: order)
        return copy
    }

    public func sorted(on columnName: String, order: Order = .ascending) -> DataFrame {
        var copy = base
        copy.sort(on: columnName, order: order)
        return copy
    }

    public func sorted<T>(
        on columnName: String,
        _ type: T.Type,
        by areInIncreasingOrder: (T, T) throws -> Bool
    ) rethrows -> DataFrame {
        var copy = base
        try copy.sort(on: columnName, type, by: areInIncreasingOrder)
        return copy
    }

    public func sorted<T0, T1>(
        on columnID0: ColumnID<T0>,
        _ columnID1: ColumnID<T1>,
        order: Order = .ascending
    ) -> DataFrame where T0: Comparable, T1: Comparable {
        var copy = base
        copy.sort(on: columnID0, columnID1, order: order)
        return copy
    }

    public func sorted<T>(
        on columnName: String,
        _ type: T.Type,
        order: Order = .ascending
    ) -> DataFrame where T: Comparable {
        var copy = base
        copy.sort(on: columnName, type, order: order)
        return copy
    }

    public func sorted<T0, T1, T2>(
        on columnID0: ColumnID<T0>,
        _ columnID1: ColumnID<T1>,
        _ columnID2: ColumnID<T2>,
        order: Order = .ascending
    ) -> DataFrame where T0: Comparable, T1: Comparable, T2: Comparable {
        var copy = base
        copy.sort(on: columnID0, columnID1, columnID2, order: order)
        return copy
    }

    public func grouped(by columnID: ColumnID<Date>, timeUnit: Calendar.Component) -> RowGrouping<Int> {
        grouped(by: columnID.name, timeUnit: timeUnit)
    }

    public func grouped(by columnName: String, timeUnit: Calendar.Component) -> RowGrouping<Int> {
        RowGrouping(frame: self, columnName: columnName, timeUnit: timeUnit)
    }

    public func grouped<InputKey, GroupingKey>(
        by columnID: ColumnID<InputKey>,
        transform: (InputKey?) -> GroupingKey?
    ) -> RowGrouping<GroupingKey> where GroupingKey: Hashable {
        grouped(by: columnID.name, transform: transform)
    }

    public func grouped<InputKey, GroupingKey>(
        by columnName: String,
        transform: (InputKey?) -> GroupingKey?
    ) -> RowGrouping<GroupingKey> where GroupingKey: Hashable {
        var buckets: [GroupingKey: [Int]] = [:]
        var order: [GroupingKey] = []
        var nilRows: [Int] = []
        let column = base.typedColumn(columnName, InputKey.self)
        for row in 0..<shape.rows {
            if let key = transform(column[row]) {
                if buckets[key] == nil {
                    order.append(key)
                    buckets[key] = []
                }
                buckets[key]!.append(row)
            } else {
                nilRows.append(row)
            }
        }
        var pairs: [(GroupingKey?, DataFrame)] = order.map {
            (Optional($0), DataFrame(DataFrame.Slice(frame: base, indices: buckets[$0]!)))
        }
        if !nilRows.isEmpty {
            pairs.append((nil, DataFrame(DataFrame.Slice(frame: base, indices: nilRows))))
        }
        return RowGrouping(groups: pairs, groupKeysColumnName: columnName)
    }

    public func grouped<GroupingKey>(
        by columnID: ColumnID<GroupingKey>
    ) -> RowGrouping<GroupingKey> where GroupingKey: Hashable {
        grouped(by: columnID.name, transform: { (value: GroupingKey?) in value })
    }

    public func grouped<T>(by columnIDs: ColumnID<T>...) -> some RowGroupingProtocol where T: Hashable {
        grouped(by: columnIDs.map(\.name))
    }

    public func grouped(by columnNames: String...) -> some RowGroupingProtocol {
        grouped(by: columnNames)
    }

    public func grouped<T0, T1>(
        by column0: ColumnID<T0>,
        _ column1: ColumnID<T1>
    ) -> some RowGroupingProtocol where T0: Hashable, T1: Hashable {
        grouped(by: [column0.name, column1.name])
    }

    public func grouped<T0, T1, T2>(
        by column0: ColumnID<T0>,
        _ column1: ColumnID<T1>,
        _ column2: ColumnID<T2>
    ) -> some RowGroupingProtocol where T0: Hashable, T1: Hashable, T2: Hashable {
        grouped(by: [column0.name, column1.name, column2.name])
    }

    func grouped(by columnNames: [String]) -> RowGrouping<String> {
        base.groupedByNames(columnNames)
    }
}

func tabularJoin(
    left: DataFrame,
    right: DataFrame,
    on columnNames: (left: String, right: String),
    kind: JoinKind
) -> DataFrame {
    var rightIndex: [String: [Int]] = [:]
    for row in 0..<right.rowCount {
        let key = right[columnNames.right][row].map { String(describing: $0) } ?? "<nil>"
        rightIndex[key, default: []].append(row)
    }
    var resultColumns: [AnyColumn] = left.columns.map {
        AnyColumn(
            name: $0.name,
            wrappedElementType: $0.wrappedElementType,
            values: [],
            prototype: $0.prototypeStorage
        )
    }
    let overlapping = Set(left.columns.map(\.name)).intersection(right.columns.map(\.name))
    let rightOnly = right.columns.filter { $0.name != columnNames.right || !overlapping.contains($0.name) }
    let rightStart = resultColumns.count
    for column in rightOnly {
        let name = overlapping.contains(column.name) ? "\(column.name)_right" : column.name
        resultColumns.append(
            AnyColumn(
                name: name,
                wrappedElementType: column.wrappedElementType,
                values: [],
                prototype: column.prototypeStorage
            )
        )
    }

    func append(leftRow: Int?, rightRow: Int?) {
        for index in left.columns.indices {
            resultColumns[index].append(leftRow.map { left.columns[index][$0] } ?? nil)
        }
        for (offset, column) in rightOnly.enumerated() {
            resultColumns[rightStart + offset].append(rightRow.map { column[$0] } ?? nil)
        }
    }

    var matchedRight = Set<Int>()
    for leftRow in 0..<left.rowCount {
        let key = left[columnNames.left][leftRow].map { String(describing: $0) } ?? "<nil>"
        let matches = rightIndex[key] ?? []
        if matches.isEmpty {
            if kind == .left || kind == .full {
                append(leftRow: leftRow, rightRow: nil)
            }
        } else {
            for rightRow in matches {
                matchedRight.insert(rightRow)
                append(leftRow: leftRow, rightRow: rightRow)
            }
        }
    }
    if kind == .right || kind == .full {
        for rightRow in 0..<right.rowCount where !matchedRight.contains(rightRow) {
            append(leftRow: nil, rightRow: rightRow)
        }
    }
    if kind == .inner && resultColumns.allSatisfy({ $0.count == 0 }) {
        return DataFrame(columns: resultColumns)
    }
    return DataFrame(columns: resultColumns)
}
