import Compression
import Foundation

// Optional schema-v1-style runtime probe. The sealed schema-v2 host gate compiles
// tests/agent/*Tests.swift plus CompressionLoadSmoke.swift and emits the marker
// from generated runner stdout; this file is not part of that isolated compile.

func compressionAgentRuntimeProbe() {
    precondition(COMPRESSION_BROTLI.rawValue == 0xB02)
    precondition(Algorithm(rawValue: COMPRESSION_ZLIB) == .zlib)
    var encoded = Data()
    let output = try! OutputFilter(.compress, using: .zlib) { chunk in
        if let chunk { encoded.append(chunk) }
    }
    try! output.write(Data("runtime".utf8))
    try! output.finalize()
    precondition(!encoded.isEmpty)
}
