import Foundation

/// An individual prediction of anticipated cellular network availability.
///
/// Linux reconstructs the public Xcode 26.1 overlay. Memberwise
/// `init(impact:predictedStartTime:predictedInterval:confidenceScore:)` is
/// exported by the pinned TBD; it is not one of the 75 Swift census IDs.
/// Codable keys follow stored property names. Apple's live coding keys and
/// `JSONEncoder.DateEncodingStrategy` are unobserved.
public struct ServicePrediction: Hashable, Codable, Sendable {
    /// An enumeration of levels of impact for a predicted event.
    public enum Impact: Codable, Hashable, Sendable, Comparable {
        /// Slightly lower throughput and possibly some service interruption.
        case low
        /// Moderately lower throughput and service interruption.
        case medium
        /// Severe interruption, including substantially lowered throughput
        /// and the potential to lose data capability.
        case high

        public static func < (a: Impact, b: Impact) -> Bool {
            a.sortIndex < b.sortIndex
        }

        private var sortIndex: Int {
            switch self {
            case .low: return 0
            case .medium: return 1
            case .high: return 2
            }
        }
    }

    /// An enumeration of levels of confidence for a prediction or one of
    /// its properties.
    public enum Confidence: Codable, Hashable, Sendable, Comparable {
        case low
        case medium
        case high

        public static func < (a: Confidence, b: Confidence) -> Bool {
            a.sortIndex < b.sortIndex
        }

        private var sortIndex: Int {
            switch self {
            case .low: return 0
            case .medium: return 1
            case .high: return 2
            }
        }
    }

    /// Discrete time intervals that express the expected duration of a
    /// predicted event.
    ///
    /// Apple's docs describe duration buckets, not exact Darwin `Double`
    /// payloads. Linux maps those documented approximations:
    /// `minimal` = 10 s, `short` = 60 s, `medium` = 300 s, `long` = 600 s
    /// (a distinct value strictly greater than five minutes). See
    /// `oracle-questions.tsv`.
    public struct QuantizedInterval: Sendable {
        private init() {}

        /// Approximately 10 seconds or fewer.
        public static let minimal: Double = 10

        /// Approximately one minute or fewer.
        public static let short: Double = 60

        /// Approximately five minutes.
        public static let medium: Double = 300

        /// More than five minutes.
        public static let long: Double = 600
    }

    /// Confidence in the overall prediction and in its timing fields.
    public struct ConfidenceScore: Hashable, Codable, Sendable {
        public let prediction: Confidence
        public let startTime: Confidence
        public let duration: Confidence

        /// ABI-exported memberwise initializer (pinned TBD). Not a census ID.
        public init(
            prediction: Confidence,
            startTime: Confidence,
            duration: Confidence
        ) {
            self.prediction = prediction
            self.startTime = startTime
            self.duration = duration
        }
    }

    /// The expected impact of the predicted event.
    public let impact: Impact
    /// The start time of the predicted event.
    public let predictedStartTime: Date
    /// The expected duration of the predicted event.
    public let predictedInterval: TimeInterval
    /// Confidence in various aspects of the prediction.
    public let confidenceScore: ConfidenceScore

    /// ABI-exported memberwise initializer (pinned TBD). Not a census ID.
    public init(
        impact: Impact,
        predictedStartTime: Date,
        predictedInterval: TimeInterval,
        confidenceScore: ConfidenceScore
    ) {
        self.impact = impact
        self.predictedStartTime = predictedStartTime
        self.predictedInterval = predictedInterval
        self.confidenceScore = confidenceScore
    }
}

/// Errors encountered while using the WirelessInsights framework.
public enum ServicePredictionError: Error, Hashable, Sendable {
    /// The device doesn’t currently support service predictions.
    case unsupportedDevice
    /// An unexpected error occurred while setting up the event stream.
    case connectionError
}

extension ServicePredictionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsupportedDevice:
            return "The device doesn’t currently support service predictions."
        case .connectionError:
            return "An unexpected error occurred while setting up the event stream."
        }
    }
}
