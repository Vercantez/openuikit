import CoreFoundation
import Foundation

public func CFNetDiagnosticCreateWithURL(
    _ alloc: CFAllocator,
    _ url: CFURL
) -> Unmanaged<CFNetDiagnostic> {
    _ = alloc
    return cfRetain(CFNetDiagnostic(url: url))
}

public func CFNetDiagnosticCreateWithStreams(
    _ alloc: CFAllocator?,
    _ readStream: CFReadStream?,
    _ writeStream: CFWriteStream?
) -> Unmanaged<CFNetDiagnostic> {
    _ = alloc
    _ = readStream
    _ = writeStream
    return cfRetain(CFNetDiagnostic(url: nil))
}

public func CFNetDiagnosticSetName(_ details: CFNetDiagnostic, _ name: CFString) {
    details.lock.lock()
    details.name = swiftString(name)
    details.lock.unlock()
}

public func CFNetDiagnosticCopyNetworkStatusPassively(
    _ details: CFNetDiagnostic,
    _ description: UnsafeMutablePointer<Unmanaged<CFString>?>?
) -> CFNetDiagnosticStatus {
    details.lock.lock()
    let name = details.name
    details.lock.unlock()
    if let description {
        let text = name ?? "Network status is indeterminate on this host"
        description.pointee = cfRetain(cfString(text))
    }
    return CFNetDiagnosticStatus(CFNetDiagnosticStatusValues.connectionIndeterminate.rawValue)
}

public func CFNetDiagnosticDiagnoseProblemInteractively(
    _ details: CFNetDiagnostic
) -> CFNetDiagnosticStatus {
    _ = details
    return CFNetDiagnosticStatus(CFNetDiagnosticStatusValues.err.rawValue)
}
