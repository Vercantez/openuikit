import Compression
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build Compression with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s Compression and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `Data` values flow through public Compression APIs
//    without a framework-local Data stand-in.

private func assertNotCompressionType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("Compression."))
}

func compressionDependencyIdentityMain() {
    let payload = Data("dependency-identity".utf8)
    assertNotCompressionType(payload)
    precondition(type(of: payload) == Data.self)
    precondition(!String(reflecting: Data.self).hasPrefix("Compression."))

    var encoded = Data()
    let output = try! OutputFilter(.compress, using: .zlib) { chunk in
        if let chunk {
            encoded.append(chunk)
        }
    }
    try! output.write(payload)
    try! output.finalize()
    precondition(!encoded.isEmpty)
    assertNotCompressionType(encoded)
    precondition(type(of: encoded) == Data.self)
}

compressionDependencyIdentityMain()
