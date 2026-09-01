import Compression
import Foundation

// Test-only declarations for the enclosing RevenueCat container types. The
// actual decompression implementation is compiled from the pinned repository's
// exact, untouched RCContainer+Compression.swift source.
struct RCContainer {
    struct Parser {
        enum FormatError: Error, Equatable {
            case unsupportedContentEncoding(UInt8)
            case contentDecompressionFailed(UInt8)
        }
    }

    struct Element {
        enum ContentEncoding: Equatable {
            case none
            case gzip
            case brotli
            case zstd
            case unsupported(UInt8)

            var rawValue: UInt8 {
                switch self {
                case .none: 0
                case .gzip: 1
                case .brotli: 2
                case .zstd: 3
                case let .unsupported(value): value
                }
            }

            static var brotliCompressionAlgorithm: Algorithm {
                get throws {
                    guard let algorithm = Algorithm(rawValue: COMPRESSION_BROTLI) else {
                        throw Parser.FormatError.contentDecompressionFailed(2)
                    }
                    return algorithm
                }
            }
        }
    }
}

@main
private enum RevenueCatZlibRuntime {
    static func main() throws {
        let compressed: [UInt8] = [
            0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x13, 0x05, 0xc1,
            0xd1, 0x0d, 0x80, 0x20, 0x0c, 0x05, 0xc0, 0x55, 0xde, 0x02, 0x2e, 0xe0,
            0x2f, 0xbf, 0x1a, 0x13, 0x36, 0xa8, 0xd0, 0x00, 0x09, 0x69, 0x09, 0xb6,
            0x46, 0x9d, 0xde, 0xbb, 0xc8, 0x37, 0x8b, 0x73, 0x20, 0x83, 0x8b, 0xa9,
            0xa7, 0xca, 0x19, 0x31, 0x04, 0x15, 0xa3, 0x26, 0x3c, 0x51, 0xbe, 0x36,
            0x30, 0xe8, 0xed, 0x4a, 0x79, 0xc5, 0xd0, 0x69, 0x74, 0x76, 0xc6, 0x4e,
            0xa9, 0x2e, 0x07, 0x8a, 0xf3, 0x65, 0x50, 0xc1, 0xd6, 0xc4, 0x9f, 0x1f,
            0x02, 0xc8, 0xd6, 0x53, 0x4d, 0x00, 0x00, 0x00
        ]
        let expected =
            "RevenueCat untouched RCContainer gzip payload: portable Mach-O guest on Linux"
        let decoded = try compressed.withUnsafeBytes { bytes in
            try RCContainer.Element.ContentEncoding.gzip.withDecodedBytes(
                from: bytes
            ) { decoded in
                String(decoding: decoded, as: UTF8.self)
            }
        }
        precondition(decoded == expected)

        do {
            _ = try [UInt8](repeating: 0xff, count: 5).withUnsafeBytes { bytes in
                try RCContainer.Element.ContentEncoding.gzip.withDecodedBytes(
                    from: bytes
                ) { Data($0) }
            }
            preconditionFailure("malformed gzip unexpectedly decoded")
        } catch let error as RCContainer.Parser.FormatError {
            precondition(error == .contentDecompressionFailed(1))
        }

        print(
            "REVENUECAT_ZLIB_UNTOUCHED_MACHO_OK commit=57043e7 " +
            "source=b0998e6 gzip=exact malformed=fail-closed bytes=77"
        )
    }
}
