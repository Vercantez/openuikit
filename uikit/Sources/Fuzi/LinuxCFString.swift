// Guest Foundation uses the same explicit encoding bridge as corelibs.
// MEASURED focus-guest-linux: Fuzi emits a 250840-byte guest object.
#if os(Linux) || OPENUIKIT_GUEST
import Foundation

// Linux corelibs Foundation does not vend these CoreFoundation encoding
// helpers. Fuzi 3.1.3 Document.swift:36 uses them after `import Foundation`
// (Darwin toll-free). Same-module names so the vendored file is unpatched.
// MEASURED swift:6.2-noble: `cannot find type 'CFString' in scope`.
// Unrecognized IANA names return invalid, and Document.swift then uses UTF-8
// (Focus OpenSearchParser XML is UTF-8).

public typealias CFString = NSString
public let kCFStringEncodingInvalidId: UInt32 = 0xFFFF_FFFF
public let kCFStringEncodingUTF8: UInt32 = 0x0800_0100

public func CFStringConvertIANACharSetNameToEncoding(_ name: CFString?) -> UInt32 {
    guard let name else { return kCFStringEncodingInvalidId }
    let s = (name as String).lowercased()
    if s == "utf-8" || s == "utf8" { return kCFStringEncodingUTF8 }
    return kCFStringEncodingInvalidId
}

public func CFStringConvertEncodingToNSStringEncoding(_ encoding: UInt32) -> UInt {
    if encoding == kCFStringEncodingUTF8 { return 4 }
    return 1
}
#else
enum _OpenUIKitFuziLinuxCFString {}
#endif

