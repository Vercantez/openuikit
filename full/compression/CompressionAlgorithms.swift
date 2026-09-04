import Foundation

enum CompressionCodec {
    static let outputLimit = 256 * 1024 * 1024

    static func encode(_ input: Data, algorithm: compression_algorithm) -> Data? {
        switch algorithm {
        case COMPRESSION_ZLIB:
            return encodeZlib(input)
        case COMPRESSION_LZ4:
            return encodeLZ4Frame(input)
        case COMPRESSION_LZ4_RAW:
            return encodeLZ4Raw(input)
        case COMPRESSION_BROTLI:
            return encodeBrotli(input)
        default:
            return nil
        }
    }

    static func decode(_ input: Data, algorithm: compression_algorithm) -> Data? {
        switch algorithm {
        case COMPRESSION_ZLIB:
            return decodeZlib(input)
        case COMPRESSION_LZ4:
            return decodeLZ4Frame(input)
        case COMPRESSION_LZ4_RAW:
            return decodeLZ4Raw(input)
        case COMPRESSION_BROTLI:
            return decodeBrotli(input)
        default:
            return nil
        }
    }

    // MARK: - zlib (RFC 1950 stored deflate blocks)

    private static func adler32(_ data: Data) -> UInt32 {
        var s1: UInt32 = 1
        var s2: UInt32 = 0
        for byte in data {
            s1 = (s1 + UInt32(byte)) % 65521
            s2 = (s2 + s1) % 65521
        }
        return (s2 << 16) | s1
    }

    private static func encodeZlib(_ input: Data) -> Data? {
        var output = Data()
        output.append(0x78)
        output.append(0x01)
        var offset = 0
        let count = input.count
        if count == 0 {
            output.append(0x01)
            output.append(contentsOf: [0x00, 0x00, 0xFF, 0xFF])
        } else {
            while offset < count {
                let remaining = count - offset
                let chunk = min(remaining, 65535)
                let isFinal = offset + chunk == count
                output.append(isFinal ? 0x01 : 0x00)
                let len = UInt16(chunk)
                output.append(UInt8(len & 0xFF))
                output.append(UInt8(len >> 8))
                let nlen = ~len
                output.append(UInt8(nlen & 0xFF))
                output.append(UInt8(nlen >> 8))
                let start = input.startIndex + offset
                output.append(input[start..<(start + chunk)])
                offset += chunk
            }
        }
        let checksum = adler32(input)
        output.append(UInt8((checksum >> 24) & 0xFF))
        output.append(UInt8((checksum >> 16) & 0xFF))
        output.append(UInt8((checksum >> 8) & 0xFF))
        output.append(UInt8(checksum & 0xFF))
        return output
    }

    private static func decodeZlib(_ input: Data) -> Data? {
        guard input.count >= 6 else { return nil }
        let cmf = input[input.startIndex]
        let flg = input[input.startIndex + 1]
        guard (UInt16(cmf) * 256 + UInt16(flg)) % 31 == 0 else { return nil }
        guard (cmf & 0x0F) == 8 else { return nil }
        guard (flg & 0x20) == 0 else { return nil }
        var index = 2
        var output = Data()
        var sawFinal = false
        while !sawFinal {
            guard index < input.count - 4 else { return nil }
            let header = input[input.startIndex + index]
            index += 1
            sawFinal = (header & 0x01) != 0
            let btype = (header >> 1) & 0x03
            guard btype == 0 else { return nil }
            guard index + 4 <= input.count - 4 else { return nil }
            let len = UInt16(input[input.startIndex + index])
                | (UInt16(input[input.startIndex + index + 1]) << 8)
            let nlen = UInt16(input[input.startIndex + index + 2])
                | (UInt16(input[input.startIndex + index + 3]) << 8)
            index += 4
            guard len == (~nlen & 0xFFFF) else { return nil }
            guard index + Int(len) <= input.count - 4 else { return nil }
            let end = index + Int(len)
            output.append(input[(input.startIndex + index)..<(input.startIndex + end)])
            index = end
            if output.count > outputLimit { return nil }
        }
        guard index + 4 == input.count else { return nil }
        let stored = (UInt32(input[input.startIndex + index]) << 24)
            | (UInt32(input[input.startIndex + index + 1]) << 16)
            | (UInt32(input[input.startIndex + index + 2]) << 8)
            | UInt32(input[input.startIndex + index + 3])
        guard stored == adler32(output) else { return nil }
        return output
    }

    // MARK: - LZ4 raw block + frame

    private static func encodeLZ4Raw(_ input: Data) -> Data? {
        var output = Data()
        let literalCount = input.count
        let tokenLiterals = min(literalCount, 15)
        output.append(UInt8(tokenLiterals << 4))
        if literalCount >= 15 {
            var extra = literalCount - 15
            while extra >= 255 {
                output.append(255)
                extra -= 255
            }
            output.append(UInt8(extra))
        }
        output.append(input)
        return output
    }

    private static func decodeLZ4Raw(_ input: Data) -> Data? {
        var index = 0
        var output = Data()
        let bytes = Array(input)
        while index < bytes.count {
            let token = bytes[index]
            index += 1
            var literalCount = Int(token >> 4)
            if literalCount == 15 {
                while index < bytes.count {
                    let extra = Int(bytes[index])
                    index += 1
                    literalCount += extra
                    if extra != 255 { break }
                }
            }
            guard index + literalCount <= bytes.count else { return nil }
            output.append(contentsOf: bytes[index..<(index + literalCount)])
            index += literalCount
            if index == bytes.count { break }
            guard index + 2 <= bytes.count else { return nil }
            let offset = Int(bytes[index]) | (Int(bytes[index + 1]) << 8)
            index += 2
            guard offset > 0, offset <= output.count else { return nil }
            var matchCount = Int(token & 0x0F) + 4
            if (token & 0x0F) == 15 {
                while index < bytes.count {
                    let extra = Int(bytes[index])
                    index += 1
                    matchCount += extra
                    if extra != 255 { break }
                }
            }
            for _ in 0..<matchCount {
                let copyIndex = output.count - offset
                guard copyIndex >= 0, copyIndex < output.count else { return nil }
                output.append(output[output.startIndex + copyIndex])
                if output.count > outputLimit { return nil }
            }
        }
        return output
    }

    private static func xxh32(_ data: Data, seed: UInt32 = 0) -> UInt32 {
        let prime1: UInt32 = 2_654_435_761
        let prime2: UInt32 = 2_246_822_519
        let prime3: UInt32 = 3_266_489_917
        let prime4: UInt32 = 668_265_263
        let prime5: UInt32 = 374_761_393
        let bytes = Array(data)
        var index = 0
        var hash: UInt32
        if bytes.count >= 16 {
            var v1 = seed &+ prime1 &+ prime2
            var v2 = seed &+ prime2
            var v3 = seed
            var v4 = seed &- prime1
            while index + 16 <= bytes.count {
                func round(_ acc: UInt32, _ lane: UInt32) -> UInt32 {
                    var value = acc &+ lane &* prime2
                    value = (value << 13) | (value >> 19)
                    return value &* prime1
                }
                func lane(_ offset: Int) -> UInt32 {
                    UInt32(bytes[index + offset])
                        | (UInt32(bytes[index + offset + 1]) << 8)
                        | (UInt32(bytes[index + offset + 2]) << 16)
                        | (UInt32(bytes[index + offset + 3]) << 24)
                }
                v1 = round(v1, lane(0))
                v2 = round(v2, lane(4))
                v3 = round(v3, lane(8))
                v4 = round(v4, lane(12))
                index += 16
            }
            hash = ((v1 << 1) | (v1 >> 31))
                &+ ((v2 << 7) | (v2 >> 25))
                &+ ((v3 << 12) | (v3 >> 20))
                &+ ((v4 << 18) | (v4 >> 14))
        } else {
            hash = seed &+ prime5
        }
        hash = hash &+ UInt32(bytes.count)
        while index + 4 <= bytes.count {
            let lane = UInt32(bytes[index])
                | (UInt32(bytes[index + 1]) << 8)
                | (UInt32(bytes[index + 2]) << 16)
                | (UInt32(bytes[index + 3]) << 24)
            hash = hash &+ lane &* prime3
            hash = ((hash << 17) | (hash >> 15)) &* prime4
            index += 4
        }
        while index < bytes.count {
            hash = hash &+ UInt32(bytes[index]) &* prime5
            hash = ((hash << 11) | (hash >> 21)) &* prime1
            index += 1
        }
        hash ^= hash >> 15
        hash = hash &* prime2
        hash ^= hash >> 13
        hash = hash &* prime3
        hash ^= hash >> 16
        return hash
    }

    private static func encodeLZ4Frame(_ input: Data) -> Data? {
        guard let block = encodeLZ4Raw(input) else { return nil }
        var output = Data([0x04, 0x22, 0x4D, 0x18])
        let flg: UInt8 = 0x40
        let bd: UInt8 = 0x70
        output.append(flg)
        output.append(bd)
        let headerChecksum = UInt8((xxh32(Data([flg, bd])) >> 8) & 0xFF)
        output.append(headerChecksum)
        let blockSize = UInt32(block.count)
        output.append(UInt8(blockSize & 0xFF))
        output.append(UInt8((blockSize >> 8) & 0xFF))
        output.append(UInt8((blockSize >> 16) & 0xFF))
        output.append(UInt8((blockSize >> 24) & 0xFF))
        output.append(block)
        output.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        return output
    }

    private static func decodeLZ4Frame(_ input: Data) -> Data? {
        let bytes = Array(input)
        guard bytes.count >= 7 else { return nil }
        guard bytes[0] == 0x04, bytes[1] == 0x22, bytes[2] == 0x4D, bytes[3] == 0x18 else {
            return nil
        }
        let flg = bytes[4]
        guard (flg >> 6) == 1 else { return nil }
        var index = 6
        if (flg & 0x08) != 0 { index += 8 }
        if (flg & 0x01) != 0 { index += 4 }
        guard index < bytes.count else { return nil }
        index += 1
        var output = Data()
        while index + 4 <= bytes.count {
            let size = UInt32(bytes[index])
                | (UInt32(bytes[index + 1]) << 8)
                | (UInt32(bytes[index + 2]) << 16)
                | (UInt32(bytes[index + 3]) << 24)
            index += 4
            if size == 0 { break }
            let uncompressed = (size & 0x8000_0000) != 0
            let blockSize = Int(size & 0x7FFF_FFFF)
            guard index + blockSize <= bytes.count else { return nil }
            let block = Data(bytes[index..<(index + blockSize)])
            index += blockSize
            if uncompressed {
                output.append(block)
            } else {
                guard let decoded = decodeLZ4Raw(block) else { return nil }
                output.append(decoded)
            }
            if output.count > outputLimit { return nil }
        }
        return output
    }

    // MARK: - Brotli (libbrotli when present; uncompressed metablocks otherwise)

    private static func encodeBrotli(_ input: Data) -> Data? {
        if let encoded = BrotliNative.compress(input) {
            return encoded
        }
        return encodeBrotliUncompressed(input)
    }

    private static func decodeBrotli(_ input: Data) -> Data? {
        if let decoded = BrotliNative.decompress(input) {
            return decoded
        }
        return decodeBrotliUncompressed(input)
    }

    private static func encodeBrotliUncompressed(_ input: Data) -> Data? {
        var writer = BitWriter()
        writer.write(1, bits: 1)
        writer.write(5, bits: 3)
        if input.isEmpty {
            writer.write(1, bits: 1)
            writer.write(1, bits: 1)
            writer.align()
            return writer.data
        }
        var offset = 0
        while offset < input.count {
            let chunk = min(input.count - offset, 4096)
            writer.write(0, bits: 1)
            writer.write(2, bits: 2)
            writer.write(chunk - 1, bits: 12)
            writer.write(1, bits: 1)
            writer.align()
            writer.append(input[(input.startIndex + offset)..<(input.startIndex + offset + chunk)])
            offset += chunk
        }
        writer.write(1, bits: 1)
        writer.write(1, bits: 1)
        writer.align()
        return writer.data
    }

    private static func decodeBrotliUncompressed(_ input: Data) -> Data? {
        var reader = BitReader(input)
        guard let first = reader.read(1) else { return nil }
        var windowBits: Int
        if first == 0 {
            windowBits = 16
        } else {
            guard let n = reader.read(3) else { return nil }
            if n != 0 {
                windowBits = n + 17
            } else {
                guard let m = reader.read(3) else { return nil }
                windowBits = m == 0 ? 17 : m + 8
            }
        }
        guard windowBits >= 10, windowBits <= 24 else { return nil }
        var output = Data()
        while true {
            guard let isLast = reader.read(1) else { return nil }
            if isLast == 1 {
                guard let empty = reader.read(1) else { return nil }
                if empty == 1 { break }
            }
            guard let mnibbles = reader.read(2) else { return nil }
            if mnibbles == 3 {
                guard let reserved = reader.read(1), reserved == 0 else { return nil }
                guard let skipBytes = reader.read(2) else { return nil }
                var skipLen = 0
                if skipBytes != 0 {
                    guard let encoded = reader.read(8 * skipBytes) else { return nil }
                    skipLen = encoded + 1
                }
                reader.align()
                guard reader.skipBytes(skipLen) else { return nil }
                continue
            }
            guard let mlenBits = reader.read(4 * (mnibbles + 1)) else { return nil }
            let mlen = mlenBits + 1
            var uncompressed = 0
            if isLast == 0 {
                guard let flag = reader.read(1) else { return nil }
                uncompressed = flag
            }
            if uncompressed == 1 {
                reader.align()
                guard let chunk = reader.takeBytes(mlen) else { return nil }
                output.append(chunk)
                if output.count > outputLimit { return nil }
            } else {
                return nil
            }
        }
        return output
    }
}

private struct BitWriter {
    var data = Data()
    private var bitBuffer: UInt32 = 0
    private var bitCount = 0

    mutating func write(_ value: Int, bits: Int) {
        bitBuffer |= UInt32(value & ((1 << bits) - 1)) << bitCount
        bitCount += bits
        while bitCount >= 8 {
            data.append(UInt8(bitBuffer & 0xFF))
            bitBuffer >>= 8
            bitCount -= 8
        }
    }

    mutating func align() {
        if bitCount > 0 {
            data.append(UInt8(bitBuffer & 0xFF))
            bitBuffer = 0
            bitCount = 0
        }
    }

    mutating func append(_ bytes: Data) {
        data.append(bytes)
    }
}

private struct BitReader {
    private let bytes: [UInt8]
    private var index = 0
    private var bit = 0

    init(_ data: Data) {
        bytes = Array(data)
    }

    mutating func read(_ count: Int) -> Int? {
        var value = 0
        for offset in 0..<count {
            guard index < bytes.count else { return nil }
            let bitValue = Int((bytes[index] >> bit) & 1)
            value |= bitValue << offset
            bit += 1
            if bit == 8 {
                bit = 0
                index += 1
            }
        }
        return value
    }

    mutating func align() {
        if bit != 0 {
            bit = 0
            index += 1
        }
    }

    mutating func skipBytes(_ count: Int) -> Bool {
        guard index + count <= bytes.count else { return false }
        index += count
        return true
    }

    mutating func takeBytes(_ count: Int) -> Data? {
        guard index + count <= bytes.count else { return nil }
        let slice = Data(bytes[index..<(index + count)])
        index += count
        return slice
    }
}

private enum BrotliNative {
    private static let encoder = Encoder()
    private static let decoder = Decoder()

    static func compress(_ input: Data) -> Data? {
        encoder.compress(input)
    }

    static func decompress(_ input: Data) -> Data? {
        decoder.decompress(input)
    }

    private final class Encoder: @unchecked Sendable {
        private let compressFn: CompressFn?
        private let maxSizeFn: MaxSizeFn?

        typealias CompressFn = @convention(c) (
            Int32, Int32, Int32, Int,
            UnsafePointer<UInt8>?, UnsafeMutablePointer<Int>?, UnsafeMutablePointer<UInt8>?
        ) -> Int32
        typealias MaxSizeFn = @convention(c) (Int) -> Int

        init() {
            let handle = "libbrotlienc.so.1".withCString { _dlopen($0, 2) }
                ?? "libbrotlienc.so".withCString { _dlopen($0, 2) }
            if let handle {
                let compressSymbol = "BrotliEncoderCompress".withCString { _dlsym(handle, $0) }
                let maxSymbol = "BrotliEncoderMaxCompressedSize".withCString { _dlsym(handle, $0) }
                compressFn = compressSymbol.map { unsafeBitCast($0, to: CompressFn.self) }
                maxSizeFn = maxSymbol.map { unsafeBitCast($0, to: MaxSizeFn.self) }
            } else {
                compressFn = nil
                maxSizeFn = nil
            }
        }

        func compress(_ input: Data) -> Data? {
            guard let compressFn else { return nil }
            let bound = max(maxSizeFn?(input.count) ?? (input.count + 1024), 1)
            var encodedSize = bound
            var output = [UInt8](repeating: 0, count: bound)
            let ok: Int32 = input.withUnsafeBytes { src in
                output.withUnsafeMutableBufferPointer { dst in
                    var size = encodedSize
                    let status = compressFn(
                        5,
                        22,
                        0,
                        input.count,
                        src.bindMemory(to: UInt8.self).baseAddress,
                        &size,
                        dst.baseAddress
                    )
                    encodedSize = size
                    return status
                }
            }
            guard ok != 0, encodedSize > 0, encodedSize <= output.count else { return nil }
            return Data(output.prefix(encodedSize))
        }
    }

    private final class Decoder: @unchecked Sendable {
        private let decompressFn: DecompressFn?

        typealias DecompressFn = @convention(c) (
            Int, UnsafePointer<UInt8>?, UnsafeMutablePointer<Int>?, UnsafeMutablePointer<UInt8>?
        ) -> Int32

        init() {
            let handle = "libbrotlidec.so.1".withCString { _dlopen($0, 2) }
                ?? "libbrotlidec.so".withCString { _dlopen($0, 2) }
            if let handle {
                let symbol = "BrotliDecoderDecompress".withCString { _dlsym(handle, $0) }
                decompressFn = symbol.map { unsafeBitCast($0, to: DecompressFn.self) }
            } else {
                decompressFn = nil
            }
        }

        func decompress(_ input: Data) -> Data? {
            guard let decompressFn else { return nil }
            var capacity = max(input.count * 8, 64)
            while capacity <= CompressionCodec.outputLimit {
                var decodedSize = capacity
                var output = [UInt8](repeating: 0, count: capacity)
                let status: Int32 = input.withUnsafeBytes { src in
                    output.withUnsafeMutableBufferPointer { dst in
                        var size = decodedSize
                        let result = decompressFn(
                            input.count,
                            src.bindMemory(to: UInt8.self).baseAddress,
                            &size,
                            dst.baseAddress
                        )
                        decodedSize = size
                        return result
                    }
                }
                if status == 1 {
                    return Data(output.prefix(decodedSize))
                }
                if status != 3 {
                    return nil
                }
                capacity *= 2
            }
            return nil
        }
    }
}

@_silgen_name("dlopen")
private func _dlopen(_ path: UnsafePointer<CChar>?, _ mode: Int32) -> UnsafeMutableRawPointer?

@_silgen_name("dlsym")
private func _dlsym(_ handle: UnsafeMutableRawPointer?, _ symbol: UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?
