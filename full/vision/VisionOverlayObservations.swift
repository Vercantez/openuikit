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

public struct RectangleObservation: VisionObservation, QuadrilateralProviding {
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

public struct BarcodeObservation: VisionObservation, QuadrilateralProviding {
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
        self.supplementalCompositeType = nil
        self.supplementalPayloadString = observation.supplementalPayloadString
        self.supplementalPayloadData = observation.supplementalPayloadData
        self.confidence = observation.confidence
        self.uuid = observation.uuid
        self.timeRange = observation.timeRange
        self.originatingRequestDescriptor = nil
    }
}

public struct ContoursObservation: VisionObservation {
    public struct Contour: Hashable, Sendable, CustomStringConvertible {
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

public struct TextObservation: VisionObservation, QuadrilateralProviding {
    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "TextObservation" }
    public var boundingBox: NormalizedRect {
        RectangleObservation(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft).boundingBox
    }
}

public struct RecognizedText: Hashable, Sendable {
    public let string: String
    public let confidence: Float
}

public struct RecognizedTextObservation: VisionObservation, QuadrilateralProviding {
    public enum Direction: String, Hashable, Sendable { case leftToRight, rightToLeft, topToBottom, bottomToTop }
    public let topLeft: NormalizedPoint
    public let topRight: NormalizedPoint
    public let bottomRight: NormalizedPoint
    public let bottomLeft: NormalizedPoint
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "RecognizedTextObservation" }
    public var boundingBox: NormalizedRect {
        RectangleObservation(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft).boundingBox
    }
    public var boundingRegion: NormalizedRegion {
        ContoursObservation.Contour(points: [topLeft, topRight, bottomRight, bottomLeft], indexPath: IndexPath(index: 0))
    }
}

public struct ClassificationObservation: VisionObservation {
    public let identifier: String
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { identifier }
}

public struct FaceObservation: VisionObservation, BoundingBoxProviding {
    public struct CaptureQuality: Hashable, Sendable { public var value: Float }
    public struct Landmarks2D: Hashable, Sendable {
        public struct Region: Hashable, Sendable {
            public enum PointsClassification: String, Hashable, Sendable { case closedPath, openPath, disconnected }
            public var points: [NormalizedPoint]
        }
        public var allPoints: Region?
    }
    public var boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "FaceObservation" }
}

public struct HumanObservation: VisionObservation, BoundingBoxProviding {
    public var boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "HumanObservation" }
}

public struct HorizonObservation: VisionObservation {
    public var angle: Double
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "HorizonObservation" }
}

public struct SmudgeObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "SmudgeObservation" }
}

public struct HumanBodyPoseObservation: VisionObservation {
    public enum JointName: String, Hashable, Sendable { case nose, neck }
    public enum JointsGroupName: String, Hashable, Sendable { case all }
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "HumanBodyPoseObservation" }
}

public struct HumanHandPoseObservation: VisionObservation {
    public enum JointName: String, Hashable, Sendable { case wrist }
    public enum JointsGroupName: String, Hashable, Sendable { case all }
    public enum Chirality: String, Hashable, Sendable { case left, right }
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "HumanHandPoseObservation" }
}

public struct AnimalBodyPoseObservation: VisionObservation {
    public enum JointName: String, Hashable, Sendable { case head }
    public enum JointsGroupName: String, Hashable, Sendable { case all }
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "AnimalBodyPoseObservation" }
}

public struct HumanBodyPose3DObservation: VisionObservation {
    public enum JointName: String, Hashable, Sendable { case root }
    public enum JointsGroupName: String, Hashable, Sendable { case all }
    public enum EstimationTechnique: String, Hashable, Sendable { case lifted }
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "HumanBodyPose3DObservation" }
}

public struct RecognizedObjectObservation: VisionObservation, BoundingBoxProviding {
    public var boundingBox: NormalizedRect
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "RecognizedObjectObservation" }
}

public struct TrajectoryObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "TrajectoryObservation" }
}

public struct DocumentObservation: VisionObservation {
    public struct Container: Hashable, Sendable {
        public struct DataDetectorMatch: Hashable, Sendable { public var boundingRegion: NormalizedRegion { ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)) } }
        public struct List: Hashable, Sendable {
            public enum Marker: String, Hashable, Sendable { case disc }
            public struct Item: Hashable, Sendable {}
            public var boundingRegion: NormalizedRegion { ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)) }
        }
        public struct Text: Hashable, Sendable {
            public enum Alignment: String, Hashable, Sendable { case left, center, right }
            public var boundingRegion: NormalizedRegion { ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)) }
            public func boundingRegion(for range: Range<String.Index>) -> NormalizedRegion? { nil }
        }
        public struct Table: Hashable, Sendable {
            public struct Cell: Hashable, Sendable {}
            public var boundingRegion: NormalizedRegion { ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)) }
        }
        public var boundingRegion: NormalizedRegion { ContoursObservation.Contour(points: [], indexPath: IndexPath(index: 0)) }
    }
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "DocumentObservation" }
}

public struct DetectedDocumentObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "DetectedDocumentObservation" }
}

public struct InstanceMaskObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "InstanceMaskObservation" }
}

public struct PixelBufferObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "PixelBufferObservation" }
}

public struct SaliencyImageObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "SaliencyImageObservation" }
}

public struct ImageAestheticsScoresObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "ImageAestheticsScoresObservation" }
}

public struct OpticalFlowObservation: VisionObservation {
    public let confidence: Float
    public let uuid: UUID
    public let timeRange: CMTimeRange?
    public let originatingRequestDescriptor: RequestDescriptor?
    public var description: String { "OpticalFlowObservation" }
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
    public var description: String { String(describing: self) }
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
        if var imageRequest = request as? any ImageProcessingRequestBox {
            return try await imageRequest.performBoxed(on: inner) as! T.Result
        }
        throw VisionError.unsupportedRequest("request type")
    }
}

protocol ImageProcessingRequestBox {
    mutating func performBoxed(on handler: VNImageRequestHandler) async throws -> Any
}

extension DetectBarcodesRequest: ImageProcessingRequestBox {
    mutating func performBoxed(on handler: VNImageRequestHandler) async throws -> Any {
        try await performOnHandler(handler)
    }
}

extension DetectRectanglesRequest: ImageProcessingRequestBox {
    mutating func performBoxed(on handler: VNImageRequestHandler) async throws -> Any {
        try await performOnHandler(handler)
    }
}

extension DetectContoursRequest: ImageProcessingRequestBox {
    mutating func performBoxed(on handler: VNImageRequestHandler) async throws -> Any {
        try await performOnHandler(handler)
    }
}

extension GenerateImageFeaturePrintRequest: ImageProcessingRequestBox {
    mutating func performBoxed(on handler: VNImageRequestHandler) async throws -> Any {
        try await performOnHandler(handler)
    }
}

public struct TargetedImageRequestHandler: @unchecked Sendable {}

public protocol PoseProviding {}
public protocol Joint {}
public protocol Joint3D {}
