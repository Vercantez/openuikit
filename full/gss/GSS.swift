import CoreFoundation

/// Linux starting point for Apple's public `GSS` Clang overlay, seeded from
/// the Xcode 26.1 iPhoneOS 26.1 SDK.
///
/// RFC 2743/2744 status codes, context flags, address families, IOV tokens,
/// OID/buffer set arithmetic, name import/display/compare, token
/// encapsulate/decapsulate, and `gss_display_status` are real. Kerberos,
/// SPNEGO, Apple credential-store, and KDC/daemon paths stay fail-closed.
public enum GSSModuleInfo {
    public static let moduleName = "GSS"
    public static let errorDomain = "org.h5l.gss"

    public static var errorDomainAsCFString: CFString {
        errorDomain.withCString { pointer in
            CFStringCreateWithCString(
                kCFAllocatorDefault,
                pointer,
                CFStringBuiltInEncodings.UTF8.rawValue
            )!
        }
    }
}
