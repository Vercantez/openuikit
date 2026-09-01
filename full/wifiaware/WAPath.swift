import Foundation

/// A Wi-Fi Aware browse/connect endpoint.
///
/// Endpoints are produced by Network browsers on Apple platforms. Linux allows
/// local construction for tests and value semantics; connecting still requires
/// a Network ``Connectable`` implementation that this starting point does not
/// claim.
public struct WAEndpoint: Sendable, Hashable, CustomStringConvertible {
    public let device: WAPairedDevice
    public let publishedService: WAPublishableService?
    public let subscribedService: WASubscribableService?

    public init(
        device: WAPairedDevice,
        publishedService: WAPublishableService? = nil,
        subscribedService: WASubscribableService? = nil
    ) {
        self.device = device
        self.publishedService = publishedService
        self.subscribedService = subscribedService
    }

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
public struct WAPerformanceReport: Sendable, Codable {
    public let timestamp: Date
    public let localTimestamp: ContinuousClock.Instant
    public let throughputCeiling: Double?
    public let throughputCapacity: Double?
    public let transmitLatency: [WAAccessCategory: TransmitLatencyMetrics]
    public let signalStrength: Double?

    public init(
        timestamp: Date,
        localTimestamp: ContinuousClock.Instant,
        throughputCeiling: Double?,
        throughputCapacity: Double?,
        transmitLatency: [WAAccessCategory: TransmitLatencyMetrics],
        signalStrength: Double?
    ) {
        self.timestamp = timestamp
        self.localTimestamp = localTimestamp
        self.throughputCeiling = throughputCeiling
        self.throughputCapacity = throughputCapacity
        self.transmitLatency = transmitLatency
        self.signalStrength = signalStrength
    }

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

        public init(accessCategory: WAAccessCategory, average: Duration?) {
            self.accessCategory = accessCategory
            self.average = average
        }
    }
}

/// Status of a Wi-Fi Aware Network path.
public struct WAPath: Sendable {
    public let endpoint: WAEndpoint
    public let performance: WAPerformanceReport
    public let durationActive: Duration

    public init(
        endpoint: WAEndpoint,
        performance: WAPerformanceReport,
        durationActive: Duration
    ) {
        self.endpoint = endpoint
        self.performance = performance
        self.durationActive = durationActive
    }
}
