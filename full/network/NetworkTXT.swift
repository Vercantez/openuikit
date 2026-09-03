import Foundation

/// Bonjour TXT record. Dictionary and Data construction is local; no mDNS query
/// is performed.
public struct NWTXTRecord: Hashable, Sendable, Collection, CustomDebugStringConvertible {
    public enum Entry: Hashable, Sendable {
        case empty
        case string(String)
        case data(Data)
    }

    public struct Index: Hashable, Comparable, Sendable, Strideable {
        public let rawValue: Int
        public init(_ rawValue: Int) { self.rawValue = rawValue }
        public static func < (lhs: Index, rhs: Index) -> Bool { lhs.rawValue < rhs.rawValue }
        public func distance(to other: Index) -> Int { other.rawValue - rawValue }
        public func advanced(by n: Int) -> Index { Index(rawValue + n) }
    }

    public typealias Element = (key: String, value: Entry)
    public typealias Indices = DefaultIndices<NWTXTRecord>
    public typealias Iterator = IndexingIterator<NWTXTRecord>

    private var storage: [(key: String, value: Entry)]

    public static func == (lhs: NWTXTRecord, rhs: NWTXTRecord) -> Bool {
        guard lhs.storage.count == rhs.storage.count else { return false }
        for (a, b) in zip(lhs.storage, rhs.storage) {
            if a.key != b.key || a.value != b.value { return false }
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        for item in storage {
            hasher.combine(item.key)
            hasher.combine(item.value)
        }
    }

    public init(_ data: Data) {
        // Opaque payload kept as a single empty-key data entry until an Apple
        // TXT decoder oracle exists.
        if data.isEmpty {
            storage = []
        } else {
            storage = [(key: "", value: .data(data))]
        }
    }

    public init(_ dictionary: [String: String] = [:]) {
        storage = dictionary.keys.sorted().map { key in
            (key: key, value: .string(dictionary[key]!))
        }
    }

    public var startIndex: Index { Index(0) }
    public var endIndex: Index { Index(storage.count) }

    public func index(after i: Index) -> Index { Index(i.rawValue + 1) }

    public subscript(position: Index) -> Element {
        storage[position.rawValue]
    }

    public subscript(key: String) -> String? {
        get {
            guard let entry = getEntry(for: key) else { return nil }
            if case .string(let value) = entry { return value }
            return nil
        }
        set {
            if let value = newValue {
                _ = setEntry(.string(value), for: key)
            } else {
                storage.removeAll { $0.key == key }
            }
        }
    }

    public func getEntry(for key: String) -> Entry? {
        storage.first { $0.key == key }?.value
    }

    @discardableResult
    public mutating func setEntry(_ entry: Entry, for key: String) -> Bool {
        if let index = storage.firstIndex(where: { $0.key == key }) {
            storage[index] = (key: key, value: entry)
        } else {
            storage.append((key: key, value: entry))
        }
        return true
    }

    public var debugDescription: String {
        storage.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
    }
}
