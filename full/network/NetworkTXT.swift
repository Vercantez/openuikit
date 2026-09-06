import Foundation

/// Bonjour TXT record per RFC 6763 §6. Dictionary and Data construction is
/// local; no mDNS query is performed.
public struct NWTXTRecord: Hashable, Sendable, Collection, CustomDebugStringConvertible {
    public enum Entry: Hashable, Sendable, CustomDebugStringConvertible {
        case none
        case empty
        case string(String)
        case data(Data)

        public init(_ data: Data?) {
            guard let data else {
                self = .none
                return
            }
            if data.isEmpty {
                self = .empty
            } else {
                self = .data(data)
            }
        }

        public var data: Data? {
            switch self {
            case .none:
                return nil
            case .empty:
                return Data()
            case .string(let value):
                return Data(value.utf8)
            case .data(let value):
                return value
            }
        }

        public var debugDescription: String {
            switch self {
            case .none: return "none"
            case .empty: return "empty"
            case .string(let value): return "string(\(value))"
            case .data(let value): return "data(\(value.count))"
            }
        }
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

    /// Decode RFC 6763 length-prefixed character-strings. A zero-length
    /// string is skipped. Strings without `=` are empty-valued keys.
    public init(_ data: Data) {
        storage = NWTXTRecord.decodeRFC6763(data)
    }

    public init(_ dictionary: [String: String] = [:]) {
        storage = dictionary.keys.sorted().map { key in
            let value = dictionary[key]!
            if value.isEmpty {
                return (key: key, value: .empty)
            }
            return (key: key, value: .string(value))
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
            switch entry {
            case .string(let value): return value
            case .empty: return ""
            case .data(let value): return String(data: value, encoding: .utf8)
            case .none: return nil
            }
        }
        set {
            if let value = newValue {
                _ = setEntry(value.isEmpty ? .empty : .string(value), for: key)
            } else {
                _ = removeEntry(key: key)
            }
        }
    }

    public var dictionary: [String: String] {
        var result: [String: String] = [:]
        for item in storage {
            if let value = self[item.key] {
                result[item.key] = value
            }
        }
        return result
    }

    /// RFC 6763 wire form: concatenated `<length><character-string>` pairs.
    public var data: Data {
        NWTXTRecord.encodeRFC6763(storage)
    }

    public func getEntry(for key: String) -> Entry? {
        storage.first { $0.key == key }?.value
    }

    @discardableResult
    public mutating func setEntry(_ entry: Entry, for key: String) -> Bool {
        if key.isEmpty { return false }
        if encodedLength(key: key, entry: entry) > 255 { return false }
        if let index = storage.firstIndex(where: { $0.key == key }) {
            storage[index] = (key: key, value: entry)
        } else {
            storage.append((key: key, value: entry))
        }
        return true
    }

    @discardableResult
    public mutating func removeEntry(key: String) -> Bool {
        let before = storage.count
        storage.removeAll { $0.key == key }
        return storage.count != before
    }

    public var debugDescription: String {
        storage.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
    }

    private func encodedLength(key: String, entry: Entry) -> Int {
        NWTXTRecord.characterString(key: key, entry: entry).count
    }

    static func decodeRFC6763(_ data: Data) -> [(key: String, value: Entry)] {
        var result: [(key: String, value: Entry)] = []
        var offset = 0
        let bytes = [UInt8](data)
        while offset < bytes.count {
            let length = Int(bytes[offset])
            offset += 1
            if length == 0 {
                continue
            }
            guard offset + length <= bytes.count else { break }
            let slice = Array(bytes[offset..<(offset + length)])
            offset += length
            if let equal = slice.firstIndex(of: 0x3d) {
                let keyBytes = slice[..<equal]
                let valueBytes = slice[(equal + 1)...]
                guard let key = String(bytes: keyBytes, encoding: .utf8), !key.isEmpty else {
                    continue
                }
                let valueData = Data(valueBytes)
                if valueData.isEmpty {
                    result.append((key: key, value: .empty))
                } else if let text = String(data: valueData, encoding: .utf8),
                          text.utf8.count == valueData.count
                {
                    result.append((key: key, value: .string(text)))
                } else {
                    result.append((key: key, value: .data(valueData)))
                }
            } else if let key = String(bytes: slice, encoding: .utf8), !key.isEmpty {
                result.append((key: key, value: .empty))
            }
        }
        return result
    }

    static func encodeRFC6763(_ storage: [(key: String, value: Entry)]) -> Data {
        var encoded = Data()
        for item in storage {
            let chars = characterString(key: item.key, entry: item.value)
            guard !chars.isEmpty, chars.count <= 255 else { continue }
            encoded.append(UInt8(chars.count))
            encoded.append(contentsOf: chars)
        }
        return encoded
    }

    static func characterString(key: String, entry: Entry) -> [UInt8] {
        let keyBytes = Array(key.utf8)
        guard !keyBytes.isEmpty, !keyBytes.contains(0x3d) else { return [] }
        switch entry {
        case .none:
            return []
        case .empty:
            return keyBytes
        case .string(let value):
            return keyBytes + [0x3d] + Array(value.utf8)
        case .data(let value):
            return keyBytes + [0x3d] + Array(value)
        }
    }
}
