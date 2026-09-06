#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if os(Linux)
import Glibc
#endif
import Foundation

public enum AudioFilePermissions: Int8, Sendable, Hashable {
    case readPermission = 0x01
    case writePermission = 0x02
    case readWritePermission = 0x03
}

public struct AudioFileFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let eraseFile = AudioFileFlags(rawValue: 1)
    public static let dontPageAlignAudioData = AudioFileFlags(rawValue: 2)
}

@frozen
public struct AudioFilePacketTableInfo: Equatable, Hashable, Sendable {
    public var mNumberValidFrames: Int64
    public var mPrimingFrames: Int32
    public var mRemainderFrames: Int32

    public init() {
        mNumberValidFrames = 0
        mPrimingFrames = 0
        mRemainderFrames = 0
    }

    public init(mNumberValidFrames: Int64, mPrimingFrames: Int32, mRemainderFrames: Int32) {
        self.mNumberValidFrames = mNumberValidFrames
        self.mPrimingFrames = mPrimingFrames
        self.mRemainderFrames = mRemainderFrames
    }
}

@frozen
public struct AudioFileTypeAndFormatID: Equatable, Hashable, Sendable {
    public var mFileType: AudioFileTypeID
    public var mFormatID: UInt32

    public init() {
        mFileType = 0
        mFormatID = 0
    }

    public init(mFileType: AudioFileTypeID, mFormatID: UInt32) {
        self.mFileType = mFileType
        self.mFormatID = mFormatID
    }
}

internal final class ATAudioFileObject: ATObject {
    var urlPath: String
    var fileType: AudioFileTypeID
    var format: ATASBD
    var audioBytes: Data
    var dataOffset: Int64
    var permissions: AudioFilePermissions
    var packetCursor: Int64 = 0
    var closed = false
    var deferSizeUpdates = false

    init(
        urlPath: String,
        fileType: AudioFileTypeID,
        format: ATASBD,
        audioBytes: Data,
        dataOffset: Int64,
        permissions: AudioFilePermissions
    ) {
        self.urlPath = urlPath
        self.fileType = fileType
        self.format = format
        self.audioBytes = audioBytes
        self.dataOffset = dataOffset
        self.permissions = permissions
    }

    var packetCount: Int64 {
        let frameBytes = max(Int(format.mBytesPerPacket), 1)
        return Int64(audioBytes.count / frameBytes)
    }

    var duration: Float64 {
        if format.mSampleRate <= 0 { return 0 }
        let frames = Float64(audioBytes.count) / Float64(max(format.mBytesPerFrame, 1))
        return frames / format.mSampleRate
    }
}

internal final class ATExtAudioFileObject: ATObject {
    var wrapped: ATAudioFileObject?
    var frameOffset: Int64 = 0
    var clientFormat: ATASBD?
    var writing = false
}

#if canImport(CoreFoundation)
internal func atPathFromCFURL(_ url: CFURL) -> String? {
    var buffer = [UInt8](repeating: 0, count: 4096)
    let gotPath = buffer.withUnsafeMutableBufferPointer { ptr in
        CFURLGetFileSystemRepresentation(url, true, ptr.baseAddress, 4096)
    }
    if !gotPath { return nil }
    let path = String(cString: buffer)
    if path.isEmpty { return nil }
    return path
}

internal func atParseWAV(_ data: Data) -> (format: ATASBD, audio: Data, offset: Int64)? {
    guard data.count >= 12,
          atReadU32BE(data, 0) == atFourCC("RIFF"),
          atReadU32BE(data, 8) == atFourCC("WAVE")
    else { return nil }
    var offset = 12
    var format = ATASBD()
    var audio = Data()
    var dataOffset: Int64 = 0
    while offset + 8 <= data.count {
        guard let chunkID = atReadU32BE(data, offset),
              let chunkSize = atReadU32LE(data, offset + 4)
        else { break }
        let body = offset + 8
        if chunkID == atFourCC("fmt ") && chunkSize >= 16 {
            guard let channels = atReadU16LE(data, body + 2),
                  let rate = atReadU32LE(data, body + 4),
                  let bits = atReadU16LE(data, body + 14),
                  let audioFormat = atReadU16LE(data, body)
            else { return nil }
            format.mSampleRate = Float64(rate)
            format.mFormatID = atFormatLinearPCM
            format.mChannelsPerFrame = UInt32(channels)
            format.mBitsPerChannel = UInt32(bits)
            format.mFramesPerPacket = 1
            if audioFormat == 3 {
                format.mFormatFlags = atFormatFlagIsFloat | atFormatFlagIsPacked
            } else {
                format.mFormatFlags = atFormatFlagIsPacked
                if bits > 8 {
                    format.mFormatFlags |= atFormatFlagIsSignedInteger
                }
            }
            atFillPCMASBD(&format)
        } else if chunkID == atFourCC("data") {
            let end = min(body + Int(chunkSize), data.count)
            if body < end {
                audio = data.subdata(in: body..<end)
                dataOffset = Int64(body)
            }
        }
        offset = body + Int(chunkSize)
        if chunkSize % 2 == 1 { offset += 1 }
    }
    if format.mChannelsPerFrame == 0 || format.mBitsPerChannel == 0 {
        return nil
    }
    return (format, audio, dataOffset)
}

internal func atParseAIFF(_ data: Data) -> (format: ATASBD, audio: Data, offset: Int64)? {
    guard data.count >= 12,
          atReadU32BE(data, 0) == atFourCC("FORM")
    else { return nil }
    let formType = atReadU32BE(data, 8)
    guard formType == atFourCC("AIFF") || formType == atFourCC("AIFC") else { return nil }
    var offset = 12
    var format = ATASBD()
    var audio = Data()
    var dataOffset: Int64 = 0
    while offset + 8 <= data.count {
        guard let chunkID = atReadU32BE(data, offset),
              let chunkSize = atReadU32BE(data, offset + 4)
        else { break }
        let body = offset + 8
        if chunkID == atFourCC("COMM") && Int(chunkSize) >= 18 {
            guard let channels = atReadU16BE(data, body),
                  let bits = atReadU16BE(data, body + 6)
            else { return nil }
            // 80-bit IEEE extended at body+8; use exponent/mantissa approximation
            let exponent = atReadU16BE(data, body + 8) ?? 0
            let hi = atReadU32BE(data, body + 10) ?? 0
            let unbiased = Int(exponent & 0x7FFF) - 16383
            let rate: Float64
            if unbiased >= 0 && unbiased < 32 {
                rate = Float64(hi) * pow(2.0, Float64(unbiased - 31))
            } else {
                rate = 44100
            }
            format.mSampleRate = rate
            format.mFormatID = atFormatLinearPCM
            format.mChannelsPerFrame = UInt32(channels)
            format.mBitsPerChannel = UInt32(bits)
            format.mFramesPerPacket = 1
            format.mFormatFlags = atFormatFlagIsPacked | atFormatFlagIsSignedInteger | atFormatFlagIsBigEndian
            atFillPCMASBD(&format)
        } else if chunkID == atFourCC("SSND") && Int(chunkSize) >= 8 {
            let ssndOffset = Int(atReadU32BE(data, body) ?? 0)
            let start = body + 8 + ssndOffset
            let end = min(body + Int(chunkSize), data.count)
            if start < end {
                audio = data.subdata(in: start..<end)
                dataOffset = Int64(start)
            }
        }
        offset = body + Int(chunkSize)
        if chunkSize % 2 == 1 { offset += 1 }
    }
    if format.mChannelsPerFrame == 0 { return nil }
    return (format, audio, dataOffset)
}

internal func atParseCAF(_ data: Data) -> (format: ATASBD, audio: Data, offset: Int64)? {
    guard data.count >= 8,
          atReadU32BE(data, 0) == kCAF_FileType
    else { return nil }
    var offset = 8
    var format = ATASBD()
    var audio = Data()
    var dataOffset: Int64 = 0
    while offset + 12 <= data.count {
        guard let chunkType = atReadU32BE(data, offset) else { break }
        let sizeHi = atReadU32BE(data, offset + 4) ?? 0
        let sizeLo = atReadU32BE(data, offset + 8) ?? 0
        let chunkSize = (Int64(sizeHi) << 32) | Int64(sizeLo)
        let body = offset + 12
        if chunkType == kCAF_StreamDescriptionChunkID && chunkSize >= 32 {
            guard let rate = atReadF64BE(data, body),
                  let formatID = atReadU32BE(data, body + 8),
                  let flags = atReadU32BE(data, body + 12),
                  let bytesPerPacket = atReadU32BE(data, body + 16),
                  let framesPerPacket = atReadU32BE(data, body + 20),
                  let channels = atReadU32BE(data, body + 24),
                  let bits = atReadU32BE(data, body + 28)
            else { return nil }
            format.mSampleRate = rate
            format.mFormatID = formatID
            format.mFormatFlags = flags
            if flags & UInt32(CAFFormatFlags.linearPCMFormatFlagIsLittleEndian.rawValue) != 0 {
                // CAF little-endian PCM maps to ASBD without big-endian flag
            } else if formatID == atFormatLinearPCM {
                format.mFormatFlags = atFormatFlagIsPacked | atFormatFlagIsSignedInteger | atFormatFlagIsBigEndian
                if flags & UInt32(CAFFormatFlags.linearPCMFormatFlagIsFloat.rawValue) != 0 {
                    format.mFormatFlags = atFormatFlagIsPacked | atFormatFlagIsFloat | atFormatFlagIsBigEndian
                }
            }
            format.mBytesPerPacket = bytesPerPacket
            format.mFramesPerPacket = framesPerPacket
            format.mChannelsPerFrame = channels
            format.mBitsPerChannel = bits
            atFillPCMASBD(&format)
        } else if chunkType == kCAF_AudioDataChunkID && chunkSize >= 4 {
            let start = body + 4
            let end = chunkSize < 0 ? data.count : min(start + Int(chunkSize) - 4, data.count)
            if start < end {
                audio = data.subdata(in: start..<end)
                dataOffset = Int64(start)
            }
        }
        if chunkSize < 0 { break }
        offset = body + Int(chunkSize)
    }
    if format.mFormatID != atFormatLinearPCM {
        return nil
    }
    return (format, audio, dataOffset)
}

internal func atEncodeWAV(format: ATASBD, audio: Data) -> Data {
    var payload = Data()
    payload.append(contentsOf: atU32BE(atFourCC("RIFF")))
    let fmtSize: UInt32 = 16
    let dataSize = UInt32(audio.count)
    let riffSize = 4 + 8 + fmtSize + 8 + dataSize
    payload.append(contentsOf: atU32LE(riffSize))
    payload.append(contentsOf: atU32BE(atFourCC("WAVE")))
    payload.append(contentsOf: atU32BE(atFourCC("fmt ")))
    payload.append(contentsOf: atU32LE(fmtSize))
    let audioFormat: UInt16 = format.isFloat ? 3 : 1
    payload.append(contentsOf: atU16LE(audioFormat))
    payload.append(contentsOf: atU16LE(UInt16(format.mChannelsPerFrame)))
    payload.append(contentsOf: atU32LE(UInt32(format.mSampleRate)))
    let byteRate = UInt32(format.mSampleRate) * format.mBytesPerFrame
    payload.append(contentsOf: atU32LE(byteRate))
    payload.append(contentsOf: atU16LE(UInt16(format.mBytesPerFrame)))
    payload.append(contentsOf: atU16LE(UInt16(format.mBitsPerChannel)))
    payload.append(contentsOf: atU32BE(atFourCC("data")))
    payload.append(contentsOf: atU32LE(dataSize))
    payload.append(audio)
    return payload
}

internal func atEncodeAIFF(format: ATASBD, audio: Data) -> Data {
    var comm = Data()
    comm.append(contentsOf: atU16BE(UInt16(format.mChannelsPerFrame)))
    let frames = UInt32(audio.count / max(Int(format.mBytesPerFrame), 1))
    comm.append(contentsOf: atU32BE(frames))
    comm.append(contentsOf: atU16BE(UInt16(format.mBitsPerChannel)))
    let rate = format.mSampleRate
    let exp = Int(log2(max(rate, 1)))
    let unbiased = UInt16(16383 + exp)
    comm.append(contentsOf: atU16BE(unbiased))
    let mantissa = UInt64((rate / pow(2.0, Float64(exp))) * Float64(UInt64(1) << 63))
    for shift in [56, 48, 40, 32, 24, 16, 8, 0] {
        comm.append(UInt8((mantissa >> UInt64(shift)) & 0xFF))
    }
    var ssnd = Data()
    ssnd.append(contentsOf: atU32BE(0))
    ssnd.append(contentsOf: atU32BE(0))
    ssnd.append(audio)
    var form = Data()
    form.append(contentsOf: atU32BE(atFourCC("FORM")))
    let size = UInt32(4 + 8 + comm.count + 8 + ssnd.count)
    form.append(contentsOf: atU32BE(size))
    form.append(contentsOf: atU32BE(atFourCC("AIFF")))
    form.append(contentsOf: atU32BE(atFourCC("COMM")))
    form.append(contentsOf: atU32BE(UInt32(comm.count)))
    form.append(comm)
    form.append(contentsOf: atU32BE(atFourCC("SSND")))
    form.append(contentsOf: atU32BE(UInt32(ssnd.count)))
    form.append(ssnd)
    return form
}

internal func atEncodeCAF(format: ATASBD, audio: Data) -> Data {
    var data = Data()
    data.append(contentsOf: atU32BE(kCAF_FileType))
    data.append(contentsOf: atU16BE(kCAF_FileVersion_Initial))
    data.append(contentsOf: atU16BE(0))
    var desc = Data()
    var rateBits = format.mSampleRate.bitPattern.bigEndian
    withUnsafeBytes(of: &rateBits) { desc.append(contentsOf: $0) }
    desc.append(contentsOf: atU32BE(format.mFormatID))
    var cafFlags: UInt32 = 0
    if format.isFloat { cafFlags |= CAFFormatFlags.linearPCMFormatFlagIsFloat.rawValue }
    if !format.isBigEndian { cafFlags |= CAFFormatFlags.linearPCMFormatFlagIsLittleEndian.rawValue }
    desc.append(contentsOf: atU32BE(cafFlags))
    desc.append(contentsOf: atU32BE(format.mBytesPerPacket))
    desc.append(contentsOf: atU32BE(format.mFramesPerPacket == 0 ? 1 : format.mFramesPerPacket))
    desc.append(contentsOf: atU32BE(format.mChannelsPerFrame))
    desc.append(contentsOf: atU32BE(format.mBitsPerChannel))
    data.append(contentsOf: atU32BE(kCAF_StreamDescriptionChunkID))
    data.append(contentsOf: atU32BE(0))
    data.append(contentsOf: atU32BE(UInt32(desc.count)))
    data.append(desc)
    var audioChunk = Data()
    audioChunk.append(contentsOf: atU32BE(0))
    audioChunk.append(audio)
    data.append(contentsOf: atU32BE(kCAF_AudioDataChunkID))
    data.append(contentsOf: atU32BE(0))
    data.append(contentsOf: atU32BE(UInt32(audioChunk.count)))
    data.append(audioChunk)
    return data
}

internal func atParseAudioFile(_ data: Data, hint: AudioFileTypeID) -> (type: AudioFileTypeID, format: ATASBD, audio: Data, offset: Int64)? {
    if hint == kAudioFileWAVEType || hint == 0 {
        if let parsed = atParseWAV(data) {
            return (kAudioFileWAVEType, parsed.format, parsed.audio, parsed.offset)
        }
    }
    if hint == kAudioFileAIFFType || hint == kAudioFileAIFCType || hint == 0 {
        if let parsed = atParseAIFF(data) {
            return (kAudioFileAIFFType, parsed.format, parsed.audio, parsed.offset)
        }
    }
    if hint == kAudioFileCAFType || hint == 0 {
        if let parsed = atParseCAF(data) {
            return (kAudioFileCAFType, parsed.format, parsed.audio, parsed.offset)
        }
    }
    return nil
}

public func AudioFileOpenURL(
    _ inFileRef: CFURL?,
    _ inPermissions: AudioFilePermissions,
    _ inFileTypeHint: AudioFileTypeID,
    _ outAudioFile: UnsafeMutablePointer<AudioFileID?>?
) -> Int32 {
    outAudioFile?.pointee = nil
    guard let inFileRef else { return kAudioFileUnspecifiedError }
    if atCFURLIsLikelyMalformed(inFileRef) {
        return kAudioFileInvalidFileError
    }
    guard let path = atPathFromCFURL(inFileRef) else {
        return kAudioFileInvalidFileError
    }
    if path == "/" {
        return kAudioFileInvalidFileError
    }
    if path.withCString({ access($0, F_OK) }) != 0 {
        return kAudioFileFileNotFoundError
    }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return kAudioFileInvalidFileError
    }
    if data.isEmpty {
        return kAudioFileInvalidFileError
    }
    guard let parsed = atParseAudioFile(data, hint: inFileTypeHint) else {
        return kAudioFileUnsupportedFileTypeError
    }
    if !parsed.format.isPCM {
        return kAudioFileUnsupportedDataFormatError
    }
    let file = ATAudioFileObject(
        urlPath: path,
        fileType: parsed.type,
        format: parsed.format,
        audioBytes: parsed.audio,
        dataOffset: parsed.offset,
        permissions: inPermissions
    )
    outAudioFile?.pointee = ATRegistry.shared.retain(file)
    return 0
}

public func AudioFileCreateWithURL(
    _ inFileRef: CFURL?,
    _ inFileType: AudioFileTypeID,
    _ inFormat: UnsafeRawPointer?,
    _ inFlags: AudioFileFlags,
    _ outAudioFile: UnsafeMutablePointer<AudioFileID?>?
) -> Int32 {
    _ = inFlags
    outAudioFile?.pointee = nil
    guard let inFileRef else { return kAudioFileUnspecifiedError }
    guard let inFormat, var format = atLoadASBD(inFormat) else {
        return kAudioFileUnspecifiedError
    }
    if format.mFormatID != atFormatLinearPCM {
        return kAudioFileUnsupportedDataFormatError
    }
    if format.validatePCM() != 0 {
        return kAudioFileUnsupportedDataFormatError
    }
    atFillPCMASBD(&format)
    switch inFileType {
    case kAudioFileWAVEType, kAudioFileAIFFType, kAudioFileAIFCType, kAudioFileCAFType:
        break
    default:
        return kAudioFileUnsupportedFileTypeError
    }
    guard let path = atPathFromCFURL(inFileRef) else {
        return kAudioFileInvalidFileError
    }
    let encoded: Data
    switch inFileType {
    case kAudioFileWAVEType:
        encoded = atEncodeWAV(format: format, audio: Data())
    case kAudioFileCAFType:
        encoded = atEncodeCAF(format: format, audio: Data())
    default:
        encoded = atEncodeAIFF(format: format, audio: Data())
    }
    do {
        try encoded.write(to: URL(fileURLWithPath: path), options: .atomic)
    } catch {
        return kAudioFileUnspecifiedError
    }
    let file = ATAudioFileObject(
        urlPath: path,
        fileType: inFileType,
        format: format,
        audioBytes: Data(),
        dataOffset: 0,
        permissions: .readWritePermission
    )
    outAudioFile?.pointee = ATRegistry.shared.retain(file)
    return 0
}

public func ExtAudioFileOpenURL(
    _ inURL: CFURL?,
    _ outExtAudioFile: UnsafeMutablePointer<ExtAudioFileRef?>?
) -> Int32 {
    outExtAudioFile?.pointee = nil
    var file: AudioFileID?
    let status = AudioFileOpenURL(inURL, .readPermission, 0, &file)
    if status != 0 {
        if status == kAudioFileFileNotFoundError { return status }
        if status == kAudioFileInvalidFileError { return kExtAudioFileError_InvalidDataFormat }
        return kExtAudioFileError_InvalidDataFormat
    }
    guard let file, let wrapped = ATRegistry.shared.lookup(file, as: ATAudioFileObject.self) else {
        return kExtAudioFileError_InvalidDataFormat
    }
    let ext = ATExtAudioFileObject()
    ext.wrapped = wrapped
    ext.clientFormat = wrapped.format
    outExtAudioFile?.pointee = ATRegistry.shared.retain(ext)
    return 0
}

public func ExtAudioFileCreateWithURL(
    _ inURL: CFURL?,
    _ inFileType: AudioFileTypeID,
    _ inStreamDesc: UnsafeRawPointer?,
    _ inChannelLayout: UnsafeRawPointer?,
    _ inFlags: AudioFileFlags,
    _ outExtAudioFile: UnsafeMutablePointer<ExtAudioFileRef?>?
) -> Int32 {
    _ = inChannelLayout
    outExtAudioFile?.pointee = nil
    var file: AudioFileID?
    let status = AudioFileCreateWithURL(inURL, inFileType, inStreamDesc, inFlags, &file)
    if status != 0 { return kExtAudioFileError_InvalidDataFormat }
    guard let file, let wrapped = ATRegistry.shared.lookup(file, as: ATAudioFileObject.self) else {
        return kExtAudioFileError_InvalidDataFormat
    }
    let ext = ATExtAudioFileObject()
    ext.wrapped = wrapped
    ext.clientFormat = wrapped.format
    ext.writing = true
    outExtAudioFile?.pointee = ATRegistry.shared.retain(ext)
    return 0
}
@_cdecl("AudioFileClose")
public func AudioFileClose(_ inAudioFile: AudioFileID?) -> Int32 {
    if let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) {
        _ = atFlushAudioFile(file)
    }
    let status = ATRegistry.shared.release(inAudioFile)
    return status == atParamError ? kAudioFileNotOpenError : 0
}

internal func atFlushAudioFile(_ file: ATAudioFileObject) -> Int32 {
#if canImport(CoreFoundation)
    let encoded: Data
    switch file.fileType {
    case kAudioFileWAVEType:
        encoded = atEncodeWAV(format: file.format, audio: file.audioBytes)
    case kAudioFileCAFType:
        encoded = atEncodeCAF(format: file.format, audio: file.audioBytes)
    default:
        encoded = atEncodeAIFF(format: file.format, audio: file.audioBytes)
    }
    do {
        try encoded.write(to: URL(fileURLWithPath: file.urlPath), options: .atomic)
        return 0
    } catch {
        return kAudioFileUnspecifiedError
    }
#else
    _ = file
    return 0
#endif
}

@_cdecl("ExtAudioFileDispose")
public func ExtAudioFileDispose(_ inExtAudioFile: ExtAudioFileRef?) -> Int32 {
    if let ext = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self),
       let wrapped = ext.wrapped
    {
        _ = atFlushAudioFile(wrapped)
    }
    let status = ATRegistry.shared.release(inExtAudioFile)
    return status == atParamError ? 0 : status
}

@_cdecl("ExtAudioFileTell")
public func ExtAudioFileTell(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ outFrameOffset: UnsafeMutablePointer<Int64>?
) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self) else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    outFrameOffset?.pointee = file.frameOffset
    return 0
}

@_cdecl("ExtAudioFileSeek")
public func ExtAudioFileSeek(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inFrameOffset: Int64
) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self) else {
        return kExtAudioFileError_InvalidSeek
    }
    if inFrameOffset < 0 {
        return kExtAudioFileError_InvalidSeek
    }
    file.frameOffset = inFrameOffset
    return 0
}

@_cdecl("ExtAudioFileWrapAudioFileID")
public func ExtAudioFileWrapAudioFileID(
    _ inFileID: AudioFileID?,
    _ inForWriting: Bool,
    _ outExtAudioFile: UnsafeMutablePointer<ExtAudioFileRef?>?
) -> Int32 {
    outExtAudioFile?.pointee = nil
    guard let wrapped = ATRegistry.shared.lookup(inFileID, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    let ext = ATExtAudioFileObject()
    ext.wrapped = wrapped
    ext.clientFormat = wrapped.format
    ext.writing = inForWriting
    outExtAudioFile?.pointee = ATRegistry.shared.retain(ext)
    return 0
}

public func AudioFileGetPropertyInfo(
    _ inAudioFile: AudioFileID?,
    _ inPropertyID: AudioFilePropertyID,
    _ outDataSize: UnsafeMutablePointer<UInt32>?,
    _ isWritable: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) != nil else {
        return kAudioFileNotOpenError
    }
    isWritable?.pointee = 0
    switch inPropertyID {
    case kAudioFilePropertyFileFormat:
        outDataSize?.pointee = 4
    case kAudioFilePropertyDataFormat:
        outDataSize?.pointee = UInt32(atASBDSize)
    case kAudioFilePropertyAudioDataByteCount, kAudioFilePropertyAudioDataPacketCount:
        outDataSize?.pointee = 8
    case kAudioFilePropertyMaximumPacketSize, kAudioFilePropertyPacketSizeUpperBound:
        outDataSize?.pointee = 4
    case kAudioFilePropertyDataOffset:
        outDataSize?.pointee = 8
    case kAudioFilePropertyEstimatedDuration:
        outDataSize?.pointee = 8
    case kAudioFilePropertyBitRate, kAudioFilePropertySourceBitDepth, kAudioFilePropertyAudioTrackCount:
        outDataSize?.pointee = 4
    case kAudioFilePropertyIsOptimized:
        outDataSize?.pointee = 4
    case kAudioFilePropertyChannelLayout:
        outDataSize?.pointee = 12
    default:
        return kAudioFileUnsupportedPropertyError
    }
    return 0
}

public func AudioFileGetProperty(
    _ inAudioFile: AudioFileID?,
    _ inPropertyID: AudioFilePropertyID,
    _ ioDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    func need(_ size: UInt32) -> Int32? {
        if let ioDataSize, ioDataSize.pointee < size, outPropertyData != nil {
            return kAudioFileBadPropertySizeError
        }
        ioDataSize?.pointee = size
        return nil
    }
    switch inPropertyID {
    case kAudioFilePropertyFileFormat:
        if let err = need(4) { return err }
        outPropertyData?.storeBytes(of: file.fileType, as: UInt32.self)
    case kAudioFilePropertyDataFormat:
        if let err = need(UInt32(atASBDSize)) { return err }
        if let outPropertyData { atStoreASBD(file.format, to: outPropertyData) }
    case kAudioFilePropertyAudioDataByteCount:
        if let err = need(8) { return err }
        outPropertyData?.storeBytes(of: UInt64(file.audioBytes.count), as: UInt64.self)
    case kAudioFilePropertyAudioDataPacketCount:
        if let err = need(8) { return err }
        outPropertyData?.storeBytes(of: UInt64(file.packetCount), as: UInt64.self)
    case kAudioFilePropertyMaximumPacketSize, kAudioFilePropertyPacketSizeUpperBound:
        if let err = need(4) { return err }
        outPropertyData?.storeBytes(of: file.format.mBytesPerPacket, as: UInt32.self)
    case kAudioFilePropertyDataOffset:
        if let err = need(8) { return err }
        outPropertyData?.storeBytes(of: file.dataOffset, as: Int64.self)
    case kAudioFilePropertyEstimatedDuration:
        if let err = need(8) { return err }
        outPropertyData?.storeBytes(of: file.duration, as: Float64.self)
    case kAudioFilePropertyBitRate:
        if let err = need(4) { return err }
        let rate = UInt32(file.format.mSampleRate) * file.format.mBytesPerFrame * 8
        outPropertyData?.storeBytes(of: rate, as: UInt32.self)
    case kAudioFilePropertySourceBitDepth:
        if let err = need(4) { return err }
        outPropertyData?.storeBytes(of: file.format.mBitsPerChannel, as: UInt32.self)
    case kAudioFilePropertyAudioTrackCount:
        if let err = need(4) { return err }
        outPropertyData?.storeBytes(of: UInt32(1), as: UInt32.self)
    case kAudioFilePropertyIsOptimized:
        if let err = need(4) { return err }
        outPropertyData?.storeBytes(of: UInt32(1), as: UInt32.self)
    case kAudioFilePropertyChannelLayout:
        if let err = need(12) { return err }
        if let outPropertyData {
            atStoreChannelLayout(channels: file.format.mChannelsPerFrame, to: outPropertyData)
        }
    default:
        return kAudioFileUnsupportedPropertyError
    }
    return 0
}

public func AudioFileReadPackets(
    _ inAudioFile: AudioFileID?,
    _ inUseCache: Bool,
    _ outNumBytes: UnsafeMutablePointer<UInt32>?,
    _ outPacketDescriptions: UnsafeMutableRawPointer?,
    _ inStartingPacket: Int64,
    _ ioNumPackets: UnsafeMutablePointer<UInt32>?,
    _ outBuffer: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inUseCache
    _ = outPacketDescriptions
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    guard let ioNumPackets else { return kAudioFileUnspecifiedError }
    let packetSize = Int(max(file.format.mBytesPerPacket, 1))
    if inStartingPacket < 0 || inStartingPacket > file.packetCount {
        return kAudioFileInvalidPacketOffsetError
    }
    let available = UInt32(max(file.packetCount - inStartingPacket, 0))
    let want = min(ioNumPackets.pointee, available)
    let byteCount = Int(want) * packetSize
    let start = Int(inStartingPacket) * packetSize
    if let outBuffer, byteCount > 0, start + byteCount <= file.audioBytes.count {
        file.audioBytes.withUnsafeBytes { raw in
            outBuffer.copyMemory(from: raw.baseAddress!.advanced(by: start), byteCount: byteCount)
        }
    }
    outNumBytes?.pointee = UInt32(byteCount)
    ioNumPackets.pointee = want
    if want == 0 {
        return kAudioFileEndOfFileError
    }
    return 0
}

public func AudioFileWritePackets(
    _ inAudioFile: AudioFileID?,
    _ inUseCache: Bool,
    _ inNumBytes: UInt32,
    _ inPacketDescriptions: UnsafeRawPointer?,
    _ inStartingPacket: Int64,
    _ ioNumPackets: UnsafeMutablePointer<UInt32>?,
    _ inBuffer: UnsafeRawPointer?
) -> Int32 {
    _ = inUseCache
    _ = inPacketDescriptions
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    if file.permissions == .readPermission {
        return kAudioFilePermissionsError
    }
    guard let inBuffer, let ioNumPackets else { return kAudioFileUnspecifiedError }
    let packetSize = Int(max(file.format.mBytesPerPacket, 1))
    let packets = Int(ioNumPackets.pointee)
    let bytes = min(Int(inNumBytes), packets * packetSize)
    let start = Int(max(inStartingPacket, 0)) * packetSize
    if start > file.audioBytes.count {
        file.audioBytes.append(Data(count: start - file.audioBytes.count))
    }
    let incoming = Data(bytes: inBuffer, count: bytes)
    if start == file.audioBytes.count {
        file.audioBytes.append(incoming)
    } else {
        let end = start + bytes
        if end > file.audioBytes.count {
            file.audioBytes.append(Data(count: end - file.audioBytes.count))
        }
        file.audioBytes.replaceSubrange(start..<end, with: incoming)
    }
    ioNumPackets.pointee = UInt32(bytes / max(packetSize, 1))
    return 0
}

public func AudioFileReadBytes(
    _ inAudioFile: AudioFileID?,
    _ inUseCache: Bool,
    _ inStartingByte: Int64,
    _ ioNumBytes: UnsafeMutablePointer<UInt32>?,
    _ outBuffer: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inUseCache
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    guard let ioNumBytes else { return kAudioFileUnspecifiedError }
    if inStartingByte < 0 {
        return kAudioFilePositionError
    }
    let start = Int(inStartingByte)
    if start >= file.audioBytes.count {
        ioNumBytes.pointee = 0
        return kAudioFileEndOfFileError
    }
    let want = min(Int(ioNumBytes.pointee), file.audioBytes.count - start)
    if let outBuffer {
        file.audioBytes.withUnsafeBytes { raw in
            outBuffer.copyMemory(from: raw.baseAddress!.advanced(by: start), byteCount: want)
        }
    }
    ioNumBytes.pointee = UInt32(want)
    return 0
}

public func AudioFileWriteBytes(
    _ inAudioFile: AudioFileID?,
    _ inUseCache: Bool,
    _ inStartingByte: Int64,
    _ ioNumBytes: UnsafeMutablePointer<UInt32>?,
    _ inBuffer: UnsafeRawPointer?
) -> Int32 {
    _ = inUseCache
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    if file.permissions == .readPermission {
        return kAudioFilePermissionsError
    }
    guard let ioNumBytes, let inBuffer else { return kAudioFileUnspecifiedError }
    let start = Int(max(inStartingByte, 0))
    let count = Int(ioNumBytes.pointee)
    if start > file.audioBytes.count {
        file.audioBytes.append(Data(count: start - file.audioBytes.count))
    }
    let incoming = Data(bytes: inBuffer, count: count)
    if start == file.audioBytes.count {
        file.audioBytes.append(incoming)
    } else {
        let end = start + count
        if end > file.audioBytes.count {
            file.audioBytes.append(Data(count: end - file.audioBytes.count))
        }
        file.audioBytes.replaceSubrange(start..<end, with: incoming)
    }
    return 0
}

public func ExtAudioFileGetProperty(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inPropertyID: ExtAudioFilePropertyID,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let ext = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self),
          let wrapped = ext.wrapped
    else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    switch inPropertyID {
    case kExtAudioFileProperty_FileDataFormat, kExtAudioFileProperty_ClientDataFormat:
        if let ioPropertyDataSize, ioPropertyDataSize.pointee < UInt32(atASBDSize) {
            return kExtAudioFileError_InvalidPropertySize
        }
        ioPropertyDataSize?.pointee = UInt32(atASBDSize)
        let format = inPropertyID == kExtAudioFileProperty_ClientDataFormat
            ? (ext.clientFormat ?? wrapped.format)
            : wrapped.format
        if let outPropertyData { atStoreASBD(format, to: outPropertyData) }
        return 0
    case kExtAudioFileProperty_FileLengthFrames:
        if let ioPropertyDataSize, ioPropertyDataSize.pointee < 8 {
            return kExtAudioFileError_InvalidPropertySize
        }
        ioPropertyDataSize?.pointee = 8
        let frames = Int64(wrapped.audioBytes.count / max(Int(wrapped.format.mBytesPerFrame), 1))
        outPropertyData?.storeBytes(of: frames, as: Int64.self)
        return 0
    case kExtAudioFileProperty_FileMaxPacketSize, kExtAudioFileProperty_ClientMaxPacketSize:
        ioPropertyDataSize?.pointee = 4
        outPropertyData?.storeBytes(of: wrapped.format.mBytesPerPacket, as: UInt32.self)
        return 0
    default:
        return kExtAudioFileError_InvalidProperty
    }
}

public func ExtAudioFileSetProperty(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inPropertyID: ExtAudioFilePropertyID,
    _ inPropertyDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    guard let ext = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self) else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    if inPropertyID == kExtAudioFileProperty_ClientDataFormat {
        guard let inPropertyData, inPropertyDataSize >= UInt32(atASBDSize),
              var format = atLoadASBD(inPropertyData)
        else {
            return kExtAudioFileError_InvalidPropertySize
        }
        if !format.isPCM {
            return kExtAudioFileError_NonPCMClientFormat
        }
        atFillPCMASBD(&format)
        ext.clientFormat = format
        return 0
    }
    return kExtAudioFileError_InvalidProperty
}

public func ExtAudioFileRead(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ ioNumberFrames: UnsafeMutablePointer<UInt32>?,
    _ ioData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let ext = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self),
          let wrapped = ext.wrapped,
          let ioNumberFrames
    else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    let client = ext.clientFormat ?? wrapped.format
    let fileFormat = wrapped.format
    let fileFrameBytes = Int(max(fileFormat.mBytesPerFrame, 1))
    let totalFrames = wrapped.audioBytes.count / fileFrameBytes
    let start = Int(ext.frameOffset)
    if start >= totalFrames {
        ioNumberFrames.pointee = 0
        return 0
    }
    let want = min(Int(ioNumberFrames.pointee), totalFrames - start)
    let srcStart = start * fileFrameBytes
    let srcCount = want * fileFrameBytes
    guard let list = atLoadBufferList(ioData), let first = list.buffers.first, let dest = first.data else {
        return kExtAudioFileError_InvalidDataFormat
    }
    let result = wrapped.audioBytes.withUnsafeBytes { raw in
        atConvertPCM(
            source: fileFormat,
            dest: client,
            input: raw.baseAddress!.advanced(by: srcStart),
            inputByteCount: srcCount,
            output: dest,
            outputByteCapacity: Int(first.dataByteSize),
            channelMap: nil
        )
    }
    if result.status != 0 {
        return result.status
    }
    ioNumberFrames.pointee = UInt32(want)
    ext.frameOffset += Int64(want)
    return 0
}

public func ExtAudioFileWrite(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inNumberFrames: UInt32,
    _ ioData: UnsafeRawPointer?
) -> Int32 {
    guard let ext = ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self),
          let wrapped = ext.wrapped
    else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    if !ext.writing && wrapped.permissions == .readPermission {
        return kExtAudioFileError_InvalidOperationOrder
    }
    let client = ext.clientFormat ?? wrapped.format
    guard let list = atLoadBufferList(ioData), let first = list.buffers.first, let src = first.data else {
        return kExtAudioFileError_InvalidDataFormat
    }
    let clientFrameBytes = Int(max(client.mBytesPerFrame, 1))
    let srcCount = Int(inNumberFrames) * clientFrameBytes
    var converted = [UInt8](repeating: 0, count: Int(inNumberFrames) * Int(max(wrapped.format.mBytesPerFrame, 1)))
    let result = converted.withUnsafeMutableBytes { dest in
        atConvertPCM(
            source: client,
            dest: wrapped.format,
            input: UnsafeRawPointer(src),
            inputByteCount: min(srcCount, Int(first.dataByteSize)),
            output: dest.baseAddress!,
            outputByteCapacity: dest.count,
            channelMap: nil
        )
    }
    if result.status != 0 {
        return result.status
    }
    wrapped.audioBytes.append(contentsOf: converted.prefix(result.outputBytes))
    ext.frameOffset += Int64(inNumberFrames)
    return 0
}

public func ExtAudioFileGetPropertyInfo(
    _ inExtAudioFile: ExtAudioFileRef?,
    _ inPropertyID: ExtAudioFilePropertyID,
    _ outSize: UnsafeMutablePointer<UInt32>?,
    _ outWritable: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inExtAudioFile, as: ATExtAudioFileObject.self) != nil else {
        return kExtAudioFileError_InvalidOperationOrder
    }
    switch inPropertyID {
    case kExtAudioFileProperty_FileDataFormat, kExtAudioFileProperty_ClientDataFormat:
        outSize?.pointee = UInt32(atASBDSize)
        outWritable?.pointee = inPropertyID == kExtAudioFileProperty_ClientDataFormat ? 1 : 0
        return 0
    case kExtAudioFileProperty_FileLengthFrames:
        outSize?.pointee = 8
        outWritable?.pointee = 0
        return 0
    default:
        return kExtAudioFileError_InvalidProperty
    }
}

public func AudioFileSetProperty(
    _ inAudioFile: AudioFileID?,
    _ inPropertyID: AudioFilePropertyID,
    _ inDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    switch inPropertyID {
    case kAudioFilePropertyDeferSizeUpdates:
        guard let inPropertyData, inDataSize >= 4 else { return kAudioFileBadPropertySizeError }
        file.deferSizeUpdates = inPropertyData.loadUnaligned(as: UInt32.self) != 0
        return 0
    default:
        return kAudioFileUnsupportedPropertyError
    }
}

@_cdecl("AudioFileOptimize")
public func AudioFileOptimize(_ inAudioFile: AudioFileID?) -> Int32 {
    guard let file = ATRegistry.shared.lookup(inAudioFile, as: ATAudioFileObject.self) else {
        return kAudioFileNotOpenError
    }
    if file.permissions == .readPermission {
        return kAudioFilePermissionsError
    }
    return 0
}

public func AudioFileReadPacketData(
    _ inAudioFile: AudioFileID?,
    _ inUseCache: Bool,
    _ outNumBytes: UnsafeMutablePointer<UInt32>?,
    _ outPacketDescriptions: UnsafeMutableRawPointer?,
    _ inStartingPacket: Int64,
    _ ioNumPackets: UnsafeMutablePointer<UInt32>?,
    _ outBuffer: UnsafeMutableRawPointer?
) -> Int32 {
    return AudioFileReadPackets(
        inAudioFile,
        inUseCache,
        outNumBytes,
        outPacketDescriptions,
        inStartingPacket,
        ioNumPackets,
        outBuffer
    )
}

private let atHostedAudioFileTypes: [AudioFileTypeID] = [
    kAudioFileWAVEType,
    kAudioFileAIFFType,
    kAudioFileCAFType,
]

public func AudioFileGetGlobalInfoSize(
    _ inPropertyID: AudioFilePropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeMutableRawPointer?,
    _ outDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inSpecifierSize
    _ = inSpecifier
    switch inPropertyID {
    case kAudioFileGlobalInfo_ReadableTypes, kAudioFileGlobalInfo_WritableTypes:
        outDataSize?.pointee = UInt32(atHostedAudioFileTypes.count * 4)
        return 0
    case kAudioFileGlobalInfo_AvailableFormatIDs:
        outDataSize?.pointee = 4
        return 0
    case kAudioFileGlobalInfo_FileTypeName:
        outDataSize?.pointee = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        return 0
    default:
        return kAudioFileUnsupportedPropertyError
    }
}

public func AudioFileGetGlobalInfo(
    _ inPropertyID: AudioFilePropertyID,
    _ inSpecifierSize: UInt32,
    _ inSpecifier: UnsafeMutableRawPointer?,
    _ ioDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inSpecifierSize
    switch inPropertyID {
    case kAudioFileGlobalInfo_ReadableTypes, kAudioFileGlobalInfo_WritableTypes:
        let size = UInt32(atHostedAudioFileTypes.count * 4)
        if let ioDataSize, ioDataSize.pointee < size {
            return kAudioFileBadPropertySizeError
        }
        ioDataSize?.pointee = size
        if let outPropertyData {
            for (index, type) in atHostedAudioFileTypes.enumerated() {
                outPropertyData.storeBytes(of: type, toByteOffset: index * 4, as: UInt32.self)
            }
        }
        return 0
    case kAudioFileGlobalInfo_AvailableFormatIDs:
        if let ioDataSize, ioDataSize.pointee < 4 {
            return kAudioFileBadPropertySizeError
        }
        ioDataSize?.pointee = 4
        outPropertyData?.storeBytes(of: atFormatLinearPCM, as: UInt32.self)
        return 0
    case kAudioFileGlobalInfo_FileTypeName:
        let fileType = inSpecifier?.loadUnaligned(as: AudioFileTypeID.self) ?? 0
        let name: String
        switch fileType {
        case kAudioFileWAVEType: name = "WAVE"
        case kAudioFileAIFFType: name = "AIFF"
        case kAudioFileCAFType: name = "CAF"
        default: name = "Unknown"
        }
        ioDataSize?.pointee = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        if let outPropertyData {
            let cf = name.withCString { pointer in
                CFStringCreateWithCString(
                    kCFAllocatorDefault,
                    pointer,
                    CFStringBuiltInEncodings.UTF8.rawValue
                )
            }!
            outPropertyData.storeBytes(of: Unmanaged.passRetained(cf), as: Unmanaged<CFString>.self)
        }
        return 0
    default:
        return kAudioFileUnsupportedPropertyError
    }
}
#endif
