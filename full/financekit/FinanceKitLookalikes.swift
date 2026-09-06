import Foundation

// Isolated-host stand-ins for ExtensionFoundation types referenced by
// BackgroundDeliveryExtension. These are not Darwin types and are compiled
// out when ExtensionFoundation is on the import path.

#if !canImport(ExtensionFoundation)
public protocol AppExtensionConfiguration {}

public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}
#endif
