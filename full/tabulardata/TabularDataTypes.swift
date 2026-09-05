/// Identifies a typed column in a `DataFrame`.
public struct ColumnID<T>: CustomStringConvertible {
    public var name: String
    public var type: any Any.Type { T.self }

    public init(_ name: String, _ type: T.Type) {
        self.name = name
    }

    public var description: String { name }
}

/// CSV cell type requested or inferred while reading.
public enum CSVType: Hashable, Sendable {
    case data
    case date
    case float
    case double
    case string
    case boolean
    case integer
}

/// JSON value type requested while reading.
public enum JSONType: Hashable, Sendable {
    case date
    case array
    case double
    case object
    case string
    case boolean
    case integer
}

/// Sort direction used by `DataFrame` sorting APIs.
public enum Order: Hashable, Sendable {
    case descending
    case ascending

    public func areOrdered<T>(_ lhs: T, _ rhs: T) -> Bool where T: Comparable {
        switch self {
        case .ascending: return lhs < rhs
        case .descending: return lhs > rhs
        }
    }
}

/// Relational join kind.
public enum JoinKind: Hashable, Sendable {
    case full
    case left
    case inner
    case right
}

/// Column identifiers used by `summary()` result frames.
public enum SummaryColumnIDs {
    public static let columnName = ColumnID<String>("columnName", String.self)
    public static let uniqueCount = ColumnID<Int>("uniqueCount", Int.self)
    public static let firstQuartile = ColumnID<Double>("firstQuartile", Double.self)
    public static let thirdQuartile = ColumnID<Double>("thirdQuartile", Double.self)
    public static let standardDeviation = ColumnID<Double>("standardDeviation", Double.self)
    public static let mean = ColumnID<Double>("mean", Double.self)
    public static let mode = ColumnID<[Any]>("mode", [Any].self)
    public static let median = ColumnID<Double>("median", Double.self)
    public static let maximum = ColumnID<Double>("maximum", Double.self)
    public static let minimum = ColumnID<Double>("minimum", Double.self)
    public static let noneCount = ColumnID<Int>("noneCount", Int.self)
    public static let someCount = ColumnID<Int>("someCount", Int.self)
}

/// A dense multidimensional array with explicit shape and strides.
public struct ShapedData<Element> {
    public let shape: [Int]
    public let strides: [Int]
    public let contents: [Element]

    public init(shape: [Int], strides: [Int], contents: [Element]) {
        self.shape = shape
        self.strides = strides
        self.contents = contents
    }

    public subscript(indices: Int...) -> Element {
        var offset = 0
        for (index, stride) in zip(indices, strides) {
            offset += index * stride
        }
        return contents[offset]
    }
}

extension ShapedData: Equatable where Element: Equatable {
    public static func == (a: ShapedData<Element>, b: ShapedData<Element>) -> Bool {
        a.shape == b.shape && a.strides == b.strides && a.contents == b.contents
    }
}

extension ShapedData: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(shape)
        hasher.combine(strides)
        hasher.combine(contents)
    }
}
