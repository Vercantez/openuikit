@_exported import Foundation

/// Linux-local fail-closed error used when SharePlay, nearby presence,
/// journals, or messengers would require Apple daemons or entitlements.
///
/// This is not an Apple SDK type. Numeric codes are host discriminators, not
/// observed `NSError` values. See `oracle-questions.tsv`.
public struct GroupActivitiesHostError: Error, Hashable, Sendable,
    LocalizedError, CustomNSError
{
    public static var errorDomain: String {
        "GroupActivities.GroupActivitiesHostError"
    }

    public let code: Int

    public var errorCode: Int { code }

    public var errorUserInfo: [String: Any] { [:] }

    public var errorDescription: String? { failureReason }

    public var failureReason: String? {
        switch code {
        case 1: return "SharePlay is unavailable on this Linux host."
        case 2: return "The local participant left the host session."
        case 3: return "The group session ended for every participant."
        case 4: return "Nearby participant detection requires Apple wireless services."
        case 5: return "Group session journals require Apple's transfer service."
        case 6: return "Group session messaging requires Apple's SharePlay daemon."
        default: return "GroupActivities host error \(code)."
        }
    }

    public static let sharePlayUnavailable = GroupActivitiesHostError(code: 1)
    public static let sessionLeft = GroupActivitiesHostError(code: 2)
    public static let sessionEnded = GroupActivitiesHostError(code: 3)
    public static let nearbyUnavailable = GroupActivitiesHostError(code: 4)
    public static let journalUnavailable = GroupActivitiesHostError(code: 5)
    public static let messengerUnavailable = GroupActivitiesHostError(code: 6)

    public init(code: Int) {
        self.code = code
    }
}

/// Result of asking the system whether an activity should start.
public enum GroupActivityActivationResult: Hashable, Sendable {
    case activationDisabled
    case activationPreferred
    case cancelled
}

/// A type that can be started as a SharePlay group activity.
///
/// Linux never contacts FaceTime, Messages, or the SharePlay daemon.
/// `prepareForActivation()` returns `.activationDisabled` and `activate()`
/// throws ``GroupActivitiesHostError/sharePlayUnavailable``.
public protocol GroupActivity: Decodable, Encodable {
    static var activityIdentifier: String { get }
    var metadata: GroupActivityMetadata { get async }
}

extension GroupActivity {
    /// Default identifier: bundle identifier plus the conforming type name.
    /// Apple's exact concatenation is an oracle question.
    public static var activityIdentifier: String {
        let bundle = Bundle.main.bundleIdentifier ?? "unknown"
        return "\(bundle).\(String(describing: Self.self))"
    }

    public typealias Sessions = GroupSession<Self>.Sessions

    /// Linux has no SharePlay eligibility UI. The host refuses activation.
    public func prepareForActivation() async -> GroupActivityActivationResult {
        .activationDisabled
    }

    /// Linux never starts a system group activity.
    public func activate() async throws -> Bool {
        throw GroupActivitiesHostError.sharePlayUnavailable
    }

    /// Linux never receives system-created sessions. The sequence completes empty.
    public static func sessions() -> Sessions {
        GroupSession<Self>.Sessions()
    }
}

/// Identifies a Codable message type independently of its Swift type name.
public protocol CustomMessageIdentifiable {
    static var messageIdentifier: String { get }
}
