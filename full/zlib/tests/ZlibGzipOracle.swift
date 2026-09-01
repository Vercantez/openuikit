import Foundation
import zlib

private let compressed: [UInt8] = [
    0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x13, 0x05, 0xc1,
    0xd1, 0x0d, 0x80, 0x20, 0x0c, 0x05, 0xc0, 0x55, 0xde, 0x02, 0x2e, 0xe0,
    0x2f, 0xbf, 0x1a, 0x13, 0x36, 0xa8, 0xd0, 0x00, 0x09, 0x69, 0x09, 0xb6,
    0x46, 0x9d, 0xde, 0xbb, 0xc8, 0x37, 0x8b, 0x73, 0x20, 0x83, 0x8b, 0xa9,
    0xa7, 0xca, 0x19, 0x31, 0x04, 0x15, 0xa3, 0x26, 0x3c, 0x51, 0xbe, 0x36,
    0x30, 0xe8, 0xed, 0x4a, 0x79, 0xc5, 0xd0, 0x69, 0x74, 0x76, 0xc6, 0x4e,
    0xa9, 0x2e, 0x07, 0x8a, 0xf3, 0x65, 0x50, 0xc1, 0xd6, 0xc4, 0x9f, 0x1f,
    0x02, 0xc8, 0xd6, 0x53, 0x4d, 0x00, 0x00, 0x00
]

private func decode(_ input: [UInt8]) -> (Int32, String, Int, Int) {
    var stream = z_stream()
    var output = [UInt8](repeating: 0, count: 256)
    let result: Int32 = input.withUnsafeBytes { inputBytes in
        output.withUnsafeMutableBytes { outputBytes in
            stream.next_in = UnsafeMutablePointer<Bytef>(
                mutating: inputBytes.bindMemory(to: Bytef.self).baseAddress
            )
            stream.avail_in = uInt(inputBytes.count)
            stream.next_out = outputBytes.bindMemory(to: Bytef.self).baseAddress
            stream.avail_out = uInt(outputBytes.count)
            let initialized = inflateInit2_(
                &stream,
                MAX_WBITS + 16,
                ZLIB_VERSION,
                Int32(MemoryLayout<z_stream>.size)
            )
            guard initialized == Z_OK else { return initialized }
            defer { inflateEnd(&stream) }
            return inflate(&stream, Z_FINISH)
        }
    }
    let string = String(decoding: output.prefix(Int(stream.total_out)), as: UTF8.self)
    return (result, string, Int(stream.avail_in), Int(stream.total_out))
}

let valid = decode(compressed)
let invalid = decode([0x1f, 0x8b, 0x08, 0x00, 0xff])
print(
    "abi=size:\(MemoryLayout<z_stream>.size),next-in:0,avail-in:8," +
    "next-out:24,state:56,reserved:104,version:\(ZLIB_VERSION)"
)
print("valid=status:\(valid.0),remaining:\(valid.2),bytes:\(valid.3),text:\(valid.1)")
print("invalid=status:\(invalid.0)")
