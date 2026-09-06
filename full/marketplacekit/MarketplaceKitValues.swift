import Foundation

/// An app version identified by Apple item and version IDs.
public struct AppVersion: Sendable, CustomStringConvertible {
    public let appleItemID: AppleItemID
    public let appleVersionID: UInt64

    public init(appleItemID: AppleItemID, appleVersionID: UInt64) {
        self.appleItemID = appleItemID
        self.appleVersionID = appleVersionID
    }

    /// Linux textual form `itemID:versionID`. Darwin's format is unobserved.
    public var description: String {
        "\(appleItemID):\(appleVersionID)"
    }
}

/// An automatic-update descriptor supplied by a marketplace extension.
public struct AutomaticUpdate: Sendable {
    public let appleItemID: AppleItemID
    public let alternativeDistributionPackage: URL
    public let account: String
    public let installVerificationToken: String
    public var appShareURL: URL?

    public init(
        appleItemID: AppleItemID,
        alternativeDistributionPackage: URL,
        account: String,
        installVerificationToken: String
    ) {
        self.appleItemID = appleItemID
        self.alternativeDistributionPackage = alternativeDistributionPackage
        self.account = account
        self.installVerificationToken = installVerificationToken
        self.appShareURL = nil
    }
}

/// Device-side install constraints decoded from an alternative-distribution
/// package. Linux is not an iOS device: non-empty Apple-device constraints
/// fail `satisfiedByDevice()`.
public struct InstallRequirements: Sendable, Codable {
    public var minimumSystemVersion: String?
    public var requiredDeviceCapabilities: Set<String>?
    public var ageRatingRank: Int?
    public var expectedInstallSize: UInt64?

    public init() {
        minimumSystemVersion = nil
        requiredDeviceCapabilities = nil
        ageRatingRank = nil
        expectedInstallSize = nil
    }

    /// Returns whether this host satisfies the recorded constraints.
    ///
    /// - Empty requirements (all fields `nil`) are vacuously satisfied.
    /// - Any `requiredDeviceCapabilities`, `minimumSystemVersion`, or
    ///   `ageRatingRank` fails closed: Linux is not an iPhone/iPad with
    ///   Screen Time age ratings.
    /// - `expectedInstallSize` compares against the home-volume free space
    ///   when Foundation reports it; unknown capacity fails closed.
    public func satisfiedByDevice() -> Bool {
        if let capabilities = requiredDeviceCapabilities, !capabilities.isEmpty {
            return false
        }
        if minimumSystemVersion != nil {
            return false
        }
        if ageRatingRank != nil {
            return false
        }
        if let expected = expectedInstallSize {
            guard let available = MarketplaceKitLinux.volumeAvailableBytes() else {
                return false
            }
            return available >= expected
        }
        return true
    }
}

/// How the running app was distributed.
public enum AppDistributor: Sendable, Equatable {
    case appStore
    case testFlight
    case marketplace(String)
    case web
    case other

    /// Linux has no App Store / marketplace identity daemon.
    public static var current: AppDistributor {
        get async throws {
            throw MarketplaceKitError.unsupportedPlatform
        }
    }
}

/// Token services for Core Technology Commission reporting.
public enum TransactionReporting: Sendable {
    /// The type of transaction reporting token.
    public struct TokenType: RawRepresentable, Sendable, Equatable {
        public typealias RawValue = String
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        /// Core Technology Commission reporting token.
        ///
        /// The Darwin string payload is unobserved; Linux uses the member
        /// name. See `oracle-questions.tsv`.
        public static let coreTechnology = TokenType(rawValue: "coreTechnology")
    }

    /// Linux has no Apple transaction-reporting service.
    public static func token(for tokenType: TokenType) async throws -> String {
        _ = tokenType
        throw MarketplaceKitError.featureUnavailable
    }
}
