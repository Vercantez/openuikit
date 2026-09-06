import Foundation

open class VNFaceLandmarkRegion: NSObject {
    public let pointCount: Int
    public let pointsClassification: VNPointsClassification

    public init(
        pointCount: Int,
        pointsClassification: VNPointsClassification = .closedPath
    ) {
        self.pointCount = pointCount
        self.pointsClassification = pointsClassification
        super.init()
    }
}

open class VNFaceLandmarkRegion2D: VNFaceLandmarkRegion {
    public let normalizedPoints: [CGPoint]
    public let precisionEstimatesPerPoint: [Float]?

    public init(
        normalizedPoints: [CGPoint],
        precisionEstimatesPerPoint: [Float]? = nil,
        pointsClassification: VNPointsClassification = .closedPath
    ) {
        self.normalizedPoints = normalizedPoints
        self.precisionEstimatesPerPoint = precisionEstimatesPerPoint
        super.init(pointCount: normalizedPoints.count, pointsClassification: pointsClassification)
    }

    public func pointsInImage(imageSize: CGSize) -> [CGPoint] {
        normalizedPoints.map {
            VNImagePointForNormalizedPoint($0, Int(imageSize.width), Int(imageSize.height))
        }
    }
}

open class VNFaceLandmarks: NSObject {
    public let confidence: VNConfidence

    public init(confidence: VNConfidence = 1) {
        self.confidence = max(0, min(1, confidence))
        super.init()
    }

    public required init?(coder: NSCoder) {
        confidence = Float(coder.decodeDouble(forKey: "confidence"))
        super.init()
    }
}

open class VNFaceLandmarks2D: VNFaceLandmarks {
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
        confidence: VNConfidence = 1,
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

    public required init?(coder: NSCoder) {
        allPoints = nil
        faceContour = nil
        innerLips = nil
        leftEye = nil
        leftEyebrow = nil
        leftPupil = nil
        medianLine = nil
        nose = nil
        noseCrest = nil
        outerLips = nil
        rightEye = nil
        rightEyebrow = nil
        rightPupil = nil
        super.init(coder: coder)
    }
}

open class VNRecognizedPoint: VNDetectedPoint {
    public let identifier: VNRecognizedPointKey

    public init(
        x: Double,
        y: Double,
        confidence: VNConfidence,
        identifier: VNRecognizedPointKey
    ) {
        self.identifier = identifier
        super.init(x: x, y: y, confidence: confidence)
    }

    public convenience init(
        location: CGPoint,
        confidence: VNConfidence,
        identifier: VNRecognizedPointKey
    ) {
        self.init(x: Double(location.x), y: Double(location.y), confidence: confidence, identifier: identifier)
    }

    public required init?(coder: NSCoder) {
        let raw = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? ?? ""
        identifier = VNRecognizedPointKey(rawValue: raw)
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(identifier.rawValue as NSString, forKey: "identifier")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        VNRecognizedPoint(x: x, y: y, confidence: confidence, identifier: identifier)
    }
}

open class VNPoint3D: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let position: simd_float4x4

    public init?(position: simd_float4x4) {
        self.position = position
        super.init()
    }

    public required init?(coder: NSCoder) {
        position = .identity
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Double(position.columns.3.x), forKey: "tx")
        coder.encode(Double(position.columns.3.y), forKey: "ty")
        coder.encode(Double(position.columns.3.z), forKey: "tz")
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        VNPoint3D(position: position) ?? VNPoint3D(position: .identity)!
    }
}

open class VNRecognizedPoint3D: VNPoint3D {
    public let identifier: VNRecognizedPointKey

    public init(position: simd_float4x4, identifier: VNRecognizedPointKey) {
        self.identifier = identifier
        super.init(position: position)!
    }

    public required init?(coder: NSCoder) {
        identifier = VNRecognizedPointKey(rawValue: "")
        super.init(coder: coder)
    }
}
