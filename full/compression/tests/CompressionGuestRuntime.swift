import Compression
import Foundation

@main
enum CompressionGuestRuntime {
    static func main() throws {
        let expected = Data(
            "IceCubes untouched RevenueCat Brotli response: portable Mach-O guests on Linux"
                .utf8
        )
        let appleEncoded = Data(base64Encoded:
            "iyaASWNlQ3ViZXMgdW50b3VjaGVkIFJldmVudWVDYXQgQnJvdGxpIHJlc3BvbnNlOiBwb3J0YWJsZSBNYWNoLU8gZ3Vlc3RzIG9uIExpbnV4Aw=="
        )!
        guard let algorithm = Algorithm(rawValue: COMPRESSION_BROTLI) else {
            fatalError("COMPRESSION_BROTLI unavailable")
        }

        var readOffset = 0
        let input = try InputFilter<Data>(.decompress, using: algorithm) { requested in
            guard readOffset < appleEncoded.count else { return nil }
            let end = min(readOffset + requested, appleEncoded.count)
            defer { readOffset = end }
            return appleEncoded.subdata(in: readOffset..<end)
        }
        var decoded = Data()
        while let chunk = try input.readData(ofLength: 7) {
            decoded.append(chunk)
        }
        precondition(decoded == expected)

        var encoded = Data()
        let output = try OutputFilter(.compress, using: algorithm) { chunk in
            if let chunk { encoded.append(chunk) }
        }
        try output.write(expected)
        try output.finalize()
        var encodedOffset = 0
        let replay = try InputFilter<Data>(.decompress, using: algorithm) { requested in
            guard encodedOffset < encoded.count else { return nil }
            let end = min(encodedOffset + requested, encoded.count)
            defer { encodedOffset = end }
            return encoded.subdata(in: encodedOffset..<end)
        }
        var roundTrip = Data()
        while let chunk = try replay.readData(ofLength: 11) {
            roundTrip.append(chunk)
        }
        precondition(roundTrip == expected)
        print("COMPRESSION_GUEST_OK algorithm=brotli apple-payload=decoded roundtrip=exact bounds=256MiB")
    }
}
