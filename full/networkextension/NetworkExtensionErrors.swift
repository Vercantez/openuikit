public struct NEVPNError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case configurationInvalid = 1
        case configurationDisabled = 2
        case connectionFailed = 3
        case configurationStale = 4
        case configurationReadWriteFailed = 5
        case configurationUnknown = 6
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { NEVPNErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let configurationInvalid = Code.configurationInvalid
    public static let configurationDisabled = Code.configurationDisabled
    public static let connectionFailed = Code.connectionFailed
    public static let configurationStale = Code.configurationStale
    public static let configurationReadWriteFailed = Code.configurationReadWriteFailed
    public static let configurationUnknown = Code.configurationUnknown

    public static func == (lhs: NEVPNError, rhs: NEVPNError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension NEVPNError.Code {
    public static func ~= (match: NEVPNError.Code, error: any Error) -> Bool {
        (error as? NEVPNError)?.code == match
    }
}

public struct NEAppProxyFlowError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case notConnected = 1
        case peerReset = 2
        case hostUnreachable = 3
        case invalidArgument = 4
        case aborted = 5
        case refused = 6
        case timedOut = 7
        case `internal` = 8
        case datagramTooLarge = 9
        case readAlreadyPending = 10
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { NEAppProxyErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let notConnected = Code.notConnected
    public static let peerReset = Code.peerReset
    public static let hostUnreachable = Code.hostUnreachable
    public static let invalidArgument = Code.invalidArgument
    public static let aborted = Code.aborted
    public static let refused = Code.refused
    public static let timedOut = Code.timedOut
    public static let `internal` = Code.internal
    public static let datagramTooLarge = Code.datagramTooLarge
    public static let readAlreadyPending = Code.readAlreadyPending

    public static func == (lhs: NEAppProxyFlowError, rhs: NEAppProxyFlowError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension NEAppProxyFlowError.Code {
    public static func ~= (match: NEAppProxyFlowError.Code, error: any Error) -> Bool {
        (error as? NEAppProxyFlowError)?.code == match
    }
}

public struct NEAppPushManagerError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case configurationInvalid = 1
        case configurationNotLoaded = 2
        case internalError = 3
        case inactiveSession = 4
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { NEAppPushErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let configurationInvalid = Code.configurationInvalid
    public static let configurationNotLoaded = Code.configurationNotLoaded
    public static let internalError = Code.internalError
    public static let inactiveSession = Code.inactiveSession

    public static func == (lhs: NEAppPushManagerError, rhs: NEAppPushManagerError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension NEAppPushManagerError.Code {
    public static func ~= (match: NEAppPushManagerError.Code, error: any Error) -> Bool {
        (error as? NEAppPushManagerError)?.code == match
    }
}

public struct NETunnelProviderError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case networkSettingsInvalid = 1
        case networkSettingsCanceled = 2
        case networkSettingsFailed = 3
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { NETunnelProviderErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let networkSettingsInvalid = Code.networkSettingsInvalid
    public static let networkSettingsCanceled = Code.networkSettingsCanceled
    public static let networkSettingsFailed = Code.networkSettingsFailed

    public static func == (lhs: NETunnelProviderError, rhs: NETunnelProviderError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension NETunnelProviderError.Code {
    public static func ~= (match: NETunnelProviderError.Code, error: any Error) -> Bool {
        (error as? NETunnelProviderError)?.code == match
    }
}
