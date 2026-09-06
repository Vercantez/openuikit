import Foundation

/// Metal IO command queues. Linux has no Apple IO command processor;
/// load commands fail closed with `MTLIOError.internal`.

public typealias MTLIOCommandBufferHandler = (any MTLIOCommandBuffer) -> Void

open class MTLIOCommandQueueDescriptor: NSObject, @unchecked Sendable {
    public var maxCommandBufferCount: Int = 0
    public var maxCommandsInFlight: Int = 0
    public var priority: MTLIOPriority = .normal
    public var type: MTLIOCommandQueueType = .serial
    public var scratchBufferAllocator: (any MTLIOScratchBufferAllocator)?

    public override init() {
        super.init()
    }
}

public protocol MTLIOFileHandle: NSObjectProtocol, Sendable {
    var label: String? { get set }
}

public protocol MTLIOScratchBuffer: NSObjectProtocol {
    var buffer: any MTLBuffer { get }
}

public protocol MTLIOScratchBufferAllocator: NSObjectProtocol {
    func makeScratchBuffer(minimumSize: Int) -> (any MTLIOScratchBuffer)?
}

public protocol MTLIOCommandBuffer: NSObjectProtocol {
    var label: String? { get set }
    var status: MTLIOStatus { get }
    var error: (any Error)? { get }
    func addBarrier()
    func addCompletedHandler(_ block: @escaping MTLIOCommandBufferHandler)
    func enqueue()
    func commit()
    func waitUntilCompleted()
    func tryCancel()
    func pushDebugGroup(_ string: String)
    func popDebugGroup()
    func signalEvent(_ event: any MTLSharedEvent, value: UInt64)
    func waitForEvent(_ event: any MTLSharedEvent, value: UInt64)
    func copyStatus(buffer: any MTLBuffer, offset: Int)
    func load(
        _ buffer: any MTLBuffer,
        offset: Int,
        size: Int,
        sourceHandle: any MTLIOFileHandle,
        sourceHandleOffset: Int
    )
    func loadBytes(
        _ pointer: UnsafeMutableRawPointer,
        size: Int,
        sourceHandle: any MTLIOFileHandle,
        sourceHandleOffset: Int
    )
    func load(
        _ texture: any MTLTexture,
        slice: Int,
        level: Int,
        size: MTLSize,
        sourceBytesPerRow: Int,
        sourceBytesPerImage: Int,
        destinationOrigin: MTLOrigin,
        sourceHandle: any MTLIOFileHandle,
        sourceHandleOffset: Int
    )
}

public protocol MTLIOCommandQueue: NSObjectProtocol, Sendable {
    var label: String? { get set }
    func makeCommandBuffer() -> any MTLIOCommandBuffer
    func makeCommandBufferWithUnretainedReferences() -> any MTLIOCommandBuffer
    func enqueueBarrier()
}

final class LinuxMTLIOCommandQueue: NSObject, MTLIOCommandQueue, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    let descriptor: MTLIOCommandQueueDescriptor

    init(device: LinuxMTLDevice, descriptor: MTLIOCommandQueueDescriptor) {
        self.owningDevice = device
        self.descriptor = descriptor
        super.init()
    }

    func makeCommandBuffer() -> any MTLIOCommandBuffer {
        LinuxMTLIOCommandBuffer(queue: self)
    }

    func makeCommandBufferWithUnretainedReferences() -> any MTLIOCommandBuffer {
        LinuxMTLIOCommandBuffer(queue: self)
    }

    func enqueueBarrier() {}
}

final class LinuxMTLIOCommandBuffer: NSObject, MTLIOCommandBuffer, @unchecked Sendable {
    unowned let queue: LinuxMTLIOCommandQueue
    var label: String?
    private(set) var status: MTLIOStatus = .pending
    private(set) var error: (any Error)?
    private var completedHandlers: [MTLIOCommandBufferHandler] = []
    private var loadRecorded = false

    init(queue: LinuxMTLIOCommandQueue) {
        self.queue = queue
        super.init()
    }

    func addBarrier() {}
    func addCompletedHandler(_ block: @escaping MTLIOCommandBufferHandler) {
        completedHandlers.append(block)
    }

    func enqueue() {
        if status == .pending {
            status = .pending
        }
    }

    func commit() {
        enqueue()
        if loadRecorded {
            status = .error
            error = MTLIOError(
                .internal,
                userInfo: [NSLocalizedDescriptionKey: "Linux has no Metal IO command processor"]
            )
        } else {
            status = .complete
            error = nil
        }
        for handler in completedHandlers {
            handler(self)
        }
    }

    func waitUntilCompleted() {
        if status == .pending {
            commit()
        }
    }

    func tryCancel() {
        if status == .pending {
            status = .cancelled
        }
    }

    func pushDebugGroup(_ string: String) { _ = string }
    func popDebugGroup() {}

    func signalEvent(_ event: any MTLSharedEvent, value: UInt64) {
        event.signaledValue = value
    }

    func waitForEvent(_ event: any MTLSharedEvent, value: UInt64) {
        _ = event.wait(untilSignaledValue: value, timeoutMS: 0)
    }

    func copyStatus(buffer: any MTLBuffer, offset: Int) {
        guard offset >= 0, offset + MemoryLayout<UInt64>.size <= buffer.length else { return }
        var raw = UInt64(status.rawValue)
        withUnsafeBytes(of: &raw) { bytes in
            buffer.contents().advanced(by: offset).copyMemory(from: bytes.baseAddress!, byteCount: MemoryLayout<UInt64>.size)
        }
    }

    func load(
        _ buffer: any MTLBuffer,
        offset: Int,
        size: Int,
        sourceHandle: any MTLIOFileHandle,
        sourceHandleOffset: Int
    ) {
        _ = (buffer, offset, size, sourceHandle, sourceHandleOffset)
        loadRecorded = true
    }

    func loadBytes(
        _ pointer: UnsafeMutableRawPointer,
        size: Int,
        sourceHandle: any MTLIOFileHandle,
        sourceHandleOffset: Int
    ) {
        _ = (pointer, size, sourceHandle, sourceHandleOffset)
        loadRecorded = true
    }

    func load(
        _ texture: any MTLTexture,
        slice: Int,
        level: Int,
        size: MTLSize,
        sourceBytesPerRow: Int,
        sourceBytesPerImage: Int,
        destinationOrigin: MTLOrigin,
        sourceHandle: any MTLIOFileHandle,
        sourceHandleOffset: Int
    ) {
        _ = (texture, slice, level, size, sourceBytesPerRow, sourceBytesPerImage, destinationOrigin, sourceHandle, sourceHandleOffset)
        loadRecorded = true
    }
}

final class LinuxMTLIOFileHandle: NSObject, MTLIOFileHandle, @unchecked Sendable {
    var label: String?
}
