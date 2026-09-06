import Dispatch
import Foundation

/// Host-clock shared events, indirect command buffers stored as CPU data, and
/// the shared-event listener objects. Listeners fire on the signaling thread
/// so tests stay synchronous (no run-loop / semaphore wait).

open class MTLSharedEventHandle: NSObject, NSSecureCoding, @unchecked Sendable {
    public var label: String?
    var signaledValue: UInt64 = 0

    public override init() {
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        super.init()
        self.label = coder.decodeObject(of: NSString.self, forKey: "label") as String?
        self.signaledValue = UInt64(bitPattern: Int64(coder.decodeInt64(forKey: "signaledValue")))
    }

    public func encode(with coder: NSCoder) {
        coder.encode(label as NSString?, forKey: "label")
        coder.encode(Int64(bitPattern: signaledValue), forKey: "signaledValue")
    }
}

open class MTLSharedEventListener: NSObject, @unchecked Sendable {
    private static let sharedInstance = MTLSharedEventListener()
    public let dispatchQueue: DispatchQueue

    public class func shared() -> MTLSharedEventListener {
        sharedInstance
    }

    public class func sharedListener() -> MTLSharedEventListener {
        shared()
    }

    public override init() {
        self.dispatchQueue = DispatchQueue.main
        super.init()
    }

    public init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
        super.init()
    }
}

final class LinuxMTLSharedEvent: NSObject, MTLSharedEvent, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    private let lock = NSLock()
    private var value: UInt64 = 0
    private var listeners: [(UInt64, MTLSharedEventNotificationBlock)] = []

    var device: any MTLDevice { owningDevice }

    var signaledValue: UInt64 {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            if newValue > value {
                value = newValue
            }
            let current = value
            let ready = listeners.filter { current >= $0.0 }
            listeners.removeAll { current >= $0.0 }
            lock.unlock()
            for entry in ready {
                entry.1(self, current)
            }
        }
    }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }

    func makeSharedEventHandle() -> MTLSharedEventHandle {
        let handle = MTLSharedEventHandle()
        handle.label = label
        handle.signaledValue = signaledValue
        return handle
    }

    func notify(
        _ listener: MTLSharedEventListener,
        atValue value: UInt64,
        block: @escaping MTLSharedEventNotificationBlock
    ) {
        _ = listener
        lock.lock()
        if self.value >= value {
            let current = self.value
            lock.unlock()
            block(self, current)
            return
        }
        listeners.append((value, block))
        lock.unlock()
    }

    func wait(untilSignaledValue value: UInt64, timeoutMS milliseconds: UInt64) -> Bool {
        if signaledValue >= value {
            return true
        }
        if milliseconds == 0 {
            return false
        }
        let deadline = Date().addingTimeInterval(Double(milliseconds) / 1000.0)
        while Date() < deadline {
            if signaledValue >= value {
                return true
            }
            Thread.sleep(forTimeInterval: 0.001)
        }
        return signaledValue >= value
    }
}

enum LinuxMTLIndirectDispatch {
    case none
    case threadgroups(MTLSize, MTLSize)
    case threads(MTLSize, MTLSize)
}

struct LinuxMTLIndirectComputeSnapshot {
    var pipeline: LinuxMTLComputePipelineState?
    var buffers: [Int: (any MTLBuffer, Int)]
    var dispatch: LinuxMTLIndirectDispatch
}

final class LinuxMTLIndirectComputeCommand: NSObject, MTLIndirectComputeCommand, @unchecked Sendable {
    var pipeline: LinuxMTLComputePipelineState?
    var buffers: [Int: (any MTLBuffer, Int)] = [:]
    var dispatch: LinuxMTLIndirectDispatch = .none
    private var barrier = false
    private var stageIn = MTLRegion()
    private var threadgroupMemory: [Int: Int] = [:]
    private var imageblock = MTLSize()

    func reset() {
        pipeline = nil
        buffers = [:]
        dispatch = .none
        barrier = false
        stageIn = MTLRegion()
        threadgroupMemory = [:]
        imageblock = MTLSize()
    }

    func setComputePipelineState(_ pipelineState: any MTLComputePipelineState) {
        pipeline = pipelineState as? LinuxMTLComputePipelineState
    }

    func setKernelBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int) {
        buffers[index] = (buffer, offset)
    }

    func setKernelBuffer(_ buffer: any MTLBuffer, offset: Int, attributeStride stride: Int, at index: Int) {
        _ = stride
        setKernelBuffer(buffer, offset: offset, at: index)
    }

    func setKernelBuffer(_ buffer: any MTLBuffer, offset: Int, index: Int) {
        setKernelBuffer(buffer, offset: offset, at: index)
    }

    func concurrentDispatchThreadgroups(_ threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        dispatch = .threadgroups(threadgroupsPerGrid, threadsPerThreadgroup)
    }

    func concurrentDispatchThreads(_ threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        dispatch = .threads(threadsPerGrid, threadsPerThreadgroup)
    }

    func setBarrier() {
        barrier = true
    }

    func clearBarrier() {
        barrier = false
    }

    func setImageblockWidth(_ width: Int, height: Int) {
        imageblock = MTLSize(width: width, height: height, depth: 1)
    }

    func setStageInRegion(_ region: MTLRegion) {
        stageIn = region
    }

    func setThreadgroupMemoryLength(_ length: Int, index: Int) {
        threadgroupMemory[index] = length
    }

    func snapshot() -> LinuxMTLIndirectComputeSnapshot {
        LinuxMTLIndirectComputeSnapshot(pipeline: pipeline, buffers: buffers, dispatch: dispatch)
    }

    func copy(from other: LinuxMTLIndirectComputeCommand) {
        pipeline = other.pipeline
        buffers = other.buffers
        dispatch = other.dispatch
        barrier = other.barrier
        stageIn = other.stageIn
        threadgroupMemory = other.threadgroupMemory
        imageblock = other.imageblock
    }
}

final class LinuxMTLIndirectRenderCommand: NSObject, MTLIndirectRenderCommand, @unchecked Sendable {
    private var pipeline: (any MTLRenderPipelineState)?
    private var vertexBuffers: [Int: (any MTLBuffer, Int)] = [:]
    private var fragmentBuffers: [Int: (any MTLBuffer, Int)] = [:]
    private var meshBuffers: [Int: (any MTLBuffer, Int)] = [:]
    private var objectBuffers: [Int: (any MTLBuffer, Int)] = [:]
    private var objectThreadgroup: [Int: Int] = [:]
    private var cull: MTLCullMode = .none
    private var fill: MTLTriangleFillMode = .fill
    private var winding: MTLWinding = .clockwise
    private var clip: MTLDepthClipMode = .clip
    private var draw: String = ""

    func reset() {
        pipeline = nil
        vertexBuffers = [:]
        fragmentBuffers = [:]
        meshBuffers = [:]
        objectBuffers = [:]
        objectThreadgroup = [:]
        cull = .none
        fill = .fill
        winding = .clockwise
        clip = .clip
        draw = ""
    }

    func setRenderPipelineState(_ pipelineState: any MTLRenderPipelineState) {
        pipeline = pipelineState
    }

    func setVertexBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int) {
        vertexBuffers[index] = (buffer, offset)
    }

    func setVertexBuffer(_ buffer: any MTLBuffer, offset: Int, attributeStride stride: Int, at index: Int) {
        _ = stride
        setVertexBuffer(buffer, offset: offset, at: index)
    }

    func setFragmentBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int) {
        fragmentBuffers[index] = (buffer, offset)
    }

    func setMeshBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int) {
        meshBuffers[index] = (buffer, offset)
    }

    func setObjectBuffer(_ buffer: any MTLBuffer, offset: Int, at index: Int) {
        objectBuffers[index] = (buffer, offset)
    }

    func setObjectThreadgroupMemoryLength(_ length: Int, index: Int) {
        objectThreadgroup[index] = length
    }

    func setCullMode(_ cullMode: MTLCullMode) {
        cull = cullMode
    }

    func setDepthBias(_ depthBias: Float, slopeScale: Float, clamp: Float) {
        _ = (depthBias, slopeScale, clamp)
    }

    func setDepthClipMode(_ depthClipMode: MTLDepthClipMode) {
        clip = depthClipMode
    }

    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?) {
        _ = depthStencilState
    }

    func setFrontFacing(_ frontFacingWindning: MTLWinding) {
        winding = frontFacingWindning
    }

    func setTriangleFillMode(_ fillMode: MTLTriangleFillMode) {
        fill = fillMode
    }

    func setBarrier() {}

    func clearBarrier() {}

    func drawPrimitives(
        _ primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int,
        baseInstance: Int
    ) {
        draw = "draw:\(primitiveType.rawValue):\(vertexStart):\(vertexCount):\(instanceCount):\(baseInstance)"
    }

    func drawIndexedPrimitives(
        _ primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        instanceCount: Int,
        baseVertex: Int,
        baseInstance: Int
    ) {
        _ = (indexBuffer, indexBufferOffset)
        draw = "indexed:\(primitiveType.rawValue):\(indexCount):\(indexType.rawValue):\(instanceCount):\(baseVertex):\(baseInstance)"
    }

    func drawPatches(
        _ numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int,
        tessellationFactorBuffer buffer: any MTLBuffer,
        tessellationFactorBufferOffset offset: Int,
        tessellationFactorBufferInstanceStride instanceStride: Int
    ) {
        _ = (patchIndexBuffer, patchIndexBufferOffset, buffer, offset, instanceStride)
        draw = "patches:\(numberOfPatchControlPoints):\(patchStart):\(patchCount):\(instanceCount):\(baseInstance)"
    }

    func drawIndexedPatches(
        _ numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        controlPointIndexBuffer: any MTLBuffer,
        controlPointIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int,
        tessellationFactorBuffer buffer: any MTLBuffer,
        tessellationFactorBufferOffset offset: Int,
        tessellationFactorBufferInstanceStride instanceStride: Int
    ) {
        _ = (patchIndexBuffer, patchIndexBufferOffset, controlPointIndexBuffer, controlPointIndexBufferOffset, buffer, offset, instanceStride)
        draw = "indexedPatches:\(numberOfPatchControlPoints):\(patchStart):\(patchCount):\(instanceCount):\(baseInstance)"
    }

    func drawMeshThreadgroups(
        _ threadgroupsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        draw = "meshGroups:\(threadgroupsPerGrid.width):\(threadsPerObjectThreadgroup.width):\(threadsPerMeshThreadgroup.width)"
    }

    func drawMeshThreads(
        _ threadsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        draw = "meshThreads:\(threadsPerGrid.width):\(threadsPerObjectThreadgroup.width):\(threadsPerMeshThreadgroup.width)"
    }

    func copy(from other: LinuxMTLIndirectRenderCommand) {
        pipeline = other.pipeline
        vertexBuffers = other.vertexBuffers
        fragmentBuffers = other.fragmentBuffers
        meshBuffers = other.meshBuffers
        objectBuffers = other.objectBuffers
        objectThreadgroup = other.objectThreadgroup
        cull = other.cull
        fill = other.fill
        winding = other.winding
        clip = other.clip
        draw = other.draw
    }
}

final class LinuxMTLIndirectCommandBuffer: LinuxMTLResource, MTLIndirectCommandBuffer, @unchecked Sendable {
    let size: Int
    let gpuResourceID: MTLResourceID
    let descriptor: MTLIndirectCommandBufferDescriptor
    private var computeCommands: [LinuxMTLIndirectComputeCommand]
    private var renderCommands: [LinuxMTLIndirectRenderCommand]

    init(
        device: LinuxMTLDevice,
        descriptor: MTLIndirectCommandBufferDescriptor,
        maxCommandCount: Int,
        options: MTLResourceOptions
    ) {
        self.size = maxCommandCount
        self.gpuResourceID = device.nextID()
        self.descriptor = descriptor
        self.computeCommands = (0..<maxCommandCount).map { _ in LinuxMTLIndirectComputeCommand() }
        self.renderCommands = (0..<maxCommandCount).map { _ in LinuxMTLIndirectRenderCommand() }
        super.init(
            device: device,
            options: options,
            allocatedSize: maxCommandCount * 64,
            heap: nil,
            heapOffset: 0
        )
        device.noteAllocated(maxCommandCount * 64)
    }

    deinit {
        owningDevice.noteFreed(allocatedSize)
    }

    func indirectComputeCommandAt(_ commandIndex: Int) -> any MTLIndirectComputeCommand {
        computeCommands[min(max(commandIndex, 0), size - 1)]
    }

    func indirectRenderCommandAt(_ commandIndex: Int) -> any MTLIndirectRenderCommand {
        renderCommands[min(max(commandIndex, 0), size - 1)]
    }

    func resetCommands(_ range: Range<Int>) {
        for index in range where index >= 0 && index < size {
            computeCommands[index].reset()
            renderCommands[index].reset()
        }
    }

    func copyCommands(
        from source: LinuxMTLIndirectCommandBuffer,
        sourceRange: Range<Int>,
        destinationIndex: Int
    ) {
        var dest = destinationIndex
        for index in sourceRange where index >= 0 && index < source.size && dest >= 0 && dest < size {
            computeCommands[dest].copy(from: source.computeCommands[index])
            renderCommands[dest].copy(from: source.renderCommands[index])
            dest += 1
        }
    }

    func snapshotCompute(range: Range<Int>) -> [LinuxMTLIndirectComputeSnapshot] {
        var result: [LinuxMTLIndirectComputeSnapshot] = []
        for index in range where index >= 0 && index < size {
            result.append(computeCommands[index].snapshot())
        }
        return result
    }
}
