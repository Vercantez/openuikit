import Foundation

/// Linux `FinanceError`. Exact Apple `errorCode` integers and localized
/// strings are unobserved; discriminators follow digester case order.
public enum FinanceError: Error, Equatable, Sendable {
    case dataRestricted(FinanceStore.DataType)
    case unknown
    case historyTokenInvalid
}

extension FinanceError: CustomNSError {
    public static var errorDomain: String { "FinanceKit.FinanceError" }

    public var errorCode: Int {
        switch self {
        case .dataRestricted: return 0
        case .unknown: return 1
        case .historyTokenInvalid: return 2
        }
    }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [:]
        if let description = errorDescription {
            info[NSLocalizedDescriptionKey] = description
        }
        if let reason = failureReason {
            info[NSLocalizedFailureReasonErrorKey] = reason
        }
        switch self {
        case .dataRestricted(let type):
            info["FinanceStoreDataType"] = String(describing: type)
        case .unknown, .historyTokenInvalid:
            break
        }
        return info
    }
}

extension FinanceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .dataRestricted(let type):
            return "FinanceStore data of type \(String(describing: type)) is restricted on this host."
        case .unknown:
            return "An unknown FinanceKit error occurred."
        case .historyTokenInvalid:
            return "The FinanceStore history token is invalid."
        }
    }

    public var failureReason: String? {
        switch self {
        case .dataRestricted:
            return "This Linux host has no Apple finance data source."
        case .unknown:
            return "The FinanceKit operation failed for an unspecified reason."
        case .historyTokenInvalid:
            return "The supplied HistoryToken was not issued by this store."
        }
    }
}
