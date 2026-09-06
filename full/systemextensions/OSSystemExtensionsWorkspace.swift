import Foundation

/// Queries system extensions associated with an application.
///
/// `shared` is a stable process-local singleton. Linux has no `sysextd`,
/// so `systemExtensions(forApplicationWithBundleID:)` always throws
/// `OSSystemExtensionError.unknown` and never returns a successful set.
open class OSSystemExtensionsWorkspace: NSObject {
    private static let sharedInstance = OSSystemExtensionsWorkspace()

    /// The shared workspace. Identity is stable for the process.
    open class var shared: OSSystemExtensionsWorkspace { sharedInstance }

    public override init() {
        super.init()
    }

    /// Returns system extensions for `bundleID`.
    ///
    /// Linux always throws `OSSystemExtensionError(.unknown)`. An empty
    /// identifier is not treated as a successful empty inventory. Darwin's
    /// exact code for a missing daemon vs an unknown bundle is unobserved.
    open func systemExtensions(
        forApplicationWithBundleID bundleID: String
    ) throws -> Set<OSSystemExtensionProperties> {
        _ = bundleID
        throw OSSystemExtensionError(.unknown)
    }
}
