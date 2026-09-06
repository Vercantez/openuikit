@_exported import Foundation

/// Linux starting point for Apple's public `SystemExtensions` module.
///
/// The iPhoneOS 26.1 surface is the error overlay, Info.plist usage-description
/// keys, `OSSystemExtensionProperties`, and `OSSystemExtensionsWorkspace`.
/// Value types, error codes, and local property storage are real. There is no
/// `sysextd`, DriverKit, Network Extension system-extension, or Endpoint
/// Security daemon on Linux: workspace queries fail closed. See `README.md`.
enum SystemExtensionsModuleMarker {
    static let name = "SystemExtensions"
}

/// Info.plist key whose value tells the user why an app is installing a
/// system extension. Linux uses the documented plist name; Darwin's loaded
/// string payload is an oracle question.
public let NSSystemExtensionUsageDescriptionKey = "NSSystemExtensionUsageDescription"

/// Info.plist key whose value tells the user why an app is installing a
/// DriverKit extension. Linux uses the documented plist name; Darwin's loaded
/// string payload is an oracle question.
public let OSBundleUsageDescriptionKey = "OSBundleUsageDescription"

/// Public System Extensions error domain. Linux uses the identifier token
/// observed in Darwin `NSError` printouts (`Error Domain=OSSystemExtensionErrorDomain`).
public let OSSystemExtensionErrorDomain = "OSSystemExtensionErrorDomain"

/// Linux host-test control. Hidden from ordinary `import SystemExtensions`
/// clients and not part of Apple's public surface.
@_spi(OpenUIKitHost)
public enum SystemExtensionsHostControl {
    /// Snapshot of extension properties. Not a live `sysextd` inventory.
    public static func makeProperties(
        bundleIdentifier: String,
        bundleVersion: String,
        bundleShortVersion: String,
        isEnabled: Bool
    ) -> OSSystemExtensionProperties {
        OSSystemExtensionProperties(
            bundleIdentifier: bundleIdentifier,
            bundleVersion: bundleVersion,
            bundleShortVersion: bundleShortVersion,
            isEnabled: isEnabled
        )
    }

    /// Error thrown by every Linux workspace query.
    public static var workspaceQueryError: OSSystemExtensionError {
        OSSystemExtensionError(.unknown)
    }
}
