// A Foundation-free reader for Apple's binary property list (`bplist00`).
// Owner: app-compat module (storyboard runtime).
//
// Why it exists: a compiled storyboard (`ibtool --compile X.storyboard`) is a
// `.storyboardc` directory whose `Info.plist` names the entry point and maps
// every storyboard identifier to its scene nib. `ibtool` writes that plist in
// the binary format (MEASURED: `file` reports "Apple binary property list"
// for all three compiled storyboards carried under fixtures/), and the
// OpenUIKit core must read it without Foundation on the guest library route.
//
// Layout (the published CFBinaryPList format, checked against the carried
// Info.plist bytes): "bplist00", then objects, then an offset table, then a
// 32-byte trailer — 6 unused bytes, offset-int size, object-ref size, object
// count (u64 BE), top object (u64 BE), offset-table offset (u64 BE). Object
// markers: 0x00 null, 0x08 false, 0x09 true, 0x1n int (2^n bytes BE),
// 0x2n real, 0x33 date, 0x4n data, 0x5n ASCII string, 0x6n UTF-16BE string,
// 0xAn array, 0xDn dictionary; a low nibble of 0xF means the count follows
// as an int object. Anything else fails closed (nil), like NibArchive.parse.

/// One decoded property-list value.
enum PropertyListValue: Equatable {
    case string(String)
    case integer(Int)
    case real(Double)
    case boolean(Bool)
    case data([UInt8])
    case date(Double)
    case array([PropertyListValue])
    case dictionary([String: PropertyListValue])
    case null

    var string: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var dictionary: [String: PropertyListValue]? {
        if case .dictionary(let d) = self { return d }
        return nil
    }

    subscript(key: String) -> PropertyListValue? { dictionary?[key] }
}

enum BinaryPropertyList {
    static func parse(_ bytes: [UInt8]) -> PropertyListValue? {
        let magic: [UInt8] = Array("bplist00".utf8)
        guard bytes.count >= 40, Array(bytes[0..<8]) == magic else { return nil }
        let trailer = bytes.count - 32
        let offsetSize = Int(bytes[trailer + 6])
        let refSize = Int(bytes[trailer + 7])
        guard let count = be(bytes, trailer + 8, 8), let top = be(bytes, trailer + 16, 8),
              let tableOffset = be(bytes, trailer + 24, 8),
              (1...8).contains(offsetSize), (1...8).contains(refSize),
              count > 0, top < count,
              tableOffset + count * offsetSize <= trailer else { return nil }
        var offsets: [Int] = []
        offsets.reserveCapacity(count)
        for i in 0..<count {
            guard let o = be(bytes, tableOffset + i * offsetSize, offsetSize), o < trailer
            else { return nil }
            offsets.append(o)
        }
        var reader = Reader(bytes: bytes, offsets: offsets, refSize: refSize)
        return reader.object(top, depth: 0)
    }

    /// Big-endian unsigned integer of `width` bytes, nil past the end.
    static func be(_ bytes: [UInt8], _ at: Int, _ width: Int) -> Int? {
        guard at >= 0, width > 0, at + width <= bytes.count else { return nil }
        var v: UInt64 = 0
        for i in 0..<width { v = (v << 8) | UInt64(bytes[at + i]) }
        guard v <= UInt64(Int.max) else { return nil }
        return Int(v)
    }

    private struct Reader {
        let bytes: [UInt8]
        let offsets: [Int]
        let refSize: Int

        /// A marker's length: the low nibble, or the int object after it.
        func length(_ marker: UInt8, at start: Int) -> (count: Int, body: Int)? {
            let nibble = Int(marker & 0x0F)
            if nibble != 0x0F { return (nibble, start + 1) }
            guard start + 1 < bytes.count else { return nil }
            let intMarker = bytes[start + 1]
            guard intMarker & 0xF0 == 0x10 else { return nil }
            let width = 1 << Int(intMarker & 0x0F)
            guard let n = BinaryPropertyList.be(bytes, start + 2, width) else { return nil }
            return (n, start + 2 + width)
        }

        mutating func object(_ index: Int, depth: Int) -> PropertyListValue? {
            // A malformed file can make a container reference itself.
            guard index >= 0, index < offsets.count, depth < 64 else { return nil }
            let start = offsets[index]
            let marker = bytes[start]
            switch marker >> 4 {
            case 0x0:
                switch marker {
                case 0x00: return .null
                case 0x08: return .boolean(false)
                case 0x09: return .boolean(true)
                default: return nil
                }
            case 0x1:
                let width = 1 << Int(marker & 0x0F)
                guard width <= 8, start + 1 + width <= bytes.count else { return nil }
                var v: UInt64 = 0
                for i in 0..<width { v = (v << 8) | UInt64(bytes[start + 1 + i]) }
                // 1/2/4-byte ints are unsigned; 8-byte ints are signed.
                return .integer(width == 8 ? Int(Int64(bitPattern: v)) : Int(v))
            case 0x2:
                let width = 1 << Int(marker & 0x0F)
                guard start + 1 + width <= bytes.count else { return nil }
                var v: UInt64 = 0
                for i in 0..<width { v = (v << 8) | UInt64(bytes[start + 1 + i]) }
                if width == 4 { return .real(Double(Float(bitPattern: UInt32(v)))) }
                if width == 8 { return .real(Double(bitPattern: v)) }
                return nil
            case 0x3:
                guard marker == 0x33, start + 9 <= bytes.count else { return nil }
                var v: UInt64 = 0
                for i in 0..<8 { v = (v << 8) | UInt64(bytes[start + 1 + i]) }
                return .date(Double(bitPattern: v))
            case 0x4:
                guard let (n, body) = length(marker, at: start), body + n <= bytes.count
                else { return nil }
                return .data(Array(bytes[body..<(body + n)]))
            case 0x5:
                guard let (n, body) = length(marker, at: start), body + n <= bytes.count
                else { return nil }
                return .string(String(decoding: bytes[body..<(body + n)], as: UTF8.self))
            case 0x6:
                guard let (n, body) = length(marker, at: start), body + 2 * n <= bytes.count
                else { return nil }
                var units: [UInt16] = []
                units.reserveCapacity(n)
                for i in 0..<n {
                    units.append(UInt16(bytes[body + 2 * i]) << 8 | UInt16(bytes[body + 2 * i + 1]))
                }
                return .string(String(decoding: units, as: UTF16.self))
            case 0xA:
                guard let (n, body) = length(marker, at: start),
                      body + n * refSize <= bytes.count else { return nil }
                var items: [PropertyListValue] = []
                for i in 0..<n {
                    guard let ref = BinaryPropertyList.be(bytes, body + i * refSize, refSize),
                          let item = object(ref, depth: depth + 1) else { return nil }
                    items.append(item)
                }
                return .array(items)
            case 0xD:
                guard let (n, body) = length(marker, at: start),
                      body + 2 * n * refSize <= bytes.count else { return nil }
                var dict: [String: PropertyListValue] = [:]
                for i in 0..<n {
                    guard let keyRef = BinaryPropertyList.be(bytes, body + i * refSize, refSize),
                          let valueRef = BinaryPropertyList.be(bytes, body + (n + i) * refSize, refSize),
                          case .string(let key)? = object(keyRef, depth: depth + 1),
                          let value = object(valueRef, depth: depth + 1) else { return nil }
                    dict[key] = value
                }
                return .dictionary(dict)
            default:
                return nil
            }
        }
    }
}
