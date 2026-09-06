import Foundation

public typealias NormalizedRegion = ContoursObservation.Contour

func overlaySymbologyToVN(_ symbology: BarcodeSymbology) -> VNBarcodeSymbology {
    switch symbology {
    case .qr: return .qr
    case .code128: return .code128
    case .ean13: return .ean13
    case .ean8: return .ean8
    case .aztec: return .aztec
    case .pdf417: return .pdf417
    case .upce: return .upce
    case .codabar: return .codabar
    case .code39: return .code39
    case .code93: return .code93
    case .dataMatrix: return .dataMatrix
    case .i2of5: return .i2of5
    default: return VNBarcodeSymbology(rawValue: "VNBarcodeSymbology" + symbology.rawValue)
    }
}

func overlaySymbologyFromVN(_ symbology: VNBarcodeSymbology) -> BarcodeSymbology {
    if symbology == .qr { return .qr }
    if symbology == .code128 { return .code128 }
    if symbology == .ean13 { return .ean13 }
    if symbology == .ean8 { return .ean8 }
    if symbology == .aztec { return .aztec }
    if symbology == .pdf417 { return .pdf417 }
    if symbology == .upce { return .upce }
    if symbology == .codabar { return .codabar }
    if symbology == .code39 { return .code39 }
    if symbology == .code93 { return .code93 }
    if symbology == .dataMatrix { return .dataMatrix }
    if symbology == .i2of5 { return .i2of5 }
    return .qr
}

public struct DetectedObjectObservation: VisionObservation, BoundingBoxProviding {
    public var boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "DetectedObjectObservation \(boundingBox)" }

    public init(boundingBox: NormalizedRect) {
        self.boundingBox = boundingBox
        self.confidence = 1
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
    }

    public init(_ observation: VNDetectedObjectObservation) {
        self.boundingBox = NormalizedRect(normalizedRect: observation.boundingBox)
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }
}

public struct RectangleObservation: VisionObservation, QuadrilateralProviding, Codable {
    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "RectangleObservation" }
    public var boundingBox: NormalizedRect {
        let xs = [topLeft.x, topRight.x, bottomLeft.x, bottomRight.x]
        let ys = [topLeft.y, topRight.y, bottomLeft.y, bottomRight.y]
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        return NormalizedRect(x: minX, y: minY, width: (xs.max() ?? 0) - minX, height: (ys.max() ?? 0) - minY)
    }

    public init(
        topLeft: NormalizedPoint,
        topRight: NormalizedPoint,
        bottomRight: NormalizedPoint,
        bottomLeft: NormalizedPoint
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.confidence = 1
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
    }

    public init(_ observation: VNRectangleObservation) {
        self.topLeft = NormalizedPoint(normalizedPoint: observation.topLeft)
        self.topRight = NormalizedPoint(normalizedPoint: observation.topRight)
        self.bottomRight = NormalizedPoint(normalizedPoint: observation.bottomRight)
        self.bottomLeft = NormalizedPoint(normalizedPoint: observation.bottomLeft)
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }
}

public struct BarcodeObservation: VisionObservation, QuadrilateralProviding, Codable {
    public enum CompositeType: String, Codable, Hashable, Sendable {
        case linked, gs1TypeA, gs1TypeB, gs1TypeC
    }

    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint
    public let symbology: BarcodeSymbology
    public let payloadString: String?
    public let payloadData: Data?
    public let isGS1DataCarrier: Bool
    public let isColorInverted: Bool
    public let supplementalCompositeType: CompositeType?
    public let supplementalPayloadString: String?
    public let supplementalPayloadData: Data?
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { payloadString ?? "BarcodeObservation" }
    public var boundingBox: NormalizedRect { RectangleObservation(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft).boundingBox }
    public var boundingRegion: NormalizedRegion {
        ContoursObservation.Contour(
            points: [topLeft, topRight, bottomRight, bottomLeft],
            indexPath: IndexPath(index: 0)
        )
    }

    public init(_ observation: VNBarcodeObservation) {
        self.topLeft = NormalizedPoint(normalizedPoint: observation.topLeft)
        self.topRight = NormalizedPoint(normalizedPoint: observation.topRight)
        self.bottomRight = NormalizedPoint(normalizedPoint: observation.bottomRight)
        self.bottomLeft = NormalizedPoint(normalizedPoint: observation.bottomLeft)
        self.symbology = overlaySymbologyFromVN(observation.symbology)
        self.payloadString = observation.payloadStringValue
        self.payloadData = observation.payloadData
        self.isGS1DataCarrier = observation.isGS1DataCarrier
        self.isColorInverted = observation.isColorInverted
        self.supplementalCompositeType = overlayCompositeType(observation.supplementalCompositeType)
        self.supplementalPayloadString = observation.supplementalPayloadString
        self.supplementalPayloadData = observation.supplementalPayloadData
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(payloadString)
        hasher.combine(symbology)
        hasher.combine(topLeft)
        hasher.combine(confidence)
    }

    public static func == (a: BarcodeObservation, b: BarcodeObservation) -> Bool {
        a.uuid == b.uuid
            && a.payloadString == b.payloadString
            && a.symbology == b.symbology
            && a.topLeft == b.topLeft
            && a.topRight == b.topRight
            && a.bottomLeft == b.bottomLeft
            && a.bottomRight == b.bottomRight
    }
}

func overlayCompositeType(_ type: VNBarcodeCompositeType) -> BarcodeObservation.CompositeType? {
    switch type {
    case .linked: return .linked
    case .gs1TypeA: return .gs1TypeA
    case .gs1TypeB: return .gs1TypeB
    case .gs1TypeC: return .gs1TypeC
    case .none: return nil
    }
}

public struct ContoursObservation: VisionObservation, BoundingRegionProviding, Codable {
    public struct Contour: Hashable, Sendable, Codable, CustomStringConvertible {
        public var points: [NormalizedPoint]
        public var childContours: [Contour]
        public var indexPath: IndexPath
        public var pointCount: Int { points.count }
        public var description: String { "Contour(\(pointCount))" }
        public var normalizedPoints: [simd_float2] {
            points.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        }
        public var normalizedPath: CGPath { visionPath(from: normalizedPoints) }
        public var aspectRatio: Float {
            let box = boundingBox
            return box.height == 0 ? 0 : Float(box.width / box.height)
        }
        public var boundingBox: NormalizedRect {
            let xs = points.map(\.x)
            let ys = points.map(\.y)
            let minX = xs.min() ?? 0
            let minY = ys.min() ?? 0
            return NormalizedRect(x: minX, y: minY, width: (xs.max() ?? 0) - minX, height: (ys.max() ?? 0) - minY)
        }
        public var boundingQuad: RectangleObservation {
            let box = boundingBox
            return RectangleObservation(
                topLeft: NormalizedPoint(x: box.origin.x, y: box.origin.y + box.height),
                topRight: NormalizedPoint(x: box.origin.x + box.width, y: box.origin.y + box.height),
                bottomRight: NormalizedPoint(x: box.origin.x + box.width, y: box.origin.y),
                bottomLeft: NormalizedPoint(x: box.origin.x, y: box.origin.y)
            )
        }

        public init(points: [NormalizedPoint], indexPath: IndexPath, childContours: [Contour] = []) {
            self.points = points
            self.indexPath = indexPath
            self.childContours = childContours
        }

        public init(_ contour: VNContour) {
            self.points = contour.normalizedPoints.map { NormalizedPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
            self.indexPath = contour.indexPath
            self.childContours = contour.childContours.map(Contour.init)
        }

        public func calculateArea(useOrientedArea: Bool = false) -> Double {
            var area: Double = 0
            let vn = VNContour(normalizedPoints: normalizedPoints, indexPath: indexPath)
            try? VNGeometryUtils.calculateArea(&area, for: vn, orientedArea: useOrientedArea)
            return area
        }

        public func calculatePerimeter() -> Double {
            var perimeter: Double = 0
            let vn = VNContour(normalizedPoints: normalizedPoints, indexPath: indexPath)
            try? VNGeometryUtils.calculatePerimeter(&perimeter, for: vn)
            return perimeter
        }

        public func boundingCircle() -> NormalizedCircle {
            NormalizedCircle.boundingCircle(for: points)
        }

        public func polygonApproximation(epsilon: Float) throws -> Contour {
            let vn = try VNContour(normalizedPoints: normalizedPoints, indexPath: indexPath)
                .polygonApproximation(epsilon: epsilon)
            return Contour(vn)
        }
    }

    public let topLevelContours: [Contour]
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var contourCount: Int { topLevelContours.reduce(0) { $0 + 1 + $1.childContours.count } }
    public var description: String { "ContoursObservation \(contourCount)" }
    public var boundingRegion: NormalizedRegion {
        topLevelContours.first ?? Contour(points: [], indexPath: IndexPath(index: 0))
    }
    public var normalizedPath: CGPath {
        let path = CGPath()
        for contour in topLevelContours {
            guard let first = contour.points.first else { continue }
            path.move(to: CGPoint(x: first.x, y: first.y))
            for point in contour.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            path.closeSubpath()
        }
        return path
    }

    public init(_ observation: VNContoursObservation) {
        self.topLevelContours = observation.topLevelContours.map(Contour.init)
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }

    public func contourAtIndex(_ index: Int) -> Contour? {
        topLevelContours.indices.contains(index) ? topLevelContours[index] : nil
    }

    public func countourAtIndexPath(_ indexPath: IndexPath) -> Contour? {
        guard let first = indexPath.first, topLevelContours.indices.contains(first) else { return nil }
        return topLevelContours[first]
    }
}

public struct FeaturePrintObservation: VisionObservation {
    public let data: Data
    public let elementType: ElementType
    public let elementCount: Int
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "FeaturePrintObservation \(elementCount)" }

    public init(_ observation: VNFeaturePrintObservation) {
        self.data = observation.data
        self.elementType = observation.elementType == .double ? .double : .float
        self.elementCount = observation.elementCount
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }

    public func distance(to featurePrint: FeaturePrintObservation) throws -> Double {
        var value: Float = 0
        let lhs = VNFeaturePrintObservation(
            elementType: elementType == .double ? .double : .float,
            data: data
        )
        let rhs = VNFeaturePrintObservation(
            elementType: featurePrint.elementType == .double ? .double : .float,
            data: featurePrint.data
        )
        try lhs.computeDistance(&value, to: rhs)
        return Double(value)
    }
}

public struct TextObservation: VisionObservation, QuadrilateralProviding, Codable {
    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let characterBoxes: [RectangleObservation]?
    public var description: String { "TextObservation" }
    public var boundingBox: NormalizedRect {
        RectangleObservation(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft).boundingBox
    }

    public init(
        topLeft: NormalizedPoint,
        topRight: NormalizedPoint,
        bottomRight: NormalizedPoint,
        bottomLeft: NormalizedPoint,
        characterBoxes: [RectangleObservation]? = nil,
        confidence: Float = 1,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.characterBoxes = characterBoxes
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
    }

    public init(_ observation: VNTextObservation) {
        self.init(
            topLeft: NormalizedPoint(normalizedPoint: observation.topLeft),
            topRight: NormalizedPoint(normalizedPoint: observation.topRight),
            bottomRight: NormalizedPoint(normalizedPoint: observation.bottomRight),
            bottomLeft: NormalizedPoint(normalizedPoint: observation.bottomLeft),
            characterBoxes: observation.characterBoxes?.map(RectangleObservation.init),
            confidence: observation.confidence,
            uuid: observation.uuid,
            timeRange: observation.timeRange
        )
    }

    public static func == (a: TextObservation, b: TextObservation) -> Bool {
        a.uuid == b.uuid
            && a.topLeft == b.topLeft
            && a.characterBoxes?.count == b.characterBoxes?.count
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(topLeft)
        hasher.combine(confidence)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

public struct RecognizedText: Hashable, Sendable, Codable, CustomStringConvertible {
    public let string: String
    public let confidence: Float
    public var description: String { string }

    public init(string: String, confidence: Float) {
        self.string = string
        self.confidence = max(0, min(1, confidence))
    }

    public func boundingBox(for range: Range<String.Index>) -> RectangleObservation? {
        _ = range
        return nil
    }
}

public struct RecognizedTextObservation: VisionObservation, QuadrilateralProviding, Codable {
    public enum Direction: String, Hashable, Sendable, Codable {
        case leftToRight, rightToLeft, topToBottom, bottomToTop
    }

    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let textDirection: Direction?
    public let recognitionLanguages: [Locale.Language]
    public let shouldWrapToNextLine: Bool?
    public let isTitle: Bool
    private let candidates: [RecognizedText]
    public var description: String { transcript }
    public var transcript: String { candidates.first?.string ?? "" }
    public var boundingBox: NormalizedRect {
        RectangleObservation(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft).boundingBox
    }
    public var boundingRegion: NormalizedRegion {
        ContoursObservation.Contour(points: [topLeft, topRight, bottomRight, bottomLeft], indexPath: IndexPath(index: 0))
    }

    public init(
        topLeft: NormalizedPoint,
        topRight: NormalizedPoint,
        bottomRight: NormalizedPoint,
        bottomLeft: NormalizedPoint,
        candidates: [RecognizedText],
        textDirection: Direction? = .leftToRight,
        isTitle: Bool = false
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.candidates = candidates
        self.confidence = candidates.first?.confidence ?? 1
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.textDirection = textDirection
        self.recognitionLanguages = []
        self.shouldWrapToNextLine = nil
        self.isTitle = isTitle
    }

    public init(_ observation: VNRecognizedTextObservation) {
        self.topLeft = NormalizedPoint(normalizedPoint: observation.topLeft)
        self.topRight = NormalizedPoint(normalizedPoint: observation.topRight)
        self.bottomRight = NormalizedPoint(normalizedPoint: observation.bottomRight)
        self.bottomLeft = NormalizedPoint(normalizedPoint: observation.bottomLeft)
        self.candidates = observation.topCandidates(10).map {
            RecognizedText(string: $0.string, confidence: $0.confidence)
        }
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.textDirection = .leftToRight
        self.recognitionLanguages = []
        self.shouldWrapToNextLine = nil
        self.isTitle = false
    }

    public func topCandidates(_ maxCandidateCount: Int) -> [RecognizedText] {
        Array(candidates.prefix(max(0, maxCandidateCount)))
    }

    private enum CodingKeys: String, CodingKey {
        case topLeft, topRight, bottomRight, bottomLeft, confidence, uuid, timeRange
        case originatingRequestDescriptor, textDirection, shouldWrapToNextLine, isTitle, candidates
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topLeft = try container.decode(NormalizedPoint.self, forKey: .topLeft)
        topRight = try container.decode(NormalizedPoint.self, forKey: .topRight)
        bottomRight = try container.decode(NormalizedPoint.self, forKey: .bottomRight)
        bottomLeft = try container.decode(NormalizedPoint.self, forKey: .bottomLeft)
        confidence = try container.decode(Float.self, forKey: .confidence)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        timeRange = try container.decodeIfPresent(CMTimeRange.self, forKey: .timeRange)
        originatingRequestDescriptor = try container.decodeIfPresent(RequestDescriptor.self, forKey: .originatingRequestDescriptor)
        textDirection = try container.decodeIfPresent(Direction.self, forKey: .textDirection)
        shouldWrapToNextLine = try container.decodeIfPresent(Bool.self, forKey: .shouldWrapToNextLine)
        isTitle = try container.decode(Bool.self, forKey: .isTitle)
        candidates = try container.decode([RecognizedText].self, forKey: .candidates)
        recognitionLanguages = []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(topLeft, forKey: .topLeft)
        try container.encode(topRight, forKey: .topRight)
        try container.encode(bottomRight, forKey: .bottomRight)
        try container.encode(bottomLeft, forKey: .bottomLeft)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(timeRange, forKey: .timeRange)
        try container.encodeIfPresent(originatingRequestDescriptor, forKey: .originatingRequestDescriptor)
        try container.encodeIfPresent(textDirection, forKey: .textDirection)
        try container.encodeIfPresent(shouldWrapToNextLine, forKey: .shouldWrapToNextLine)
        try container.encode(isTitle, forKey: .isTitle)
        try container.encode(candidates, forKey: .candidates)
    }
}

public struct ClassificationObservation: VisionObservation {
    public let identifier: String
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { identifier }
    public var hasPrecisionRecallCurve: Bool { false }

    public init(identifier: String, confidence: Float) {
        self.identifier = identifier
        self.confidence = max(0, min(1, confidence))
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
    }

    public init(_ observation: VNClassificationObservation) {
        self.identifier = observation.identifier
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
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

public struct FaceObservation: VisionObservation, BoundingBoxProviding {
    public struct CaptureQuality: Hashable, Sendable, Codable, CustomStringConvertible {
        public let score: Float
        public let originatingRequestDescriptor: RequestDescriptor?
        public var description: String { "CaptureQuality \(score)" }
        public init(score: Float, originatingRequestDescriptor: RequestDescriptor? = nil) {
            self.score = score
            self.originatingRequestDescriptor = originatingRequestDescriptor
        }
    }

    public struct Landmarks2D: Hashable, Sendable, Codable, CustomStringConvertible {
        public struct Region: Hashable, Sendable, Codable, CustomStringConvertible {
            public enum PointsClassification: String, Hashable, Sendable, Codable {
                case closedPath, openPath, disconnected
            }

            public let points: [NormalizedPoint]
            public let pointsClassification: PointsClassification
            public let precisionEstimatesPerPoint: [Float]?
            public let originatingRequestDescriptor: RequestDescriptor?
            public var description: String { "Region(\(points.count))" }

            public init(
                points: [NormalizedPoint],
                pointsClassification: PointsClassification = .closedPath,
                precisionEstimatesPerPoint: [Float]? = nil,
                originatingRequestDescriptor: RequestDescriptor? = nil
            ) {
                self.points = points
                self.pointsClassification = pointsClassification
                self.precisionEstimatesPerPoint = precisionEstimatesPerPoint
                self.originatingRequestDescriptor = originatingRequestDescriptor
            }

            public func pointsInImageCoordinates(_ imageSize: CGSize, origin: CoordinateOrigin = .lowerLeft) -> [CGPoint] {
                points.map { $0.toImageCoordinates(imageSize, origin: origin) }
            }
        }

        public var allPoints: Region
        public var faceContour: Region
        public var innerLips: Region
        public var leftEye: Region
        public var leftEyebrow: Region
        public var leftPupil: Region
        public var medianLine: Region
        public var nose: Region
        public var noseCrest: Region
        public var outerLips: Region
        public var rightEye: Region
        public var rightEyebrow: Region
        public var rightPupil: Region
        public let originatingRequestDescriptor: RequestDescriptor?
        public var description: String { "Landmarks2D" }

        public init(
            allPoints: Region = Region(points: []),
            faceContour: Region = Region(points: []),
            innerLips: Region = Region(points: []),
            leftEye: Region = Region(points: []),
            leftEyebrow: Region = Region(points: []),
            leftPupil: Region = Region(points: []),
            medianLine: Region = Region(points: []),
            nose: Region = Region(points: []),
            noseCrest: Region = Region(points: []),
            outerLips: Region = Region(points: []),
            rightEye: Region = Region(points: []),
            rightEyebrow: Region = Region(points: []),
            rightPupil: Region = Region(points: []),
            originatingRequestDescriptor: RequestDescriptor? = nil
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
            self.originatingRequestDescriptor = originatingRequestDescriptor
        }
    }

    public var boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var landmarks: Landmarks2D?
    public var captureQuality: CaptureQuality?
    public let yaw: Measurement<UnitAngle>
    public let roll: Measurement<UnitAngle>
    public let pitch: Measurement<UnitAngle>
    public var description: String { "FaceObservation" }

    public init(boundingBox: NormalizedRect, revision: DetectFaceRectanglesRequest.Revision? = nil) {
        _ = revision
        self.boundingBox = boundingBox
        self.confidence = 1
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.landmarks = nil
        self.captureQuality = nil
        self.yaw = Measurement(value: 0, unit: .radians)
        self.roll = Measurement(value: 0, unit: .radians)
        self.pitch = Measurement(value: 0, unit: .radians)
    }

    public init(_ observation: VNFaceObservation) {
        self.boundingBox = NormalizedRect(normalizedRect: observation.boundingBox)
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        if let landmarks = observation.landmarks {
            func region(_ source: VNFaceLandmarkRegion2D?) -> Landmarks2D.Region {
                Landmarks2D.Region(
                    points: (source?.normalizedPoints ?? []).map { NormalizedPoint(normalizedPoint: $0) },
                    pointsClassification: {
                        switch source?.pointsClassification {
                        case .openPath: return .openPath
                        case .disconnected: return .disconnected
                        default: return .closedPath
                        }
                    }(),
                    precisionEstimatesPerPoint: source?.precisionEstimatesPerPoint
                )
            }
            self.landmarks = Landmarks2D(
                allPoints: region(landmarks.allPoints),
                faceContour: region(landmarks.faceContour),
                innerLips: region(landmarks.innerLips),
                leftEye: region(landmarks.leftEye),
                leftEyebrow: region(landmarks.leftEyebrow),
                leftPupil: region(landmarks.leftPupil),
                medianLine: region(landmarks.medianLine),
                nose: region(landmarks.nose),
                noseCrest: region(landmarks.noseCrest),
                outerLips: region(landmarks.outerLips),
                rightEye: region(landmarks.rightEye),
                rightEyebrow: region(landmarks.rightEyebrow),
                rightPupil: region(landmarks.rightPupil)
            )
        } else {
            self.landmarks = nil
        }
        if let quality = observation.faceCaptureQuality {
            self.captureQuality = CaptureQuality(score: quality.floatValue)
        } else {
            self.captureQuality = nil
        }
        self.yaw = Measurement(value: observation.yaw?.doubleValue ?? 0, unit: .radians)
        self.roll = Measurement(value: observation.roll?.doubleValue ?? 0, unit: .radians)
        self.pitch = Measurement(value: observation.pitch?.doubleValue ?? 0, unit: .radians)
    }
}

public struct HumanObservation: VisionObservation, BoundingBoxProviding, Codable {
    public let boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let isUpperBodyOnly: Bool
    public var description: String { "HumanObservation" }

    public init(
        boundingBox: NormalizedRect,
        revision: DetectHumanRectanglesRequest.Revision? = nil,
        isUpperBodyOnly: Bool = false,
        confidence: Float = 1,
        uuid: UUID = UUID()
    ) {
        _ = revision
        self.boundingBox = boundingBox
        self.isUpperBodyOnly = isUpperBodyOnly
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = nil
        self.originatingRequestDescriptor = revision.map { .detectHumanRectanglesRequest($0) }
    }

    public init(_ observation: VNHumanObservation) {
        self.boundingBox = NormalizedRect(normalizedRect: observation.boundingBox)
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.isUpperBodyOnly = observation.upperBodyOnly
    }
}

public struct HorizonObservation: VisionObservation {
    public var angle: Measurement<UnitAngle>
    public let transform: CGAffineTransform
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "HorizonObservation" }

    public init(angle: Measurement<UnitAngle>, transform: CGAffineTransform = .identity) {
        self.angle = angle
        self.transform = transform
        self.confidence = 1
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
    }

    public init(_ observation: VNHorizonObservation) {
        self.angle = Measurement(value: observation.angle, unit: .radians)
        self.transform = observation.transform
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }

    public func transform(for imageSize: CGSize) -> CGAffineTransform {
        visionHorizonCenteredTransform(
            angle: angle.value,
            width: Int(imageSize.width),
            height: Int(imageSize.height)
        )
    }
}

public struct SmudgeObservation: VisionObservation, Codable {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "SmudgeObservation" }

    public init(
        confidence: Float = 0,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil
    ) {
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
    }
}

public struct HumanBodyPoseObservation: VisionObservation, PoseProviding {
    public typealias PoseJointName = JointName
    public typealias PoseJointsGroupName = JointsGroupName

    public enum JointName: String, Hashable, Sendable, Codable, CaseIterable {
        case rightAnkle, rightElbow, rightWrist, leftShoulder, rightShoulder
        case neck, nose, root, leftEar, leftEye, leftHip, leftKnee
        case rightEar, rightEye, rightHip, leftAnkle, leftElbow, leftWrist, rightKnee
    }

    public enum JointsGroupName: String, Hashable, Sendable, Codable, CaseIterable {
        case face, torso, leftArm, leftLeg, rightArm, rightLeg
    }

    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let leftHand: HumanHandPoseObservation?
    public let rightHand: HumanHandPoseObservation?
    public var joints: [JointName: Joint]
    public var description: String { "HumanBodyPoseObservation" }
    public var availableJointNames: [JointName] { Array(joints.keys) }
    public var availableJointsGroupNames: [JointsGroupName] { JointsGroupName.allCases }
    public var keypoints: MLMultiArray {
        get throws {
            throw VisionError.invalidModel("Linux has no Apple pose keypoints array")
        }
    }

    public init(joints: [JointName: Joint] = [:], confidence: Float = 1) {
        self.confidence = confidence
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.leftHand = nil
        self.rightHand = nil
        self.joints = joints
    }

    public init(_ observation: VNHumanBodyPoseObservation) {
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.leftHand = nil
        self.rightHand = nil
        var mapped: [JointName: Joint] = [:]
        for name in JointName.allCases {
            let vnName = VNHumanBodyPoseObservation.JointName(rawValue: VNRecognizedPointKey(rawValue: overlayBodyKey(name)))
            if let point = try? observation.recognizedPoint(vnName) {
                mapped[name] = Joint(
                    location: NormalizedPoint(x: point.x, y: point.y),
                    confidence: point.confidence,
                    jointName: name.rawValue
                )
            }
        }
        self.joints = mapped
    }

    public func joint(for jointName: JointName) -> Joint? { joints[jointName] }

    public func allJoints(in groupName: JointsGroupName? = nil) -> [JointName: Joint] {
        guard let groupName else { return joints }
        let names: [JointName]
        switch groupName {
        case .face: names = [.nose, .leftEye, .rightEye, .leftEar, .rightEar]
        case .torso: names = [.root, .neck, .leftShoulder, .rightShoulder, .leftHip, .rightHip]
        case .leftArm: names = [.leftShoulder, .leftElbow, .leftWrist]
        case .rightArm: names = [.rightShoulder, .rightElbow, .rightWrist]
        case .leftLeg: names = [.leftHip, .leftKnee, .leftAnkle]
        case .rightLeg: names = [.rightHip, .rightKnee, .rightAnkle]
        }
        return joints.filter { names.contains($0.key) }
    }
}

private func overlayBodyKey(_ name: HumanBodyPoseObservation.JointName) -> String {
    switch name {
    case .leftAnkle: return VNRecognizedPointKey.bodyLandmarkKeyLeftAnkle.rawValue
    case .leftEar: return VNRecognizedPointKey.bodyLandmarkKeyLeftEar.rawValue
    case .leftElbow: return VNRecognizedPointKey.bodyLandmarkKeyLeftElbow.rawValue
    case .leftEye: return VNRecognizedPointKey.bodyLandmarkKeyLeftEye.rawValue
    case .leftHip: return VNRecognizedPointKey.bodyLandmarkKeyLeftHip.rawValue
    case .leftKnee: return VNRecognizedPointKey.bodyLandmarkKeyLeftKnee.rawValue
    case .leftShoulder: return VNRecognizedPointKey.bodyLandmarkKeyLeftShoulder.rawValue
    case .leftWrist: return VNRecognizedPointKey.bodyLandmarkKeyLeftWrist.rawValue
    case .neck: return VNRecognizedPointKey.bodyLandmarkKeyNeck.rawValue
    case .nose: return VNRecognizedPointKey.bodyLandmarkKeyNose.rawValue
    case .rightAnkle: return VNRecognizedPointKey.bodyLandmarkKeyRightAnkle.rawValue
    case .rightEar: return VNRecognizedPointKey.bodyLandmarkKeyRightEar.rawValue
    case .rightElbow: return VNRecognizedPointKey.bodyLandmarkKeyRightElbow.rawValue
    case .rightEye: return VNRecognizedPointKey.bodyLandmarkKeyRightEye.rawValue
    case .rightHip: return VNRecognizedPointKey.bodyLandmarkKeyRightHip.rawValue
    case .rightKnee: return VNRecognizedPointKey.bodyLandmarkKeyRightKnee.rawValue
    case .rightShoulder: return VNRecognizedPointKey.bodyLandmarkKeyRightShoulder.rawValue
    case .rightWrist: return VNRecognizedPointKey.bodyLandmarkKeyRightWrist.rawValue
    case .root: return VNRecognizedPointKey.bodyLandmarkKeyRoot.rawValue
    }
}

public struct HumanHandPoseObservation: VisionObservation, PoseProviding {
    public typealias PoseJointName = JointName
    public typealias PoseJointsGroupName = JointsGroupName

    public enum JointName: String, Hashable, Sendable, Codable, CaseIterable {
        case wrist, ringDIP, ringMCP, ringPIP, ringTip, thumbIP, thumbMP
        case indexDIP, indexMCP, indexPIP, indexTip, thumbCMC, thumbTip
        case littleDIP, littleMCP, littlePIP, littleTip
        case middleDIP, middleMCP, middlePIP, middleTip
    }

    public enum JointsGroupName: String, Hashable, Sendable, Codable, CaseIterable {
        case ringFinger, indexFinger, littleFinger, middleFinger, thumb
    }

    public enum Chirality: String, Hashable, Sendable, Codable {
        case left, right
    }

    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let chirality: Chirality
    public var joints: [JointName: Joint]
    public var description: String { "HumanHandPoseObservation" }
    public var availableJointNames: [JointName] { Array(joints.keys) }
    public var availableJointsGroupNames: [JointsGroupName] { JointsGroupName.allCases }
    public var keypoints: MLMultiArray {
        get throws {
            throw VisionError.invalidModel("Linux has no Apple hand keypoints array")
        }
    }

    public init(joints: [JointName: Joint] = [:], chirality: Chirality = .right, confidence: Float = 1) {
        self.confidence = confidence
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.chirality = chirality
        self.joints = joints
    }

    public init(_ observation: VNHumanHandPoseObservation) {
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.chirality = observation.chirality == .left ? .left : .right
        var mapped: [JointName: Joint] = [:]
        for name in JointName.allCases {
            let vn = VNHumanHandPoseObservation.JointName(rawValue: VNRecognizedPointKey(rawValue: "VNHumanHandPoseObservationJointName" + overlayHandSuffix(name)))
            if let point = try? observation.recognizedPoint(vn) {
                mapped[name] = Joint(location: NormalizedPoint(x: point.x, y: point.y), confidence: point.confidence, jointName: name.rawValue)
            }
        }
        self.joints = mapped
    }

    public func joint(for jointName: JointName) -> Joint? { joints[jointName] }

    public func allJoints(in groupName: JointsGroupName? = nil) -> [JointName: Joint] {
        guard let groupName else { return joints }
        let names: [JointName]
        switch groupName {
        case .thumb: names = [.wrist, .thumbCMC, .thumbMP, .thumbIP, .thumbTip]
        case .indexFinger: names = [.wrist, .indexMCP, .indexPIP, .indexDIP, .indexTip]
        case .middleFinger: names = [.wrist, .middleMCP, .middlePIP, .middleDIP, .middleTip]
        case .ringFinger: names = [.wrist, .ringMCP, .ringPIP, .ringDIP, .ringTip]
        case .littleFinger: names = [.wrist, .littleMCP, .littlePIP, .littleDIP, .littleTip]
        }
        return joints.filter { names.contains($0.key) }
    }
}

private func overlayHandSuffix(_ name: HumanHandPoseObservation.JointName) -> String {
    switch name {
    case .wrist: return "Wrist"
    case .thumbCMC: return "ThumbCMC"
    case .thumbMP: return "ThumbMP"
    case .thumbIP: return "ThumbIP"
    case .thumbTip: return "ThumbTip"
    case .indexMCP: return "IndexMCP"
    case .indexPIP: return "IndexPIP"
    case .indexDIP: return "IndexDIP"
    case .indexTip: return "IndexTip"
    case .middleMCP: return "MiddleMCP"
    case .middlePIP: return "MiddlePIP"
    case .middleDIP: return "MiddleDIP"
    case .middleTip: return "MiddleTip"
    case .ringMCP: return "RingMCP"
    case .ringPIP: return "RingPIP"
    case .ringDIP: return "RingDIP"
    case .ringTip: return "RingTip"
    case .littleMCP: return "LittleMCP"
    case .littlePIP: return "LittlePIP"
    case .littleDIP: return "LittleDIP"
    case .littleTip: return "LittleTip"
    }
}

public struct AnimalBodyPoseObservation: VisionObservation, PoseProviding {
    public typealias PoseJointName = JointName
    public typealias PoseJointsGroupName = JointsGroupName

    public enum JointName: String, Hashable, Sendable, Codable, CaseIterable {
        case leftEarTop, tailBottom, tailMiddle, leftBackPaw, rightEarTop
        case leftBackKnee, leftFrontPaw, rightBackPaw, leftBackElbow, leftEarBottom
        case leftEarMiddle, leftFrontKnee, rightBackKnee, rightFrontPaw, leftFrontElbow
        case rightBackElbow, rightEarBottom, rightEarMiddle, rightFrontKnee, rightFrontElbow
        case neck, nose, leftEye, tailTop, rightEye
    }

    public enum JointsGroupName: String, Hashable, Sendable, Codable, CaseIterable {
        case head, tail, trunk, forelegs, hindlegs
    }

    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var joints: [JointName: Joint]
    public var description: String { "AnimalBodyPoseObservation" }
    public var availableJointNames: [JointName] { Array(joints.keys) }
    public var availableJointsGroupNames: [JointsGroupName] { JointsGroupName.allCases }

    public init(joints: [JointName: Joint] = [:], confidence: Float = 1) {
        self.confidence = confidence
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.joints = joints
    }

    public init(_ observation: VNAnimalBodyPoseObservation) {
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        var mapped: [JointName: Joint] = [:]
        for name in JointName.allCases {
            let vn = VNAnimalBodyPoseObservation.JointName(
                rawValue: VNRecognizedPointKey(rawValue: "VNAnimalBodyPoseObservationJointName" + String(name.rawValue.prefix(1)).uppercased() + name.rawValue.dropFirst())
            )
            if let point = try? observation.recognizedPoint(vn) {
                mapped[name] = Joint(location: NormalizedPoint(x: point.x, y: point.y), confidence: point.confidence, jointName: name.rawValue)
            }
        }
        self.joints = mapped
    }

    public func joint(for jointName: JointName) -> Joint? { joints[jointName] }

    public func allJoints(in groupName: JointsGroupName? = nil) -> [JointName: Joint] {
        guard let groupName else { return joints }
        let names: [JointName]
        switch groupName {
        case .head:
            names = [.nose, .neck, .leftEye, .rightEye, .leftEarTop, .leftEarMiddle, .leftEarBottom, .rightEarTop, .rightEarMiddle, .rightEarBottom]
        case .tail: names = [.tailTop, .tailMiddle, .tailBottom]
        case .trunk: names = [.neck, .nose]
        case .forelegs: names = [.leftFrontElbow, .leftFrontKnee, .leftFrontPaw, .rightFrontElbow, .rightFrontKnee, .rightFrontPaw]
        case .hindlegs: names = [.leftBackElbow, .leftBackKnee, .leftBackPaw, .rightBackElbow, .rightBackKnee, .rightBackPaw]
        }
        return joints.filter { names.contains($0.key) }
    }
}

public struct HumanBodyPose3DObservation: VisionObservation {
    public enum JointName: String, Hashable, Sendable, Codable, CaseIterable {
        case centerHead, rightAnkle, rightElbow, rightWrist, leftShoulder, rightShoulder
        case centerShoulder, root, spine, leftHip, topHead, leftKnee, rightHip
        case leftAnkle, leftElbow, leftWrist, rightKnee
    }

    public enum JointsGroupName: String, Hashable, Sendable, Codable, CaseIterable {
        case head, torso, leftArm, leftLeg, rightArm, rightLeg
    }

    public enum EstimationTechnique: String, Hashable, Sendable, Codable {
        case measured, reference
    }

    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let bodyHeight: Float
    public let cameraOriginMatrix: simd_float4x4
    public let heightEstimationTechnique: EstimationTechnique
    public var joints: [JointName: Joint3D]
    public var imagePoints: [JointName: NormalizedPoint]
    public var description: String { "HumanBodyPose3DObservation" }
    public var availableJointNames: [JointName] { Array(joints.keys) }
    public var availableJointsGroupNames: [JointsGroupName] { JointsGroupName.allCases }

    public init(
        joints: [JointName: Joint3D] = [:],
        imagePoints: [JointName: NormalizedPoint] = [:],
        bodyHeight: Float = 0,
        heightEstimationTechnique: EstimationTechnique = .reference
    ) {
        self.confidence = 1
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.bodyHeight = bodyHeight
        self.cameraOriginMatrix = .identity
        self.heightEstimationTechnique = heightEstimationTechnique
        self.joints = joints
        self.imagePoints = imagePoints
    }

    public init(_ observation: VNHumanBodyPose3DObservation) {
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.bodyHeight = observation.bodyHeight
        self.cameraOriginMatrix = observation.cameraOriginMatrix
        self.heightEstimationTechnique = observation.heightEstimation == .measured ? .measured : .reference
        var mapped: [JointName: Joint3D] = [:]
        var images: [JointName: NormalizedPoint] = [:]
        for name in JointName.allCases {
            let vn = VNHumanBodyPose3DObservation.JointName(
                rawValue: VNRecognizedPointKey(rawValue: "VNHumanBodyPose3DObservationJointName" + String(name.rawValue.prefix(1)).uppercased() + name.rawValue.dropFirst())
            )
            if let point = try? observation.recognizedPoint(vn) {
                mapped[name] = Joint3D(
                    position: point.position,
                    localPosition: point.localPosition,
                    identifer: name.rawValue,
                    parentJoint: point.parentJoint.rawValue.rawValue
                )
            }
            if let image = try? observation.pointInImage(vn) {
                images[name] = NormalizedPoint(x: image.x, y: image.y)
            }
        }
        self.joints = mapped
        self.imagePoints = images
    }

    public func joint(for jointName: JointName) -> Joint3D? { joints[jointName] }

    public func allJoints(in groupName: JointsGroupName? = nil) -> [JointName: Joint3D] {
        guard let groupName else { return joints }
        let names: [JointName]
        switch groupName {
        case .head: names = [.topHead, .centerHead]
        case .torso: names = [.root, .spine, .centerShoulder, .leftHip, .rightHip]
        case .leftArm: names = [.leftShoulder, .leftElbow, .leftWrist]
        case .rightArm: names = [.rightShoulder, .rightElbow, .rightWrist]
        case .leftLeg: names = [.leftHip, .leftKnee, .leftAnkle]
        case .rightLeg: names = [.rightHip, .rightKnee, .rightAnkle]
        }
        return joints.filter { names.contains($0.key) }
    }

    public func pointInImage(for jointName: JointName) -> NormalizedPoint? { imagePoints[jointName] }

    public func parentJointName(for jointName: JointName) -> JointName {
        switch jointName {
        case .root: return .root
        case .spine: return .root
        case .centerShoulder: return .spine
        case .centerHead, .leftShoulder, .rightShoulder: return .centerShoulder
        case .topHead: return .centerHead
        case .leftElbow: return .leftShoulder
        case .leftWrist: return .leftElbow
        case .rightElbow: return .rightShoulder
        case .rightWrist: return .rightElbow
        case .leftHip, .rightHip: return .root
        case .leftKnee: return .leftHip
        case .leftAnkle: return .leftKnee
        case .rightKnee: return .rightHip
        case .rightAnkle: return .rightKnee
        }
    }

    public func cameraRelativePosition(for jointName: JointName) -> simd_float4x4 {
        joints[jointName]?.position ?? .identity
    }
}

public struct RecognizedObjectObservation: VisionObservation, BoundingBoxProviding {
    public var boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "RecognizedObjectObservation" }
}

public struct TrajectoryObservation: VisionObservation, Codable {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let detectedPoints: [NormalizedPoint]
    public let projectedPoints: [NormalizedPoint]
    public let equationCoefficients: SIMD3<Float>
    public let movingAverageRadius: CGFloat
    public var description: String { "TrajectoryObservation \(detectedPoints.count)" }

    public init(
        detectedPoints: [NormalizedPoint],
        projectedPoints: [NormalizedPoint] = [],
        equationCoefficients: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
        movingAverageRadius: CGFloat = 0,
        confidence: Float = 1,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil
    ) {
        self.detectedPoints = detectedPoints
        self.projectedPoints = projectedPoints
        self.equationCoefficients = equationCoefficients
        self.movingAverageRadius = movingAverageRadius
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
    }

    public init(_ observation: VNTrajectoryObservation) {
        self.detectedPoints = observation.detectedPoints.map { NormalizedPoint(x: $0.x, y: $0.y) }
        self.projectedPoints = observation.projectedPoints.map { NormalizedPoint(x: $0.x, y: $0.y) }
        self.equationCoefficients = observation.equationCoefficients
        self.movingAverageRadius = observation.movingAverageRadius
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }
}

public struct DocumentObservation: VisionObservation, Codable {
    public struct Container: Hashable, Sendable, Codable {
        public struct DataDetectorMatch: Hashable, Sendable, Codable {
            public var boundingRegion: NormalizedRegion
            public var match: DataDetector.Match

            public init(
                boundingRegion: NormalizedRegion,
                match: DataDetector.Match
            ) {
                self.boundingRegion = boundingRegion
                self.match = match
            }
        }

        public struct List: Hashable, Sendable, Codable {
            public enum Marker: String, Hashable, Sendable, Codable, CaseIterable {
                case lowercaseLatin, uppercaseLatin, compositeDecimal, decorativeDecimal, bullet, hyphen, decimal
            }

            public struct Item: Hashable, Sendable, Codable {
                public var itemString: String
                public var markerType: Marker?
                public var markerString: String
                public var content: DocumentObservation.Container

                public init(
                    itemString: String,
                    markerType: Marker? = nil,
                    markerString: String = "",
                    content: DocumentObservation.Container = DocumentObservation.Container()
                ) {
                    self.itemString = itemString
                    self.markerType = markerType
                    self.markerString = markerString
                    self.content = content
                }
            }

            public var boundingRegion: NormalizedRegion
            public var items: [Item]

            public init(
                boundingRegion: NormalizedRegion = ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)),
                items: [Item] = []
            ) {
                self.boundingRegion = boundingRegion
                self.items = items
            }
        }

        public struct Text: Hashable, Sendable, Codable {
            public enum Alignment: String, Hashable, Sendable, Codable {
                case center, leading, trailing
            }

            public var transcript: String
            public var detectedData: [DataDetectorMatch]
            public var textAlignment: Alignment?
            public var boundingRegion: NormalizedRegion
            public var lines: [RecognizedTextObservation]
            public var words: [RecognizedTextObservation]?

            public init(
                transcript: String = "",
                detectedData: [DataDetectorMatch] = [],
                textAlignment: Alignment? = .leading,
                boundingRegion: NormalizedRegion = ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)),
                lines: [RecognizedTextObservation] = [],
                words: [RecognizedTextObservation]? = nil
            ) {
                self.transcript = transcript
                self.detectedData = detectedData
                self.textAlignment = textAlignment
                self.boundingRegion = boundingRegion
                self.lines = lines
                self.words = words
            }

            public func boundingRegion(for range: Range<String.Index>) -> NormalizedRegion? {
                _ = range
                return boundingRegion
            }
        }

        public struct Table: Hashable, Sendable, Codable {
            public struct Cell: Hashable, Sendable, Codable {
                public var columnRange: ClosedRange<Int>
                public var rowRange: ClosedRange<Int>
                public var content: DocumentObservation.Container

                public init(
                    columnRange: ClosedRange<Int>,
                    rowRange: ClosedRange<Int>,
                    content: DocumentObservation.Container = DocumentObservation.Container()
                ) {
                    self.columnRange = columnRange
                    self.rowRange = rowRange
                    self.content = content
                }
            }

            public var boundingRegion: NormalizedRegion
            public var rows: [[Cell]]
            public var columns: [[Cell]]

            public init(
                boundingRegion: NormalizedRegion = ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)),
                rows: [[Cell]] = [],
                columns: [[Cell]] = []
            ) {
                self.boundingRegion = boundingRegion
                self.rows = rows
                self.columns = columns
            }

            public func cell(row: Int, col: Int) -> Cell? {
                guard rows.indices.contains(row), rows[row].indices.contains(col) else { return nil }
                return rows[row][col]
            }
        }

        public var boundingRegion: NormalizedRegion
        public var paragraphs: [Text]
        public var text: Text
        public var lists: [List]
        public var title: Text?
        public var tables: [Table]
        public var barcodes: [BarcodeObservation]

            public init(
                boundingRegion: NormalizedRegion = ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)),
                text: Text = Text(),
            paragraphs: [Text] = [],
            lists: [List] = [],
            title: Text? = nil,
            tables: [Table] = [],
            barcodes: [BarcodeObservation] = []
        ) {
            self.boundingRegion = boundingRegion
            self.text = text
            self.paragraphs = paragraphs
            self.lists = lists
            self.title = title
            self.tables = tables
            self.barcodes = barcodes
        }
    }

    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let document: Container
    public var description: String { document.text.transcript }

    public init(document: Container, confidence: Float = 1) {
        self.confidence = confidence
        self.uuid = UUID()
        self.timeRange = nil
        self.originatingRequestDescriptor = nil
        self.document = document
    }
}

public struct DetectedDocumentObservation: VisionObservation, QuadrilateralProviding, Codable {
    public var topLeft: NormalizedPoint
    public var topRight: NormalizedPoint
    public var bottomRight: NormalizedPoint
    public var bottomLeft: NormalizedPoint
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var globalSegmentationMask: PixelBufferObservation
    public var description: String { "DetectedDocumentObservation" }

    public init(
        topLeft: NormalizedPoint,
        topRight: NormalizedPoint,
        bottomRight: NormalizedPoint,
        bottomLeft: NormalizedPoint,
        confidence: Float = 1,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil,
        globalSegmentationMask: PixelBufferObservation = PixelBufferObservation()
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
        self.globalSegmentationMask = globalSegmentationMask
    }

    public init?(_ observation: VNRectangleObservation) {
        self.topLeft = NormalizedPoint(normalizedPoint: observation.topLeft)
        self.topRight = NormalizedPoint(normalizedPoint: observation.topRight)
        self.bottomRight = NormalizedPoint(normalizedPoint: observation.bottomRight)
        self.bottomLeft = NormalizedPoint(normalizedPoint: observation.bottomLeft)
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.globalSegmentationMask = PixelBufferObservation()
    }
}

public struct InstanceMaskObservation: VisionObservation, Codable {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let allInstances: IndexSet
    public let allInstancesMask: PixelBufferObservation
    public var description: String { "InstanceMaskObservation" }

    enum CodingKeys: String, CodingKey {
        case confidence, uuid, timeRange, originatingRequestDescriptor, allInstances
    }

    public init(
        instanceMask: CVPixelBuffer,
        confidence: Float = 1,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil
    ) {
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
        self.allInstances = visionInstanceLabels(in: instanceMask)
        self.allInstancesMask = PixelBufferObservation(
            confidence: confidence,
            uuid: uuid,
            timeRange: timeRange,
            originatingRequestDescriptor: originatingRequestDescriptor,
            pixelBuffer: instanceMask
        )
    }

    public init?(_ observation: VNInstanceMaskObservation) {
        self.init(
            instanceMask: observation.instanceMask,
            confidence: observation.confidence,
            uuid: observation.uuid,
            timeRange: observation.timeRange
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confidence = try container.decode(Float.self, forKey: .confidence)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        timeRange = try container.decodeIfPresent(CMTimeRange.self, forKey: .timeRange)
        originatingRequestDescriptor = try container.decodeIfPresent(
            RequestDescriptor.self,
            forKey: .originatingRequestDescriptor
        )
        let labels = try container.decode([Int].self, forKey: .allInstances)
        allInstances = IndexSet(labels)
        allInstancesMask = PixelBufferObservation(
            confidence: confidence,
            uuid: uuid,
            timeRange: timeRange,
            originatingRequestDescriptor: originatingRequestDescriptor
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(timeRange, forKey: .timeRange)
        try container.encodeIfPresent(originatingRequestDescriptor, forKey: .originatingRequestDescriptor)
        try container.encode(Array(allInstances), forKey: .allInstances)
    }

    public func generateMask(for instances: IndexSet) throws -> CVPixelBuffer {
        guard let buffer = allInstancesMask.pixelBuffer else {
            throw VisionError.invalidImage("instance mask is empty")
        }
        return try visionGenerateInstanceMask(buffer, instances: instances)
    }

    public func generateScaledMask(
        for instances: IndexSet,
        scaledToImageFrom requestHandler: ImageRequestHandler
    ) throws -> CVPixelBuffer {
        let mask = try generateMask(for: instances)
        let raster = requestHandler.inner.raster
        return visionScaleMask(mask, width: raster.width, height: raster.height)
    }

    public func generateMaskedImage(
        for instances: IndexSet,
        imageFrom requestHandler: ImageRequestHandler,
        croppedToInstancesExtent: Bool = false
    ) throws -> CVPixelBuffer {
        let mask = try generateMask(for: instances)
        return try visionApplyInstanceMask(
            mask,
            to: requestHandler.inner.raster.makePixelBuffer(),
            croppedToInstancesExtent: croppedToInstancesExtent
        )
    }

    public func instanceAtPoint(_ point: NormalizedPoint) -> IndexSet {
        guard let buffer = allInstancesMask.pixelBuffer, buffer.width > 0, buffer.height > 0 else {
            return IndexSet()
        }
        let x = min(buffer.width - 1, max(0, Int((point.x * CGFloat(buffer.width)).rounded(.down))))
        let yTop = 1 - point.y
        let y = min(buffer.height - 1, max(0, Int((yTop * CGFloat(buffer.height)).rounded(.down))))
        let label = Int(buffer.pixels[(y * buffer.width + x) * 4])
        return label > 0 ? IndexSet(integer: label) : IndexSet()
    }

    public static func == (lhs: InstanceMaskObservation, rhs: InstanceMaskObservation) -> Bool {
        lhs.uuid == rhs.uuid && lhs.allInstances == rhs.allInstances
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(Array(allInstances))
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

public struct PixelBufferObservation: VisionObservation, Codable {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let pixelBuffer: CVPixelBuffer?
    public var description: String {
        "PixelBufferObservation \(Int(size.width))x\(Int(size.height))"
    }
    public var pixelFormat: OSType { kCVPixelFormatType_32BGRA }
    public var size: CGSize {
        CGSize(width: CGFloat(pixelBuffer?.width ?? 0), height: CGFloat(pixelBuffer?.height ?? 0))
    }
    public var cgImage: CGImage {
        get throws {
            guard let buffer = pixelBuffer, buffer.width > 0, buffer.height > 0 else {
                throw VisionError.invalidImage("empty pixel buffer")
            }
            return CGImage(width: buffer.width, height: buffer.height, pixels: buffer.pixels)
        }
    }

    enum CodingKeys: String, CodingKey {
        case confidence, uuid, timeRange, originatingRequestDescriptor, width, height
    }

    public init(
        confidence: Float = 0,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil,
        pixelBuffer: CVPixelBuffer? = nil
    ) {
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
        self.pixelBuffer = pixelBuffer
    }

    public init?(_ observation: VNPixelBufferObservation) {
        self.init(
            confidence: observation.confidence,
            uuid: observation.uuid,
            timeRange: observation.timeRange,
            originatingRequestDescriptor: nil,
            pixelBuffer: observation.pixelBuffer
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        confidence = try container.decode(Float.self, forKey: .confidence)
        uuid = try container.decode(UUID.self, forKey: .uuid)
        timeRange = try container.decodeIfPresent(CMTimeRange.self, forKey: .timeRange)
        originatingRequestDescriptor = try container.decodeIfPresent(
            RequestDescriptor.self,
            forKey: .originatingRequestDescriptor
        )
        let width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
        let height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 0
        pixelBuffer = (width > 0 && height > 0) ? CVPixelBuffer(width: width, height: height) : nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(uuid, forKey: .uuid)
        try container.encodeIfPresent(timeRange, forKey: .timeRange)
        try container.encodeIfPresent(originatingRequestDescriptor, forKey: .originatingRequestDescriptor)
        try container.encode(pixelBuffer?.width ?? 0, forKey: .width)
        try container.encode(pixelBuffer?.height ?? 0, forKey: .height)
    }

    public func pixel(at point: NormalizedPoint) -> Float {
        guard let buffer = pixelBuffer, buffer.width > 0, buffer.height > 0 else { return 0 }
        let x = min(max(Int((point.x * CGFloat(buffer.width)).rounded(.down)), 0), buffer.width - 1)
        let y = min(max(Int(((1 - point.y) * CGFloat(buffer.height)).rounded(.down)), 0), buffer.height - 1)
        let index = (y * buffer.width + x) * 4
        guard index + 2 < buffer.pixels.count else { return 0 }
        let blue = Float(buffer.pixels[index])
        let green = Float(buffer.pixels[index + 1])
        let red = Float(buffer.pixels[index + 2])
        return (red + green + blue) / (3 * 255)
    }

    public func withUnsafePointer<R>(_ body: (UnsafeRawPointer) -> R) -> R {
        let pixels = pixelBuffer?.pixels ?? [0]
        return pixels.withUnsafeBytes { raw in
            body(raw.baseAddress!)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(confidence)
        hasher.combine(pixelBuffer?.width ?? 0)
        hasher.combine(pixelBuffer?.height ?? 0)
    }

    public static func == (lhs: PixelBufferObservation, rhs: PixelBufferObservation) -> Bool {
        lhs.uuid == rhs.uuid
            && lhs.confidence == rhs.confidence
            && lhs.pixelBuffer?.width == rhs.pixelBuffer?.width
            && lhs.pixelBuffer?.height == rhs.pixelBuffer?.height
    }
}

public struct SaliencyImageObservation: VisionObservation, Codable {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let salientObjects: [RectangleObservation]
    public let heatMap: PixelBufferObservation
    public var description: String { "SaliencyImageObservation" }

    public init(
        confidence: Float = 0,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil,
        salientObjects: [RectangleObservation] = [],
        heatMap: PixelBufferObservation = PixelBufferObservation()
    ) {
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
        self.salientObjects = salientObjects
        self.heatMap = heatMap
    }

    public init?(_ observation: VNSaliencyImageObservation) {
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.salientObjects = (observation.salientObjects ?? []).map(RectangleObservation.init)
        self.heatMap = PixelBufferObservation(observation) ?? PixelBufferObservation()
    }
}

public struct ImageAestheticsScoresObservation: VisionObservation, Codable {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let overallScore: Float
    public let isUtility: Bool
    public var description: String { "ImageAestheticsScoresObservation \(overallScore)" }

    public init(
        overallScore: Float = 0,
        isUtility: Bool = false,
        confidence: Float = 0,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil
    ) {
        self.overallScore = max(-1, min(1, overallScore))
        self.isUtility = isUtility
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
    }

    public init(_ observation: VNImageAestheticsScoresObservation) {
        self.init(
            overallScore: observation.overallScore,
            isUtility: observation.isUtility,
            confidence: observation.confidence,
            uuid: observation.uuid,
            timeRange: observation.timeRange
        )
    }
}

public struct OpticalFlowObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public let pixelBuffer: CVPixelBuffer?
    public var description: String { "OpticalFlowObservation" }

    public init(
        confidence: Float = 0,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil,
        pixelBuffer: CVPixelBuffer? = nil
    ) {
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
        self.pixelBuffer = pixelBuffer
    }

    public init?(_ observation: VNPixelBufferObservation) {
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
        self.pixelBuffer = observation.pixelBuffer
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(confidence)
    }

    public static func == (a: OpticalFlowObservation, b: OpticalFlowObservation) -> Bool {
        a.uuid == b.uuid && a.confidence == b.confidence
    }
}

public struct ImageTranslationAlignmentObservation: VisionObservation {
    public let alignmentTransform: CGAffineTransform
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "ImageTranslationAlignmentObservation" }
    public func applyTransform(to ciImage: CIImage) -> CIImage { ciImage }
    public init(_ observation: VNImageTranslationAlignmentObservation) {
        self.alignmentTransform = observation.alignmentTransform
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }
}

public struct ImageHomographicAlignmentObservation: VisionObservation {
    public var warpTransform: matrix_float3x3
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "ImageHomographicAlignmentObservation" }

    public init(
        warpTransform: matrix_float3x3 = .identity,
        confidence: Float = 0,
        uuid: UUID = UUID(),
        timeRange: CMTimeRange? = nil,
        originatingRequestDescriptor: RequestDescriptor? = nil
    ) {
        self.warpTransform = warpTransform
        self.confidence = confidence
        self.uuid = uuid
        self.timeRange = timeRange
        self.originatingRequestDescriptor = originatingRequestDescriptor
    }
}

public enum VisionResult: CustomStringConvertible {
    case trackObject(TrackObjectRequest, DetectedObjectObservation?)
    case classifyImage(ClassifyImageRequest, [ClassificationObservation])
    case detectHorizon(DetectHorizonRequest, HorizonObservation?)
    case recognizeText(RecognizeTextRequest, [RecognizedTextObservation])
    case detectBarcodes(DetectBarcodesRequest, [BarcodeObservation])
    case detectContours(DetectContoursRequest, ContoursObservation)
    case trackRectangle(TrackRectangleRequest, RectangleObservation?)
    case detectLensSmudge(DetectLensSmudgeRequest, SmudgeObservation)
    case detectRectangles(DetectRectanglesRequest, [RectangleObservation])
    case recognizeAnimals(RecognizeAnimalsRequest, [RecognizedObjectObservation])
    case trackOpticalFlow(TrackOpticalFlowRequest, OpticalFlowObservation?)
    case detectTrajectories(DetectTrajectoriesRequest, [TrajectoryObservation])
    case recognizeDocuments(RecognizeDocumentsRequest, [DocumentObservation])
    case detectFaceLandmarks(DetectFaceLandmarksRequest, [FaceObservation])
    case detectHumanBodyPose(DetectHumanBodyPoseRequest, [HumanBodyPoseObservation])
    case detectHumanHandPose(DetectHumanHandPoseRequest, [HumanHandPoseObservation])
    case detectAnimalBodyPose(DetectAnimalBodyPoseRequest, [AnimalBodyPoseObservation])
    case detectFaceRectangles(DetectFaceRectanglesRequest, [FaceObservation])
    case detectTextRectangles(DetectTextRectanglesRequest, [TextObservation])
    case detectHumanBodyPose3D(DetectHumanBodyPose3DRequest, [HumanBodyPose3DObservation])
    case detectHumanRectangles(DetectHumanRectanglesRequest, [HumanObservation])
    case detectFaceCaptureQuality(DetectFaceCaptureQualityRequest, [FaceObservation])
    case generateImageFeaturePrint(GenerateImageFeaturePrintRequest, FeaturePrintObservation)
    case detectDocumentSegmentation(DetectDocumentSegmentationRequest, DetectedDocumentObservation?)
    case generatePersonInstanceMask(GeneratePersonInstanceMaskRequest, InstanceMaskObservation?)
    case generatePersonSegmentation(GeneratePersonSegmentationRequest, PixelBufferObservation)
    case calculateImageAestheticsScores(CalculateImageAestheticsScoresRequest, ImageAestheticsScoresObservation)
    case generateForegroundInstanceMask(GenerateForegroundInstanceMaskRequest, InstanceMaskObservation?)
    case trackHomographicImageRegistration(TrackHomographicImageRegistrationRequest, ImageHomographicAlignmentObservation)
    case generateAttentionBasedSaliencyImage(GenerateAttentionBasedSaliencyImageRequest, SaliencyImageObservation)
    case trackTranslationalImageRegistration(TrackTranslationalImageRegistrationRequest, ImageTranslationAlignmentObservation)
    case generateObjectnessBasedSaliencyImage(GenerateObjectnessBasedSaliencyImageRequest, SaliencyImageObservation)
    case error(any VisionRequest, any Error)
    case coreML(CoreMLRequest, [any VisionObservation])
    public var description: String {
        switch self {
        case .detectBarcodes: return "detectBarcodes"
        case .detectContours: return "detectContours"
        case .detectRectangles: return "detectRectangles"
        case .generateImageFeaturePrint: return "generateImageFeaturePrint"
        case .classifyImage: return "classifyImage"
        case .recognizeText: return "recognizeText"
        case .detectFaceRectangles: return "detectFaceRectangles"
        case .detectHumanBodyPose: return "detectHumanBodyPose"
        case .detectHorizon: return "detectHorizon"
        case .detectLensSmudge: return "detectLensSmudge"
        case .recognizeAnimals: return "recognizeAnimals"
        case .detectTrajectories: return "detectTrajectories"
        case .recognizeDocuments: return "recognizeDocuments"
        case .detectFaceLandmarks: return "detectFaceLandmarks"
        case .detectHumanHandPose: return "detectHumanHandPose"
        case .detectAnimalBodyPose: return "detectAnimalBodyPose"
        case .detectTextRectangles: return "detectTextRectangles"
        case .detectHumanRectangles: return "detectHumanRectangles"
        case .detectFaceCaptureQuality: return "detectFaceCaptureQuality"
        case .detectDocumentSegmentation: return "detectDocumentSegmentation"
        case .generatePersonInstanceMask: return "generatePersonInstanceMask"
        case .generatePersonSegmentation: return "generatePersonSegmentation"
        case .calculateImageAestheticsScores: return "calculateImageAestheticsScores"
        case .generateForegroundInstanceMask: return "generateForegroundInstanceMask"
        case .generateAttentionBasedSaliencyImage: return "generateAttentionBasedSaliencyImage"
        case .generateObjectnessBasedSaliencyImage: return "generateObjectnessBasedSaliencyImage"
        case .detectHumanBodyPose3D: return "detectHumanBodyPose3D"
        case .coreML: return "coreML"
        case .trackObject: return "trackObject"
        case .trackRectangle: return "trackRectangle"
        case .trackOpticalFlow: return "trackOpticalFlow"
        case .trackHomographicImageRegistration: return "trackHomographicImageRegistration"
        case .trackTranslationalImageRegistration: return "trackTranslationalImageRegistration"
        case .error: return "error"
        }
    }
}

public final class ImageRequestHandler: @unchecked Sendable {
    let inner: VNImageRequestHandler

    public convenience init(_ imageURL: URL, orientation: CGImagePropertyOrientation? = nil) {
        self.init(handler: VNImageRequestHandler(url: imageURL, orientation: orientation ?? .up, options: [:]))
    }

    public convenience init(_ data: Data, orientation: CGImagePropertyOrientation? = nil) {
        self.init(handler: VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }

    public convenience init(_ image: CGImage, orientation: CGImagePropertyOrientation? = nil) {
        self.init(handler: VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }

    public convenience init(_ image: CIImage, orientation: CGImagePropertyOrientation? = nil) {
        self.init(handler: VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    public convenience init(
        _ pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData? = nil,
        orientation: CGImagePropertyOrientation? = nil
    ) {
        _ = depthData
        self.init(handler: VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation ?? .up,
            options: [:]
        ))
    }

    public convenience init(
        _ sampleBuffer: CMSampleBuffer,
        depthData: AVDepthData? = nil,
        orientation: CGImagePropertyOrientation? = nil
    ) {
        _ = depthData
        self.init(handler: VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: orientation ?? .up,
            options: [:]
        ))
    }

    init(handler: VNImageRequestHandler) {
        self.inner = handler
    }

    public func perform<T: VisionRequest>(_ request: T) async throws -> T.Result {
        try performNow(request)
    }

    @_spi(OpenUIKitHost)
    public func performNow<T: VisionRequest>(_ request: T) throws -> T.Result {
        if let imageRequest = request as? any ImageProcessingRequestBox {
            return try imageRequest.performBoxed(on: inner) as! T.Result
        }
        throw VisionError.unsupportedRequest("request type")
    }
}

protocol ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any
}

extension DetectBarcodesRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectRectanglesRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectContoursRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension GenerateImageFeaturePrintRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension RecognizeDocumentsRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension TrackOpticalFlowRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler) as Any
    }
}

extension DetectFaceRectanglesRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension RecognizeTextRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectLensSmudgeRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectFaceLandmarksRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectHumanRectanglesRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectFaceCaptureQualityRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectDocumentSegmentationRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler) as Any
    }
}

extension GeneratePersonInstanceMaskRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler) as Any
    }
}

extension GenerateForegroundInstanceMaskRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler) as Any
    }
}

extension CalculateImageAestheticsScoresRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension GenerateAttentionBasedSaliencyImageRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension GenerateObjectnessBasedSaliencyImageRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension DetectHorizonRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler) as Any
    }
}

extension TrackObjectRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler) as Any
    }
}

extension TrackHomographicImageRegistrationRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

extension TrackTranslationalImageRegistrationRequest: ImageProcessingRequestBox {
    func performBoxed(on handler: VNImageRequestHandler) throws -> Any {
        try performOnHandler(handler)
    }
}

public struct TargetedImageRequestHandler: @unchecked Sendable {}

public protocol PoseProviding {
    associatedtype PoseJointName: Decodable, Encodable, Hashable, RawRepresentable where PoseJointName.RawValue == String
    associatedtype PoseJointsGroupName: CaseIterable, RawRepresentable where PoseJointsGroupName.RawValue == String
    var availableJointNames: [PoseJointName] { get }
    var availableJointsGroupNames: [PoseJointsGroupName] { get }
    func joint(for jointName: PoseJointName) -> Joint?
    func allJoints(in groupName: PoseJointsGroupName?) -> [PoseJointName: Joint]
}

public struct Joint: Hashable, Sendable, Codable, CustomStringConvertible {
    public let location: NormalizedPoint
    public let confidence: Float
    public let jointName: String
    public var description: String { jointName }

    public init(location: NormalizedPoint, confidence: Float, jointName: String) {
        self.location = location
        self.confidence = confidence
        self.jointName = jointName
    }

    public func distance(to joint: Joint) -> CGFloat {
        let dx = location.x - joint.location.x
        let dy = location.y - joint.location.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

public struct Joint3D: Hashable, Sendable {
    public let position: simd_float4x4
    public let localPosition: simd_float4x4
    public let identifier: String
    public let parentJoint: String

    public init(position: simd_float4x4, localPosition: simd_float4x4, identifer: String, parentJoint: String) {
        self.position = position
        self.localPosition = localPosition
        self.identifier = identifer
        self.parentJoint = parentJoint
    }
}
