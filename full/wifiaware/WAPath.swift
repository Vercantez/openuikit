import Foundation

/// A Wi-Fi Aware browse/connect endpoint.
///
/// Endpoints are produced by Network browsers on Apple platforms. The exact
/// graph has no public initializer, so this starting point does not add one.
public struct WAEndpoint: Sendable, Hashable, CustomStringConvertible {
    public let device: WAPairedDevice
    public let publishedService: WAPublishableService?
    public let subscribedService: WASubscribableService?

    public var description: String {
        var parts = [device.description]
        if let publishedService {
            parts.append("published:\(publishedService.name)")
        }
        if let subscribedService {
            parts.append("subscribed:\(subscribedService.name)")
        }
        return "WAEndpoint(\(parts.joined(separator: ", ")))"
    }
}

/// Performance sample for an active Wi-Fi Aware datapath.
///
/// Public construction is `init(from:)`. Memberwise construction is internal.
public struct WAPerformanceReport: Sendable, Codable {
    public let timestamp: Date
    public let localTimestamp: ContinuousClock.Instant
    public let throughputCeiling: Double?
    public let throughputCapacity: Double?
    public let transmitLatency: [WAAccessCategory: TransmitLatencyMetrics]
    public let signalStrength: Double?

    /// `throughputCapacity / throughputCeiling` when both values are present
    /// and the ceiling is nonzero. Missing samples yield `nil`. This does not
    /// clamp; Apple's observed range is documented as 0.0...1.0.
    public var throughputCapacityRatio: Double? {
        guard let throughputCapacity, let throughputCeiling, throughputCeiling != 0 else {
            return nil
        }
        return throughputCapacity / throughputCeiling
    }

    public struct TransmitLatencyMetrics: Sendable, Codable {
        public let accessCategory: WAAccessCategory
        public let average: Duration?
    }
}

/// Status of a Wi-Fi Aware Network path.
///
/// Paths are system-produced. The exact graph has no public initializer.
public struct WAPath: Sendable {
    public let endpoint: WAEndpoint
    public let performance: WAPerformanceReport
    public let durationActive: Duration
}
