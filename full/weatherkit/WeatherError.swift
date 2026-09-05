import Foundation

/// Typed WeatherKit failure. Apple documents two cases; Linux uses `.unknown`
/// for the missing weather daemon / entitlement / network boundary.
public enum WeatherError: Error, Equatable, Hashable, Sendable, LocalizedError {
    case permissionDenied
    case unknown

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "This app is not permitted to use WeatherKit."
        case .unknown:
            return WeatherKitHost.unsupportedDescription
        }
    }

    public var failureReason: String? {
        switch self {
        case .permissionDenied:
            return "WeatherKit entitlement or user permission is missing."
        case .unknown:
            return "No Apple weather service is available."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Enable the WeatherKit capability and retry on an Apple platform."
        case .unknown:
            return "Retry on a host with Apple WeatherKit services."
        }
    }

    public var helpAnchor: String? { nil }

    public var localizedDescription: String {
        errorDescription ?? WeatherKitHost.unsupportedDescription
    }
}
