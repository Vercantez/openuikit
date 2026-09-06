import Foundation

/// Grid-cleanliness / load-shifting guidance for an energy venue. Values are
/// Codable snapshots; live guidance requires Apple's electricity service.
public struct ElectricityGuidance: Codable, Sendable {
    public enum SuggestedAction: Codable, Equatable, Hashable, Sendable {
        case shift
        case reduce
    }

    public struct Query: Codable, Sendable {
        public let suggestedAction: ElectricityGuidance.SuggestedAction

        public init(suggestedAction: ElectricityGuidance.SuggestedAction) {
            self.suggestedAction = suggestedAction
        }
    }

    public struct Value: Codable, Sendable {
        public let interval: DateInterval
        public let rating: Double

        public init(interval: DateInterval, rating: Double) {
            self.interval = interval
            self.rating = rating
        }
    }

    public enum Options: Codable, Equatable, Hashable, Sendable, CaseIterable {
        case locationHasRatePlan
        case guidanceIncorporatesRatePlan
    }

    public final class Service: Sendable {
        public init() {}

        /// Live guidance stream. The iterator fails closed with
        /// `guidanceUnavailable` because this host has no Apple guidance daemon.
        public func guidance(
            using query: ElectricityGuidance.Query,
            at energyVenueID: UUID
        ) -> some AsyncSequence<ElectricityGuidance, any Error> {
            _ = query
            _ = energyVenueID
            return EnergyKitFailClosedSequence<ElectricityGuidance>(
                error: .guidanceUnavailable
            )
        }
    }

    public let guidanceToken: UUID
    public let energyVenueID: UUID
    public let suggestedAction: ElectricityGuidance.SuggestedAction
    public let interval: DateInterval
    public let values: [ElectricityGuidance.Value]
    public let options: Set<ElectricityGuidance.Options>

    public static let sharedService = ElectricityGuidance.Service()

    public init(
        guidanceToken: UUID,
        energyVenueID: UUID,
        suggestedAction: ElectricityGuidance.SuggestedAction,
        interval: DateInterval,
        values: [ElectricityGuidance.Value],
        options: Set<ElectricityGuidance.Options>
    ) {
        self.guidanceToken = guidanceToken
        self.energyVenueID = energyVenueID
        self.suggestedAction = suggestedAction
        self.interval = interval
        self.values = values
        self.options = options
    }
}
