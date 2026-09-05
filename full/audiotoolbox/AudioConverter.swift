import Foundation

public struct AudioConverterOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

@frozen
public struct AudioConverterPrimeInfo: Equatable, Hashable, Sendable {
    public var leadingFrames: UInt32
    public var trailingFrames: UInt32

    public init() {
        leadingFrames = 0
        trailingFrames = 0
    }

    public init(leadingFrames: UInt32, trailingFrames: UInt32) {
        self.leadingFrames = leadingFrames
        self.trailingFrames = trailingFrames
    }
}

internal final class ATAudioConverterObject: ATObject {
    var source: ATASBD
    var dest: ATASBD
    var primed = false
    var channelMap: [Int32] = []
    var sampleRateComplexity: UInt32 = kAudioConverterSampleRateConverterComplexity_Linear

    init(source: ATASBD, dest: ATASBD) {
        self.source = source
        self.dest = dest
    }
}

public func AudioConverterNew(
    _ inSourceFormat: UnsafeRawPointer?,
    _ inDestinationFormat: UnsafeRawPointer?,
    _ outAudioConverter: UnsafeMutablePointer<AudioConverterRef?>?
) -> Int32 {
    outAudioConverter?.pointee = nil
    guard let inSourceFormat, let inDestinationFormat else {
        return kAudioConverterErr_UnspecifiedError
    }
    guard var source = atLoadASBD(inSourceFormat), var dest = atLoadASBD(inDestinationFormat) else {
        return kAudioConverterErr_UnspecifiedError
    }
    if source.mFormatID != atFormatLinearPCM || dest.mFormatID != atFormatLinearPCM {
        return kAudioConverterErr_FormatNotSupported
    }
    let sourceStatus = source.validatePCM()
    if sourceStatus != 0 {
        return kAudioConverterErr_FormatNotSupported
    }
    let destStatus = dest.validatePCM()
    if destStatus != 0 {
        return kAudioConverterErr_FormatNotSupported
    }
    atFillPCMASBD(&source)
    atFillPCMASBD(&dest)
    let converter = ATAudioConverterObject(source: source, dest: dest)
    outAudioConverter?.pointee = ATRegistry.shared.retain(converter)
    return 0
}

public func AudioConverterNewWithOptions(
    _ inSourceFormat: UnsafeRawPointer?,
    _ inDestinationFormat: UnsafeRawPointer?,
    _ inOptions: AudioConverterOptions,
    _ outAudioConverter: UnsafeMutablePointer<AudioConverterRef?>?
) -> Int32 {
    _ = inOptions
    return AudioConverterNew(inSourceFormat, inDestinationFormat, outAudioConverter)
}

@_cdecl("AudioConverterDispose")
public func AudioConverterDispose(_ inAudioConverter: AudioConverterRef?) -> Int32 {
    let status = ATRegistry.shared.release(inAudioConverter)
    return status == atParamError ? 0 : status
}

@_cdecl("AudioConverterReset")
public func AudioConverterReset(_ inAudioConverter: AudioConverterRef?) -> Int32 {
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    converter.primed = false
    return 0
}

public func AudioConverterConvertBuffer(
    _ inAudioConverter: AudioConverterRef?,
    _ inInputDataSize: UInt32,
    _ inInputData: UnsafeRawPointer?,
    _ ioOutputDataSize: UnsafeMutablePointer<UInt32>?,
    _ outOutputData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    guard let inInputData, let ioOutputDataSize, let outOutputData else {
        return kAudioConverterErr_UnspecifiedError
    }
    let result = atConvertPCM(
        source: converter.source,
        dest: converter.dest,
        input: inInputData,
        inputByteCount: Int(inInputDataSize),
        output: outOutputData,
        outputByteCapacity: Int(ioOutputDataSize.pointee),
        channelMap: converter.channelMap.isEmpty ? nil : converter.channelMap
    )
    if result.status == 0 {
        ioOutputDataSize.pointee = UInt32(result.outputBytes)
    }
    return result.status
}

@_cdecl("AudioConverterGetPropertyInfo")
public func AudioConverterGetPropertyInfo(
    _ inAudioConverter: AudioConverterRef?,
    _ inPropertyID: AudioConverterPropertyID,
    _ outSize: UnsafeMutablePointer<UInt32>?,
    _ outWritable: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    switch inPropertyID {
    case kAudioConverterCurrentInputStreamDescription, kAudioConverterCurrentOutputStreamDescription:
        outSize?.pointee = UInt32(atASBDSize)
        outWritable?.pointee = 0
        return 0
    case kAudioConverterChannelMap:
        outSize?.pointee = UInt32(max(converter.channelMap.count, Int(converter.dest.mChannelsPerFrame)) * 4)
        outWritable?.pointee = 1
        return 0
    case kAudioConverterPropertyMinimumInputBufferSize, kAudioConverterPropertyMinimumOutputBufferSize,
         kAudioConverterPropertyMaximumInputPacketSize, kAudioConverterPropertyMaximumOutputPacketSize,
         kAudioConverterSampleRateConverterComplexity, kAudioConverterSampleRateConverterQuality:
        outSize?.pointee = 4
        outWritable?.pointee = inPropertyID == kAudioConverterSampleRateConverterComplexity ? 1 : 0
        return 0
    default:
        outSize?.pointee = 0
        outWritable?.pointee = 0
        return kAudioConverterErr_PropertyNotSupported
    }
}

@_cdecl("AudioConverterGetProperty")
public func AudioConverterGetProperty(
    _ inAudioConverter: AudioConverterRef?,
    _ inPropertyID: AudioConverterPropertyID,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    switch inPropertyID {
    case kAudioConverterCurrentInputStreamDescription:
        guard let ioPropertyDataSize, ioPropertyDataSize.pointee >= UInt32(atASBDSize) else {
            return kAudioConverterErr_BadPropertySizeError
        }
        ioPropertyDataSize.pointee = UInt32(atASBDSize)
        if let outPropertyData {
            atStoreASBD(converter.source, to: outPropertyData)
        }
        return 0
    case kAudioConverterCurrentOutputStreamDescription:
        guard let ioPropertyDataSize, ioPropertyDataSize.pointee >= UInt32(atASBDSize) else {
            return kAudioConverterErr_BadPropertySizeError
        }
        ioPropertyDataSize.pointee = UInt32(atASBDSize)
        if let outPropertyData {
            atStoreASBD(converter.dest, to: outPropertyData)
        }
        return 0
    case kAudioConverterChannelMap:
        let count = converter.channelMap.isEmpty ? Int(converter.dest.mChannelsPerFrame) : converter.channelMap.count
        let bytes = UInt32(count * 4)
        guard let ioPropertyDataSize, ioPropertyDataSize.pointee >= bytes else {
            return kAudioConverterErr_BadPropertySizeError
        }
        ioPropertyDataSize.pointee = bytes
        if let outPropertyData {
            if converter.channelMap.isEmpty {
                for index in 0..<count {
                    outPropertyData.storeBytes(of: Int32(index), toByteOffset: index * 4, as: Int32.self)
                }
            } else {
                for (index, value) in converter.channelMap.enumerated() {
                    outPropertyData.storeBytes(of: value, toByteOffset: index * 4, as: Int32.self)
                }
            }
        }
        return 0
    case kAudioConverterSampleRateConverterComplexity:
        guard let ioPropertyDataSize, ioPropertyDataSize.pointee >= 4 else {
            return kAudioConverterErr_BadPropertySizeError
        }
        ioPropertyDataSize.pointee = 4
        outPropertyData?.storeBytes(of: converter.sampleRateComplexity, as: UInt32.self)
        return 0
    default:
        return kAudioConverterErr_PropertyNotSupported
    }
}

public func AudioConverterFillComplexBuffer(
    _ inAudioConverter: AudioConverterRef?,
    _ inInputDataProc: AudioConverterComplexInputDataProc?,
    _ inInputDataProcUserData: UnsafeMutableRawPointer?,
    _ ioOutputDataPacketSize: UnsafeMutablePointer<UInt32>?,
    _ outOutputData: UnsafeMutableRawPointer?,
    _ outPacketDescription: UnsafeMutableRawPointer?
) -> Int32 {
    _ = outPacketDescription
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    guard let inInputDataProc, let ioOutputDataPacketSize, let outOutputData else {
        return kAudioConverterErr_UnspecifiedError
    }
    let destPackets = Int(ioOutputDataPacketSize.pointee)
    if destPackets <= 0 {
        return 0
    }
    let destFrames = destPackets
    let srcEstimate = atLinearInterpolateFrameCount(
        sourceFrames: max(destFrames, 2),
        sourceRate: converter.dest.mSampleRate,
        destRate: converter.source.mSampleRate
    )
    let sourceFrames = max(srcEstimate, destFrames)
    let sourceByteCount = sourceFrames * converter.source.bytesPerSample
        * converter.source.frameCountChannels
    var sourceStorage = [UInt8](repeating: 0, count: max(sourceByteCount, 1))
    var packetDescSlot: UnsafeMutableRawPointer? = nil
    var providedPackets = UInt32(sourceFrames)
    var abl = [UInt8](repeating: 0, count: 24)
    let status = sourceStorage.withUnsafeMutableBytes { storage in
        abl.withUnsafeMutableBytes { raw in
            raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: converter.source.mChannelsPerFrame, toByteOffset: 8, as: UInt32.self)
            raw.baseAddress!.storeBytes(of: UInt32(storage.count), toByteOffset: 12, as: UInt32.self)
            raw.baseAddress!.storeBytes(
                of: UInt(bitPattern: storage.baseAddress),
                toByteOffset: 16,
                as: UInt.self
            )
            return inInputDataProc(
                inAudioConverter!,
                &providedPackets,
                raw.baseAddress!,
                &packetDescSlot,
                inInputDataProcUserData
            )
        }
    }
    if status != 0 {
        ioOutputDataPacketSize.pointee = 0
        return status
    }
    if providedPackets == 0 {
        ioOutputDataPacketSize.pointee = 0
        return 0
    }
    guard let outputList = atLoadBufferList(outOutputData),
          let destBuffer = outputList.buffers.first,
          let destPtr = destBuffer.data
    else {
        return kAudioConverterErr_InvalidOutputSize
    }
    let inputByteCount = min(
        sourceStorage.count,
        Int(providedPackets) * converter.source.bytesPerSample * converter.source.frameCountChannels
    )
    let result = sourceStorage.withUnsafeBytes { src in
        atConvertPCM(
            source: converter.source,
            dest: converter.dest,
            input: src.baseAddress!,
            inputByteCount: inputByteCount,
            output: destPtr,
            outputByteCapacity: Int(destBuffer.dataByteSize),
            channelMap: converter.channelMap.isEmpty ? nil : converter.channelMap
        )
    }
    if result.status != 0 {
        ioOutputDataPacketSize.pointee = 0
        return result.status
    }
    let destWidth = converter.dest.bytesPerSample * converter.dest.frameCountChannels
    ioOutputDataPacketSize.pointee = destWidth == 0 ? 0 : UInt32(result.outputBytes / max(destWidth, 1))
    return 0
}

public func AudioConverterConvertComplexBuffer(
    _ inAudioConverter: AudioConverterRef?,
    _ inNumberPCMFrames: UInt32,
    _ inInputData: UnsafeRawPointer?,
    _ outOutputData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    guard let inInputData, let outOutputData, let inputList = atLoadBufferList(inInputData),
          let outputList = atLoadBufferList(outOutputData),
          let inputBuffer = inputList.buffers.first, let outputBuffer = outputList.buffers.first,
          let inputPtr = inputBuffer.data, let destPtr = outputBuffer.data
    else {
        return kAudioConverterErr_UnspecifiedError
    }
    let inputBytes = min(
        Int(inputBuffer.dataByteSize),
        Int(inNumberPCMFrames) * converter.source.bytesPerSample * converter.source.frameCountChannels
    )
    let result = atConvertPCM(
        source: converter.source,
        dest: converter.dest,
        input: inputPtr,
        inputByteCount: inputBytes,
        output: destPtr,
        outputByteCapacity: Int(outputBuffer.dataByteSize),
        channelMap: converter.channelMap.isEmpty ? nil : converter.channelMap
    )
    return result.status
}

@_cdecl("AudioConverterSetProperty")
public func AudioConverterSetProperty(
    _ inAudioConverter: AudioConverterRef?,
    _ inPropertyID: AudioConverterPropertyID,
    _ inPropertyDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    guard let converter = ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) else {
        return kAudioConverterErr_UnspecifiedError
    }
    if inPropertyID == kAudioConverterChannelMap {
        guard let inPropertyData, inPropertyDataSize >= 4 else {
            return kAudioConverterErr_BadPropertySizeError
        }
        let count = Int(inPropertyDataSize / 4)
        converter.channelMap = (0..<count).map { index in
            inPropertyData.loadUnaligned(fromByteOffset: index * 4, as: Int32.self)
        }
        return 0
    }
    if inPropertyID == kAudioConverterSampleRateConverterComplexity {
        guard let inPropertyData, inPropertyDataSize >= 4 else {
            return kAudioConverterErr_BadPropertySizeError
        }
        converter.sampleRateComplexity = inPropertyData.loadUnaligned(as: UInt32.self)
        return 0
    }
    return kAudioConverterErr_PropertyNotSupported
}
