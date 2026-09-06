import Foundation
import Metal
import MetalPerformanceShadersGraph

/// Probe for a future clean EC2 integration build that links the real
/// Foundation and Metal modules. The isolated host gate does not compile
/// this file and is not permission to invent public Metal stand-ins.
func metalPerformanceShadersGraphDependencyIdentity() {
    let payload = Data([0, 1, 2, 3])
    let url = URL(fileURLWithPath: "/tmp/missing.mpsgraphpackage")
    let count = NSNumber(value: 2)
    let graph = MPSGraph()
    let constant = graph.constant(payload, shape: [count], dataType: .float32)
    _ = graph.constant(Double(count.doubleValue), dataType: .float32)
    _ = MPSGraphExecutable(package: url, descriptor: nil)
    _ = constant.shape
}
