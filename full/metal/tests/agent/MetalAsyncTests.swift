import Foundation
import Metal

/// Async Metal 4 compiler and shared-event overlays.
///
/// Every test below is a top-level `async` no-argument function that awaits
/// the exact async overlay identifier. All completions are in-process: the
/// CPU reference has no shader compiler (immediate fail-closed throw) and the
/// shared event is pre-signaled (no suspension on hardware).

func testAsyncCompilerBinaryFunction() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    let taskOptions = MTL4CompilerTaskOptions()
    taskOptions.lookupArchives = []
    let binaryDesc = MTL4BinaryFunctionDescriptor()
    binaryDesc.name = "async-bin"
    do {
        _ = try await compiler.makeBinaryFunction(descriptor: binaryDesc, compilerTaskOptions: taskOptions)
        preconditionFailure("async binary function compile must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncCompilerDynamicLibraryFromURL() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    do {
        _ = try await compiler.makeDynamicLibrary(url: URL(fileURLWithPath: "/tmp/missing-async.metallib"))
        preconditionFailure("async dynamic library URL must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .fileNotFound)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncCompilerDynamicLibraryFromLibrary() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    do {
        _ = try await compiler.makeDynamicLibrary(library: MTLMakeCPUBuiltinLibrary(device))
        preconditionFailure("async dynamic library from library must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncCompilerRenderPipeline() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    do {
        _ = try await compiler.makeRenderPipelineState(
            descriptor: MTL4PipelineDescriptor(),
            dynamicLinkingDescriptor: nil,
            compilerTaskOptions: nil
        )
        preconditionFailure("async Metal 4 render pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncCompilerComputePipeline() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    do {
        _ = try await compiler.makeComputePipelineState(
            descriptor: MTL4ComputePipelineDescriptor(),
            dynamicLinkingDescriptor: nil,
            compilerTaskOptions: nil
        )
        preconditionFailure("async Metal 4 compute pipeline must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncCompilerMachineLearningPipeline() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    do {
        _ = try await compiler.makeMachineLearningPipelineState(descriptor: MTL4MachineLearningPipelineDescriptor())
        preconditionFailure("async ML pipeline creation must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncCompilerRenderPipelineSpecialization() async {
    let device = MTLCreateSystemDefaultDevice()!
    let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
    let cpuPipeline = try! device.makeRenderPipelineState(descriptor: {
        let d = MTLRenderPipelineDescriptor()
        d.colorAttachments[0].pixelFormat = .rgba8Unorm
        return d
    }())
    do {
        _ = try await compiler.makeRenderPipelineStateBySpecialization(
            descriptor: MTL4PipelineDescriptor(),
            pipeline: cpuPipeline
        )
        preconditionFailure("async specialization must fail closed")
    } catch let error as MTLLibraryError {
        precondition(error.code == .compileFailure)
    } catch {
        preconditionFailure("expected MTLLibraryError")
    }
}

func testAsyncSharedEventValueSignaled() async {
    let device = MTLCreateSystemDefaultDevice()!
    let event = device.makeSharedEvent()!
    precondition(event.signaledValue == 0)
    event.signaledValue = 9
    precondition(event.signaledValue == 9)
    await event.valueSignaled(9)
    await event.valueSignaled(4)
    precondition(event.signaledValue == 9)
}
