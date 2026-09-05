import Foundation

enum AVAudioContainerKind {
    case wav
    case caf
    case aiff
}

struct AVAudioContainerPCM {
    var format: AVAudioFormat
    var interleaved: Data
    var frames: AVAudioFramePosition
}

enum AVAudioContainerError: Error {
    case unsupported
    case truncated
}

func avfaudioContainerKind(url: URL, settings: [String: Any]) -> AVAudioContainerKind {
    if let hinted = settings[AVAudioFileTypeKey] as? String {
        let lowered = hinted.lowercased()
        if lowered.contains("caf") { return .caf }
        if lowered.contains("aif") { return .aiff }
        if lowered.contains("wav") || lowered.contains("wave") { return .wav }
    }
    switch url.pathExtension.lowercased() {
    case "caf": return .caf
    case "aif", "aiff", "aifc": return .aiff
    default: return .wav
    }
}

func avfaudioReadU16LE(_ data: Data, _ offset: Int) -> UInt16 {
    UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
}

func avfaudioReadU16BE(_ data: Data, _ offset: Int) -> UInt16 {
    (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
}

func avfaudioReadU32LE(_ data: Data, _ offset: Int) -> UInt32 {
    UInt32(data[offset])
        | (UInt32(data[offset + 1]) << 8)
        | (UInt32(data[offset + 2]) << 16)
        | (UInt32(data[offset + 3]) << 24)
}

func avfaudioReadU32BE(_ data: Data, _ offset: Int) -> UInt32 {
    (UInt32(data[offset]) << 24)
        | (UInt32(data[offset + 1]) << 16)
        | (UInt32(data[offset + 2]) << 8)
        | UInt32(data[offset + 3])
}

func avfaudioReadI64BE(_ data: Data, _ offset: Int) -> Int64 {
    var value: UInt64 = 0
    for index in 0..<8 {
        value = (value << 8) | UInt64(data[offset + index])
    }
    return Int64(bitPattern: value)
}

func avfaudioReadF64BE(_ data: Data, _ offset: Int) -> Double {
    var bits: UInt64 = 0
    for index in 0..<8 {
        bits = (bits << 8) | UInt64(data[offset + index])
    }
    return Double(bitPattern: bits)
}

func avfaudioReadIEEE80(_ data: Data, _ offset: Int) -> Double {
    let exponent = avfaudioReadU16BE(data, offset)
    var mantissa: UInt64 = 0
    for index in 0..<8 {
        mantissa = (mantissa << 8) | UInt64(data[offset + 2 + index])
    }
    if exponent == 0 && mantissa == 0 { return 0 }
    let sign = (exponent & 0x8000) != 0
    let unbiased = Int(exponent & 0x7fff) - 16383
    let value = Double(mantissa) * pow(2.0, Double(unbiased - 63))
    return sign ? -value : value
}

func avfaudioWriteIEEE80(_ value: Double) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: 10)
    if value == 0 || !value.isFinite { return bytes }
    let bits = value.bitPattern
    let sign = bits >> 63
    let exp64 = Int((bits >> 52) & 0x7ff)
    let frac = bits & 0x000f_ffff_ffff_ffff
    if exp64 == 0 && frac == 0 { return bytes }
    let storedExp = UInt16((sign << 15) | UInt64(exp64 - 1023 + 16383))
    bytes[0] = UInt8(storedExp >> 8)
    bytes[1] = UInt8(storedExp & 0xff)
    let mantissa = (frac << 11) | (UInt64(1) << 63)
    for index in 0..<8 {
        bytes[2 + index] = UInt8((mantissa >> (8 * (7 - index))) & 0xff)
    }
    return bytes
}

func avfaudioAppendU16LE(_ data: inout Data, _ value: UInt16) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
}

func avfaudioAppendU32LE(_ data: inout Data, _ value: UInt32) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
}

func avfaudioAppendU16BE(_ data: inout Data, _ value: UInt16) {
    var big = value.bigEndian
    withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
}

func avfaudioAppendU32BE(_ data: inout Data, _ value: UInt32) {
    var big = value.bigEndian
    withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
}

func avfaudioAppendI64BE(_ data: inout Data, _ value: Int64) {
    var big = value.bigEndian
    withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
}

func avfaudioAppendF64BE(_ data: inout Data, _ value: Double) {
    var bits = value.bitPattern.bigEndian
    withUnsafeBytes(of: &bits) { data.append(contentsOf: $0) }
}

func avfaudioASCII(_ data: Data, _ offset: Int, _ count: Int = 4) -> String {
    String(decoding: data[offset..<(offset + count)], as: UTF8.self)
}

func avfaudioFormatFromPCM(
    sampleRate: Double,
    channels: AVAudioChannelCount,
    bits: Int,
    isFloat: Bool,
    interleaved: Bool
) -> AVAudioFormat? {
    let common: AVAudioCommonFormat
    if isFloat {
        common = bits >= 64 ? .pcmFormatFloat64 : .pcmFormatFloat32
    } else if bits <= 16 {
        common = .pcmFormatInt16
    } else {
        common = .pcmFormatInt32
    }
    return AVAudioFormat(
        commonFormat: common,
        sampleRate: sampleRate,
        channels: channels,
        interleaved: interleaved
    )
}

func avfaudioParseContainer(_ data: Data) throws -> AVAudioContainerPCM {
    guard data.count >= 12 else { throw AVAudioContainerError.truncated }
    let header = avfaudioASCII(data, 0)
    if header == "RIFF" {
        return try avfaudioParseWAVE(data)
    }
    if header == "caff" {
        return try avfaudioParseCAF(data)
    }
    if header == "FORM" {
        return try avfaudioParseAIFF(data)
    }
    throw AVAudioContainerError.unsupported
}

func avfaudioParseWAVE(_ data: Data) throws -> AVAudioContainerPCM {
    guard data.count >= 12, avfaudioASCII(data, 8) == "WAVE" else {
        throw AVAudioContainerError.unsupported
    }
    var offset = 12
    var audioFormat: UInt16?
    var channels: UInt16?
    var sampleRate: UInt32?
    var bits: UInt16?
    var payload: Data?
    while offset + 8 <= data.count {
        let chunkID = avfaudioASCII(data, offset)
        let chunkSize = Int(avfaudioReadU32LE(data, offset + 4))
        let body = offset + 8
        guard chunkSize >= 0, body <= data.count else { throw AVAudioContainerError.truncated }
        let next = body + chunkSize + (chunkSize & 1)
        if chunkID == "fmt " {
            guard chunkSize >= 16, body + 16 <= data.count else { throw AVAudioContainerError.truncated }
            audioFormat = avfaudioReadU16LE(data, body)
            channels = avfaudioReadU16LE(data, body + 2)
            sampleRate = avfaudioReadU32LE(data, body + 4)
            bits = avfaudioReadU16LE(data, body + 14)
        } else if chunkID == "data" {
            guard body + chunkSize <= data.count else { throw AVAudioContainerError.truncated }
            payload = data.subdata(in: body..<(body + chunkSize))
        }
        guard next > offset else { throw AVAudioContainerError.truncated }
        offset = next
    }
    guard
        let formatTag = audioFormat,
        formatTag == 1 || formatTag == 3,
        let channelCount = channels, channelCount > 0,
        let rate = sampleRate, rate > 0,
        let bitDepth = bits, bitDepth > 0,
        let bytes = payload
    else {
        throw AVAudioContainerError.unsupported
    }
    let isFloat = formatTag == 3
    guard
        let format = avfaudioFormatFromPCM(
            sampleRate: Double(rate),
            channels: AVAudioChannelCount(channelCount),
            bits: Int(bitDepth),
            isFloat: isFloat,
            interleaved: true
        )
    else {
        throw AVAudioContainerError.unsupported
    }
    let frameSize = max(format.bytesPerSample * Int(channelCount), 1)
    guard bytes.count % frameSize == 0 else { throw AVAudioContainerError.truncated }
    return AVAudioContainerPCM(
        format: format,
        interleaved: bytes,
        frames: AVAudioFramePosition(bytes.count / frameSize)
    )
}

func avfaudioParseCAF(_ data: Data) throws -> AVAudioContainerPCM {
    guard data.count >= 8, avfaudioASCII(data, 0) == "caff" else {
        throw AVAudioContainerError.unsupported
    }
    var offset = 8
    var sampleRate: Double?
    var formatID: UInt32?
    var formatFlags: UInt32?
    var bytesPerPacket: UInt32?
    var framesPerPacket: UInt32?
    var channels: UInt32?
    var bits: UInt32?
    var payload: Data?
    while offset + 12 <= data.count {
        let chunkType = avfaudioASCII(data, offset)
        let chunkSize = Int(avfaudioReadI64BE(data, offset + 4))
        let body = offset + 12
        guard chunkSize >= 0, body + chunkSize <= data.count else { throw AVAudioContainerError.truncated }
        if chunkType == "desc" {
            guard chunkSize >= 36 else { throw AVAudioContainerError.truncated }
            sampleRate = avfaudioReadF64BE(data, body)
            formatID = avfaudioReadU32BE(data, body + 8)
            formatFlags = avfaudioReadU32BE(data, body + 12)
            bytesPerPacket = avfaudioReadU32BE(data, body + 16)
            framesPerPacket = avfaudioReadU32BE(data, body + 20)
            channels = avfaudioReadU32BE(data, body + 28)
            bits = avfaudioReadU32BE(data, body + 32)
        } else if chunkType == "data" {
            guard chunkSize >= 4 else { throw AVAudioContainerError.truncated }
            payload = data.subdata(in: (body + 4)..<(body + chunkSize))
        }
        offset = body + chunkSize
    }
    guard
        formatID == avfaudioLinearPCMFormatID,
        let rate = sampleRate, rate > 0,
        let channelCount = channels, channelCount > 0,
        let bitDepth = bits, bitDepth > 0,
        let bytes = payload,
        framesPerPacket == 1,
        bytesPerPacket != nil
    else {
        throw AVAudioContainerError.unsupported
    }
    let flags = formatFlags ?? 0
    let isFloat = (flags & 1) != 0
    let littleEndian = (flags & 2) != 0
    guard
        let format = avfaudioFormatFromPCM(
            sampleRate: rate,
            channels: channelCount,
            bits: Int(bitDepth),
            isFloat: isFloat,
            interleaved: true
        )
    else {
        throw AVAudioContainerError.unsupported
    }
    let frameSize = max(format.bytesPerSample * Int(channelCount), 1)
    guard bytes.count % frameSize == 0 else { throw AVAudioContainerError.truncated }
    let interleaved: Data
    if littleEndian {
        interleaved = bytes
    } else {
        interleaved = avfaudioSwapPCMEndian(bytes, sampleBytes: format.bytesPerSample)
    }
    return AVAudioContainerPCM(
        format: format,
        interleaved: interleaved,
        frames: AVAudioFramePosition(bytes.count / frameSize)
    )
}

func avfaudioParseAIFF(_ data: Data) throws -> AVAudioContainerPCM {
    guard data.count >= 12, avfaudioASCII(data, 8) == "AIFF" || avfaudioASCII(data, 8) == "AIFC" else {
        throw AVAudioContainerError.unsupported
    }
    if avfaudioASCII(data, 8) == "AIFC" {
        throw AVAudioContainerError.unsupported
    }
    var offset = 12
    var channels: UInt16?
    var frames: UInt32?
    var bits: UInt16?
    var sampleRate: Double?
    var payload: Data?
    while offset + 8 <= data.count {
        let chunkID = avfaudioASCII(data, offset)
        let chunkSize = Int(avfaudioReadU32BE(data, offset + 4))
        let body = offset + 8
        guard chunkSize >= 0, body <= data.count else { throw AVAudioContainerError.truncated }
        let next = body + chunkSize + (chunkSize & 1)
        if chunkID == "COMM" {
            guard chunkSize >= 18, body + 18 <= data.count else { throw AVAudioContainerError.truncated }
            channels = avfaudioReadU16BE(data, body)
            frames = avfaudioReadU32BE(data, body + 2)
            bits = avfaudioReadU16BE(data, body + 6)
            sampleRate = avfaudioReadIEEE80(data, body + 8)
        } else if chunkID == "SSND" {
            guard chunkSize >= 8, body + chunkSize <= data.count else { throw AVAudioContainerError.truncated }
            let dataOffset = Int(avfaudioReadU32BE(data, body))
            let start = body + 8 + dataOffset
            guard start <= body + chunkSize else { throw AVAudioContainerError.truncated }
            payload = data.subdata(in: start..<(body + chunkSize))
        }
        guard next > offset else { throw AVAudioContainerError.truncated }
        offset = next
    }
    guard
        let channelCount = channels, channelCount > 0,
        let rate = sampleRate, rate > 0,
        let bitDepth = bits, bitDepth > 0,
        let bytes = payload
    else {
        throw AVAudioContainerError.unsupported
    }
    guard
        let format = avfaudioFormatFromPCM(
            sampleRate: rate,
            channels: AVAudioChannelCount(channelCount),
            bits: Int(bitDepth),
            isFloat: false,
            interleaved: true
        )
    else {
        throw AVAudioContainerError.unsupported
    }
    let frameSize = max(format.bytesPerSample * Int(channelCount), 1)
    let usable = (bytes.count / frameSize) * frameSize
    let native = avfaudioSwapPCMEndian(Data(bytes.prefix(usable)), sampleBytes: format.bytesPerSample)
    let frameCount = frames.map { min(AVAudioFramePosition($0), AVAudioFramePosition(usable / frameSize)) }
        ?? AVAudioFramePosition(usable / frameSize)
    return AVAudioContainerPCM(
        format: format,
        interleaved: native,
        frames: frameCount
    )
}

func avfaudioSwapPCMEndian(_ data: Data, sampleBytes: Int) -> Data {
    guard sampleBytes == 2 || sampleBytes == 4 || sampleBytes == 8 else { return Data(data) }
    var swapped = Data(data)
    swapped.withUnsafeMutableBytes { raw in
        var index = 0
        while index + sampleBytes <= raw.count {
            for pair in 0..<(sampleBytes / 2) {
                let a = index + pair
                let b = index + sampleBytes - 1 - pair
                let tmp = raw[a]
                raw[a] = raw[b]
                raw[b] = tmp
            }
            index += sampleBytes
        }
    }
    return swapped
}

func avfaudioEncodeWAVE(_ pcm: AVAudioContainerPCM) -> Data {
    let channels = UInt16(pcm.format.channelCount)
    let bits = UInt16(pcm.format.bitDepth)
    let isFloat = pcm.format.commonFormat == .pcmFormatFloat32
        || pcm.format.commonFormat == .pcmFormatFloat64
    let blockAlign = channels * (bits / 8)
    let byteRate = UInt32(pcm.format.sampleRate) * UInt32(blockAlign)
    let dataBytes = UInt32(pcm.interleaved.count)
    var data = Data()
    data.append(contentsOf: "RIFF".utf8)
    avfaudioAppendU32LE(&data, 36 + dataBytes)
    data.append(contentsOf: "WAVE".utf8)
    data.append(contentsOf: "fmt ".utf8)
    avfaudioAppendU32LE(&data, 16)
    avfaudioAppendU16LE(&data, isFloat ? 3 : 1)
    avfaudioAppendU16LE(&data, channels)
    avfaudioAppendU32LE(&data, UInt32(pcm.format.sampleRate))
    avfaudioAppendU32LE(&data, byteRate)
    avfaudioAppendU16LE(&data, blockAlign)
    avfaudioAppendU16LE(&data, bits)
    data.append(contentsOf: "data".utf8)
    avfaudioAppendU32LE(&data, dataBytes)
    data.append(pcm.interleaved)
    return data
}

func avfaudioEncodeCAF(_ pcm: AVAudioContainerPCM) -> Data {
    let channels = pcm.format.channelCount
    let bits = UInt32(pcm.format.bitDepth)
    let bytesPerFrame = UInt32(pcm.format.bytesPerSample) * channels
    var flags: UInt32 = 2
    if pcm.format.commonFormat == .pcmFormatFloat32 || pcm.format.commonFormat == .pcmFormatFloat64 {
        flags |= 1
    }
    var data = Data()
    data.append(contentsOf: "caff".utf8)
    avfaudioAppendU16BE(&data, 1)
    avfaudioAppendU16BE(&data, 0)
    data.append(contentsOf: "desc".utf8)
    avfaudioAppendI64BE(&data, 36)
    avfaudioAppendF64BE(&data, pcm.format.sampleRate)
    avfaudioAppendU32BE(&data, avfaudioLinearPCMFormatID)
    avfaudioAppendU32BE(&data, flags)
    avfaudioAppendU32BE(&data, bytesPerFrame)
    avfaudioAppendU32BE(&data, 1)
    avfaudioAppendU32BE(&data, bytesPerFrame)
    avfaudioAppendU32BE(&data, channels)
    avfaudioAppendU32BE(&data, bits)
    data.append(contentsOf: "data".utf8)
    avfaudioAppendI64BE(&data, Int64(4 + pcm.interleaved.count))
    avfaudioAppendU32BE(&data, 0)
    data.append(pcm.interleaved)
    return data
}

func avfaudioEncodeContainer(_ pcm: AVAudioContainerPCM, kind: AVAudioContainerKind) throws -> Data {
    switch kind {
    case .wav: return avfaudioEncodeWAVE(pcm)
    case .caf: return avfaudioEncodeCAF(pcm)
    case .aiff: throw AVAudioContainerError.unsupported
    }
}

func avfaudioPCMBufferToInterleaved(_ buffer: AVAudioPCMBuffer) -> Data {
    let channels = Int(buffer.format.channelCount)
    let frames = Int(buffer.frameLength)
    let sampleBytes = buffer.format.bytesPerSample
    var data = Data(count: frames * channels * max(sampleBytes, 1))
    data.withUnsafeMutableBytes { raw in
        guard let base = raw.baseAddress else { return }
        for frame in 0..<frames {
            for channel in 0..<channels {
                let dest = base.advanced(by: (frame * channels + channel) * sampleBytes)
                switch buffer.format.commonFormat {
                case .pcmFormatFloat32:
                    dest.assumingMemoryBound(to: Float.self).pointee =
                        Float(avfaudioReadPCMSample(buffer, channel: channel, frame: frame))
                case .pcmFormatInt16:
                    dest.assumingMemoryBound(to: Int16.self).pointee = Int16(
                        clamping: Int(
                            (avfaudioClampUnit(
                                avfaudioReadPCMSample(buffer, channel: channel, frame: frame)
                            ) * 32767.0).rounded()
                        )
                    )
                case .pcmFormatInt32:
                    dest.assumingMemoryBound(to: Int32.self).pointee = Int32(
                        clamping: Int(
                            (avfaudioClampUnit(
                                avfaudioReadPCMSample(buffer, channel: channel, frame: frame)
                            ) * 2_147_483_647.0).rounded()
                        )
                    )
                default:
                    break
                }
            }
        }
    }
    return data
}

func avfaudioFillPCMBuffer(
    _ buffer: AVAudioPCMBuffer,
    fromInterleaved data: Data,
    format: AVAudioFormat,
    startFrame: Int,
    frameCount: Int
) -> AVAudioFrameCount {
    let channels = Int(format.channelCount)
    let sampleBytes = max(format.bytesPerSample, 1)
    let frameSize = sampleBytes * max(channels, 1)
    let available = max(data.count / frameSize - startFrame, 0)
    let frames = min(frameCount, available, Int(buffer.frameCapacity))
    buffer.frameLength = AVAudioFrameCount(frames)
    data.withUnsafeBytes { raw in
        guard let base = raw.baseAddress else { return }
        for frame in 0..<frames {
            for channel in 0..<channels {
                let src = base.advanced(by: ((startFrame + frame) * channels + channel) * sampleBytes)
                let value: Double
                switch format.commonFormat {
                case .pcmFormatFloat32:
                    value = Double(src.assumingMemoryBound(to: Float.self).pointee)
                case .pcmFormatInt16:
                    value = Double(src.assumingMemoryBound(to: Int16.self).pointee) / 32768.0
                case .pcmFormatInt32:
                    value = Double(src.assumingMemoryBound(to: Int32.self).pointee) / 2_147_483_648.0
                default:
                    value = 0
                }
                avfaudioWritePCMSample(buffer, channel: channel, frame: frame, value: value)
            }
        }
    }
    return AVAudioFrameCount(frames)
}
