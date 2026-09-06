@_exported import Foundation

// Linux starting point for Apple's public ManagedAppDistribution module.
// Linux has no MDM client, no managed-app daemon, and no App Store
// catalog. Value types, error identities, and in-process library
// fail-closed snapshots are real. Artwork URLs, install, and catalog
// refresh never report Apple service success.

/// The supported platform for the app.
public struct Platform: Hashable, Sendable, CustomStringConvertible {
    private let name: String

    private init(name: String) {
        self.name = name
    }

    /// iOS is a supported platform.
    public static let iOS = Platform(name: "iOS")

    /// macOS is a supported platform.
    public static let macOS = Platform(name: "macOS")

    /// visionOS is a supported platform.
    public static let visionOS = Platform(name: "visionOS")

    public var description: String { name }
}

/// A representation of a managed app.
///
/// ``ManagedApp`` represents a managed app that the framework can install.
/// Use an instance of this object to obtain information about the app.
public struct ManagedApp: Hashable, Sendable, Identifiable {
    /// A type representing the stable identity of the entity associated with an instance.
    public typealias ID = String

    /// The supported platform for the app.
    public struct Platform: Hashable, Sendable, CustomStringConvertible {
        private let name: String

        private init(name: String) {
            self.name = name
        }

        /// iOS is a supported platform.
        public static let iOS = ManagedApp.Platform(name: "iOS")

        /// macOS is a supported platform.
        public static let macOS = ManagedApp.Platform(name: "macOS")

        /// visionOS is a supported platform.
        public static let visionOS = ManagedApp.Platform(name: "visionOS")

        public var description: String { name }
    }

    /// The stable identity of the entity associated with this instance.
    public var id: String { bundleIdentifier }

    /// The platform of the app.
    ///
    /// Graph / digester type is the module-level ``Platform``, not
    /// ``ManagedApp.Platform``.
    public let platform: ManagedAppDistribution.Platform

    /// The size of the app in bytes.
    public let fileSize: Measurement<UnitInformationStorage>?

    /// The language of the localized properties of this managed app.
    public let metadataLanguage: Locale.Language?

    /// The app's localized name.
    public let name: String

    /// The app's localized subtitle.
    public let subtitle: String?

    /// The app's localized seller.
    public let seller: String?

    /// The app's localized genres.
    public let genres: [String]

    /// The app's localized description.
    public let description: String?

    /// The app's supported languages.
    public let languages: [Locale.Language]

    /// The app's localized operating system compatibility requirements.
    public let requirements: String?

    /// The app's version information.
    public let version: String?

    /// The app's release date.
    public let releaseDate: Date?

    /// The app's localized developer release notes.
    public let releaseNotes: String?

    /// The app's content age rating.
    public let contentRating: String?

    /// The app's developer website URL.
    public let developerWebsite: URL?

    /// The app's privacy policy URL.
    public let privacyPolicy: URL?

    /// The app's license agreement URL.
    public var licenseAgreement: URL? { licenseAgreementStorage }

    /// The app's copyright information.
    public let copyright: String?

    private let bundleIdentifier: String
    private let licenseAgreementStorage: URL?
    private var iconBySize: [String: URL]
    private var screenshotsBySize: [String: [URL]]

    public init(
        id: String,
        name: String,
        platform: ManagedAppDistribution.Platform = .iOS,
        fileSize: Measurement<UnitInformationStorage>? = nil,
        metadataLanguage: Locale.Language? = nil,
        subtitle: String? = nil,
        seller: String? = nil,
        genres: [String] = [],
        description: String? = nil,
        languages: [Locale.Language] = [],
        requirements: String? = nil,
        version: String? = nil,
        releaseDate: Date? = nil,
        releaseNotes: String? = nil,
        contentRating: String? = nil,
        developerWebsite: URL? = nil,
        privacyPolicy: URL? = nil,
        licenseAgreement: URL? = nil,
        copyright: String? = nil
    ) {
        self.bundleIdentifier = id
        self.name = name
        self.platform = platform
        self.fileSize = fileSize
        self.metadataLanguage = metadataLanguage
        self.subtitle = subtitle
        self.seller = seller
        self.genres = genres
        self.description = description
        self.languages = languages
        self.requirements = requirements
        self.version = version
        self.releaseDate = releaseDate
        self.releaseNotes = releaseNotes
        self.contentRating = contentRating
        self.developerWebsite = developerWebsite
        self.privacyPolicy = privacyPolicy
        self.licenseAgreementStorage = licenseAgreement
        self.copyright = copyright
        self.iconBySize = [:]
        self.screenshotsBySize = [:]
    }

    /// A URL for the icon of the app.
    ///
    /// Linux has no MDM artwork CDN. Returns a host-installed URL for an
    /// exact size key, or `nil` when none was installed.
    public func iconURL(fitting size: CGSize) -> URL? {
        iconBySize[Self.sizeKey(size)]
    }

    /// An array of the app's screenshot URLs.
    ///
    /// Linux has no MDM artwork CDN. Returns host-installed URLs for an
    /// exact size key, or `[]` when none were installed.
    public func screenshotURLs(fitting size: CGSize) -> [URL] {
        screenshotsBySize[Self.sizeKey(size)] ?? []
    }

    @_spi(OpenUIKitHost)
    public mutating func _installIconURL(_ url: URL, fitting size: CGSize) {
        iconBySize[Self.sizeKey(size)] = url
    }

    @_spi(OpenUIKitHost)
    public mutating func _installScreenshotURLs(_ urls: [URL], fitting size: CGSize) {
        screenshotsBySize[Self.sizeKey(size)] = urls
    }

    public static func == (lhs: ManagedApp, rhs: ManagedApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
            && lhs.platform == rhs.platform
            && lhs.fileSize == rhs.fileSize
            && lhs.name == rhs.name
            && lhs.subtitle == rhs.subtitle
            && lhs.seller == rhs.seller
            && lhs.genres == rhs.genres
            && lhs.description == rhs.description
            && lhs.metadataLanguage == rhs.metadataLanguage
            && lhs.languages == rhs.languages
            && lhs.requirements == rhs.requirements
            && lhs.version == rhs.version
            && lhs.releaseDate == rhs.releaseDate
            && lhs.releaseNotes == rhs.releaseNotes
            && lhs.contentRating == rhs.contentRating
            && lhs.developerWebsite == rhs.developerWebsite
            && lhs.privacyPolicy == rhs.privacyPolicy
            && lhs.licenseAgreementStorage == rhs.licenseAgreementStorage
            && lhs.copyright == rhs.copyright
            && lhs.iconBySize == rhs.iconBySize
            && lhs.screenshotsBySize == rhs.screenshotsBySize
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
        hasher.combine(platform)
        hasher.combine(fileSize)
        hasher.combine(name)
        hasher.combine(subtitle)
        hasher.combine(seller)
        hasher.combine(genres)
        hasher.combine(description)
        hasher.combine(metadataLanguage)
        hasher.combine(languages)
        hasher.combine(requirements)
        hasher.combine(version)
        hasher.combine(releaseDate)
        hasher.combine(releaseNotes)
        hasher.combine(contentRating)
        hasher.combine(developerWebsite)
        hasher.combine(privacyPolicy)
        hasher.combine(licenseAgreementStorage)
        hasher.combine(copyright)
    }

    private static func sizeKey(_ size: CGSize) -> String {
        "\(size.width)x\(size.height)"
    }
}
