/// A contiguous slice of a typed column.
public struct ColumnSlice<WrappedElement>: OptionalColumnProtocol, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public typealias SubSequence = ColumnSlice<WrappedElement>
    public typealias Index = Int
    public typealias Element = WrappedElement?
    public typealias Indices = Range<ColumnSlice<WrappedElement>.Index>
    public typealias Iterator = IndexingIterator<ColumnSlice<WrappedElement>>
    public var indices: Range<Int> { startIndex..<endIndex }

    public var name: String
    var values: [WrappedElement?]

    public init(_ column: Column<WrappedElement>) {
        self.name = column.name
        self.values = column.values
    }

    init(name: String, values: [WrappedElement?]) {
        self.name = name
        self.values = values
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { values.count }
    public var count: Int { values.count }
    public var missingCount: Int { values.reduce(0) { $0 + ($1 == nil ? 1 : 0) } }
    public var wrappedElementType: any Any.Type { WrappedElement.self }
    public var prototype: any AnyColumnPrototype { TypedColumnPrototype<WrappedElement>(name: name) }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public func isNil(at index: Int) -> Bool { values[index] == nil }

    public subscript(position: Int) -> WrappedElement? {
        get { values[position] }
        set { values[position] = newValue }
    }

    public subscript(range: Range<Int>) -> ColumnSlice<WrappedElement> {
        get { ColumnSlice(name: name, values: Array(values[range])) }
        set {
            precondition(newValue.count == range.count)
            values.replaceSubrange(range, with: newValue.values)
        }
    }

    public subscript<R>(range: R) -> ColumnSlice<WrappedElement>
    where R: RangeExpression, R.Bound == Int {
        get { self[range.relative(to: values.indices)] }
        set { self[range.relative(to: values.indices)] = newValue }
    }

    public subscript(range: (UnboundedRange_) -> Void) -> ColumnSlice<WrappedElement> {
        get { self }
        set { values = newValue.values }
    }

    public var description: String { description(options: FormattingOptions()) }
    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["name": name, "count": count])
    }

    public func eraseToAnyColumn() -> AnyColumnSlice { AnyColumnSlice(self) }

    public func map<T>(
        _ transform: (ColumnSlice<WrappedElement>.Element) throws -> T?
    ) rethrows -> Column<T> {
        Column<T>(name: name, contents: try values.map(transform))
    }

    public func filter(
        _ isIncluded: (ColumnSlice<WrappedElement>.Element) throws -> Bool
    ) rethrows -> DiscontiguousColumnSlice<WrappedElement> {
        DiscontiguousColumnSlice(column: Column(self), indices: try indices.filter { try isIncluded(values[$0]) })
    }
}

extension ColumnSlice {
    public func distinct() -> ColumnSlice<WrappedElement> where WrappedElement: Hashable {
        var seen = Set<WrappedElement>()
        var nilIncluded = false
        var next: [WrappedElement?] = []
        for value in values {
            if let value {
                if seen.insert(value).inserted { next.append(value) }
            } else if !nilIncluded {
                nilIncluded = true
                next.append(nil)
            }
        }
        return ColumnSlice(name: name, values: next)
    }

    public func summary() -> CategoricalSummary<WrappedElement> where WrappedElement: Hashable {
        tabularCategoricalSummary(values)
    }

    public func numericSummary() -> NumericSummary<WrappedElement> where WrappedElement: BinaryFloatingPoint {
        tabularNumericSummary(values)
    }

    public func numericSummary() -> NumericSummary<Double> where WrappedElement: BinaryInteger {
        tabularNumericSummary(values.map { $0.map { Double($0) } })
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> ColumnSlice<WrappedElement>.Element
    where WrappedElement: BinaryFloatingPoint {
        Column(self).standardDeviation(deltaDegreesOfFreedom: deltaDegreesOfFreedom)
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> Double?
    where WrappedElement: BinaryInteger {
        Column(self).standardDeviation(deltaDegreesOfFreedom: deltaDegreesOfFreedom)
    }

    public func mean() -> ColumnSlice<WrappedElement>.Element where WrappedElement: BinaryFloatingPoint {
        Column(self).mean()
    }

    public func mean() -> Double? where WrappedElement: BinaryInteger {
        Column(self).mean()
    }

    public func sum() -> WrappedElement where WrappedElement: AdditiveArithmetic {
        Column(self).sum()
    }

    public func max() -> ColumnSlice<WrappedElement>.Element where WrappedElement: Comparable {
        values.compactMap { $0 }.max()
    }

    public func min() -> ColumnSlice<WrappedElement>.Element where WrappedElement: Comparable {
        values.compactMap { $0 }.min()
    }

    public func argmax() -> Int? where WrappedElement: Comparable {
        Column(self).argmax()
    }

    public func argmin() -> Int? where WrappedElement: Comparable {
        Column(self).argmin()
    }
}

extension ColumnSlice: Equatable where WrappedElement: Equatable {
    public static func == (a: ColumnSlice<WrappedElement>, b: ColumnSlice<WrappedElement>) -> Bool {
        a.name == b.name && a.values == b.values
    }
}

extension ColumnSlice: Hashable where WrappedElement: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(values)
    }
}

/// A possibly non-contiguous slice of a typed column.
public struct DiscontiguousColumnSlice<WrappedElement>: OptionalColumnProtocol, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public typealias SubSequence = DiscontiguousColumnSlice<WrappedElement>
    public typealias Index = Int
    public typealias Element = WrappedElement?
    public typealias Indices = DefaultIndices<DiscontiguousColumnSlice<WrappedElement>>
    public typealias Iterator = IndexingIterator<DiscontiguousColumnSlice<WrappedElement>>

    public var name: String
    var values: [WrappedElement?]

    public init(column: Column<WrappedElement>, ranges: [Range<Int>]) {
        self.name = column.name
        var next: [WrappedElement?] = []
        for range in ranges {
            next.append(contentsOf: column.values[range])
        }
        self.values = next
    }

    public init(_ column: Column<WrappedElement>) {
        self.name = column.name
        self.values = column.values
    }

    init(column: Column<WrappedElement>, indices: [Int]) {
        self.name = column.name
        self.values = indices.map { column.values[$0] }
    }

    init(name: String, values: [WrappedElement?]) {
        self.name = name
        self.values = values
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { values.count }
    public var count: Int { values.count }
    public var missingCount: Int { values.reduce(0) { $0 + ($1 == nil ? 1 : 0) } }
    public var wrappedElementType: any Any.Type { WrappedElement.self }
    public var prototype: any AnyColumnPrototype { TypedColumnPrototype<WrappedElement>(name: name) }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public func isNil(at index: Int) -> Bool { values[index] == nil }

    public subscript(position: Int) -> WrappedElement? {
        get { values[position] }
        set { values[position] = newValue }
    }

    public subscript(range: Range<Int>) -> DiscontiguousColumnSlice<WrappedElement> {
        get { DiscontiguousColumnSlice(name: name, values: Array(values[range])) }
        set {
            precondition(newValue.count == range.count)
            values.replaceSubrange(range, with: newValue.values)
        }
    }

    public subscript<R>(range: R) -> DiscontiguousColumnSlice<WrappedElement>
    where R: RangeExpression, R.Bound == Int {
        get { self[range.relative(to: values.indices)] }
        set { self[range.relative(to: values.indices)] = newValue }
    }

    public subscript(range: (UnboundedRange_) -> Void) -> DiscontiguousColumnSlice<WrappedElement> {
        get { self }
        set { values = newValue.values }
    }

    public var description: String { description(options: FormattingOptions()) }
    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["name": name, "count": count])
    }

    public func eraseToAnyColumn() -> AnyColumnSlice { AnyColumnSlice(self) }

    public func map<T>(
        _ transform: (DiscontiguousColumnSlice<WrappedElement>.Element) throws -> T?
    ) rethrows -> Column<T> {
        Column<T>(name: name, contents: try values.map(transform))
    }

    public func filter(
        _ isIncluded: (DiscontiguousColumnSlice<WrappedElement>.Element) throws -> Bool
    ) rethrows -> DiscontiguousColumnSlice<WrappedElement> {
        DiscontiguousColumnSlice(name: name, values: try values.filter(isIncluded))
    }
}

extension DiscontiguousColumnSlice {
    public func distinct() -> DiscontiguousColumnSlice<WrappedElement> where WrappedElement: Hashable {
        DiscontiguousColumnSlice(name: name, values: Column(name: name, contents: values).distinct().values)
    }

    public func summary() -> CategoricalSummary<WrappedElement> where WrappedElement: Hashable {
        tabularCategoricalSummary(values)
    }

    public func numericSummary() -> NumericSummary<WrappedElement> where WrappedElement: BinaryFloatingPoint {
        tabularNumericSummary(values)
    }

    public func numericSummary() -> NumericSummary<Double> where WrappedElement: BinaryInteger {
        tabularNumericSummary(values.map { $0.map { Double($0) } })
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> DiscontiguousColumnSlice<WrappedElement>.Element
    where WrappedElement: BinaryFloatingPoint {
        Column(name: name, contents: values).standardDeviation(deltaDegreesOfFreedom: deltaDegreesOfFreedom)
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> Double?
    where WrappedElement: BinaryInteger {
        Column(name: name, contents: values).standardDeviation(deltaDegreesOfFreedom: deltaDegreesOfFreedom)
    }

    public func mean() -> DiscontiguousColumnSlice<WrappedElement>.Element
    where WrappedElement: BinaryFloatingPoint {
        Column(name: name, contents: values).mean()
    }

    public func mean() -> Double? where WrappedElement: BinaryInteger {
        Column(name: name, contents: values).mean()
    }

    public func sum() -> WrappedElement where WrappedElement: AdditiveArithmetic {
        Column(name: name, contents: values).sum()
    }

    public func max() -> DiscontiguousColumnSlice<WrappedElement>.Element where WrappedElement: Comparable {
        values.compactMap { $0 }.max()
    }

    public func min() -> DiscontiguousColumnSlice<WrappedElement>.Element where WrappedElement: Comparable {
        values.compactMap { $0 }.min()
    }

    public func argmax() -> Int? where WrappedElement: Comparable {
        Column(name: name, contents: values).argmax()
    }

    public func argmin() -> Int? where WrappedElement: Comparable {
        Column(name: name, contents: values).argmin()
    }
}

extension DiscontiguousColumnSlice: Equatable where WrappedElement: Equatable {
    public static func == (
        a: DiscontiguousColumnSlice<WrappedElement>,
        b: DiscontiguousColumnSlice<WrappedElement>
    ) -> Bool {
        a.name == b.name && a.values == b.values
    }
}

extension DiscontiguousColumnSlice: Hashable where WrappedElement: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(values)
    }
}
