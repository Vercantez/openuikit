import Foundation

// MARK: - Privacy tokens

/// A representation of an activity, such as an app or website, that doesn't
/// reveal its identity.
///
/// Apple's `Token` encoding is unobserved on this host. Linux round-trips a
/// keyed `linuxOpaqueID` UUID payload only. Any other decoder payload fails
/// closed with `DecodingError`. There is no public Apple initializer besides
/// `init(from:)`.
public struct Token<T>: Equatable, Hashable {
    let opaqueID: UUID

    public static func == (a: Token<T>, b: Token<T>) -> Bool {
        a.opaqueID == b.opaqueID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(opaqueID)
    }
}

extension Token: Codable {
    enum CodingKeys: String, CodingKey {
        case linuxOpaqueID
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.contains(.linuxOpaqueID) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "ManagedSettings.Token requires a Linux linuxOpaqueID payload; Apple Family Controls token bytes are not decoded on this host"
                )
            )
        }
        opaqueID = try container.decode(UUID.self, forKey: .linuxOpaqueID)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(opaqueID, forKey: .linuxOpaqueID)
    }
}

/// A representation of an application.
public typealias ApplicationToken = Token<Application>

/// A token that represents a category of app or website activity.
public typealias ActivityCategoryToken = Token<ActivityCategory>

/// A representation of a web domain that preserves the user's privacy.
public typealias WebDomainToken = Token<WebDomain>

// MARK: - Application

/// A representation of an application on the user's device.
public struct Application: Equatable, Hashable {
    /// The unique string that identifies this app.
    ///
    /// In a ManagedSettingsUI shield-configuration extension this is the app's
    /// bundle identifier. This Linux host is never that extension, so
    /// token-constructed instances keep `nil`. Instances constructed with
    /// `init(bundleIdentifier:)` retain the caller-supplied string.
    public let bundleIdentifier: String?

    /// An opaque representation of a specific application.
    public let token: ApplicationToken?

    /// A localized display name for the application.
    ///
    /// Documented as `nil` outside a shield-configuration extension. Linux
    /// never populates this field.
    public let localizedDisplayName: String?

    public init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
        self.token = nil
        self.localizedDisplayName = nil
    }

    public init(token: ApplicationToken) {
        self.bundleIdentifier = nil
        self.token = token
        self.localizedDisplayName = nil
    }

    public static func == (a: Application, b: Application) -> Bool {
        a.bundleIdentifier == b.bundleIdentifier
            && a.token == b.token
            && a.localizedDisplayName == b.localizedDisplayName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
        hasher.combine(token)
        hasher.combine(localizedDisplayName)
    }
}

// MARK: - Web domain

/// An object that represents a website.
public struct WebDomain: Equatable, Hashable {
    /// A string that identifies a specific web domain.
    ///
    /// Documented as `nil` outside a shield-configuration extension for
    /// system-provided instances. `init(domain:)` retains the caller-supplied
    /// string on this host.
    public let domain: String?

    /// An opaque representation of a specific web domain.
    public let token: WebDomainToken?

    public init(domain: String) {
        self.domain = domain
        self.token = nil
    }

    public init(token: WebDomainToken) {
        self.domain = nil
        self.token = token
    }

    public static func == (a: WebDomain, b: WebDomain) -> Bool {
        a.domain == b.domain && a.token == b.token
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(domain)
        hasher.combine(token)
    }
}

// MARK: - Activity category

/// An activity's category, such as Entertainment or Social.
public struct ActivityCategory: Equatable, Hashable {
    /// An opaque representation of a category of activities.
    public let token: ActivityCategoryToken?

    /// A localized display name for the category.
    ///
    /// Documented as `nil` outside a shield-configuration extension. Linux
    /// never populates this field.
    public let localizedDisplayName: String?

    public init(token: ActivityCategoryToken) {
        self.token = token
        self.localizedDisplayName = nil
    }

    public static func == (a: ActivityCategory, b: ActivityCategory) -> Bool {
        a.token == b.token && a.localizedDisplayName == b.localizedDisplayName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(localizedDisplayName)
    }
}
