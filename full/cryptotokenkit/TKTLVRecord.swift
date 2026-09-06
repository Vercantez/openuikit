import Foundation

// MARK: - BER-TLV helpers (ISO 7816-4 / X.690 tag+length)

enum TKTLVCodec {
    static func encodeTag(_ tag: TKTLVTag) -> Data {
        if tag == 0 {
            return Data([0])
        }
        var bytes: [UInt8] = []
        var value = tag
        while value > 0 {
            bytes.insert(UInt8(truncatingIfNeeded: value & 0xFF), at: 0)
            value >>= 8
        }
        return Data(bytes)
    }

    static func encodeLength(_ length: Int) -> Data {
        if length < 0 {
            return Data([0])
        }
        if length < 0x80 {
            return Data([UInt8(length)])
        }
        var bytes: [UInt8] = []
        var remaining = length
        while remaining > 0 {
            bytes.insert(UInt8(truncatingIfNeeded: remaining & 0xFF), at: 0)
            remaining >>= 8
        }
        return Data([UInt8(0x80 | bytes.count)]) + Data(bytes)
    }

    static func encodeBER(tag: TKTLVTag, value: Data) -> Data {
        encodeTag(tag) + encodeLength(value.count) + value
    }

    struct Parsed {
        var tag: TKTLVTag
        var value: Data
        var encoded: Data
        var consumed: Int
    }

    static func parseTag(_ bytes: [UInt8], offset: inout Int) -> TKTLVTag? {
        guard offset < bytes.count else { return nil }
        let first = bytes[offset]
        offset += 1
        if (first & 0x1F) != 0x1F {
            return TKTLVTag(first)
        }
        var tag = TKTLVTag(first)
        var guardCount = 0
        while offset < bytes.count {
            let next = bytes[offset]
            offset += 1
            tag = (tag << 8) | TKTLVTag(next)
            guardCount += 1
            if next & 0x80 == 0 {
                return tag
            }
            if guardCount > 8 {
                return nil
            }
        }
        return nil
    }

    static func parseLength(_ bytes: [UInt8], offset: inout Int) -> Int? {
        guard offset < bytes.count else { return nil }
        let first = bytes[offset]
        offset += 1
        if first < 0x80 {
            return Int(first)
        }
        if first == 0x80 {
            return nil
        }
        let count = Int(first & 0x7F)
        if count == 0 || count > 8 || offset + count > bytes.count {
            return nil
        }
        var length = 0
        for _ in 0..<count {
            length = (length << 8) | Int(bytes[offset])
            offset += 1
        }
        return length
    }

    static func parseBER(_ data: Data, start: Int = 0) -> Parsed? {
        let bytes = [UInt8](data)
        var offset = start
        let origin = offset
        guard let tag = parseTag(bytes, offset: &offset) else { return nil }
        guard let length = parseLength(bytes, offset: &offset) else { return nil }
        guard length >= 0, offset + length <= bytes.count else { return nil }
        let value = Data(bytes[offset..<(offset + length)])
        offset += length
        let encoded = Data(bytes[origin..<offset])
        return Parsed(tag: tag, value: value, encoded: encoded, consumed: offset - origin)
    }

    static func parseBERSequence(_ data: Data) -> [Parsed]? {
        if data.isEmpty {
            return []
        }
        var offset = 0
        var records: [Parsed] = []
        while offset < data.count {
            guard let parsed = parseBER(data, start: offset) else { return nil }
            records.append(parsed)
            offset += parsed.consumed
        }
        return records
    }

    static func encodeCompact(tag: UInt8, value: Data) -> Data {
        let nibbleTag = tag & 0x0F
        let length = min(value.count, 15)
        let header = UInt8((nibbleTag << 4) | UInt8(length))
        return Data([header]) + value.prefix(length)
    }

    static func parseCompact(_ data: Data, start: Int = 0) -> Parsed? {
        let bytes = [UInt8](data)
        guard start < bytes.count else { return nil }
        let header = bytes[start]
        let tag = TKTLVTag(header >> 4)
        let length = Int(header & 0x0F)
        let origin = start
        let valueStart = start + 1
        guard valueStart + length <= bytes.count else { return nil }
        let value = Data(bytes[valueStart..<(valueStart + length)])
        let encoded = Data(bytes[origin..<(valueStart + length)])
        return Parsed(tag: tag, value: value, encoded: encoded, consumed: 1 + length)
    }

    static func parseCompactSequence(_ data: Data) -> [Parsed]? {
        if data.isEmpty {
            return []
        }
        var offset = 0
        var records: [Parsed] = []
        while offset < data.count {
            guard let parsed = parseCompact(data, start: offset) else { return nil }
            records.append(parsed)
            offset += parsed.consumed
        }
        return records
    }

    static func encodeSimple(tag: UInt8, value: Data) -> Data {
        let length = min(value.count, 255)
        return Data([tag, UInt8(length)]) + value.prefix(length)
    }

    static func parseSimple(_ data: Data, start: Int = 0) -> Parsed? {
        let bytes = [UInt8](data)
        guard start + 2 <= bytes.count else { return nil }
        let tag = TKTLVTag(bytes[start])
        let length = Int(bytes[start + 1])
        let valueStart = start + 2
        guard valueStart + length <= bytes.count else { return nil }
        let value = Data(bytes[valueStart..<(valueStart + length)])
        let encoded = Data(bytes[start..<(valueStart + length)])
        return Parsed(tag: tag, value: value, encoded: encoded, consumed: 2 + length)
    }
}

/// Abstract TLV record. Linux parses `init(from:)` as BER-TLV (ISO 7816-4).
open class TKTLVRecord: NSObject {
    public let tag: TKTLVTag
    public let value: Data
    private let encoded: Data

    public var data: Data { encoded }

    init(tag: TKTLVTag, value: Data, encoded: Data) {
        self.tag = tag
        self.value = value
        self.encoded = encoded
        super.init()
    }

    public convenience init?(from data: Data) {
        guard let parsed = TKTLVCodec.parseBER(data) else { return nil }
        self.init(tag: parsed.tag, value: parsed.value, encoded: parsed.encoded)
    }

    public convenience init?(fromData data: Data) {
        self.init(from: data)
    }

    public class func sequenceOfRecords(from data: Data) -> [TKTLVRecord]? {
        guard let parsed = TKTLVCodec.parseBERSequence(data) else { return nil }
        return parsed.map { item in
            TKBERTLVRecord(tag: item.tag, value: item.value)
        }
    }
}

/// BER-TLV record (ISO 7816-4 / X.690 definite length).
open class TKBERTLVRecord: TKTLVRecord {
    public class func data(forTag tag: TKTLVTag) -> Data {
        TKTLVCodec.encodeTag(tag)
    }

    public init(tag: TKTLVTag, value: Data) {
        super.init(tag: tag, value: value, encoded: TKTLVCodec.encodeBER(tag: tag, value: value))
    }

    public init(tag: TKTLVTag, records: [TKTLVRecord]) {
        var nested = Data()
        for record in records {
            nested.append(record.data)
        }
        super.init(tag: tag, value: nested, encoded: TKTLVCodec.encodeBER(tag: tag, value: nested))
    }
}

/// Compact TLV (ISO 7816-4 historical bytes): one nibble tag, one nibble length.
open class TKCompactTLVRecord: TKTLVRecord {
    public init(tag: UInt8, value: Data) {
        let encoded = TKTLVCodec.encodeCompact(tag: tag, value: value)
        let stored = encoded.count > 1 ? encoded.dropFirst() : Data()
        super.init(tag: TKTLVTag(tag & 0x0F), value: Data(stored), encoded: encoded)
    }
}

/// Simple TLV: one-byte tag, one-byte length, value (max 255 bytes).
open class TKSimpleTLVRecord: TKTLVRecord {
    public init(tag: UInt8, value: Data) {
        let encoded = TKTLVCodec.encodeSimple(tag: tag, value: value)
        let stored = encoded.count > 2 ? encoded.dropFirst(2) : Data()
        super.init(tag: TKTLVTag(tag), value: Data(stored), encoded: encoded)
    }
}
