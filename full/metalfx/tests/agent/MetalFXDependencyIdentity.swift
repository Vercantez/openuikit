import Foundation
import Metal
import MetalFX

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation plus Metal lookalikes is not integrated
// MetalFX/Metal GPU success.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation and Metal modules and their dylibs.
// 2. Build MetalFX against those modules (drop MetalFXLinuxSupport.swift).
// 3. Link this file as a client that imports MetalFX, Foundation, and Metal.
// 4. Run with LD_LIBRARY_PATH covering the dylibs.
// 5. Confirm METALFX_DEPENDENCY_IDENTITY_OK and that libMetalFX.dylib loaded.

private func assertNotMetalFXType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("MetalFX."))
}

func metalFXDependencyIdentityProbe() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    assertNotMetalFXType(stamp)
    precondition(type(of: stamp) == Date.self)

    let descriptor = MTLFXSpatialScalerDescriptor()
    descriptor.inputWidth = 8
    descriptor.inputHeight = 8
    descriptor.outputWidth = 16
    descriptor.outputHeight = 16
    _ = descriptor.copy(with: nil)

    #if canImport(Metal)
    if let device = MTLCreateSystemDefaultDevice() {
        assertNotMetalFXType(device)
        precondition(MTLFXSpatialScalerDescriptor.supportsDevice(device) == false)
        precondition(descriptor.makeSpatialScaler(device: device) == nil)
    }
    #endif
}

#if METALFX_IDENTITY_MAIN
metalFXDependencyIdentityProbe()
print("METALFX_DEPENDENCY_IDENTITY_OK")
#endif
