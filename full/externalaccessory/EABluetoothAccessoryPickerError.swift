import Foundation

/// Bridged Bluetooth accessory picker error.
///
/// Raw values are the sequential `NSInteger` codes recorded by the pinned
/// dotnet-macios `EABluetoothAccessoryPickerError` enum (`AlreadyConnected`
/// through `Failed`) and the API-digester child order:
/// `alreadyConnected = 0`, `resultNotFound = 1`, `resultCancelled = 2`,
/// `resultFailed = 3`.
public struct EABluetoothAccessoryPickerError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case alreadyConnected = 0
        case resultNotFound = 1
        case resultCancelled = 2
        case resultFailed = 3
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { EABluetoothAccessoryPickerErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static let alreadyConnected = Code.alreadyConnected
    public static let resultNotFound = Code.resultNotFound
    public static let resultCancelled = Code.resultCancelled
    public static let resultFailed = Code.resultFailed

    public static func == (
        lhs: EABluetoothAccessoryPickerError,
        rhs: EABluetoothAccessoryPickerError
    ) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

extension EABluetoothAccessoryPickerError.Code {
    public static func ~= (match: EABluetoothAccessoryPickerError.Code, error: any Error) -> Bool {
        if let typed = error as? EABluetoothAccessoryPickerError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == EABluetoothAccessoryPickerErrorDomain
            && nsError.code == match.rawValue
    }
}
