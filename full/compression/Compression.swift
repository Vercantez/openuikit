import Foundation

public enum Algorithm: CaseIterable, Hashable, RawRepresentable, Sendable {
    case lzfse
    case zlib
    case lz4
    case lzma
    case lzbitmap
    case brotli

    public typealias RawValue = compression_algorithm
    public typealias AllCases = [Algorithm]

    nonisolated public static var allCases: [Algorithm] {
        [.lzfse, .zlib, .lz4, .lzma, .lzbitmap, .brotli]
    }

    public init?(rawValue: compression_algorithm) {
        switch rawValue {
        case COMPRESSION_LZFSE: self = .lzfse
        case COMPRESSION_ZLIB: self = .zlib
        case COMPRESSION_LZ4: self = .lz4
        case COMPRESSION_LZMA: self = .lzma
        case COMPRESSION_LZBITMAP: self = .lzbitmap
        case COMPRESSION_BROTLI: self = .brotli
        default: return nil
        }
    }

    public var rawValue: compression_algorithm {
        switch self {
        case .lzfse: COMPRESSION_LZFSE
        case .zlib: COMPRESSION_ZLIB
        case .lz4: COMPRESSION_LZ4
        case .lzma: COMPRESSION_LZMA
        case .lzbitmap: COMPRESSION_LZBITMAP
        case .brotli: COMPRESSION_BROTLI
        }
    }
}

public enum FilterOperation: Hashable, RawRepresentable, Sendable {
    case compress
    case decompress

    public typealias RawValue = compression_stream_operation

    public init?(rawValue: compression_stream_operation) {
        switch rawValue {
        case COMPRESSION_STREAM_ENCODE: self = .compress
        case COMPRESSION_STREAM_DECODE: self = .decompress
        default: return nil
        }
    }

    public var rawValue: compression_stream_operation {
        switch self {
        case .compress: COMPRESSION_STREAM_ENCODE
        case .decompress: COMPRESSION_STREAM_DECODE
        }
    }
}

public enum FilterError: Error, Hashable, Sendable {
    case invalidState
    case invalidData
}

private let _openCompressionLimit = 256 * 1024 * 1024

private func _transform(
    _ data: Data,
    operation: FilterOperation,
    algorithm: Algorithm
) throws -> Data {
    guard data.count <= _openCompressionLimit else { throw FilterError.invalidData }
    return try compressionTransform(data, operation: operation, algorithm: algorithm)
}

public final class InputFilter<D> where D: DataProtocol {
    private let operation: FilterOperation
    private let algorithm: Algorithm
    private let bufferCapacity: Int
    private let readFunc: (Int) throws -> D?
    private var prepared: Data?
    private var offset = 0
    private var finished = false

    public init(
        _ operation: FilterOperation,
        using algorithm: Algorithm,
        bufferCapacity: Int = 65536,
        readingFrom readFunc: @escaping (Int) throws -> D?
    ) throws {
        guard bufferCapacity > 0 else { throw FilterError.invalidState }
        self.operation = operation
        self.algorithm = algorithm
        self.bufferCapacity = bufferCapacity
        self.readFunc = readFunc
    }

    public func readData(ofLength count: Int) throws -> Data? {
        guard count > 0, !finished else {
            if finished { return nil }
            throw FilterError.invalidState
        }
        if prepared == nil {
            var input = Data()
            while let chunk = try readFunc(bufferCapacity) {
                guard !chunk.isEmpty,
                      input.count <= _openCompressionLimit - chunk.count else {
                    throw FilterError.invalidData
                }
                input.append(contentsOf: chunk)
            }
            prepared = try _transform(
                input,
                operation: operation,
                algorithm: algorithm
            )
        }
        guard let prepared else { throw FilterError.invalidState }
        if offset == prepared.count {
            finished = true
            return nil
        }
        let end = Swift.min(prepared.count, offset + count)
        let result = prepared.subdata(in: offset..<end)
        offset = end
        return result
    }
}

public final class OutputFilter {
    private let operation: FilterOperation
    private let algorithm: Algorithm
    private let bufferCapacity: Int
    private let writeFunc: (Data?) throws -> Void
    private var input = Data()
    private var finalized = false

    public init(
        _ operation: FilterOperation,
        using algorithm: Algorithm,
        bufferCapacity: Int = 65536,
        writingTo writeFunc: @escaping (Data?) throws -> Void
    ) throws {
        guard bufferCapacity > 0 else { throw FilterError.invalidState }
        self.operation = operation
        self.algorithm = algorithm
        self.bufferCapacity = bufferCapacity
        self.writeFunc = writeFunc
    }

    public func write<D>(_ data: D?) throws where D: DataProtocol {
        guard !finalized else { throw FilterError.invalidState }
        guard let data else {
            try finalize()
            return
        }
        guard input.count <= _openCompressionLimit - data.count else {
            throw FilterError.invalidData
        }
        input.append(contentsOf: data)
    }

    public func finalize() throws {
        guard !finalized else { throw FilterError.invalidState }
        finalized = true
        let output = try _transform(
            input,
            operation: operation,
            algorithm: algorithm
        )
        var offset = 0
        while offset < output.count {
            let end = Swift.min(output.count, offset + bufferCapacity)
            try writeFunc(output.subdata(in: offset..<end))
            offset = end
        }
        try writeFunc(nil)
    }
}
