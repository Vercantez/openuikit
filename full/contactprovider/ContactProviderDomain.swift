import Foundation

/// A domain, including traits like an identifier and display name, used to
/// configure the extension.
public protocol ContactProviderDomain {
    /// The identifier of the domain.
    var identifier: String { get }

    /// The display name the system shows to represent this domain.
    var displayName: String { get }

    /// Custom values used to configure the extension before enumeration begins.
    var userInfo: Dictionary<String, Any> { get }
}

/// The default domain the extension uses.
///
/// Darwin's static identifier string is unobserved. Linux uses the type name
/// as a stable sentinel. `displayName` follows the documented rule of using
/// the app's bundle display name, falling back to the process name.
public struct DefaultContactProviderDomain: ContactProviderDomain {
    /// The identifier used for all default domains.
    public static let identifier = ContactProviderLinux.defaultDomainIdentifier

    /// The identifier of the domain.
    public var identifier: String { Self.identifier }

    /// The display name the system shows to represent the default domain.
    ///
    /// The default domain uses the app's bundle display name.
    public let displayName: String

    /// Custom values used to configure the extension before enumeration begins.
    public let userInfo: Dictionary<String, Any>

    /// Creates an instance of the default domain.
    public init() {
        self.displayName = ContactProviderLinux.bundleDisplayName()
        self.userInfo = [:]
    }
}
