import Foundation

public protocol TipOption: Sendable {}

public struct TipKitError: Error, Hashable, Sendable, LocalizedError, CustomStringConvertible {
    enum Code: String, Sendable {
        case invalidPredicateValueType
        case tipsDatastoreAlreadyConfigured
        case missingGroupContainerEntitlements
    }

    let code: Code

    public static let invalidPredicateValueType = TipKitError(code: .invalidPredicateValueType)
    public static let tipsDatastoreAlreadyConfigured = TipKitError(
        code: .tipsDatastoreAlreadyConfigured
    )
    public static let missingGroupContainerEntitlements = TipKitError(
        code: .missingGroupContainerEntitlements
    )

    public var description: String { code.rawValue }
    public var errorDescription: String? { code.rawValue }
}

extension Tips {
    public enum InvalidationReason: Hashable, Sendable {
        case actionPerformed
        case displayCountExceeded
        case displayDurationExceeded
        case tipClosed
    }

    public enum Status: Hashable, Sendable {
        case pending
        case available
        case invalidated(Tips.InvalidationReason)
    }

    public struct DonationTimeRange: Hashable, Codable, Sendable {
        let hostSeconds: TimeInterval

        init(hostSeconds: TimeInterval) {
            self.hostSeconds = hostSeconds
        }

        public static var minute: Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 60)
        }

        public static var hour: Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 3_600)
        }

        public static var day: Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 86_400)
        }

        public static var week: Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 604_800)
        }

        public static func minutes(_ value: Int) -> Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 60 * TimeInterval(value))
        }

        public static func hours(_ value: Int) -> Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 3_600 * TimeInterval(value))
        }

        public static func days(_ value: Int) -> Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 86_400 * TimeInterval(value))
        }

        public static func weeks(_ value: Int) -> Tips.DonationTimeRange {
            Tips.DonationTimeRange(hostSeconds: 604_800 * TimeInterval(value))
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            hostSeconds = try container.decode(TimeInterval.self)
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(hostSeconds)
        }
    }

    public struct DonationLimit: Sendable {
        public let maximumCount: Int
        public let maximumAge: Tips.DonationTimeRange?

        public init(maximumCount: Int, maximumAge: Tips.DonationTimeRange? = nil) {
            self.maximumCount = maximumCount
            self.maximumAge = maximumAge
        }
    }

    public struct EmptyDonation: Codable, Hashable, Sendable {
        public init() {}
    }

    public struct MaxDisplayCount: TipOption, Sendable {
        let maxDisplayCount: Int

        public init(_ maxDisplayCount: Int) {
            self.maxDisplayCount = maxDisplayCount
        }
    }

    public struct MaxDisplayDuration: TipOption, Sendable {
        let maxDisplayDuration: TimeInterval

        public init(_ maxDisplayDuration: TimeInterval) {
            self.maxDisplayDuration = maxDisplayDuration
        }
    }

    public struct IgnoresDisplayFrequency: TipOption, Sendable {
        let ignoresDisplayFrequency: Bool

        public init(_ ignoresDisplayFrequency: Bool) {
            self.ignoresDisplayFrequency = ignoresDisplayFrequency
        }
    }

    public struct ParameterOption: Sendable, Hashable {
        let kind: Kind

        enum Kind: Hashable, Sendable {
            case transient
        }

        public static var transient: Tips.ParameterOption {
            Tips.ParameterOption(kind: .transient)
        }
    }

    public struct ConfigurationOption: Sendable {
        enum Payload: Sendable {
            case datastore(DatastoreLocation)
            case frequency(DisplayFrequency)
            case cloudKit(CloudKitContainer?)
        }

        let payload: Payload

        public struct CloudKitContainer: Hashable, Sendable {
            let name: String?

            public static var automatic: Tips.ConfigurationOption.CloudKitContainer {
                Tips.ConfigurationOption.CloudKitContainer(name: nil)
            }

            public static func named(
                _ containerName: String
            ) -> Tips.ConfigurationOption.CloudKitContainer {
                Tips.ConfigurationOption.CloudKitContainer(name: containerName)
            }
        }

        public struct DisplayFrequency: Hashable, Sendable {
            enum Kind: Hashable, Sendable {
                case immediate, hourly, daily, weekly, monthly
            }

            let kind: Kind

            public static var immediate: Tips.ConfigurationOption.DisplayFrequency {
                Tips.ConfigurationOption.DisplayFrequency(kind: .immediate)
            }

            public static var hourly: Tips.ConfigurationOption.DisplayFrequency {
                Tips.ConfigurationOption.DisplayFrequency(kind: .hourly)
            }

            public static var daily: Tips.ConfigurationOption.DisplayFrequency {
                Tips.ConfigurationOption.DisplayFrequency(kind: .daily)
            }

            public static var weekly: Tips.ConfigurationOption.DisplayFrequency {
                Tips.ConfigurationOption.DisplayFrequency(kind: .weekly)
            }

            public static var monthly: Tips.ConfigurationOption.DisplayFrequency {
                Tips.ConfigurationOption.DisplayFrequency(kind: .monthly)
            }

            /// Elapsed-second mapping used by Linux display-frequency arithmetic.
            /// Calendar-month boundaries are unobserved; monthly is 30 days.
            var hostSeconds: TimeInterval? {
                switch kind {
                case .immediate: return nil
                case .hourly: return 3_600
                case .daily: return 86_400
                case .weekly: return 604_800
                case .monthly: return 2_592_000
                }
            }
        }

        public struct DatastoreLocation: Hashable, Sendable {
            enum Kind: Hashable, Sendable {
                case applicationDefault
                case url(URL)
            }

            let kind: Kind

            public static var applicationDefault: Tips.ConfigurationOption.DatastoreLocation {
                Tips.ConfigurationOption.DatastoreLocation(kind: .applicationDefault)
            }

            public static func url(_ url: URL) -> Tips.ConfigurationOption.DatastoreLocation {
                Tips.ConfigurationOption.DatastoreLocation(kind: .url(url))
            }

            /// Linux has no app-group container for TipKit. Always fail-closed.
            public static func groupContainer(identifier: String) throws
                -> Tips.ConfigurationOption.DatastoreLocation
            {
                _ = identifier
                throw TipKitError.missingGroupContainerEntitlements
            }
        }

        public static func datastoreLocation(
            _ storeLocation: Tips.ConfigurationOption.DatastoreLocation
        ) -> Tips.ConfigurationOption {
            Tips.ConfigurationOption(payload: .datastore(storeLocation))
        }

        public static func displayFrequency(
            _ displayFrequency: Tips.ConfigurationOption.DisplayFrequency
        ) -> Tips.ConfigurationOption {
            Tips.ConfigurationOption(payload: .frequency(displayFrequency))
        }

        public static func cloudKitContainer(
            _ cloudKitContainer: Tips.ConfigurationOption.CloudKitContainer?
        ) -> Tips.ConfigurationOption {
            Tips.ConfigurationOption(payload: .cloudKit(cloudKitContainer))
        }
    }
}
