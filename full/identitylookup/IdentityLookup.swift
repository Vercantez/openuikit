@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Portable Linux starting point for Apple's public `IdentityLookup` module.
///
/// Isolated host compilation imports Foundation only. Value types, exact
/// error codes, and in-process classification/filter state are real. Message
/// Filter extensions, SMS/Call classification hosts, Live Caller ID PIR,
/// Settings, and Apple network deferral never report success.

/// Apple's `NS_ERROR_ENUM` domain for `ILMessageFilterError`. The string matches
/// the pinned `dotnet/macios` `[ErrorDomain ("ILMessageFilterErrorDomain")]`
/// annotation and the TBD export `_ILMessageFilterErrorDomain`.
public let ILMessageFilterErrorDomain = "ILMessageFilterErrorDomain"

/// Unobserved Darwin Live Caller ID / classification extension-point
/// identifier. Linux keeps the empty string until an Apple-oracle probe
/// records the exact value; see `oracle-questions.tsv`.
public let extensionPointName: String = ""

enum IdentityLookupLinux {
    static func filterError(
        _ code: ILMessageFilterError.Code,
        userInfo: [String: Any] = [:]
    ) -> ILMessageFilterError {
        var info = userInfo
        if info[NSLocalizedDescriptionKey] == nil {
            info[NSLocalizedDescriptionKey] =
                "Linux has no IdentityLookup extension host or Apple messaging service (\(code))."
        }
        return ILMessageFilterError(code, userInfo: info)
    }

    static func encodeString(_ value: String?, _ coder: NSCoder, key: String) {
        if let value {
            coder.encode(value as NSString, forKey: key)
        }
    }

    static func decodeString(_ coder: NSCoder, key: String) -> String? {
        coder.decodeObject(of: NSString.self, forKey: key) as String?
    }

    static func encodeDate(_ value: Date, _ coder: NSCoder, key: String) {
        coder.encode(NSNumber(value: value.timeIntervalSince1970), forKey: key)
    }

    static func decodeDate(_ coder: NSCoder, key: String) -> Date? {
        guard let number = coder.decodeObject(of: NSNumber.self, forKey: key) else {
            return nil
        }
        return Date(timeIntervalSince1970: number.doubleValue)
    }

    static func encodeInt(_ value: Int, _ coder: NSCoder, key: String) {
        coder.encode(NSNumber(value: value), forKey: key)
    }

    static func decodeInt(_ coder: NSCoder, key: String) -> Int? {
        coder.decodeObject(of: NSNumber.self, forKey: key)?.intValue
    }
}

/// User-facing classification action for reporting a communication.
///
/// Raw values match pinned `dotnet/macios` `[Native]` order.
public enum ILClassificationAction: Int, Hashable, Sendable {
    case none = 0
    case reportNotJunk = 1
    case reportJunk = 2
    case reportJunkAndBlockSender = 3
}

/// Action returned by an SMS/MMS Message Filter extension.
///
/// Raw values match pinned `dotnet/macios` `[Native]` order. The historical
/// ObjC case `ILMessageFilterActionFilter` is the Swift overlay
/// `static var filter`, aliased to `.junk`.
public enum ILMessageFilterAction: Int, Hashable, Sendable {
    case none = 0
    case allow = 1
    case junk = 2
    case promotion = 3
    case transaction = 4

    /// Deprecated ObjC `ILMessageFilterActionFilter` overlay. Same raw value
    /// as `.junk` (macios `Junk = 2`).
    public static var filter: ILMessageFilterAction { .junk }
}

/// Fine-grained filter sub-action for capabilities and query responses.
///
/// Raw values match pinned `dotnet/macios` `[Native]` constants: `none = 0`,
/// transactional family `10000...10008`, promotional family `20000...20002`.
public enum ILMessageFilterSubAction: Int, Hashable, Sendable {
    case none = 0
    case transactionalOthers = 10000
    case transactionalFinance = 10001
    case transactionalOrders = 10002
    case transactionalReminders = 10003
    case transactionalHealth = 10004
    case transactionalWeather = 10005
    case transactionalCarrier = 10006
    case transactionalRewards = 10007
    case transactionalPublicServices = 10008
    case promotionalOthers = 20000
    case promotionalOffers = 20001
    case promotionalCoupons = 20002
}

/// Enablement of a Live Caller ID lookup extension on this device.
///
/// Linux has no Call Directory / Live Caller ID daemon, so
/// `LiveCallerIDLookupManager.status(forExtensionWithIdentifier:)` is always
/// `.disabled`.
public enum CallLookupExtensionStatus: Hashable, Sendable {
    case enabled
    case disabled
}
