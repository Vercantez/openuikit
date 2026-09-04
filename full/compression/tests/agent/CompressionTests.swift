import Compression
import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

private let samplePayload = Data(
    "IceCubes untouched RevenueCat Brotli response: portable Mach-O guests on Linux".utf8
)

private let appleBrotliTranscript: [UInt8] = [
    0x8b, 0x26, 0x80, 0x49, 0x63, 0x65, 0x43, 0x75, 0x62, 0x65,
    0x73, 0x20, 0x75, 0x6e, 0x74, 0x6f, 0x75, 0x63, 0x68, 0x65,
    0x64, 0x20, 0x52, 0x65, 0x76, 0x65, 0x6e, 0x75, 0x65, 0x43,
    0x61, 0x74, 0x20, 0x42, 0x72, 0x6f, 0x74, 0x6c, 0x69, 0x20,
    0x72, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65, 0x3a, 0x20,
    0x70, 0x6f, 0x72, 0x74, 0x61, 0x62, 0x6c, 0x65, 0x20, 0x4d,
    0x61, 0x63, 0x68, 0x2d, 0x4f, 0x20, 0x67, 0x75, 0x65, 0x73,
    0x74, 0x73, 0x20, 0x6f, 0x6e, 0x20, 0x4c, 0x69, 0x6e, 0x75,
    0x78, 0x03
]

private func roundTripBuffer(_ algorithm: compression_algorithm, payload: Data = samplePayload) {
    var encoded = [UInt8](repeating: 0, count: max(payload.count * 4 + 64, 128))
    let encodedCount = payload.withUnsafeBytes { src in
        encoded.withUnsafeMutableBufferPointer { dst in
            compression_encode_buffer(
                dst.baseAddress!,
                dst.count,
                src.bindMemory(to: UInt8.self).baseAddress!,
                payload.count,
                nil,
                algorithm
            )
        }
    }
    require(encodedCount > 0, "encode produced no bytes")
    var decoded = [UInt8](repeating: 0, count: max(payload.count + 16, 16))
    let decodedCount = encoded.withUnsafeBufferPointer { src in
        decoded.withUnsafeMutableBufferPointer { dst in
            compression_decode_buffer(
                dst.baseAddress!,
                dst.count,
                src.baseAddress!,
                encodedCount,
                nil,
                algorithm
            )
        }
    }
    require(decodedCount == payload.count, "decoded length drifted")
    require(Data(decoded.prefix(decodedCount)) == payload, "decoded bytes drifted")
}

func testAlgorithmRawValues() {
    require(Algorithm.allCases == [.lzfse, .zlib, .lz4, .lzma, .lzbitmap, .brotli], "allCases order")
    require(Algorithm.AllCases.self == [Algorithm].self, "AllCases")
    require(Algorithm.RawValue.self == compression_algorithm.self, "RawValue")
    require(Algorithm.lzfse.rawValue == COMPRESSION_LZFSE, "lzfse")
    require(Algorithm.zlib.rawValue == COMPRESSION_ZLIB, "zlib")
    require(Algorithm.lz4.rawValue == COMPRESSION_LZ4, "lz4")
    require(Algorithm.lzma.rawValue == COMPRESSION_LZMA, "lzma")
    require(Algorithm.lzbitmap.rawValue == COMPRESSION_LZBITMAP, "lzbitmap")
    require(Algorithm.brotli.rawValue == COMPRESSION_BROTLI, "brotli")
    require(Algorithm(rawValue: COMPRESSION_BROTLI) == .brotli, "init brotli")
    require(Algorithm(rawValue: COMPRESSION_LZ4_RAW) == nil, "lz4 raw is C-only")
    require(Algorithm.zlib != Algorithm.lz4, "algorithm !=")
    require(Algorithm.zlib.hashValue == Algorithm.zlib.hashValue, "algorithm hashValue")
    var hasher = Hasher()
    Algorithm.brotli.hash(into: &hasher)
    _ = hasher.finalize()
}

func testFilterOperationRawValues() {
    require(FilterOperation.RawValue.self == compression_stream_operation.self, "RawValue")
    require(FilterOperation.compress.rawValue == COMPRESSION_STREAM_ENCODE, "compress")
    require(FilterOperation.decompress.rawValue == COMPRESSION_STREAM_DECODE, "decompress")
    require(FilterOperation(rawValue: COMPRESSION_STREAM_ENCODE) == .compress, "init encode")
    require(FilterOperation(rawValue: COMPRESSION_STREAM_DECODE) == .decompress, "init decode")
    require(FilterOperation.compress != FilterOperation.decompress, "operation !=")
    require(FilterOperation.compress.hashValue == FilterOperation.compress.hashValue, "hashValue")
    var hasher = Hasher()
    FilterOperation.decompress.hash(into: &hasher)
    _ = hasher.finalize()
}

func testFilterErrorHashable() {
    require(FilterError.invalidData == FilterError.invalidData, "invalidData ==")
    require(FilterError.invalidState == FilterError.invalidState, "invalidState ==")
    require(FilterError.invalidData != FilterError.invalidState, "error !=")
    require(FilterError.invalidData.hashValue == FilterError.invalidData.hashValue, "hashValue")
    var hasher = Hasher()
    FilterError.invalidState.hash(into: &hasher)
    _ = hasher.finalize()
    require(!FilterError.invalidData.localizedDescription.isEmpty, "localizedDescription")
}

func testCConstants() {
    require(COMPRESSION_LZ4.rawValue == 0x100, "LZ4")
    require(COMPRESSION_LZ4_RAW.rawValue == 0x101, "LZ4_RAW")
    require(COMPRESSION_ZLIB.rawValue == 0x205, "ZLIB")
    require(COMPRESSION_LZMA.rawValue == 0x306, "LZMA")
    require(COMPRESSION_LZBITMAP.rawValue == 0x702, "LZBITMAP")
    require(COMPRESSION_LZFSE.rawValue == 0x801, "LZFSE")
    require(COMPRESSION_BROTLI.rawValue == 0xB02, "BROTLI")
    require(COMPRESSION_STATUS_OK.rawValue == 0, "OK")
    require(COMPRESSION_STATUS_END.rawValue == 1, "END")
    require(COMPRESSION_STATUS_ERROR.rawValue == -1, "ERROR")
    require(COMPRESSION_STREAM_FINALIZE.rawValue == 1, "FINALIZE")
    require(COMPRESSION_STREAM_ENCODE.rawValue == 0, "ENCODE")
    require(COMPRESSION_STREAM_DECODE.rawValue == 1, "DECODE")
}

func testCStructInitsAndHash() {
    let algorithm = compression_algorithm(0xB02)
    require(algorithm.rawValue == COMPRESSION_BROTLI.rawValue, "algorithm unlabeled init")
    require(compression_algorithm(rawValue: 0x100) == COMPRESSION_LZ4, "algorithm rawValue init")
    require(algorithm != COMPRESSION_ZLIB, "algorithm !=")
    require(algorithm.hashValue == COMPRESSION_BROTLI.hashValue, "algorithm hashValue")
    var algorithmHasher = Hasher()
    algorithm.hash(into: &algorithmHasher)
    _ = algorithmHasher.finalize()

    let status = compression_status(-1)
    require(status == COMPRESSION_STATUS_ERROR, "status unlabeled")
    require(compression_status(rawValue: 0) == COMPRESSION_STATUS_OK, "status rawValue")
    require(status != COMPRESSION_STATUS_OK, "status !=")
    require(status.hashValue == COMPRESSION_STATUS_ERROR.hashValue, "status hashValue")
    var statusHasher = Hasher()
    status.hash(into: &statusHasher)
    _ = statusHasher.finalize()

    let flags = compression_stream_flags(1)
    require(flags == COMPRESSION_STREAM_FINALIZE, "flags unlabeled")
    require(compression_stream_flags(rawValue: 1) == COMPRESSION_STREAM_FINALIZE, "flags rawValue")
    require(flags != compression_stream_flags(0), "flags !=")
    require(flags.hashValue == COMPRESSION_STREAM_FINALIZE.hashValue, "flags hashValue")
    var flagsHasher = Hasher()
    flags.hash(into: &flagsHasher)
    _ = flagsHasher.finalize()

    let operation = compression_stream_operation(0)
    require(operation == COMPRESSION_STREAM_ENCODE, "operation unlabeled")
    require(compression_stream_operation(rawValue: 1) == COMPRESSION_STREAM_DECODE, "operation rawValue")
    require(operation != COMPRESSION_STREAM_DECODE, "operation !=")
    require(operation.hashValue == COMPRESSION_STREAM_ENCODE.hashValue, "operation hashValue")
    var operationHasher = Hasher()
    operation.hash(into: &operationHasher)
    _ = operationHasher.finalize()
}

func testZlibBufferRoundTrip() {
    roundTripBuffer(COMPRESSION_ZLIB)
}

func testLZ4BufferRoundTrip() {
    roundTripBuffer(COMPRESSION_LZ4)
    roundTripBuffer(COMPRESSION_LZ4_RAW)
}

func testBrotliBufferAndAppleTranscript() {
    roundTripBuffer(COMPRESSION_BROTLI)
    var decoded = [UInt8](repeating: 0, count: samplePayload.count + 8)
    let count = appleBrotliTranscript.withUnsafeBufferPointer { src in
        decoded.withUnsafeMutableBufferPointer { dst in
            compression_decode_buffer(
                dst.baseAddress!,
                dst.count,
                src.baseAddress!,
                appleBrotliTranscript.count,
                nil,
                COMPRESSION_BROTLI
            )
        }
    }
    require(count == samplePayload.count, "apple length")
    require(Data(decoded.prefix(count)) == samplePayload, "apple bytes")
}

func testInputOutputFilters() {
    var encoded = Data()
    let output = try! OutputFilter(.compress, using: .zlib, bufferCapacity: 8) { chunk in
        if let chunk {
            encoded.append(chunk)
        }
    }
    try! output.write(samplePayload)
    try! output.finalize()
    require(!encoded.isEmpty, "output filter produced bytes")

    var offset = 0
    let input = try! InputFilter<Data>(.decompress, using: .zlib, bufferCapacity: 5) { requested in
        guard offset < encoded.count else { return nil }
        let end = min(offset + requested, encoded.count)
        defer { offset = end }
        return encoded.subdata(in: offset..<end)
    }
    var decoded = Data()
    while let chunk = try! input.readData(ofLength: 9) {
        decoded.append(chunk)
    }
    require(decoded == samplePayload, "filter round-trip")

    do {
        _ = try InputFilter<Data>(.compress, using: .zlib, bufferCapacity: 0) { _ in nil }
        fatalError("zero bufferCapacity must throw")
    } catch FilterError.invalidState {
    } catch {
        fatalError("unexpected zero-capacity error")
    }

    let second = try! OutputFilter(.compress, using: .zlib) { _ in }
    try! second.finalize()
    do {
        try second.finalize()
        fatalError("double finalize must throw")
    } catch FilterError.invalidState {
    } catch {
        fatalError("unexpected double-finalize error")
    }
}

func testStreamFinalize() {
    let srcStorage = Array(samplePayload)
    var dstStorage = [UInt8](repeating: 0, count: 256)
    let status: compression_status = srcStorage.withUnsafeBufferPointer { src in
        dstStorage.withUnsafeMutableBufferPointer { dst in
            var stream = compression_stream(
                dst_ptr: dst.baseAddress!,
                dst_size: dst.count,
                src_ptr: src.baseAddress!,
                src_size: src.count,
                state: nil
            )
            require(
                compression_stream_init(&stream, COMPRESSION_STREAM_ENCODE, COMPRESSION_ZLIB)
                    == COMPRESSION_STATUS_OK,
                "stream init"
            )
            require(stream.state != nil, "state")
            let process = compression_stream_process(
                &stream,
                Int32(bitPattern: COMPRESSION_STREAM_FINALIZE.rawValue)
            )
            require(process == COMPRESSION_STATUS_END, "stream process")
            let produced = dst.count - stream.dst_size
            require(produced > 0, "stream produced bytes")
            require(stream.src_size == 0, "src consumed")
            require(compression_stream_destroy(&stream) == COMPRESSION_STATUS_OK, "destroy")
            require(stream.state == nil, "state cleared")
            return process
        }
    }
    require(status == COMPRESSION_STATUS_END, "status")
}

func testScratchAndUnsupported() {
    require(compression_encode_scratch_buffer_size(COMPRESSION_ZLIB) == 0, "encode scratch")
    require(compression_decode_scratch_buffer_size(COMPRESSION_BROTLI) == 0, "decode scratch")
    var dst = [UInt8](repeating: 0, count: 32)
    let encoded = samplePayload.withUnsafeBytes { src in
        dst.withUnsafeMutableBufferPointer { out in
            compression_encode_buffer(
                out.baseAddress!,
                out.count,
                src.bindMemory(to: UInt8.self).baseAddress!,
                samplePayload.count,
                nil,
                COMPRESSION_LZFSE
            )
        }
    }
    require(encoded == 0, "lzfse fail-closed")
    let lzma = samplePayload.withUnsafeBytes { src in
        dst.withUnsafeMutableBufferPointer { out in
            compression_encode_buffer(
                out.baseAddress!,
                out.count,
                src.bindMemory(to: UInt8.self).baseAddress!,
                samplePayload.count,
                nil,
                COMPRESSION_LZMA
            )
        }
    }
    require(lzma == 0, "lzma fail-closed")
    let bitmap = samplePayload.withUnsafeBytes { src in
        dst.withUnsafeMutableBufferPointer { out in
            compression_encode_buffer(
                out.baseAddress!,
                out.count,
                src.bindMemory(to: UInt8.self).baseAddress!,
                samplePayload.count,
                nil,
                COMPRESSION_LZBITMAP
            )
        }
    }
    require(bitmap == 0, "lzbitmap fail-closed")
}
