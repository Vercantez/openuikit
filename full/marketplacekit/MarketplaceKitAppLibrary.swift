import Foundation

/// In-process catalog of marketplace apps.
///
/// Darwin talks to the alternative-distribution install daemon. Linux keeps
/// `installedApps` / `installingApps` as process-local sets, never reports a
/// successful Apple install, and throws `MarketplaceKitError` from every
/// service method.
public final class AppLibrary: @unchecked Sendable {
    public static let current = AppLibrary()

    private var appsByID: [AppleItemID: App] = [:]
    private var territory: String?

    public var installedApps: Set<App> = []
    public var installingApps: Set<App> = []

    /// Linux never loads from an Apple daemon.
    public var isLoading: Bool { false }

    /// Fail-closed: no Screen Time / parental-control daemon, so the allowed
    /// age rating is `0`.
    public var maximumAllowedAgeRating: Int { 0 }

    public var searchTerritory: String? {
        get async {
            territory
        }
    }

    public func app(forAppleItemID appleItemID: AppleItemID) -> App {
        if let existing = appsByID[appleItemID] {
            return existing
        }
        let created = App(id: appleItemID)
        appsByID[appleItemID] = created
        return created
    }

    public func setSearchTerritory(_ territory: String?) async {
        self.territory = territory
    }

    public func requestAppInstallation(
        for url: URL,
        account: String,
        installVerificationToken: String
    ) async throws {
        _ = account
        try Self.rejectInstallation(url: url, token: installVerificationToken)
    }

    public func requestAppInstallation(_ request: InstallationRequest) async throws {
        try Self.rejectInstallation(
            url: request.alternativeDistributionPackageURL,
            token: request.installVerificationToken
        )
    }

    public func requestAppInstallationFromBrowser(for url: URL, referrer: URL) async throws {
        _ = referrer
        try Self.rejectInstallation(url: url, token: "")
    }

    public func requestAppUpdate(
        for url: URL,
        account: String,
        installVerificationToken: String
    ) async throws {
        _ = account
        try Self.rejectInstallation(url: url, token: installVerificationToken)
    }

    public func requestAppUpdate(_ request: InstallationRequest) async throws {
        try Self.rejectInstallation(
            url: request.alternativeDistributionPackageURL,
            token: request.installVerificationToken
        )
    }

    public func didAuthenticate(account: String) async {
        _ = account
    }

    public func requestLicenseRenewal(appleItemIDs: [UInt64]) async throws {
        _ = appleItemIDs
        throw MarketplaceKitError.invalidLicense
    }

    public func currentAgeExceptionRequests() async throws -> [ExceptionRequest] {
        []
    }

    static func rejectInstallation(url: URL, token: String) throws {
        if url.scheme != MarketplaceKitURIScheme && url.scheme != "https" && url.scheme != "http" {
            throw MarketplaceKitError.invalidURL
        }
        if token.isEmpty {
            throw MarketplaceKitError.missingInstallVerificationToken
        }
        throw MarketplaceKitError.unsupportedPlatform
    }

    /// An app known to this library, identified by `AppleItemID`.
    public final class App: Hashable, @unchecked Sendable {
        public typealias ID = AppleItemID

        public let id: AppleItemID

        public struct Metadata: Sendable, Equatable {
            public let appleVersionID: AppleVersionID
            public let version: String
            public let shortVersion: String
            public let account: String?

            public init(
                appleVersionID: AppleVersionID,
                version: String,
                shortVersion: String,
                account: String?
            ) {
                self.appleVersionID = appleVersionID
                self.version = version
                self.shortVersion = shortVersion
                self.account = account
            }

            public static func == (a: Metadata, b: Metadata) -> Bool {
                a.appleVersionID == b.appleVersionID
                    && a.version == b.version
                    && a.shortVersion == b.shortVersion
                    && a.account == b.account
            }
        }

        public struct Installation: Sendable {
            public var progress: Progress

            public init(progress: Progress) {
                self.progress = progress
            }
        }

        public var installedMetadata: Metadata?
        public var installation: Installation?
        public var installationError: MarketplaceKitError?
        public var isInstalled: Bool { installedMetadata != nil }
        public var isInstalling: Bool { installation != nil && installedMetadata == nil }
        public var isUpdating: Bool { installation != nil && installedMetadata != nil }

        init(id: AppleItemID) {
            self.id = id
        }

        public func presentAgeExceptionApproveInPersonSheet() async throws {
            throw MarketplaceKitError.featureUnavailable
        }

        public static func == (lhs: App, rhs: App) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    public struct InstallationRequest {
        public var alternativeDistributionPackageURL: URL
        public var account: String
        public var installVerificationToken: String
        public var appShareURL: URL?

        public init(
            alternativeDistributionPackageURL: URL,
            account: String,
            installVerificationToken: String
        ) {
            self.alternativeDistributionPackageURL = alternativeDistributionPackageURL
            self.account = account
            self.installVerificationToken = installVerificationToken
            self.appShareURL = nil
        }
    }

    public struct ExceptionRequest: Sendable, Codable {
        public let appleItemID: AppleItemID
        public let status: Status

        public init(appleItemID: AppleItemID, status: Status) {
            self.appleItemID = appleItemID
            self.status = status
        }

        /// Digester child order: `pending`, `approved`, `declined`.
        public enum Status: Int, Sendable, Codable, Hashable {
            case pending = 0
            case approved = 1
            case declined = 2
        }
    }
}
