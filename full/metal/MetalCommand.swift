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
        status = .completed
        error = nil
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
        if status == .committed || status == .scheduled {
            status = .completed
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
            (event as? LinuxMTLEvent)?.signal(value)
        }
    }

    func encodeWaitForEvent(_ event: any MTLEvent, value: UInt64) {
        record {
            _ = (event, value)
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
        _ = renderPassDescriptor
        return nil
    }

    func makeResourceStateCommandEncoder() -> (any MTLResourceStateCommandEncoder)? {
        nil
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
        commandBuffer.record {
            guard let pipeline = snapshotPipeline, pipeline.function.isCPUBuiltin else { return }
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

    init(commandBuffer: LinuxMTLCommandBuffer, descriptor: MTLRenderPassDescriptor) {
        self.commandBuffer = commandBuffer
        self.descriptor = descriptor
        super.init()
    }

    func endEncoding() {
        guard !ended else { return }
        ended = true
        let descriptor = self.descriptor
        commandBuffer.record {
            LinuxMTLRenderCommandEncoder.applyLoadStore(descriptor)
        }
        commandBuffer.finishEncoder()
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
}

final class LinuxMTLArgumentEncoder: NSObject, MTLArgumentEncoder, @unchecked Sendable {
    unowned let owningDevice: LinuxMTLDevice
    var label: String?
    let encodedLength: Int
    let alignment: Int = 16
    private var dummy = UnsafeMutableRawPointer.allocate(byteCount: 16, alignment: 16)

    var device: any MTLDevice { owningDevice }

    init(device: LinuxMTLDevice, arguments: [MTLArgumentDescriptor]) {
        self.owningDevice = device
        self.encodedLength = 0
        _ = arguments
        super.init()
        dummy.initializeMemory(as: UInt8.self, repeating: 0, count: 16)
    }

    deinit {
        dummy.deallocate()
    }

    func setArgumentBuffer(_ argumentBuffer: (any MTLBuffer)?, offset: Int) {
        _ = (argumentBuffer, offset)
    }

    func setArgumentBuffer(_ argumentBuffer: (any MTLBuffer)?, startOffset: Int, arrayElement: Int) {
        _ = (argumentBuffer, startOffset, arrayElement)
    }

    func setBuffer(_ buffer: (any MTLBuffer)?, offset: Int, index: Int) {
        _ = (buffer, offset, index)
    }

    func setTexture(_ texture: (any MTLTexture)?, index: Int) {
        _ = (texture, index)
    }

    func setSamplerState(_ sampler: (any MTLSamplerState)?, index: Int) {
        _ = (sampler, index)
    }

    func setRenderPipelineState(_ pipeline: (any MTLRenderPipelineState)?, index: Int) {
        _ = (pipeline, index)
    }

    func setComputePipelineState(_ pipeline: (any MTLComputePipelineState)?, index: Int) {
        _ = (pipeline, index)
    }

    func setIndirectCommandBuffer(_ indirectCommandBuffer: (any MTLIndirectCommandBuffer)?, index: Int) {
        _ = (indirectCommandBuffer, index)
    }

    func setDepthStencilState(_ depthStencilState: (any MTLDepthStencilState)?, index: Int) {
        _ = (depthStencilState, index)
    }

    func constantData(at index: Int) -> UnsafeMutableRawPointer {
        _ = index
        return dummy
    }

    func makeArgumentEncoderForBuffer(atIndex index: Int) -> (any MTLArgumentEncoder)? {
        _ = index
        return nil
    }
}
