import Foundation
#if os(Linux)
import Glibc
#endif

public struct AudioQueueProcessingTapFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
}

/// Queue buffer record. `mPacketDescriptions` is an opaque pointer on
/// isolated Linux because `AudioStreamPacketDescription` belongs to
/// CoreAudioTypes. The stored field is still a pointer-sized C slot.
@frozen
public struct AudioQueueBuffer {
    public private(set) var mAudioDataBytesCapacity: UInt32
    public private(set) var mAudioData: UnsafeMutableRawPointer
    public var mAudioDataByteSize: UInt32
    public var mUserData: UnsafeMutableRawPointer?
    public private(set) var mPacketDescriptionCapacity: UInt32
    public private(set) var mPacketDescriptions: UnsafeMutableRawPointer?
    public var mPacketDescriptionCount: UInt32

    public init(
        mAudioDataBytesCapacity: UInt32,
        mAudioData: UnsafeMutableRawPointer,
        mAudioDataByteSize: UInt32,
        mUserData: UnsafeMutableRawPointer?,
        mPacketDescriptionCapacity: UInt32,
        mPacketDescriptions: UnsafeMutableRawPointer?,
        mPacketDescriptionCount: UInt32
    ) {
        self.mAudioDataBytesCapacity = mAudioDataBytesCapacity
        self.mAudioData = mAudioData
        self.mAudioDataByteSize = mAudioDataByteSize
        self.mUserData = mUserData
        self.mPacketDescriptionCapacity = mPacketDescriptionCapacity
        self.mPacketDescriptions = mPacketDescriptions
        self.mPacketDescriptionCount = mPacketDescriptionCount
    }
}

public typealias AudioQueueBufferRef = UnsafeMutablePointer<AudioQueueBuffer>
public typealias AudioQueueOutputCallback = (
    UnsafeMutableRawPointer?,
    AudioQueueRef,
    AudioQueueBufferRef
) -> Void

internal final class ATAudioQueueBufferOwner {
    let pointer: UnsafeMutablePointer<AudioQueueBuffer>
    let data: UnsafeMutableRawPointer
    let dataCapacity: Int
    let packetStorage: UnsafeMutableRawPointer?
    var enqueued = false
    var trimStartFrames: UInt32 = 0
    var trimEndFrames: UInt32 = 0

    init(
        pointer: UnsafeMutablePointer<AudioQueueBuffer>,
        data: UnsafeMutableRawPointer,
        dataCapacity: Int,
        packetStorage: UnsafeMutableRawPointer?
    ) {
        self.pointer = pointer
        self.data = data
        self.dataCapacity = dataCapacity
        self.packetStorage = packetStorage
    }

    deinit {
        data.deallocate()
        packetStorage?.deallocate()
        pointer.deallocate()
    }
}

internal final class ATAudioQueueObject: ATObject {
    let lock = NSLock()
    var buffers: [ObjectIdentifier: ATAudioQueueBufferOwner] = [:]
    var started = false
    var paused = false
    var isInput = false
    var outputCallback: AudioQueueOutputCallback?
    var inputCallback: AudioQueueInputCallback?
    var callbackUserData: UnsafeMutableRawPointer?
    var callbackInvocations: UInt64 = 0
    var format = ATASBD()
    var enqueued: [ATAudioQueueBufferOwner] = []
    var levelMetering = false
    var sampleTime: Float64 = 0
    var listeners: [(id: AudioQueuePropertyID, proc: AudioQueuePropertyListenerProc, user: UnsafeMutableRawPointer?)] = []
    var renderedPCM = Data()
    var volume: AudioQueueParameterValue = 1
    var pan: AudioQueueParameterValue = 0
    var playRate: AudioQueueParameterValue = 1
    var pitch: AudioQueueParameterValue = 0
    var volumeRampTime: AudioQueueParameterValue = 0
}

public func AudioQueueAllocateBuffer(
    _ inAQ: AudioQueueRef?,
    _ inBufferByteSize: UInt32,
    _ outBuffer: UnsafeMutablePointer<AudioQueueBufferRef?>?
) -> Int32 {
    outBuffer?.pointee = nil
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    if inBufferByteSize == 0 {
        return kAudioQueueErr_InvalidParameter
    }
    if inBufferByteSize > 1 << 24 {
        return kAudioQueueErr_InvalidParameter
    }
    return atWithLock(queue.lock) {
        let data = UnsafeMutableRawPointer.allocate(
            byteCount: Int(inBufferByteSize),
            alignment: MemoryLayout<UInt8>.alignment
        )
        data.initializeMemory(as: UInt8.self, repeating: 0, count: Int(inBufferByteSize))
        let pointer = UnsafeMutablePointer<AudioQueueBuffer>.allocate(capacity: 1)
        pointer.initialize(
            to: AudioQueueBuffer(
                mAudioDataBytesCapacity: inBufferByteSize,
                mAudioData: data,
                mAudioDataByteSize: 0,
                mUserData: nil,
                mPacketDescriptionCapacity: 0,
                mPacketDescriptions: nil,
                mPacketDescriptionCount: 0
            )
        )
        let owner = ATAudioQueueBufferOwner(
            pointer: pointer,
            data: data,
            dataCapacity: Int(inBufferByteSize),
            packetStorage: nil
        )
        queue.buffers[ObjectIdentifier(owner)] = owner
        outBuffer?.pointee = pointer
        return 0
    }
}

public func AudioQueueAllocateBufferWithPacketDescriptions(
    _ inAQ: AudioQueueRef?,
    _ inBufferByteSize: UInt32,
    _ inNumberPacketDescriptions: UInt32,
    _ outBuffer: UnsafeMutablePointer<AudioQueueBufferRef?>?
) -> Int32 {
    outBuffer?.pointee = nil
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    if inBufferByteSize == 0 {
        return kAudioQueueErr_InvalidParameter
    }
    if inNumberPacketDescriptions > 1 << 20 {
        return kAudioQueueErr_InvalidParameter
    }
    return atWithLock(queue.lock) {
        let data = UnsafeMutableRawPointer.allocate(
            byteCount: Int(inBufferByteSize),
            alignment: MemoryLayout<UInt8>.alignment
        )
        data.initializeMemory(as: UInt8.self, repeating: 0, count: Int(inBufferByteSize))
        var packetStorage: UnsafeMutableRawPointer?
        if inNumberPacketDescriptions > 0 {
            let bytes = Int(inNumberPacketDescriptions) * 16
            let storage = UnsafeMutableRawPointer.allocate(
                byteCount: bytes,
                alignment: 8
            )
            storage.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
            packetStorage = storage
        }
        let pointer = UnsafeMutablePointer<AudioQueueBuffer>.allocate(capacity: 1)
        pointer.initialize(
            to: AudioQueueBuffer(
                mAudioDataBytesCapacity: inBufferByteSize,
                mAudioData: data,
                mAudioDataByteSize: 0,
                mUserData: nil,
                mPacketDescriptionCapacity: inNumberPacketDescriptions,
                mPacketDescriptions: packetStorage,
                mPacketDescriptionCount: 0
            )
        )
        let owner = ATAudioQueueBufferOwner(
            pointer: pointer,
            data: data,
            dataCapacity: Int(inBufferByteSize),
            packetStorage: packetStorage
        )
        queue.buffers[ObjectIdentifier(owner)] = owner
        outBuffer?.pointee = pointer
        return 0
    }
}

public func AudioQueueFreeBuffer(
    _ inAQ: AudioQueueRef?,
    _ inBuffer: AudioQueueBufferRef?
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    guard let inBuffer else { return kAudioQueueErr_InvalidBuffer }
    return atWithLock(queue.lock) {
        guard let owner = queue.buffers.first(where: { $0.value.pointer == inBuffer })?.value else {
            return kAudioQueueErr_InvalidBuffer
        }
        if owner.enqueued {
            return kAudioQueueErr_BufferInQueue
        }
        queue.buffers[ObjectIdentifier(owner)] = nil
        return 0
    }
}

public func AudioQueueEnqueueBuffer(
    _ inAQ: AudioQueueRef?,
    _ inBuffer: AudioQueueBufferRef?,
    _ inNumPacketDescs: UInt32,
    _ inPacketDescs: UnsafeRawPointer?
) -> Int32 {
    _ = inNumPacketDescs
    _ = inPacketDescs
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    guard let inBuffer else { return kAudioQueueErr_InvalidBuffer }
    return atWithLock(queue.lock) {
        guard let owner = queue.buffers.first(where: { $0.value.pointer == inBuffer })?.value else {
            return kAudioQueueErr_InvalidBuffer
        }
        if owner.enqueued {
            return kAudioQueueErr_BufferEnqueuedTwice
        }
        if inBuffer.pointee.mAudioDataByteSize > inBuffer.pointee.mAudioDataBytesCapacity {
            return kAudioQueueErr_InvalidParameter
        }
        owner.enqueued = true
        owner.trimStartFrames = 0
        owner.trimEndFrames = 0
        if !queue.enqueued.contains(where: { $0 === owner }) {
            queue.enqueued.append(owner)
        }
        return 0
    }
}

public func AudioQueueEnqueueBufferWithParameters(
    _ inAQ: AudioQueueRef?,
    _ inBuffer: AudioQueueBufferRef?,
    _ inNumPacketDescs: UInt32,
    _ inPacketDescs: UnsafeRawPointer?,
    _ inTrimFramesAtStart: UInt32,
    _ inTrimFramesAtEnd: UInt32,
    _ inNumParamValues: UInt32,
    _ inParamValues: UnsafePointer<AudioQueueParameterEvent>?,
    _ inStartTime: UnsafeRawPointer?,
    _ outActualStartTime: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inStartTime
    if let outActualStartTime {
        outActualStartTime.initializeMemory(as: UInt8.self, repeating: 0, count: 64)
    }
    if let inParamValues {
        var index = 0
        while index < Int(inNumParamValues) {
            let event = inParamValues.advanced(by: index).pointee
            if event.mID == kAudioQueueParam_Volume
                || event.mID == kAudioQueueParam_Pan
                || event.mID == kAudioQueueParam_PlayRate
                || event.mID == kAudioQueueParam_Pitch
                || event.mID == kAudioQueueParam_VolumeRampTime
            {
                let status = AudioQueueSetParameter(inAQ, event.mID, event.mValue)
                if status != 0 {
                    return status
                }
            }
            index += 1
        }
    }
    let status = AudioQueueEnqueueBuffer(inAQ, inBuffer, inNumPacketDescs, inPacketDescs)
    if status != 0 {
        return status
    }
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self),
          let inBuffer
    else {
        return status
    }
    return atWithLock(queue.lock) {
        if let owner = queue.buffers.first(where: { $0.value.pointer == inBuffer })?.value {
            owner.trimStartFrames = inTrimFramesAtStart
            owner.trimEndFrames = inTrimFramesAtEnd
        }
        return 0
    }
}

public func AudioQueueOfflineRender(
    _ inAQ: AudioQueueRef?,
    _ inTimestamp: UnsafeRawPointer?,
    _ ioBuffer: AudioQueueBufferRef?,
    _ inNumberFrames: UInt32
) -> Int32 {
    _ = inTimestamp
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    guard let ioBuffer else { return kAudioQueueErr_InvalidBuffer }
    return atWithLock(queue.lock) {
        let bytesPerFrame = max(Int(queue.format.mBytesPerFrame), 1)
        let want = Int(inNumberFrames) * bytesPerFrame
        if want > Int(ioBuffer.pointee.mAudioDataBytesCapacity) {
            return kAudioQueueErr_InvalidParameter
        }
        guard let owner = queue.enqueued.first else {
            memset(ioBuffer.pointee.mAudioData, 0, want)
            ioBuffer.pointee.mAudioDataByteSize = UInt32(want)
            return 0
        }
        queue.enqueued.removeFirst()
        owner.enqueued = false
        let startSkip = Int(owner.trimStartFrames) * bytesPerFrame
        let endSkip = Int(owner.trimEndFrames) * bytesPerFrame
        let sourceBytes = Int(owner.pointer.pointee.mAudioDataByteSize)
        let available = max(sourceBytes - startSkip - endSkip, 0)
        let copyCount = min(want, available)
        if copyCount > 0 {
            memcpy(
                ioBuffer.pointee.mAudioData,
                owner.data.advanced(by: startSkip),
                copyCount
            )
        }
        if copyCount < want {
            memset(ioBuffer.pointee.mAudioData.advanced(by: copyCount), 0, want - copyCount)
        }
        ioBuffer.pointee.mAudioDataByteSize = UInt32(want)
        let copied = Data(bytes: ioBuffer.pointee.mAudioData, count: want)
        queue.renderedPCM.append(copied)
        return 0
    }
}

public func AudioQueueDispose(
    _ inAQ: AudioQueueRef?,
    _ inImmediate: Bool
) -> Int32 {
    _ = inImmediate
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return 0
    }
    atWithLock(queue.lock) {
        queue.buffers.removeAll()
        queue.started = false
    }
    return ATRegistry.shared.release(inAQ) == atParamError ? 0 : 0
}

@_cdecl("AudioQueueStart")
public func AudioQueueStart(
    _ inAQ: AudioQueueRef?,
    _ inStartTime: UnsafeRawPointer?
) -> Int32 {
    _ = inStartTime
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    if queue.format.mFormatID != 0 && queue.format.mFormatID != atFormatLinearPCM {
        return kAudioQueueErr_CodecNotFound
    }
    return atWithLock(queue.lock) {
        queue.started = true
        queue.paused = false
        atNotifyAudioQueue(queue, kAudioQueueProperty_IsRunning)
        atPumpAudioQueue(queue)
        return 0
    }
}

internal func atNotifyAudioQueue(_ queue: ATAudioQueueObject, _ id: AudioQueuePropertyID) {
    let handle = OpaquePointer(Unmanaged.passUnretained(queue).toOpaque())
    for listener in queue.listeners where listener.id == id {
        listener.proc(listener.user, handle, id)
    }
}

public func AudioQueueAddPropertyListener(
    _ inAQ: AudioQueueRef?,
    _ inID: AudioQueuePropertyID,
    _ inProc: AudioQueuePropertyListenerProc?,
    _ inUserData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    guard let inProc else { return kAudioQueueErr_InvalidParameter }
    return atWithLock(queue.lock) {
        queue.listeners.append((id: inID, proc: inProc, user: inUserData))
        return 0
    }
}

public func AudioQueueRemovePropertyListener(
    _ inAQ: AudioQueueRef?,
    _ inID: AudioQueuePropertyID,
    _ inProc: AudioQueuePropertyListenerProc?,
    _ inUserData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    return atWithLock(queue.lock) {
        queue.listeners.removeAll { listener in
            listener.id == inID && listener.user == inUserData
        }
        _ = inProc
        return 0
    }
}

internal func atPumpAudioQueue(_ queue: ATAudioQueueObject) {
    var pumps = 0
    while queue.started && !queue.paused && pumps < 32 {
        if queue.isInput {
            guard let owner = queue.enqueued.first else { break }
            queue.enqueued.removeFirst()
            owner.enqueued = false
            let frames = owner.dataCapacity / max(Int(queue.format.mBytesPerFrame), 1)
            memset(owner.data, 0, owner.dataCapacity)
            owner.pointer.pointee.mAudioDataByteSize = UInt32(min(owner.dataCapacity, frames * Int(max(queue.format.mBytesPerFrame, 1))))
            queue.callbackInvocations += 1
            queue.sampleTime += Float64(frames)
            let user = queue.callbackUserData
            let callback = queue.inputCallback
            let buffer = owner.pointer
            queue.lock.unlock()
            callback?(user, OpaquePointer(Unmanaged.passUnretained(queue).toOpaque()), buffer, nil, 0, nil)
            queue.lock.lock()
            pumps += 1
            continue
        }
        guard let owner = queue.enqueued.first else { break }
        queue.enqueued.removeFirst()
        owner.enqueued = false
        let byteSize = Int(owner.pointer.pointee.mAudioDataByteSize)
        if byteSize > 0 {
            let count = min(byteSize, owner.dataCapacity)
            if queue.volume != 1 {
                var scaled = Data(count: count)
                scaled.withUnsafeMutableBytes { destRaw in
                    _ = atMixPCM(
                        inputs: [
                            (
                                format: queue.format,
                                bytes: UnsafeRawPointer(owner.data),
                                byteCount: count,
                                gain: queue.volume
                            )
                        ],
                        dest: queue.format,
                        output: destRaw.baseAddress!,
                        outputByteCapacity: destRaw.count
                    )
                }
                queue.renderedPCM.append(scaled)
            } else {
                queue.renderedPCM.append(Data(bytes: owner.data, count: count))
            }
        }
        let frames = Int(owner.pointer.pointee.mAudioDataByteSize) / max(Int(queue.format.mBytesPerFrame), 1)
        queue.sampleTime += Float64(max(frames, 1))
        queue.callbackInvocations += 1
        let user = queue.callbackUserData
        let callback = queue.outputCallback
        let buffer = owner.pointer
        queue.lock.unlock()
        callback?(user, OpaquePointer(Unmanaged.passUnretained(queue).toOpaque()), buffer)
        queue.lock.lock()
        pumps += 1
    }
}

public func AudioQueueStop(
    _ inAQ: AudioQueueRef?,
    _ inImmediate: Bool
) -> Int32 {
    _ = inImmediate
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    return atWithLock(queue.lock) {
        queue.started = false
        queue.paused = false
        atNotifyAudioQueue(queue, kAudioQueueProperty_IsRunning)
        return 0
    }
}

@_cdecl("AudioQueuePause")
public func AudioQueuePause(_ inAQ: AudioQueueRef?) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    return atWithLock(queue.lock) {
        queue.paused = true
        atNotifyAudioQueue(queue, kAudioQueueProperty_IsRunning)
        return 0
    }
}

@_cdecl("AudioQueueReset")
public func AudioQueueReset(_ inAQ: AudioQueueRef?) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    return atWithLock(queue.lock) {
        for owner in queue.buffers.values {
            owner.enqueued = false
        }
        queue.enqueued.removeAll()
        return 0
    }
}

@_cdecl("AudioQueueFlush")
public func AudioQueueFlush(_ inAQ: AudioQueueRef?) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    return atWithLock(queue.lock) {
        if queue.started && !queue.paused {
            atPumpAudioQueue(queue)
        }
        return 0
    }
}

/// Creates an in-process PCM output queue. An offline clock pumps enqueued
/// buffers and invokes the output callback; there is no hardware device.
public func AudioQueueNewOutput(
    _ inFormat: UnsafeRawPointer?,
    _ inCallbackProc: AudioQueueOutputCallback?,
    _ inUserData: UnsafeMutableRawPointer?,
    _ inCallbackRunLoop: UnsafeRawPointer?,
    _ inCallbackRunLoopMode: UnsafeRawPointer?,
    _ inFlags: UInt32,
    _ outAQ: UnsafeMutablePointer<AudioQueueRef?>?
) -> Int32 {
    _ = inCallbackRunLoop
    _ = inCallbackRunLoopMode
    _ = inFlags
    outAQ?.pointee = nil
    guard let inFormat, var format = atLoadASBD(inFormat) else {
        return kAudioQueueErr_InvalidParameter
    }
    if format.mFormatID != 0 && format.mFormatID != atFormatLinearPCM {
        return kAudioQueueErr_CodecNotFound
    }
    if format.mFormatID == atFormatLinearPCM {
        if format.validatePCM() != 0 {
            return kAudioQueueErr_InvalidParameter
        }
        atFillPCMASBD(&format)
    }
    let queue = ATAudioQueueObject()
    queue.format = format
    queue.outputCallback = inCallbackProc
    queue.callbackUserData = inUserData
    outAQ?.pointee = ATRegistry.shared.retain(queue)
    return 0
}

public func AudioQueueNewInput(
    _ inFormat: UnsafeRawPointer?,
    _ inCallbackProc: AudioQueueInputCallback?,
    _ inUserData: UnsafeMutableRawPointer?,
    _ inCallbackRunLoop: UnsafeRawPointer?,
    _ inCallbackRunLoopMode: UnsafeRawPointer?,
    _ inFlags: UInt32,
    _ outAQ: UnsafeMutablePointer<AudioQueueRef?>?
) -> Int32 {
    _ = inCallbackRunLoop
    _ = inCallbackRunLoopMode
    _ = inFlags
    outAQ?.pointee = nil
    guard let inFormat, var format = atLoadASBD(inFormat) else {
        return kAudioQueueErr_InvalidParameter
    }
    if format.mFormatID != 0 && format.mFormatID != atFormatLinearPCM {
        return kAudioQueueErr_CodecNotFound
    }
    if format.mFormatID == atFormatLinearPCM {
        if format.validatePCM() != 0 {
            return kAudioQueueErr_InvalidParameter
        }
        atFillPCMASBD(&format)
    }
    let queue = ATAudioQueueObject()
    queue.format = format
    queue.isInput = true
    queue.inputCallback = inCallbackProc
    queue.callbackUserData = inUserData
    outAQ?.pointee = ATRegistry.shared.retain(queue)
    return 0
}

public func AudioQueueGetProperty(
    _ inAQ: AudioQueueRef?,
    _ inID: AudioQueuePropertyID,
    _ outData: UnsafeMutableRawPointer?,
    _ ioDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    switch inID {
    case kAudioQueueProperty_IsRunning:
        ioDataSize?.pointee = 4
        let running: UInt32 = (queue.started && !queue.paused) ? 1 : 0
        outData?.storeBytes(of: running, as: UInt32.self)
        return 0
    case kAudioQueueProperty_StreamDescription:
        if let ioDataSize, ioDataSize.pointee < UInt32(atASBDSize) {
            return kAudioQueueErr_InvalidPropertySize
        }
        ioDataSize?.pointee = UInt32(atASBDSize)
        if let outData { atStoreASBD(queue.format, to: outData) }
        return 0
    case kAudioQueueDeviceProperty_SampleRate:
        ioDataSize?.pointee = 8
        outData?.storeBytes(of: queue.format.mSampleRate, as: Float64.self)
        return 0
    case kAudioQueueDeviceProperty_NumberChannels:
        ioDataSize?.pointee = 4
        outData?.storeBytes(of: queue.format.mChannelsPerFrame, as: UInt32.self)
        return 0
    case kAudioQueueProperty_EnableLevelMetering:
        ioDataSize?.pointee = 4
        let enabled: UInt32 = queue.levelMetering ? 1 : 0
        outData?.storeBytes(of: enabled, as: UInt32.self)
        return 0
    case kAudioQueueProperty_MaximumOutputPacketSize:
        ioDataSize?.pointee = 4
        outData?.storeBytes(of: queue.format.mBytesPerPacket, as: UInt32.self)
        return 0
    default:
        return kAudioQueueErr_InvalidProperty
    }
}

public func AudioQueueGetPropertySize(
    _ inAQ: AudioQueueRef?,
    _ inID: AudioQueuePropertyID,
    _ outDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) != nil else {
        return kAudioQueueErr_QueueInvalidated
    }
    switch inID {
    case kAudioQueueProperty_StreamDescription:
        outDataSize?.pointee = UInt32(atASBDSize)
    case kAudioQueueDeviceProperty_SampleRate:
        outDataSize?.pointee = 8
    default:
        outDataSize?.pointee = 4
    }
    return 0
}

public func AudioQueueSetProperty(
    _ inAQ: AudioQueueRef?,
    _ inID: AudioQueuePropertyID,
    _ inData: UnsafeRawPointer?,
    _ inDataSize: UInt32
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    if inID == kAudioQueueProperty_EnableLevelMetering {
        guard let inData, inDataSize >= 4 else { return kAudioQueueErr_InvalidPropertySize }
        queue.levelMetering = inData.loadUnaligned(as: UInt32.self) != 0
        return 0
    }
    if inID == kAudioQueueProperty_MagicCookie {
        return 0
    }
    return kAudioQueueErr_InvalidProperty
}

@_cdecl("AudioQueueGetParameter")
public func AudioQueueGetParameter(
    _ inAQ: AudioQueueRef?,
    _ inParamID: AudioQueueParameterID,
    _ outValue: UnsafeMutablePointer<AudioQueueParameterValue>?
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    switch inParamID {
    case kAudioQueueParam_Volume: outValue?.pointee = queue.volume
    case kAudioQueueParam_PlayRate: outValue?.pointee = queue.playRate
    case kAudioQueueParam_Pitch: outValue?.pointee = queue.pitch
    case kAudioQueueParam_VolumeRampTime: outValue?.pointee = queue.volumeRampTime
    case kAudioQueueParam_Pan: outValue?.pointee = queue.pan
    default:
        return kAudioQueueErr_InvalidParameter
    }
    return 0
}

@_cdecl("AudioQueueSetParameter")
public func AudioQueueSetParameter(
    _ inAQ: AudioQueueRef?,
    _ inParamID: AudioQueueParameterID,
    _ inValue: AudioQueueParameterValue
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    switch inParamID {
    case kAudioQueueParam_Volume: queue.volume = inValue
    case kAudioQueueParam_PlayRate: queue.playRate = inValue
    case kAudioQueueParam_Pitch: queue.pitch = inValue
    case kAudioQueueParam_VolumeRampTime: queue.volumeRampTime = inValue
    case kAudioQueueParam_Pan: queue.pan = inValue
    default:
        return kAudioQueueErr_InvalidParameter
    }
    return 0
}

@_cdecl("AudioQueuePrime")
public func AudioQueuePrime(
    _ inAQ: AudioQueueRef?,
    _ inNumberOfFramesToPrepare: UInt32,
    _ outNumberOfFramesPrepared: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    outNumberOfFramesPrepared?.pointee = inNumberOfFramesToPrepare
    _ = queue
    return 0
}

public func AudioQueueGetCurrentTime(
    _ inAQ: AudioQueueRef?,
    _ inTimeline: AudioQueueTimelineRef?,
    _ outTimeStamp: UnsafeMutableRawPointer?,
    _ outTimelineDiscontinuity: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    _ = inTimeline
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    outTimeStamp?.storeBytes(of: queue.sampleTime, toByteOffset: 0, as: Float64.self)
    outTimelineDiscontinuity?.pointee = 0
    return 0
}

public func AudioQueueDeviceGetCurrentTime(
    _ inAQ: AudioQueueRef?,
    _ outTimeStamp: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inAQ
    _ = outTimeStamp
    return kAudioQueueErr_InvalidDevice
}

public func AudioQueueDeviceTranslateTime(
    _ inAQ: AudioQueueRef?,
    _ inTime: UnsafeRawPointer?,
    _ outTime: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inAQ
    _ = inTime
    _ = outTime
    return kAudioQueueErr_InvalidDevice
}

public func AudioQueueDeviceGetNearestStartTime(
    _ inAQ: AudioQueueRef?,
    _ ioRequestedStartTime: UnsafeMutableRawPointer?,
    _ inFlags: UInt32
) -> Int32 {
    _ = inAQ
    _ = ioRequestedStartTime
    _ = inFlags
    return kAudioQueueErr_InvalidDevice
}

public func AudioQueueProcessingTapNew(
    _ inAQ: AudioQueueRef?,
    _ inCallback: UnsafeRawPointer?,
    _ inClientData: UnsafeMutableRawPointer?,
    _ inFlags: AudioQueueProcessingTapFlags,
    _ outMaxFrames: UnsafeMutablePointer<UInt32>?,
    _ outProcessingFormat: UnsafeMutableRawPointer?,
    _ outAQTap: UnsafeMutablePointer<AudioQueueProcessingTapRef?>?
) -> Int32 {
    _ = inCallback
    _ = inClientData
    _ = inFlags
    outMaxFrames?.pointee = 0
    _ = outProcessingFormat
    outAQTap?.pointee = nil
    guard ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) != nil else {
        return kAudioQueueErr_QueueInvalidated
    }
    return kAudioQueueErr_TooManyTaps
}

@_cdecl("AudioQueueProcessingTapDispose")
public func AudioQueueProcessingTapDispose(_ inAQTap: AudioQueueProcessingTapRef?) -> Int32 {
    _ = inAQTap
    return kAudioQueueErr_InvalidTapContext
}

public func AudioQueueProcessingTapGetQueueTime(
    _ inAQTap: AudioQueueProcessingTapRef?,
    _ outQueueSampleTime: UnsafeMutablePointer<Float64>?,
    _ outQueueFrameCount: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    _ = inAQTap
    outQueueSampleTime?.pointee = 0
    outQueueFrameCount?.pointee = 0
    return kAudioQueueErr_InvalidTapContext
}

public func AudioQueueProcessingTapGetSourceAudio(
    _ inAQTap: AudioQueueProcessingTapRef?,
    _ inNumberFrames: UInt32,
    _ ioTimeStamp: UnsafeMutableRawPointer?,
    _ outFlags: UnsafeMutablePointer<AudioQueueProcessingTapFlags>?,
    _ outNumberFrames: UnsafeMutablePointer<UInt32>?,
    _ ioData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = inNumberFrames
    _ = ioTimeStamp
    outFlags?.pointee = []
    outNumberFrames?.pointee = 0
    _ = ioData
    _ = inAQTap
    return kAudioQueueErr_InvalidTapContext
}

@_cdecl("AudioQueueCreateTimeline")
public func AudioQueueCreateTimeline(
    _ inAQ: AudioQueueRef?,
    _ outTimeline: UnsafeMutablePointer<AudioQueueTimelineRef?>?
) -> Int32 {
    outTimeline?.pointee = nil
    guard ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) != nil else {
        return kAudioQueueErr_QueueInvalidated
    }
    return kAudioQueueErr_InvalidParameter
}

@_cdecl("AudioQueueDisposeTimeline")
public func AudioQueueDisposeTimeline(
    _ inAQ: AudioQueueRef?,
    _ inTimeline: AudioQueueTimelineRef?
) -> Int32 {
    _ = inAQ
    _ = inTimeline
    return 0
}
