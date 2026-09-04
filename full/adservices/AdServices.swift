@_exported import Foundation

/// Apple's public attribution error domain. The payload matches the
/// 2026-09-01 Apple interface oracle in
/// `tests/adservices-interface-apple-2026-09-01.txt`.
public let AAAttributionErrorDomain =
    "com.apple.ap.adservices.attributionError"

/// Bridged AdServices attribution error.
///
/// The pinned API digester records a stored `_nsError: NSError` overlay
/// (`ClangImporterSynthesizedType`, Frozen). Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`.
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// (`__HALT`) on this toolchain, so those two Hashable members are provided
/// here.
///
/// `Code` raw values match the pinned `dotnet/macios` `[Native]` cases
/// (`NetworkError = 1`, `InternalError = 2`, `PlatformNotSupported = 3`)
/// and the Apple interface oracle.
@frozen
public struct AAAttributionError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = AAAttributionError

        case networkError = 1
        case internalError = 2
        case platformNotSupported = 3
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { AAAttributionErrorDomain }

    public static var networkError: Code { .networkError }
    public static var internalError: Code { .internalError }
    public static var platformNotSupported: Code { .platformNotSupported }

    /// Foundation's `_BridgedStoredNSError` hash witnesses trap on Linux.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

/// Linux has no Apple Ads attribution daemon, App Store receipt identity, or
/// corresponding privacy boundary. Returning a fabricated token would be both
/// semantically wrong and unsafe, so this API deterministically fails closed.
@available(iOS 14.3, macOS 11.1, tvOS 14.3, *)
open class AAAttribution: NSObject {
    open class func attributionToken() throws -> String {
        throw AAAttributionError(
            .platformNotSupported,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Apple Ads attribution is unavailable on this host"
            ]
        )
    }
}
