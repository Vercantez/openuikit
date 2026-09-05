import Foundation

#if canImport(CoreML)
import CoreML
#endif

/// Sound classification request. Linux constructs a configuration object
/// for `SNClassifierIdentifier.version1` but never loads Apple's classifier.
/// `knownClassifications` is empty. Analysis observers still fail closed.
public final class SNClassifySoundRequest: NSObject, SNRequest {
    private var overlapFactorStorage: Double
    private var windowDurationStorage: CMTime
    private let constraint: SNTimeDurationConstraint
    private let classifications: [String]

    @available(*, unavailable)
    public override init() {
        fatalError("SNClassifySoundRequest has no public default initializer")
    }

    public init(classifierIdentifier: SNClassifierIdentifier) throws {
        guard classifierIdentifier == .version1 else {
            throw snLinuxUnavailable(.invalidModel)
        }
        self.overlapFactorStorage = 0
        self.windowDurationStorage = .invalid
        self.constraint = .enumeratedDurations([])
        self.classifications = []
        super.init()
    }

#if canImport(CoreML)
    public init(mlModel: MLModel) throws {
        _ = mlModel
        throw snLinuxUnavailable(.invalidModel)
    }

    public init(MLModel mlModel: MLModel) throws {
        _ = mlModel
        throw snLinuxUnavailable(.invalidModel)
    }
#endif

    public var knownClassifications: [String] { classifications }

    /// Documented range is 0.0...1.0. Linux clamps to that range. Apple's
    /// default and out-of-range rejection policy are unobserved.
    public var overlapFactor: Double {
        get { overlapFactorStorage }
        set { overlapFactorStorage = min(max(newValue, 0), 1) }
    }

    public var windowDuration: CMTime {
        get { windowDurationStorage }
        set { windowDurationStorage = newValue }
    }

    public var windowDurationConstraint: SNTimeDurationConstraint { constraint }
}
