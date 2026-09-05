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
         kAudioConverterPropertyMaximumInputPacketSize, kAudioConverterPropertyMaximumOutputPacketSize:
        outSize?.pointee = 4
        outWritable?.pointee = 0
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
    default:
        return kAudioConverterErr_PropertyNotSupported
    }
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
    return kAudioConverterErr_PropertyNotSupported
}
