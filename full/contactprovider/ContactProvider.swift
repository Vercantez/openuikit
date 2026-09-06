@_exported import Foundation

/// Portable Linux starting point for Apple's public `ContactProvider` module.
///
/// Isolated host compilation imports Foundation only. Value types, error
/// discriminators, observer callbacks, and process-local manager state are
/// real. Contact Provider extensions, `contactsd`, Settings enablement UI,
/// and the system Contacts database never report success.
///
/// `Contacts.CNMutableContact` and `ExtensionFoundation.AppExtension` are
/// isolation stand-ins when those modules are absent. They are not Linux
/// ports of those frameworks and compile out when the real modules are on
/// the import path.

enum ContactProviderLinux {
    static let rootContainerValue = "rootContainer"
    static let defaultDomainIdentifier = "DefaultContactProviderDomain"
    static let errorDomain = "ContactProvider.ContactProviderError"

    static func bundleDisplayName() -> String {
        if let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !display.isEmpty {
            return display
        }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !name.isEmpty {
            return name
        }
        return ProcessInfo.processInfo.processName
    }
}
