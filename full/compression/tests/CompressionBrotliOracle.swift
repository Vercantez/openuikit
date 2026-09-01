import Compression
import Foundation

let payload = Data(
    "IceCubes untouched RevenueCat Brotli response: portable Mach-O guests on Linux"
        .utf8
)
guard let algorithm = Algorithm(rawValue: COMPRESSION_BROTLI) else {
    fatalError("Apple Compression rejected COMPRESSION_BROTLI")
}

var encoded = Data()
let output = try OutputFilter(.compress, using: algorithm) { chunk in
    if let chunk {
        encoded.append(chunk)
    }
}
try output.write(payload)
try output.finalize()

var offset = 0
let input = try InputFilter<Data>(.decompress, using: algorithm) { requested in
    guard offset < encoded.count else { return nil }
    let end = min(offset + requested, encoded.count)
    defer { offset = end }
    return encoded.subdata(in: offset..<end)
}
var decoded = Data()
while let chunk = try input.readData(ofLength: 7) {
    decoded.append(chunk)
}

print("algorithm=\(String(describing: algorithm.rawValue))")
print("encoded=\(encoded.base64EncodedString())")
print("decoded=\(String(decoding: decoded, as: UTF8.self))")
