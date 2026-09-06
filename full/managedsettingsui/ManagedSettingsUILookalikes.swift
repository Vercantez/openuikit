@_exported import Foundation

// Isolated-host stand-ins for ManagedSettings and UIKit types named by the
// public ManagedSettingsUI surface. The sealed host gate compiles this module
// alone. When a real `ManagedSettings` / `UIKit` module is on the link line,
// these blocks compile out. They are not a Linux ManagedSettings or UIKit
// port and must not be cited as proof of those identities.

#if !canImport(ManagedSettings)

/// A representation of an activity, such as an app or website, that doesn't
/// reveal its identity.
///
/// Matches the Linux `ManagedSettings.Token` contract: the only public
/// initializer is `init(from:)`. Round-trips a keyed `linuxOpaqueID` UUID
/// and fail-closes on any other decoder payload.
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

public typealias ApplicationToken = Token<Application>
public typealias ActivityCategoryToken = Token<ActivityCategory>
public typealias WebDomainToken = Token<WebDomain>

/// A representation of an application on the user's device.
public struct Application: Equatable, Hashable {
    public let bundleIdentifier: String?
    public let token: ApplicationToken?
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
}

/// An object that represents a website.
public struct WebDomain: Equatable, Hashable {
    public let domain: String?
    public let token: WebDomainToken?

    public init(domain: String) {
        self.domain = domain
        self.token = nil
    }

    public init(token: WebDomainToken) {
        self.domain = nil
        self.token = token
    }
}

/// An activity's category, such as Entertainment or Social.
public struct ActivityCategory: Equatable, Hashable {
    public let token: ActivityCategoryToken?
    public let localizedDisplayName: String?

    public init(token: ActivityCategoryToken) {
        self.token = token
        self.localizedDisplayName = nil
    }
}

#endif

#if !canImport(UIKit)

/// Isolated-host `UIColor`. Component values follow Apple's
/// `init(red:green:blue:alpha:)` unit interval. Named colors are
/// identity-stable process singletons.
open class UIColor: NSObject, @unchecked Sendable {
    public let redComponent: CGFloat
    public let greenComponent: CGFloat
    public let blueComponent: CGFloat
    public let alphaComponent: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        redComponent = red
        greenComponent = green
        blueComponent = blue
        alphaComponent = alpha
        super.init()
    }

    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        return redComponent == other.redComponent
            && greenComponent == other.greenComponent
            && blueComponent == other.blueComponent
            && alphaComponent == other.alphaComponent
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(Double(redComponent))
        hasher.combine(Double(greenComponent))
        hasher.combine(Double(blueComponent))
        hasher.combine(Double(alphaComponent))
        return hasher.finalize()
    }
}

/// Isolated-host `UIImage`. Linux never decodes image bytes.
open class UIImage: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

/// Isolated-host `UIBlurEffect`. Raw `Style` values match UIKit's
/// `UIBlurEffectStyle` C enum (`regular = 4`, `prominent = 5`).
open class UIBlurEffect: NSObject, @unchecked Sendable {
    public enum Style: Int, Equatable, Hashable, Sendable {
        case extraLight = 0
        case light = 1
        case dark = 2
        case regular = 4
        case prominent = 5
        case systemUltraThinMaterial = 6
        case systemThinMaterial = 7
        case systemMaterial = 8
        case systemThickMaterial = 9
        case systemChromeMaterial = 10
        case systemUltraThinMaterialLight = 11
        case systemThinMaterialLight = 12
        case systemMaterialLight = 13
        case systemThickMaterialLight = 14
        case systemChromeMaterialLight = 15
        case systemUltraThinMaterialDark = 16
        case systemThinMaterialDark = 17
        case systemMaterialDark = 18
        case systemThickMaterialDark = 19
        case systemChromeMaterialDark = 20
    }

    public override init() {
        super.init()
    }
}

#endif
