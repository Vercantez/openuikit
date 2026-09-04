import Foundation

public struct PKPassKitError: Error, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = -1
        case invalidDataError = 1
        case unsupportedVersionError = 2
        case invalidSignature = 3
        case notEntitledError = 4
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { PKPassKitErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String { "\(PKPassKitErrorDomain) \(code.rawValue)" }

    public static var unknownError: Code { .unknownError }
    public static var invalidDataError: Code { .invalidDataError }
    public static var unsupportedVersionError: Code { .unsupportedVersionError }
    public static var invalidSignature: Code { .invalidSignature }
    public static var notEntitledError: Code { .notEntitledError }
}

extension PKPassKitError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PKPassKitError)?.code == match
    }
}

public struct PKPaymentError: Error, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = -1
        case shippingContactInvalidError = 1
        case billingContactInvalidError = 2
        case shippingAddressUnserviceableError = 3
        case couponCodeInvalidError = 4
        case couponCodeExpiredError = 5
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { PKPaymentErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String { "\(PKPaymentErrorDomain) \(code.rawValue)" }

    public static var unknownError: Code { .unknownError }
    public static var shippingContactInvalidError: Code { .shippingContactInvalidError }
    public static var billingContactInvalidError: Code { .billingContactInvalidError }
    public static var shippingAddressUnserviceableError: Code { .shippingAddressUnserviceableError }
    public static var couponCodeInvalidError: Code { .couponCodeInvalidError }
    public static var couponCodeExpiredError: Code { .couponCodeExpiredError }
}

extension PKPaymentError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PKPaymentError)?.code == match
    }
}

public struct PKIdentityError: Error, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case notSupported = 1
        case cancelled = 2
        case networkUnavailable = 3
        case noElementsRequested = 4
        case requestAlreadyInProgress = 5
        case invalidNonce = 6
        case invalidElement = 7
        case regionNotSupported = 8
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { PKIdentityErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String { "\(PKIdentityErrorDomain) \(code.rawValue)" }

    public static var unknown: Code { .unknown }
    public static var notSupported: Code { .notSupported }
    public static var cancelled: Code { .cancelled }
    public static var networkUnavailable: Code { .networkUnavailable }
    public static var noElementsRequested: Code { .noElementsRequested }
    public static var requestAlreadyInProgress: Code { .requestAlreadyInProgress }
    public static var invalidNonce: Code { .invalidNonce }
    public static var invalidElement: Code { .invalidElement }
    public static var regionNotSupported: Code { .regionNotSupported }
}

extension PKIdentityError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PKIdentityError)?.code == match
    }
}

public struct PKDisbursementError: Error, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = -1
        case unsupportedCardError = 1
        case recipientContactInvalidError = 2
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { PKDisbursementErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String { "\(PKDisbursementErrorDomain) \(code.rawValue)" }

    public static var unknownError: Code { .unknownError }
    public static var unsupportedCardError: Code { .unsupportedCardError }
    public static var recipientContactInvalidError: Code { .recipientContactInvalidError }
}

extension PKDisbursementError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PKDisbursementError)?.code == match
    }
}

public struct PKAddSecureElementPassError: Error, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case genericError = 0
        case userCanceledError = 1
        case unavailableError = 2
        case invalidConfigurationError = 3
        case deviceNotSupportedError = 4
        case deviceNotReadyError = 5
        case osVersionNotSupportedError = 6
        public static var unknownError: Code { .genericError }
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { PKAddSecureElementPassErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String { "\(PKAddSecureElementPassErrorDomain) \(code.rawValue)" }

    public static var genericError: Code { .genericError }
    public static var unknownError: Code { .genericError }
    public static var userCanceledError: Code { .userCanceledError }
    public static var unavailableError: Code { .unavailableError }
    public static var invalidConfigurationError: Code { .invalidConfigurationError }
    public static var deviceNotSupportedError: Code { .deviceNotSupportedError }
    public static var deviceNotReadyError: Code { .deviceNotReadyError }
    public static var osVersionNotSupportedError: Code { .osVersionNotSupportedError }
}

extension PKAddSecureElementPassError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PKAddSecureElementPassError)?.code == match
    }
}

public struct PKShareSecureElementPassError: Error, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = 0
        case setupError = 1
    }

    public var code: Code
    public var userInfo: [String: String]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        var strings: [String: String] = [:]
        for (key, value) in userInfo {
            strings[key] = String(describing: value)
        }
        self.userInfo = strings
    }

    public static var errorDomain: String { PKShareSecureElementPassErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }
    public var localizedDescription: String { "\(PKShareSecureElementPassErrorDomain) \(code.rawValue)" }

    public static var unknownError: Code { .unknownError }
    public static var setupError: Code { .setupError }
}

extension PKShareSecureElementPassError.Code {
    public static func ~= (match: Self, error: any Error) -> Bool {
        (error as? PKShareSecureElementPassError)?.code == match
    }
}
