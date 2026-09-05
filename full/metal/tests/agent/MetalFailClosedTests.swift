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
    precondition(encoder.encodedLength == 0)
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
    let icb = MTLIndirectCommandBufferDescriptor()
    icb.commandTypes = [.draw]
    precondition(device.makeIndirectCommandBuffer(descriptor: icb, maxCommandCount: 4, options: []) == nil)
}
