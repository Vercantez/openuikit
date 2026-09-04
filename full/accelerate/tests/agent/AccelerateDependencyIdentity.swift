import Accelerate
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build Accelerate with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s Accelerate and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `Data` values flow through public Accelerate APIs
//    without a framework-local Data stand-in.

private func assertNotAccelerateType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("Accelerate."))
}

func accelerateDependencyIdentityMain() {
    let payload = Data([1, 2, 3, 4])
    assertNotAccelerateType(payload)
    precondition(type(of: payload) == Data.self)
    precondition(!String(reflecting: Data.self).hasPrefix("Accelerate."))

    let vectorA = payload.map { Float($0) }
    let vectorB: [Float] = [10, 20, 30, 40]
    let summed = vDSP.add(vectorA, vectorB)
    precondition(summed == [11, 22, 33, 44])
    assertNotAccelerateType(payload)
}

accelerateDependencyIdentityMain()
