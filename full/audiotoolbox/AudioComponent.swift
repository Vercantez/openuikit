import Foundation

public struct AudioComponentFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let unsearchable = AudioComponentFlags(rawValue: 1 << 0)
    public static let sandboxSafe = AudioComponentFlags(rawValue: 1 << 1)
    public static let isV3AudioUnit = AudioComponentFlags(rawValue: 1 << 2)
    public static let requiresAsyncInstantiation = AudioComponentFlags(rawValue: 1 << 3)
    public static let canLoadInProcess = AudioComponentFlags(rawValue: 1 << 4)
}

public struct AudioComponentInstantiationOptions: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let loadOutOfProcess = AudioComponentInstantiationOptions(rawValue: 1)
    public static let loadedRemotely = AudioComponentInstantiationOptions(rawValue: 1 << 31)
}

public enum AudioComponentValidationResult: UInt32, Sendable, Hashable {
    case unknown = 0
    case passed = 1
    case failed = 2
    case timedOut = 3
    case unauthorizedError_Open = 4
    case unauthorizedError_Init = 5
}

/// Component identity record. Field storage is `UInt32`, which is the C ABI of
/// Darwin `OSType`. This module does not redeclare `OSType`.
@frozen
public struct AudioComponentDescription: Equatable, Hashable, Sendable {
    public var componentType: UInt32
    public var componentSubType: UInt32
    public var componentManufacturer: UInt32
    public var componentFlags: UInt32
    public var componentFlagsMask: UInt32

    public init() {
        componentType = 0
        componentSubType = 0
        componentManufacturer = 0
        componentFlags = 0
        componentFlagsMask = 0
    }

    public init(
        componentType: UInt32,
        componentSubType: UInt32,
        componentManufacturer: UInt32,
        componentFlags: UInt32,
        componentFlagsMask: UInt32
    ) {
        self.componentType = componentType
        self.componentSubType = componentSubType
        self.componentManufacturer = componentManufacturer
        self.componentFlags = componentFlags
        self.componentFlagsMask = componentFlagsMask
    }
}

private final class ATAudioComponentRecord: ATObject {
    let description: AudioComponentDescription
    init(description: AudioComponentDescription) {
        self.description = description
    }
}

internal struct ATUnitConnection {
    var source: AudioUnit
    var sourceOutput: UInt32
}

internal final class ATAudioUnitObject: ATObject {
    let description: AudioComponentDescription
    var initialized = false
    var inputCount: UInt32 = 1
    var outputCount: UInt32 = 1
    var inputFormat = ATASBD.pcm(sampleRate: 44100, channels: 2, bits: 16, floating: false)
    var outputFormat = ATASBD.pcm(sampleRate: 44100, channels: 2, bits: 16, floating: false)
    var lastRenderError: Int32 = 0
    var maximumFrames: UInt32 = 4096
    var parameters: [UInt32: Float32] = [:]
    var scopedParameters: [UInt64: Float32] = [:]
    var connections: [UInt32: ATUnitConnection] = [:]
    var inputCallbacks: [UInt32: AURenderCallbackStruct] = [:]
    var renderCallback = AURenderCallbackStruct()
    var renderNotifies: [AURenderCallbackStruct] = [:]
    var sampleCounter: Int64 = 0

    func parameterKey(scope: AudioUnitScope, element: AudioUnitElement, id: AudioUnitParameterID) -> UInt64 {
        (UInt64(scope) << 48) | (UInt64(element) << 32) | UInt64(id)
    }

    func mixerGain(element: AudioUnitElement) -> Float {
        let enable = scopedParameters[parameterKey(scope: kAudioUnitScope_Input, element: element, id: kMultiChannelMixerParam_Enable)]
            ?? parameters[kMultiChannelMixerParam_Enable]
            ?? 1
        if enable <= 0 {
            return 0
        }
        return scopedParameters[parameterKey(scope: kAudioUnitScope_Input, element: element, id: kMultiChannelMixerParam_Volume)]
            ?? parameters[kMultiChannelMixerParam_Volume]
            ?? 1
    }

    func mixerPan(element: AudioUnitElement) -> Float {
        scopedParameters[parameterKey(scope: kAudioUnitScope_Input, element: element, id: kMultiChannelMixerParam_Pan)]
            ?? parameters[kMultiChannelMixerParam_Pan]
            ?? 0
    }

    var isRemoteIO: Bool {
        description.componentSubType == kAudioUnitSubType_RemoteIO
            || description.componentSubType == kAudioUnitSubType_VoiceProcessingIO
    }

    var isMixer: Bool {
        description.componentType == kAudioUnitType_Mixer
            || description.componentSubType == kAudioUnitSubType_MultiChannelMixer
            || description.componentSubType == kAudioUnitSubType_AUAudioMix
    }

    var isGenericOutput: Bool {
        description.componentSubType == kAudioUnitSubType_GenericOutput
    }

    var isGenerator: Bool {
        description.componentType == kAudioUnitType_Generator
            || description.componentSubType == kAudioUnitSubType_ScheduledSoundPlayer
    }

    init(description: AudioComponentDescription) {
        self.description = description
        if description.componentType == kAudioUnitType_Mixer
            || description.componentSubType == kAudioUnitSubType_MultiChannelMixer
            || description.componentSubType == kAudioUnitSubType_AUAudioMix
        {
            inputCount = 2
        }
    }
}

private let builtinComponents: [ATAudioComponentRecord] = {
    let specs: [(UInt32, UInt32)] = [
        (kAudioUnitType_Output, kAudioUnitSubType_GenericOutput),
        (kAudioUnitType_Mixer, kAudioUnitSubType_MultiChannelMixer),
        (kAudioUnitType_Generator, kAudioUnitSubType_ScheduledSoundPlayer),
        (kAudioUnitType_Output, kAudioUnitSubType_RemoteIO),
    ]
    return specs.map { type, subtype in
        ATAudioComponentRecord(
            description: AudioComponentDescription(
                componentType: type,
                componentSubType: subtype,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
        )
    }
}()

private func atComponentMatches(_ value: AudioComponentDescription, _ query: AudioComponentDescription) -> Bool {
    if query.componentType != 0 && query.componentType != value.componentType { return false }
    if query.componentSubType != 0 && query.componentSubType != value.componentSubType { return false }
    if query.componentManufacturer != 0 && query.componentManufacturer != value.componentManufacturer {
        return false
    }
    return true
}

private let instantiateGate = NSLock()
private var instantiateDepth = 0

public func AudioComponentCount(
    _ inDesc: UnsafePointer<AudioComponentDescription>?
) -> UInt32 {
    guard let inDesc else { return 0 }
    return UInt32(builtinComponents.filter { atComponentMatches($0.description, inDesc.pointee) }.count)
}

public func AudioComponentFindNext(
    _ inComponent: AudioComponent?,
    _ inDesc: UnsafePointer<AudioComponentDescription>?
) -> AudioComponent? {
    guard let inDesc else { return nil }
    let query = inDesc.pointee
    let matches = builtinComponents.filter { atComponentMatches($0.description, query) }
    if let inComponent,
       let current = ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self),
       let index = matches.firstIndex(where: { $0 === current })
    {
        let next = index + 1
        if next < matches.count {
            return ATRegistry.shared.retain(matches[next])
        }
        return nil
    }
    if let first = matches.first {
        return ATRegistry.shared.retain(first)
    }
    return nil
}

@_cdecl("AudioComponentInstanceNew")
public func AudioComponentInstanceNew(
    _ inComponent: AudioComponent?,
    _ outInstance: UnsafeMutablePointer<AudioComponentInstance?>?
) -> Int32 {
    outInstance?.pointee = nil
    guard let record = ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self) else {
        return kAudioComponentErr_UnsupportedType
    }
    let unit = ATAudioUnitObject(description: record.description)
    if unit.isMixer {
        unit.inputCount = 2
    }
    outInstance?.pointee = ATRegistry.shared.retain(unit)
    return 0
}

@_cdecl("AudioComponentInstanceDispose")
public func AudioComponentInstanceDispose(
    _ inInstance: AudioComponentInstance?
) -> Int32 {
    let status = ATRegistry.shared.release(inInstance)
    if status == atParamError {
        return 0
    }
    return status
}

public func AudioComponentGetDescription(
    _ inComponent: AudioComponent?,
    _ outDesc: UnsafeMutablePointer<AudioComponentDescription>?
) -> Int32 {
    guard let record = ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self) else {
        return kAudioComponentErr_InstanceInvalidated
    }
    outDesc?.pointee = record.description
    return 0
}

@_cdecl("AudioComponentGetVersion")
public func AudioComponentGetVersion(
    _ inComponent: AudioComponent?,
    _ outVersion: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self) != nil else {
        return kAudioComponentErr_InstanceInvalidated
    }
    outVersion?.pointee = 0
    return 0
}

@_cdecl("AudioComponentInstanceGetComponent")
public func AudioComponentInstanceGetComponent(
    _ inInstance: AudioComponentInstance?
) -> AudioComponent {
    if let unit = ATRegistry.shared.lookup(inInstance, as: ATAudioUnitObject.self) {
        var description = unit.description
        return AudioComponentFindNext(nil, &description) ?? AudioComponent(bitPattern: 1)!
    }
    return AudioComponent(bitPattern: 1)!
}

public func AudioComponentInstanceCanDo(
    _ inInstance: AudioComponentInstance?,
    _ inSelectorID: Int16
) -> Bool {
    _ = inSelectorID
    return ATRegistry.shared.lookup(inInstance, as: ATAudioUnitObject.self) != nil
}

public func AudioComponentInstantiate(
    _ inComponent: AudioComponent?,
    _ inOptions: AudioComponentInstantiationOptions,
    _ inCompletionHandler: @escaping (AudioComponentInstance?, Int32) -> Void
) {
    _ = inOptions
    var shouldCall = true
    atWithLock(instantiateGate) {
        instantiateDepth += 1
        if instantiateDepth > 8 {
            shouldCall = false
        }
    }
    defer {
        atWithLock(instantiateGate) {
            instantiateDepth -= 1
        }
    }
    _ = inComponent
    if shouldCall {
        inCompletionHandler(nil, kAudioComponentErr_UnsupportedType)
    }
}

#if canImport(CoreFoundation)
import CoreFoundation

@_cdecl("AudioComponentCopyName")
public func AudioComponentCopyName(
    _ inComponent: AudioComponent?,
    _ outName: UnsafeMutablePointer<Unmanaged<CFString>?>?
) -> Int32 {
    outName?.pointee = nil
    guard ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self) != nil else {
        return kAudioComponentErr_InstanceInvalidated
    }
    return kAudioComponentErr_UnsupportedType
}

public func AudioComponentRegister(
    _ inDesc: UnsafePointer<AudioComponentDescription>?,
    _ inName: CFString?,
    _ inVersion: UInt32,
    _ inFactory: AudioComponentFactoryFunction?
) -> AudioComponent? {
    _ = inDesc
    _ = inName
    _ = inVersion
    _ = inFactory
    return nil
}

public func AudioComponentValidate(
    _ inComponent: AudioComponent?,
    _ inValidationParameters: CFDictionary?,
    _ outValidationResult: UnsafeMutablePointer<AudioComponentValidationResult>?
) -> Int32 {
    _ = inComponent
    _ = inValidationParameters
    outValidationResult?.pointee = .failed
    return kAudioComponentErr_NotPermitted
}
#endif

public typealias AudioComponentFactoryFunction = (
    UnsafePointer<AudioComponentDescription>
) -> UnsafeMutablePointer<AudioComponentPlugInInterface>?

public struct AudioComponentPlugInInterface {
    public var Open: ((UnsafeMutableRawPointer, AudioComponentInstance) -> Int32)?
    public var Close: ((UnsafeMutableRawPointer) -> Int32)?
    public var Lookup: ((Int16) -> AudioComponentMethod?)?
    public var reserved: UnsafeMutableRawPointer?

    public init(
        Open: ((UnsafeMutableRawPointer, AudioComponentInstance) -> Int32)?,
        Close: ((UnsafeMutableRawPointer) -> Int32)?,
        Lookup: ((Int16) -> AudioComponentMethod?)?,
        reserved: UnsafeMutableRawPointer?
    ) {
        self.Open = Open
        self.Close = Close
        self.Lookup = Lookup
        self.reserved = reserved
    }
}
