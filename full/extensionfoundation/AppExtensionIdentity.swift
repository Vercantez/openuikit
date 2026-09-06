import Foundation

/// A type that uniquely identifies an app extension on the system.
///
/// Darwin clients do not construct this type; they receive it from
/// `AppExtensionPoint.Monitor`. Linux never discovers appexes, so the public
/// surface stays constructible only through host SPI for tests.
public struct AppExtensionIdentity: Hashable, Identifiable, Sendable {
    public typealias ID = String

    /// The bundle identifier of the app extension.
    public let bundleIdentifier: String
    /// The host extension point this identity claims to support.
    public let extensionPointIdentifier: String
    /// The localized, human-readable name of the app extension.
    public let localizedName: String

    public var id: String {
        "\(bundleIdentifier)|\(extensionPointIdentifier)"
    }

    @_spi(OpenUIKitHost)
    public init(
        bundleIdentifier: String,
        extensionPointIdentifier: String,
        localizedName: String
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.extensionPointIdentifier = extensionPointIdentifier
        self.localizedName = localizedName
    }

    public static func == (lhs: AppExtensionIdentity, rhs: AppExtensionIdentity) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
            && lhs.extensionPointIdentifier == rhs.extensionPointIdentifier
            && lhs.localizedName == rhs.localizedName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
        hasher.combine(extensionPointIdentifier)
        hasher.combine(localizedName)
    }
}
