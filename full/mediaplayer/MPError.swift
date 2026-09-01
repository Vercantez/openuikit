import Foundation

/// Apple's public MediaPlayer error domain. The string matches the exported
/// C symbol name recorded in the TBD; a central Apple-oracle probe should
/// confirm the runtime byte value.
public let MPErrorDomain = "MPErrorDomain"

/// Bridged `NS_ERROR_ENUM` counterpart of `MPErrorCode`.
///
/// Numeric codes follow the public Xcode 26.1 `MPError.h` enumeration order
/// (`unknown = 0` through `requestTimedOut = 7`). Stored `userInfo` is
/// preserved exactly; this overlay does not insert a default localized
/// description.
public struct MPError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case permissionDenied = 1
        case cloudServiceCapabilityMissing = 2
        case networkConnectionFailed = 3
        case notFound = 4
        case notSupported = 5
        case cancelled = 6
        case requestTimedOut = 7
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MPErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknown = Code.unknown
    public static let permissionDenied = Code.permissionDenied
    public static let cloudServiceCapabilityMissing = Code.cloudServiceCapabilityMissing
    public static let networkConnectionFailed = Code.networkConnectionFailed
    public static let notFound = Code.notFound
    public static let notSupported = Code.notSupported
    public static let cancelled = Code.cancelled
    public static let requestTimedOut = Code.requestTimedOut

    public static func == (lhs: MPError, rhs: MPError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MPError.Code {
    public static func ~= (match: MPError.Code, error: any Error) -> Bool {
        (error as? MPError)?.code == match
    }
}

func _mpNotSupportedError() -> MPError {
    MPError(.notSupported)
}
