/// A bidirectional collection of column cells.
public protocol ColumnProtocol<Element>: BidirectionalCollection {
    var name: String { get set }
}

/// Type-erased column surface shared by `AnyColumn` and `AnyColumnSlice`.
public protocol AnyColumnProtocol {
    var wrappedElementType: any Any.Type { get }
    var name: String { get set }
    var count: Int { get }
    subscript(range: Range<Int>) -> AnyColumnSlice { get }
    subscript(position: Int) -> Any? { get }
}

/// Factory used to allocate a column of the same wrapped type.
public protocol AnyColumnPrototype {
    var name: String { get set }
    func makeColumn(capacity: Int) -> AnyColumn
}

/// A column whose collection elements are optional wrapped values.
public protocol OptionalColumnProtocol<WrappedElement>: ColumnProtocol
where Element == WrappedElement? {
    associatedtype WrappedElement
}

extension OptionalColumnProtocol {
    public func filled(with value: Self.WrappedElement) -> FilledColumn<Self> {
        FilledColumn(base: self, fill: value)
    }

    public func description(options: FormattingOptions) -> String {
        var cells: [String] = []
        for value in self {
            let text: String
            if let value {
                text = tabularDisplay(value, options: options)
            } else {
                text = "<nil>"
            }
            cells.append(String(text.prefix(options.maximumCellWidth)))
        }
        return "\(name): [" + cells.joined(separator: ", ") + "]"
    }
}

/// A `DataFrame` or `DataFrame.Slice`.
public protocol DataFrameProtocol {
    associatedtype ColumnType: AnyColumnProtocol
    var base: DataFrame { get }
    var rows: DataFrame.Rows { get set }
    var shape: (rows: Int, columns: Int) { get }
    var columns: [ColumnType] { get }
}

/// Grouped slices of a data frame.
public protocol RowGroupingProtocol: CustomStringConvertible {
    var count: Int { get }
    func aggregated<Element, Result>(
        on columnNames: [String],
        naming: (String) -> String,
        transform: (DiscontiguousColumnSlice<Element>) throws -> Result?
    ) rethrows -> DataFrame
    func randomSplit(by proportion: Double, seed: Int?) -> (Self, Self)
    func counts(order: Order?) -> DataFrame
    func filter(_ isIncluded: (DataFrame.Slice) throws -> Bool) rethrows -> Self
    func summary(of columnNames: [String]) -> any GroupSummaries
    func summary() -> any GroupSummaries
    func mapGroups(_ transform: (DataFrame.Slice) throws -> DataFrame) rethrows -> Self
    func ungrouped() -> DataFrame
    func aggregated<Element, Result>(
        on columnID: ColumnID<Element>,
        into aggregatedColumnName: String?,
        transform: (DiscontiguousColumnSlice<Element>) throws -> Result?
    ) rethrows -> DataFrame
    func aggregated<Element, Result>(
        on columnNames: String...,
        naming: (String) -> String,
        transform: (DiscontiguousColumnSlice<Element>) throws -> Result?
    ) rethrows -> DataFrame
    func randomSplit(by proportion: Double) -> (Self, Self)
    func sums<N>(_ columnID: ColumnID<N>, order: Order?) -> DataFrame
    where N: AdditiveArithmetic, N: Comparable
    func sums<N>(_ columnName: String, _ type: N.Type, order: Order?) -> DataFrame
    where N: AdditiveArithmetic, N: Comparable
    func means<N>(_ columnID: ColumnID<N>, order: Order?) -> DataFrame where N: FloatingPoint
    func means<N>(_ columnName: String, _ type: N.Type, order: Order?) -> DataFrame
    where N: FloatingPoint
    func counts() -> DataFrame
    func summary(of columnNames: String...) -> any GroupSummaries
    func maximums<N>(_ columnID: ColumnID<N>, order: Order?) -> DataFrame where N: Comparable
    func maximums<N>(_ columnName: String, _ type: N.Type, order: Order?) -> DataFrame
    where N: Comparable
    func minimums<N>(_ columnID: ColumnID<N>, order: Order?) -> DataFrame where N: Comparable
    func minimums<N>(_ columnName: String, _ type: N.Type, order: Order?) -> DataFrame
    where N: Comparable
    func quantiles<N>(_ columnID: ColumnID<N>, quantile: N, order: Order?) -> DataFrame
    where N: BinaryFloatingPoint
    func quantiles<N>(
        _ columnName: String, _ type: N.Type, quantile: N, order: Order?
    ) -> DataFrame where N: BinaryFloatingPoint
    subscript(keys: Any?...) -> DataFrame.Slice? { get }
}

/// Summaries computed per group.
public protocol GroupSummaries: CustomStringConvertible {
    func description(options: FormattingOptions) -> String
    var description: String { get }
    subscript(keys: Any?...) -> DataFrame? { get }
}

struct TypedColumnPrototype<T>: AnyColumnPrototype {
    public var name: String

    func makeColumn(capacity: Int) -> AnyColumn {
        AnyColumn(Column<T>(name: name, capacity: capacity))
    }
}

/// A column view with missing values replaced by a fill value.
public struct FilledColumn<Base>: ColumnProtocol where Base: OptionalColumnProtocol {
    public typealias Element = Base.WrappedElement
    public typealias Index = Base.Index
    public typealias SubSequence = Swift.Slice<FilledColumn<Base>>
    public typealias WrappedElement = Base.WrappedElement
    public typealias Indices = DefaultIndices<FilledColumn<Base>>
    public typealias Iterator = IndexingIterator<FilledColumn<Base>>

    var base: Base
    var fill: Base.WrappedElement

    public var startIndex: Base.Index { base.startIndex }
    public var endIndex: Base.Index { base.endIndex }
    public var name: String {
        get { base.name }
        set { base.name = newValue }
    }

    public func index(after i: Base.Index) -> Base.Index { base.index(after: i) }
    public func index(before i: Base.Index) -> Base.Index { base.index(before: i) }

    public subscript(position: Base.Index) -> Base.WrappedElement {
        base[position] ?? fill
    }

    public func description(options: FormattingOptions) -> String {
        var cells: [String] = []
        for value in self {
            cells.append(String(tabularDisplay(value, options: options).prefix(options.maximumCellWidth)))
        }
        return "\(name): [" + cells.joined(separator: ", ") + "]"
    }

    public var description: String { description(options: FormattingOptions()) }
    public var debugDescription: String { description }

    public func numericSummary() -> NumericSummary<Base.WrappedElement>
    where Base.WrappedElement: BinaryFloatingPoint {
        tabularNumericSummary(Array(self).map { Optional($0) })
    }

    public func numericSummary() -> NumericSummary<Double>
    where Base.WrappedElement: BinaryInteger {
        let doubles: [Double?] = map { Double($0) }
        return tabularNumericSummary(doubles)
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> FilledColumn<Base>.Element?
    where Base.WrappedElement: BinaryFloatingPoint {
        let summary: NumericSummary<Base.WrappedElement> = numericSummary()
        _ = deltaDegreesOfFreedom
        return summary.someCount == 0 ? nil : summary.standardDeviation
    }

    public func standardDeviation(deltaDegreesOfFreedom: Int = 1) -> Double?
    where Base.WrappedElement: BinaryInteger {
        let summary: NumericSummary<Double> = numericSummary()
        _ = deltaDegreesOfFreedom
        return summary.someCount == 0 ? nil : summary.standardDeviation
    }

    public func sum() -> FilledColumn<Base>.Element where Base.WrappedElement: AdditiveArithmetic {
        reduce(Base.WrappedElement.zero, +)
    }

    public func mean() -> FilledColumn<Base>.Element? where Base.WrappedElement: FloatingPoint {
        let values = Array(self)
        guard !values.isEmpty else { return nil }
        let total = values.reduce(Base.WrappedElement.zero, +)
        return total / Base.WrappedElement(values.count)
    }

    public func mean() -> Double? where Base.WrappedElement: BinaryInteger {
        let values = Array(self)
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0.0) { $0 + Double($1) }
        return total / Double(values.count)
    }

    public func summary() -> CategoricalSummary<FilledColumn<Base>.WrappedElement>
    where Base.WrappedElement: Hashable {
        tabularCategoricalSummary(Array(self).map { Optional($0) })
    }

    public func max() -> FilledColumn<Base>.Element? where Base.WrappedElement: Comparable {
        var best: Base.WrappedElement? = nil
        for value in self {
            if let current = best {
                if value > current { best = value }
            } else {
                best = value
            }
        }
        return best
    }

    public func min() -> FilledColumn<Base>.Element? where Base.WrappedElement: Comparable {
        var best: Base.WrappedElement? = nil
        for value in self {
            if let current = best {
                if value < current { best = value }
            } else {
                best = value
            }
        }
        return best
    }

    public func argmax() -> FilledColumn<Base>.Index? where Base.WrappedElement: Comparable {
        indices.max { self[$0] < self[$1] }
    }

    public func argmin() -> Base.Index? where Base.WrappedElement: Comparable {
        indices.min { self[$0] < self[$1] }
    }
}

extension FilledColumn: CustomStringConvertible, CustomDebugStringConvertible {}
