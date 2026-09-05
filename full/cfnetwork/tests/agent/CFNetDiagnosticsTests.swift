import CFNetwork
import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

final class CallbackCounter {
    var value = 0
}

func cfDataFromUTF8(_ value: String) -> CFData {
    Array(value.utf8).withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CFNetworkRuntime: \(message)")
    }
}

func swiftString(_ value: CFString) -> String {
    let length = Int(CFStringGetLength(value))
    var buffer = [CChar](repeating: 0, count: max(16, length * 4 + 1))
    require(
        CFStringGetCString(
            value,
            &buffer,
            CFIndex(buffer.count),
            CFStringBuiltInEncodings.UTF8.rawValue
        ),
        "CFString conversion"
    )
    return String(cString: buffer)
}

func cfString(_ value: String) -> CFString {
    value.withCString { CFStringCreateWithCString(nil, $0, CFStringBuiltInEncodings.UTF8.rawValue)! }
}

func testCFNetDiagnosticCreate() {

    let url = CFURLCreateWithString(nil, cfString("https://example.com/"), nil)!
    let diagnostic = CFNetDiagnosticCreateWithURL(kCFAllocatorSystemDefault!, url)
        .takeRetainedValue()
    CFNetDiagnosticSetName(diagnostic, cfString("probe"))
    let fromStreams = CFNetDiagnosticCreateWithStreams(nil, nil, nil).takeRetainedValue()
    require(fromStreams != diagnostic, "stream diagnostic identity")
    require(fromStreams.hashValue == fromStreams.hashValue, "diagnostic hashValue")
    var diagnosticHasher = Hasher()
    fromStreams.hash(into: &diagnosticHasher)
    _ = diagnosticHasher.finalize()
    require(fromStreams == fromStreams, "diagnostic equality")
}

func testCFNetDiagnosticStatus() {

    let url = CFURLCreateWithString(nil, cfString("https://example.com/"), nil)!
    let diagnostic = CFNetDiagnosticCreateWithURL(kCFAllocatorSystemDefault!, url)
        .takeRetainedValue()
    CFNetDiagnosticSetName(diagnostic, cfString("probe"))
    var description: Unmanaged<CFString>?
    let status = CFNetDiagnosticCopyNetworkStatusPassively(diagnostic, &description)
    require(
        status == CFNetDiagnosticStatus(CFNetDiagnosticStatusValues.connectionIndeterminate.rawValue),
        "passive status is indeterminate"
    )
    require(swiftString(description!.takeRetainedValue()) == "probe", "diagnostic name")
    require(
        CFNetDiagnosticDiagnoseProblemInteractively(diagnostic)
            == CFNetDiagnosticStatus(CFNetDiagnosticStatusValues.err.rawValue),
        "interactive diagnose unavailable"
    )
}
