import Foundation
import Metal

func testLibraryFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    do {
        _ = try device.makeLibrary(source: "kernel void k() {}", options: nil)
        fatalError("shader compilation must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
        precondition(error.errorCode == Int(MTLLibraryError.Code.compileFailure.rawValue))
        precondition(MTLLibraryError.errorDomain == MTLLibraryErrorDomain)
        let description = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        precondition(description.contains("no shader compiler"))
        precondition(MTLLibraryError.compileFailure ~= error)
        _ = error.errorUserInfo
        _ = error.hashValue
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
        let copy = MTLLibraryError(.compileFailure, userInfo: error.userInfo)
        precondition(copy == error)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeLibrary(URL: URL(fileURLWithPath: "/tmp/missing.metallib"))
        fatalError("metallib loading must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
        precondition(MTLLibraryError.fileNotFound ~= error)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeLibrary(filepath: "/tmp/missing.metallib")
        fatalError("filepath library load must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    do {
        _ = try device.makeDefaultLibrary(bundle: Bundle.main)
        fatalError("default library bundle load must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    _ = MTLLibraryError.unsupported
    _ = MTLLibraryError.internal
    _ = MTLLibraryError.compileWarning
    _ = MTLLibraryError.functionNotFound
}

func testCaptureFailClosed() {
    let capture = MTLCaptureManager.shared()
    precondition(!capture.supportsDestination(.developerTools))
    precondition(!capture.supportsDestination(.gpuTraceDocument))
    precondition(!capture.isCapturing)
    _ = capture.defaultCaptureScope
    do {
        try capture.startCapture(with: MTLCaptureDescriptor())
        fatalError("GPU capture must fail closed")
    } catch let error as MTLCaptureError {
        precondition(error == .notSupported)
        _ = MTLCaptureError.alreadyCapturing
        _ = MTLCaptureError.invalidDescriptor
    } catch {
        fatalError("expected MTLCaptureError")
    }
    let device = MTLCreateSystemDefaultDevice()!
    capture.startCapture(device: device)
    capture.startCapture(commandQueue: device.makeCommandQueue()!)
    let scope = capture.makeCaptureScope(device: device)
    scope.label = "scope"
    _ = scope.device
    _ = scope.commandQueue
    scope.begin()
    capture.startCapture(scope: scope)
    scope.end()
    _ = capture.makeCaptureScope(commandQueue: device.makeCommandQueue()!)
    capture.stopCapture()
    precondition(!capture.isCapturing)
}

func testArgumentEncoderAndICB() {
    let device = MTLCreateSystemDefaultDevice()!
    let argument = MTLArgumentDescriptor.argumentDescriptor()
    argument.dataType = .float
    argument.index = 0
    let encoder = device.makeArgumentEncoder(arguments: [argument])!
    encoder.label = "args"
    precondition(encoder.label == "args")
    precondition(encoder.encodedLength == 16)
    precondition(encoder.alignment == 16)
    precondition(encoder.device.name == device.name)
    let buffer = device.makeBuffer(length: 16, options: [])!
    encoder.setArgumentBuffer(buffer, offset: 0)
    encoder.setArgumentBuffer(buffer, startOffset: 0, arrayElement: 0)
    encoder.setBuffer(buffer, offset: 0, index: 0)
    encoder.setTexture(nil, index: 0)
    encoder.setSamplerState(nil, index: 0)
    encoder.setRenderPipelineState(nil, index: 0)
    encoder.setComputePipelineState(nil, index: 0)
    encoder.setIndirectCommandBuffer(nil, index: 0)
    encoder.setDepthStencilState(nil, index: 0)
    _ = encoder.constantData(at: 0)
    precondition(encoder.makeArgumentEncoderForBuffer(atIndex: 0) == nil)
    let payload = device.makeBuffer(length: encoder.encodedLength, options: [])!
    encoder.setArgumentBuffer(payload, offset: 0)
    let constant: Float = 2.5
    encoder.constantData(at: 0).storeBytes(of: constant, as: Float.self)
    precondition(payload.contents().load(as: Float.self) == 2.5)
    let pointed = device.makeBuffer(length: 8, options: [])!
    encoder.setBuffer(pointed, offset: 0, index: 0)
    precondition(payload.contents().load(as: UInt64.self) == pointed.gpuAddress)
    encoder.setArgumentBuffer(payload, startOffset: 0, arrayElement: 0)
    let icbDesc = MTLIndirectCommandBufferDescriptor()
    icbDesc.commandTypes = [.concurrentDispatch]
    let icb = device.makeIndirectCommandBuffer(descriptor: icbDesc, maxCommandCount: 4, options: [])!
    precondition(icb.size == 4)
    _ = icb.gpuResourceID
    precondition(icb.device.name == device.name)
    encoder.setIndirectCommandBuffer(icb, index: 0)
}

func testPipelineDescriptorValidation() {
    let device = MTLCreateSystemDefaultDevice()!
    let samples = MTLRenderPipelineDescriptor()
    samples.sampleCount = 0
    do {
        _ = try device.makeRenderPipelineState(descriptor: samples)
        fatalError("invalid sampleCount must fail")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("sampleCount"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
    let blending = MTLRenderPipelineDescriptor()
    blending.colorAttachments[0].isBlendingEnabled = true
    blending.colorAttachments[0].pixelFormat = .invalid
    do {
        _ = try device.makeRenderPipelineState(descriptor: blending)
        fatalError("blending without a color format must fail")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("blending"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
    let library = MTLMakeCPUBuiltinLibrary(device)
    let kernel = library.makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let shaded = MTLRenderPipelineDescriptor()
    shaded.vertexFunction = kernel
    do {
        _ = try device.makeRenderPipelineState(descriptor: shaded)
        fatalError("MSL vertex functions must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
        let description = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        precondition(description.contains("no shader compiler"))
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let fragmentShaded = MTLRenderPipelineDescriptor()
    fragmentShaded.fragmentFunction = kernel
    do {
        _ = try device.makeRenderPipelineState(descriptor: fragmentShaded)
        fatalError("MSL fragment functions must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        fatalError("expected MTLLibraryError")
    }
    let compute = MTLComputePipelineDescriptor()
    do {
        _ = try device.makeComputePipelineState(descriptor: compute)
        fatalError("compute pipeline without a function must fail")
    } catch let error as MTLCPUValidationError {
        precondition(error.reason.contains("compute function"))
    } catch {
        fatalError("expected MTLCPUValidationError")
    }
    let vertex = MTLVertexDescriptor()
    vertex.layouts[0].stride = 16
    let pipeline = MTLRenderPipelineDescriptor()
    pipeline.vertexDescriptor = vertex
    pipeline.colorAttachments[0].pixelFormat = .rgba8Unorm
    _ = try! device.makeRenderPipelineState(descriptor: pipeline)
}

func testComputeDispatchFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    let queue = device.makeCommandQueue()!
    let commandBuffer = queue.makeCommandBuffer()!
    let encoder = commandBuffer.makeComputeCommandEncoder()!
    encoder.dispatchThreads(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(1, 1, 1))
    encoder.endEncoding()
    var completed = false
    commandBuffer.addCompletedHandler { buffer in
        completed = true
        precondition(buffer.status == .error)
        let error = buffer.error as? MTLCommandBufferError
        precondition(error?.code == .notPermitted)
        precondition(MTLCommandBufferError.notPermitted ~= buffer.error!)
        precondition(MTLCommandBufferError.errorDomain == MTLCommandBufferErrorDomain)
        _ = error?.errorCode
        _ = error?.errorUserInfo
        _ = error?.hashValue
    }
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    precondition(completed)
    precondition(commandBuffer.status == .error)
    precondition((commandBuffer.error as? MTLCommandBufferError)?.code == .notPermitted)
}

func testIOCommandBufferFailClosed() {
    let device = MTLCreateSystemDefaultDevice()!
    let queueDesc = MTLIOCommandQueueDescriptor()
    queueDesc.maxCommandBufferCount = 2
    queueDesc.maxCommandsInFlight = 1
    queueDesc.priority = .normal
    queueDesc.type = .serial
    queueDesc.scratchBufferAllocator = nil
    let queue = try! device.makeIOCommandQueue(descriptor: queueDesc)
    queue.label = "io"
    precondition(queue.label == "io")
    queue.enqueueBarrier()
    let empty = queue.makeCommandBuffer()
    empty.label = "empty"
    precondition(empty.status == .pending)
    var emptyCompleted = false
    empty.addCompletedHandler { buffer in
        emptyCompleted = true
        precondition(buffer.status == .complete)
        precondition(buffer.error == nil)
    }
    empty.addBarrier()
    empty.pushDebugGroup("g")
    empty.popDebugGroup()
    let event = device.makeSharedEvent()!
    empty.signalEvent(event, value: 1)
    empty.waitForEvent(event, value: 1)
    empty.enqueue()
    empty.commit()
    empty.waitUntilCompleted()
    precondition(emptyCompleted)
    precondition(empty.status == .complete)
    let statusBuffer = device.makeBuffer(length: 8, options: [])!
    empty.copyStatus(buffer: statusBuffer, offset: 0)
    precondition(statusBuffer.contents().load(as: UInt64.self) == UInt64(MTLIOStatus.complete.rawValue))

    let loaded = queue.makeCommandBufferWithUnretainedReferences()
    let handle = MetalTestIOFileHandle()
    handle.label = "file"
    precondition(handle.label == "file")
    loaded.load(device.makeBuffer(length: 4, options: [])!, offset: 0, size: 4, sourceHandle: handle, sourceHandleOffset: 0)
    var bytes: UInt8 = 0
    withUnsafeMutableBytes(of: &bytes) { raw in
        loaded.loadBytes(raw.baseAddress!, size: 1, sourceHandle: handle, sourceHandleOffset: 0)
    }
    let tex = device.makeTexture(descriptor: MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .r8Unorm,
        width: 1,
        height: 1,
        mipmapped: false
    ))!
    loaded.load(
        tex,
        slice: 0,
        level: 0,
        size: MTLSizeMake(1, 1, 1),
        sourceBytesPerRow: 1,
        sourceBytesPerImage: 1,
        destinationOrigin: MTLOrigin(),
        sourceHandle: handle,
        sourceHandleOffset: 0
    )
    var loadCompleted = false
    loaded.addCompletedHandler { buffer in
        loadCompleted = true
        precondition(buffer.status == .error)
        let error = buffer.error as? MTLIOError
        precondition(error?.code == .internal)
        precondition(MTLIOError.internal ~= buffer.error!)
    }
    loaded.commit()
    loaded.waitUntilCompleted()
    precondition(loadCompleted)
    precondition(loaded.status == .error)

    let cancelled = queue.makeCommandBuffer()
    cancelled.tryCancel()
    precondition(cancelled.status == .cancelled)
}

func testCPUTensorBinaryArchiveAndHandles() {
    let device = MTLCreateSystemDefaultDevice()!
    let invalid = MTLTensorDescriptor()
    invalid.dataType = .none
    do {
        _ = try device.makeTensor(descriptor: invalid)
        fatalError("empty tensor must fail closed")
    } catch let error as MTLTensorError {
        precondition(error.code == .invalidDescriptor)
        precondition(MTLTensorError.invalidDescriptor ~= error)
        precondition(error.localizedDescription.contains("tensor"))
    } catch {
        fatalError("expected MTLTensorError")
    }
    let descriptor = MTLTensorDescriptor()
    descriptor.dataType = .float32
    descriptor.dimensions = MTLTensorExtents([4])!
    descriptor.usage = [.compute]
    descriptor.storageMode = .shared
    descriptor.cpuCacheMode = .defaultCache
    descriptor.hazardTrackingMode = .default
    descriptor.resourceOptions = .storageModeShared
    descriptor.strides = MTLTensorExtents([1])
    let copy = descriptor.copy() as! MTLTensorDescriptor
    precondition(copy.dimensions.extents == [4])
    let sized = device.tensorSizeAndAlign(descriptor: descriptor)
    precondition(sized.size >= 16)
    precondition(sized.align == 16)
    let tensor = try! device.makeTensor(descriptor: descriptor)
    precondition(tensor.dataType == .float32)
    precondition(tensor.dimensions.extents == [4])
    precondition(tensor.usage.contains(.compute))
    precondition(tensor.buffer == nil)
    precondition(tensor.bufferOffset == 0)
    _ = tensor.gpuResourceID
    _ = tensor.strides
    let values: [Float] = [1, 2, 3, 4]
    values.withUnsafeBytes { raw in
        tensor.replace(
            sliceOrigin: MTLTensorExtents([0])!,
            sliceDimensions: MTLTensorExtents([4])!,
            withBytes: raw.baseAddress!,
            strides: MTLTensorExtents([1])!
        )
    }
    var readback = [Float](repeating: 0, count: 4)
    readback.withUnsafeMutableBytes { raw in
        tensor.getBytes(
            raw.baseAddress!,
            strides: MTLTensorExtents([1])!,
            sliceOrigin: MTLTensorExtents([0])!,
            sliceDimensions: MTLTensorExtents([4])!
        )
    }
    precondition(readback == values)

    let archiveDesc = MTLBinaryArchiveDescriptor()
    archiveDesc.url = URL(fileURLWithPath: "/tmp/missing.metallib")
    let archive = try! device.makeBinaryArchive(descriptor: archiveDesc)
    archive.label = "cpu-archive"
    precondition(archive.device.name == device.name)
    try! archive.addComputePipelineFunctions(descriptor: MTLComputePipelineDescriptor())
    try! archive.addRenderPipelineFunctions(descriptor: MTLRenderPipelineDescriptor())
    do {
        try archive.serialize(to: URL(fileURLWithPath: "/tmp/out.metallib"))
        fatalError("serialize must fail closed")
    } catch let error as MTLBinaryArchiveError {
        precondition(error.code == .internalError)
        precondition(MTLBinaryArchiveError.internalError ~= error)
    } catch {
        fatalError("expected MTLBinaryArchiveError")
    }

    let builtin = MTLMakeCPUBuiltinLibrary(device).makeFunction(name: MTLCPUBuiltinKernel.fillUInt32.rawValue)!
    let handle = device.functionHandle(function: builtin)!
    precondition(handle.name == builtin.name)
    precondition(handle.functionType == .kernel)
    precondition(handle.device.name == device.name)
    _ = handle.gpuResourceID
    _ = device.functionHandle(function: LinuxMTL4BinaryFunctionStub())

    do {
        _ = try device.makeDynamicLibrary(library: MTLMakeCPUBuiltinLibrary(device))
        fatalError("dynamic library must fail closed")
    } catch let error as MTLDynamicLibraryError {
        precondition(error.code == .unsupported)
        precondition(MTLDynamicLibraryError.unsupported ~= error)
        precondition(error.localizedDescription.contains("dynamic library"))
    } catch {
        fatalError("expected MTLDynamicLibraryError")
    }
    do {
        _ = try device.makeDynamicLibrary(url: URL(fileURLWithPath: "/tmp/missing.dylib"))
        fatalError("dynamic library URL must fail closed")
    } catch let error as MTLDynamicLibraryError {
        precondition(error.code == .unsupported)
    } catch {
        fatalError("expected MTLDynamicLibraryError")
    }

    let logDesc = MTLLogStateDescriptor()
    logDesc.bufferSize = 256
    logDesc.level = .info
    let logState = try! device.makeLogState(descriptor: logDesc)
    var handlerCount = 0
    logState.addLogHandler { _, _, _, _ in handlerCount += 1 }
    precondition(handlerCount == 0)
    do {
        let bad = MTLLogStateDescriptor()
        bad.bufferSize = -1
        _ = try device.makeLogState(descriptor: bad)
        fatalError("negative log buffer must fail closed")
    } catch let error as MTLLogStateError {
        precondition(error == .invalidSize)
    } catch {
        fatalError("expected MTLLogStateError")
    }

    let sharedDesc = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba8Unorm,
        width: 1,
        height: 1,
        mipmapped: false
    )
    precondition(device.makeSharedTexture(descriptor: sharedDesc) == nil)
    let sharedHandle = MTLSharedTextureHandle()
    sharedHandle.label = "none"
    _ = sharedHandle.device
    _ = MTLSharedTextureHandle.supportsSecureCoding
    precondition(device.makeSharedTexture(handle: sharedHandle) == nil)

    let poolDesc = MTLResourceViewPoolDescriptor()
    poolDesc.label = "views"
    poolDesc.resourceViewCount = 4
    let pool = try! device.makeTextureViewPool(descriptor: poolDesc)
    precondition(pool.resourceViewCount == 4)
    precondition(pool.device.name == device.name)
    _ = pool.baseResourceID
    _ = pool.label
    let texture = device.makeTexture(descriptor: sharedDesc)!
    let first = pool.setTextureView(texture: texture, index: 0)
    _ = pool.setTextureView(texture: texture, descriptor: MTLTextureViewDescriptor(), index: 1)
    let buffer = device.makeBuffer(length: 16, options: .storageModeShared)!
    _ = pool.setTextureView(
        buffer: buffer,
        descriptor: sharedDesc,
        offset: 0,
        bytesPerRow: 4,
        index: 2
    )
    _ = pool.copyResourceViews(from: pool, sourceRange: 0..<1, destinationIndex: 3)
    _ = first

    let counterDesc = MTLCounterSampleBufferDescriptor()
    counterDesc.sampleCount = 2
    counterDesc.label = "cpu-counters"
    let counters = try! device.makeCounterSampleBuffer(descriptor: counterDesc)
    precondition(counters.sampleCount == 2)
    precondition(counters.device.name == device.name)
    precondition(try! counters.resolveCounterRange(0..<2) == nil)

    let encoderInfo = MetalTestCommandBufferEncoderInfo()
    precondition(encoderInfo.label == "encoder")
    precondition(encoderInfo.debugSignposts.isEmpty)
    precondition(encoderInfo.errorState == .completed)
}

private final class LinuxMTL4BinaryFunctionStub: NSObject, MTL4BinaryFunction {}

private final class MetalTestCommandBufferEncoderInfo: NSObject, MTLCommandBufferEncoderInfo {
    var label: String { "encoder" }
    var debugSignposts: [String] { [] }
    var errorState: MTLCommandEncoderErrorState { .completed }
}

private final class MetalTestIOFileHandle: NSObject, MTLIOFileHandle, @unchecked Sendable {
    var label: String?
}
