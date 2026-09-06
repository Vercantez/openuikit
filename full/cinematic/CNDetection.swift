import Foundation

/// A cinematic subject detection at a single time.
public struct CNDetection: Equatable, Sendable {
    public var time: CMTime { storedTime }
    public var detectionType: CNDetectionType { storedType }
    public var normalizedRect: CGRect { storedRect }
    public var focusDisparity: Float { storedDisparity }
    public var detectionID: CNDetectionID? { storedDetectionID }
    public var detectionGroupID: CNDetectionGroupID? { storedGroupID }

    private var storedTime: CMTime
    private var storedType: CNDetectionType
    private var storedRect: CGRect
    private var storedDisparity: Float
    private var storedDetectionID: CNDetectionID?
    private var storedGroupID: CNDetectionGroupID?

    public init(
        time: CMTime,
        detectionType: CNDetectionType,
        normalizedRect: CGRect,
        focusDisparity: Float
    ) {
        self.storedTime = time
        self.storedType = detectionType
        self.storedRect = normalizedRect
        self.storedDisparity = focusDisparity
        self.storedDetectionID = nil
        self.storedGroupID = nil
    }

    init(
        time: CMTime,
        detectionType: CNDetectionType,
        normalizedRect: CGRect,
        focusDisparity: Float,
        detectionID: CNDetectionID?,
        detectionGroupID: CNDetectionGroupID?
    ) {
        self.storedTime = time
        self.storedType = detectionType
        self.storedRect = normalizedRect
        self.storedDisparity = focusDisparity
        self.storedDetectionID = detectionID
        self.storedGroupID = detectionGroupID
    }

    func assigning(
        detectionID: CNDetectionID?,
        detectionGroupID: CNDetectionGroupID?
    ) -> CNDetection {
        CNDetection(
            time: storedTime,
            detectionType: storedType,
            normalizedRect: storedRect,
            focusDisparity: storedDisparity,
            detectionID: detectionID,
            detectionGroupID: detectionGroupID
        )
    }

    /// Linux-local English accessibility tokens named after the detection
    /// type. Apple's VoiceOver strings are localized and unobserved.
    public static func accessibilityLabel(for detectionType: CNDetectionType) -> String {
        switch detectionType {
        case .unknown: return "Unknown"
        case .humanFace: return "Person"
        case .humanHead: return "Head"
        case .humanTorso: return "Torso"
        case .catBody: return "Cat"
        case .dogBody: return "Dog"
        case .catHead: return "Cat"
        case .dogHead: return "Dog"
        case .sportsBall: return "Sports Ball"
        case .autoFocus: return "Auto Focus"
        case .fixedFocus: return "Fixed Focus"
        case .custom: return "Custom"
        }
    }

    /// Disparity sampling from a pixel buffer is Apple ML/video behavior.
    /// Linux returns `priorDisparity` when provided, otherwise `0`, and never
    /// invents a disparity map read.
    public static func disparity(
        in normalizedRect: CGRect,
        sourceDisparity: CVPixelBuffer,
        detectionType: CNDetectionType,
        priorDisparity: Float? = nil
    ) -> Float {
        _ = normalizedRect
        _ = sourceDisparity
        _ = detectionType
        return priorDisparity ?? 0
    }
}

/// Predicted normalized bounds plus a tracker confidence in `0...1`.
public struct CNBoundsPrediction: Sendable {
    public var normalizedBounds: CGRect
    public var confidence: Float

    public init(normalizedBounds: CGRect = .zero, confidence: Float = 0) {
        self.normalizedBounds = normalizedBounds
        self.confidence = confidence
    }
}
