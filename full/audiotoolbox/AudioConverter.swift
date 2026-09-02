#if canImport(CoreAudioTypes)
import CoreAudioTypes
#endif
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
    var primed = false
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

@_cdecl("AudioConverterGetPropertyInfo")
public func AudioConverterGetPropertyInfo(
    _ inAudioConverter: AudioConverterRef?,
    _ inPropertyID: AudioConverterPropertyID,
    _ outSize: UnsafeMutablePointer<UInt32>?,
    _ outWritable: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    _ = inPropertyID
    guard ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) != nil else {
        return kAudioConverterErr_UnspecifiedError
    }
    outSize?.pointee = 0
    outWritable?.pointee = 0
    return kAudioConverterErr_PropertyNotSupported
}

@_cdecl("AudioConverterGetProperty")
public func AudioConverterGetProperty(
    _ inAudioConverter: AudioConverterRef?,
    _ inPropertyID: AudioConverterPropertyID,
    _ ioPropertyDataSize: UnsafeMutablePointer<UInt32>?,
    _ outPropertyData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inPropertyID
    _ = ioPropertyDataSize
    _ = outPropertyData
    guard ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) != nil else {
        return kAudioConverterErr_UnspecifiedError
    }
    return kAudioConverterErr_PropertyNotSupported
}

@_cdecl("AudioConverterSetProperty")
public func AudioConverterSetProperty(
    _ inAudioConverter: AudioConverterRef?,
    _ inPropertyID: AudioConverterPropertyID,
    _ inPropertyDataSize: UInt32,
    _ inPropertyData: UnsafeRawPointer?
) -> Int32 {
    _ = inPropertyID
    _ = inPropertyDataSize
    _ = inPropertyData
    guard ATRegistry.shared.lookup(inAudioConverter, as: ATAudioConverterObject.self) != nil else {
        return kAudioConverterErr_UnspecifiedError
    }
    return kAudioConverterErr_PropertyNotSupported
}

#if canImport(CoreAudioTypes)
public func AudioConverterNew(
    _ inSourceFormat: UnsafePointer<AudioStreamBasicDescription>,
    _ inDestinationFormat: UnsafePointer<AudioStreamBasicDescription>,
    _ outAudioConverter: UnsafeMutablePointer<AudioConverterRef?>
) -> Int32 {
    _ = inSourceFormat
    _ = inDestinationFormat
    outAudioConverter.pointee = nil
    return kAudioConverterErr_FormatNotSupported
}

public func AudioConverterNewWithOptions(
    _ inSourceFormat: UnsafePointer<AudioStreamBasicDescription>,
    _ inDestinationFormat: UnsafePointer<AudioStreamBasicDescription>,
    _ inOptions: AudioConverterOptions,
    _ outAudioConverter: UnsafeMutablePointer<AudioConverterRef?>
) -> Int32 {
    _ = inOptions
    return AudioConverterNew(inSourceFormat, inDestinationFormat, outAudioConverter)
}
#endif
