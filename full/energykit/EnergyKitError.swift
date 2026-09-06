import Foundation

/// Errors thrown by EnergyKit on this Linux host. Case order matches the
/// Xcode 26.1 API digester. Exact Apple `errorDescription` copy, help
/// anchors, and recovery strings are unobserved.
public enum EnergyKitError: Error, LocalizedError, Equatable, Hashable, Sendable {
    case guidanceUnavailable
    case inProgress
    case invalidLoadEvent
    case locationServicesDenied
    case permissionDenied
    case rateLimitExceeded
    case serviceUnavailable
    case unsupportedRegion
    case venueUnavailable

    public var errorDescription: String? {
        switch self {
        case .guidanceUnavailable:
            return "Electricity guidance is unavailable on this host."
        case .inProgress:
            return "An EnergyKit operation is already in progress."
        case .invalidLoadEvent:
            return "The electrical load event is invalid."
        case .locationServicesDenied:
            return "Location services are denied; EnergyKit cannot match a home."
        case .permissionDenied:
            return "EnergyKit permission was denied."
        case .rateLimitExceeded:
            return "The EnergyKit request exceeded the allowed rate."
        case .serviceUnavailable:
            return "The EnergyKit service is unavailable on this host."
        case .unsupportedRegion:
            return "EnergyKit is not available in this region on this host."
        case .venueUnavailable:
            return "The requested energy venue is unavailable."
        }
    }

    public var failureReason: String? {
        switch self {
        case .guidanceUnavailable:
            return "This Linux host has no Apple electricity-guidance daemon."
        case .inProgress:
            return "A previous EnergyKit request has not completed."
        case .invalidLoadEvent:
            return "The load event failed EnergyKit validation."
        case .locationServicesDenied:
            return "Home matching requires location/home identity that this host does not provide."
        case .permissionDenied:
            return "The process is not entitled to EnergyKit on this host."
        case .rateLimitExceeded:
            return "EnergyKit refused the request because a rate limit was exceeded."
        case .serviceUnavailable:
            return "There is no Apple EnergyKit service on this Linux host."
        case .unsupportedRegion:
            return "The host region is not an EnergyKit region."
        case .venueUnavailable:
            return "No energy venue exists for the supplied identifier on this host."
        }
    }

    public var helpAnchor: String? {
        nil
    }

    public var recoverySuggestion: String? {
        switch self {
        case .guidanceUnavailable, .serviceUnavailable, .venueUnavailable, .unsupportedRegion:
            return "EnergyKit service APIs fail closed on Linux until an Apple oracle observes a live device."
        case .invalidLoadEvent:
            return "Submit a well-formed HVAC or vehicle load event with a nonempty device identifier."
        case .locationServicesDenied:
            return "Home-unique venue lookup cannot succeed without Apple location/home services."
        case .permissionDenied:
            return "Do not invent a successful authorization prompt on this host."
        case .inProgress, .rateLimitExceeded:
            return "Retry only after observing Apple's timing; this host does not simulate those conditions."
        }
    }
}
