import Foundation

/// Grid import versus export direction for vehicle measurements and insight
/// queries. Case order matches the Xcode 26.1 digester.
public enum ElectricityFlowDirection: Codable, Equatable, Hashable, Sendable {
    case imported
    case exported
}

/// A query for energy or runtime insights. Options are an option set;
/// `cleanliness` and `tariff` bit values follow declaration order (1 << 0,
/// 1 << 1) and are unobserved against Apple.
public struct ElectricityInsightQuery: Codable, Sendable {
    public struct Options: OptionSet, Codable, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let cleanliness = ElectricityInsightQuery.Options(rawValue: 1 << 0)
        public static let tariff = ElectricityInsightQuery.Options(rawValue: 1 << 1)
    }

    public enum Granularity: Codable, Equatable, Hashable, Sendable {
        case hourly
        case daily
        case weekly
        case monthly
        case yearly
    }

    public let options: ElectricityInsightQuery.Options
    public let range: DateInterval
    public let granularity: ElectricityInsightQuery.Granularity
    public let flowDirection: ElectricityFlowDirection

    public init(
        options: ElectricityInsightQuery.Options,
        range: DateInterval,
        granularity: ElectricityInsightQuery.Granularity,
        flowDirection: ElectricityFlowDirection
    ) {
        self.options = options
        self.range = range
        self.granularity = granularity
        self.flowDirection = flowDirection
    }
}

/// A single insight bucket. `totalEnergy` is always a `UnitEnergy`
/// measurement; `totalRuntime` is always a `Duration`, independent of
/// `Measure`. Live records come from `ElectricityInsightService`, which fails
/// closed on this host.
public struct ElectricityInsightRecord<Measure: ElectricityInsightMeasure> {
    public struct GridCleanliness {
        public var cleaner: Measure?
        public var lessClean: Measure?
        public var avoid: Measure?
        public var unknown: Measure?

        public init(
            cleaner: Measure?,
            lessClean: Measure?,
            avoid: Measure?,
            unknown: Measure?
        ) {
            self.cleaner = cleaner
            self.lessClean = lessClean
            self.avoid = avoid
            self.unknown = unknown
        }
    }

    public struct TariffPeak {
        public var superOffPeak: Measure?
        public var offPeak: Measure?
        public var partialPeak: Measure?
        public var onPeak: Measure?
        public var criticalPeak: Measure?
        public var unknown: Measure?

        public init(
            superOffPeak: Measure?,
            offPeak: Measure?,
            partialPeak: Measure?,
            onPeak: Measure?,
            criticalPeak: Measure?,
            unknown: Measure?
        ) {
            self.superOffPeak = superOffPeak
            self.offPeak = offPeak
            self.partialPeak = partialPeak
            self.onPeak = onPeak
            self.criticalPeak = criticalPeak
            self.unknown = unknown
        }
    }

    public let range: DateInterval
    public var totalEnergy: Measurement<UnitEnergy>?
    public var totalRuntime: Duration?
    public var dataByGridCleanliness: ElectricityInsightRecord<Measure>.GridCleanliness?
    public var dataByTariffPeak: ElectricityInsightRecord<Measure>.TariffPeak?

    public init(range: DateInterval) {
        self.range = range
        self.totalEnergy = nil
        self.totalRuntime = nil
        self.dataByGridCleanliness = nil
        self.dataByTariffPeak = nil
    }
}

/// Apple electricity-insight actor. `shared` is a process singleton; queries
/// throw `serviceUnavailable` because there is no insight daemon on Linux.
public final actor ElectricityInsightService {
    public static let shared = ElectricityInsightService()

    public func energyInsights(
        forDeviceID deviceID: String,
        using query: ElectricityInsightQuery,
        atVenue energyVenueID: UUID
    ) async throws -> AsyncStream<ElectricityInsightRecord<Measurement<UnitEnergy>>> {
        _ = deviceID
        _ = query
        _ = energyVenueID
        throw EnergyKitError.serviceUnavailable
    }

    public func runtimeInsights(
        forDeviceID deviceID: String,
        using query: ElectricityInsightQuery,
        atVenue energyVenueID: UUID
    ) async throws -> AsyncStream<ElectricityInsightRecord<Duration>> {
        _ = deviceID
        _ = query
        _ = energyVenueID
        throw EnergyKitError.serviceUnavailable
    }
}
