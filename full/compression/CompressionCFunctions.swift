import Foundation

public func compression_encode_scratch_buffer_size(_ algorithm: compression_algorithm) -> Int {
    _ = algorithm
    return 0
}

public func compression_decode_scratch_buffer_size(_ algorithm: compression_algorithm) -> Int {
    _ = algorithm
    return 0
}

public func compression_encode_buffer(
    _ dst_buffer: UnsafeMutablePointer<UInt8>,
    _ dst_size: Int,
    _ src_buffer: UnsafePointer<UInt8>,
    _ src_size: Int,
    _ scratch_buffer: UnsafeMutableRawPointer?,
    _ algorithm: compression_algorithm
) -> Int {
    _ = scratch_buffer
    guard dst_size >= 0, src_size >= 0 else { return 0 }
    let input: Data
    if src_size == 0 {
        input = Data()
    } else {
        input = Data(bytes: src_buffer, count: src_size)
    }
    guard let encoded = CompressionCodec.encode(input, algorithm: algorithm) else {
        return 0
    }
    guard encoded.count <= dst_size, encoded.count > 0 || src_size == 0 else {
        return 0
    }
    encoded.copyBytes(to: dst_buffer, count: encoded.count)
    return encoded.count
}

public func compression_decode_buffer(
    _ dst_buffer: UnsafeMutablePointer<UInt8>,
    _ dst_size: Int,
    _ src_buffer: UnsafePointer<UInt8>,
    _ src_size: Int,
    _ scratch_buffer: UnsafeMutableRawPointer?,
    _ algorithm: compression_algorithm
) -> Int {
    _ = scratch_buffer
    guard dst_size >= 0, src_size >= 0 else { return 0 }
    let input: Data
    if src_size == 0 {
        input = Data()
    } else {
        input = Data(bytes: src_buffer, count: src_size)
    }
    guard let decoded = CompressionCodec.decode(input, algorithm: algorithm) else {
        return 0
    }
    guard decoded.count <= dst_size else { return 0 }
    decoded.copyBytes(to: dst_buffer, count: decoded.count)
    return decoded.count
}

final class CompressionStreamState {
    let operation: compression_stream_operation
    let algorithm: compression_algorithm
    var input = Data()
    var output = Data()
    var outputOffset = 0
    var finished = false

    init(operation: compression_stream_operation, algorithm: compression_algorithm) {
        self.operation = operation
        self.algorithm = algorithm
    }
}

public func compression_stream_init(
    _ stream: UnsafeMutablePointer<compression_stream>,
    _ operation: compression_stream_operation,
    _ algorithm: compression_algorithm
) -> compression_status {
    switch algorithm {
    case COMPRESSION_LZ4, COMPRESSION_LZ4_RAW, COMPRESSION_ZLIB,
         COMPRESSION_LZMA, COMPRESSION_LZFSE, COMPRESSION_LZBITMAP, COMPRESSION_BROTLI:
        break
    default:
        return COMPRESSION_STATUS_ERROR
    }
    switch operation {
    case COMPRESSION_STREAM_ENCODE, COMPRESSION_STREAM_DECODE:
        break
    default:
        return COMPRESSION_STATUS_ERROR
    }
    if let existing = stream.pointee.state {
        Unmanaged<CompressionStreamState>.fromOpaque(existing).release()
        stream.pointee.state = nil
    }
    let state = CompressionStreamState(operation: operation, algorithm: algorithm)
    stream.pointee.state = Unmanaged.passRetained(state).toOpaque()
    return COMPRESSION_STATUS_OK
}

public func compression_stream_process(
    _ stream: UnsafeMutablePointer<compression_stream>,
    _ flags: Int32
) -> compression_status {
    guard let opaque = stream.pointee.state else { return COMPRESSION_STATUS_ERROR }
    let state = Unmanaged<CompressionStreamState>.fromOpaque(opaque).takeUnretainedValue()
    if stream.pointee.src_size > 0 {
        let incoming = Data(bytes: stream.pointee.src_ptr, count: stream.pointee.src_size)
        guard state.input.count <= CompressionCodec.outputLimit - incoming.count else {
            return COMPRESSION_STATUS_ERROR
        }
        state.input.append(incoming)
        stream.pointee.src_ptr = stream.pointee.src_ptr.advanced(by: stream.pointee.src_size)
        stream.pointee.src_size = 0
    }
    let finalize = (UInt32(bitPattern: flags) & COMPRESSION_STREAM_FINALIZE.rawValue) != 0
    if state.output.isEmpty && !state.finished {
        if finalize {
            let transformed: Data?
            if state.operation == COMPRESSION_STREAM_ENCODE {
                transformed = CompressionCodec.encode(state.input, algorithm: state.algorithm)
            } else {
                transformed = CompressionCodec.decode(state.input, algorithm: state.algorithm)
            }
            guard let transformed else { return COMPRESSION_STATUS_ERROR }
            state.output = transformed
            state.finished = true
        } else {
            return COMPRESSION_STATUS_OK
        }
    }
    let remaining = state.output.count - state.outputOffset
    let n = min(remaining, max(stream.pointee.dst_size, 0))
    if n > 0 {
        state.output.copyBytes(
            to: stream.pointee.dst_ptr,
            from: state.outputOffset..<(state.outputOffset + n)
        )
        stream.pointee.dst_ptr = stream.pointee.dst_ptr.advanced(by: n)
        stream.pointee.dst_size -= n
        state.outputOffset += n
    }
    if state.finished && state.outputOffset == state.output.count {
        return COMPRESSION_STATUS_END
    }
    return COMPRESSION_STATUS_OK
}

public func compression_stream_destroy(
    _ stream: UnsafeMutablePointer<compression_stream>
) -> compression_status {
    guard let opaque = stream.pointee.state else { return COMPRESSION_STATUS_ERROR }
    Unmanaged<CompressionStreamState>.fromOpaque(opaque).release()
    stream.pointee.state = nil
    return COMPRESSION_STATUS_OK
}

func compressionTransform(_ data: Data, operation: FilterOperation, algorithm: Algorithm) throws -> Data {
    let transformed: Data?
    switch operation {
    case .compress:
        transformed = CompressionCodec.encode(data, algorithm: algorithm.rawValue)
    case .decompress:
        transformed = CompressionCodec.decode(data, algorithm: algorithm.rawValue)
    }
    guard let transformed else { throw FilterError.invalidData }
    return transformed
}
