import Foundation

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
    var outputCallback: AudioQueueOutputCallback?
    var callbackUserData: UnsafeMutableRawPointer?
    var callbackInvocations: UInt64 = 0
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
        return kAudioQueueErr_CannotStart
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
    guard ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) != nil else {
        return kAudioQueueErr_QueueInvalidated
    }
    return kAudioQueueErr_InvalidDevice
}

public func AudioQueueStop(
    _ inAQ: AudioQueueRef?,
    _ inImmediate: Bool
) -> Int32 {
    _ = inImmediate
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_QueueInvalidated
    }
    queue.started = false
    return 0
}

@_cdecl("AudioQueuePause")
public func AudioQueuePause(_ inAQ: AudioQueueRef?) -> Int32 {
    guard ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) != nil else {
        return kAudioQueueErr_QueueInvalidated
    }
    return 0
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
        return 0
    }
}

@_cdecl("AudioQueueFlush")
public func AudioQueueFlush(_ inAQ: AudioQueueRef?) -> Int32 {
    guard ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) != nil else {
        return kAudioQueueErr_QueueInvalidated
    }
    return 0
}

/// Creates an in-process queue object that never reaches hardware. Format
/// bytes are not interpreted; CoreAudioTypes `AudioStreamBasicDescription`
/// is required before a converter/codec path can be added.
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
    guard inFormat != nil else { return kAudioQueueErr_InvalidParameter }
    let queue = ATAudioQueueObject()
    queue.outputCallback = inCallbackProc
    queue.callbackUserData = inUserData
    outAQ?.pointee = ATRegistry.shared.retain(queue)
    return 0
}
