import Dispatch
import Foundation

// MARK: - Fail-closed HAL (hardware / Apple audio server)
//
// The 20-app corpus (Home Assistant iOS) talks to CoreAudio through
// AudioObjectGetPropertyData on kAudioObjectSystemObject. Linux has no Apple
// HAL, Core Audio server, or device graph, so every query fails closed with
// kAudioHardwareUnsupportedOperationError and never invents a device list.

public typealias AudioObjectID = UInt32
public typealias AudioDeviceID = AudioObjectID
public typealias AudioObjectPropertySelector = UInt32
public typealias AudioObjectPropertyScope = UInt32
public typealias AudioObjectPropertyElement = UInt32

public let kAudioObjectUnknown: AudioObjectID = 0
public let kAudioObjectSystemObject: AudioObjectID = 1
public let kAudioObjectPropertyScopeGlobal: AudioObjectPropertyScope = 0x676C6F62 // 'glob'
public let kAudioObjectPropertyScopeInput: AudioObjectPropertyScope = 0x696E7074 // 'inpt'
public let kAudioObjectPropertyScopeOutput: AudioObjectPropertyScope = 0x6F757470 // 'outp'
public let kAudioObjectPropertyElementMain: AudioObjectPropertyElement = 0
public let kAudioHardwarePropertyDevices: AudioObjectPropertySelector = 0x64657623 // 'dev#'
public let kAudioHardwarePropertyDefaultInputDevice: AudioObjectPropertySelector = 0x64496E23 // 'dIn#'
public let kAudioHardwarePropertyDefaultOutputDevice: AudioObjectPropertySelector = 0x644F7574 // 'dOut'

public struct AudioObjectPropertyAddress: Equatable, Sendable {
    public var mSelector: AudioObjectPropertySelector
    public var mScope: AudioObjectPropertyScope
    public var mElement: AudioObjectPropertyElement

    public init(
        mSelector: AudioObjectPropertySelector,
        mScope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
        mElement: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) {
        self.mSelector = mSelector
        self.mScope = mScope
        self.mElement = mElement
    }
}

/// Linux has no Apple HAL / Core Audio server. Property queries fail closed.
public enum CoreAudioHardware {
    public static let isAvailable = false
}

public func AudioObjectHasProperty(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>
) -> Bool {
    _ = inObjectID
    _ = inAddress
    return false
}

public func AudioObjectIsPropertySettable(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
    _ outIsSettable: UnsafeMutablePointer<DarwinBoolean>
) -> OSStatus {
    _ = inObjectID
    _ = inAddress
    outIsSettable.pointee = DarwinBoolean(false)
    return kAudioHardwareUnsupportedOperationError
}

public func AudioObjectGetPropertyDataSize(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
    _ inQualifierDataSize: UInt32,
    _ inQualifierData: UnsafeRawPointer?,
    _ outDataSize: UnsafeMutablePointer<UInt32>
) -> OSStatus {
    _ = inObjectID
    _ = inAddress
    _ = inQualifierDataSize
    _ = inQualifierData
    outDataSize.pointee = 0
    return kAudioHardwareUnsupportedOperationError
}

public func AudioObjectGetPropertyData(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
    _ inQualifierDataSize: UInt32,
    _ inQualifierData: UnsafeRawPointer?,
    _ ioDataSize: UnsafeMutablePointer<UInt32>,
    _ outData: UnsafeMutableRawPointer
) -> OSStatus {
    _ = inObjectID
    _ = inAddress
    _ = inQualifierDataSize
    _ = inQualifierData
    _ = outData
    ioDataSize.pointee = 0
    return kAudioHardwareUnsupportedOperationError
}

public func AudioObjectSetPropertyData(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
    _ inQualifierDataSize: UInt32,
    _ inQualifierData: UnsafeRawPointer?,
    _ inDataSize: UInt32,
    _ inData: UnsafeRawPointer
) -> OSStatus {
    _ = inObjectID
    _ = inAddress
    _ = inQualifierDataSize
    _ = inQualifierData
    _ = inDataSize
    _ = inData
    return kAudioHardwareUnsupportedOperationError
}

public func AudioObjectAddPropertyListener(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
    _ inListener: AudioObjectPropertyListenerProc,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    _ = inObjectID
    _ = inAddress
    _ = inListener
    _ = inClientData
    return kAudioHardwareUnsupportedOperationError
}

public func AudioObjectRemovePropertyListener(
    _ inObjectID: AudioObjectID,
    _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
    _ inListener: AudioObjectPropertyListenerProc,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    _ = inObjectID
    _ = inAddress
    _ = inListener
    _ = inClientData
    return kAudioHardwareUnsupportedOperationError
}

public typealias AudioObjectPropertyListenerProc = (
    AudioObjectID,
    UInt32,
    UnsafePointer<AudioObjectPropertyAddress>,
    UnsafeMutableRawPointer?
) -> OSStatus

/// `DarwinBoolean` stand-in used by imported HAL C APIs on Apple platforms.
public struct DarwinBoolean: ExpressibleByBooleanLiteral, Equatable, Sendable {
    public var boolValue: Bool

    public init(_ value: Bool) {
        self.boolValue = value
    }

    public init(booleanLiteral value: Bool) {
        self.boolValue = value
    }
}

public func AudioGetCurrentHostTime() -> UInt64 {
    // Linux host time is nanoseconds of `DispatchTime` uptime, not Darwin's
    // mach_absolute_time. Conversion functions are therefore identity.
    DispatchTime.now().uptimeNanoseconds
}

public func AudioConvertHostTimeToNanos(_ inHostTime: UInt64) -> UInt64 {
    inHostTime
}

public func AudioConvertNanosToHostTime(_ inNanos: UInt64) -> UInt64 {
    inNanos
}

public func AudioGetHostClockFrequency() -> Float64 {
    1_000_000_000
}

public func AudioGetHostClockMinimumTimeDelta() -> UInt32 {
    1
}

public func AudioObjectExists(_ inObjectID: AudioObjectID) -> Bool {
    _ = inObjectID
    return false
}
