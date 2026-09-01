// Project-owned NSError and error-domain compatibility for the standalone
// Foundation guest.  This implementation intentionally uses the Objective-C
// runtime's canonical NSObject identity, but it does not depend on Darwin
// Foundation or CoreFoundation.

import FoundationEssentials
import ObjectiveC

public let NSCocoaErrorDomain = "NSCocoaErrorDomain"
public let NSPOSIXErrorDomain = "NSPOSIXErrorDomain"
public let NSOSStatusErrorDomain = "NSOSStatusErrorDomain"
public let NSMachErrorDomain = "NSMachErrorDomain"

public let NSLocalizedDescriptionKey = "NSLocalizedDescription"
public let NSLocalizedFailureReasonErrorKey = "NSLocalizedFailureReason"
public let NSLocalizedRecoverySuggestionErrorKey = "NSLocalizedRecoverySuggestion"
public let NSLocalizedRecoveryOptionsErrorKey = "NSLocalizedRecoveryOptions"
public let NSRecoveryAttempterErrorKey = "NSRecoveryAttempter"
public let NSHelpAnchorErrorKey = "NSHelpAnchor"
public let NSUnderlyingErrorKey = "NSUnderlyingError"
public let NSMultipleUnderlyingErrorsKey = "NSMultipleUnderlyingErrorsKey"
public let NSDebugDescriptionErrorKey = "NSDebugDescription"
public let NSFilePathErrorKey = "NSFilePath"
public let NSStringEncodingErrorKey = "NSStringEncodingErrorKey"
public let NSURLErrorKey = "NSURL"
public let NSSourceFilePathErrorKey = "NSSourceFilePathErrorKey"
public let NSDestinationFilePathErrorKey = "NSDestinationFilePath"

public let NSUserCancelledError = 3072
public let NSFileNoSuchFileError = 4
public let NSFileReadCorruptFileError = 259
public let NSPropertyListReadCorruptError = 3840

/// A Swift error that supplies its NSError domain, code, and user-info graph.
public protocol CustomNSError: Error {
    static var errorDomain: String { get }
    var errorCode: Int { get }
    var errorUserInfo: [String: Any] { get }
}

public extension CustomNSError {
    static var errorDomain: String { _typeName(Self.self, qualified: true) }
    var errorCode: Int { _getDefaultErrorCode(self) }
    var errorUserInfo: [String: Any] { [:] }
}

public extension CustomNSError where Self: RawRepresentable,
    Self.RawValue: FixedWidthInteger {
    var errorCode: Int { Int(truncatingIfNeeded: rawValue) }
}

public protocol RecoverableError: Error {
    var recoveryOptions: [String] { get }
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool
    func attemptRecovery(
        optionIndex recoveryOptionIndex: Int,
        resultHandler handler: @escaping (Bool) -> Void
    )
}

public extension RecoverableError {
    func attemptRecovery(
        optionIndex recoveryOptionIndex: Int,
        resultHandler handler: @escaping (Bool) -> Void
    ) {
        handler(attemptRecovery(optionIndex: recoveryOptionIndex))
    }
}

public typealias NSErrorPointer = AutoreleasingUnsafeMutablePointer<NSError?>?
public typealias ErrorPointer = NSErrorPointer

/// The Objective-C-shaped error object shared by thrown errors, JSON, regex,
/// and unchanged application code.
///
/// The user-info dictionary deliberately remains `[String: Any]`: Foundation
/// permits framework-specific values here, and erasing it to a Codable or
/// Hashable-only graph would break the error propagation contract.
open class NSError: NSObject, Error, CustomStringConvertible,
    CustomDebugStringConvertible, @unchecked Sendable {
    public let domain: String
    public let code: Int
    public let userInfo: [String: Any]

    /// Creates the empty-domain error used by source-compatible call sites
    /// such as `throw NSError() as Error`.
    ///
    /// Darwin exposes this initializer with an empty domain, zero code, and
    /// empty user-info dictionary. Its textual description is intentionally
    /// not specialized here: asking Darwin Foundation to describe this
    /// invalid-domain sentinel is not a stable operation.
    public override init() {
        self.domain = ""
        self.code = 0
        self.userInfo = [:]
        super.init()
    }

    public init(domain: String, code: Int, userInfo dict: [String: Any]? = nil) {
        self.domain = domain
        self.code = code
        self.userInfo = dict ?? [:]
        super.init()
    }

    open var localizedDescription: String {
        if let description = userInfo[NSLocalizedDescriptionKey] as? String {
            return description
        }
        if domain == NSCocoaErrorDomain,
           userInfo[NSLocalizedFailureReasonErrorKey] == nil {
            switch code {
            case NSPropertyListReadCorruptError:
                return "The data couldn’t be read because it isn’t in the correct format."
            case NSUserCancelledError:
                return "The operation was cancelled."
            case NSFileNoSuchFileError:
                return "The file doesn’t exist."
            default:
                break
            }
        }
        if let reason = localizedFailureReason {
            return "The operation couldn’t be completed. \(reason)"
        }
        return "The operation couldn’t be completed. (\(domain) error \(code).)"
    }

    open var localizedFailureReason: String? {
        if let value = userInfo[NSLocalizedFailureReasonErrorKey] as? String {
            return value
        }
        if domain == NSCocoaErrorDomain && code == NSPropertyListReadCorruptError {
            return "The data is not in the correct format."
        }
        return nil
    }

    open var localizedRecoverySuggestion: String? {
        userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String
    }

    open var localizedRecoveryOptions: [String]? {
        userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String]
    }

    open var recoveryAttempter: Any? {
        userInfo[NSRecoveryAttempterErrorKey]
    }

    open var helpAnchor: String? {
        userInfo[NSHelpAnchorErrorKey] as? String
    }

    open var filePath: String? {
        userInfo[NSFilePathErrorKey] as? String
    }

    open var underlyingErrors: [any Error] {
        var result: [any Error] = []
        if let error = userInfo[NSUnderlyingErrorKey] as? any Error {
            result.append(error)
        }
        if let errors = userInfo[NSMultipleUnderlyingErrorsKey] as? [any Error] {
            result.append(contentsOf: errors)
        }
        return result
    }

    public var _domain: String { domain }
    public var _code: Int { code }
    public var _userInfo: AnyObject? { userInfo as AnyObject }
    public func _getEmbeddedNSError() -> AnyObject? { self }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSError else { return false }
        return domain == other.domain
            && code == other.code
            && _foundationGuestAnyEqual(userInfo, other.userInfo)
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(domain)
        hasher.combine(code)
        _foundationGuestHashAny(userInfo, into: &hasher)
        return hasher.finalize()
    }

    open var description: String {
        let quoted = userInfo[NSLocalizedDescriptionKey] as? String
        let headline = quoted.map { "\"\($0)\"" } ?? "\"(null)\""
        guard !userInfo.isEmpty else {
            return "Error Domain=\(domain) Code=\(code) \(headline)"
        }
        return "Error Domain=\(domain) Code=\(code) \(headline) UserInfo=\(_foundationGuestDescribeDictionary(userInfo))"
    }

    open var debugDescription: String { description }
}

/// A Swift error value that can be reconstructed from its Objective-C
/// `NSError` representation.  The Swift runtime looks up this protocol and
/// `_bridgeNSErrorToError` by their Foundation ABI names when performing a
/// dynamic cast from `NSError` to a concrete error type.
public protocol _ObjectiveCBridgeableError: Error {
    init?(_bridgedNSError: NSError)
}

/// Runtime entry point for dynamically bridging an `NSError` into a concrete
/// Swift error.  On failure `out` remains uninitialized, matching the standard
/// Foundation overlay contract.
///
/// Apple's overlay uses a Clang-imported `NSError`, whose type component is
/// encoded as `So0C0C` in this compiler-known ABI symbol.  Our implementation
/// is a native Foundation class with the same object-reference calling
/// convention, so pin the entry point to the runtime spelling explicitly.
@_silgen_name("$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_SpyxGtAA021_ObjectiveCBridgeableE0RzlF")
public func _bridgeNSErrorToError<T: _ObjectiveCBridgeableError>(
    _ error: NSError,
    out: UnsafeMutablePointer<T>
) -> Bool {
    guard let bridged = T(_bridgedNSError: error) else { return false }
    out.initialize(to: bridged)
    return true
}

/// Foundation's null sentinel. Every instance compares equal and hashes alike,
/// matching the value semantics JSON clients rely upon.
open class NSNull: NSObject, CustomStringConvertible, @unchecked Sendable {
    public override init() { super.init() }
    open override func isEqual(_ object: Any?) -> Bool { object is NSNull }
    open override var hash: Int { 0 }
    open var description: String { "<null>" }
}

@inline(__always)
internal func _foundationGuestNSError(
    _ error: any Error,
    fallbackUserInfo: [String: Any] = [:]
) -> NSError {
    // Error's compiler-provided embedded-object hook distinguishes a real
    // NSError existential from a value error without asking Objective-C to
    // bridge the value. `error as AnyObject` is not safe here: for a value
    // error that expression re-enters `_convertErrorToNSError` recursively.
    if let error = error._getEmbeddedNSError() as? NSError { return error }
    if let custom = error as? any CustomNSError {
        var info = custom.errorUserInfo
        if let localized = error as? any LocalizedError {
            if info[NSLocalizedDescriptionKey] == nil,
               let value = localized.errorDescription {
                info[NSLocalizedDescriptionKey] = value
            }
            if info[NSLocalizedFailureReasonErrorKey] == nil,
               let value = localized.failureReason {
                info[NSLocalizedFailureReasonErrorKey] = value
            }
            if info[NSLocalizedRecoverySuggestionErrorKey] == nil,
               let value = localized.recoverySuggestion {
                info[NSLocalizedRecoverySuggestionErrorKey] = value
            }
            if info[NSHelpAnchorErrorKey] == nil,
               let value = localized.helpAnchor {
                info[NSHelpAnchorErrorKey] = value
            }
        }
        if let recoverable = error as? any RecoverableError {
            info[NSLocalizedRecoveryOptionsErrorKey] = recoverable.recoveryOptions
            info[NSRecoveryAttempterErrorKey] = recoverable
        }
        return NSError(
            domain: type(of: custom).errorDomain,
            code: custom.errorCode,
            userInfo: info
        )
    }
    var info = fallbackUserInfo
    if let localized = error as? any LocalizedError {
        if let value = localized.errorDescription {
            info[NSLocalizedDescriptionKey] = value
        }
        if let value = localized.failureReason {
            info[NSLocalizedFailureReasonErrorKey] = value
        }
        if let value = localized.recoverySuggestion {
            info[NSLocalizedRecoverySuggestionErrorKey] = value
        }
        if let value = localized.helpAnchor {
            info[NSHelpAnchorErrorKey] = value
        }
    }
    if let recoverable = error as? any RecoverableError {
        info[NSLocalizedRecoveryOptionsErrorKey] = recoverable.recoveryOptions
        info[NSRecoveryAttempterErrorKey] = recoverable
    }
    return NSError(domain: error._domain, code: error._code, userInfo: info)
}

/// Compiler-known bridge entry point used by unchanged `error as NSError`
/// expressions. Its spelling and signature are part of Swift's Foundation
/// overlay contract.
public func _convertErrorToNSError(_ error: any Error) -> NSError {
    _foundationGuestNSError(error)
}

/// Compiler-known bridge entry point used when an Objective-C nullable error
/// enters Swift. A nonnil NSError is already an Error and preserves identity.
public func _convertNSErrorToError(_ error: NSError?) -> any Error {
    error ?? NSError(
        domain: NSCocoaErrorDomain,
        code: 0,
        userInfo: [NSDebugDescriptionErrorKey: "A nil NSError crossed the error bridge."]
    )
}

private func _foundationGuestAnyEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if let lhs = lhs as? String, let rhs = rhs as? String { return lhs == rhs }
    if let lhs = lhs as? Bool, let rhs = rhs as? Bool { return lhs == rhs }
    if let lhs = lhs as? Int, let rhs = rhs as? Int { return lhs == rhs }
    if let lhs = lhs as? Int64, let rhs = rhs as? Int64 { return lhs == rhs }
    if let lhs = lhs as? UInt64, let rhs = rhs as? UInt64 { return lhs == rhs }
    if let lhs = lhs as? Double, let rhs = rhs as? Double { return lhs == rhs }
    if lhs is NSNull, rhs is NSNull { return true }
    if let lhs = lhs as? NSError, let rhs = rhs as? NSError {
        return lhs.isEqual(rhs)
    }
    if let lhs = lhs as? [Any], let rhs = rhs as? [Any] {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy(_foundationGuestAnyEqual)
    }
    if let lhs = lhs as? [String: Any], let rhs = rhs as? [String: Any] {
        guard lhs.count == rhs.count else { return false }
        return lhs.allSatisfy { key, value in
            rhs[key].map { _foundationGuestAnyEqual(value, $0) } ?? false
        }
    }
    if Mirror(reflecting: lhs).displayStyle == .class,
       Mirror(reflecting: rhs).displayStyle == .class {
        return ObjectIdentifier(lhs as AnyObject) == ObjectIdentifier(rhs as AnyObject)
    }
    return String(reflecting: lhs) == String(reflecting: rhs)
}

private func _foundationGuestHashAny(_ value: Any, into hasher: inout Hasher) {
    if let value = value as? String { hasher.combine(0); hasher.combine(value); return }
    if let value = value as? Bool { hasher.combine(1); hasher.combine(value); return }
    if let value = value as? Int { hasher.combine(2); hasher.combine(value); return }
    if let value = value as? Int64 { hasher.combine(3); hasher.combine(value); return }
    if let value = value as? UInt64 { hasher.combine(4); hasher.combine(value); return }
    if let value = value as? Double { hasher.combine(5); hasher.combine(value); return }
    if value is NSNull { hasher.combine(6); return }
    if let value = value as? NSError {
        hasher.combine(7); hasher.combine(value.hash); return
    }
    if let value = value as? [Any] {
        hasher.combine(8); hasher.combine(value.count)
        for element in value { _foundationGuestHashAny(element, into: &hasher) }
        return
    }
    if let value = value as? [String: Any] {
        hasher.combine(9); hasher.combine(value.count)
        for key in value.keys.sorted() {
            hasher.combine(key)
            _foundationGuestHashAny(value[key]!, into: &hasher)
        }
        return
    }
    if Mirror(reflecting: value).displayStyle == .class {
        hasher.combine(ObjectIdentifier(value as AnyObject))
    } else {
        hasher.combine(String(reflecting: value))
    }
}

private func _foundationGuestDescribeDictionary(_ dictionary: [String: Any]) -> String {
    let body = dictionary.keys.sorted().map { key in
        let value = dictionary[key]!
        if let string = value as? String { return "\(key) = \(string);" }
        return "\(key) = \(String(describing: value));"
    }.joined(separator: " ")
    return "{\(body)}"
}
