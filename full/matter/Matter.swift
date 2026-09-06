@_exported import Foundation

/// Linux starting point for Apple's public Matter module.
/// Isolated host compilation produces `libMatter.dylib`.
///
/// Value types, enumerations, setup-payload parsing, TLV data-value
/// dictionaries, and an in-memory object graph are real. Matter fabrics,
/// commissioning over BLE/IP, certificates that need Security.SecKey, and
/// XPC controller daemons fail closed with `MTRError`.
public enum MatterModuleMarker {
    public static let linuxStartingPoint = true
}
