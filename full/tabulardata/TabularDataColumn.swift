/// A typed column of optional cells.
public struct Column<WrappedElement>: OptionalColumnProtocol, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public typealias SubSequence = ColumnSlice<WrappedElement>
    public typealias Index = Int
    public typealias Element = WrappedElement?
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<Column<WrappedElement>>
    public var indices: Range<Int> { startIndex..<endIndex }

    public var name: String
    var values: [WrappedElement?]

    public init(name: String, capacity: Int) {
        self.name = name
        self.values = Array(repeating: nil, count: Swift.max(capacity, 0))
    }

    public init<S>(name: String, contents: S) where WrappedElement == S.Element, S: Sequence {
        self.name = name
        self.values = contents.map { Optional($0) }
    }

    public init<S>(name: String, contents: S) where S: Sequence, S.Element == WrappedElement? {
        self.name = name
        self.values = Array(contents)
    }

    public init(_ id: ColumnID<WrappedElement>, capacity: Int) {
        self.init(name: id.name, capacity: capacity)
    }

    public init<S>(_ id: ColumnID<S.Element>, contents: S)
    where WrappedElement == S.Element, S: Sequence {
        self.init(name: id.name, contents: contents)
    }

    public init<S>(_ id: ColumnID<S.Element>, contents: S)
    where S: Sequence, S.Element == WrappedElement? {
        self.init(name: id.name, contents: contents)
    }

    public init(_ slice: ColumnSlice<WrappedElement>) {
        self.name = slice.name
        self.values = slice.values
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

    public subscript(bounds: Range<Int>) -> ColumnSlice<WrappedElement> {
        get {
            ColumnSlice(
                name: name,
                values: Array(values[bounds])
            )
        }
        set {
            precondition(newValue.count == bounds.count)
            values.replaceSubrange(bounds, with: newValue.values)
        }
    }

    public subscript<R>(range: R) -> ColumnSlice<WrappedElement>
    where R: RangeExpression, R.Bound == Int {
        get { self[range.relative(to: values.indices)] }
        set { self[range.relative(to: values.indices)] = newValue }
    }

    public subscript<C>(mask: C) -> DiscontiguousColumnSlice<WrappedElement>
    where C: Collection, C.Element == Bool {
        var indices: [Int] = []
        for (index, flag) in zip(self.indices, mask) where flag {
            indices.append(index)
        }
        return DiscontiguousColumnSlice(column: self, indices: indices)
    }

    public var description: String { description(options: FormattingOptions()) }
    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["name": name, "count": count, "missing": missingCount])
    }

    public func eraseToAnyColumn() -> AnyColumn { AnyColumn(self) }

    public func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<WrappedElement>) throws -> R
    ) rethrows -> R? {
        _ = body
        return nil
    }

    public func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<WrappedElement?>) throws -> R
    ) rethrows -> R? {
        try values.withUnsafeBufferPointer(body)
    }

    public mutating func withContiguousMutableStorageIfAvailable<R>(
        _ body: (inout UnsafeMutableBufferPointer<WrappedElement>) throws -> R
    ) rethrows -> R? {
        _ = body
        return nil
    }

    public mutating func withContiguousMutableStorageIfAvailable<R>(
        _ body: (inout UnsafeMutableBufferPointer<WrappedElement?>) throws -> R
    ) rethrows -> R? {
        try values.withUnsafeMutableBufferPointer(body)
    }

    public func map<T>(_ transform: (Column<WrappedElement>.Element) throws -> T?) rethrows -> Column<T> {
        Column<T>(name: name, contents: try values.map(transform))
    }

    public func mapNonNil<T>(_ transform: (WrappedElement) throws -> T?) rethrows -> Column<T> {
        Column<T>(
            name: name,
            contents: try values.map { value in
                guard let value else { return nil }
                return try transform(value)
            }
        )
    }

    public mutating func append<S>(contentsOf sequence: S)
    where WrappedElement == S.Element, S: Sequence {
        values.append(contentsOf: sequence.map { Optional($0) })
    }

    public mutating func append<S>(contentsOf sequence: S)
    where S: Sequence, S.Element == WrappedElement? {
        values.append(contentsOf: sequence)
    }

    public mutating func append(_ element: WrappedElement) {
        values.append(element)
    }

    public mutating func append(_ element: Column<WrappedElement>.Element) {
        values.append(element)
    }

    public func filter(
        _ isIncluded: (Column<WrappedElement>.Element) throws -> Bool
    ) rethrows -> DiscontiguousColumnSlice<WrappedElement> {
        var indices: [Int] = []
        for index in self.indices where try isIncluded(values[index]) {
            indices.append(index)
        }
        return DiscontiguousColumnSlice(column: self, indices: indices)
    }

    public mutating func remove(at index: Int) {
        values.remove(at: index)
    }

    public mutating func transform(
        _ transform: (Column<WrappedElement>.Element) throws -> Column<WrappedElement>.Element
    ) rethrows {
        for index in values.indices {
            values[index] = try transform(values[index])
        }
    }

    public mutating func transform(
        _ transform: (WrappedElement) throws -> WrappedElement
    ) rethrows {
        for index in values.indices {
            if let value = values[index] {
                values[index] = try transform(value)
            }
        }
    }
}

extension Column {
    public func distinct() -> DiscontiguousColumnSlice<WrappedElement> where WrappedElement: Hashable {
        var seen = Set<WrappedElement>()
        var nilIncluded = false
        var indices: [Int] = []
        for index in self.indices {
            if let value = values[index] {
                if seen.insert(value).inserted {
                    indices.append(index)
                }
            } else if !nilIncluded {
                nilIncluded = true
                indices.append(index)
            }
        }
        return DiscontiguousColumnSlice(column: self, indices: indices)
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

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> Column<WrappedElement>.Element
    where WrappedElement: BinaryFloatingPoint {
        let present = values.compactMap { $0 }
        guard present.count > deltaDegreesOfFreedom else { return nil }
        let mean = present.reduce(WrappedElement.zero, +) / WrappedElement(present.count)
        var variance = WrappedElement.zero
        for value in present {
            let delta = value - mean
            variance += delta * delta
        }
        variance /= WrappedElement(present.count - deltaDegreesOfFreedom)
        return variance.squareRoot()
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> Double?
    where WrappedElement: BinaryInteger {
        let present = values.compactMap { $0 }.map { Double($0) }
        guard present.count > deltaDegreesOfFreedom else { return nil }
        let mean = present.reduce(0, +) / Double(present.count)
        var variance = 0.0
        for value in present {
            let delta = value - mean
            variance += delta * delta
        }
        variance /= Double(present.count - deltaDegreesOfFreedom)
        return variance.squareRoot()
    }

    public func mean() -> Column<WrappedElement>.Element where WrappedElement: BinaryFloatingPoint {
        let present = values.compactMap { $0 }
        guard !present.isEmpty else { return nil }
        return present.reduce(WrappedElement.zero, +) / WrappedElement(present.count)
    }

    public func mean() -> Double? where WrappedElement: BinaryInteger {
        let present = values.compactMap { $0 }
        guard !present.isEmpty else { return nil }
        return present.reduce(0.0) { $0 + Double($1) } / Double(present.count)
    }

    public func sum() -> WrappedElement where WrappedElement: AdditiveArithmetic {
        values.compactMap { $0 }.reduce(WrappedElement.zero, +)
    }

    public func max() -> Column<WrappedElement>.Element where WrappedElement: Comparable {
        values.compactMap { $0 }.max()
    }

    public func min() -> Column<WrappedElement>.Element where WrappedElement: Comparable {
        values.compactMap { $0 }.min()
    }

    public func argmax() -> Int? where WrappedElement: Comparable {
        var bestIndex: Int?
        var best: WrappedElement?
        for (index, value) in values.enumerated() {
            guard let value else { continue }
            if let current = best {
                if value > current {
                    best = value
                    bestIndex = index
                }
            } else {
                best = value
                bestIndex = index
            }
        }
        return bestIndex
    }

    public func argmin() -> Int? where WrappedElement: Comparable {
        var bestIndex: Int?
        var best: WrappedElement?
        for (index, value) in values.enumerated() {
            guard let value else { continue }
            if let current = best {
                if value < current {
                    best = value
                    bestIndex = index
                }
            } else {
                best = value
                bestIndex = index
            }
        }
        return bestIndex
    }
}

extension Column: Equatable where WrappedElement: Equatable {
    public static func == (a: Column<WrappedElement>, b: Column<WrappedElement>) -> Bool {
        a.name == b.name && a.values == b.values
    }
}

extension Column: Hashable where WrappedElement: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(values)
    }
}

extension Column: Codable where WrappedElement: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case values
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        values = try container.decode([WrappedElement?].self, forKey: .values)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(values, forKey: .values)
    }
}
