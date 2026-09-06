import Foundation
import MetalPerformanceShadersGraph

func testPackageLoadRefuses() {
    MPSGraphHostBoundary.reset()
    let url = URL(fileURLWithPath: "/tmp/missing.mpsgraphpackage")
    let coreML = MPSGraphExecutable(coreMLPackageAtURL: url, descriptor: nil)
    precondition(MPSGraphHostBoundary.lastRefusedAPI?.contains("coreMLPackageAtURL") == true)
    _ = MPSGraphExecutable(coreMLPackageAtURL: url, compilationDescriptor: nil)
    _ = MPSGraphExecutable(package: url, descriptor: nil)
    _ = MPSGraphExecutable(MPSGraphPackageAtURL: url, compilationDescriptor: nil)
    coreML.serialize(package: url, descriptor: MPSGraphExecutableSerializationDescriptor())
    precondition(MPSGraphHostBoundary.lastRefusedAPI?.contains("serialize") == true)
}

func testCompileAndExecutable() {
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, name: "x")
    let y = graph.identity(with: x, name: "y")
    let shaped = MPSGraphShapedType(shape: mpsgShape(2), dataType: .float32)
    let executable = graph.compile(
        with: MPSGraphDevice.hostDevice(),
        feeds: [x: shaped],
        targetTensors: [y],
        targetOperations: nil,
        compilationDescriptor: nil
    )
    executable.options = .verbose
    precondition(executable.options == .verbose)
    precondition(executable.feedTensors?.contains { $0 === x } == true)
    precondition(executable.targetTensors?.contains { $0 === y } == true)
    let types = executable.getOutputTypes(
        with: MPSGraphDevice.hostDevice(),
        inputTypes: [shaped],
        compilationDescriptor: nil
    )
    precondition(types?.count == 1)
    executable.specialize(with: nil, inputTypes: [shaped], compilationDescriptor: nil)
    let loaded = MPSGraphExecutable(package: URL(fileURLWithPath: "/tmp/missing.mpsgraphpackage"), descriptor: nil)
    precondition(loaded.getOutputTypes(with: nil, inputTypes: [], compilationDescriptor: nil) == nil)
    loaded.specialize(with: nil, inputTypes: [], compilationDescriptor: nil)
}

func testUnsupportedOpOmitsResult() {
    MPSGraphHostBoundary.reset()
    let graph = MPSGraph()
    let x = mpsgPlaceholder(graph, 2, name: "x")
    let fft = graph.fastFourierTransform(x, axes: mpsgShape(0), descriptor: MPSGraphFFTDescriptor(), name: nil)
    let results = graph.run(
        feeds: [x: mpsgFloatData([1, 2], shape: [2])],
        targetTensors: [fft],
        targetOperations: nil
    )
    precondition(results[fft] == nil)
    precondition(MPSGraphHostBoundary.lastRefusedAPI == "fastFourierTransform")
}
