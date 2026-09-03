import Foundation

// Isolated Linux host has no CoreFoundation module. These spellings match the
// imported Security overlay's use of CF types. They are host lookalikes for
// CoreFoundation, not a second Foundation. The later EC2 integration build
// uses real CF types from the platform sysroot.

public typealias CFString = String
public typealias CFDictionary = [String: Any]
public typealias CFTypeRef = Any
public typealias CFData = Data
public typealias CFArray = [Any]
public typealias CFDate = Date
public typealias CFURL = URL
public typealias CFError = NSError
public typealias CFTypeID = UInt
public typealias CFIndex = Int
public typealias CFOptionFlags = UInt
public typealias CFAbsoluteTime = Double

/// Only the default allocator is representable on the isolated host.
public enum CFAllocator: Sendable {}

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
