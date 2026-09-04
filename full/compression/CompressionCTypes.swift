import Foundation

/// Linux lookalikes of the Darwin `compression.h` enumerator types.
/// Raw values match Apple's public `compression.h` / pinned `dotnet/macios`
/// `Compression/Enums.cs` (`LZ4 = 0x100`, `LZ4Raw = 0x101`, `Zlib = 0x205`,
/// `Lzma = 0x306`, `LZBitmap = 0x702`, `Lzfse = 0x801`, `Brotli = 0xB02`).

public struct compression_algorithm: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public let COMPRESSION_LZ4 = compression_algorithm(rawValue: 0x100)
public let COMPRESSION_LZ4_RAW = compression_algorithm(rawValue: 0x101)
public let COMPRESSION_ZLIB = compression_algorithm(rawValue: 0x205)
public let COMPRESSION_LZMA = compression_algorithm(rawValue: 0x306)
public let COMPRESSION_LZBITMAP = compression_algorithm(rawValue: 0x702)
public let COMPRESSION_LZFSE = compression_algorithm(rawValue: 0x801)
public let COMPRESSION_BROTLI = compression_algorithm(rawValue: 0xB02)

public struct compression_status: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int32) {
        self.rawValue = rawValue
    }
}

public let COMPRESSION_STATUS_OK = compression_status(rawValue: 0)
public let COMPRESSION_STATUS_END = compression_status(rawValue: 1)
public let COMPRESSION_STATUS_ERROR = compression_status(rawValue: -1)

public struct compression_stream_flags: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public let COMPRESSION_STREAM_FINALIZE = compression_stream_flags(rawValue: 0x0001)

public struct compression_stream_operation: RawRepresentable, Equatable, Hashable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public let COMPRESSION_STREAM_ENCODE = compression_stream_operation(rawValue: 0)
public let COMPRESSION_STREAM_DECODE = compression_stream_operation(rawValue: 1)

public struct compression_stream {
    public var dst_ptr: UnsafeMutablePointer<UInt8>
    public var dst_size: Int
    public var src_ptr: UnsafePointer<UInt8>
    public var src_size: Int
    public var state: UnsafeMutableRawPointer?

    public init(
        dst_ptr: UnsafeMutablePointer<UInt8>,
        dst_size: Int,
        src_ptr: UnsafePointer<UInt8>,
        src_size: Int,
        state: UnsafeMutableRawPointer?
    ) {
        self.dst_ptr = dst_ptr
        self.dst_size = dst_size
        self.src_ptr = src_ptr
        self.src_size = src_size
        self.state = state
    }
}
