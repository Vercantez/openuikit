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
