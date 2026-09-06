import Foundation

public let AXFeatureOverrideSessionErrorDomain = "AXFeatureOverrideSessionErrorDomain"

/// Bridged `NS_ERROR_ENUM` for feature-override sessions.
///
/// Raw values follow the pinned dotnet-macios `AXFeatureOverrideSessionError`
/// (`Undefined = 0` through `OverrideNotFoundForUUID = 3`) and the API-digester
/// child order.
@frozen
public struct AXFeatureOverrideSessionError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = AXFeatureOverrideSessionError

        case undefined = 0
        case appNotEntitled = 1
        case overrideIsAlreadyActive = 2
        case overrideNotFoundForUUID = 3
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { AXFeatureOverrideSessionErrorDomain }

    public static var errorDomain: String { AXFeatureOverrideSessionErrorDomain }

    public static var undefined: Code { .undefined }
    public static var appNotEntitled: Code { .appNotEntitled }
    public static var overrideIsAlreadyActive: Code { .overrideIsAlreadyActive }
    public static var overrideNotFoundForUUID: Code { .overrideNotFoundForUUID }

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

extension AXFeatureOverrideSessionError.Code {
    public static func ~= (match: AXFeatureOverrideSessionError.Code, error: any Error) -> Bool {
        if let typed = error as? AXFeatureOverrideSessionError {
            return typed.code == match
        }
        let nsError = error as NSError
        return nsError.domain == AXFeatureOverrideSessionErrorDomain
            && nsError.code == match.rawValue
    }
}
