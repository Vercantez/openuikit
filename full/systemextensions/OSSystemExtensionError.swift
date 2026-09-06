import Foundation

/// Portable counterpart of SystemExtensions' bridged
/// `NS_ERROR_ENUM(OSSystemExtensionErrorDomain, OSSystemExtensionErrorCode)`.
///
/// Numeric codes follow the public header enumeration: `unknown = 1` through
/// `authorizationRequired = 13`. The stored `userInfo` is preserved exactly;
/// this overlay does not insert a default localized-description entry.
public struct OSSystemExtensionError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 1
        case missingEntitlement = 2
        case unsupportedParentBundleLocation = 3
        case extensionNotFound = 4
        case extensionMissingIdentifier = 5
        /// Apple's identifier preserves the historical misspelling.
        case duplicateExtensionIdentifer = 6
        case unknownExtensionCategory = 7
        case codeSignatureInvalid = 8
        case validationFailed = 9
        case forbiddenBySystemPolicy = 10
        case requestCanceled = 11
        case requestSuperseded = 12
        case authorizationRequired = 13
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { OSSystemExtensionErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unknown = Code.unknown
    public static let missingEntitlement = Code.missingEntitlement
    public static let unsupportedParentBundleLocation = Code.unsupportedParentBundleLocation
    public static let extensionNotFound = Code.extensionNotFound
    public static let extensionMissingIdentifier = Code.extensionMissingIdentifier
    public static let duplicateExtensionIdentifer = Code.duplicateExtensionIdentifer
    public static let unknownExtensionCategory = Code.unknownExtensionCategory
    public static let codeSignatureInvalid = Code.codeSignatureInvalid
    public static let validationFailed = Code.validationFailed
    public static let forbiddenBySystemPolicy = Code.forbiddenBySystemPolicy
    public static let requestCanceled = Code.requestCanceled
    public static let requestSuperseded = Code.requestSuperseded
    public static let authorizationRequired = Code.authorizationRequired

    public static func == (lhs: OSSystemExtensionError, rhs: OSSystemExtensionError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension OSSystemExtensionError.Code {
    /// Allow matching a System Extensions error code against an arbitrary error.
    public static func ~= (match: OSSystemExtensionError.Code, error: any Error) -> Bool {
        (error as? OSSystemExtensionError)?.code == match
    }
}
