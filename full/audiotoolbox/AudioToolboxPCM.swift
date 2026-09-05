#if os(Linux)
import Glibc
#endif
import Foundation

/// Isolated 40-byte C `AudioStreamBasicDescription` overlay. The public
/// `AudioStreamBasicDescription` name belongs to CoreAudioTypes and is not
/// redeclared here.
internal let atASBDSize = 40

internal let atFormatLinearPCM: UInt32 = 0x6C70_636D // 'lpcm'
internal let atFormatFlagIsFloat: UInt32 = 1
internal let atFormatFlagIsBigEndian: UInt32 = 2
internal let atFormatFlagIsSignedInteger: UInt32 = 4
internal let atFormatFlagIsPacked: UInt32 = 8
internal let atFormatFlagIsNonInterleaved: UInt32 = 32

internal struct ATASBD: Equatable {
    var mSampleRate: Float64
    var mFormatID: UInt32
    var mFormatFlags: UInt32
    var mBytesPerPacket: UInt32
    var mFramesPerPacket: UInt32
    var mBytesPerFrame: UInt32
    var mChannelsPerFrame: UInt32
    var mBitsPerChannel: UInt32
    var mReserved: UInt32

    init() {
        mSampleRate = 0
        mFormatID = 0
        mFormatFlags = 0
        mBytesPerPacket = 0
        mFramesPerPacket = 0
        mBytesPerFrame = 0
        mChannelsPerFrame = 0
        mBitsPerChannel = 0
        mReserved = 0
    }

    static func pcm(sampleRate: Float64, channels: UInt32, bits: UInt32, floating: Bool) -> ATASBD {
        var format = ATASBD()
        format.mSampleRate = sampleRate
        format.mFormatID = atFormatLinearPCM
        format.mFormatFlags = atFormatFlagIsPacked
        if floating {
            format.mFormatFlags |= atFormatFlagIsFloat
        } else if bits > 8 {
            format.mFormatFlags |= atFormatFlagIsSignedInteger
        }
        format.mBitsPerChannel = bits
        format.mChannelsPerFrame = channels
        format.mFramesPerPacket = 1
        format.mBytesPerFrame = (bits / 8) * channels
        format.mBytesPerPacket = format.mBytesPerFrame
        return format
    }

    var isPCM: Bool { mFormatID == atFormatLinearPCM }
    var isFloat: Bool { mFormatFlags & atFormatFlagIsFloat != 0 }
    var isBigEndian: Bool { mFormatFlags & atFormatFlagIsBigEndian != 0 }
    var isNonInterleaved: Bool { mFormatFlags & atFormatFlagIsNonInterleaved != 0 }
    var bytesPerSample: Int { Int(mBitsPerChannel / 8) }
    var frameCountChannels: Int { Int(max(mChannelsPerFrame, 1)) }

    func validatePCM() -> Int32 {
        if mFormatID != 0 && mFormatID != atFormatLinearPCM {
            return kAudioConverterErr_FormatNotSupported
        }
        if mSampleRate <= 0 || mChannelsPerFrame == 0 || mBitsPerChannel == 0 {
            return kAudioQueueErr_InvalidParameter
        }
        if mBitsPerChannel % 8 != 0 || mBitsPerChannel > 64 {
            return kAudioQueueErr_InvalidParameter
        }
        if mFramesPerPacket != 0 && mFramesPerPacket != 1 {
            return kAudioConverterErr_FormatNotSupported
        }
        return 0
    }
}

internal func atLoadASBD(_ pointer: UnsafeRawPointer?) -> ATASBD? {
    guard let pointer else { return nil }
    var format = ATASBD()
    format.mSampleRate = pointer.loadUnaligned(fromByteOffset: 0, as: Float64.self)
    format.mFormatID = pointer.loadUnaligned(fromByteOffset: 8, as: UInt32.self)
    format.mFormatFlags = pointer.loadUnaligned(fromByteOffset: 12, as: UInt32.self)
    format.mBytesPerPacket = pointer.loadUnaligned(fromByteOffset: 16, as: UInt32.self)
    format.mFramesPerPacket = pointer.loadUnaligned(fromByteOffset: 20, as: UInt32.self)
    format.mBytesPerFrame = pointer.loadUnaligned(fromByteOffset: 24, as: UInt32.self)
    format.mChannelsPerFrame = pointer.loadUnaligned(fromByteOffset: 28, as: UInt32.self)
    format.mBitsPerChannel = pointer.loadUnaligned(fromByteOffset: 32, as: UInt32.self)
    format.mReserved = pointer.loadUnaligned(fromByteOffset: 36, as: UInt32.self)
    return format
}

internal func atStoreASBD(_ format: ATASBD, to pointer: UnsafeMutableRawPointer) {
    pointer.storeBytes(of: format.mSampleRate, toByteOffset: 0, as: Float64.self)
    pointer.storeBytes(of: format.mFormatID, toByteOffset: 8, as: UInt32.self)
    pointer.storeBytes(of: format.mFormatFlags, toByteOffset: 12, as: UInt32.self)
    pointer.storeBytes(of: format.mBytesPerPacket, toByteOffset: 16, as: UInt32.self)
    pointer.storeBytes(of: format.mFramesPerPacket, toByteOffset: 20, as: UInt32.self)
    pointer.storeBytes(of: format.mBytesPerFrame, toByteOffset: 24, as: UInt32.self)
    pointer.storeBytes(of: format.mChannelsPerFrame, toByteOffset: 28, as: UInt32.self)
    pointer.storeBytes(of: format.mBitsPerChannel, toByteOffset: 32, as: UInt32.self)
    pointer.storeBytes(of: format.mReserved, toByteOffset: 36, as: UInt32.self)
}

internal func atFillPCMASBD(_ format: inout ATASBD) {
    if format.mFramesPerPacket == 0 {
        format.mFramesPerPacket = 1
    }
    let width = format.mBitsPerChannel / 8
    if format.mBytesPerFrame == 0 {
        if format.isNonInterleaved {
            format.mBytesPerFrame = width
        } else {
            format.mBytesPerFrame = width * format.mChannelsPerFrame
        }
    }
    if format.mBytesPerPacket == 0 {
        format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket
    }
}

internal struct ATAudioBufferView {
    var numberChannels: UInt32
    var dataByteSize: UInt32
    var data: UnsafeMutableRawPointer?
}

internal func atAudioBufferListHeaderSize() -> Int { 8 }

internal func atLoadBufferList(
    _ pointer: UnsafeRawPointer?,
    maxBuffers: Int = 16
) -> (count: Int, buffers: [ATAudioBufferView])? {
    guard let pointer else { return nil }
    let count = Int(pointer.loadUnaligned(fromByteOffset: 0, as: UInt32.self))
    if count < 0 || count > maxBuffers {
        return nil
    }
    var buffers: [ATAudioBufferView] = []
    buffers.reserveCapacity(count)
    var offset = atAudioBufferListHeaderSize()
    for _ in 0..<count {
        let channels = pointer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
        let byteSize = pointer.loadUnaligned(fromByteOffset: offset + 4, as: UInt32.self)
        let stored = pointer.loadUnaligned(fromByteOffset: offset + 8, as: UInt.self)
        let raw = UnsafeMutableRawPointer(bitPattern: stored)
        buffers.append(ATAudioBufferView(numberChannels: channels, dataByteSize: byteSize, data: raw))
        offset += 16
    }
    return (count, buffers)
}

internal func atStoreBufferListHeader(_ pointer: UnsafeMutableRawPointer, count: UInt32) {
    pointer.storeBytes(of: count, toByteOffset: 0, as: UInt32.self)
}

internal func atSampleToFloat(bytes: UnsafeRawPointer, bits: Int, floating: Bool, bigEndian: Bool) -> Float {
    if floating {
        if bits == 32 {
            var value = bytes.loadUnaligned(as: UInt32.self)
            if bigEndian {
                value = value.byteSwapped
            }
            return Float(bitPattern: value)
        }
        if bits == 64 {
            var value = bytes.loadUnaligned(as: UInt64.self)
            if bigEndian {
                value = value.byteSwapped
            }
            return Float(Double(bitPattern: value))
        }
    }
    switch bits {
    case 8:
        let raw = bytes.loadUnaligned(as: UInt8.self)
        return (Float(Int(raw) - 128) / 128.0)
    case 16:
        var value = bytes.loadUnaligned(as: UInt16.self)
        if bigEndian {
            value = value.byteSwapped
        }
        return Float(Int16(bitPattern: value)) / 32768.0
    case 24:
        let b0 = bytes.loadUnaligned(fromByteOffset: 0, as: UInt8.self)
        let b1 = bytes.loadUnaligned(fromByteOffset: 1, as: UInt8.self)
        let b2 = bytes.loadUnaligned(fromByteOffset: 2, as: UInt8.self)
        let packed: Int32
        if bigEndian {
            packed = (Int32(b0) << 16) | (Int32(b1) << 8) | Int32(b2)
        } else {
            packed = (Int32(b2) << 16) | (Int32(b1) << 8) | Int32(b0)
        }
        let signed = (packed << 8) >> 8
        return Float(signed) / 8_388_608.0
    case 32:
        var value = bytes.loadUnaligned(as: UInt32.self)
        if bigEndian {
            value = value.byteSwapped
        }
        return Float(Int32(bitPattern: value)) / Float(Int32.max)
    default:
        return 0
    }
}

internal func atFloatToSample(_ sample: Float, dest: UnsafeMutableRawPointer, bits: Int, floating: Bool, bigEndian: Bool) {
    let clipped = max(-1.0, min(1.0, sample))
    if floating {
        if bits == 32 {
            var bitsPattern = clipped.bitPattern
            if bigEndian {
                bitsPattern = bitsPattern.byteSwapped
            }
            dest.storeBytes(of: bitsPattern, as: UInt32.self)
            return
        }
        if bits == 64 {
            var bitsPattern = Double(clipped).bitPattern
            if bigEndian {
                bitsPattern = bitsPattern.byteSwapped
            }
            dest.storeBytes(of: bitsPattern, as: UInt64.self)
            return
        }
    }
    switch bits {
    case 8:
        let scaled = Int(clipped * 127.0) + 128
        dest.storeBytes(of: UInt8(clamping: scaled), as: UInt8.self)
    case 16:
        var value = UInt16(bitPattern: Int16(clamping: Int(clipped * 32767.0)))
        if bigEndian {
            value = value.byteSwapped
        }
        dest.storeBytes(of: value, as: UInt16.self)
    case 24:
        let scaled = Int32(clipped * 8_388_607.0)
        if bigEndian {
            dest.storeBytes(of: UInt8((scaled >> 16) & 0xFF), toByteOffset: 0, as: UInt8.self)
            dest.storeBytes(of: UInt8((scaled >> 8) & 0xFF), toByteOffset: 1, as: UInt8.self)
            dest.storeBytes(of: UInt8(scaled & 0xFF), toByteOffset: 2, as: UInt8.self)
        } else {
            dest.storeBytes(of: UInt8(scaled & 0xFF), toByteOffset: 0, as: UInt8.self)
            dest.storeBytes(of: UInt8((scaled >> 8) & 0xFF), toByteOffset: 1, as: UInt8.self)
            dest.storeBytes(of: UInt8((scaled >> 16) & 0xFF), toByteOffset: 2, as: UInt8.self)
        }
    case 32:
        var value = UInt32(bitPattern: Int32(clipped * Float(Int32.max - 1)))
        if bigEndian {
            value = value.byteSwapped
        }
        dest.storeBytes(of: value, as: UInt32.self)
    default:
        break
    }
}

internal func atConvertPCM(
    source: ATASBD,
    dest: ATASBD,
    input: UnsafeRawPointer,
    inputByteCount: Int,
    output: UnsafeMutableRawPointer,
    outputByteCapacity: Int,
    channelMap: [Int32]?
) -> (status: Int32, outputBytes: Int) {
    if !source.isPCM || !dest.isPCM {
        return (kAudioConverterErr_FormatNotSupported, 0)
    }
    if source.mSampleRate != dest.mSampleRate {
        return (kAudioConverterErr_FormatNotSupported, 0)
    }
    let srcWidth = source.bytesPerSample
    let dstWidth = dest.bytesPerSample
    if srcWidth <= 0 || dstWidth <= 0 {
        return (kAudioConverterErr_InvalidInputSize, 0)
    }
    let srcChannels = source.frameCountChannels
    let dstChannels = dest.frameCountChannels
    let srcFrameBytes = source.isNonInterleaved ? srcWidth : srcWidth * srcChannels
    let frames = inputByteCount / max(srcFrameBytes, 1)
    if frames <= 0 {
        return (0, 0)
    }
    let dstFrameBytes = dest.isNonInterleaved ? dstWidth : dstWidth * dstChannels
    let needed = frames * dstFrameBytes
    if needed > outputByteCapacity {
        return (kAudioConverterErr_InvalidOutputSize, 0)
    }
    var map: [Int]
    if let channelMap, channelMap.count >= dstChannels {
        map = channelMap.prefix(dstChannels).map { Int($0) }
    } else {
        map = (0..<dstChannels).map { min($0, srcChannels - 1) }
    }
    for frame in 0..<frames {
        for destChannel in 0..<dstChannels {
            let sourceChannel = map[destChannel]
            let sample: Float
            if sourceChannel < 0 || sourceChannel >= srcChannels {
                sample = 0
            } else if source.isNonInterleaved {
                let plane = input.advanced(by: sourceChannel * frames * srcWidth + frame * srcWidth)
                sample = atSampleToFloat(
                    bytes: plane,
                    bits: Int(source.mBitsPerChannel),
                    floating: source.isFloat,
                    bigEndian: source.isBigEndian
                )
            } else {
                let offset = frame * srcWidth * srcChannels + sourceChannel * srcWidth
                sample = atSampleToFloat(
                    bytes: input.advanced(by: offset),
                    bits: Int(source.mBitsPerChannel),
                    floating: source.isFloat,
                    bigEndian: source.isBigEndian
                )
            }
            if dest.isNonInterleaved {
                let plane = output.advanced(by: destChannel * frames * dstWidth + frame * dstWidth)
                atFloatToSample(
                    sample,
                    dest: plane,
                    bits: Int(dest.mBitsPerChannel),
                    floating: dest.isFloat,
                    bigEndian: dest.isBigEndian
                )
            } else {
                let offset = frame * dstWidth * dstChannels + destChannel * dstWidth
                atFloatToSample(
                    sample,
                    dest: output.advanced(by: offset),
                    bits: Int(dest.mBitsPerChannel),
                    floating: dest.isFloat,
                    bigEndian: dest.isBigEndian
                )
            }
        }
    }
    return (0, needed)
}

internal func atMixPCM(
    inputs: [(format: ATASBD, bytes: UnsafeRawPointer, byteCount: Int)],
    dest: ATASBD,
    output: UnsafeMutableRawPointer,
    outputByteCapacity: Int
) -> Int32 {
    if !dest.isPCM {
        return kAudioUnitErr_FormatNotSupported
    }
    let dstWidth = dest.bytesPerSample
    let dstChannels = dest.frameCountChannels
    let dstFrameBytes = dest.isNonInterleaved ? dstWidth : dstWidth * dstChannels
    guard dstFrameBytes > 0 else { return kAudioUnitErr_InvalidParameter }
    let frames = outputByteCapacity / dstFrameBytes
    if frames <= 0 {
        return 0
    }
    memset(output, 0, frames * dstFrameBytes)
    for input in inputs {
        var converted = [UInt8](repeating: 0, count: frames * dstFrameBytes)
        let result = converted.withUnsafeMutableBytes { destBuffer in
            atConvertPCM(
                source: input.format,
                dest: dest,
                input: input.bytes,
                inputByteCount: input.byteCount,
                output: destBuffer.baseAddress!,
                outputByteCapacity: destBuffer.count,
                channelMap: nil
            )
        }
        if result.status != 0 {
            continue
        }
        let mixFrames = min(frames, result.outputBytes / dstFrameBytes)
        for frame in 0..<mixFrames {
            for channel in 0..<dstChannels {
                let offset: Int
                if dest.isNonInterleaved {
                    offset = channel * frames * dstWidth + frame * dstWidth
                } else {
                    offset = frame * dstWidth * dstChannels + channel * dstWidth
                }
                let existing = atSampleToFloat(
                    bytes: output.advanced(by: offset),
                    bits: Int(dest.mBitsPerChannel),
                    floating: dest.isFloat,
                    bigEndian: dest.isBigEndian
                )
                let incoming = atSampleToFloat(
                    bytes: converted.withUnsafeBytes { $0.baseAddress!.advanced(by: offset) },
                    bits: Int(dest.mBitsPerChannel),
                    floating: dest.isFloat,
                    bigEndian: dest.isBigEndian
                )
                atFloatToSample(
                    existing + incoming,
                    dest: output.advanced(by: offset),
                    bits: Int(dest.mBitsPerChannel),
                    floating: dest.isFloat,
                    bigEndian: dest.isBigEndian
                )
            }
        }
    }
    return 0
}

internal func atU32BE(_ value: UInt32) -> [UInt8] {
    [
        UInt8((value >> 24) & 0xFF),
        UInt8((value >> 16) & 0xFF),
        UInt8((value >> 8) & 0xFF),
        UInt8(value & 0xFF),
    ]
}

internal func atU16LE(_ value: UInt16) -> [UInt8] {
    [UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF)]
}

internal func atU16BE(_ value: UInt16) -> [UInt8] {
    [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
}

internal func atU32LE(_ value: UInt32) -> [UInt8] {
    [
        UInt8(value & 0xFF),
        UInt8((value >> 8) & 0xFF),
        UInt8((value >> 16) & 0xFF),
        UInt8((value >> 24) & 0xFF),
    ]
}

internal func atReadU32BE(_ data: Data, _ offset: Int) -> UInt32? {
    guard offset + 4 <= data.count else { return nil }
    return (UInt32(data[offset]) << 24)
        | (UInt32(data[offset + 1]) << 16)
        | (UInt32(data[offset + 2]) << 8)
        | UInt32(data[offset + 3])
}

internal func atReadU16LE(_ data: Data, _ offset: Int) -> UInt16? {
    guard offset + 2 <= data.count else { return nil }
    return UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
}

internal func atReadU16BE(_ data: Data, _ offset: Int) -> UInt16? {
    guard offset + 2 <= data.count else { return nil }
    return (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
}

internal func atReadU32LE(_ data: Data, _ offset: Int) -> UInt32? {
    guard offset + 4 <= data.count else { return nil }
    return UInt32(data[offset])
        | (UInt32(data[offset + 1]) << 8)
        | (UInt32(data[offset + 2]) << 16)
        | (UInt32(data[offset + 3]) << 24)
}

internal func atReadF64BE(_ data: Data, _ offset: Int) -> Float64? {
    guard offset + 8 <= data.count else { return nil }
    var bits: UInt64 = 0
    for index in 0..<8 {
        bits = (bits << 8) | UInt64(data[offset + index])
    }
    return Float64(bitPattern: bits)
}
