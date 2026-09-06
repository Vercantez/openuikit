import Foundation

/// Snapshot of a system extension's bundle identity and enabled state.
///
/// Apple publishes no public designated initializer; clients obtain instances
/// from `OSSystemExtensionsWorkspace`. The default `NSObject` initializer
/// stores empty strings and `isEnabled == false`. Host tests construct
/// populated snapshots via `SystemExtensionsHostControl`. Neither path is a
/// live inventory from `sysextd`.
open class OSSystemExtensionProperties: NSObject {
    private let storedBundleIdentifier: String
    private let storedBundleVersion: String
    private let storedBundleShortVersion: String
    private let storedIsEnabled: Bool

    /// The extension's bundle identifier.
    open var bundleIdentifier: String { storedBundleIdentifier }

    /// The extension's `CFBundleVersion` string.
    open var bundleVersion: String { storedBundleVersion }

    /// The extension's `CFBundleShortVersionString`.
    open var bundleShortVersion: String { storedBundleShortVersion }

    /// Whether the extension is enabled.
    ///
    /// Default-constructed snapshots report `false`. Linux never enables a
    /// system extension.
    open var isEnabled: Bool { storedIsEnabled }

    public override init() {
        storedBundleIdentifier = ""
        storedBundleVersion = ""
        storedBundleShortVersion = ""
        storedIsEnabled = false
        super.init()
    }

    init(
        bundleIdentifier: String,
        bundleVersion: String,
        bundleShortVersion: String,
        isEnabled: Bool
    ) {
        storedBundleIdentifier = bundleIdentifier
        storedBundleVersion = bundleVersion
        storedBundleShortVersion = bundleShortVersion
        storedIsEnabled = isEnabled
        super.init()
    }
}
