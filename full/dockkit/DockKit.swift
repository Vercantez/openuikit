import Foundation

// Linux starting point for Apple's DockKit. Tracking stands, motor
// orientation, camera-frame tracking, and TCC camera access are
// fail-closed: Linux has no DockKit daemon, dock accessory, or camera
// entitlement prompt. Value types, enum identity, Codable round trips,
// limit validation, and explicit DockKitError cases are implemented and
// tested here.

/// Dock accessory errors. Case order matches the Xcode 26.1 API digester.
///
/// This is a Swift `Error` enum, not an `NS_ERROR_ENUM`. Public inputs do
/// not record integer raw values, so this port does not invent them.
public enum DockKitError: Error, LocalizedError, Equatable, Hashable, Sendable {
    case notSupported
    case notConnected
    case notSupportedByDevice
    case invalidParameter
    case noSubjectFound
    case frameRateTooLow
    case cameraTCCMissing
    case frameRateTooHigh

    public var errorDescription: String? {
        switch self {
        case .notSupported:
            return "DockKit is not supported on this platform."
        case .notConnected:
            return "No dock accessory is connected."
        case .notSupportedByDevice:
            return "The connected accessory does not support this operation."
        case .invalidParameter:
            return "A DockKit parameter is invalid."
        case .noSubjectFound:
            return "No trackable subject was found."
        case .frameRateTooLow:
            return "The camera frame rate is too low for DockKit tracking."
        case .cameraTCCMissing:
            return "Camera access has not been granted for DockKit."
        case .frameRateTooHigh:
            return "The camera frame rate is too high for DockKit tracking."
        }
    }
}

func dockKitUnsupported() -> DockKitError {
    .notSupported
}

func dockKitInvalidParameter() -> DockKitError {
    .invalidParameter
}
