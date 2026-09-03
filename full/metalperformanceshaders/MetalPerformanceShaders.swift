import Foundation

/// Linux starting point for Apple's public `MetalPerformanceShaders` overlay.
///
/// This module reconstructs the compile-time surface used by image filters,
/// matrix descriptors, and kernel option types. GPU encode is fail-closed:
/// Linux has no Metal command stream, so encode APIs trap instead of inventing
/// filtered pixels. Host-backed `MPSImage` storage, data-type sizing, and
/// descriptor math are real CPU behavior.

public enum MetalPerformanceShadersModule {
    public static let moduleName = "MetalPerformanceShaders"
}
