import Foundation

// Isolated Linux host has no CoreFoundation module. These spellings match the
// imported Security overlay's use of CF types. They are host lookalikes for
// CoreFoundation, not a second Foundation. The later EC2 integration build
// uses real CF types from the platform sysroot.

#if OPENUIKIT_GUEST
// The Linux-hosted Mach-O guest's Foundation re-exports its CoreFoundation
// module (full/foundation/CoreFoundationCompatibility.swift), which already
// names these with Apple's shapes (CFTypeRef is AnyObject, as in the iOS SDK:
// `var result: AnyObject?; SecItemCopyMatching(query, &result)`). Declaring
// them again here would make every file importing Security and Foundation
// ambiguous.
#else
public typealias CFString = String
public typealias CFDictionary = [String: Any]
public typealias CFTypeRef = Any
public typealias CFURL = URL
public typealias CFAbsoluteTime = Double

/// Only the default allocator is representable on the isolated host.
public enum CFAllocator: Sendable {}
#endif
public typealias CFData = Data
public typealias CFArray = [Any]
public typealias CFDate = Date
public typealias CFError = NSError
public typealias CFTypeID = UInt
public typealias CFIndex = Int
public typealias CFOptionFlags = UInt

/// DarwinBoolean stand-in for imported C APIs. Not a public Darwin substitute
/// for use outside Security; it exists so `SecTrustGetNetworkFetchAllowed`
/// can keep its graph signature.
public struct DarwinBoolean: ExpressibleByBooleanLiteral, Equatable, Sendable {
    public var boolValue: Bool

    public init(_ value: Bool) {
        self.boolValue = value
    }

    public init(booleanLiteral value: Bool) {
        self.boolValue = value
    }
}

func _securityFailClosedError() -> NSError {
    NSError(
        domain: "Security",
        code: Int(errSecUnimplemented),
        userInfo: [NSLocalizedDescriptionKey: "Security API is unimplemented on this Linux host"]
    )
}

func _securityError(_ status: OSStatus, _ message: String) -> NSError {
    NSError(
        domain: "Security",
        code: Int(status),
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}

// Isolated host has no Dispatch module. These spellings match the imported
// Security overlay (dispatch_queue_t / dispatch_data_t). They are host
// lookalikes, not a second libdispatch. The later EC2 integration build
// uses real Dispatch types from the platform sysroot.
public final class dispatch_queue_s: NSObject, @unchecked Sendable {}
public typealias dispatch_queue_t = dispatch_queue_s
public typealias dispatch_data_t = Data

public final class _SecCFArrayObject: NSObject, @unchecked Sendable {
    let values: [Any]
    init(_ values: [Any]) { self.values = values }
}
