import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

// Wave-12 depth pass: offline-invokable remainder of the AudioToolbox census.
// Everything here runs in-process without hardware, daemons, or services.
// Apple-oracle pins (Xcode 26.1, pinned iPhoneOS 26.1 SDK, `xcrun swiftc`
// probes) are noted per item; unobserved behavior stays fail-closed and is
// recorded in oracle-questions.tsv instead of guessed.

// MARK: - Oracle-pinned version, preset, and VoiceIO property constants

/// Pinned via macOS probe: AUDIO_TOOLBOX_VERSION=1060.
public let AUDIO_TOOLBOX_VERSION: Int32 = 1060
/// Pinned via macOS probe: AUDIO_UNIT_VERSION=1070.
public let AUDIO_UNIT_VERSION: Int32 = 1070
/// Pinned via macOS probe: AU_SUPPORT_INTERAPP_AUDIO=1.
public let AU_SUPPORT_INTERAPP_AUDIO: Int32 = 1
/// Pinned via macOS probe: "preset-number".
public let kAUPresetNumberKey: String = "preset-number"
/// Pinned from the pinned iPhoneOS 26.1 SDK header (AudioUnitProperties.h):
/// `kAUVoiceIOProperty_DuckNonVoiceAudio = 2102` (iOS-only, deprecated).
public let kAUVoiceIOProperty_DuckNonVoiceAudio: AudioUnitPropertyID = 2102
/// Pinned from the pinned iPhoneOS 26.1 SDK header:
/// `kAUVoiceIOProperty_OtherAudioDuckingConfiguration = 2108`.
public let kAUVoiceIOProperty_OtherAudioDuckingConfiguration: AudioUnitPropertyID = 2108
/// Pinned from the pinned iPhoneOS 26.1 SDK header:
/// `kAUVoiceIOProperty_VoiceProcessingQuality = 2103` (deprecated).
public let kAUVoiceIOProperty_VoiceProcessingQuality: AudioUnitPropertyID = 2103

#if canImport(CoreFoundation)
/// Pinned via macOS probe: "com.apple.coreaudio.AudioComponentInstanceInvalidated".
public let kAudioComponentInstanceInvalidationNotification: CFString =
    "com.apple.coreaudio.AudioComponentInstanceInvalidated" as CFString
/// Pinned via macOS probe: "com.apple.coreaudio.AudioComponentRegistrationsChanged".
public let kAudioComponentRegistrationsChangedNotification: CFString =
    "com.apple.coreaudio.AudioComponentRegistrationsChanged" as CFString
#endif

// MARK: - AudioUnitEvent (flattened C-union overlay)

// The C `mArgument` union has no Swift spelling on Linux, so the offline
// overlay flattens it to the parameter payload, matching the house precedent
// set by `AudioUnitParameterEvent` / `AudioUnitParameterEventValues`.
@frozen
public struct AudioUnitEvent: Equatable, Hashable, Sendable {
    public struct __Unnamed_union_mArgument: Equatable, Hashable, Sendable {
        public var parameter: AudioUnitParameter

        public init() {
            parameter = AudioUnitParameter()
        }

        public init(parameter: AudioUnitParameter) {
            self.parameter = parameter
        }
    }

    public var mEventType: AudioUnitEventType
    public var mArgument: __Unnamed_union_mArgument

    public init() {
        mEventType = .parameterValueChange
        mArgument = __Unnamed_union_mArgument()
    }

    public init(mEventType: AudioUnitEventType, mArgument: __Unnamed_union_mArgument) {
        self.mEventType = mEventType
        self.mArgument = mArgument
    }
}

// MARK: - AU listener callback types

// NOTE: these two listener procs are plain Swift closures rather than
// `@convention(c)`: their event/parameter pointer targets are Swift-native
// value types, which Swift 6 does not admit in `@convention(c)` signatures.
// The Create functions below therefore take escaping Swift closures; no C
// function-pointer interop is claimed for the v1 listener path.
public typealias AUEventListenerProc = (
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    UnsafePointer<AudioUnitEvent>,
    UInt64,
    AudioUnitParameterValue
) -> Void

public typealias AUEventListenerBlock = (
    UnsafeMutableRawPointer?,
    UnsafePointer<AudioUnitEvent>,
    UInt64,
    AudioUnitParameterValue
) -> Void

public typealias AUParameterListenerProc = (
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    UnsafePointer<AudioUnitParameter>,
    AudioUnitParameterValue
) -> Void

public typealias AUParameterListenerBlock = (
    UnsafeMutableRawPointer?,
    UnsafePointer<AudioUnitParameter>,
    AudioUnitParameterValue
) -> Void

// MARK: - In-process AU listener registry

internal struct ATWave12ParameterRegistration: @unchecked Sendable {
    var object: UnsafeMutableRawPointer?
    var unit: AudioUnit?
    var parameterID: AudioUnitParameterID
    var scope: AudioUnitScope
    var element: AudioUnitElement
}

internal struct ATWave12EventRegistration: @unchecked Sendable {
    var object: UnsafeMutableRawPointer?
    var eventType: AudioUnitEventType
}

internal final class ATWave12ParameterListener: ATObject {
    var proc: AUParameterListenerProc?
    var userData: UnsafeMutableRawPointer?
    var registrations: [ATWave12ParameterRegistration] = []
}

internal final class ATWave12EventListener: ATObject {
    var proc: AUEventListenerProc?
    var userData: UnsafeMutableRawPointer?
    var registrations: [ATWave12EventRegistration] = []
}

private let atWave12ListenerLock = NSLock()
private var atWave12ParameterListeners: [OpaquePointer: ATWave12ParameterListener] = [:]
private var atWave12EventListeners: [OpaquePointer: ATWave12EventListener] = [:]

internal func atWave12CurrentParameterValue(_ parameter: AudioUnitParameter) -> AudioUnitParameterValue {
    var value: AudioUnitParameterValue = 0
    if AudioUnitGetParameter(
        parameter.mAudioUnit,
        parameter.mParameterID,
        parameter.mScope,
        parameter.mElement,
        &value
    ) == 0 {
        return value
    }
    return 0
}

internal func atWave12NotifyParameterListeners(
    sending: AUParameterListenerRef?,
    object: UnsafeMutableRawPointer?,
    parameter: AudioUnitParameter,
    value: AudioUnitParameterValue
) {
    let targets: [(proc: AUParameterListenerProc, userData: UnsafeMutableRawPointer?)] = atWithLock(
        atWave12ListenerLock
    ) {
        var result: [(AUParameterListenerProc, UnsafeMutableRawPointer?)] = []
        for (ref, listener) in atWave12ParameterListeners {
            if let sending, sending == ref {
                continue
            }
            guard let proc = listener.proc else {
                continue
            }
            let matches = listener.registrations.contains { registration in
                let objectMatches = registration.object == nil || registration.object == object
                return objectMatches
                    && registration.unit == parameter.mAudioUnit
                    && registration.parameterID == parameter.mParameterID
                    && registration.scope == parameter.mScope
                    && registration.element == parameter.mElement
            }
            if matches {
                result.append((proc, listener.userData))
            }
        }
        return result
    }
    for target in targets {
        var snapshot = parameter
        withUnsafePointer(to: &snapshot) { pointer in
            target.proc(target.userData, object, pointer, value)
        }
    }
}

#if canImport(CoreFoundation)
public func AUListenerCreate(
    _ inProc: AUParameterListenerProc?,
    _ inUserData: UnsafeMutableRawPointer,
    _ inRunLoop: CFRunLoop?,
    _ inRunLoopMode: CFString?,
    _ inNotificationInterval: Float32,
    _ outListener: UnsafeMutablePointer<AUParameterListenerRef?>?
) -> Int32 {
    _ = inRunLoop
    _ = inRunLoopMode
    _ = inNotificationInterval
    guard let outListener, let inProc else {
        return atParamError
    }
    let listener = ATWave12ParameterListener()
    listener.proc = inProc
    listener.userData = inUserData
    let ref = ATRegistry.shared.retain(listener)
    atWithLock(atWave12ListenerLock) {
        atWave12ParameterListeners[ref] = listener
    }
    outListener.pointee = ref
    return 0
}
#endif

public func AUListenerDispose(_ inListener: AUParameterListenerRef?) -> Int32 {
    guard let inListener else {
        return atParamError
    }
    let removed: Bool = atWithLock(atWave12ListenerLock) {
        if atWave12ParameterListeners.removeValue(forKey: inListener) != nil {
            return true
        }
        if atWave12EventListeners.removeValue(forKey: inListener) != nil {
            return true
        }
        return false
    }
    if !removed {
        return atParamError
    }
    let status = ATRegistry.shared.release(inListener)
    return status == atParamError ? 0 : status
}

public func AUListenerAddParameter(
    _ inListener: AUParameterListenerRef?,
    _ inObject: UnsafeMutableRawPointer?,
    _ inParameter: UnsafePointer<AudioUnitParameter>?
) -> Int32 {
    guard let inListener, let inParameter else {
        return atParamError
    }
    return atWithLock(atWave12ListenerLock) {
        guard let listener = atWave12ParameterListeners[inListener] else {
            return atParamError
        }
        let parameter = inParameter.pointee
        listener.registrations.append(
            ATWave12ParameterRegistration(
                object: inObject,
                unit: parameter.mAudioUnit,
                parameterID: parameter.mParameterID,
                scope: parameter.mScope,
                element: parameter.mElement
            )
        )
        return 0
    }
}

public func AUListenerRemoveParameter(
    _ inListener: AUParameterListenerRef?,
    _ inObject: UnsafeMutableRawPointer?,
    _ inParameter: UnsafePointer<AudioUnitParameter>?
) -> Int32 {
    guard let inListener, let inParameter else {
        return atParamError
    }
    return atWithLock(atWave12ListenerLock) {
        guard let listener = atWave12ParameterListeners[inListener] else {
            return atParamError
        }
        let parameter = inParameter.pointee
        let before = listener.registrations.count
        listener.registrations.removeAll { registration in
            registration.object == inObject
                && registration.unit == parameter.mAudioUnit
                && registration.parameterID == parameter.mParameterID
                && registration.scope == parameter.mScope
                && registration.element == parameter.mElement
        }
        return listener.registrations.count == before ? atParamError : 0
    }
}

public func AUParameterListenerNotify(
    _ inSendingListener: AUParameterListenerRef?,
    _ inSendingObject: UnsafeMutableRawPointer?,
    _ inParameter: UnsafePointer<AudioUnitParameter>?
) -> Int32 {
    guard let inParameter else {
        return atParamError
    }
    if let inSendingListener {
        let known: Bool = atWithLock(atWave12ListenerLock) {
            atWave12ParameterListeners[inSendingListener] != nil
        }
        if !known {
            return atParamError
        }
    }
    let parameter = inParameter.pointee
    atWave12NotifyParameterListeners(
        sending: inSendingListener,
        object: inSendingObject,
        parameter: parameter,
        value: atWave12CurrentParameterValue(parameter)
    )
    return 0
}

public func AUParameterSet(
    _ inSendingListener: AUParameterListenerRef?,
    _ inSendingObject: UnsafeMutableRawPointer?,
    _ inParameter: UnsafePointer<AudioUnitParameter>?,
    _ inValue: AudioUnitParameterValue,
    _ inBufferOffsetInFrames: UInt32
) -> Int32 {
    guard let inParameter else {
        return atParamError
    }
    let parameter = inParameter.pointee
    let status = AudioUnitSetParameter(
        parameter.mAudioUnit,
        parameter.mParameterID,
        parameter.mScope,
        parameter.mElement,
        inValue,
        inBufferOffsetInFrames
    )
    guard status == 0 else {
        return status
    }
    atWave12NotifyParameterListeners(
        sending: inSendingListener,
        object: inSendingObject,
        parameter: parameter,
        value: inValue
    )
    return 0
}

#if canImport(CoreFoundation)
public func AUEventListenerCreate(
    _ inProc: AUEventListenerProc?,
    _ inUserData: UnsafeMutableRawPointer?,
    _ inRunLoop: CFRunLoop?,
    _ inRunLoopMode: CFString?,
    _ inNotificationInterval: Float32,
    _ inValueChangeGranularity: Float32,
    _ outListener: UnsafeMutablePointer<AUEventListenerRef?>?
) -> Int32 {
    _ = inRunLoop
    _ = inRunLoopMode
    _ = inNotificationInterval
    _ = inValueChangeGranularity
    guard let outListener, let inProc else {
        return atParamError
    }
    let listener = ATWave12EventListener()
    listener.proc = inProc
    listener.userData = inUserData
    let ref = ATRegistry.shared.retain(listener)
    atWithLock(atWave12ListenerLock) {
        atWave12EventListeners[ref] = listener
    }
    outListener.pointee = ref
    return 0
}
#endif

public func AUEventListenerAddEventType(
    _ inListener: AUEventListenerRef?,
    _ inObject: UnsafeMutableRawPointer?,
    _ inEvent: UnsafePointer<AudioUnitEvent>?
) -> Int32 {
    guard let inListener, let inEvent else {
        return atParamError
    }
    return atWithLock(atWave12ListenerLock) {
        guard let listener = atWave12EventListeners[inListener] else {
            return atParamError
        }
        listener.registrations.append(
            ATWave12EventRegistration(object: inObject, eventType: inEvent.pointee.mEventType)
        )
        return 0
    }
}

public func AUEventListenerRemoveEventType(
    _ inListener: AUEventListenerRef?,
    _ inObject: UnsafeMutableRawPointer?,
    _ inEvent: UnsafePointer<AudioUnitEvent>?
) -> Int32 {
    guard let inListener, let inEvent else {
        return atParamError
    }
    return atWithLock(atWave12ListenerLock) {
        guard let listener = atWave12EventListeners[inListener] else {
            return atParamError
        }
        let eventType = inEvent.pointee.mEventType
        let before = listener.registrations.count
        listener.registrations.removeAll { registration in
            registration.object == inObject && registration.eventType == eventType
        }
        return listener.registrations.count == before ? atParamError : 0
    }
}

internal func atWave12HostNanoseconds() -> UInt64 {
    let seconds = Date().timeIntervalSince1970
    if seconds <= 0 {
        return 0
    }
    let nanos = seconds * 1_000_000_000
    if nanos >= Double(UInt64.max) {
        return UInt64.max
    }
    return UInt64(nanos)
}

public func AUEventListenerNotify(
    _ inSendingListener: AUEventListenerRef?,
    _ inSendingObject: UnsafeMutableRawPointer?,
    _ inEvent: UnsafePointer<AudioUnitEvent>?
) -> Int32 {
    guard let inEvent else {
        return atParamError
    }
    if let inSendingListener {
        let known: Bool = atWithLock(atWave12ListenerLock) {
            atWave12EventListeners[inSendingListener] != nil
        }
        if !known {
            return atParamError
        }
    }
    let event = inEvent.pointee
    let value: AudioUnitParameterValue =
        event.mEventType == .parameterValueChange
        ? atWave12CurrentParameterValue(event.mArgument.parameter) : 0
    let hostTime = atWave12HostNanoseconds()
    let targets: [(proc: AUEventListenerProc, userData: UnsafeMutableRawPointer?)] = atWithLock(
        atWave12ListenerLock
    ) {
        var result: [(AUEventListenerProc, UnsafeMutableRawPointer?)] = []
        for (ref, listener) in atWave12EventListeners {
            if let inSendingListener, inSendingListener == ref {
                continue
            }
            guard let proc = listener.proc else {
                continue
            }
            let matches = listener.registrations.contains { registration in
                (registration.object == nil || registration.object == inSendingObject)
                    && registration.eventType == event.mEventType
            }
            if matches {
                result.append((proc, listener.userData))
            }
        }
        return result
    }
    for target in targets {
        var snapshot = event
        withUnsafePointer(to: &snapshot) { pointer in
            target.proc(target.userData, inSendingObject, pointer, hostTime, value)
        }
    }
    return 0
}

// MARK: - AUParameterFormatValue (oracle-pinned numeric fallback)

// macOS probes against a real MultiChannelMixer volume parameter:
// (0.75123, 3) -> "0.75", (100.5, 3) -> "100.50", (0.000123456, 3) -> "0.00",
// (123456.0, 5) -> "123456.0000", (-2.5, 4) -> "-2.500", (1/3, 6) -> "0.33333".
// That is `%.*f` with precision `max(digits - 1, 0)`. Hosted units publish no
// custom string-from-value callbacks, so the numeric fallback is the whole
// offline behavior. Precision is capped so hostile `inDigits` values cannot
// demand unbounded output.
public func AUParameterFormatValue(
    _ inParameterValue: Float64,
    _ inParameter: UnsafePointer<AudioUnitParameter>?,
    _ inTextBuffer: UnsafeMutablePointer<CChar>?,
    _ inDigits: UInt32
) -> UnsafeMutablePointer<CChar>? {
    _ = inParameter
    guard let inTextBuffer else {
        return nil
    }
    let precision = min(max(Int64(inDigits) - 1, 0), 32)
    let text = String(format: "%.*f", precision, inParameterValue)
    text.withCString { source in
        inTextBuffer.initialize(from: source, count: text.utf8.count + 1)
    }
    return inTextBuffer
}

// MARK: - AudioComponent metadata (fail-closed)

#if canImport(CoreFoundation)
public func AudioComponentCopyConfigurationInfo(
    _ inComponent: AudioComponent?,
    _ outConfigurationInfo: UnsafeMutablePointer<Unmanaged<CFDictionary>?>?
) -> Int32 {
    outConfigurationInfo?.pointee = nil
    guard ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self) != nil else {
        return kAudioComponentErr_InstanceInvalidated
    }
    // The plug-in configuration dictionary (architectures, bus layouts, icon
    // URLs) has no offline source on Linux; fail closed instead of guessing.
    return kAudioComponentErr_UnsupportedType
}

public func AudioComponentGetLastActiveTime(_ comp: AudioComponent?) -> CFAbsoluteTime {
    guard ATRegistry.shared.lookup(comp, as: ATAudioComponentRecord.self) != nil else {
        return 0
    }
    // Activation timestamps are not tracked by the offline registry.
    return 0
}

public func AudioComponentValidateWithResults(
    _ inComponent: AudioComponent?,
    _ inValidationParameters: CFDictionary?,
    _ inCompletionHandler: @escaping (AudioComponentValidationResult, CFDictionary) -> Void
) -> Int32 {
    _ = inValidationParameters
    guard ATRegistry.shared.lookup(inComponent, as: ATAudioComponentRecord.self) != nil else {
        inCompletionHandler(.failed, [:] as CFDictionary)
        return kAudioComponentErr_InstanceInvalidated
    }
    // Mirrors the synchronous AudioComponentValidate fail-closed contract:
    // on-device validation (open times, render tests, format sweeps) cannot
    // run offline, so the completion reports failure synchronously.
    inCompletionHandler(.failed, [:] as CFDictionary)
    return kAudioComponentErr_NotPermitted
}

public func AudioUnitExtensionCopyComponentList(
    _ extensionIdentifier: CFString
) -> Unmanaged<CFArray>? {
    _ = extensionIdentifier
    // No app-extension registry exists offline.
    return nil
}

public func AudioUnitExtensionSetComponentList(
    _ extensionIdentifier: CFString,
    _ audioComponentInfo: CFArray?
) -> Int32 {
    _ = extensionIdentifier
    _ = audioComponentInfo
    return kAudioComponentErr_NotPermitted
}
#endif

// MARK: - CAShow (debug output to stderr)

// Debug descriptions go to stderr so automation stdout keeps carrying only the
// sealed load-smoke marker.
public func CAShow(_ inObject: UnsafeMutableRawPointer?) {
    let text: String
    if let inObject {
        text = "AudioToolbox object \(inObject)\n"
    } else {
        text = "AudioToolbox object nil\n"
    }
    if let data = text.data(using: .utf8) {
        try? FileHandle.standardError.write(contentsOf: data)
    }
}
