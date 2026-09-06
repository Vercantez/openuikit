// The Linux guest has no haptic hardware; callers take their audio fallback.
public struct CHHapticDeviceCapability { public let supportsHaptics = false }
public enum CHHapticEngine {
    public static func capabilitiesForHardware() -> CHHapticDeviceCapability { .init() }
}
