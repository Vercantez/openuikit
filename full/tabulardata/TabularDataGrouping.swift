/// Groups of rows sharing a key.
public struct RowGrouping<GroupingKey>: RowGroupingProtocol, BidirectionalCollection
where GroupingKey: Hashable {
    public typealias SubSequence = Swift.Slice<RowGrouping<GroupingKey>>
    public typealias Index = Int
    public typealias Element = (key: GroupingKey?, group: DataFrame.Slice)
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<RowGrouping<GroupingKey>>
    public var indices: Range<Int> { startIndex..<endIndex }

    public var groupKeysColumnName: String
    var keys: [GroupingKey?]
    var frames: [DataFrame]

    public init<D>(frame: D, columnName: String, timeUnit: Calendar.Component)
    where GroupingKey == Int, D: DataFrameProtocol {
        self.groupKeysColumnName = columnName
        let calendar = Calendar.current
        var buckets: [Int: [Int]] = [:]
        var order: [Int] = []
        let source = frame.base
        let dates = source.typedColumn(columnName, Date.self)
        for row in 0..<source.rowCount {
            guard let date = dates[row] else { continue }
            let key = calendar.component(timeUnit, from: date)
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]!.append(row)
        }
        self.keys = order
        self.frames = order.map { DataFrame(DataFrame.Slice(frame: source, indices: buckets[$0]!)) }
    }

    public init<D>(groups: [(GroupingKey?, D)], groupKeysColumnName: String)
    where D: DataFrameProtocol {
        self.groupKeysColumnName = groupKeysColumnName
        self.keys = groups.map(\.0)
        self.frames = groups.map { pair in
            let columns = pair.1.columns.map { column in
                AnyColumn(
                    name: column.name,
                    wrappedElementType: column.wrappedElementType,
                    values: (0..<column.count).map { column[$0] },
                    prototype: TypedColumnPrototype<AnyHashable>(name: column.name)
                )
            }
            return DataFrame(columns: columns)
        }
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { keys.count }
    public var count: Int { keys.count }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }

    public subscript(position: Int) -> (key: GroupingKey?, group: DataFrame.Slice) {
        (keys[position], frames[position][0..<frames[position].rowCount])
    }

    public var description: String {
        "RowGrouping(\(count) groups on \(groupKeysColumnName))"
    }

    public func ungrouped() -> DataFrame {
        var result = DataFrame()
        for frame in frames {
            if result.columns.isEmpty {
                result = frame
            } else {
                result.append(frame)
            }
        }
        return result
    }

    public func filter(_ isIncluded: (DataFrame.Slice) throws -> Bool) rethrows -> Self {
        var nextKeys: [GroupingKey?] = []
        var nextFrames: [DataFrame] = []
        for (key, frame) in zip(keys, frames) {
            let slice = frame[0..<frame.rowCount]
            if try isIncluded(slice) {
                nextKeys.append(key)
                nextFrames.append(frame)
            }
        }
        var copy = self
        copy.keys = nextKeys
        copy.frames = nextFrames
        return copy
    }

    public func mapGroups(_ transform: (DataFrame.Slice) throws -> DataFrame) rethrows -> Self {
        var next = self
        next.frames = try frames.map { try transform($0[0..<$0.rowCount]) }
        return next
    }

    public func randomSplit(by proportion: Double) -> (Self, Self) {
        randomSplit(by: proportion, seed: nil)
    }

    public func randomSplit(by proportion: Double, seed: Int?) -> (Self, Self) {
        var generator: any RandomNumberGenerator = seed.map { TabularSeededGenerator(seed: $0) } ?? SystemRandomNumberGenerator()
        var leftKeys: [GroupingKey?] = []
        var leftFrames: [DataFrame] = []
        var rightKeys: [GroupingKey?] = []
        var rightFrames: [DataFrame] = []
        for (key, frame) in zip(keys, frames) {
            if Double.random(in: 0..<1, using: &generator) < proportion {
                leftKeys.append(key)
                leftFrames.append(frame)
            } else {
                rightKeys.append(key)
                rightFrames.append(frame)
            }
        }
        var left = self
        left.keys = leftKeys
        left.frames = leftFrames
        var right = self
        right.keys = rightKeys
        right.frames = rightFrames
        return (left, right)
    }

    public func counts(order: Order?) -> DataFrame {
        var keyCol = Column<String>(name: groupKeysColumnName, contents: keys.map { $0.map { String(describing: $0) } })
        var countCol = Column<Int>(name: "count", contents: frames.map(\.rowCount))
        if let order {
            let paired = zip(keyCol.values, countCol.values).enumerated().sorted { lhs, rhs in
                order.areOrdered(lhs.element.1 ?? 0, rhs.element.1 ?? 0)
            }
            keyCol = Column(name: groupKeysColumnName, contents: paired.map { $0.element.0 })
            countCol = Column(name: "count", contents: paired.map { $0.element.1 })
        }
        return DataFrame(columns: [AnyColumn(keyCol), AnyColumn(countCol)])
    }

    public func counts() -> DataFrame { counts(order: nil) }

    public func aggregated<Element, Result>(
        on columnNames: [String],
        naming: (String) -> String,
        transform: (DiscontiguousColumnSlice<Element>) throws -> Result?
    ) rethrows -> DataFrame {
        var keyCol = Column<String>(name: groupKeysColumnName, contents: [String?]())
        var resultColumns: [String: Column<Result>] = [:]
        for name in columnNames {
            resultColumns[name] = Column<Result>(name: naming(name), contents: [Result?]())
        }
        for (key, frame) in zip(keys, frames) {
            keyCol.append(key.map { String(describing: $0) })
            for name in columnNames {
                let slice = DiscontiguousColumnSlice<Element>(
                    name: name,
                    values: frame.typedColumn(name, Element.self).values
                )
                resultColumns[name]!.append(try transform(slice))
            }
        }
        var columns = [AnyColumn(keyCol)]
        for name in columnNames {
            columns.append(AnyColumn(resultColumns[name]!))
        }
        return DataFrame(columns: columns)
    }

    public func aggregated<Element, Result>(
        on columnID: ColumnID<Element>,
        into aggregatedColumnName: String? = nil,
        transform: (DiscontiguousColumnSlice<Element>) throws -> Result?
    ) rethrows -> DataFrame {
        try aggregated(
            on: [columnID.name],
            naming: { _ in aggregatedColumnName ?? columnID.name },
            transform: transform
        )
    }

    public func aggregated<Element, Result>(
        on columnNames: String...,
        naming: (String) -> String,
        transform: (DiscontiguousColumnSlice<Element>) throws -> Result?
    ) rethrows -> DataFrame {
        try aggregated(on: columnNames, naming: naming, transform: transform)
    }

    public func sums<N>(_ columnID: ColumnID<N>, order: Order? = nil) -> DataFrame
    where N: AdditiveArithmetic, N: Comparable {
        sums(columnID.name, N.self, order: order)
    }

    public func sums<N>(_ columnName: String, _ type: N.Type, order: Order? = nil) -> DataFrame
    where N: AdditiveArithmetic, N: Comparable {
        let frame = aggregated(on: [columnName], naming: { $0 }) { (slice: DiscontiguousColumnSlice<N>) in
            slice.sum()
        }
        _ = order
        return frame
    }

    public func means<N>(_ columnID: ColumnID<N>, order: Order? = nil) -> DataFrame
    where N: FloatingPoint {
        means(columnID.name, N.self, order: order)
    }

    public func means<N>(_ columnName: String, _ type: N.Type, order: Order? = nil) -> DataFrame
    where N: FloatingPoint {
        let frame = aggregated(on: [columnName], naming: { $0 }) { (slice: DiscontiguousColumnSlice<N>) -> N? in
            let present = slice.values.compactMap { $0 }
            guard !present.isEmpty else { return nil }
            return present.reduce(N.zero, +) / N(present.count)
        }
        _ = order
        return frame
    }

    public func maximums<N>(_ columnID: ColumnID<N>, order: Order? = nil) -> DataFrame
    where N: Comparable {
        maximums(columnID.name, N.self, order: order)
    }

    public func maximums<N>(_ columnName: String, _ type: N.Type, order: Order? = nil) -> DataFrame
    where N: Comparable {
        aggregated(on: [columnName], naming: { $0 }) { (slice: DiscontiguousColumnSlice<N>) in
            slice.max()
        }
    }

    public func minimums<N>(_ columnID: ColumnID<N>, order: Order? = nil) -> DataFrame
    where N: Comparable {
        minimums(columnID.name, N.self, order: order)
    }

    public func minimums<N>(_ columnName: String, _ type: N.Type, order: Order? = nil) -> DataFrame
    where N: Comparable {
        aggregated(on: [columnName], naming: { $0 }) { (slice: DiscontiguousColumnSlice<N>) in
            slice.min()
        }
    }

    public func quantiles<N>(_ columnID: ColumnID<N>, quantile: N, order: Order? = nil) -> DataFrame
    where N: BinaryFloatingPoint {
        quantiles(columnID.name, N.self, quantile: quantile, order: order)
    }

    public func quantiles<N>(
        _ columnName: String, _ type: N.Type, quantile: N, order: Order? = nil
    ) -> DataFrame where N: BinaryFloatingPoint {
        aggregated(on: [columnName], naming: { $0 }) { (slice: DiscontiguousColumnSlice<N>) in
            let present = slice.values.compactMap { $0 }.sorted()
            return tabularQuantile(present, Double(quantile))
        }
    }

    public func summary() -> any GroupSummaries {
        summary(of: frames.first?.columns.map(\.name) ?? [])
    }

    public func summary(of columnNames: String...) -> any GroupSummaries {
        summary(of: columnNames)
    }

    public func summary(of columnNames: [String]) -> any GroupSummaries {
        TabularGroupSummaries(grouping: self, columnNames: columnNames)
    }

    public subscript(keys: Any?...) -> DataFrame.Slice? {
        let wanted = keys.map { $0.map { String(describing: $0) } ?? "<nil>" }.joined(separator: "\u{1f}")
        for (index, key) in self.keys.enumerated() {
            let rendered = key.map { String(describing: $0) } ?? "<nil>"
            if rendered == wanted || (keys.count == 1 && rendered == wanted) {
                return frames[index][0..<frames[index].rowCount]
            }
        }
        return nil
    }
}

struct TabularGroupSummaries: GroupSummaries {
    var frames: [(key: String, summary: DataFrame)]

    init<K>(grouping: RowGrouping<K>, columnNames: [String]) {
        self.frames = zip(grouping.keys, grouping.frames).map { key, frame in
            (
                key.map { String(describing: $0) } ?? "<nil>",
                frame.summary(of: columnNames.isEmpty ? frame.columns.map(\.name) : columnNames)
            )
        }
    }

    var description: String { description(options: FormattingOptions()) }

    func description(options: FormattingOptions) -> String {
        frames.map { "\($0.key)\n\($0.summary.description(options: options))" }.joined(separator: "\n")
    }

    subscript(keys: Any?...) -> DataFrame? {
        let wanted = keys.map { $0.map { String(describing: $0) } ?? "<nil>" }.joined()
        return frames.first { $0.key == wanted }?.summary
    }
}
