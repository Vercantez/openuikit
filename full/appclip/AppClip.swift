import Foundation

/// Apple's public App Clip activation error domain.
///
/// The pinned `dotnet/macios` `[ErrorDomain("APActivationPayloadErrorDomain")]`
/// annotation records this string. The live Darwin `CFSTR` payload is not in
/// the sealed graphs; that remaining byte-level question is in
/// `oracle-questions.tsv`.
public let APActivationPayloadErrorDomain = "APActivationPayloadErrorDomain"

/// Bridged App Clip activation error.
///
/// The pinned API digester records a stored `_nsError: NSError` overlay
/// (`ClangImporterSynthesizedType`, Frozen) with `Code` children
/// `disallowed` then `doesNotMatch`. Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`.
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// (`__HALT`) on this toolchain, so those two Hashable members are provided
/// here.
///
/// `Code` raw values match the pinned `dotnet/macios` `[Native]` cases
/// (`Disallowed = 1`, `DoesNotMatch = 2`).
@frozen
public struct APActivationPayloadError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = APActivationPayloadError

        case disallowed = 1
        case doesNotMatch = 2
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { APActivationPayloadErrorDomain }

    public static var errorDomain: String { APActivationPayloadErrorDomain }

    public static var disallowed: Code { .disallowed }

    public static var doesNotMatch: Code { .doesNotMatch }

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

/// Invocation payload that launched an App Clip.
///
/// Apple's class is an `NSObject` that conforms to `NSSecureCoding` and
/// `NSCopying`, with no public default constructor (`DisableDefaultCtor` in
/// macios). Linux has no App Clip invocation, CardSession, or location
/// confirmation daemon, so this type is an empty host payload: `url` is
/// always `nil`, `init(coder:)` fails closed, and `confirmAcquired(in:)` is
/// omitted because `CLRegion` is owned by CoreLocation (not a declared
/// dependency). A public `init()` exists only so a host can hold the empty
/// state; it is not an Apple invocation factory.
open class APActivationPayload: NSObject, NSSecureCoding, NSCopying {
    public static var supportsSecureCoding: Bool { true }

    /// The invocation URL when Apple launched this App Clip. Always `nil`
    /// on Linux: there is no invocation payload to surface.
    open var url: URL? { nil }

    public override init() {
        super.init()
    }

    /// Apple's keyed-archive layout is unobserved. Unknown archives fail
    /// closed rather than inventing an invocation URL.
    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return APActivationPayload()
    }
}
