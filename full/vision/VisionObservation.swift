//===----------------------------------------------------------------------===//
// Observation types. Constructors that exist on Apple are real; ML-produced
// fields stay empty / nil rather than fabricating detections.
//===----------------------------------------------------------------------===//

open class VNObservation: NSObject, NSCopying, VNRequestRevisionProviding, @unchecked Sendable {
    public let uuid: UUID
    public let confidence: VNConfidence
    public let requestRevision: Int

    public init(
        requestRevision: Int = VNRequestRevisionUnspecified,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.requestRevision = requestRevision
        self.confidence = confidence
        self.uuid = uuid
        super.init()
    }

    public init?(coder: NSCoder) {
        return nil
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNObservation(
            requestRevision: requestRevision,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNDetectedObjectObservation: VNObservation, @unchecked Sendable {
    public let boundingBox: CGRect

    public convenience init(boundingBox: CGRect) {
        self.init(requestRevision: VNRequestRevisionUnspecified, boundingBox: boundingBox)
    }

    public convenience init(requestRevision: Int, boundingBox: CGRect) {
        self.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: 1,
            uuid: UUID()
        )
    }

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.boundingBox = boundingBox
        super.init(requestRevision: requestRevision, confidence: confidence, uuid: uuid)
    }

    public override func copy(with zone: NSZone? = nil) -> Any {
        VNDetectedObjectObservation(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNFaceObservation: VNDetectedObjectObservation, @unchecked Sendable {
    public let roll: NSNumber?
    public let yaw: NSNumber?
    public let pitch: NSNumber?
    public internal(set) var landmarks: VNFaceLandmarks2D?
    public internal(set) var faceCaptureQuality: Float?

    public convenience init(
        requestRevision: Int,
        boundingBox: CGRect,
        roll: NSNumber?,
        yaw: NSNumber?
    ) {
        self.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            roll: roll,
            yaw: yaw,
            pitch: nil
        )
    }

    public convenience init(
        requestRevision: Int,
        boundingBox: CGRect,
        roll: NSNumber?,
        yaw: NSNumber?,
        pitch: NSNumber?
    ) {
        self.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            roll: roll,
            yaw: yaw,
            pitch: pitch,
            confidence: 1,
            uuid: UUID()
        )
    }

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        roll: NSNumber?,
        yaw: NSNumber?,
        pitch: NSNumber?,
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.roll = roll
        self.yaw = yaw
        self.pitch = pitch
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNRectangleObservation: VNDetectedObjectObservation, @unchecked Sendable {
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomRight: CGPoint
    public let bottomLeft: CGPoint

    public convenience init(
        requestRevision: Int,
        topLeft: CGPoint,
        bottomLeft: CGPoint,
        bottomRight: CGPoint,
        topRight: CGPoint
    ) {
        self.init(
            requestRevision: requestRevision,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft
        )
    }

    public convenience init(
        requestRevision: Int,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint
    ) {
        let minX = min(topLeft.x, bottomLeft.x, bottomRight.x, topRight.x)
        let maxX = max(topLeft.x, bottomLeft.x, bottomRight.x, topRight.x)
        let minY = min(topLeft.y, bottomLeft.y, bottomRight.y, topRight.y)
        let maxY = max(topLeft.y, bottomLeft.y, bottomRight.y, topRight.y)
        self.init(
            requestRevision: requestRevision,
            boundingBox: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: 1,
            uuid: UUID()
        )
    }

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNBarcodeObservation: VNRectangleObservation, @unchecked Sendable {
    public let symbology: VNBarcodeSymbology
    public let payloadStringValue: String?
    public let payloadData: Data?
    public let supplementalPayloadString: String?
    public let supplementalPayloadData: Data?
    public let supplementalCompositeType: VNBarcodeCompositeType
    public let isGS1DataCarrier: Bool
    public let isColorInverted: Bool

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        symbology: VNBarcodeSymbology,
        payloadStringValue: String?,
        payloadData: Data?,
        supplementalPayloadString: String? = nil,
        supplementalPayloadData: Data? = nil,
        supplementalCompositeType: VNBarcodeCompositeType = .none,
        isGS1DataCarrier: Bool = false,
        isColorInverted: Bool = false,
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.symbology = symbology
        self.payloadStringValue = payloadStringValue
        self.payloadData = payloadData
        self.supplementalPayloadString = supplementalPayloadString
        self.supplementalPayloadData = supplementalPayloadData
        self.supplementalCompositeType = supplementalCompositeType
        self.isGS1DataCarrier = isGS1DataCarrier
        self.isColorInverted = isColorInverted
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNTextObservation: VNRectangleObservation, @unchecked Sendable {
    public let characterBoxes: [VNRectangleObservation]?

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        characterBoxes: [VNRectangleObservation]?,
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.characterBoxes = characterBoxes
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNRecognizedText: NSObject, @unchecked Sendable {
    public let string: String
    public let confidence: VNConfidence

    public init(string: String, confidence: VNConfidence) {
        self.string = string
        self.confidence = confidence
        super.init()
    }

    public init?(coder: NSCoder) {
        return nil
    }

    public func boundingBox(for range: Range<String.Index>) throws -> VNRectangleObservation? {
        _ = range
        throw visionError(
            .notImplemented,
            "Linux Vision cannot map recognized-text ranges onto image boxes"
        )
    }
}

open class VNRecognizedTextObservation: VNRectangleObservation, @unchecked Sendable {
    internal var candidates: [VNRecognizedText]

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        candidates: [VNRecognizedText],
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.candidates = candidates
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }

    public func topCandidates(_ maxCandidateCount: Int) -> [VNRecognizedText] {
        guard maxCandidateCount > 0 else { return [] }
        return Array(candidates.prefix(maxCandidateCount))
    }
}

open class VNClassificationObservation: VNObservation, @unchecked Sendable {
    public let identifier: String
    public let hasPrecisionRecallCurve: Bool

    public init(
        requestRevision: Int,
        identifier: String,
        confidence: VNConfidence,
        hasPrecisionRecallCurve: Bool = false,
        uuid: UUID = UUID()
    ) {
        self.identifier = identifier
        self.hasPrecisionRecallCurve = hasPrecisionRecallCurve
        super.init(requestRevision: requestRevision, confidence: confidence, uuid: uuid)
    }

    public func hasMinimumPrecision(_ minimumPrecision: Float, forRecall recall: Float) -> Bool {
        _ = minimumPrecision
        _ = recall
        return false
    }

    public func hasMinimumRecall(_ minimumRecall: Float, forPrecision precision: Float) -> Bool {
        _ = minimumRecall
        _ = precision
        return false
    }
}

open class VNRecognizedObjectObservation: VNDetectedObjectObservation, @unchecked Sendable {
    public let labels: [VNClassificationObservation]

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        labels: [VNClassificationObservation],
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.labels = labels
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNPixelBufferObservation: VNObservation, @unchecked Sendable {
    public let featureName: String?

    public init(
        requestRevision: Int,
        featureName: String?,
        confidence: VNConfidence,
        uuid: UUID = UUID()
    ) {
        self.featureName = featureName
        super.init(requestRevision: requestRevision, confidence: confidence, uuid: uuid)
    }
}

open class VNSaliencyImageObservation: VNPixelBufferObservation, @unchecked Sendable {
    public let salientObjects: [VNRectangleObservation]?

    public init(
        requestRevision: Int,
        featureName: String?,
        salientObjects: [VNRectangleObservation]?,
        confidence: VNConfidence,
        uuid: UUID = UUID()
    ) {
        self.salientObjects = salientObjects
        super.init(
            requestRevision: requestRevision,
            featureName: featureName,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNHorizonObservation: VNObservation, @unchecked Sendable {
    public let angle: CGFloat

    public init(
        requestRevision: Int,
        angle: CGFloat,
        confidence: VNConfidence,
        uuid: UUID = UUID()
    ) {
        self.angle = angle
        super.init(requestRevision: requestRevision, confidence: confidence, uuid: uuid)
    }
}

open class VNHumanObservation: VNDetectedObjectObservation, @unchecked Sendable {
    public let upperBodyOnly: Bool

    public init(
        requestRevision: Int,
        boundingBox: CGRect,
        upperBodyOnly: Bool,
        confidence: VNConfidence,
        uuid: UUID
    ) {
        self.upperBodyOnly = upperBodyOnly
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNFaceLandmarkRegion: NSObject, @unchecked Sendable {
    public let pointCount: Int

    public init(pointCount: Int) {
        self.pointCount = pointCount
        super.init()
    }

    public init?(coder: NSCoder) {
        return nil
    }
}

open class VNFaceLandmarkRegion2D: VNFaceLandmarkRegion, @unchecked Sendable {
    public let normalizedPoints: [CGPoint]
    public let precisionEstimatesPerPoint: [Float]?
    public let pointsClassification: VNPointsClassification

    public init(
        normalizedPoints: [CGPoint],
        precisionEstimatesPerPoint: [Float]? = nil,
        pointsClassification: VNPointsClassification = .disconnected
    ) {
        self.normalizedPoints = normalizedPoints
        self.precisionEstimatesPerPoint = precisionEstimatesPerPoint
        self.pointsClassification = pointsClassification
        super.init(pointCount: normalizedPoints.count)
    }

    public func pointsInImage(imageSize: CGSize) -> [CGPoint] {
        normalizedPoints.map { point in
            CGPoint(x: point.x * imageSize.width, y: point.y * imageSize.height)
        }
    }
}

open class VNFaceLandmarks: NSObject, @unchecked Sendable {
    public let confidence: VNConfidence

    public init(confidence: VNConfidence) {
        self.confidence = confidence
        super.init()
    }
}

open class VNFaceLandmarks2D: VNFaceLandmarks, @unchecked Sendable {
    public let allPoints: VNFaceLandmarkRegion2D?
    public let faceContour: VNFaceLandmarkRegion2D?
    public let innerLips: VNFaceLandmarkRegion2D?
    public let leftEye: VNFaceLandmarkRegion2D?
    public let leftEyebrow: VNFaceLandmarkRegion2D?
    public let leftPupil: VNFaceLandmarkRegion2D?
    public let medianLine: VNFaceLandmarkRegion2D?
    public let nose: VNFaceLandmarkRegion2D?
    public let noseCrest: VNFaceLandmarkRegion2D?
    public let outerLips: VNFaceLandmarkRegion2D?
    public let rightEye: VNFaceLandmarkRegion2D?
    public let rightEyebrow: VNFaceLandmarkRegion2D?
    public let rightPupil: VNFaceLandmarkRegion2D?

    public init(
        confidence: VNConfidence,
        allPoints: VNFaceLandmarkRegion2D? = nil,
        faceContour: VNFaceLandmarkRegion2D? = nil,
        innerLips: VNFaceLandmarkRegion2D? = nil,
        leftEye: VNFaceLandmarkRegion2D? = nil,
        leftEyebrow: VNFaceLandmarkRegion2D? = nil,
        leftPupil: VNFaceLandmarkRegion2D? = nil,
        medianLine: VNFaceLandmarkRegion2D? = nil,
        nose: VNFaceLandmarkRegion2D? = nil,
        noseCrest: VNFaceLandmarkRegion2D? = nil,
        outerLips: VNFaceLandmarkRegion2D? = nil,
        rightEye: VNFaceLandmarkRegion2D? = nil,
        rightEyebrow: VNFaceLandmarkRegion2D? = nil,
        rightPupil: VNFaceLandmarkRegion2D? = nil
    ) {
        self.allPoints = allPoints
        self.faceContour = faceContour
        self.innerLips = innerLips
        self.leftEye = leftEye
        self.leftEyebrow = leftEyebrow
        self.leftPupil = leftPupil
        self.medianLine = medianLine
        self.nose = nose
        self.noseCrest = noseCrest
        self.outerLips = outerLips
        self.rightEye = rightEye
        self.rightEyebrow = rightEyebrow
        self.rightPupil = rightPupil
        super.init(confidence: confidence)
    }
}
