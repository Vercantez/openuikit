import Foundation

/// Bridged `SNErrorCode` overlay. Raw values follow the pinned
/// dotnet/macios `SNErrorCode` enumeration (`UnknownError = 1` through
/// `InvalidFile = 5`).
public struct SNError: Error, CustomNSError, Hashable, @unchecked Sendable {
    public struct Code: RawRepresentable, Hashable, Sendable {
        public var rawValue: Int

        public init?(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let unknownError = Code(rawValue: 1)!
        public static let operationFailed = Code(rawValue: 2)!
        public static let invalidFormat = Code(rawValue: 3)!
        public static let invalidModel = Code(rawValue: 4)!
        public static let invalidFile = Code(rawValue: 5)!

        public static func ~= (match: SNError.Code, error: any Error) -> Bool {
            guard let snError = error as? SNError else { return false }
            return snError.code == match
        }
    }

    public var code: Code
    public var userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { SNErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknownError: Code { .unknownError }
    public static var operationFailed: Code { .operationFailed }
    public static var invalidFormat: Code { .invalidFormat }
    public static var invalidModel: Code { .invalidModel }
    public static var invalidFile: Code { .invalidFile }

    public var localizedDescription: String {
        if let description = userInfo[NSLocalizedDescriptionKey] as? String {
            return description
        }
        return "SNError code \(code.rawValue)"
    }

    public static func == (lhs: SNError, rhs: SNError) -> Bool {
        lhs.code == rhs.code
    }

    public static func != (lhs: SNError, rhs: SNError) -> Bool {
        lhs.code != rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
