@_exported import Foundation

/// Linux starting point for Apple's public HomeKit module.
/// Isolated host compilation produces `libHomeKit.dylib`.
///
/// Value types, HAP characteristic-value enumerations, string constants, and
/// an in-memory object graph are real. Apple Home, home hubs, accessory
/// pairing, HAP sessions, camera RTP, Matter, and entitlement-gated setup
/// fail closed with `HMError`.
public enum HomeKitModuleMarker {
    public static let linuxStartingPoint = true
}
