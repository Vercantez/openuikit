import Foundation

/// Bridged `NS_ERROR_ENUM` for Message Filter network-deferral failures.
///
/// `Code` raw values match pinned `dotnet/macios` `[Native]`:
/// `system = 1`, then sequential through `redundantNetworkDeferral = 5`.
/// There is no case with raw value `0`.
public struct ILMessageFilterError: Error, Hashable {
    public enum Code: Int, Hashable, Sendable {
        case system = 1
        case invalidNetworkURL = 2
        case networkURLUnauthorized = 3
        case networkRequestFailed = 4
        case redundantNetworkDeferral = 5

        public static func ~= (match: ILMessageFilterError.Code, error: any Error) -> Bool {
            (error as? ILMessageFilterError)?.code == match
        }
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public var errorCode: Int { code.rawValue }

    public var errorUserInfo: [String: Any] { userInfo }

    public static var errorDomain: String { ILMessageFilterErrorDomain }

    public var localizedDescription: String {
        if let description = userInfo[NSLocalizedDescriptionKey] as? String {
            return description
        }
        return "ILMessageFilterError.\(code) (\(code.rawValue))"
    }

    public static var system: Code { .system }
    public static var invalidNetworkURL: Code { .invalidNetworkURL }
    public static var networkURLUnauthorized: Code { .networkURLUnauthorized }
    public static var networkRequestFailed: Code { .networkRequestFailed }
    public static var redundantNetworkDeferral: Code { .redundantNetworkDeferral }

    public static func == (lhs: ILMessageFilterError, rhs: ILMessageFilterError) -> Bool {
        lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
