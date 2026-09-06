import Foundation

final class LinuxMTLCommandQueue: NSObject, MTLCommandQueue, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice) {
        self.owningDevice = device
        super.init()
    }

    func makeCommandBuffer() -> (any MTLCommandBuffer)? {
        LinuxMTLCommandBuffer(queue: self, retainedReferences: true)
    }

    func makeCommandBuffer(descriptor: MTLCommandBufferDescriptor) -> (any MTLCommandBuffer)? {
        LinuxMTLCommandBuffer(queue: self, retainedReferences: descriptor.retainedReferences)
    }

    func makeCommandBufferWithUnretainedReferences() -> (any MTLCommandBuffer)? {
        LinuxMTLCommandBuffer(queue: self, retainedReferences: false)
    }

    func insertDebugCaptureBoundary() {}

    func addResidencySet(_ residencySet: any MTLResidencySet) {
        _ = residencySet
    }

    func removeResidencySet(_ residencySet: any MTLResidencySet) {
        _ = residencySet
    }
}

final class LinuxMTLCommandBuffer: NSObject, MTLCommandBuffer, @unchecked Sendable {
    unowned let queue: LinuxMTLCommandQueue
    let retainedReferences: Bool
    let errorOptions: MTLCommandBufferErrorOption = []
    var label: String?
    private(set) var status: MTLCommandBufferStatus = .notEnqueued
    private(set) var error: (any Error)?
    var kernelStartTime: TimeInterval = 0
    var kernelEndTime: TimeInterval = 0
    var gpuStartTime: TimeInterval = 0
    var gpuEndTime: TimeInterval = 0
    let logs = MTLLogContainer()
    private var completedHandlers: [MTLCommandBufferHandler] = []
    private var scheduledHandlers: [MTLCommandBufferHandler] = []
    private var recorded: [() -> Void] = []
    private var encoding = false
    private var pendingError: MTLCommandBufferError?

    var device: any MTLDevice { queue.device }
    var commandQueue: any MTLCommandQueue { queue }

    init(queue: LinuxMTLCommandQueue, retainedReferences: Bool) {
        self.queue = queue
        self.retainedReferences = retainedReferences
        super.init()
    }

    func enqueue() {
        if status == .notEnqueued {
            status = .enqueued
        }
    }

    func commit() {
        enqueue()
        status = .committed
        let start = ProcessInfo.processInfo.systemUptime
        kernelStartTime = start
        gpuStartTime = start
        status = .scheduled
        for handler in scheduledHandlers {
            handler(self)
        }
        for work in recorded {
            work()
        }
        recorded.removeAll()
        let end = ProcessInfo.processInfo.systemUptime
        kernelEndTime = end
        gpuEndTime = end
        if let pendingError {
            status = .error
            error = pendingError
        } else {
            status = .completed
            error = nil
        }
        for handler in completedHandlers {
            handler(self)
        }
    }

    func addScheduledHandler(_ block: @escaping MTLCommandBufferHandler) {
        scheduledHandlers.append(block)
    }

    func addCompletedHandler(_ block: @escaping MTLCommandBufferHandler) {
        completedHandlers.append(block)
    }

    func waitUntilScheduled() {
        if status == .committed {
            status = .scheduled
        }
    }

    func waitUntilCompleted() {
        if status == .committed {
            status = .scheduled
        }
        if status == .scheduled {
            status = error == nil ? .completed : .error
        }
    }

    func failClosed(_ code: MTLCommandBufferError.Code, reason: String) {
        if pendingError == nil {
            pendingError = MTLCommandBufferError(
                code,
                userInfo: [NSLocalizedDescriptionKey: reason]
            )
        }
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func present(_ drawable: any MTLDrawable) {
        drawable.present()
    }

    func present(_ drawable: any MTLDrawable, atTime presentationTime: CFTimeInterval) {
        drawable.present(at: presentationTime)
    }

    func present(_ drawable: any MTLDrawable, afterMinimumDuration duration: CFTimeInterval) {
        drawable.present(afterMinimumDuration: duration)
    }

    func encodeSignalEvent(_ event: any MTLEvent, value: UInt64) {
        record {
            if let shared = event as? LinuxMTLSharedEvent {
                shared.signaledValue = value
            } else {
                (event as? LinuxMTLEvent)?.signal(value)
            }
        }
    }

    func encodeWaitForEvent(_ event: any MTLEvent, value: UInt64) {
        record {
            if let shared = event as? LinuxMTLSharedEvent {
                _ = shared.wait(untilSignaledValue: value, timeoutMS: 0)
            }
        }
    }

    func makeBlitCommandEncoder() -> (any MTLBlitCommandEncoder)? {
        guard beginEncoder() else { return nil }
        return LinuxMTLBlitCommandEncoder(commandBuffer: self)
    }

    func makeBlitCommandEncoder(descriptor blitPassDescriptor: MTLBlitPassDescriptor) -> (any MTLBlitCommandEncoder)? {
        _ = blitPassDescriptor
        return makeBlitCommandEncoder()
    }

    func makeComputeCommandEncoder() -> (any MTLComputeCommandEncoder)? {
        makeComputeCommandEncoder(dispatchType: .serial)
    }

    func makeComputeCommandEncoder(dispatchType: MTLDispatchType) -> (any MTLComputeCommandEncoder)? {
        guard beginEncoder() else { return nil }
        return LinuxMTLComputeCommandEncoder(commandBuffer: self, dispatchType: dispatchType)
    }

    func makeComputeCommandEncoder(descriptor computePassDescriptor: MTLComputePassDescriptor) -> (any MTLComputeCommandEncoder)? {
        makeComputeCommandEncoder(dispatchType: computePassDescriptor.dispatchType)
    }

    func makeRenderCommandEncoder(descriptor renderPassDescriptor: MTLRenderPassDescriptor) -> (any MTLRenderCommandEncoder)? {
        guard beginEncoder() else { return nil }
        return LinuxMTLRenderCommandEncoder(commandBuffer: self, descriptor: renderPassDescriptor)
    }

    func makeParallelRenderCommandEncoder(descriptor renderPassDescriptor: MTLRenderPassDescriptor) -> (any MTLParallelRenderCommandEncoder)? {
        guard beginEncoder() else { return nil }
        return LinuxMTLParallelRenderCommandEncoder(commandBuffer: self, descriptor: renderPassDescriptor)
    }

    func makeResourceStateCommandEncoder() -> (any MTLResourceStateCommandEncoder)? {
        guard beginEncoder() else { return nil }
        return LinuxMTLResourceStateCommandEncoder(commandBuffer: self)
    }

    func resourceStateCommandEncoder(with resourceStatePassDescriptor: MTLResourceStatePassDescriptor) -> (any MTLResourceStateCommandEncoder)? {
        _ = resourceStatePassDescriptor
        return makeResourceStateCommandEncoder()
    }

    func makeAccelerationStructureCommandEncoder() -> (any MTLAccelerationStructureCommandEncoder)? {
        guard beginEncoder() else { return nil }
        return LinuxMTLAccelerationStructureCommandEncoder(commandBuffer: self)
    }

    func makeAccelerationStructureCommandEncoder(descriptor: MTLAccelerationStructurePassDescriptor) -> any MTLAccelerationStructureCommandEncoder {
        _ = descriptor
        return makeAccelerationStructureCommandEncoder()!
    }

    func useResidencySet(_ residencySet: any MTLResidencySet) {
        _ = residencySet
    }

    func finishEncoder() {
        encoding = false
    }

    func record(_ work: @escaping () -> Void) {
        recorded.append(work)
    }

    private func beginEncoder() -> Bool {
        guard !encoding else { return false }
        encoding = true
        return true
    }
}

final class LinuxMTLBlitCommandEncoder: NSObject, MTLBlitCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    var label: String?
    private var ended = false

    var device: any MTLDevice { commandBuffer.device }

    init(commandBuffer: LinuxMTLCommandBuffer) {
        self.commandBuffer = commandBuffer
        super.init()
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        commandBuffer.finishEncoder()
    }

    func insertDebugSignpost(_ string: String) {
        _ = string
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages) {
        _ = (afterQueueStages, beforeStages)
    }

    func fill(buffer: any MTLBuffer, range: Range<Int>, value: UInt8) {
        let lower = range.lowerBound
        let count = range.count
        commandBuffer.record {
            guard lower >= 0, lower + count <= buffer.length else { return }
            buffer.contents().advanced(by: lower).initializeMemory(
                as: UInt8.self,
                repeating: value,
                count: count
            )
        }
    }

    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        size: Int
    ) {
        commandBuffer.record {
            guard size > 0,
                  sourceOffset >= 0,
                  destinationOffset >= 0,
                  sourceOffset + size <= sourceBuffer.length,
                  destinationOffset + size <= destinationBuffer.length
            else { return }
            destinationBuffer.contents().advanced(by: destinationOffset).copyMemory(
                from: sourceBuffer.contents().advanced(by: sourceOffset),
                byteCount: size
            )
        }
    }

    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        sourceBytesPerRow: Int,
        sourceBytesPerImage: Int,
        sourceSize: MTLSize,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    ) {
        copy(
            from: sourceBuffer,
            sourceOffset: sourceOffset,
            sourceBytesPerRow: sourceBytesPerRow,
            sourceBytesPerImage: sourceBytesPerImage,
            sourceSize: sourceSize,
            to: destinationTexture,
            destinationSlice: destinationSlice,
            destinationLevel: destinationLevel,
            destinationOrigin: destinationOrigin,
            options: []
        )
    }

    func copy(
        from sourceBuffer: any MTLBuffer,
        sourceOffset: Int,
        sourceBytesPerRow: Int,
        sourceBytesPerImage: Int,
        sourceSize: MTLSize,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin,
        options: MTLBlitOption
    ) {
        _ = (sourceBytesPerImage, options)
        commandBuffer.record {
            guard let texture = destinationTexture as? LinuxMTLTexture else { return }
            let region = MTLRegion(
                origin: destinationOrigin,
                size: sourceSize
            )
            let src = sourceBuffer.contents().advanced(by: sourceOffset)
            texture.replace(
                region: region,
                mipmapLevel: destinationLevel,
                slice: destinationSlice,
                withBytes: src,
                bytesPerRow: sourceBytesPerRow,
                bytesPerImage: sourceBytesPerRow * max(sourceSize.height, 1)
            )
        }
    }

    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        destinationBytesPerRow: Int,
        destinationBytesPerImage: Int
    ) {
        copy(
            from: sourceTexture,
            sourceSlice: sourceSlice,
            sourceLevel: sourceLevel,
            sourceOrigin: sourceOrigin,
            sourceSize: sourceSize,
            to: destinationBuffer,
            destinationOffset: destinationOffset,
            destinationBytesPerRow: destinationBytesPerRow,
            destinationBytesPerImage: destinationBytesPerImage,
            options: []
        )
    }

    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        to destinationBuffer: any MTLBuffer,
        destinationOffset: Int,
        destinationBytesPerRow: Int,
        destinationBytesPerImage: Int,
        options: MTLBlitOption
    ) {
        _ = (destinationBytesPerImage, options)
        commandBuffer.record {
            let dest = destinationBuffer.contents().advanced(by: destinationOffset)
            sourceTexture.getBytes(
                dest,
                bytesPerRow: destinationBytesPerRow,
                bytesPerImage: destinationBytesPerRow * max(sourceSize.height, 1),
                from: MTLRegion(origin: sourceOrigin, size: sourceSize),
                mipmapLevel: sourceLevel,
                slice: sourceSlice
            )
        }
    }

    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    ) {
        commandBuffer.record {
            guard let bpp = metalBytesPerPixel(sourceTexture.pixelFormat), bpp > 0 else { return }
            let rowBytes = max(sourceSize.width, 0) * bpp
            let byteCount = rowBytes * max(sourceSize.height, 0) * max(sourceSize.depth, 1)
            guard byteCount > 0 else { return }
            let temp = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 16)
            defer { temp.deallocate() }
            sourceTexture.getBytes(
                temp,
                bytesPerRow: rowBytes,
                bytesPerImage: rowBytes * max(sourceSize.height, 1),
                from: MTLRegion(origin: sourceOrigin, size: sourceSize),
                mipmapLevel: sourceLevel,
                slice: sourceSlice
            )
            destinationTexture.replace(
                region: MTLRegion(origin: destinationOrigin, size: sourceSize),
                mipmapLevel: destinationLevel,
                slice: destinationSlice,
                withBytes: temp,
                bytesPerRow: rowBytes,
                bytesPerImage: rowBytes * max(sourceSize.height, 1)
            )
        }
    }

    func copy(
        from sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        to destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        sliceCount: Int,
        levelCount: Int
    ) {
        for slice in 0..<max(sliceCount, 0) {
            for level in 0..<max(levelCount, 0) {
                let srcLevel = sourceLevel + level
                let dstLevel = destinationLevel + level
                let width = max(sourceTexture.width >> srcLevel, 1)
                let height = max(sourceTexture.height >> srcLevel, 1)
                copy(
                    from: sourceTexture,
                    sourceSlice: sourceSlice + slice,
                    sourceLevel: srcLevel,
                    sourceOrigin: MTLOrigin(),
                    sourceSize: MTLSize(width: width, height: height, depth: 1),
                    to: destinationTexture,
                    destinationSlice: destinationSlice + slice,
                    destinationLevel: dstLevel,
                    destinationOrigin: MTLOrigin()
                )
            }
        }
    }

    func copy(from sourceTexture: any MTLTexture, to destinationTexture: any MTLTexture) {
        copy(
            from: sourceTexture,
            sourceSlice: 0,
            sourceLevel: 0,
            to: destinationTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            sliceCount: min(sourceTexture.arrayLength, destinationTexture.arrayLength),
            levelCount: min(sourceTexture.mipmapLevelCount, destinationTexture.mipmapLevelCount)
        )
    }

    func generateMipmaps(for texture: any MTLTexture) {
        commandBuffer.record {
            (texture as? LinuxMTLTexture)?.generateMipmapsBoxFilter()
        }
    }

    func optimizeContentsForCPUAccess(texture: any MTLTexture) {
        _ = texture
    }

    func optimizeContentsForCPUAccess(texture: any MTLTexture, slice: Int, level: Int) {
        _ = (texture, slice, level)
    }

    func optimizeContentsForGPUAccess(texture: any MTLTexture) {
        _ = texture
    }

    func optimizeContentsForGPUAccess(texture: any MTLTexture, slice: Int, level: Int) {
        _ = (texture, slice, level)
    }

    func updateFence(_ fence: any MTLFence) {
        commandBuffer.record {
            (fence as? LinuxMTLFence)?.signal()
        }
    }

    func waitForFence(_ fence: any MTLFence) {
        commandBuffer.record {
            (fence as? LinuxMTLFence)?.wait()
        }
    }

    func resetCommandsInBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>) {
        commandBuffer.record {
            (buffer as? LinuxMTLIndirectCommandBuffer)?.resetCommands(range)
        }
    }

    func copyIndirectCommandBuffer(
        _ buffer: any MTLIndirectCommandBuffer,
        sourceRange: Range<Int>,
        destination: any MTLIndirectCommandBuffer,
        destinationIndex: Int
    ) {
        commandBuffer.record {
            guard let source = buffer as? LinuxMTLIndirectCommandBuffer,
                  let dest = destination as? LinuxMTLIndirectCommandBuffer
            else { return }
            dest.copyCommands(from: source, sourceRange: sourceRange, destinationIndex: destinationIndex)
        }
    }

    func optimizeIndirectCommandBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>) {
        _ = (buffer, range)
    }
}

final class LinuxMTLComputeCommandEncoder: NSObject, MTLComputeCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    let dispatchType: MTLDispatchType
    var label: String?
    private var ended = false
    private var pipeline: LinuxMTLComputePipelineState?
    private var buffers: [Int: (any MTLBuffer, Int)] = [:]
    private var bytes: [Int: [UInt8]] = [:]

    var device: any MTLDevice { commandBuffer.device }

    init(commandBuffer: LinuxMTLCommandBuffer, dispatchType: MTLDispatchType) {
        self.commandBuffer = commandBuffer
        self.dispatchType = dispatchType
        super.init()
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        commandBuffer.finishEncoder()
    }

    func insertDebugSignpost(_ string: String) {
        _ = string
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages) {
        _ = (afterQueueStages, beforeStages)
    }

    func setComputePipelineState(_ state: any MTLComputePipelineState) {
        pipeline = state as? LinuxMTLComputePipelineState
    }

    func setBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        if let buffer {
            buffers[index] = (buffer, offset)
        } else {
            buffers[index] = nil
        }
    }

    func setBuffer(_ buffer: any MTLBuffer, offset: Int, attributeStride stride: Int, index: Int) {
        _ = stride
        setBuffer(buffer, offset: offset, index: index)
    }

    func setBufferOffset(_ offset: Int, index: Int) {
        if let existing = buffers[index] {
            buffers[index] = (existing.0, offset)
        }
    }

    func setBufferOffset(offset: Int, attributeStride stride: Int, index: Int) {
        _ = stride
        setBufferOffset(offset, index: index)
    }

    func setBytes(_ bytesPointer: UnsafeRawPointer, length: Int, index: Int) {
        let copy = Array(UnsafeRawBufferPointer(start: bytesPointer, count: max(length, 0)))
        bytes[index] = copy
    }

    func setBytes(_ bytesPointer: UnsafeRawPointer, length: Int, attributeStride stride: Int, index: Int) {
        _ = stride
        setBytes(bytesPointer, length: length, index: index)
    }

    func setTexture(_ texture: (any MTLTexture)?, index: Int) {
        _ = (texture, index)
    }

    func setSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        _ = (sampler, index)
    }

    func setSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int) {
        _ = (sampler, lodMinClamp, lodMaxClamp, index)
    }

    func setThreadgroupMemoryLength(_ length: Int, index: Int) {
        _ = (length, index)
    }

    func setImageblockWidth(_ width: Int, height: Int) {
        _ = (width, height)
    }

    func setStageInRegion(_ region: MTLRegion) {
        _ = region
    }

    func setStageInRegionWithIndirectBuffer(_ indirectBuffer: any MTLBuffer, indirectBufferOffset: Int) {
        _ = (indirectBuffer, indirectBufferOffset)
    }

    func dispatchThreadgroups(_ threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        let threads = MTLSize(
            width: max(threadgroupsPerGrid.width, 0) * max(threadsPerThreadgroup.width, 0),
            height: max(threadgroupsPerGrid.height, 0) * max(threadsPerThreadgroup.height, 0),
            depth: max(threadgroupsPerGrid.depth, 0) * max(threadsPerThreadgroup.depth, 0)
        )
        dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    func dispatchThreadgroups(
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int,
        threadsPerThreadgroup: MTLSize
    ) {
        _ = (indirectBuffer, indirectBufferOffset, threadsPerThreadgroup)
    }

    func dispatchThreads(_ threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        _ = threadsPerThreadgroup
        let snapshotBuffers = buffers
        let snapshotBytes = bytes
        let snapshotPipeline = pipeline
        let count = max(threadsPerGrid.width, 0) * max(threadsPerGrid.height, 0) * max(threadsPerGrid.depth, 0)
        let recorded = commandBuffer
        recorded.record {
            guard let pipeline = snapshotPipeline, pipeline.function.isCPUBuiltin else {
                recorded.failClosed(.notPermitted, reason: "no shader execution")
                return
            }
            LinuxMTLCPUKernel.run(
                name: pipeline.function.name,
                threadCount: count,
                buffers: snapshotBuffers,
                bytes: snapshotBytes
            )
        }
    }

    func memoryBarrier(scope: MTLBarrierScope) {
        _ = scope
    }

    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage) {
        _ = (resource, usage)
    }

    func useHeap(_ heap: any MTLHeap) {
        _ = heap
    }

    func updateFence(_ fence: any MTLFence) {
        (fence as? LinuxMTLFence)?.signal()
    }

    func waitForFence(_ fence: any MTLFence) {
        (fence as? LinuxMTLFence)?.wait()
    }

    func executeCommandsInBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>) {
        guard let icb = buffer as? LinuxMTLIndirectCommandBuffer else { return }
        let snapshot = icb.snapshotCompute(range: range)
        let recorded = commandBuffer
        recorded.record {
            for command in snapshot {
                guard let pipeline = command.pipeline, pipeline.function.isCPUBuiltin else {
                    recorded.failClosed(.notPermitted, reason: "no shader execution")
                    continue
                }
                let count: Int
                switch command.dispatch {
                case .none:
                    continue
                case .threadgroups(let groups, let threads):
                    count = max(groups.width, 0) * max(threads.width, 0)
                        * max(groups.height, 0) * max(threads.height, 0)
                        * max(groups.depth, 0) * max(threads.depth, 0)
                case .threads(let threads, _):
                    count = max(threads.width, 0) * max(threads.height, 0) * max(threads.depth, 0)
                }
                LinuxMTLCPUKernel.run(
                    name: pipeline.function.name,
                    threadCount: count,
                    buffers: command.buffers,
                    bytes: [:]
                )
            }
        }
    }

    func executeCommandsInBuffer(
        _ buffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: any MTLBuffer,
        offset: Int
    ) {
        let location = Int(indirectRangeBuffer.contents().advanced(by: offset).load(as: UInt32.self))
        let length = Int(indirectRangeBuffer.contents().advanced(by: offset + 4).load(as: UInt32.self))
        executeCommandsInBuffer(buffer, range: location..<(location + length))
    }

    func executeCommands(in indirectCommandBuffer: any MTLIndirectCommandBuffer, with executionRange: NSRange) {
        let lower = executionRange.location
        executeCommandsInBuffer(indirectCommandBuffer, range: lower..<(lower + executionRange.length))
    }

    func executeCommands(
        in indirectCommandbuffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    ) {
        executeCommandsInBuffer(
            indirectCommandbuffer,
            indirectBuffer: indirectRangeBuffer,
            offset: indirectBufferOffset
        )
    }
}

enum LinuxMTLCPUKernel {
    static func run(
        name: String,
        threadCount: Int,
        buffers: [Int: (any MTLBuffer, Int)],
        bytes: [Int: [UInt8]]
    ) {
        switch MTLCPUBuiltinKernel(rawValue: name) {
        case .fillUInt32:
            guard let dest = buffers[0] else { return }
            var value: UInt32 = 0
            if let payload = bytes[1], payload.count >= 4 {
                value = payload.withUnsafeBytes { $0.load(as: UInt32.self) }
            } else if let source = buffers[1], source.0.length - source.1 >= 4 {
                value = source.0.contents().advanced(by: source.1).load(as: UInt32.self)
            }
            for thread in 0..<threadCount {
                let offset = dest.1 + thread * 4
                guard offset + 4 <= dest.0.length else { break }
                dest.0.contents().advanced(by: offset).storeBytes(of: value, as: UInt32.self)
            }
        case .addUInt32:
            guard let a = buffers[0], let b = buffers[1], let out = buffers[2] else { return }
            for thread in 0..<threadCount {
                let aOff = a.1 + thread * 4
                let bOff = b.1 + thread * 4
                let oOff = out.1 + thread * 4
                guard aOff + 4 <= a.0.length, bOff + 4 <= b.0.length, oOff + 4 <= out.0.length else { break }
                let lhs = a.0.contents().advanced(by: aOff).load(as: UInt32.self)
                let rhs = b.0.contents().advanced(by: bOff).load(as: UInt32.self)
                out.0.contents().advanced(by: oOff).storeBytes(of: lhs &+ rhs, as: UInt32.self)
            }
        case .copyUInt8:
            guard let src = buffers[0], let dst = buffers[1] else { return }
            for thread in 0..<threadCount {
                let s = src.1 + thread
                let d = dst.1 + thread
                guard s < src.0.length, d < dst.0.length else { break }
                dst.0.contents().advanced(by: d).storeBytes(
                    of: src.0.contents().advanced(by: s).load(as: UInt8.self),
                    as: UInt8.self
                )
            }
        case nil:
            break
        }
    }
}

final class LinuxMTLRenderCommandEncoder: NSObject, MTLRenderCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    let descriptor: MTLRenderPassDescriptor
    var label: String?
    private var ended = false
    private(set) var recordedState: [String] = []
    var tileWidth: Int { max(descriptor.tileWidth, 0) }
    var tileHeight: Int { max(descriptor.tileHeight, 0) }

    var device: any MTLDevice { commandBuffer.device }

    let ownsCommandBufferSlot: Bool

    init(
        commandBuffer: LinuxMTLCommandBuffer,
        descriptor: MTLRenderPassDescriptor,
        ownsCommandBufferSlot: Bool = true
    ) {
        self.commandBuffer = commandBuffer
        self.descriptor = descriptor
        self.ownsCommandBufferSlot = ownsCommandBufferSlot
        super.init()
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        let descriptor = self.descriptor
        commandBuffer.record {
            LinuxMTLRenderCommandEncoder.applyLoadStore(descriptor)
        }
        if ownsCommandBufferSlot {
            commandBuffer.finishEncoder()
        }
    }

    static func applyLoadStore(_ descriptor: MTLRenderPassDescriptor) {
        let color = descriptor.colorAttachments[0]!
        if let texture = color.texture as? LinuxMTLTexture {
            switch color.loadAction {
            case .clear:
                texture.clearLevelZero(color: color.clearColor)
            case .load, .dontCare:
                break
            @unknown default:
                break
            }
        }
        if let depth = descriptor.depthAttachment,
           let texture = depth.texture as? LinuxMTLTexture,
           depth.loadAction == .clear {
            texture.clearLevelZero(depth: depth.clearDepth)
        }
    }

    func insertDebugSignpost(_ string: String) {
        recordedState.append("signpost:\(string)")
    }

    func pushDebugGroup(_ string: String) {
        recordedState.append("push:\(string)")
    }

    func popDebugGroup() {
        recordedState.append("pop")
    }

    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages) {
        _ = (afterQueueStages, beforeStages)
    }

    func setRenderPipelineState(_ pipelineState: any MTLRenderPipelineState) {
        recordedState.append("pipeline:\(pipelineState.label ?? "")")
    }

    func setVertexBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        recordedState.append("vb:\(index):\(offset):\(buffer?.length ?? -1)")
    }

    func setVertexBuffer(_ buffer: (any MTLBuffer)?, offset: Int, attributeStride stride: Int, index: Int) {
        _ = stride
        setVertexBuffer(buffer, offset: offset, index: index)
    }

    func setVertexBufferOffset(_ offset: Int, index: Int) {
        recordedState.append("vbo:\(index):\(offset)")
    }

    func setVertexBufferOffset(offset: Int, attributeStride stride: Int, index: Int) {
        _ = stride
        setVertexBufferOffset(offset, index: index)
    }

    func setVertexBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        _ = bytes
        recordedState.append("vbytes:\(index):\(length)")
    }

    func setVertexBytes(_ bytes: UnsafeRawPointer, length: Int, attributeStride stride: Int, index: Int) {
        _ = stride
        setVertexBytes(bytes, length: length, index: index)
    }

    func setVertexTexture(_ texture: (any MTLTexture)?, index: Int) {
        recordedState.append("vt:\(index):\(texture?.width ?? -1)")
    }

    func setVertexSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        recordedState.append("vs:\(index):\(sampler != nil)")
    }

    func setVertexSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int) {
        _ = (lodMinClamp, lodMaxClamp)
        setVertexSamplerState(sampler, index: index)
    }

    func setFragmentBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        recordedState.append("fb:\(index):\(offset):\(buffer?.length ?? -1)")
    }

    func setFragmentBufferOffset(_ offset: Int, index: Int) {
        recordedState.append("fbo:\(index):\(offset)")
    }

    func setFragmentBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        _ = bytes
        recordedState.append("fbytes:\(index):\(length)")
    }

    func setFragmentTexture(_ texture: (any MTLTexture)?, index: Int) {
        recordedState.append("ft:\(index):\(texture?.width ?? -1)")
    }

    func setFragmentSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        recordedState.append("fs:\(index):\(sampler != nil)")
    }

    func setFragmentSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int) {
        _ = (lodMinClamp, lodMaxClamp)
        setFragmentSamplerState(sampler, index: index)
    }

    func setViewport(_ viewport: MTLViewport) {
        recordedState.append("viewport:\(viewport.width)x\(viewport.height)")
    }

    func setScissorRect(_ rect: MTLScissorRect) {
        recordedState.append("scissor:\(rect.width)x\(rect.height)")
    }

    func setCullMode(_ cullMode: MTLCullMode) {
        recordedState.append("cull:\(cullMode.rawValue)")
    }

    func setFrontFacing(_ frontFacingWinding: MTLWinding) {
        recordedState.append("winding:\(frontFacingWinding.rawValue)")
    }

    func setDepthClipMode(_ depthClipMode: MTLDepthClipMode) {
        recordedState.append("clip:\(depthClipMode.rawValue)")
    }

    func setDepthBias(_ depthBias: Float, slopeScale: Float, clamp: Float) {
        recordedState.append("bias:\(depthBias):\(slopeScale):\(clamp)")
    }

    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?) {
        recordedState.append("ds:\(depthStencilState != nil)")
    }

    func setTriangleFillMode(_ fillMode: MTLTriangleFillMode) {
        recordedState.append("fill:\(fillMode.rawValue)")
    }

    func setBlendColor(red: Float, green: Float, blue: Float, alpha: Float) {
        recordedState.append("blend:\(red),\(green),\(blue),\(alpha)")
    }

    func setStencilReferenceValue(_ referenceValue: UInt32) {
        recordedState.append("stencil:\(referenceValue)")
    }

    func setStencilReferenceValues(front frontReferenceValue: UInt32, back backReferenceValue: UInt32) {
        recordedState.append("stencil:\(frontReferenceValue):\(backReferenceValue)")
    }

    func setVisibilityResultMode(_ mode: MTLVisibilityResultMode, offset: Int) {
        recordedState.append("vis:\(mode.rawValue):\(offset)")
    }

    func setColorStoreAction(_ storeAction: MTLStoreAction, index colorAttachmentIndex: Int) {
        descriptor.colorAttachments[colorAttachmentIndex].storeAction = storeAction
    }

    func setColorStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions, index colorAttachmentIndex: Int) {
        descriptor.colorAttachments[colorAttachmentIndex].storeActionOptions = storeActionOptions
    }

    func setDepthStoreAction(_ storeAction: MTLStoreAction) {
        descriptor.depthAttachment.storeAction = storeAction
    }

    func setDepthStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions) {
        descriptor.depthAttachment.storeActionOptions = storeActionOptions
    }

    func setStencilStoreAction(_ storeAction: MTLStoreAction) {
        descriptor.stencilAttachment.storeAction = storeAction
    }

    func setStencilStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions) {
        descriptor.stencilAttachment.storeActionOptions = storeActionOptions
    }

    func drawPrimitives(type primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int) {
        recordedState.append("draw:\(primitiveType.rawValue):\(vertexStart):\(vertexCount)")
    }

    func drawPrimitives(type primitiveType: MTLPrimitiveType, vertexStart: Int, vertexCount: Int, instanceCount: Int) {
        drawPrimitives(type: primitiveType, vertexStart: vertexStart, vertexCount: vertexCount)
        recordedState.append("instances:\(instanceCount)")
    }

    func drawPrimitives(
        type primitiveType: MTLPrimitiveType,
        vertexStart: Int,
        vertexCount: Int,
        instanceCount: Int,
        baseInstance: Int
    ) {
        drawPrimitives(type: primitiveType, vertexStart: vertexStart, vertexCount: vertexCount, instanceCount: instanceCount)
        recordedState.append("baseInstance:\(baseInstance)")
    }

    func drawPrimitives(type primitiveType: MTLPrimitiveType, indirectBuffer: any MTLBuffer, indirectBufferOffset: Int) {
        recordedState.append("drawIndirect:\(primitiveType.rawValue):\(indirectBuffer.length):\(indirectBufferOffset)")
    }

    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int
    ) {
        recordedState.append(
            "drawIndexed:\(primitiveType.rawValue):\(indexCount):\(indexType.rawValue):\(indexBuffer.length):\(indexBufferOffset)"
        )
    }

    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        instanceCount: Int
    ) {
        drawIndexedPrimitives(
            type: primitiveType,
            indexCount: indexCount,
            indexType: indexType,
            indexBuffer: indexBuffer,
            indexBufferOffset: indexBufferOffset
        )
        recordedState.append("instances:\(instanceCount)")
    }

    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexCount: Int,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        instanceCount: Int,
        baseVertex: Int,
        baseInstance: Int
    ) {
        drawIndexedPrimitives(
            type: primitiveType,
            indexCount: indexCount,
            indexType: indexType,
            indexBuffer: indexBuffer,
            indexBufferOffset: indexBufferOffset,
            instanceCount: instanceCount
        )
        recordedState.append("base:\(baseVertex):\(baseInstance)")
    }

    func drawIndexedPrimitives(
        type primitiveType: MTLPrimitiveType,
        indexType: MTLIndexType,
        indexBuffer: any MTLBuffer,
        indexBufferOffset: Int,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    ) {
        recordedState.append(
            "drawIndexedIndirect:\(primitiveType.rawValue):\(indexType.rawValue):\(indexBuffer.length):\(indexBufferOffset):\(indirectBuffer.length):\(indirectBufferOffset)"
        )
    }

    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage) {
        _ = (resource, usage)
    }

    func useResource(_ resource: any MTLResource, usage: MTLResourceUsage, stages: MTLRenderStages) {
        _ = (resource, usage, stages)
    }

    func useHeap(_ heap: any MTLHeap) {
        _ = heap
    }

    func useHeap(_ heap: any MTLHeap, stages: MTLRenderStages) {
        _ = (heap, stages)
    }

    func updateFence(_ fence: any MTLFence, after stages: MTLRenderStages) {
        _ = stages
        (fence as? LinuxMTLFence)?.signal()
    }

    func waitForFence(_ fence: any MTLFence, before stages: MTLRenderStages) {
        _ = stages
        (fence as? LinuxMTLFence)?.wait()
    }

    func memoryBarrier(scope: MTLBarrierScope, after: MTLRenderStages, before: MTLRenderStages) {
        _ = (scope, after, before)
    }

    func executeCommandsInBuffer(_ buffer: any MTLIndirectCommandBuffer, range: Range<Int>) {
        _ = (buffer, range)
        commandBuffer.failClosed(.notPermitted, reason: "no shader execution")
    }

    func executeCommandsInBuffer(
        _ buffer: any MTLIndirectCommandBuffer,
        indirectBuffer indirectRangeBuffer: any MTLBuffer,
        offset: Int
    ) {
        _ = (buffer, indirectRangeBuffer, offset)
        commandBuffer.failClosed(.notPermitted, reason: "no shader execution")
    }

    func setMeshBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        recordedState.append("meshB:\(index):\(offset):\(buffer?.length ?? -1)")
    }

    func setMeshBufferOffset(_ offset: Int, index: Int) {
        recordedState.append("meshBO:\(index):\(offset)")
    }

    func setMeshBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        _ = bytes
        recordedState.append("meshBytes:\(index):\(length)")
    }

    func setMeshTexture(_ texture: (any MTLTexture)?, index: Int) {
        recordedState.append("meshT:\(index):\(texture?.width ?? -1)")
    }

    func setMeshSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        recordedState.append("meshS:\(index):\(sampler != nil)")
    }

    func setMeshSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int) {
        _ = (lodMinClamp, lodMaxClamp)
        setMeshSamplerState(sampler, index: index)
    }

    func setObjectBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        recordedState.append("objB:\(index):\(offset):\(buffer?.length ?? -1)")
    }

    func setObjectBufferOffset(_ offset: Int, index: Int) {
        recordedState.append("objBO:\(index):\(offset)")
    }

    func setObjectBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        _ = bytes
        recordedState.append("objBytes:\(index):\(length)")
    }

    func setObjectTexture(_ texture: (any MTLTexture)?, index: Int) {
        recordedState.append("objT:\(index):\(texture?.width ?? -1)")
    }

    func setObjectSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        recordedState.append("objS:\(index):\(sampler != nil)")
    }

    func setObjectSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int) {
        _ = (lodMinClamp, lodMaxClamp)
        setObjectSamplerState(sampler, index: index)
    }

    func setObjectThreadgroupMemoryLength(_ length: Int, index: Int) {
        recordedState.append("objTG:\(index):\(length)")
    }

    func setTileBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        recordedState.append("tileB:\(index):\(offset):\(buffer?.length ?? -1)")
    }

    func setTileBufferOffset(_ offset: Int, index: Int) {
        recordedState.append("tileBO:\(index):\(offset)")
    }

    func setTileBytes(_ bytes: UnsafeRawPointer, length: Int, index: Int) {
        _ = bytes
        recordedState.append("tileBytes:\(index):\(length)")
    }

    func setTileTexture(_ texture: (any MTLTexture)?, index: Int) {
        recordedState.append("tileT:\(index):\(texture?.width ?? -1)")
    }

    func setTileSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        recordedState.append("tileS:\(index):\(sampler != nil)")
    }

    func setTileSamplerState(_ sampler: (any MTLSamplerState)?, lodMinClamp: Float, lodMaxClamp: Float, index: Int) {
        _ = (lodMinClamp, lodMaxClamp)
        setTileSamplerState(sampler, index: index)
    }

    func setThreadgroupMemoryLength(_ length: Int, offset: Int, index: Int) {
        recordedState.append("tg:\(index):\(offset):\(length)")
    }

    func setTessellationFactorBuffer(_ buffer: (any MTLBuffer)?, offset: Int, instanceStride: Int) {
        recordedState.append("tess:\(offset):\(instanceStride):\(buffer?.length ?? -1)")
    }

    func setTessellationFactorScale(_ scale: Float) {
        recordedState.append("tessScale:\(scale)")
    }

    func setDepthTestBounds(_ bounds: ClosedRange<Float>) {
        recordedState.append("depthBounds:\(bounds.lowerBound):\(bounds.upperBound)")
    }

    func dispatchThreadsPerTile(_ threadsPerTile: MTLSize) {
        recordedState.append("tileDispatch:\(threadsPerTile.width)x\(threadsPerTile.height)")
    }

    func drawMeshThreadgroups(
        _ threadgroupsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        recordedState.append(
            "meshTG:\(threadgroupsPerGrid.width):\(threadsPerObjectThreadgroup.width):\(threadsPerMeshThreadgroup.width)"
        )
    }

    func drawMeshThreadgroups(
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        recordedState.append(
            "meshTGIndirect:\(indirectBuffer.length):\(indirectBufferOffset):\(threadsPerObjectThreadgroup.width):\(threadsPerMeshThreadgroup.width)"
        )
    }

    func drawMeshThreads(
        _ threadsPerGrid: MTLSize,
        threadsPerObjectThreadgroup: MTLSize,
        threadsPerMeshThreadgroup: MTLSize
    ) {
        recordedState.append(
            "meshThreads:\(threadsPerGrid.width):\(threadsPerObjectThreadgroup.width):\(threadsPerMeshThreadgroup.width)"
        )
    }

    func drawPatches(
        numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int
    ) {
        recordedState.append(
            "patches:\(numberOfPatchControlPoints):\(patchStart):\(patchCount):\(patchIndexBufferOffset):\(instanceCount):\(baseInstance)"
        )
    }

    func drawPatches(
        numberOfPatchControlPoints: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    ) {
        recordedState.append(
            "patchesIndirect:\(numberOfPatchControlPoints):\(patchIndexBufferOffset):\(indirectBuffer.length):\(indirectBufferOffset)"
        )
    }

    func drawIndexedPatches(
        numberOfPatchControlPoints: Int,
        patchStart: Int,
        patchCount: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        controlPointIndexBuffer: any MTLBuffer,
        controlPointIndexBufferOffset: Int,
        instanceCount: Int,
        baseInstance: Int
    ) {
        recordedState.append(
            "idxPatches:\(numberOfPatchControlPoints):\(patchStart):\(patchCount):\(controlPointIndexBuffer.length):\(instanceCount):\(baseInstance)"
        )
    }

    func drawIndexedPatches(
        numberOfPatchControlPoints: Int,
        patchIndexBuffer: (any MTLBuffer)?,
        patchIndexBufferOffset: Int,
        controlPointIndexBuffer: any MTLBuffer,
        controlPointIndexBufferOffset: Int,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    ) {
        recordedState.append(
            "idxPatchesIndirect:\(numberOfPatchControlPoints):\(controlPointIndexBuffer.length):\(indirectBuffer.length):\(indirectBufferOffset)"
        )
    }

    func memoryBarrier(resources: [any MTLResource], after: MTLRenderStages, before: MTLRenderStages) {
        recordedState.append("barrierResources:\(resources.count):\(after.rawValue):\(before.rawValue)")
    }

    func sampleCounters(sampleBuffer: any MTLCounterSampleBuffer, sampleIndex: Int, barrier: Bool) {
        recordedState.append("counters:\(sampleBuffer.sampleCount):\(sampleIndex):\(barrier)")
    }

    func setColorAttachmentMap(_ mapping: MTLLogicalToPhysicalColorAttachmentMap?) {
        recordedState.append("colorMap:\(mapping != nil)")
    }

    func setVertexAccelerationStructure(_ accelerationStructure: (any MTLAccelerationStructure)?, bufferIndex: Int) {
        recordedState.append("vas:\(bufferIndex):\(accelerationStructure?.size ?? -1)")
    }

    func setFragmentAccelerationStructure(_ accelerationStructure: (any MTLAccelerationStructure)?, bufferIndex: Int) {
        recordedState.append("fas:\(bufferIndex):\(accelerationStructure?.size ?? -1)")
    }

    func setTileAccelerationStructure(_ accelerationStructure: (any MTLAccelerationStructure)?, bufferIndex: Int) {
        recordedState.append("tas:\(bufferIndex):\(accelerationStructure?.size ?? -1)")
    }

    func setVertexIntersectionFunctionTable(_ intersectionFunctionTable: (any MTLIntersectionFunctionTable)?, bufferIndex: Int) {
        recordedState.append("vift:\(bufferIndex):\(intersectionFunctionTable != nil)")
    }

    func setFragmentIntersectionFunctionTable(_ intersectionFunctionTable: (any MTLIntersectionFunctionTable)?, bufferIndex: Int) {
        recordedState.append("fift:\(bufferIndex):\(intersectionFunctionTable != nil)")
    }

    func setTileIntersectionFunctionTable(_ intersectionFunctionTable: (any MTLIntersectionFunctionTable)?, bufferIndex: Int) {
        recordedState.append("tift:\(bufferIndex):\(intersectionFunctionTable != nil)")
    }

    func setVertexVisibleFunctionTable(_ functionTable: (any MTLVisibleFunctionTable)?, bufferIndex: Int) {
        recordedState.append("vvft:\(bufferIndex):\(functionTable != nil)")
    }

    func setFragmentVisibleFunctionTable(_ functionTable: (any MTLVisibleFunctionTable)?, bufferIndex: Int) {
        recordedState.append("fvft:\(bufferIndex):\(functionTable != nil)")
    }

    func setTileVisibleFunctionTable(_ functionTable: (any MTLVisibleFunctionTable)?, bufferIndex: Int) {
        recordedState.append("tvft:\(bufferIndex):\(functionTable != nil)")
    }

    func setVertexAmplificationCount(_ count: Int, viewMappings: UnsafePointer<MTLVertexAmplificationViewMapping>?) {
        let viewport = viewMappings?.pointee.viewportArrayIndexOffset ?? 0
        recordedState.append("amplify:\(count):\(viewport)")
    }
}

final class LinuxMTLLibrary: NSObject, MTLLibrary, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    let functionNames: [String]
    let type: MTLLibraryType
    let installName: String?
    private let builtin: Bool

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, functionNames: [String], builtin: Bool) {
        self.owningDevice = device
        self.functionNames = functionNames
        self.type = .executable
        self.installName = nil
        self.builtin = builtin
        super.init()
    }

    static func cpuBuiltin(device: any MTLDevice) -> LinuxMTLLibrary {
        let linux = device as? LinuxMTLDevice ?? LinuxMTLDevice.shared
        return LinuxMTLLibrary(
            device: linux,
            functionNames: MTLCPUBuiltinKernel.allCases.map(\.rawValue),
            builtin: true
        )
    }

    func makeFunction(name functionName: String) -> (any MTLFunction)? {
        guard functionNames.contains(functionName) else { return nil }
        return LinuxMTLFunction(device: owningDevice, name: functionName, builtin: builtin)
    }

    func makeFunction(descriptor: MTLFunctionDescriptor) throws -> any MTLFunction {
        guard let name = descriptor.name, let function = makeFunction(name: name) else {
            throw metalUnsupportedLibraryError(.functionNotFound, reason: "function not found")
        }
        return function
    }

    func makeFunction(name: String, constantValues: MTLFunctionConstantValues) throws -> any MTLFunction {
        _ = constantValues
        guard let function = makeFunction(name: name) else {
            throw metalUnsupportedLibraryError(.functionNotFound, reason: "function not found")
        }
        return function
    }

    func reflection(functionName: String) -> MTLFunctionReflection? {
        _ = functionName
        return nil
    }
}

final class LinuxMTLFunction: NSObject, MTLFunction, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let functionType: MTLFunctionType
    let name: String
    var label: String?
    let options: MTLFunctionOptions = []
    let patchType: MTLPatchType = .none
    let patchControlPointCount: Int = 0
    let vertexAttributes: [MTLVertexAttribute]? = nil
    let stageInputAttributes: [MTLAttribute]? = nil
    let functionConstantsDictionary: [String: MTLFunctionConstant] = [:]
    let isCPUBuiltin: Bool

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, name: String, builtin: Bool) {
        self.owningDevice = device
        self.name = name
        self.isCPUBuiltin = builtin
        self.functionType = .kernel
        super.init()
    }

    func makeArgumentEncoder(bufferIndex: Int) -> any MTLArgumentEncoder {
        _ = bufferIndex
        return LinuxMTLArgumentEncoder(device: owningDevice, arguments: [])
    }
}

final class LinuxMTLComputePipelineState: NSObject, MTLComputePipelineState, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let function: LinuxMTLFunction
    let allocatedSize: Int = 0
    var label: String? { function.label }
    let gpuResourceID: MTLResourceID
    var maxTotalThreadsPerThreadgroup: Int { 64 }
    var threadExecutionWidth: Int { 1 }
    var staticThreadgroupMemoryLength: Int { 0 }
    var supportIndirectCommandBuffers: Bool { false }
    var shaderValidation: MTLShaderValidation { .disabled }
    var requiredThreadsPerThreadgroup: MTLSize { MTLSize() }

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, function: LinuxMTLFunction) {
        self.owningDevice = device
        self.function = function
        self.gpuResourceID = device.nextID()
        super.init()
    }

    func imageblockMemoryLength(forDimensions imageblockDimensions: MTLSize) -> Int {
        _ = imageblockDimensions
        return 0
    }
}

final class LinuxMTLRenderPipelineState: NSObject, MTLRenderPipelineState, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    let descriptor: MTLRenderPipelineDescriptor
    let allocatedSize: Int = 0
    var label: String? { descriptor.label }
    let gpuResourceID: MTLResourceID
    var maxTotalThreadsPerThreadgroup: Int { 0 }
    var threadExecutionWidth: Int { 1 }
    var imageblockSampleLength: Int { 0 }
    var supportIndirectCommandBuffers: Bool { false }
    var shaderValidation: MTLShaderValidation { descriptor.shaderValidation }
    var maxTotalThreadgroupsPerMeshGrid: Int { 0 }
    var maxTotalThreadsPerMeshThreadgroup: Int { 0 }
    var maxTotalThreadsPerObjectThreadgroup: Int { 0 }
    var meshThreadExecutionWidth: Int { 1 }
    var objectThreadExecutionWidth: Int { 1 }
    var requiredThreadsPerMeshThreadgroup: MTLSize { MTLSize() }
    var requiredThreadsPerObjectThreadgroup: MTLSize { MTLSize() }
    var requiredThreadsPerTileThreadgroup: MTLSize { MTLSize() }
    var threadgroupSizeMatchesTileSize: Bool { false }

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, descriptor: MTLRenderPipelineDescriptor) {
        self.owningDevice = device
        self.descriptor = descriptor
        self.gpuResourceID = device.nextID()
        super.init()
    }

    func imageblockMemoryLength(forDimensions imageblockDimensions: MTLSize) -> Int {
        _ = imageblockDimensions
        return 0
    }

    func makeRenderPipelineState(
        additionalBinaryFunctions binaryFunctionsDescriptor: MTL4RenderPipelineBinaryFunctionsDescriptor
    ) throws -> any MTLRenderPipelineState {
        _ = binaryFunctionsDescriptor
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeRenderPipelineState(
        additionalBinaryFunctions: MTLRenderPipelineFunctionsDescriptor
    ) throws -> any MTLRenderPipelineState {
        _ = additionalBinaryFunctions
        throw metalUnsupportedLibraryError(
            .compileFailure,
            reason: "no shader compiler"
        )
    }

    func makeRenderPipelineDescriptorForSpecialization() -> MTL4PipelineDescriptor {
        MTL4PipelineDescriptor()
    }
}

final class LinuxMTLArgumentEncoder: NSObject, MTLArgumentEncoder, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    let encodedLength: Int
    let alignment: Int = 16
    private let slotStride = 16
    private var backing: UnsafeMutableRawPointer
    private var ownsBacking = true
    private var argumentBuffer: (any MTLBuffer)?
    private var argumentOffset = 0
    private let arguments: [MTLArgumentDescriptor]

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, arguments: [MTLArgumentDescriptor]) {
        self.owningDevice = device
        self.arguments = arguments
        let maxIndex = arguments.map(\.index).max() ?? -1
        let length = maxIndex < 0 ? 0 : (maxIndex + 1) * 16
        self.encodedLength = length
        self.backing = UnsafeMutableRawPointer.allocate(byteCount: max(length, 16), alignment: 16)
        self.backing.initializeMemory(as: UInt8.self, repeating: 0, count: max(length, 16))
        super.init()
    }

    deinit {
        if ownsBacking {
            backing.deallocate()
        }
    }

    private func slot(_ index: Int) -> UnsafeMutableRawPointer? {
        let offset = argumentOffset + index * slotStride
        if let argumentBuffer {
            guard offset + slotStride <= argumentBuffer.length else { return nil }
            return argumentBuffer.contents().advanced(by: offset)
        }
        guard offset + slotStride <= max(encodedLength, 16) else { return nil }
        return backing.advanced(by: index * slotStride)
    }

    func setArgumentBuffer(_ argumentBuffer: (any MTLBuffer)?, offset: Int) {
        self.argumentBuffer = argumentBuffer
        self.argumentOffset = max(offset, 0)
    }

    func setArgumentBuffer(_ argumentBuffer: (any MTLBuffer)?, startOffset: Int, arrayElement: Int) {
        setArgumentBuffer(argumentBuffer, offset: startOffset + arrayElement * encodedLength)
    }

    func setBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        guard let slot = slot(index) else { return }
        let packed = (buffer?.gpuAddress ?? 0) &+ UInt64(offset)
        slot.storeBytes(of: packed, as: UInt64.self)
    }

    func setTexture(_ texture: (any MTLTexture)?, index: Int) {
        guard let slot = slot(index) else { return }
        slot.storeBytes(of: texture?.gpuResourceID._impl ?? 0, as: UInt64.self)
    }

    func setSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        guard let slot = slot(index) else { return }
        slot.storeBytes(of: sampler?.gpuResourceID._impl ?? 0, as: UInt64.self)
    }

    func setRenderPipelineState(_ pipeline: (any MTLRenderPipelineState)?, index: Int) {
        guard let slot = slot(index) else { return }
        slot.storeBytes(of: pipeline?.gpuResourceID._impl ?? 0, as: UInt64.self)
    }

    func setComputePipelineState(_ pipeline: (any MTLComputePipelineState)?, index: Int) {
        guard let slot = slot(index) else { return }
        slot.storeBytes(of: pipeline?.gpuResourceID._impl ?? 0, as: UInt64.self)
    }

    func setIndirectCommandBuffer(_ indirectCommandBuffer: (any MTLIndirectCommandBuffer)?, index: Int) {
        guard let slot = slot(index) else { return }
        slot.storeBytes(of: indirectCommandBuffer?.gpuResourceID._impl ?? 0, as: UInt64.self)
    }

    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?, index: Int) {
        guard let slot = slot(index) else { return }
        slot.storeBytes(of: depthStencilState?.gpuResourceID._impl ?? 0, as: UInt64.self)
    }

    func constantData(at index: Int) -> UnsafeMutableRawPointer {
        slot(index) ?? backing
    }

    func makeArgumentEncoderForBuffer(atIndex index: Int) -> (any MTLArgumentEncoder)? {
        _ = index
        return nil
    }
}

final class LinuxMTLParallelRenderCommandEncoder: NSObject, MTLParallelRenderCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    let descriptor: MTLRenderPassDescriptor
    var label: String?
    private var ended = false
    private var childCount = 0

    var device: any MTLDevice { commandBuffer.device }

    init(commandBuffer: LinuxMTLCommandBuffer, descriptor: MTLRenderPassDescriptor) {
        self.commandBuffer = commandBuffer
        self.descriptor = descriptor
        super.init()
    }

    func makeRenderCommandEncoder() -> (any MTLRenderCommandEncoder)? {
        guard !ended else { return nil }
        childCount += 1
        return LinuxMTLRenderCommandEncoder(
            commandBuffer: commandBuffer,
            descriptor: descriptor,
            ownsCommandBufferSlot: false
        )
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        if childCount == 0 {
            let descriptor = self.descriptor
            commandBuffer.record {
                LinuxMTLRenderCommandEncoder.applyLoadStore(descriptor)
            }
        }
        commandBuffer.finishEncoder()
    }

    func insertDebugSignpost(_ string: String) {
        _ = string
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages) {
        _ = (afterQueueStages, beforeStages)
    }

    func setColorStoreAction(_ storeAction: MTLStoreAction, index colorAttachmentIndex: Int) {
        descriptor.colorAttachments[colorAttachmentIndex].storeAction = storeAction
    }

    func setColorStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions, index colorAttachmentIndex: Int) {
        descriptor.colorAttachments[colorAttachmentIndex].storeActionOptions = storeActionOptions
    }

    func setDepthStoreAction(_ storeAction: MTLStoreAction) {
        descriptor.depthAttachment.storeAction = storeAction
    }

    func setDepthStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions) {
        descriptor.depthAttachment.storeActionOptions = storeActionOptions
    }

    func setStencilStoreAction(_ storeAction: MTLStoreAction) {
        descriptor.stencilAttachment.storeAction = storeAction
    }

    func setStencilStoreActionOptions(_ storeActionOptions: MTLStoreActionOptions) {
        descriptor.stencilAttachment.storeActionOptions = storeActionOptions
    }
}

final class LinuxMTLResourceStateCommandEncoder: NSObject, MTLResourceStateCommandEncoder, @unchecked Sendable {
    unowned let commandBuffer: LinuxMTLCommandBuffer
    var label: String?
    private var ended = false

    var device: any MTLDevice { commandBuffer.device }

    init(commandBuffer: LinuxMTLCommandBuffer) {
        self.commandBuffer = commandBuffer
        super.init()
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        commandBuffer.finishEncoder()
    }

    func insertDebugSignpost(_ string: String) {
        _ = string
    }

    func pushDebugGroup(_ string: String) {
        _ = string
    }

    func popDebugGroup() {}

    func barrier(afterQueueStages: MTLStages, beforeStages: MTLStages) {
        _ = (afterQueueStages, beforeStages)
    }

    func update(_ fence: any MTLFence) {
        commandBuffer.record {
            (fence as? LinuxMTLFence)?.signal()
        }
    }

    func wait(for fence: any MTLFence) {
        commandBuffer.record {
            (fence as? LinuxMTLFence)?.wait()
        }
    }

    func updateTextureMapping(
        _ texture: any MTLTexture,
        mode: MTLSparseTextureMappingMode,
        region: MTLRegion,
        mipLevel: Int,
        slice: Int
    ) {
        _ = (texture, mode, region, mipLevel, slice)
        commandBuffer.failClosed(
            .notPermitted,
            reason: "sparse texture mapping is not available on the CPU reference"
        )
    }

    func updateTextureMapping(
        _ texture: any MTLTexture,
        mode: MTLSparseTextureMappingMode,
        indirectBuffer: any MTLBuffer,
        indirectBufferOffset: Int
    ) {
        _ = (texture, mode, indirectBuffer, indirectBufferOffset)
        commandBuffer.failClosed(
            .notPermitted,
            reason: "sparse texture mapping is not available on the CPU reference"
        )
    }

    func updateTextureMappings(
        _ texture: any MTLTexture,
        mode: MTLSparseTextureMappingMode,
        regions: UnsafePointer<MTLRegion>,
        mipLevels: UnsafePointer<Int>,
        slices: UnsafePointer<Int>,
        numRegions: Int
    ) {
        _ = (texture, mode, regions, mipLevels, slices, numRegions)
        commandBuffer.failClosed(
            .notPermitted,
            reason: "sparse texture mapping is not available on the CPU reference"
        )
    }

    func moveTextureMappings(
        sourceTexture: any MTLTexture,
        sourceSlice: Int,
        sourceLevel: Int,
        sourceOrigin: MTLOrigin,
        sourceSize: MTLSize,
        destinationTexture: any MTLTexture,
        destinationSlice: Int,
        destinationLevel: Int,
        destinationOrigin: MTLOrigin
    ) {
        _ = (
            sourceTexture, sourceSlice, sourceLevel, sourceOrigin, sourceSize,
            destinationTexture, destinationSlice, destinationLevel, destinationOrigin
        )
        commandBuffer.failClosed(
            .notPermitted,
            reason: "sparse texture mapping is not available on the CPU reference"
        )
    }
}
