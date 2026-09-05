import Foundation

/// One labeled classification. Apple produces these from a model; Linux
/// exposes them only through `@_spi(OpenUIKitHost)` so tests can exercise
/// lookup without inventing a classifier.
public final class SNClassification: NSObject {
    public let identifier: String
    public let confidence: Double

    @available(*, unavailable)
    public override init() {
        fatalError("SNClassification has no public default initializer")
    }

    @_spi(OpenUIKitHost)
    public init(hostIdentifier: String, confidence: Double) {
        self.identifier = hostIdentifier
        self.confidence = confidence
        super.init()
    }
}

/// Classification window result. Linux never produces one from analysis;
/// host tests construct snapshots through `@_spi(OpenUIKitHost)`.
public final class SNClassificationResult: NSObject, SNResult {
    public private(set) var classifications: [SNClassification]
    public private(set) var timeRange: CMTimeRange

    @available(*, unavailable)
    public override init() {
        fatalError("SNClassificationResult has no public default initializer")
    }

    @_spi(OpenUIKitHost)
    public init(hostClassifications: [SNClassification], timeRange: CMTimeRange) {
        self.classifications = hostClassifications
        self.timeRange = timeRange
        super.init()
    }

    public func classification(forIdentifier identifier: String) -> SNClassification? {
        classifications.first { $0.identifier == identifier }
    }
}
