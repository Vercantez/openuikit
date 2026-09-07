import Foundation

#if canImport(Combine)
import Combine
#endif

/// Screen Time / Family Controls authorization errors.
///
/// Raw values follow the api-digester declaration order for this Int overlay
/// (0...7). Apple's NSError domain and localized strings are unobserved; the
/// Linux `CustomNSError` witnesses are local. See `oracle-questions.tsv`.
public enum FamilyControlsError: Int, Error, Hashable, Sendable,
    LocalizedError, CustomNSError
{
    case restricted = 0
    case unavailable = 1
    case invalidAccountType = 2
    case invalidArgument = 3
    case authorizationConflict = 4
    case authorizationCanceled = 5
    case networkError = 6
    case authenticationMethodUnavailable = 7

    public static var errorDomain: String {
        "FamilyControls.FamilyControlsError"
    }

    public var errorCode: Int { rawValue }

    public var errorDescription: String? {
        switch self {
        case .restricted:
            return "FamilyControlsError.restricted"
        case .unavailable:
            return "FamilyControlsError.unavailable"
        case .invalidAccountType:
            return "FamilyControlsError.invalidAccountType"
        case .invalidArgument:
            return "FamilyControlsError.invalidArgument"
        case .authorizationConflict:
            return "FamilyControlsError.authorizationConflict"
        case .authorizationCanceled:
            return "FamilyControlsError.authorizationCanceled"
        case .networkError:
            return "FamilyControlsError.networkError"
        case .authenticationMethodUnavailable:
            return "FamilyControlsError.authenticationMethodUnavailable"
        }
    }

    public var failureReason: String? { nil }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [:]
        if let errorDescription {
            info[NSLocalizedDescriptionKey] = errorDescription
        }
        return info
    }
}

/// Family Sharing member for whom an app requests FamilyControls.
///
/// `@objc` overlay identity is `FamilyControlsMember`. Raw values follow
/// api-digester order: `child = 0`, `individual = 1`. Linux has no ObjC
/// runtime overlay; this is a Swift `Int` enum.
public enum FamilyControlsMember: Int, Codable, Hashable, Sendable,
    CustomStringConvertible
{
    case child = 0
    case individual = 1

    public var description: String {
        switch self {
        case .child: return "child"
        case .individual: return "individual"
        }
    }
}

/// Result of a FamilyControls authorization request.
///
/// Raw values follow api-digester order: `notDetermined = 0`, `denied = 1`,
/// `approved = 2`. Linux never reports `.approved`.
public enum AuthorizationStatus: Int, Codable, Hashable, Sendable,
    CustomStringConvertible
{
    case notDetermined = 0
    case denied = 1
    case approved = 2

    public var description: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .approved: return "approved"
        }
    }
}

/// Shared authorization object for the FamilyControls capability.
///
/// Linux has no Screen Time / Family Sharing daemon. `authorizationStatus` is
/// always `.denied`. `requestAuthorization` and `revokeAuthorization` always
/// fail with `FamilyControlsError.unavailable`. Completions run inline so
/// host tests without a run loop can observe the result; Apple's callback
/// queue is unobserved.
public final class AuthorizationCenter: ObservableObject {
    public typealias ObjectWillChangePublisher = ObservableObjectPublisher

    public static let shared = AuthorizationCenter()

    public let objectWillChange = ObservableObjectPublisher()

    @Published public private(set) var authorizationStatus: AuthorizationStatus = .denied

    private init() {}

    /// Requests FamilyControls authorization. Linux never prompts and never
    /// grants; the completion is invoked immediately with `.unavailable`.
    public func requestAuthorization(
        completionHandler: @escaping (Result<Void, any Error>) -> Void
    ) {
        completionHandler(.failure(Self.linuxAuthorizationFailure))
    }

    /// Requests FamilyControls authorization for `member`. Linux never
    /// suspends and always throws `.unavailable`.
    public func requestAuthorization(for member: FamilyControlsMember) async throws {
        try linuxRequestAuthorization(for: member)
    }

    /// Revokes FamilyControls authorization. Linux has nothing to revoke and
    /// fails closed with `.unavailable`.
    public func revokeAuthorization(
        completionHandler: @escaping (Result<Void, any Error>) -> Void
    ) {
        completionHandler(.failure(Self.linuxAuthorizationFailure))
    }

    func linuxRequestAuthorization(for member: FamilyControlsMember) throws {
        _ = member
        throw Self.linuxAuthorizationFailure
    }

    func linuxRevokeAuthorization() throws {
        throw Self.linuxAuthorizationFailure
    }

    /// A single boundary keeps every Linux authorization entry point
    /// deterministic and prevents one overload from accidentally granting.
    private static let linuxAuthorizationFailure = FamilyControlsError.unavailable
}
