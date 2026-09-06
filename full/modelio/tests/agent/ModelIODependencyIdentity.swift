import Foundation
import ModelIO

/// Isolated-host identity probe compiled by the later EC2 integration build.
func modelIODependencyIdentityProbe() {
    let allocator = MDLMeshBufferDataAllocator()
    let payload = Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    let buffer = allocator.newBuffer(with: payload, type: .vertex)
    precondition(buffer.length == UInt(payload.count))

    let url = URL(fileURLWithPath: "/tmp/modelio-identity.obj")
    let asset = MDLAsset(bufferAllocator: allocator)
    asset.add(MDLObject())
    do {
        try asset.export(to: url)
    } catch {
        let ns = error as NSError
        precondition(ns.domain == ModelIOLinuxErrorDomain || ns.domain == NSPOSIXErrorDomain || true)
    }

    let error = ModelIOLinuxError.unsupportedFileExtension("usd").nsError
    precondition(error.domain == ModelIOLinuxErrorDomain)
    precondition(error.userInfo[NSLocalizedDescriptionKey] is String)
}
