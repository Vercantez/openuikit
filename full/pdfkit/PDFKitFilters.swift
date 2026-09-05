import Foundation

/// Stream filters from ISO 32000-1 §7.4 (PDF 1.7): ASCIIHexDecode (§7.4.2),
/// ASCII85Decode (§7.4.3), RunLengthDecode (§7.4.5), FlateDecode (§7.4.4,
/// zlib/RFC 1950 wrapping deflate/RFC 1951). Identity is a no-op.
enum PDFKitFilters {
    static let maxDecodedBytes = 8_000_000

    static func decode(_ data: Data, filter: PDFKitObject?, decodeParms: PDFKitObject?) throws -> Data {
        let names = filterNames(filter)
        var current = data
        let parmsList = decodeParmsList(decodeParms, count: names.count)
        for (index, name) in names.enumerated() {
            current = try apply(name, to: current, parms: parmsList[index])
            if current.count > maxDecodedBytes { throw PDFKitParseFailure.budgetExceeded }
        }
        return current
    }

    static func encodeFlate(_ data: Data) -> Data {
        PDFKitInflate.zlibStored(data)
    }

    static func encodeASCIIHex(_ data: Data) -> Data {
        var hex = Data()
        hex.reserveCapacity(data.count * 2 + 1)
        let digits = Array("0123456789ABCDEF".utf8)
        for byte in data {
            hex.append(digits[Int(byte >> 4)])
            hex.append(digits[Int(byte & 0x0F)])
        }
        hex.append(0x3E)
        return hex
    }

    static func encodeASCII85(_ data: Data) -> Data {
        var output = Data()
        var index = data.startIndex
        while index < data.endIndex {
            var chunk: UInt32 = 0
            var count = 0
            while count < 4 && index < data.endIndex {
                chunk = (chunk << 8) | UInt32(data[index])
                index += 1
                count += 1
            }
            if count < 4 { chunk <<= UInt32(8 * (4 - count)) }
            if count == 4 && chunk == 0 {
                output.append(0x7A)
                continue
            }
            var chars = [UInt8](repeating: 0, count: 5)
            var value = chunk
            for position in stride(from: 4, through: 0, by: -1) {
                chars[position] = UInt8(value % 85) &+ 33
                value /= 85
            }
            output.append(contentsOf: chars.prefix(count + 1))
        }
        output.append(contentsOf: [0x7E, 0x3E])
        return output
    }

    static func encodeRunLength(_ data: Data) -> Data {
        var output = Data()
        var index = data.startIndex
        while index < data.endIndex {
            let start = index
            let byte = data[index]
            index += 1
            var run = 1
            while index < data.endIndex, data[index] == byte, run < 128 {
                index += 1
                run += 1
            }
            if run >= 2 {
                output.append(UInt8(257 - run))
                output.append(byte)
                continue
            }
            index = start
            var literal: [UInt8] = []
            while index < data.endIndex, literal.count < 128 {
                let next = data[index]
                if index + 1 < data.endIndex, data[index + 1] == next {
                    var peek = 2
                    var cursor = index + 2
                    while cursor < data.endIndex, data[cursor] == next, peek < 128 {
                        peek += 1
                        cursor += 1
                    }
                    if peek >= 2 && !literal.isEmpty { break }
                }
                literal.append(next)
                index += 1
            }
            output.append(UInt8(literal.count - 1))
            output.append(contentsOf: literal)
        }
        output.append(128)
        return output
    }

    private static func apply(_ name: String, to data: Data, parms: [String: PDFKitObject]) throws -> Data {
        switch name {
        case "Identity":
            return data
        case "ASCIIHexDecode", "AHx":
            return try asciiHex(data)
        case "ASCII85Decode", "A85":
            return try ascii85(data)
        case "RunLengthDecode", "RL":
            return try runLength(data)
        case "FlateDecode", "Fl":
            let inflated = try PDFKitInflate.zlib(data)
            return try applyPredictor(inflated, parms: parms)
        default:
            throw PDFKitParseFailure.unsupportedFilter
        }
    }

    private static func filterNames(_ filter: PDFKitObject?) -> [String] {
        guard let filter else { return [] }
        if let name = filter.nameValue { return [name] }
        if let array = filter.arrayValue {
            return array.compactMap(\.nameValue)
        }
        return []
    }

    private static func decodeParmsList(
        _ parms: PDFKitObject?,
        count: Int
    ) -> [[String: PDFKitObject]] {
        if count == 0 { return [] }
        if let dict = parms?.dictValue {
            return Array(repeating: dict, count: count)
        }
        if let array = parms?.arrayValue {
            return (0..<count).map { index in
                index < array.count ? (array[index].dictValue ?? [:]) : [:]
            }
        }
        return Array(repeating: [:], count: count)
    }

    private static func asciiHex(_ data: Data) throws -> Data {
        var hex: [UInt8] = []
        hex.reserveCapacity(data.count)
        for byte in data {
            if byte == 0x3E { break }
            if byte == 0x00 || byte == 0x09 || byte == 0x0A || byte == 0x0C || byte == 0x0D || byte == 0x20 {
                continue
            }
            hex.append(byte)
        }
        if hex.count % 2 == 1 { hex.append(0x30) }
        var output = Data()
        output.reserveCapacity(hex.count / 2)
        var index = 0
        while index + 1 < hex.count {
            guard let high = fromHex(hex[index]), let low = fromHex(hex[index + 1]) else {
                throw PDFKitParseFailure.unsupportedFilter
            }
            output.append((high << 4) | low)
            index += 2
        }
        return output
    }

    private static func fromHex(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39: return byte - 0x30
        case 0x41...0x46: return byte - 0x41 + 10
        case 0x61...0x66: return byte - 0x61 + 10
        default: return nil
        }
    }

    private static func ascii85(_ data: Data) throws -> Data {
        var output = Data()
        var group: [UInt8] = []
        var index = data.startIndex
        func flush(_ count: Int) throws {
            if group.isEmpty { return }
            while group.count < 5 { group.append(0x21) }
            var value: UInt32 = 0
            for char in group {
                let digit = Int(char) - 33
                if digit < 0 || digit > 84 { throw PDFKitParseFailure.unsupportedFilter }
                value = value &* 85 &+ UInt32(digit)
            }
            let bytes = [
                UInt8((value >> 24) & 0xFF),
                UInt8((value >> 16) & 0xFF),
                UInt8((value >> 8) & 0xFF),
                UInt8(value & 0xFF)
            ]
            output.append(contentsOf: bytes.prefix(count))
            group.removeAll(keepingCapacity: true)
        }
        while index < data.endIndex {
            let byte = data[index]
            index += 1
            if byte == 0x7E, index < data.endIndex, data[index] == 0x3E { break }
            if byte == 0x00 || byte == 0x09 || byte == 0x0A || byte == 0x0C || byte == 0x0D || byte == 0x20 {
                continue
            }
            if byte == 0x7A {
                if !group.isEmpty { throw PDFKitParseFailure.unsupportedFilter }
                output.append(contentsOf: [0, 0, 0, 0])
                continue
            }
            group.append(byte)
            if group.count == 5 {
                try flush(4)
            }
        }
        if !group.isEmpty {
            let produced = group.count - 1
            try flush(produced)
        }
        return output
    }

    private static func runLength(_ data: Data) throws -> Data {
        var output = Data()
        var index = data.startIndex
        while index < data.endIndex {
            let control = data[index]
            index += 1
            if control == 128 { break }
            if control < 128 {
                let count = Int(control) + 1
                guard index + count <= data.endIndex else { throw PDFKitParseFailure.truncated }
                output.append(data[index..<(index + count)])
                index += count
            } else {
                guard index < data.endIndex else { throw PDFKitParseFailure.truncated }
                let repeated = data[index]
                index += 1
                let count = 257 - Int(control)
                output.append(contentsOf: repeatElement(repeated, count: count))
            }
            if output.count > maxDecodedBytes { throw PDFKitParseFailure.budgetExceeded }
        }
        return output
    }

    /// ISO 32000-1 Table 8 / §7.4.4.4 PNG and TIFF predictors.
    private static func applyPredictor(_ data: Data, parms: [String: PDFKitObject]) throws -> Data {
        let predictor = parms["Predictor"]?.intValue ?? 1
        if predictor <= 1 { return data }
        let columns = max(1, parms["Columns"]?.intValue ?? 1)
        let colors = max(1, parms["Colors"]?.intValue ?? 1)
        let bits = parms["BitsPerComponent"]?.intValue ?? 8
        if bits != 8 { throw PDFKitParseFailure.unsupportedFilter }
        let row = columns * colors
        if predictor == 2 {
            return try tiffPredictor(data, row: row, colors: colors)
        }
        if predictor >= 10 && predictor <= 15 {
            return try pngPredictor(data, row: row)
        }
        throw PDFKitParseFailure.unsupportedFilter
    }

    private static func tiffPredictor(_ data: Data, row: Int, colors: Int) throws -> Data {
        guard row > 0, data.count % row == 0 else { throw PDFKitParseFailure.unsupportedFilter }
        var output = [UInt8](data)
        var offset = 0
        while offset < output.count {
            for index in colors..<row {
                output[offset + index] = output[offset + index] &+ output[offset + index - colors]
            }
            offset += row
        }
        return Data(output)
    }

    private static func pngPredictor(_ data: Data, row: Int) throws -> Data {
        let stride = row + 1
        guard stride > 1, data.count % stride == 0 else { throw PDFKitParseFailure.unsupportedFilter }
        var output = Data()
        output.reserveCapacity((data.count / stride) * row)
        var previous = [UInt8](repeating: 0, count: row)
        var offset = 0
        while offset < data.count {
            let method = data[data.startIndex + offset]
            offset += 1
            var rowBytes = [UInt8](data[(data.startIndex + offset)..<(data.startIndex + offset + row)])
            offset += row
            switch method {
            case 0:
                break
            case 1:
                for index in 1..<row { rowBytes[index] = rowBytes[index] &+ rowBytes[index - 1] }
            case 2:
                for index in 0..<row { rowBytes[index] = rowBytes[index] &+ previous[index] }
            case 3:
                for index in 0..<row {
                    let left = index > 0 ? rowBytes[index - 1] : 0
                    let avg = UInt8((UInt16(left) + UInt16(previous[index])) / 2)
                    rowBytes[index] = rowBytes[index] &+ avg
                }
            case 4:
                for index in 0..<row {
                    let left = index > 0 ? rowBytes[index - 1] : 0
                    let up = previous[index]
                    let upLeft = index > 0 ? previous[index - 1] : 0
                    rowBytes[index] = rowBytes[index] &+ paeth(left, up, upLeft)
                }
            default:
                throw PDFKitParseFailure.unsupportedFilter
            }
            output.append(contentsOf: rowBytes)
            previous = rowBytes
        }
        return output
    }

    private static func paeth(_ a: UInt8, _ b: UInt8, _ c: UInt8) -> UInt8 {
        let ia = Int(a), ib = Int(b), ic = Int(c)
        let p = ia + ib - ic
        let pa = abs(p - ia), pb = abs(p - ib), pc = abs(p - ic)
        if pa <= pb && pa <= pc { return a }
        if pb <= pc { return b }
        return c
    }
}

/// RFC 1950 zlib wrapper around RFC 1951 deflate (stored, fixed, and dynamic
/// Huffman blocks). Used for FlateDecode; measured against Python zlib and
/// against stored-block fixtures the writer emits.
enum PDFKitInflate {
    static func zlib(_ data: Data) throws -> Data {
        guard data.count >= 6 else { throw PDFKitParseFailure.unsupportedFilter }
        let bytes = [UInt8](data)
        let cmf = bytes[0]
        let flg = bytes[1]
        if ((UInt16(cmf) << 8) | UInt16(flg)) % 31 != 0 { throw PDFKitParseFailure.unsupportedFilter }
        if (cmf & 0x0F) != 8 { throw PDFKitParseFailure.unsupportedFilter }
        if (flg & 0x20) != 0 { throw PDFKitParseFailure.unsupportedFilter }
        var reader = BitReader(bytes: bytes, index: 2)
        let inflated = try inflate(&reader)
        guard reader.byteIndex + 4 <= bytes.count else { throw PDFKitParseFailure.truncated }
        let stored =
            (UInt32(bytes[reader.byteIndex]) << 24)
            | (UInt32(bytes[reader.byteIndex + 1]) << 16)
            | (UInt32(bytes[reader.byteIndex + 2]) << 8)
            | UInt32(bytes[reader.byteIndex + 3])
        guard stored == adler32(inflated) else { throw PDFKitParseFailure.unsupportedFilter }
        return inflated
    }

    static func zlibStored(_ data: Data) -> Data {
        var output = Data()
        output.append(0x78)
        output.append(0x01)
        let count = data.count
        if count == 0 {
            output.append(contentsOf: [0x01, 0x00, 0x00, 0xFF, 0xFF])
        } else {
            var offset = 0
            while offset < count {
                let chunk = min(count - offset, 65535)
                let isFinal = offset + chunk == count
                output.append(isFinal ? 0x01 : 0x00)
                let len = UInt16(chunk)
                output.append(UInt8(len & 0xFF))
                output.append(UInt8(len >> 8))
                let nlen = ~len
                output.append(UInt8(nlen & 0xFF))
                output.append(UInt8(nlen >> 8))
                let start = data.startIndex + offset
                output.append(data[start..<(start + chunk)])
                offset += chunk
            }
        }
        let checksum = adler32(data)
        output.append(UInt8((checksum >> 24) & 0xFF))
        output.append(UInt8((checksum >> 16) & 0xFF))
        output.append(UInt8((checksum >> 8) & 0xFF))
        output.append(UInt8(checksum & 0xFF))
        return output
    }

    private static func inflate(_ reader: inout BitReader) throws -> Data {
        var output: [UInt8] = []
        var sawFinal = false
        while !sawFinal {
            sawFinal = try reader.bits(1) == 1
            let blockType = try reader.bits(2)
            switch blockType {
            case 0:
                try stored(&reader, into: &output)
            case 1:
                try huffman(&reader, literal: Self.fixedLiteral, distance: Self.fixedDistance, into: &output)
            case 2:
                let tables = try dynamicTables(&reader)
                try huffman(&reader, literal: tables.0, distance: tables.1, into: &output)
            default:
                throw PDFKitParseFailure.unsupportedFilter
            }
            if output.count > PDFKitFilters.maxDecodedBytes { throw PDFKitParseFailure.budgetExceeded }
        }
        return Data(output)
    }

    private static func stored(_ reader: inout BitReader, into output: inout [UInt8]) throws {
        reader.align()
        let len = try reader.bits(16)
        let nlen = try reader.bits(16)
        if UInt16(len) != (~UInt16(nlen) & 0xFFFF) { throw PDFKitParseFailure.unsupportedFilter }
        for _ in 0..<len {
            output.append(try reader.byte())
        }
    }

    private static func huffman(
        _ reader: inout BitReader,
        literal: HuffmanTable,
        distance: HuffmanTable,
        into output: inout [UInt8]
    ) throws {
        while true {
            let symbol = try literal.decode(&reader)
            if symbol < 256 {
                output.append(UInt8(symbol))
                continue
            }
            if symbol == 256 { return }
            let length = try lengthValue(symbol, reader: &reader)
            let distanceSymbol = try distance.decode(&reader)
            let distance = try distanceValue(distanceSymbol, reader: &reader)
            if distance <= 0 || distance > output.count { throw PDFKitParseFailure.unsupportedFilter }
            for _ in 0..<length {
                output.append(output[output.count - distance])
            }
            if output.count > PDFKitFilters.maxDecodedBytes { throw PDFKitParseFailure.budgetExceeded }
        }
    }

    private static func dynamicTables(_ reader: inout BitReader) throws -> (HuffmanTable, HuffmanTable) {
        let hlit = try reader.bits(5) + 257
        let hdist = try reader.bits(5) + 1
        let hclen = try reader.bits(4) + 4
        let order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
        var codeLengths = [Int](repeating: 0, count: 19)
        for index in 0..<hclen {
            codeLengths[order[index]] = try reader.bits(3)
        }
        let lengthTable = try HuffmanTable(lengths: codeLengths)
        var lengths = [Int](repeating: 0, count: hlit + hdist)
        var filled = 0
        while filled < lengths.count {
            let symbol = try lengthTable.decode(&reader)
            if symbol < 16 {
                lengths[filled] = symbol
                filled += 1
                continue
            }
            let repeatCount: Int
            let value: Int
            if symbol == 16 {
                if filled == 0 { throw PDFKitParseFailure.unsupportedFilter }
                value = lengths[filled - 1]
                repeatCount = try reader.bits(2) + 3
            } else if symbol == 17 {
                value = 0
                repeatCount = try reader.bits(3) + 3
            } else {
                value = 0
                repeatCount = try reader.bits(7) + 11
            }
            if filled + repeatCount > lengths.count { throw PDFKitParseFailure.unsupportedFilter }
            for _ in 0..<repeatCount {
                lengths[filled] = value
                filled += 1
            }
        }
        let literal = try HuffmanTable(lengths: Array(lengths.prefix(hlit)))
        let distance = try HuffmanTable(lengths: Array(lengths.suffix(hdist)))
        return (literal, distance)
    }

    private static let lengthBase: [Int] = [
        3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
        35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
    ]
    private static let lengthExtra: [Int] = [
        0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
        3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
    ]
    private static let distanceBase: [Int] = [
        1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
        257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
    ]
    private static let distanceExtra: [Int] = [
        0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
        7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
    ]

    private static func lengthValue(_ symbol: Int, reader: inout BitReader) throws -> Int {
        let index = symbol - 257
        guard lengthBase.indices.contains(index) else { throw PDFKitParseFailure.unsupportedFilter }
        return lengthBase[index] + (try reader.bits(lengthExtra[index]))
    }

    private static func distanceValue(_ symbol: Int, reader: inout BitReader) throws -> Int {
        guard distanceBase.indices.contains(symbol) else { throw PDFKitParseFailure.unsupportedFilter }
        return distanceBase[symbol] + (try reader.bits(distanceExtra[symbol]))
    }

    private static let fixedLiteral: HuffmanTable = {
        var lengths = [Int](repeating: 8, count: 288)
        for index in 144...255 { lengths[index] = 9 }
        for index in 256...279 { lengths[index] = 7 }
        for index in 280...287 { lengths[index] = 8 }
        return try! HuffmanTable(lengths: lengths)
    }()

    private static let fixedDistance: HuffmanTable = {
        try! HuffmanTable(lengths: [Int](repeating: 5, count: 32))
    }()

    private static func adler32(_ data: Data) -> UInt32 {
        var s1: UInt32 = 1
        var s2: UInt32 = 0
        for byte in data {
            s1 = (s1 + UInt32(byte)) % 65521
            s2 = (s2 + s1) % 65521
        }
        return (s2 << 16) | s1
    }
}

private struct BitReader {
    let bytes: [UInt8]
    var index: Int
    var bit = 0

    var byteIndex: Int { index }

    mutating func bits(_ count: Int) throws -> Int {
        if count == 0 { return 0 }
        var value = 0
        var shift = 0
        var remaining = count
        while remaining > 0 {
            guard index < bytes.count else { throw PDFKitParseFailure.truncated }
            let take = min(remaining, 8 - bit)
            let slice = Int(bytes[index] >> bit) & ((1 << take) - 1)
            value |= slice << shift
            shift += take
            remaining -= take
            bit += take
            if bit == 8 {
                bit = 0
                index += 1
            }
        }
        return value
    }

    mutating func byte() throws -> UInt8 {
        align()
        guard index < bytes.count else { throw PDFKitParseFailure.truncated }
        let value = bytes[index]
        index += 1
        return value
    }

    mutating func align() {
        if bit != 0 {
            bit = 0
            index += 1
        }
    }
}

private struct HuffmanTable {
    private let maxBits: Int
    private let symbols: [Int]
    private let bits: [Int]

    init(lengths: [Int]) throws {
        let maxBits = lengths.max() ?? 0
        if maxBits == 0 || maxBits > 15 { throw PDFKitParseFailure.unsupportedFilter }
        var blCount = [Int](repeating: 0, count: maxBits + 1)
        for length in lengths where length > 0 { blCount[length] += 1 }
        var nextCode = [Int](repeating: 0, count: maxBits + 1)
        var code = 0
        for bits in 1...maxBits {
            code = (code + blCount[bits - 1]) << 1
            nextCode[bits] = code
        }
        let size = 1 << maxBits
        var symbols = [Int](repeating: -1, count: size)
        var used = [Int](repeating: 0, count: size)
        for (symbol, length) in lengths.enumerated() where length > 0 {
            let assigned = nextCode[length]
            nextCode[length] += 1
            let reversed = reverseBits(assigned, length)
            let fill = 1 << (maxBits - length)
            for extra in 0..<fill {
                let index = reversed | (extra << length)
                symbols[index] = symbol
                used[index] = length
            }
        }
        self.maxBits = maxBits
        self.symbols = symbols
        self.bits = used
    }

    func decode(_ reader: inout BitReader) throws -> Int {
        var code = 0
        for length in 1...maxBits {
            code |= try reader.bits(1) << (length - 1)
            let probe = code
            if probe < symbols.count, bits[probe] == length, symbols[probe] >= 0 {
                return symbols[probe]
            }
        }
        throw PDFKitParseFailure.unsupportedFilter
    }
}

private func reverseBits(_ value: Int, _ count: Int) -> Int {
    var input = value
    var output = 0
    for _ in 0..<count {
        output = (output << 1) | (input & 1)
        input >>= 1
    }
    return output
}
