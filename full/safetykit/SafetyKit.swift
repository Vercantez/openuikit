@_exported import Foundation

/// Linux starting point for Apple's public `SafetyKit` module (iOS 16+ Crash
/// Detection and Emergency Response). Isolated-host success is not Apple
/// crash-detection, telephony, or entitlement success.
///
/// Hardware sensors, SafetyKit daemons, and the Crash Detection entitlement
/// are absent on Linux. Availability is `false` and mutating operations
/// fail closed with `SAError`.
public enum SafetyKitLinuxBoundary {
    /// Crash Detection is an Apple-hardware and entitlement feature.
    public static let crashDetectionAvailable = false
}