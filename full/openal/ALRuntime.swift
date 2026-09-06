import Foundation
#if canImport(Glibc)
import Glibc
#endif

private let openALLock = NSRecursiveLock()

private func alLocked<T>(_ body: () -> T) -> T {
    openALLock.lock()
    defer { openALLock.unlock() }
    return body()
}

private func strdupAL(_ string: String) -> UnsafePointer<ALchar> {
    string.withCString { pointer in
        let count = strlen(pointer) + 1
        let copy = UnsafeMutablePointer<CChar>.allocate(capacity: count)
        copy.initialize(from: pointer, count: count)
        return UnsafePointer(copy)
    }
}

private func strdupList(_ entries: [String]) -> UnsafePointer<ALchar> {
    var bytes: [CChar] = []
    for entry in entries {
        bytes.append(contentsOf: entry.utf8.map { CChar(bitPattern: $0) })
        bytes.append(0)
    }
    bytes.append(0)
    let copy = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
    copy.initialize(from: bytes, count: bytes.count)
    return UnsafePointer(copy)
}

private enum ALStaticStrings {
    static let vendor = strdupAL(OpenALModuleInfo.vendor)
    static let version = strdupAL(OpenALModuleInfo.version)
    static let renderer = strdupAL(OpenALModuleInfo.renderer)
    static let alExtensions = strdupAL("")
    static let alcExtensions = strdupAL("ALC_ENUMERATION_EXT ALC_ENUMERATE_ALL_EXT ALC_EXT_CAPTURE")
    static let deviceName = strdupAL(OpenALModuleInfo.deviceName)
    static let deviceList = strdupList([OpenALModuleInfo.deviceName])
    static let emptyList = strdupList([])
}

private let alEnumNames: [String: ALenum] = {
    [
        "AL_NONE": AL_NONE, "AL_FALSE": AL_FALSE, "AL_TRUE": AL_TRUE,
        "AL_SOURCE_RELATIVE": AL_SOURCE_RELATIVE,
        "AL_CONE_INNER_ANGLE": AL_CONE_INNER_ANGLE, "AL_CONE_OUTER_ANGLE": AL_CONE_OUTER_ANGLE,
        "AL_PITCH": AL_PITCH, "AL_POSITION": AL_POSITION, "AL_DIRECTION": AL_DIRECTION,
        "AL_VELOCITY": AL_VELOCITY, "AL_LOOPING": AL_LOOPING, "AL_BUFFER": AL_BUFFER,
        "AL_GAIN": AL_GAIN, "AL_MIN_GAIN": AL_MIN_GAIN, "AL_MAX_GAIN": AL_MAX_GAIN,
        "AL_ORIENTATION": AL_ORIENTATION, "AL_SOURCE_STATE": AL_SOURCE_STATE,
        "AL_INITIAL": AL_INITIAL, "AL_PLAYING": AL_PLAYING, "AL_PAUSED": AL_PAUSED,
        "AL_STOPPED": AL_STOPPED, "AL_BUFFERS_QUEUED": AL_BUFFERS_QUEUED,
        "AL_BUFFERS_PROCESSED": AL_BUFFERS_PROCESSED,
        "AL_REFERENCE_DISTANCE": AL_REFERENCE_DISTANCE, "AL_ROLLOFF_FACTOR": AL_ROLLOFF_FACTOR,
        "AL_CONE_OUTER_GAIN": AL_CONE_OUTER_GAIN, "AL_MAX_DISTANCE": AL_MAX_DISTANCE,
        "AL_SEC_OFFSET": AL_SEC_OFFSET, "AL_SAMPLE_OFFSET": AL_SAMPLE_OFFSET,
        "AL_BYTE_OFFSET": AL_BYTE_OFFSET, "AL_SOURCE_TYPE": AL_SOURCE_TYPE,
        "AL_STATIC": AL_STATIC, "AL_STREAMING": AL_STREAMING, "AL_UNDETERMINED": AL_UNDETERMINED,
        "AL_FORMAT_MONO8": AL_FORMAT_MONO8, "AL_FORMAT_MONO16": AL_FORMAT_MONO16,
        "AL_FORMAT_STEREO8": AL_FORMAT_STEREO8, "AL_FORMAT_STEREO16": AL_FORMAT_STEREO16,
        "AL_FREQUENCY": AL_FREQUENCY, "AL_BITS": AL_BITS, "AL_CHANNELS": AL_CHANNELS,
        "AL_SIZE": AL_SIZE, "AL_UNUSED": AL_UNUSED, "AL_PENDING": AL_PENDING,
        "AL_PROCESSED": AL_PROCESSED, "AL_NO_ERROR": AL_NO_ERROR,
        "AL_INVALID_NAME": AL_INVALID_NAME, "AL_INVALID_ENUM": AL_INVALID_ENUM,
        "AL_INVALID_VALUE": AL_INVALID_VALUE, "AL_INVALID_OPERATION": AL_INVALID_OPERATION,
        "AL_OUT_OF_MEMORY": AL_OUT_OF_MEMORY, "AL_ILLEGAL_ENUM": AL_ILLEGAL_ENUM,
        "AL_ILLEGAL_COMMAND": AL_ILLEGAL_COMMAND, "AL_VENDOR": AL_VENDOR,
        "AL_VERSION": AL_VERSION, "AL_RENDERER": AL_RENDERER, "AL_EXTENSIONS": AL_EXTENSIONS,
        "AL_DOPPLER_FACTOR": AL_DOPPLER_FACTOR, "AL_DOPPLER_VELOCITY": AL_DOPPLER_VELOCITY,
        "AL_SPEED_OF_SOUND": AL_SPEED_OF_SOUND, "AL_DISTANCE_MODEL": AL_DISTANCE_MODEL,
        "AL_INVERSE_DISTANCE": AL_INVERSE_DISTANCE,
        "AL_INVERSE_DISTANCE_CLAMPED": AL_INVERSE_DISTANCE_CLAMPED,
        "AL_LINEAR_DISTANCE": AL_LINEAR_DISTANCE,
        "AL_LINEAR_DISTANCE_CLAMPED": AL_LINEAR_DISTANCE_CLAMPED,
        "AL_EXPONENT_DISTANCE": AL_EXPONENT_DISTANCE,
        "AL_EXPONENT_DISTANCE_CLAMPED": AL_EXPONENT_DISTANCE_CLAMPED,
        "AL_INVALID": AL_INVALID, "AL_QUEUE_HAS_LOOPED": AL_QUEUE_HAS_LOOPED,
    ]
}()

private let alcEnumNames: [String: ALCenum] = {
    [
        "ALC_FALSE": ALC_FALSE, "ALC_TRUE": ALC_TRUE, "ALC_INVALID": ALC_INVALID,
        "ALC_VERSION_0_1": ALC_VERSION_0_1, "ALC_FREQUENCY": ALC_FREQUENCY,
        "ALC_REFRESH": ALC_REFRESH, "ALC_SYNC": ALC_SYNC,
        "ALC_MONO_SOURCES": ALC_MONO_SOURCES, "ALC_STEREO_SOURCES": ALC_STEREO_SOURCES,
        "ALC_NO_ERROR": ALC_NO_ERROR, "ALC_INVALID_DEVICE": ALC_INVALID_DEVICE,
        "ALC_INVALID_CONTEXT": ALC_INVALID_CONTEXT, "ALC_INVALID_ENUM": ALC_INVALID_ENUM,
        "ALC_INVALID_VALUE": ALC_INVALID_VALUE, "ALC_OUT_OF_MEMORY": ALC_OUT_OF_MEMORY,
        "ALC_MAJOR_VERSION": ALC_MAJOR_VERSION, "ALC_MINOR_VERSION": ALC_MINOR_VERSION,
        "ALC_ATTRIBUTES_SIZE": ALC_ATTRIBUTES_SIZE, "ALC_ALL_ATTRIBUTES": ALC_ALL_ATTRIBUTES,
        "ALC_DEFAULT_DEVICE_SPECIFIER": ALC_DEFAULT_DEVICE_SPECIFIER,
        "ALC_DEVICE_SPECIFIER": ALC_DEVICE_SPECIFIER, "ALC_EXTENSIONS": ALC_EXTENSIONS,
        "ALC_CAPTURE_DEVICE_SPECIFIER": ALC_CAPTURE_DEVICE_SPECIFIER,
        "ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER": ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER,
        "ALC_CAPTURE_SAMPLES": ALC_CAPTURE_SAMPLES,
        "ALC_DEFAULT_ALL_DEVICES_SPECIFIER": ALC_DEFAULT_ALL_DEVICES_SPECIFIER,
        "ALC_ALL_DEVICES_SPECIFIER": ALC_ALL_DEVICES_SPECIFIER,
    ]
}()

private let distanceModels: Set<ALenum> = [
    AL_NONE, AL_INVERSE_DISTANCE, AL_INVERSE_DISTANCE_CLAMPED,
    AL_LINEAR_DISTANCE, AL_LINEAR_DISTANCE_CLAMPED,
    AL_EXPONENT_DISTANCE, AL_EXPONENT_DISTANCE_CLAMPED,
]

private enum BufferFormatInfo {
    static func info(_ format: ALenum) -> (channels: ALint, bits: ALint, frame: Int)? {
        switch format {
        case AL_FORMAT_MONO8: return (1, 8, 1)
        case AL_FORMAT_MONO16: return (1, 16, 2)
        case AL_FORMAT_STEREO8: return (2, 8, 2)
        case AL_FORMAT_STEREO16: return (2, 16, 4)
        default: return nil
        }
    }
}

private struct Vec3 {
    var x: ALfloat
    var y: ALfloat
    var z: ALfloat
    static let zero = Vec3(x: 0, y: 0, z: 0)
}

private final class ALBufferObject {
    var format: ALenum = 0
    var frequency: ALsizei = 0
    var bits: ALint = 0
    var channels: ALint = 0
    var data: [UInt8] = []
}

private final class ALSourceObject {
    var state: ALenum = AL_INITIAL
    var type: ALenum = AL_UNDETERMINED
    var queue: [ALuint] = []
    var processed: Int = 0
    var looping: ALint = 0
    var relative: ALint = 0
    var pitch: ALfloat = 1
    var gain: ALfloat = 1
    var minGain: ALfloat = 0
    var maxGain: ALfloat = 1
    var refDistance: ALfloat = 1
    var rolloff: ALfloat = 1
    var maxDistance: ALfloat = Float.greatestFiniteMagnitude
    var coneInner: ALfloat = 360
    var coneOuter: ALfloat = 360
    var coneOuterGain: ALfloat = 0
    var position = Vec3.zero
    var velocity = Vec3.zero
    var direction = Vec3.zero
    var secOffset: ALfloat = 0
    var sampleOffset: ALint = 0
    var byteOffset: ALint = 0

    var attachedBuffer: ALuint {
        queue.count == 1 && type == AL_STATIC ? queue[0] : 0
    }
}

private struct ALListenerObject {
    var gain: ALfloat = 1
    var position = Vec3.zero
    var velocity = Vec3.zero
    var at = Vec3(x: 0, y: 0, z: -1)
    var up = Vec3(x: 0, y: 1, z: 0)
}

private final class ALContextObject {
    let id: UInt
    let deviceID: UInt
    var error: ALenum = AL_NO_ERROR
    var distanceModel: ALenum = AL_INVERSE_DISTANCE_CLAMPED
    var dopplerFactor: ALfloat = 1
    var dopplerVelocity: ALfloat = 1
    var speedOfSound: ALfloat = 343.3
    var listener = ALListenerObject()
    var sources: [ALuint: ALSourceObject] = [:]
    var buffers: [ALuint: ALBufferObject] = [:]
    var nextName: ALuint = 1
    var suspended = false
    var frequency: ALCint = 44100
    var refresh: ALCint = 60
    var sync: ALCint = 0
    var monoSources: ALCint = 32
    var stereoSources: ALCint = 32

    init(id: UInt, deviceID: UInt) {
        self.id = id
        self.deviceID = deviceID
    }

    func setError(_ value: ALenum) {
        if error == AL_NO_ERROR {
            error = value
        }
    }

    func takeError() -> ALenum {
        let value = error
        error = AL_NO_ERROR
        return value
    }

    func generateNames(_ count: ALsizei) -> [ALuint] {
        var names: [ALuint] = []
        names.reserveCapacity(Int(count))
        for _ in 0..<Int(count) {
            let name = nextName
            nextName += 1
            names.append(name)
        }
        return names
    }
}

private final class ALDeviceObject {
    let id: UInt
    let name: String
    let capture: Bool
    var error: ALCenum = ALC_NO_ERROR
    var contexts: Set<UInt> = []
    var captureFrequency: ALCuint = 0
    var captureFormat: ALCenum = 0
    var captureBufferSize: ALCsizei = 0
    var capturing = false

    init(id: UInt, name: String, capture: Bool) {
        self.id = id
        self.name = name
        self.capture = capture
    }

    func setError(_ value: ALCenum) {
        if error == ALC_NO_ERROR {
            error = value
        }
    }

    func takeError() -> ALCenum {
        let value = error
        error = ALC_NO_ERROR
        return value
    }

    var handle: OpaquePointer {
        OpaquePointer(bitPattern: Int(id))!
    }
}

private enum ALWorld {
    static var nextID: UInt = 1
    static var devices: [UInt: ALDeviceObject] = [:]
    static var contexts: [UInt: ALContextObject] = [:]
    static var nullDeviceError: ALCenum = ALC_NO_ERROR
    static var detachedError: ALenum = AL_NO_ERROR
    static let tlsKey = "OpenUIKit.OpenAL.currentContext"

    static func allocID() -> UInt {
        let value = nextID
        nextID += 1
        return value
    }

    static var currentContextID: UInt {
        get { (Thread.current.threadDictionary[tlsKey] as? NSNumber)?.uintValue ?? 0 }
        set {
            if newValue == 0 {
                Thread.current.threadDictionary[tlsKey] = nil
            } else {
                Thread.current.threadDictionary[tlsKey] = NSNumber(value: newValue)
            }
        }
    }

    static func setNullError(_ value: ALCenum) {
        if nullDeviceError == ALC_NO_ERROR {
            nullDeviceError = value
        }
    }

    static func takeNullError() -> ALCenum {
        let value = nullDeviceError
        nullDeviceError = ALC_NO_ERROR
        return value
    }

    static func setDetached(_ value: ALenum) {
        if detachedError == AL_NO_ERROR {
            detachedError = value
        }
    }

    static func takeDetached() -> ALenum {
        let value = detachedError
        detachedError = AL_NO_ERROR
        return value
    }
}

private func pointerID(_ pointer: OpaquePointer?) -> UInt {
    guard let pointer else { return 0 }
    return UInt(bitPattern: pointer)
}

private func device(_ pointer: OpaquePointer?) -> ALDeviceObject? {
    let ident = pointerID(pointer)
    guard ident != 0 else { return nil }
    return ALWorld.devices[ident]
}

private func context(_ pointer: OpaquePointer?) -> ALContextObject? {
    let ident = pointerID(pointer)
    guard ident != 0 else { return nil }
    return ALWorld.contexts[ident]
}

private func currentContext() -> ALContextObject? {
    let ident = ALWorld.currentContextID
    guard ident != 0 else { return nil }
    return ALWorld.contexts[ident]
}

private func withCurrent(_ body: (ALContextObject) -> Void) {
    guard let ctx = currentContext() else {
        ALWorld.setDetached(AL_INVALID_OPERATION)
        return
    }
    body(ctx)
}

private func withCurrentRet<T>(_ fallback: T, _ body: (ALContextObject) -> T) -> T {
    guard let ctx = currentContext() else {
        ALWorld.setDetached(AL_INVALID_OPERATION)
        return fallback
    }
    return body(ctx)
}

private func cString(_ pointer: UnsafePointer<ALchar>?) -> String? {
    guard let pointer else { return nil }
    return String(cString: pointer)
}

private func storeVec3(_ vec: Vec3, _ out: UnsafeMutablePointer<ALfloat>?) {
    guard let out else { return }
    out[0] = vec.x
    out[1] = vec.y
    out[2] = vec.z
}

private func bufferInUse(_ ctx: ALContextObject, _ bid: ALuint) -> Bool {
    ctx.sources.values.contains { source in
        source.queue.contains(bid) && (source.state == AL_PLAYING || source.state == AL_PAUSED)
    }
}

private func setSourcePlaying(_ source: ALSourceObject) {
    if source.queue.isEmpty {
        source.state = AL_STOPPED
        source.processed = 0
        return
    }
    source.state = AL_PLAYING
}

private func setSourceStopped(_ source: ALSourceObject) {
    source.state = AL_STOPPED
    source.processed = source.queue.count
    source.secOffset = 0
    source.sampleOffset = 0
    source.byteOffset = 0
}

private func inverseDistanceGain(distance: ALfloat, ref: ALfloat, rolloff: ALfloat, maxDistance: ALfloat, clamped: Bool) -> ALfloat {
    var d = distance
    if clamped {
        d = min(max(d, ref), maxDistance)
    }
    let denom = ref + rolloff * (d - ref)
    if denom <= 0 {
        return 1
    }
    return min(1, ref / denom)
}

public func openALInverseDistanceGain(
    distance: ALfloat,
    referenceDistance: ALfloat,
    rolloff: ALfloat,
    maxDistance: ALfloat,
    clamped: Bool
) -> ALfloat {
    inverseDistanceGain(
        distance: distance,
        ref: referenceDistance,
        rolloff: rolloff,
        maxDistance: maxDistance,
        clamped: clamped
    )
}

// MARK: - ALC

public func alcOpenDevice(_ devicename: UnsafePointer<ALCchar>!) -> OpaquePointer! {
    alLocked {
        if let name = cString(devicename), !name.isEmpty, name != OpenALModuleInfo.deviceName {
            ALWorld.setNullError(ALC_INVALID_VALUE)
            return nil
        }
        let ident = ALWorld.allocID()
        let object = ALDeviceObject(id: ident, name: OpenALModuleInfo.deviceName, capture: false)
        ALWorld.devices[ident] = object
        return object.handle
    }
}

public func alcCloseDevice(_ deviceHandle: OpaquePointer!) -> ALCboolean {
    alLocked {
        guard let object = device(deviceHandle), !object.capture else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return 0
        }
        if !object.contexts.isEmpty {
            object.setError(ALC_INVALID_DEVICE)
            return 0
        }
        ALWorld.devices[object.id] = nil
        return 1
    }
}

public func alcCreateContext(_ deviceHandle: OpaquePointer!, _ attrlist: UnsafePointer<ALCint>!) -> OpaquePointer! {
    alLocked {
        guard let object = device(deviceHandle), !object.capture else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return nil
        }
        let ctx = ALContextObject(id: ALWorld.allocID(), deviceID: object.id)
        if let attrlist {
            var index = 0
            while attrlist[index] != 0 {
                let key = attrlist[index]
                let value = attrlist[index + 1]
                switch key {
                case ALC_FREQUENCY:
                    if value <= 0 {
                        object.setError(ALC_INVALID_VALUE)
                        return nil
                    }
                    ctx.frequency = value
                case ALC_REFRESH:
                    if value <= 0 {
                        object.setError(ALC_INVALID_VALUE)
                        return nil
                    }
                    ctx.refresh = value
                case ALC_SYNC:
                    ctx.sync = value == 0 ? 0 : 1
                case ALC_MONO_SOURCES:
                    if value < 0 {
                        object.setError(ALC_INVALID_VALUE)
                        return nil
                    }
                    ctx.monoSources = value
                case ALC_STEREO_SOURCES:
                    if value < 0 {
                        object.setError(ALC_INVALID_VALUE)
                        return nil
                    }
                    ctx.stereoSources = value
                default:
                    object.setError(ALC_INVALID_ENUM)
                    return nil
                }
                index += 2
            }
        }
        ALWorld.contexts[ctx.id] = ctx
        object.contexts.insert(ctx.id)
        return OpaquePointer(bitPattern: Int(ctx.id))
    }
}

public func alcDestroyContext(_ contextHandle: OpaquePointer!) {
    alLocked {
        guard let ctx = context(contextHandle) else {
            ALWorld.setNullError(ALC_INVALID_CONTEXT)
            return
        }
        if ALWorld.currentContextID == ctx.id {
            ALWorld.currentContextID = 0
        }
        if let object = ALWorld.devices[ctx.deviceID] {
            object.contexts.remove(ctx.id)
        }
        ALWorld.contexts[ctx.id] = nil
    }
}

public func alcMakeContextCurrent(_ contextHandle: OpaquePointer!) -> ALCboolean {
    alLocked {
        if contextHandle == nil {
            ALWorld.currentContextID = 0
            return 1
        }
        guard let ctx = context(contextHandle) else {
            ALWorld.setNullError(ALC_INVALID_CONTEXT)
            return 0
        }
        ALWorld.currentContextID = ctx.id
        return 1
    }
}

public func alcGetCurrentContext() -> OpaquePointer! {
    alLocked {
        let ident = ALWorld.currentContextID
        guard ident != 0 else { return nil }
        return OpaquePointer(bitPattern: Int(ident))
    }
}

public func alcGetContextsDevice(_ contextHandle: OpaquePointer!) -> OpaquePointer! {
    alLocked {
        guard let ctx = context(contextHandle), let object = ALWorld.devices[ctx.deviceID] else {
            ALWorld.setNullError(ALC_INVALID_CONTEXT)
            return nil
        }
        return object.handle
    }
}

public func alcProcessContext(_ contextHandle: OpaquePointer!) {
    alLocked {
        guard let ctx = context(contextHandle) else {
            ALWorld.setNullError(ALC_INVALID_CONTEXT)
            return
        }
        ctx.suspended = false
    }
}

public func alcSuspendContext(_ contextHandle: OpaquePointer!) {
    alLocked {
        guard let ctx = context(contextHandle) else {
            ALWorld.setNullError(ALC_INVALID_CONTEXT)
            return
        }
        ctx.suspended = true
    }
}

public func alcGetError(_ deviceHandle: OpaquePointer!) -> ALCenum {
    alLocked {
        if deviceHandle == nil {
            return ALWorld.takeNullError()
        }
        guard let object = device(deviceHandle) else {
            return ALC_INVALID_DEVICE
        }
        return object.takeError()
    }
}

public func alcIsExtensionPresent(_ deviceHandle: OpaquePointer!, _ extname: UnsafePointer<ALCchar>!) -> ALCboolean {
    alLocked {
        guard let name = cString(extname), !name.isEmpty else {
            if let object = device(deviceHandle) {
                object.setError(ALC_INVALID_VALUE)
            } else {
                ALWorld.setNullError(ALC_INVALID_VALUE)
            }
            return 0
        }
        if deviceHandle != nil && device(deviceHandle) == nil {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return 0
        }
        let folded = name.uppercased()
        let supported = [
            "ALC_ENUMERATION_EXT",
            "ALC_ENUMERATE_ALL_EXT",
            "ALC_EXT_CAPTURE",
        ]
        return supported.contains(folded) ? 1 : 0
    }
}

public func alcGetProcAddress(_ deviceHandle: OpaquePointer!, _ funcname: UnsafePointer<ALCchar>!) -> UnsafeMutableRawPointer! {
    alLocked {
        if deviceHandle != nil && device(deviceHandle) == nil {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return nil
        }
        guard let name = cString(funcname), !name.isEmpty else {
            if let object = device(deviceHandle) {
                object.setError(ALC_INVALID_VALUE)
            } else {
                ALWorld.setNullError(ALC_INVALID_VALUE)
            }
            return nil
        }
        _ = name
        return nil
    }
}

public func alcGetEnumValue(_ deviceHandle: OpaquePointer!, _ enumname: UnsafePointer<ALCchar>!) -> ALCenum {
    alLocked {
        if deviceHandle != nil && device(deviceHandle) == nil {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return 0
        }
        guard let name = cString(enumname), !name.isEmpty else {
            if let object = device(deviceHandle) {
                object.setError(ALC_INVALID_VALUE)
            } else {
                ALWorld.setNullError(ALC_INVALID_VALUE)
            }
            return 0
        }
        return alcEnumNames[name] ?? 0
    }
}

public func alcGetString(_ deviceHandle: OpaquePointer!, _ param: ALCenum) -> UnsafePointer<ALCchar>! {
    alLocked {
        switch param {
        case ALC_EXTENSIONS:
            if deviceHandle != nil && device(deviceHandle) == nil {
                ALWorld.setNullError(ALC_INVALID_DEVICE)
                return nil
            }
            return ALStaticStrings.alcExtensions
        case ALC_DEFAULT_DEVICE_SPECIFIER, ALC_DEFAULT_ALL_DEVICES_SPECIFIER:
            return ALStaticStrings.deviceName
        case ALC_DEVICE_SPECIFIER, ALC_ALL_DEVICES_SPECIFIER:
            if let object = device(deviceHandle), !object.capture {
                return strdupAL(object.name)
            }
            if deviceHandle == nil {
                return ALStaticStrings.deviceList
            }
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return nil
        case ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER:
            return nil
        case ALC_CAPTURE_DEVICE_SPECIFIER:
            if deviceHandle == nil {
                return ALStaticStrings.emptyList
            }
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return nil
        default:
            if let object = device(deviceHandle) {
                object.setError(ALC_INVALID_ENUM)
            } else {
                ALWorld.setNullError(ALC_INVALID_ENUM)
            }
            return nil
        }
    }
}

public func alcGetIntegerv(_ deviceHandle: OpaquePointer!, _ param: ALCenum, _ size: ALCsizei, _ data: UnsafeMutablePointer<ALCint>!) {
    alLocked {
        if size <= 0 {
            if let object = device(deviceHandle) {
                object.setError(ALC_INVALID_VALUE)
            } else {
                ALWorld.setNullError(ALC_INVALID_VALUE)
            }
            return
        }
        guard let data else {
            if let object = device(deviceHandle) {
                object.setError(ALC_INVALID_VALUE)
            } else {
                ALWorld.setNullError(ALC_INVALID_VALUE)
            }
            return
        }
        if deviceHandle == nil {
            switch param {
            case ALC_MAJOR_VERSION: data[0] = 1
            case ALC_MINOR_VERSION: data[0] = 1
            default:
                ALWorld.setNullError(ALC_INVALID_ENUM)
            }
            return
        }
        guard let object = device(deviceHandle) else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return
        }
        if object.capture {
            switch param {
            case ALC_CAPTURE_SAMPLES:
                data[0] = 0
            case ALC_MAJOR_VERSION:
                data[0] = 1
            case ALC_MINOR_VERSION:
                data[0] = 1
            default:
                object.setError(ALC_INVALID_ENUM)
            }
            return
        }
        let ctx = object.contexts.compactMap { ALWorld.contexts[$0] }.first
        switch param {
        case ALC_MAJOR_VERSION: data[0] = 1
        case ALC_MINOR_VERSION: data[0] = 1
        case ALC_ATTRIBUTES_SIZE:
            data[0] = 11
        case ALC_ALL_ATTRIBUTES:
            guard size >= 11 else {
                object.setError(ALC_INVALID_VALUE)
                return
            }
            let frequency = ctx?.frequency ?? 44100
            let refresh = ctx?.refresh ?? 60
            let sync = ctx?.sync ?? 0
            let mono = ctx?.monoSources ?? 32
            let stereo = ctx?.stereoSources ?? 32
            data[0] = ALC_FREQUENCY
            data[1] = frequency
            data[2] = ALC_REFRESH
            data[3] = refresh
            data[4] = ALC_SYNC
            data[5] = sync
            data[6] = ALC_MONO_SOURCES
            data[7] = mono
            data[8] = ALC_STEREO_SOURCES
            data[9] = stereo
            data[10] = 0
        case ALC_FREQUENCY: data[0] = ctx?.frequency ?? 44100
        case ALC_REFRESH: data[0] = ctx?.refresh ?? 60
        case ALC_SYNC: data[0] = ctx?.sync ?? 0
        case ALC_MONO_SOURCES: data[0] = ctx?.monoSources ?? 32
        case ALC_STEREO_SOURCES: data[0] = ctx?.stereoSources ?? 32
        default:
            object.setError(ALC_INVALID_ENUM)
        }
    }
}

public func alcCaptureOpenDevice(
    _ devicename: UnsafePointer<ALCchar>!,
    _ frequency: ALCuint,
    _ format: ALCenum,
    _ buffersize: ALCsizei
) -> OpaquePointer! {
    alLocked {
        _ = devicename
        _ = frequency
        _ = format
        _ = buffersize
        ALWorld.setNullError(ALC_INVALID_VALUE)
        return nil
    }
}

public func alcCaptureCloseDevice(_ deviceHandle: OpaquePointer!) -> ALCboolean {
    alLocked {
        guard let object = device(deviceHandle), object.capture else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return 0
        }
        ALWorld.devices[object.id] = nil
        return 1
    }
}

public func alcCaptureStart(_ deviceHandle: OpaquePointer!) {
    alLocked {
        guard let object = device(deviceHandle), object.capture else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return
        }
        object.capturing = true
    }
}

public func alcCaptureStop(_ deviceHandle: OpaquePointer!) {
    alLocked {
        guard let object = device(deviceHandle), object.capture else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return
        }
        object.capturing = false
    }
}

public func alcCaptureSamples(_ deviceHandle: OpaquePointer!, _ buffer: UnsafeMutableRawPointer!, _ samples: ALCsizei) {
    alLocked {
        guard let object = device(deviceHandle), object.capture else {
            ALWorld.setNullError(ALC_INVALID_DEVICE)
            return
        }
        if samples < 0 || (samples > 0 && buffer == nil) {
            object.setError(ALC_INVALID_VALUE)
            return
        }
        if samples > 0 {
            object.setError(ALC_INVALID_VALUE)
        }
    }
}

// MARK: - AL state

public func alGetError() -> ALenum {
    alLocked {
        if let ctx = currentContext() {
            let detached = ALWorld.takeDetached()
            if detached != AL_NO_ERROR {
                return detached
            }
            return ctx.takeError()
        }
        let detached = ALWorld.takeDetached()
        return detached == AL_NO_ERROR ? AL_INVALID_OPERATION : detached
    }
}

public func alEnable(_ capability: ALenum) {
    alLocked {
        withCurrent { ctx in
            ctx.setError(AL_INVALID_ENUM)
            _ = capability
        }
    }
}

public func alDisable(_ capability: ALenum) {
    alLocked {
        withCurrent { ctx in
            ctx.setError(AL_INVALID_ENUM)
            _ = capability
        }
    }
}

public func alIsEnabled(_ capability: ALenum) -> ALboolean {
    alLocked {
        withCurrentRet(0) { ctx in
            ctx.setError(AL_INVALID_ENUM)
            _ = capability
            return 0
        }
    }
}

public func alGetBoolean(_ param: ALenum) -> ALboolean {
    var value: ALboolean = 0
    alGetBooleanv(param, &value)
    return value
}

public func alGetBooleanv(_ param: ALenum, _ data: UnsafeMutablePointer<ALboolean>!) {
    alLocked {
        withCurrent { ctx in
            ctx.setError(AL_INVALID_ENUM)
            _ = param
            _ = data
        }
    }
}

public func alGetInteger(_ param: ALenum) -> ALint {
    var value: ALint = 0
    alGetIntegerv(param, &value)
    return value
}

public func alGetIntegerv(_ param: ALenum, _ data: UnsafeMutablePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let data else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_DISTANCE_MODEL:
                data[0] = ctx.distanceModel
            default:
                ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetFloat(_ param: ALenum) -> ALfloat {
    var value: ALfloat = 0
    alGetFloatv(param, &value)
    return value
}

public func alGetFloatv(_ param: ALenum, _ data: UnsafeMutablePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let data else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_DOPPLER_FACTOR: data[0] = ctx.dopplerFactor
            case AL_DOPPLER_VELOCITY: data[0] = ctx.dopplerVelocity
            case AL_SPEED_OF_SOUND: data[0] = ctx.speedOfSound
            default:
                ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetDouble(_ param: ALenum) -> ALdouble {
    var value: ALdouble = 0
    alGetDoublev(param, &value)
    return value
}

public func alGetDoublev(_ param: ALenum, _ data: UnsafeMutablePointer<ALdouble>!) {
    alLocked {
        withCurrent { ctx in
            guard let data else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_DOPPLER_FACTOR: data[0] = ALdouble(ctx.dopplerFactor)
            case AL_DOPPLER_VELOCITY: data[0] = ALdouble(ctx.dopplerVelocity)
            case AL_SPEED_OF_SOUND: data[0] = ALdouble(ctx.speedOfSound)
            default:
                ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetString(_ param: ALenum) -> UnsafePointer<ALchar>! {
    alLocked {
        withCurrentRet(nil) { ctx in
            switch param {
            case AL_VENDOR: return ALStaticStrings.vendor
            case AL_VERSION: return ALStaticStrings.version
            case AL_RENDERER: return ALStaticStrings.renderer
            case AL_EXTENSIONS: return ALStaticStrings.alExtensions
            default:
                ctx.setError(AL_INVALID_ENUM)
                return nil
            }
        }
    }
}

public func alDistanceModel(_ distanceModel: ALenum) {
    alLocked {
        withCurrent { ctx in
            guard distanceModels.contains(distanceModel) else {
                ctx.setError(AL_INVALID_ENUM)
                return
            }
            ctx.distanceModel = distanceModel
        }
    }
}

public func alDopplerFactor(_ value: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard value >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            ctx.dopplerFactor = value
        }
    }
}

public func alDopplerVelocity(_ value: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard value >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            ctx.dopplerVelocity = value
        }
    }
}

public func alSpeedOfSound(_ value: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard value > 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            ctx.speedOfSound = value
        }
    }
}

public func alIsExtensionPresent(_ extname: UnsafePointer<ALchar>!) -> ALboolean {
    alLocked {
        withCurrentRet(0) { ctx in
            guard let name = cString(extname), !name.isEmpty else {
                ctx.setError(AL_INVALID_VALUE)
                return 0
            }
            _ = name
            return 0
        }
    }
}

public func alGetProcAddress(_ fname: UnsafePointer<ALchar>!) -> UnsafeMutableRawPointer! {
    alLocked {
        withCurrentRet(nil) { ctx in
            guard let name = cString(fname), !name.isEmpty else {
                ctx.setError(AL_INVALID_VALUE)
                return nil
            }
            _ = name
            return nil
        }
    }
}

public func alGetEnumValue(_ ename: UnsafePointer<ALchar>!) -> ALenum {
    alLocked {
        withCurrentRet(0) { ctx in
            guard let name = cString(ename), !name.isEmpty else {
                ctx.setError(AL_INVALID_VALUE)
                return 0
            }
            return alEnumNames[name] ?? 0
        }
    }
}

// MARK: - Listener

private func setListenerf(_ ctx: ALContextObject, _ param: ALenum, _ value: ALfloat) {
    switch param {
    case AL_GAIN:
        guard value >= 0 else {
            ctx.setError(AL_INVALID_VALUE)
            return
        }
        ctx.listener.gain = value
    default:
        ctx.setError(AL_INVALID_ENUM)
    }
}

private func setListener3f(_ ctx: ALContextObject, _ param: ALenum, _ x: ALfloat, _ y: ALfloat, _ z: ALfloat) {
    switch param {
    case AL_POSITION: ctx.listener.position = Vec3(x: x, y: y, z: z)
    case AL_VELOCITY: ctx.listener.velocity = Vec3(x: x, y: y, z: z)
    default:
        ctx.setError(AL_INVALID_ENUM)
    }
}

private func setListenerfv(_ ctx: ALContextObject, _ param: ALenum, _ values: UnsafePointer<ALfloat>?) {
    guard let values else {
        ctx.setError(AL_INVALID_VALUE)
        return
    }
    switch param {
    case AL_GAIN: setListenerf(ctx, param, values[0])
    case AL_POSITION, AL_VELOCITY:
        setListener3f(ctx, param, values[0], values[1], values[2])
    case AL_ORIENTATION:
        ctx.listener.at = Vec3(x: values[0], y: values[1], z: values[2])
        ctx.listener.up = Vec3(x: values[3], y: values[4], z: values[5])
    default:
        ctx.setError(AL_INVALID_ENUM)
    }
}

public func alListenerf(_ param: ALenum, _ value: ALfloat) {
    alLocked { withCurrent { setListenerf($0, param, value) } }
}

public func alListener3f(_ param: ALenum, _ value1: ALfloat, _ value2: ALfloat, _ value3: ALfloat) {
    alLocked { withCurrent { setListener3f($0, param, value1, value2, value3) } }
}

public func alListenerfv(_ param: ALenum, _ values: UnsafePointer<ALfloat>!) {
    alLocked { withCurrent { setListenerfv($0, param, values) } }
}

public func alListeneri(_ param: ALenum, _ value: ALint) {
    alListenerf(param, ALfloat(value))
}

public func alListener3i(_ param: ALenum, _ value1: ALint, _ value2: ALint, _ value3: ALint) {
    alListener3f(param, ALfloat(value1), ALfloat(value2), ALfloat(value3))
}

public func alListeneriv(_ param: ALenum, _ values: UnsafePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_GAIN:
                setListenerf(ctx, param, ALfloat(values[0]))
            case AL_POSITION, AL_VELOCITY:
                setListener3f(ctx, param, ALfloat(values[0]), ALfloat(values[1]), ALfloat(values[2]))
            case AL_ORIENTATION:
                ctx.listener.at = Vec3(x: ALfloat(values[0]), y: ALfloat(values[1]), z: ALfloat(values[2]))
                ctx.listener.up = Vec3(x: ALfloat(values[3]), y: ALfloat(values[4]), z: ALfloat(values[5]))
            default:
                ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetListenerf(_ param: ALenum, _ value: UnsafeMutablePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let value else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_GAIN: value.pointee = ctx.listener.gain
            default: ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetListener3f(
    _ param: ALenum,
    _ value1: UnsafeMutablePointer<ALfloat>!,
    _ value2: UnsafeMutablePointer<ALfloat>!,
    _ value3: UnsafeMutablePointer<ALfloat>!
) {
    alLocked {
        withCurrent { ctx in
            guard let value1, let value2, let value3 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            let vec: Vec3
            switch param {
            case AL_POSITION: vec = ctx.listener.position
            case AL_VELOCITY: vec = ctx.listener.velocity
            default:
                ctx.setError(AL_INVALID_ENUM)
                return
            }
            value1.pointee = vec.x
            value2.pointee = vec.y
            value3.pointee = vec.z
        }
    }
}

public func alGetListenerfv(_ param: ALenum, _ values: UnsafeMutablePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_GAIN: values[0] = ctx.listener.gain
            case AL_POSITION: storeVec3(ctx.listener.position, values)
            case AL_VELOCITY: storeVec3(ctx.listener.velocity, values)
            case AL_ORIENTATION:
                values[0] = ctx.listener.at.x
                values[1] = ctx.listener.at.y
                values[2] = ctx.listener.at.z
                values[3] = ctx.listener.up.x
                values[4] = ctx.listener.up.y
                values[5] = ctx.listener.up.z
            default:
                ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetListeneri(_ param: ALenum, _ value: UnsafeMutablePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let value else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_GAIN: value.pointee = ALint(ctx.listener.gain)
            default: ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetListener3i(
    _ param: ALenum,
    _ value1: UnsafeMutablePointer<ALint>!,
    _ value2: UnsafeMutablePointer<ALint>!,
    _ value3: UnsafeMutablePointer<ALint>!
) {
    alLocked {
        withCurrent { ctx in
            guard let value1, let value2, let value3 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            let vec: Vec3
            switch param {
            case AL_POSITION: vec = ctx.listener.position
            case AL_VELOCITY: vec = ctx.listener.velocity
            default:
                ctx.setError(AL_INVALID_ENUM)
                return
            }
            value1.pointee = ALint(vec.x)
            value2.pointee = ALint(vec.y)
            value3.pointee = ALint(vec.z)
        }
    }
}

public func alGetListeneriv(_ param: ALenum, _ values: UnsafeMutablePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_GAIN: values[0] = ALint(ctx.listener.gain)
            case AL_POSITION:
                values[0] = ALint(ctx.listener.position.x)
                values[1] = ALint(ctx.listener.position.y)
                values[2] = ALint(ctx.listener.position.z)
            case AL_VELOCITY:
                values[0] = ALint(ctx.listener.velocity.x)
                values[1] = ALint(ctx.listener.velocity.y)
                values[2] = ALint(ctx.listener.velocity.z)
            case AL_ORIENTATION:
                values[0] = ALint(ctx.listener.at.x)
                values[1] = ALint(ctx.listener.at.y)
                values[2] = ALint(ctx.listener.at.z)
                values[3] = ALint(ctx.listener.up.x)
                values[4] = ALint(ctx.listener.up.y)
                values[5] = ALint(ctx.listener.up.z)
            default:
                ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

// MARK: - Sources

public func alGenSources(_ n: ALsizei, _ sources: UnsafeMutablePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard n >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if n == 0 { return }
            guard let sources else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            let names = ctx.generateNames(n)
            for (index, name) in names.enumerated() {
                ctx.sources[name] = ALSourceObject()
                sources[index] = name
            }
        }
    }
}

public func alDeleteSources(_ n: ALsizei, _ sources: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard n >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if n == 0 { return }
            guard let sources else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            for index in 0..<Int(n) {
                let name = sources[index]
                if name == 0 { continue }
                guard ctx.sources[name] != nil else {
                    ctx.setError(AL_INVALID_NAME)
                    return
                }
            }
            for index in 0..<Int(n) {
                ctx.sources[sources[index]] = nil
            }
        }
    }
}

public func alIsSource(_ sid: ALuint) -> ALboolean {
    alLocked {
        withCurrentRet(0) { ctx in
            ctx.sources[sid] != nil ? 1 : 0
        }
    }
}

private func setSourcef(_ ctx: ALContextObject, _ source: ALSourceObject, _ param: ALenum, _ value: ALfloat) {
    switch param {
    case AL_PITCH:
        guard value > 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.pitch = value
    case AL_GAIN:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.gain = value
    case AL_MIN_GAIN:
        guard value >= 0 && value <= 1 else { ctx.setError(AL_INVALID_VALUE); return }
        source.minGain = value
    case AL_MAX_GAIN:
        guard value >= 0 && value <= 1 else { ctx.setError(AL_INVALID_VALUE); return }
        source.maxGain = value
    case AL_MAX_DISTANCE:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.maxDistance = value
    case AL_ROLLOFF_FACTOR:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.rolloff = value
    case AL_CONE_OUTER_GAIN:
        guard value >= 0 && value <= 1 else { ctx.setError(AL_INVALID_VALUE); return }
        source.coneOuterGain = value
    case AL_CONE_INNER_ANGLE, AL_CONE_OUTER_ANGLE:
        source.coneInner = param == AL_CONE_INNER_ANGLE ? value : source.coneInner
        source.coneOuter = param == AL_CONE_OUTER_ANGLE ? value : source.coneOuter
        if param == AL_CONE_INNER_ANGLE { source.coneInner = value }
        if param == AL_CONE_OUTER_ANGLE { source.coneOuter = value }
    case AL_REFERENCE_DISTANCE:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.refDistance = value
    case AL_SEC_OFFSET:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.secOffset = value
    case AL_SAMPLE_OFFSET:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.sampleOffset = ALint(value)
    case AL_BYTE_OFFSET:
        guard value >= 0 else { ctx.setError(AL_INVALID_VALUE); return }
        source.byteOffset = ALint(value)
    default:
        ctx.setError(AL_INVALID_ENUM)
    }
}

private func setSource3f(_ ctx: ALContextObject, _ source: ALSourceObject, _ param: ALenum, _ x: ALfloat, _ y: ALfloat, _ z: ALfloat) {
    switch param {
    case AL_POSITION: source.position = Vec3(x: x, y: y, z: z)
    case AL_VELOCITY: source.velocity = Vec3(x: x, y: y, z: z)
    case AL_DIRECTION: source.direction = Vec3(x: x, y: y, z: z)
    default: ctx.setError(AL_INVALID_ENUM)
    }
}

private func setSourcei(_ ctx: ALContextObject, _ source: ALSourceObject, _ param: ALenum, _ value: ALint) {
    switch param {
    case AL_SOURCE_RELATIVE:
        source.relative = value == 0 ? 0 : 1
    case AL_LOOPING:
        source.looping = value == 0 ? 0 : 1
    case AL_BUFFER:
        if source.state == AL_PLAYING || source.state == AL_PAUSED {
            ctx.setError(AL_INVALID_OPERATION)
            return
        }
        if value == 0 {
            source.queue = []
            source.processed = 0
            source.type = AL_UNDETERMINED
            return
        }
        guard ctx.buffers[ALuint(value)] != nil else {
            ctx.setError(AL_INVALID_VALUE)
            return
        }
        source.queue = [ALuint(value)]
        source.processed = 0
        source.type = AL_STATIC
    case AL_SEC_OFFSET, AL_SAMPLE_OFFSET, AL_BYTE_OFFSET,
         AL_REFERENCE_DISTANCE, AL_ROLLOFF_FACTOR, AL_MAX_DISTANCE,
         AL_CONE_INNER_ANGLE, AL_CONE_OUTER_ANGLE, AL_CONE_OUTER_GAIN,
         AL_PITCH, AL_GAIN, AL_MIN_GAIN, AL_MAX_GAIN:
        setSourcef(ctx, source, param, ALfloat(value))
    default:
        ctx.setError(AL_INVALID_ENUM)
    }
}

private func requireSource(_ ctx: ALContextObject, _ sid: ALuint) -> ALSourceObject? {
    guard let source = ctx.sources[sid] else {
        ctx.setError(AL_INVALID_NAME)
        return nil
    }
    return source
}

public func alSourcef(_ sid: ALuint, _ param: ALenum, _ value: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            setSourcef(ctx, source, param, value)
        }
    }
}

public func alSource3f(_ sid: ALuint, _ param: ALenum, _ value1: ALfloat, _ value2: ALfloat, _ value3: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            setSource3f(ctx, source, param, value1, value2, value3)
        }
    }
}

public func alSourcefv(_ sid: ALuint, _ param: ALenum, _ values: UnsafePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_POSITION, AL_VELOCITY, AL_DIRECTION:
                setSource3f(ctx, source, param, values[0], values[1], values[2])
            default:
                setSourcef(ctx, source, param, values[0])
            }
        }
    }
}

public func alSourcei(_ sid: ALuint, _ param: ALenum, _ value: ALint) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            setSourcei(ctx, source, param, value)
        }
    }
}

public func alSource3i(_ sid: ALuint, _ param: ALenum, _ value1: ALint, _ value2: ALint, _ value3: ALint) {
    alSource3f(sid, param, ALfloat(value1), ALfloat(value2), ALfloat(value3))
}

public func alSourceiv(_ sid: ALuint, _ param: ALenum, _ values: UnsafePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_POSITION, AL_VELOCITY, AL_DIRECTION:
                setSource3f(ctx, source, param, ALfloat(values[0]), ALfloat(values[1]), ALfloat(values[2]))
            default:
                setSourcei(ctx, source, param, values[0])
            }
        }
    }
}

public func alGetSourcef(_ sid: ALuint, _ param: ALenum, _ value: UnsafeMutablePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let value else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_PITCH: value.pointee = source.pitch
            case AL_GAIN: value.pointee = source.gain
            case AL_MIN_GAIN: value.pointee = source.minGain
            case AL_MAX_GAIN: value.pointee = source.maxGain
            case AL_MAX_DISTANCE: value.pointee = source.maxDistance
            case AL_ROLLOFF_FACTOR: value.pointee = source.rolloff
            case AL_CONE_OUTER_GAIN: value.pointee = source.coneOuterGain
            case AL_CONE_INNER_ANGLE: value.pointee = source.coneInner
            case AL_CONE_OUTER_ANGLE: value.pointee = source.coneOuter
            case AL_REFERENCE_DISTANCE: value.pointee = source.refDistance
            case AL_SEC_OFFSET: value.pointee = source.secOffset
            case AL_SAMPLE_OFFSET: value.pointee = ALfloat(source.sampleOffset)
            case AL_BYTE_OFFSET: value.pointee = ALfloat(source.byteOffset)
            default: ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetSource3f(
    _ sid: ALuint,
    _ param: ALenum,
    _ value1: UnsafeMutablePointer<ALfloat>!,
    _ value2: UnsafeMutablePointer<ALfloat>!,
    _ value3: UnsafeMutablePointer<ALfloat>!
) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let value1, let value2, let value3 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            let vec: Vec3
            switch param {
            case AL_POSITION: vec = source.position
            case AL_VELOCITY: vec = source.velocity
            case AL_DIRECTION: vec = source.direction
            default:
                ctx.setError(AL_INVALID_ENUM)
                return
            }
            value1.pointee = vec.x
            value2.pointee = vec.y
            value3.pointee = vec.z
        }
    }
}

public func alGetSourcefv(_ sid: ALuint, _ param: ALenum, _ values: UnsafeMutablePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_POSITION: storeVec3(source.position, values)
            case AL_VELOCITY: storeVec3(source.velocity, values)
            case AL_DIRECTION: storeVec3(source.direction, values)
            default:
                var scalar: ALfloat = 0
                alGetSourcefUnlocked(ctx, source, param, &scalar)
                values[0] = scalar
            }
        }
    }
}

private func alGetSourcefUnlocked(_ ctx: ALContextObject, _ source: ALSourceObject, _ param: ALenum, _ value: inout ALfloat) {
    switch param {
    case AL_PITCH: value = source.pitch
    case AL_GAIN: value = source.gain
    case AL_MIN_GAIN: value = source.minGain
    case AL_MAX_GAIN: value = source.maxGain
    case AL_MAX_DISTANCE: value = source.maxDistance
    case AL_ROLLOFF_FACTOR: value = source.rolloff
    case AL_CONE_OUTER_GAIN: value = source.coneOuterGain
    case AL_CONE_INNER_ANGLE: value = source.coneInner
    case AL_CONE_OUTER_ANGLE: value = source.coneOuter
    case AL_REFERENCE_DISTANCE: value = source.refDistance
    case AL_SEC_OFFSET: value = source.secOffset
    case AL_SAMPLE_OFFSET: value = ALfloat(source.sampleOffset)
    case AL_BYTE_OFFSET: value = ALfloat(source.byteOffset)
    default: ctx.setError(AL_INVALID_ENUM)
    }
}

public func alGetSourcei(_ sid: ALuint, _ param: ALenum, _ value: UnsafeMutablePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let value else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_SOURCE_RELATIVE: value.pointee = source.relative
            case AL_LOOPING: value.pointee = source.looping
            case AL_BUFFER: value.pointee = ALint(source.type == AL_STATIC ? (source.queue.first ?? 0) : 0)
            case AL_SOURCE_STATE: value.pointee = source.state
            case AL_BUFFERS_QUEUED: value.pointee = ALint(source.queue.count)
            case AL_BUFFERS_PROCESSED: value.pointee = ALint(source.processed)
            case AL_SOURCE_TYPE: value.pointee = source.type
            case AL_BYTE_OFFSET: value.pointee = source.byteOffset
            case AL_SAMPLE_OFFSET: value.pointee = source.sampleOffset
            case AL_SEC_OFFSET: value.pointee = ALint(source.secOffset)
            default: ctx.setError(AL_INVALID_ENUM)
            }
        }
    }
}

public func alGetSource3i(
    _ sid: ALuint,
    _ param: ALenum,
    _ value1: UnsafeMutablePointer<ALint>!,
    _ value2: UnsafeMutablePointer<ALint>!,
    _ value3: UnsafeMutablePointer<ALint>!
) {
    var x: ALfloat = 0
    var y: ALfloat = 0
    var z: ALfloat = 0
    alGetSource3f(sid, param, &x, &y, &z)
    if let value1 { value1.pointee = ALint(x) }
    if let value2 { value2.pointee = ALint(y) }
    if let value3 { value3.pointee = ALint(z) }
}

public func alGetSourceiv(_ sid: ALuint, _ param: ALenum, _ values: UnsafeMutablePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard let values else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            switch param {
            case AL_POSITION:
                values[0] = ALint(source.position.x)
                values[1] = ALint(source.position.y)
                values[2] = ALint(source.position.z)
            case AL_VELOCITY:
                values[0] = ALint(source.velocity.x)
                values[1] = ALint(source.velocity.y)
                values[2] = ALint(source.velocity.z)
            case AL_DIRECTION:
                values[0] = ALint(source.direction.x)
                values[1] = ALint(source.direction.y)
                values[2] = ALint(source.direction.z)
            default:
                alGetSourcei(sid, param, values)
            }
        }
    }
}

private func playSource(_ source: ALSourceObject) {
    setSourcePlaying(source)
}

private func pauseSource(_ source: ALSourceObject) {
    if source.state == AL_PLAYING {
        source.state = AL_PAUSED
    }
}

private func stopSource(_ source: ALSourceObject) {
    if source.state != AL_INITIAL {
        setSourceStopped(source)
    }
}

private func rewindSource(_ source: ALSourceObject) {
    source.state = AL_INITIAL
    source.processed = 0
    source.secOffset = 0
    source.sampleOffset = 0
    source.byteOffset = 0
}

public func alSourcePlay(_ sid: ALuint) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            playSource(source)
        }
    }
}

public func alSourcePlayv(_ ns: ALsizei, _ sids: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard ns >= 0, let sids else {
                if ns < 0 { ctx.setError(AL_INVALID_VALUE) }
                return
            }
            for index in 0..<Int(ns) {
                guard let source = requireSource(ctx, sids[index]) else { return }
                playSource(source)
            }
        }
    }
}

public func alSourcePause(_ sid: ALuint) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            pauseSource(source)
        }
    }
}

public func alSourcePausev(_ ns: ALsizei, _ sids: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard ns >= 0, let sids else {
                if ns < 0 { ctx.setError(AL_INVALID_VALUE) }
                return
            }
            for index in 0..<Int(ns) {
                guard let source = requireSource(ctx, sids[index]) else { return }
                pauseSource(source)
            }
        }
    }
}

public func alSourceStop(_ sid: ALuint) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            stopSource(source)
        }
    }
}

public func alSourceStopv(_ ns: ALsizei, _ sids: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard ns >= 0, let sids else {
                if ns < 0 { ctx.setError(AL_INVALID_VALUE) }
                return
            }
            for index in 0..<Int(ns) {
                guard let source = requireSource(ctx, sids[index]) else { return }
                stopSource(source)
            }
        }
    }
}

public func alSourceRewind(_ sid: ALuint) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            rewindSource(source)
        }
    }
}

public func alSourceRewindv(_ ns: ALsizei, _ sids: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard ns >= 0, let sids else {
                if ns < 0 { ctx.setError(AL_INVALID_VALUE) }
                return
            }
            for index in 0..<Int(ns) {
                guard let source = requireSource(ctx, sids[index]) else { return }
                rewindSource(source)
            }
        }
    }
}

public func alSourceQueueBuffers(_ sid: ALuint, _ numEntries: ALsizei, _ bids: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard numEntries >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if numEntries == 0 { return }
            guard let bids else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if source.type == AL_STATIC {
                ctx.setError(AL_INVALID_OPERATION)
                return
            }
            var names: [ALuint] = []
            for index in 0..<Int(numEntries) {
                let bid = bids[index]
                guard ctx.buffers[bid] != nil else {
                    ctx.setError(AL_INVALID_VALUE)
                    return
                }
                names.append(bid)
            }
            source.queue.append(contentsOf: names)
            source.type = AL_STREAMING
        }
    }
}

public func alSourceUnqueueBuffers(_ sid: ALuint, _ numEntries: ALsizei, _ bids: UnsafeMutablePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard let source = requireSource(ctx, sid) else { return }
            guard numEntries >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if numEntries == 0 { return }
            guard let bids else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            guard numEntries <= source.processed else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            for index in 0..<Int(numEntries) {
                bids[index] = source.queue.removeFirst()
            }
            source.processed -= Int(numEntries)
            if source.queue.isEmpty {
                source.type = AL_UNDETERMINED
            }
        }
    }
}

// MARK: - Buffers

public func alGenBuffers(_ n: ALsizei, _ buffers: UnsafeMutablePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard n >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if n == 0 { return }
            guard let buffers else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            let names = ctx.generateNames(n)
            for (index, name) in names.enumerated() {
                ctx.buffers[name] = ALBufferObject()
                buffers[index] = name
            }
        }
    }
}

public func alDeleteBuffers(_ n: ALsizei, _ buffers: UnsafePointer<ALuint>!) {
    alLocked {
        withCurrent { ctx in
            guard n >= 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if n == 0 { return }
            guard let buffers else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            for index in 0..<Int(n) {
                let name = buffers[index]
                if name == 0 { continue }
                guard ctx.buffers[name] != nil else {
                    ctx.setError(AL_INVALID_NAME)
                    return
                }
                if bufferInUse(ctx, name) {
                    ctx.setError(AL_INVALID_OPERATION)
                    return
                }
            }
            for index in 0..<Int(n) {
                ctx.buffers[buffers[index]] = nil
            }
        }
    }
}

public func alIsBuffer(_ bid: ALuint) -> ALboolean {
    alLocked {
        withCurrentRet(0) { ctx in
            ctx.buffers[bid] != nil ? 1 : 0
        }
    }
}

public func alBufferData(_ bid: ALuint, _ format: ALenum, _ data: UnsafeRawPointer!, _ size: ALsizei, _ freq: ALsizei) {
    alLocked {
        withCurrent { ctx in
            guard let buffer = ctx.buffers[bid] else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            if bufferInUse(ctx, bid) {
                ctx.setError(AL_INVALID_OPERATION)
                return
            }
            guard let info = BufferFormatInfo.info(format) else {
                ctx.setError(AL_INVALID_ENUM)
                return
            }
            guard size >= 0, freq > 0 else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if size > 0 && Int(size) % info.frame != 0 {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            if size > 0 && data == nil {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            buffer.format = format
            buffer.frequency = freq
            buffer.bits = info.bits
            buffer.channels = info.channels
            if size == 0 {
                buffer.data = []
            } else {
                let bytes = UnsafeRawBufferPointer(start: data, count: Int(size))
                buffer.data = Array(bytes)
            }
        }
    }
}

private func getBufferi(_ ctx: ALContextObject, _ buffer: ALBufferObject, _ param: ALenum, _ value: UnsafeMutablePointer<ALint>) {
    switch param {
    case AL_FREQUENCY: value.pointee = ALint(buffer.frequency)
    case AL_BITS: value.pointee = buffer.bits
    case AL_CHANNELS: value.pointee = buffer.channels
    case AL_SIZE: value.pointee = ALint(buffer.data.count)
    default: ctx.setError(AL_INVALID_ENUM)
    }
}

public func alBufferf(_ bid: ALuint, _ param: ALenum, _ value: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = value
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alBuffer3f(_ bid: ALuint, _ param: ALenum, _ value1: ALfloat, _ value2: ALfloat, _ value3: ALfloat) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = value1
            _ = value2
            _ = value3
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alBufferfv(_ bid: ALuint, _ param: ALenum, _ values: UnsafePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = values
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alBufferi(_ bid: ALuint, _ param: ALenum, _ value: ALint) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = value
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alBuffer3i(_ bid: ALuint, _ param: ALenum, _ value1: ALint, _ value2: ALint, _ value3: ALint) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = value1
            _ = value2
            _ = value3
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alBufferiv(_ bid: ALuint, _ param: ALenum, _ values: UnsafePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = values
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alGetBufferf(_ bid: ALuint, _ param: ALenum, _ value: UnsafeMutablePointer<ALfloat>!) {
    alLocked {
        withCurrent { ctx in
            guard let buffer = ctx.buffers[bid] else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            guard let value else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            var integer: ALint = 0
            getBufferi(ctx, buffer, param, &integer)
            if ctx.error == AL_NO_ERROR {
                value.pointee = ALfloat(integer)
            }
        }
    }
}

public func alGetBuffer3f(
    _ bid: ALuint,
    _ param: ALenum,
    _ value1: UnsafeMutablePointer<ALfloat>!,
    _ value2: UnsafeMutablePointer<ALfloat>!,
    _ value3: UnsafeMutablePointer<ALfloat>!
) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = value1
            _ = value2
            _ = value3
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alGetBufferfv(_ bid: ALuint, _ param: ALenum, _ values: UnsafeMutablePointer<ALfloat>!) {
    alGetBufferf(bid, param, values)
}

public func alGetBufferi(_ bid: ALuint, _ param: ALenum, _ value: UnsafeMutablePointer<ALint>!) {
    alLocked {
        withCurrent { ctx in
            guard let buffer = ctx.buffers[bid] else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            guard let value else {
                ctx.setError(AL_INVALID_VALUE)
                return
            }
            getBufferi(ctx, buffer, param, value)
        }
    }
}

public func alGetBuffer3i(
    _ bid: ALuint,
    _ param: ALenum,
    _ value1: UnsafeMutablePointer<ALint>!,
    _ value2: UnsafeMutablePointer<ALint>!,
    _ value3: UnsafeMutablePointer<ALint>!
) {
    alLocked {
        withCurrent { ctx in
            guard ctx.buffers[bid] != nil else {
                ctx.setError(AL_INVALID_NAME)
                return
            }
            _ = param
            _ = value1
            _ = value2
            _ = value3
            ctx.setError(AL_INVALID_ENUM)
        }
    }
}

public func alGetBufferiv(_ bid: ALuint, _ param: ALenum, _ values: UnsafeMutablePointer<ALint>!) {
    alGetBufferi(bid, param, values)
}
