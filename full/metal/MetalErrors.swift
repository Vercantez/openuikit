import Foundation

public struct MTLLibraryError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: UInt, Hashable, Sendable {
        case unsupported = 1
        case `internal` = 2
        case compileFailure = 3
        case compileWarning = 4
        case functionNotFound = 5
        case fileNotFound = 6
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MTLLibraryErrorDomain }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let unsupported = Code.unsupported
    public static let `internal` = Code.internal
    public static let compileFailure = Code.compileFailure
    public static let compileWarning = Code.compileWarning
    public static let functionNotFound = Code.functionNotFound
    public static let fileNotFound = Code.fileNotFound

    public static func == (lhs: MTLLibraryError, rhs: MTLLibraryError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MTLLibraryError.Code {
    public static func ~= (match: MTLLibraryError.Code, error: any Error) -> Bool {
        (error as? MTLLibraryError)?.code == match
    }
}

public struct MTLCommandBufferError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: UInt, Hashable, Sendable {
        case none = 0
        case `internal` = 1
        case timeout = 2
        case pageFault = 3
        case blacklisted = 4
        case notPermitted = 7
        case outOfMemory = 8
        case invalidResource = 9
        case memoryless = 10
        case stackOverflow = 12
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MTLCommandBufferErrorDomain }
    public var errorCode: Int { Int(code.rawValue) }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let none = Code.none
    public static let `internal` = Code.internal
    public static let timeout = Code.timeout
    public static let pageFault = Code.pageFault
    public static let blacklisted = Code.blacklisted
    public static var accessRevoked: Code { .blacklisted }
    public static let notPermitted = Code.notPermitted
    public static let outOfMemory = Code.outOfMemory
    public static let invalidResource = Code.invalidResource
    public static let memoryless = Code.memoryless
    public static let stackOverflow = Code.stackOverflow

    public static func == (lhs: MTLCommandBufferError, rhs: MTLCommandBufferError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MTLCommandBufferError.Code {
    public static var accessRevoked: MTLCommandBufferError.Code { .blacklisted }

    public static func ~= (match: MTLCommandBufferError.Code, error: any Error) -> Bool {
        (error as? MTLCommandBufferError)?.code == match
    }
}

/// CPU-reference pipeline / descriptor validation. This is not an Apple
/// `MTLRenderPipelineError` domain (that identifier is absent from the
/// iPhoneOS 26.1 Swift graph). Callers must not treat the raw value as ABI.
public struct MTLCPUValidationError: Error, CustomStringConvertible, Equatable {
    public let reason: String

    public init(_ reason: String) {
        self.reason = reason
    }

    public var description: String { reason }
}

public struct MTLIOError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case urlInvalid = 1
        case `internal` = 2
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { MTLIOErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let urlInvalid = Code.urlInvalid
    public static let `internal` = Code.internal

    public static func == (lhs: MTLIOError, rhs: MTLIOError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension MTLIOError.Code {
    public static func ~= (match: MTLIOError.Code, error: any Error) -> Bool {
        (error as? MTLIOError)?.code == match
    }
}
