import Foundation

public struct AudioFileStreamParseFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let discontinuity = AudioFileStreamParseFlags(rawValue: 1)
}

public struct AudioFileStreamPropertyFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let propertyIsCached = AudioFileStreamPropertyFlags(rawValue: 1)
    public static let cacheProperty = AudioFileStreamPropertyFlags(rawValue: 2)
}

public struct AudioFileStreamSeekFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let offsetIsEstimated = AudioFileStreamSeekFlags(rawValue: 1)
}

public let kAudioFileStreamError_UnsupportedFileType: Int32 = atSignedFourCC("typ?")
public let kAudioFileStreamError_UnsupportedDataFormat: Int32 = atSignedFourCC("fmt?")
public let kAudioFileStreamError_UnsupportedProperty: Int32 = atSignedFourCC("pty?")
public let kAudioFileStreamError_BadPropertySize: Int32 = atSignedFourCC("!siz")
public let kAudioFileStreamError_NotOptimized: Int32 = atSignedFourCC("optm")
public let kAudioFileStreamError_InvalidPacketOffset: Int32 = atSignedFourCC("pck?")
public let kAudioFileStreamError_InvalidFile: Int32 = atSignedFourCC("dta?")
public let kAudioFileStreamError_ValueUnknown: Int32 = atSignedFourCC("unk?")
public let kAudioFileStreamError_DataUnavailable: Int32 = atSignedFourCC("more")
public let kAudioFileStreamError_IllegalOperation: Int32 = atSignedFourCC("nope")
public let kAudioFileStreamError_UnspecifiedError: Int32 = atSignedFourCC("wht?")
public let kAudioFileStreamError_DiscontinuityCantRecover: Int32 = atSignedFourCC("dsc!")

public let kAudioFileStreamProperty_ReadyToProducePackets: AudioFileStreamPropertyID = atFourCC("redy")
public let kAudioFileStreamProperty_FileFormat: AudioFileStreamPropertyID = atFourCC("ffmt")
public let kAudioFileStreamProperty_DataFormat: AudioFileStreamPropertyID = atFourCC("dfmt")
public let kAudioFileStreamProperty_FormatList: AudioFileStreamPropertyID = atFourCC("flst")
public let kAudioFileStreamProperty_MagicCookieData: AudioFileStreamPropertyID = atFourCC("mgic")
public let kAudioFileStreamProperty_AudioDataByteCount: AudioFileStreamPropertyID = atFourCC("bcnt")
public let kAudioFileStreamProperty_AudioDataPacketCount: AudioFileStreamPropertyID = atFourCC("pcnt")
public let kAudioFileStreamProperty_MaximumPacketSize: AudioFileStreamPropertyID = atFourCC("psze")
public let kAudioFileStreamProperty_DataOffset: AudioFileStreamPropertyID = atFourCC("doff")
public let kAudioFileStreamProperty_ChannelLayout: AudioFileStreamPropertyID = atFourCC("cmap")
public let kAudioFileStreamProperty_PacketToFrame: AudioFileStreamPropertyID = atFourCC("pkfr")
public let kAudioFileStreamProperty_FrameToPacket: AudioFileStreamPropertyID = atFourCC("frpk")
public let kAudioFileStreamProperty_PacketToByte: AudioFileStreamPropertyID = atFourCC("pkby")
public let kAudioFileStreamProperty_ByteToPacket: AudioFileStreamPropertyID = atFourCC("bypk")
public let kAudioFileStreamProperty_PacketTableInfo: AudioFileStreamPropertyID = atFourCC("pnfo")
public let kAudioFileStreamProperty_PacketSizeUpperBound: AudioFileStreamPropertyID = atFourCC("pkub")
public let kAudioFileStreamProperty_AverageBytesPerPacket: AudioFileStreamPropertyID = atFourCC("abpp")
public let kAudioFileStreamProperty_BitRate: AudioFileStreamPropertyID = atFourCC("brat")
public let kAudioFileStreamProperty_InfoDictionary: AudioFileStreamPropertyID = atFourCC("info")
public let kAudioFileStreamProperty_NextIndependentPacket: AudioFileStreamPropertyID = atFourCC("nind")
public let kAudioFileStreamProperty_PreviousIndependentPacket: AudioFileStreamPropertyID = atFourCC("pind")
public let kAudioFileStreamProperty_PacketToDependencyInfo: AudioFileStreamPropertyID = atFourCC("pdep")
public let kAudioFileStreamProperty_PacketToRollDistance: AudioFileStreamPropertyID = atFourCC("prll")
public let kAudioFileStreamProperty_RestrictsRandomAccess: AudioFileStreamPropertyID = atFourCC("rran")

public typealias AudioFileStream_PropertyListenerProc = (
    UnsafeMutableRawPointer?,
    AudioFileStreamID,
    AudioFileStreamPropertyID,
    UnsafeMutablePointer<AudioFileStreamPropertyFlags>
) -> Void

public typealias AudioFileStream_PacketsProc = (
    UnsafeMutableRawPointer?,
    UInt32,
    UInt32,
    UnsafeRawPointer?,
    UnsafeMutableRawPointer?
) -> Void

internal final class ATAudioFileStreamObject: ATObject {
    var hint: AudioFileTypeID
    var clientData: UnsafeMutableRawPointer?
    var propertyListener: AudioFileStream_PropertyListenerProc?
    var packetsProc: AudioFileStream_PacketsProc?
    var buffer = Data()
    var fileType: AudioFileTypeID = 0
    var format = ATASBD()
    var audio = Data()
    var dataOffset: Int64 = 0
    var ready = false
    var announcedReady = false
    var deliveredBytes = 0

    init(
        hint: AudioFileTypeID,
        clientData: UnsafeMutableRawPointer?,
        propertyListener: AudioFileStream_PropertyListenerProc?,
        packetsProc: AudioFileStream_PacketsProc?
    ) {
        self.hint = hint
        self.clientData = clientData
        self.propertyListener = propertyListener
        self.packetsProc = packetsProc
    }
}

public func AudioFileStreamOpen(
    _ inClientData: UnsafeMutableRawPointer?,
    _ inPropertyListenerProc: AudioFileStream_PropertyListenerProc?,
    _ inPacketsProc: AudioFileStream_PacketsProc?,
    _ inFileTypeHint: AudioFileTypeID,
    _ outAudioFileStream: UnsafeMutablePointer<AudioFileStreamID?>?
) -> Int32 {
    outAudioFileStream?.pointee = nil
    let stream = ATAudioFileStreamObject(
        hint: inFileTypeHint,
        clientData: inClientData,
        propertyListener: inPropertyListenerProc,
        packetsProc: inPacketsProc
    )
    outAudioFileStream?.pointee = ATRegistry.shared.retain(stream)
    return 0
}

@_cdecl("AudioFileStreamClose")
public func AudioFileStreamClose(_ inAudioFileStream: AudioFileStreamID?) -> Int32 {
    let status = ATRegistry.shared.release(inAudioFileStream)
    return status == atParamError ? 0 : status
}

public func AudioFileStreamParseBytes(
    _ inAudioFileStream: AudioFileStreamID?,
    _ inDataByteSize: UInt32,
    _ inData: UnsafeRawPointer?,
    _ inFlags: AudioFileStreamParseFlags
) -> Int32 {
    guard let stream = ATRegistry.shared.lookup(inAudioFileStream, as: ATAudioFileStreamObject.self) else {
        return kAudioFileStreamError_IllegalOperation
    }
    if inFlags.contains(.discontinuity) {
        stream.buffer.removeAll(keepingCapacity: true)
        stream.ready = false
        stream.announcedReady = false
        stream.deliveredBytes = 0
        stream.audio = Data()
    }
    if inDataByteSize > 0 {
        guard let inData else { return kAudioFileStreamError_UnspecifiedError }
        stream.buffer.append(Data(bytes: inData, count: Int(inDataByteSize)))
    }
    guard let parsed = atParseAudioFile(stream.buffer, hint: stream.hint) else {
        // Incomplete headers are not a format error: the client is expected to
        // feed more bytes. Reject only a complete prefix with a foreign magic.
        if stream.buffer.count >= 4 {
            let magic = stream.buffer.prefix(4)
            let riff = magic.elementsEqual([0x52, 0x49, 0x46, 0x46])
            let form = magic.elementsEqual([0x46, 0x4F, 0x52, 0x4D])
            let caff = magic.elementsEqual([0x63, 0x61, 0x66, 0x66])
            if !riff && !form && !caff {
                return kAudioFileStreamError_UnsupportedFileType
            }
        }
        return 0
    }
    if !parsed.format.isPCM {
        return kAudioFileStreamError_UnsupportedDataFormat
    }
    stream.fileType = parsed.type
    stream.format = parsed.format
    stream.audio = parsed.audio
    stream.dataOffset = parsed.offset
    stream.ready = true
    if !stream.announcedReady {
        stream.announcedReady = true
        atStreamAnnounce(stream, kAudioFileStreamProperty_FileFormat)
        atStreamAnnounce(stream, kAudioFileStreamProperty_DataFormat)
        atStreamAnnounce(stream, kAudioFileStreamProperty_ReadyToProducePackets)
    }
    let remaining = stream.audio.count - stream.deliveredBytes
    if remaining > 0, let packetsProc = stream.packetsProc {
        let packetSize = max(Int(stream.format.mBytesPerPacket), 1)
        let packets = remaining / packetSize
        if packets > 0 {
            let bytes = packets * packetSize
            let slice = stream.audio.subdata(
                in: stream.deliveredBytes..<(stream.deliveredBytes + bytes)
            )
            slice.withUnsafeBytes { raw in
                packetsProc(
                    stream.clientData,
                    UInt32(bytes),
                    UInt32(packets),
                    raw.baseAddress,
                    nil
                )
            }
            stream.deliveredBytes += bytes
        }
    }
    return 0
}

private func atStreamAnnounce(_ stream: ATAudioFileStreamObject, _ property: AudioFileStreamPropertyID) {
    guard let listener = stream.propertyListener else { return }
    var flags = AudioFileStreamPropertyFlags.propertyIsCached
    let handle = OpaquePointer(Unmanaged.passUnretained(stream).toOpaque())
    listener(stream.clientData, handle, property, &flags)
}

public func AudioFileStreamGetPropertyInfo(
    _ inAudioFileStream: AudioFileStreamID?,
    _ inPropertyID: AudioFileStreamPropertyID,
    _ outPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outWritable: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let stream = ATRegistry.shared.lookup(inAudioFileStream, as: ATAudioFileStreamObject.self) else {
        return kAudioFileStreamError_IllegalOperation
    }
    if !stream.ready && inPropertyID != kAudioFileStreamProperty_FileFormat {
        return kAudioFileStreamError_DataUnavailable
    }
    outWritable?.pointee = 0
    switch inPropertyID {
    case kAudioFileStreamProperty_DataFormat:
        outPropertyDataSize?.pointee = UInt32(atASBDSize)
    case kAudioFileStreamProperty_FileFormat, kAudioFileStreamProperty_MaximumPacketSize,
         kAudioFileStreamProperty_PacketSizeUpperBound, kAudioFileStreamProperty_ReadyToProducePackets,
         kAudioFileStreamProperty_BitRate:
        outPropertyDataSize?.pointee = 4
    case kAudioFileStreamProperty_AudioDataByteCount, kAudioFileStreamProperty_AudioDataPacketCount,
         kAudioFileStreamProperty_DataOffset:
        outPropertyDataSize?.pointee = 8
    case kAudioFileStreamProperty_ChannelLayout:
        outPropertyDataSize?.pointee = 12
    default:
        return kAudioFileStreamError_UnsupportedProperty
    }
    return 0
}

public func AudioFileStreamGetProperty(
    _ inAudioFileStream: AudioFileStreamID?,
    _ inPropertyID: AudioFileStreamPropertyID,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let stream = ATRegistry.shared.lookup(inAudioFileStream, as: ATAudioFileStreamObject.self) else {
        return kAudioFileStreamError_IllegalOperation
    }
    if !stream.ready {
        return kAudioFileStreamError_DataUnavailable
    }
    switch inPropertyID {
    case kAudioFileStreamProperty_DataFormat:
        if let ioPropertyDataSize, ioPropertyDataSize.pointee < UInt32(atASBDSize) {
            return kAudioFileStreamError_BadPropertySize
        }
        ioPropertyDataSize?.pointee = UInt32(atASBDSize)
        if let outPropertyData { atStoreASBD(stream.format, to: outPropertyData) }
    case kAudioFileStreamProperty_FileFormat:
        ioPropertyDataSize?.pointee = 4
        outPropertyData?.storeBytes(of: stream.fileType, as: UInt32.self)
    case kAudioFileStreamProperty_AudioDataByteCount:
        ioPropertyDataSize?.pointee = 8
        outPropertyData?.storeBytes(of: UInt64(stream.audio.count), as: UInt64.self)
    case kAudioFileStreamProperty_AudioDataPacketCount:
        ioPropertyDataSize?.pointee = 8
        let packets = stream.audio.count / max(Int(stream.format.mBytesPerPacket), 1)
        outPropertyData?.storeBytes(of: UInt64(packets), as: UInt64.self)
    case kAudioFileStreamProperty_MaximumPacketSize, kAudioFileStreamProperty_PacketSizeUpperBound,
         kAudioFileStreamProperty_AverageBytesPerPacket:
        ioPropertyDataSize?.pointee = 4
        outPropertyData?.storeBytes(of: stream.format.mBytesPerPacket, as: UInt32.self)
    case kAudioFileStreamProperty_DataOffset:
        ioPropertyDataSize?.pointee = 8
        outPropertyData?.storeBytes(of: stream.dataOffset, as: Int64.self)
    case kAudioFileStreamProperty_ReadyToProducePackets:
        ioPropertyDataSize?.pointee = 4
        outPropertyData?.storeBytes(of: UInt32(stream.ready ? 1 : 0), as: UInt32.self)
    case kAudioFileStreamProperty_BitRate:
        ioPropertyDataSize?.pointee = 4
        let rate = UInt32(stream.format.mSampleRate) * stream.format.mBytesPerFrame * 8
        outPropertyData?.storeBytes(of: rate, as: UInt32.self)
    case kAudioFileStreamProperty_ChannelLayout:
        if let ioPropertyDataSize, ioPropertyDataSize.pointee < 12 {
            return kAudioFileStreamError_BadPropertySize
        }
        ioPropertyDataSize?.pointee = 12
        if let outPropertyData {
            atStoreChannelLayout(channels: stream.format.mChannelsPerFrame, to: outPropertyData)
        }
    default:
        return kAudioFileStreamError_UnsupportedProperty
    }
    return 0
}

public func AudioFileStreamSetProperty(
    _ inAudioFileStream: AudioFileStreamID?,
    _ inPropertyID: AudioFileStreamPropertyID,
    _ inPropertyDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    _ = inPropertyDataSize
    _ = inPropertyData
    guard ATRegistry.shared.lookup(inAudioFileStream, as: ATAudioFileStreamObject.self) != nil else {
        return kAudioFileStreamError_IllegalOperation
    }
    _ = inPropertyID
    return kAudioFileStreamError_UnsupportedProperty
}

public func AudioFileStreamSeek(
    _ inAudioFileStream: AudioFileStreamID?,
    _ inPacketOffset: Int64,
    _ outDataByteOffset: UnsafeMutablePointer<Int64>?,
    _ ioFlags: UnsafeMutablePointer<AudioFileStreamSeekFlags>?
) -> Int32 {
    guard let stream = ATRegistry.shared.lookup(inAudioFileStream, as: ATAudioFileStreamObject.self) else {
        return kAudioFileStreamError_IllegalOperation
    }
    if !stream.ready {
        return kAudioFileStreamError_DataUnavailable
    }
    let packetSize = Int64(max(stream.format.mBytesPerPacket, 1))
    let packets = Int64(stream.audio.count) / packetSize
    if inPacketOffset < 0 || inPacketOffset > packets {
        return kAudioFileStreamError_InvalidPacketOffset
    }
    outDataByteOffset?.pointee = stream.dataOffset + inPacketOffset * packetSize
    ioFlags?.pointee = []
    return 0
}

internal func atStoreChannelLayout(channels: UInt32, to pointer: UnsafeMutableRawPointer) {
    let tag: UInt32
    if channels == 1 {
        tag = (100 << 16) | 1
    } else if channels == 2 {
        tag = (101 << 16) | 2
    } else {
        tag = (147 << 16) | channels
    }
    pointer.storeBytes(of: tag, toByteOffset: 0, as: UInt32.self)
    pointer.storeBytes(of: UInt32(0), toByteOffset: 4, as: UInt32.self)
    pointer.storeBytes(of: UInt32(0), toByteOffset: 8, as: UInt32.self)
}
