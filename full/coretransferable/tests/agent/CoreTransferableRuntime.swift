@_spi(OpenUIKitHost) import CoreTransferable
import Dispatch
import Foundation

// Standalone host probe. The sealed schema-v2 gate compiles
// tests/agent/*Tests.swift plus a generated runner instead of this file.

precondition(TransferRepresentationVisibility.all != .team)
precondition(TransferRepresentationVisibility.ownProcess == .ownProcess)

let payload = Data("runtime-transfer".utf8)
let representation = DataRepresentation<Data>(
    exportedContentType: .data
) { item in
    item
}

let exported = { () -> Data in
    let semaphore = DispatchSemaphore(value: 0)
    var result: Data?
    Task {
        result = try await representation._export(payload)
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + .seconds(5)) == .success)
    return result!
}()
precondition(exported == payload)

print("CORETRANSFERABLE_AGENT_RUNTIME_OK")
