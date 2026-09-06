import CoreFoundation
import Foundation

/// Process-local CFTypeID. Darwin's registered value is unobserved.
private let mtAudioProcessingTapHostTypeID: CFTypeID = 0x4D54_4150

public final class MTAudioProcessingTap: Hashable, @unchecked Sendable {
    let callbacks: MTAudioProcessingTapCallbacks
    let creationFlags: MTAudioProcessingTapCreationFlags
    private var storagePointer: UnsafeMutableRawPointer
    private var ownsDummyStorage: Bool
    private var prepared: Bool = false
    private var processing: Bool = false
    private var finalized: Bool = false

    init(callbacks: MTAudioProcessingTapCallbacks, flags: MTAudioProcessingTapCreationFlags) {
        self.callbacks = callbacks
        self.creationFlags = flags
        self.storagePointer = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
        self.storagePointer.storeBytes(of: UInt8(0), as: UInt8.self)
        self.ownsDummyStorage = true
    }

    deinit {
        if prepared {
            callbacks.unprepare?(self)
            prepared = false
        }
        if !finalized {
            callbacks.finalize?(self)
            finalized = true
        }
        if ownsDummyStorage {
            storagePointer.deallocate()
        }
    }

    func storage() -> UnsafeMutableRawPointer {
        storagePointer
    }

    func installStorage(_ provided: UnsafeMutableRawPointer?) {
        guard let provided else { return }
        if ownsDummyStorage {
            storagePointer.deallocate()
            ownsDummyStorage = false
        }
        storagePointer = provided
    }

    var isProcessing: Bool { processing }

    func markProcessing(_ value: Bool) {
        processing = value
    }

    func markPrepared(_ value: Bool) {
        prepared = value
    }

    var isPrepared: Bool { prepared }

    public static func == (left: MTAudioProcessingTap, right: MTAudioProcessingTap) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public func MTAudioProcessingTapGetTypeID() -> CFTypeID {
    mtAudioProcessingTapHostTypeID
}

public func MTAudioProcessingTapGetStorage(_ tap: MTAudioProcessingTap) -> UnsafeMutableRawPointer {
    tap.storage()
}

public func MTAudioProcessingTapCreate(
    _ allocator: CFAllocator?,
    _ callbacks: UnsafePointer<MTAudioProcessingTapCallbacks>,
    _ flags: MTAudioProcessingTapCreationFlags,
    _ tapOut: UnsafeMutablePointer<MTAudioProcessingTap?>
) -> OSStatus {
    _ = allocator
    tapOut.pointee = nil
    let callbacksValue = callbacks.pointee
    if callbacksValue.version != kMTAudioProcessingTapCallbacksVersion_0 {
        return kMTAudioProcessingTapInvalidArgumentErr
    }
    let pre = (flags & kMTAudioProcessingTapCreationFlag_PreEffects) != 0
    let post = (flags & kMTAudioProcessingTapCreationFlag_PostEffects) != 0
    if pre == post {
        return kMTAudioProcessingTapInvalidArgumentErr
    }
    let tap = MTAudioProcessingTap(callbacks: callbacksValue, flags: flags)
    var storage: UnsafeMutableRawPointer? = nil
    if let initialize = callbacksValue.`init` {
        withUnsafeMutablePointer(to: &storage) { pointer in
            initialize(tap, callbacksValue.clientInfo, pointer)
        }
    }
    tap.installStorage(storage)
    tapOut.pointee = tap
    return 0
}

public func MTAudioProcessingTapGetSourceAudio(
    _ tap: MTAudioProcessingTap,
    _ numberFrames: CMItemCount,
    _ bufferListInOut: UnsafeMutablePointer<AudioBufferList>,
    _ flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>?,
    _ timeRangeOut: UnsafeMutablePointer<CMTimeRange>?,
    _ numberFramesOut: UnsafeMutablePointer<CMItemCount>?
) -> OSStatus {
    _ = bufferListInOut
    _ = flagsOut
    _ = timeRangeOut
    _ = numberFramesOut
    _ = tap.isProcessing
    _ = numberFrames
    return kMTAudioProcessingTapInvalidArgumentErr
}

/// Linux host pump. Invokes `prepare` once. Not an Apple entry point.
public func MTAudioProcessingTapHostPrepare(
    _ tap: MTAudioProcessingTap,
    maxFrames: CMItemCount,
    processingFormat: UnsafePointer<AudioStreamBasicDescription>
) {
    if !tap.isPrepared {
        tap.callbacks.prepare?(tap, maxFrames, processingFormat)
        tap.markPrepared(true)
    }
}

/// Linux host pump. Invokes `process` synchronously. Not an Apple entry point.
public func MTAudioProcessingTapHostProcess(
    _ tap: MTAudioProcessingTap,
    numberFrames: CMItemCount,
    flags: MTAudioProcessingTapFlags,
    bufferList: UnsafeMutablePointer<AudioBufferList>,
    numberFramesOut: UnsafeMutablePointer<CMItemCount>,
    flagsOut: UnsafeMutablePointer<MTAudioProcessingTapFlags>
) {
    tap.markProcessing(true)
    tap.callbacks.process(tap, numberFrames, flags, bufferList, numberFramesOut, flagsOut)
    tap.markProcessing(false)
}

/// Linux host pump. Invokes `unprepare` once. Not an Apple entry point.
public func MTAudioProcessingTapHostUnprepare(_ tap: MTAudioProcessingTap) {
    if tap.isPrepared {
        tap.callbacks.unprepare?(tap)
        tap.markPrepared(false)
    }
}
