/// A type-erased column.
public struct AnyColumn: AnyColumnProtocol, BidirectionalCollection, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable {
    public typealias SubSequence = AnyColumnSlice
    public typealias Index = Int
    public typealias Element = Any?
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<AnyColumn>
    public var indices: Range<Int> { startIndex..<endIndex }

    public var name: String
    public var wrappedElementType: any Any.Type
    var values: [Any?]
    var prototypeStorage: any AnyColumnPrototype

    public var prototype: any AnyColumnPrototype {
        var proto = prototypeStorage
        proto.name = name
        return proto
    }

    public init<T>(_ column: Column<T>) {
        self.name = column.name
        self.wrappedElementType = T.self
        self.values = column.values.map { $0 }
        self.prototypeStorage = TypedColumnPrototype<T>(name: column.name)
    }

    init(name: String, wrappedElementType: any Any.Type, values: [Any?], prototype: any AnyColumnPrototype) {
        self.name = name
        self.wrappedElementType = wrappedElementType
        self.values = values
        self.prototypeStorage = prototype
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { values.count }
    public var count: Int { values.count }
    public var missingCount: Int { values.reduce(0) { $0 + ($1 == nil ? 1 : 0) } }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public func isNil(at index: Int) -> Bool { values[index] == nil }

    public subscript(position: Int) -> Any? {
        get { values[position] }
        set { values[position] = newValue }
    }

    public subscript(range: Range<Int>) -> AnyColumnSlice {
        get { AnyColumnSlice(name: name, wrappedElementType: wrappedElementType, values: Array(values[range]), prototype: prototypeStorage) }
        set {
            precondition(newValue.count == range.count)
            values.replaceSubrange(range, with: newValue.values)
        }
    }

    public subscript<C>(mask: C) -> AnyColumnSlice where C: Collection, C.Element == Bool {
        var next: [Any?] = []
        for (value, flag) in zip(values, mask) where flag {
            next.append(value)
        }
        return AnyColumnSlice(name: name, wrappedElementType: wrappedElementType, values: next, prototype: prototypeStorage)
    }

    public var description: String {
        Column<String>(
            name: name,
            contents: values.map { $0.map { String(describing: $0) } ?? nil }
        ).description
    }

    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["name": name, "count": count, "type": String(describing: wrappedElementType)])
    }

    public func assumingType<T>(_ type: T.Type) -> Column<T> {
        Column<T>(name: name, contents: values.map { $0 as? T })
    }

    public mutating func append(contentsOf other: AnyColumnSlice) {
        values.append(contentsOf: other.values)
    }

    public mutating func append(contentsOf other: AnyColumn) {
        values.append(contentsOf: other.values)
    }

    public mutating func append(_ element: Any?) {
        values.append(element)
    }

    public mutating func remove(at index: Int) {
        values.remove(at: index)
    }

    public func distinct() -> AnyColumnSlice {
        var seen = Set<String>()
        var next: [Any?] = []
        for value in values {
            let key = value.map { String(describing: $0) } ?? "<nil>"
            if seen.insert(key).inserted {
                next.append(value)
            }
        }
        return AnyColumnSlice(name: name, wrappedElementType: wrappedElementType, values: next, prototype: prototypeStorage)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(String(describing: wrappedElementType))
        hasher.combine(values.count)
        for value in values {
            tabularHash(value, into: &hasher)
        }
    }

    public static func == (lhs: AnyColumn, rhs: AnyColumn) -> Bool {
        guard lhs.name == rhs.name, lhs.count == rhs.count else { return false }
        return zip(lhs.values, rhs.values).allSatisfy { tabularValuesEqual($0, $1) }
    }
}

/// A type-erased column slice.
public struct AnyColumnSlice: AnyColumnProtocol, BidirectionalCollection, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable, Hashable {
    public typealias SubSequence = AnyColumnSlice
    public typealias Index = Int
    public typealias Element = Any?
    public typealias Indices = Range<Int>
    public typealias Iterator = IndexingIterator<AnyColumnSlice>
    public var indices: Range<Int> { startIndex..<endIndex }

    public var name: String
    public var wrappedElementType: any Any.Type
    var values: [Any?]
    var prototypeStorage: any AnyColumnPrototype

    public var prototype: any AnyColumnPrototype {
        var proto = prototypeStorage
        proto.name = name
        return proto
    }

    public init(_ column: AnyColumn) {
        self.name = column.name
        self.wrappedElementType = column.wrappedElementType
        self.values = column.values
        self.prototypeStorage = column.prototypeStorage
    }

    public init<T>(_ slice: ColumnSlice<T>) {
        self.name = slice.name
        self.wrappedElementType = T.self
        self.values = slice.values.map { $0 }
        self.prototypeStorage = TypedColumnPrototype<T>(name: slice.name)
    }

    public init<T>(_ slice: DiscontiguousColumnSlice<T>) {
        self.name = slice.name
        self.wrappedElementType = T.self
        self.values = slice.values.map { $0 }
        self.prototypeStorage = TypedColumnPrototype<T>(name: slice.name)
    }

    init(name: String, wrappedElementType: any Any.Type, values: [Any?], prototype: any AnyColumnPrototype) {
        self.name = name
        self.wrappedElementType = wrappedElementType
        self.values = values
        self.prototypeStorage = prototype
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { values.count }
    public var count: Int { values.count }
    public var missingCount: Int { values.reduce(0) { $0 + ($1 == nil ? 1 : 0) } }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
    public func isNil(at index: Int) -> Bool { values[index] == nil }

    public subscript(position: Int) -> Any? {
        get { values[position] }
        set { values[position] = newValue }
    }

    public subscript(range: Range<Int>) -> AnyColumnSlice {
        get {
            AnyColumnSlice(
                name: name,
                wrappedElementType: wrappedElementType,
                values: Array(values[range]),
                prototype: prototypeStorage
            )
        }
        set {
            precondition(newValue.count == range.count)
            values.replaceSubrange(range, with: newValue.values)
        }
    }

    public var description: String { AnyColumn(name: name, wrappedElementType: wrappedElementType, values: values, prototype: prototypeStorage).description }
    public var debugDescription: String { description }
    public var customMirror: Mirror {
        Mirror(self, children: ["name": name, "count": count])
    }

    public func assumingType<T>(_ type: T.Type) -> ColumnSlice<T> {
        ColumnSlice(name: name, values: values.map { $0 as? T })
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(values.count)
        for value in values { tabularHash(value, into: &hasher) }
    }

    public static func == (lhs: AnyColumnSlice, rhs: AnyColumnSlice) -> Bool {
        guard lhs.name == rhs.name, lhs.count == rhs.count else { return false }
        return zip(lhs.values, rhs.values).allSatisfy { tabularValuesEqual($0, $1) }
    }
}
