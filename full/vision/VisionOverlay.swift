import Foundation

public enum CoordinateOrigin: Hashable, Sendable {
    case lowerLeft
    case upperLeft
}

public enum ComputeStage: String, Codable, Hashable, Sendable {
    case main
    case postProcessing
}

public enum ElementType: String, Codable, Hashable, Sendable {
    case float
    case double
}

public enum ImageCropAndScaleAction: String, Codable, Hashable, Sendable, CaseIterable {
    case centerCrop
    case scaleToFit
    case scaleToFill
    case scaleToFitPlus90CCWRotation
    case scaleToFillPlus90CCWRotation
}

public enum Chirality: String, Codable, Hashable, Sendable {
    case left
    case right
}

public enum BarcodeSymbology: String, Codable, Hashable, Sendable, CaseIterable {
    case aztec, codabar, code128, code39, code39Checksum, code39FullASCII
    case code39FullASCIIChecksum, code93, code93i, dataMatrix, ean13, ean8
    case gs1DataBar, gs1DataBarExpanded, gs1DataBarLimited, i2of5, i2of5Checksum
    case itf14, msiPlessey, microPDF417, microQR, pdf417, qr, upce
}

public protocol BoundingBoxProviding {
    var boundingBox: NormalizedRect { get }
}

public protocol BoundingRegionProviding {
    var boundingRegion: NormalizedRegion { get }
}

public protocol QuadrilateralProviding: BoundingBoxProviding {
    var bottomLeft: NormalizedPoint { get }
    var bottomRight: NormalizedPoint { get }
    var topLeft: NormalizedPoint { get }
    var topRight: NormalizedPoint { get }
}

public protocol VisionObservation: CustomStringConvertible, Hashable, Sendable {
    var confidence: Float { get }
    var originatingRequestDescriptor: RequestDescriptor? { get }
    var uuid: UUID { get }
    var timeRange: CMTimeRange? { get }
}

public protocol VisionRequest: CustomStringConvertible, Hashable, Sendable {
    associatedtype Result
    var descriptor: RequestDescriptor { get }
    func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice?
    mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage)
}

public protocol ImageProcessingRequest: VisionRequest {
    var regionOfInterest: NormalizedRect { get set }
    func perform(on url: URL, orientation: CGImagePropertyOrientation?) async throws -> Self.Result
    func perform(on data: Data, orientation: CGImagePropertyOrientation?) async throws -> Self.Result
    func perform(on image: CGImage, orientation: CGImagePropertyOrientation?) async throws -> Self.Result
    func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation?) async throws -> Self.Result
    func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation?) async throws -> Self.Result
    func perform(on image: CIImage, orientation: CGImagePropertyOrientation?) async throws -> Self.Result
}

public protocol StatefulRequest: VisionRequest {
    var frameAnalysisSpacing: CMTime { get }
    var minimumLatencyFrameCount: Int { get }
}

public protocol TargetedRequest: VisionRequest {}

public struct NormalizedPoint: Codable, Hashable, Sendable, CustomStringConvertible {
    public let cgPoint: CGPoint
    public var x: CGFloat { cgPoint.x }
    public var y: CGFloat { cgPoint.y }
    public var description: String { "(\(x), \(y))" }
    public static var zero: NormalizedPoint { NormalizedPoint(x: 0, y: 0) }
    public init(normalizedPoint: CGPoint) { self.cgPoint = normalizedPoint }
    public init(x: CGFloat, y: CGFloat) { self.cgPoint = CGPoint(x: x, y: y) }
    public init(imagePoint: CGPoint, in imageSize: CGSize) {
        self.cgPoint = VNNormalizedPointForImagePoint(imagePoint, Int(imageSize.width), Int(imageSize.height))
    }
    public init(imagePoint: CGPoint, in imageSize: CGSize, normalizedTo regionOfInterest: NormalizedRect) {
        self.cgPoint = VNNormalizedPointForImagePointUsingRegionOfInterest(
            imagePoint, Int(imageSize.width), Int(imageSize.height), regionOfInterest.cgRect
        )
    }
    public func verticallyFlipped() -> NormalizedPoint { NormalizedPoint(x: x, y: 1 - y) }
    public func toImageCoordinates(_ imageSize: CGSize, origin: CoordinateOrigin = .lowerLeft) -> CGPoint {
        var point = VNImagePointForNormalizedPoint(cgPoint, Int(imageSize.width), Int(imageSize.height))
        if origin == .upperLeft { point.y = imageSize.height - point.y }
        return point
    }
    public func toImageCoordinates(from regionOfInterest: NormalizedRect, imageSize: CGSize, origin: CoordinateOrigin = .lowerLeft) -> CGPoint {
        var point = VNImagePointForNormalizedPointUsingRegionOfInterest(
            cgPoint, Int(imageSize.width), Int(imageSize.height), regionOfInterest.cgRect
        )
        if origin == .upperLeft { point.y = imageSize.height - point.y }
        return point
    }

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        self.cgPoint = CGPoint(x: x, y: y)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

public struct NormalizedRect: Codable, Hashable, Sendable, CustomStringConvertible {
    public let cgRect: CGRect
    public var width: CGFloat { cgRect.width }
    public var height: CGFloat { cgRect.height }
    public var origin: CGPoint { cgRect.origin }
    public var description: String { "\(cgRect)" }
    public static var fullImage: NormalizedRect { NormalizedRect(normalizedRect: VNNormalizedIdentityRect) }
    public init(normalizedRect: CGRect) { self.cgRect = normalizedRect }
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.cgRect = CGRect(x: x, y: y, width: width, height: height)
    }
    public init(imageRect: CGRect, in imageSize: CGSize) {
        self.cgRect = VNNormalizedRectForImageRect(imageRect, Int(imageSize.width), Int(imageSize.height))
    }
    public init(imageRect: CGRect, in imageSize: CGSize, normalizedTo regionOfInterest: NormalizedRect) {
        self.cgRect = VNNormalizedRectForImageRectUsingRegionOfInterest(
            imageRect, Int(imageSize.width), Int(imageSize.height), regionOfInterest.cgRect
        )
    }
    public func verticallyFlipped() -> NormalizedRect {
        NormalizedRect(x: cgRect.origin.x, y: 1 - cgRect.origin.y - cgRect.height, width: cgRect.width, height: cgRect.height)
    }
    public func toImageCoordinates(_ imageSize: CGSize, origin: CoordinateOrigin = .lowerLeft) -> CGRect {
        var rect = VNImageRectForNormalizedRect(cgRect, Int(imageSize.width), Int(imageSize.height))
        if origin == .upperLeft { rect.origin.y = imageSize.height - rect.origin.y - rect.height }
        return rect
    }
    public func toImageCoordinates(from regionOfInterest: NormalizedRect, imageSize: CGSize, origin: CoordinateOrigin = .lowerLeft) -> CGRect {
        var rect = VNImageRectForNormalizedRectUsingRegionOfInterest(
            cgRect, Int(imageSize.width), Int(imageSize.height), regionOfInterest.cgRect
        )
        if origin == .upperLeft { rect.origin.y = imageSize.height - rect.origin.y - rect.height }
        return rect
    }

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(CGFloat.self)
        let y = try container.decode(CGFloat.self)
        let width = try container.decode(CGFloat.self)
        let height = try container.decode(CGFloat.self)
        self.cgRect = CGRect(x: x, y: y, width: width, height: height)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(cgRect.origin.x)
        try container.encode(cgRect.origin.y)
        try container.encode(cgRect.width)
        try container.encode(cgRect.height)
    }
}

public struct NormalizedCircle: Hashable, Sendable {
    public let center: NormalizedPoint
    public let radius: CGFloat
    public static var zero: NormalizedCircle { NormalizedCircle(center: .zero, radius: 0) }
    public init(center: NormalizedPoint, radius: CGFloat) {
        self.center = center
        self.radius = radius
    }
    public static func boundingCircle(for points: [NormalizedPoint]) -> NormalizedCircle {
        let vn = points.map { VNPoint(x: Double($0.x), y: Double($0.y)) }
        let circle = (try? VNGeometryUtils.boundingCircle(for: vn)) ?? .zero
        return NormalizedCircle(center: NormalizedPoint(x: circle.center.x, y: circle.center.y), radius: circle.radius)
    }
    public func contains(_ point: NormalizedPoint) -> Bool {
        VNCircle(center: VNPoint(x: Double(center.x), y: Double(center.y)), radius: Double(radius))
            .contains(VNPoint(x: Double(point.x), y: Double(point.y)))
    }
    public func contains(_ point: NormalizedPoint, inCircumferentialRingOfWidth ringWidth: CGFloat) -> Bool {
        VNCircle(center: VNPoint(x: Double(center.x), y: Double(center.y)), radius: Double(radius))
            .contains(VNPoint(x: Double(point.x), y: Double(point.y)), inCircumferentialRingOfWidth: Double(ringWidth))
    }
}

public enum VisionError: Error, CustomStringConvertible, LocalizedError {
    case outOfBoundsError(String)
    case ioError(String)
    case internalError(String)
    case outOfMemory(String)
    case invalidImage(String)
    case invalidModel(String)
    case invalidFormat(String)
    case dataUnavailable(String)
    case invalidArgument(String)
    case operationFailed(String)
    case invalidOperation(String)
    case requestCancelled(String)
    case timeStampNotFound(String)
    case unsupportedRequest(String)
    case unsupportedRevision(String)
    case unsupportedComputeStage(String)
    case unsupportedComputeDevice(String)
    case pixelBufferCreationFailed(CVReturn)
    case timeout(String)
    public var description: String { errorDescription ?? "VisionError" }
    public var errorDescription: String? {
        switch self {
        case .outOfBoundsError(let s), .ioError(let s), .internalError(let s), .outOfMemory(let s),
             .invalidImage(let s), .invalidModel(let s), .invalidFormat(let s), .dataUnavailable(let s),
             .invalidArgument(let s), .operationFailed(let s), .invalidOperation(let s),
             .requestCancelled(let s), .timeStampNotFound(let s), .unsupportedRequest(let s),
             .unsupportedRevision(let s), .unsupportedComputeStage(let s), .unsupportedComputeDevice(let s),
             .timeout(let s):
            return s
        case .pixelBufferCreationFailed(let code):
            return "pixel buffer \(code)"
        }
    }
    public var failureReason: String? { errorDescription }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

func visionNSErrorToVisionError(_ error: Error) -> VisionError {
    let ns = error as NSError
    guard ns.domain == VNErrorDomain else { return .operationFailed(ns.localizedDescription) }
    let message = ns.localizedDescription
    switch VNErrorCode(rawValue: ns.code) {
    case .requestCancelled: return .requestCancelled(message)
    case .invalidFormat: return .invalidFormat(message)
    case .operationFailed: return .operationFailed(message)
    case .outOfBoundsError: return .outOfBoundsError(message)
    case .ioError: return .ioError(message)
    case .internalError: return .internalError(message)
    case .outOfMemory: return .outOfMemory(message)
    case .invalidImage: return .invalidImage(message)
    case .invalidArgument: return .invalidArgument(message)
    case .invalidModel: return .invalidModel(message)
    case .unsupportedRevision: return .unsupportedRevision(message)
    case .dataUnavailable: return .dataUnavailable(message)
    case .timeStampNotFound: return .timeStampNotFound(message)
    case .unsupportedRequest: return .unsupportedRequest(message)
    case .timeout: return .timeout(message)
    case .unsupportedComputeStage: return .unsupportedComputeStage(message)
    case .unsupportedComputeDevice: return .unsupportedComputeDevice(message)
    default: return .operationFailed(message)
    }
}

public enum RequestDescriptor: Codable, Hashable, Sendable, CustomStringConvertible {
    case detectBarcodesRequest(DetectBarcodesRequest.Revision)
    case detectRectanglesRequest(DetectRectanglesRequest.Revision)
    case detectContoursRequest(DetectContoursRequest.Revision)
    case generateImageFeaturePrintRequest(GenerateImageFeaturePrintRequest.Revision)
    case classifyImageRequest(ClassifyImageRequest.Revision)
    case recognizeTextRequest(RecognizeTextRequest.Revision)
    case detectFaceRectanglesRequest(DetectFaceRectanglesRequest.Revision)
    case detectHumanBodyPoseRequest(DetectHumanBodyPoseRequest.Revision)
    case detectHorizonRequest(DetectHorizonRequest.Revision)
    case detectLensSmudgeRequest(DetectLensSmudgeRequest.Revision)
    case recognizeAnimalsRequest(RecognizeAnimalsRequest.Revision)
    case detectTrajectoriesRequest(DetectTrajectoriesRequest.Revision)
    case recognizeDocumentsRequest(RecognizeDocumentsRequest.Revision)
    case detectFaceLandmarksRequest(DetectFaceLandmarksRequest.Revision)
    case detectHumanHandPoseRequest(DetectHumanHandPoseRequest.Revision)
    case detectAnimalBodyPoseRequest(DetectAnimalBodyPoseRequest.Revision)
    case detectTextRectanglesRequest(DetectTextRectanglesRequest.Revision)
    case detectHumanRectanglesRequest(DetectHumanRectanglesRequest.Revision)
    case detectFaceCaptureQualityRequest(DetectFaceCaptureQualityRequest.Revision)
    case detectDocumentSegmentationRequest(DetectDocumentSegmentationRequest.Revision)
    case generatePersonInstanceMaskRequest(GeneratePersonInstanceMaskRequest.Revision)
    case generatePersonSegmentationRequest(GeneratePersonSegmentationRequest.Revision)
    case calculateImageAestheticsScoresRequest(CalculateImageAestheticsScoresRequest.Revision)
    case generateForegroundInstanceMaskRequest(GenerateForegroundInstanceMaskRequest.Revision)
    case generateAttentionBasedSaliencyImageRequest(GenerateAttentionBasedSaliencyImageRequest.Revision)
    case generateObjectnessBasedSaliencyImageRequest(GenerateObjectnessBasedSaliencyImageRequest.Revision)
    case detectHumanBodyPose3DRequest(DetectHumanBodyPose3DRequest.Revision)
    case coreMLRequest(CoreMLRequest.Revision)
    case trackObjectRequest(TrackObjectRequest.Revision)
    case trackRectangleRequest(TrackRectangleRequest.Revision)
    case trackOpticalFlowRequest(TrackOpticalFlowRequest.Revision)
    case trackHomographicImageRegistrationRequest(TrackHomographicImageRegistrationRequest.Revision)
    case trackTranslationalImageRegistrationRequest(TrackTranslationalImageRegistrationRequest.Revision)
    public var description: String { String(describing: self) }
}



public struct DetectBarcodesRequest: ImageProcessingRequest {
    public typealias Result = [BarcodeObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision4
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public var symbologies: [BarcodeSymbology] = BarcodeSymbology.allCases
    public var coalescesCompositeSymbologies: Bool = false
    public var supportedSymbologies: [BarcodeSymbology] { BarcodeSymbology.allCases }
    public static let supportedRevisions: [Revision] = [.revision4]
    public var descriptor: RequestDescriptor { .detectBarcodesRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision4 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        let request = VNDetectBarcodesRequest()
        request.symbologies = symbologies.map { overlaySymbologyToVN($0) }
        request.coalesceCompositeSymbologies = coalescesCompositeSymbologies
        request.regionOfInterest = regionOfInterest.cgRect
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0 as? VNBarcodeObservation }.map(BarcodeObservation.init)

    }
}

public struct DetectRectanglesRequest: ImageProcessingRequest {
    public typealias Result = [RectangleObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public var minimumSize: Float = 0.2
    public var minimumConfidence: Float = 0
    public var maximumAspectRatio: Float = 1
    public var minimumAspectRatio: Float = 0.5
    public var maximumObservations: Int = 8
    public var quadratureToleranceDegrees: Float = 30
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectRectanglesRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        let request = VNDetectRectanglesRequest()
        request.minimumSize = minimumSize
        request.minimumConfidence = minimumConfidence
        request.maximumAspectRatio = maximumAspectRatio
        request.minimumAspectRatio = minimumAspectRatio
        request.maximumObservations = maximumObservations
        request.quadratureTolerance = quadratureToleranceDegrees
        request.regionOfInterest = regionOfInterest.cgRect
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0 as? VNRectangleObservation }.map(RectangleObservation.init)

    }
}

public struct DetectContoursRequest: ImageProcessingRequest {
    public typealias Result = ContoursObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public var contrastPivot: Float? = 0.5
    public var contrastAdjustment: Float = 2
    public var detectsDarkOnLight: Bool = true
    public var maximumImageDimension: Int = 512
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectContoursRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        let request = VNDetectContoursRequest()
        request.contrastPivot = contrastPivot.map { NSNumber(value: $0) }
        request.contrastAdjustment = contrastAdjustment
        request.detectsDarkOnLight = detectsDarkOnLight
        request.maximumImageDimension = maximumImageDimension
        request.regionOfInterest = regionOfInterest.cgRect
        try handler.perform([request])
        guard let obs = request.results?.first as? VNContoursObservation else {
            return ContoursObservation(VNContoursObservation(topLevelContours: []))
        }
        return ContoursObservation(obs)

    }
}

public struct GenerateImageFeaturePrintRequest: ImageProcessingRequest {
    public typealias Result = FeaturePrintObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision2
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public var cropAndScaleAction: ImageCropAndScaleAction = .scaleToFill
    public static let supportedRevisions: [Revision] = [.revision2]
    public var descriptor: RequestDescriptor { .generateImageFeaturePrintRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision2 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        let request = VNGenerateImageFeaturePrintRequest()
        request.regionOfInterest = regionOfInterest.cgRect
        try handler.perform([request])
        guard let obs = request.results?.first as? VNFeaturePrintObservation else {
            throw VisionError.operationFailed("missing feature print")
        }
        return FeaturePrintObservation(obs)

    }
}

public struct ClassifyImageRequest: ImageProcessingRequest {
    public typealias Result = [ClassificationObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision2
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision2]
    public var descriptor: RequestDescriptor { .classifyImageRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision2 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct RecognizeTextRequest: ImageProcessingRequest {
    public typealias Result = [RecognizedTextObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision3
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public enum RecognitionLevel: Int, Codable, Hashable, Sendable, CaseIterable, Comparable {
        case accurate = 0
        case fast = 1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public var recognitionLevel: RecognizeTextRequest.RecognitionLevel = .accurate
    public var usesLanguageCorrection: Bool = true
    public var automaticallyDetectsLanguage: Bool = false
    public var minimumTextHeight: Float = 0
    public var customWords: [String] = []
    public var recognitionLanguages: [String] = []
    public static let supportedRevisions: [Revision] = [.revision3]
    public var descriptor: RequestDescriptor { .recognizeTextRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision3 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectFaceRectanglesRequest: ImageProcessingRequest {
    public typealias Result = [FaceObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision3
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision3]
    public var descriptor: RequestDescriptor { .detectFaceRectanglesRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision3 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectHumanBodyPoseRequest: ImageProcessingRequest {
    public typealias Result = [HumanBodyPoseObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectHumanBodyPoseRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectHorizonRequest: ImageProcessingRequest {
    public typealias Result = HorizonObservation?
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectHorizonRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectLensSmudgeRequest: ImageProcessingRequest {
    public typealias Result = SmudgeObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectLensSmudgeRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct RecognizeAnimalsRequest: ImageProcessingRequest {
    public typealias Result = [RecognizedObjectObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .recognizeAnimalsRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectTrajectoriesRequest: ImageProcessingRequest {
    public typealias Result = [TrajectoryObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectTrajectoriesRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct RecognizeDocumentsRequest: ImageProcessingRequest {
    public typealias Result = [DocumentObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .recognizeDocumentsRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectFaceLandmarksRequest: ImageProcessingRequest {
    public typealias Result = [FaceObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectFaceLandmarksRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectHumanHandPoseRequest: ImageProcessingRequest {
    public typealias Result = [HumanHandPoseObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectHumanHandPoseRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectAnimalBodyPoseRequest: ImageProcessingRequest {
    public typealias Result = [AnimalBodyPoseObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectAnimalBodyPoseRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectTextRectanglesRequest: ImageProcessingRequest {
    public typealias Result = [TextObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectTextRectanglesRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectHumanRectanglesRequest: ImageProcessingRequest {
    public typealias Result = [HumanObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectHumanRectanglesRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectFaceCaptureQualityRequest: ImageProcessingRequest {
    public typealias Result = [FaceObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectFaceCaptureQualityRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectDocumentSegmentationRequest: ImageProcessingRequest {
    public typealias Result = DetectedDocumentObservation?
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectDocumentSegmentationRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct GeneratePersonInstanceMaskRequest: ImageProcessingRequest {
    public typealias Result = InstanceMaskObservation?
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .generatePersonInstanceMaskRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct GeneratePersonSegmentationRequest: ImageProcessingRequest {
    public typealias Result = PixelBufferObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public enum QualityLevel: UInt, Codable, Hashable, Sendable, CaseIterable {
        case accurate = 0
        case balanced = 1
        case fast = 2
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public var qualityLevel: GeneratePersonSegmentationRequest.QualityLevel = .balanced
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .generatePersonSegmentationRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct CalculateImageAestheticsScoresRequest: ImageProcessingRequest {
    public typealias Result = ImageAestheticsScoresObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .calculateImageAestheticsScoresRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct GenerateForegroundInstanceMaskRequest: ImageProcessingRequest {
    public typealias Result = InstanceMaskObservation?
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .generateForegroundInstanceMaskRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct GenerateAttentionBasedSaliencyImageRequest: ImageProcessingRequest {
    public typealias Result = SaliencyImageObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .generateAttentionBasedSaliencyImageRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct GenerateObjectnessBasedSaliencyImageRequest: ImageProcessingRequest {
    public typealias Result = SaliencyImageObservation
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .generateObjectnessBasedSaliencyImageRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct DetectHumanBodyPose3DRequest: ImageProcessingRequest {
    public typealias Result = [HumanBodyPose3DObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .detectHumanBodyPose3DRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}

public struct CoreMLRequest: ImageProcessingRequest {
    public typealias Result = [any VisionObservation]
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    public let revision: Revision
    public var regionOfInterest: NormalizedRect = .fullImage
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    public static let supportedRevisions: [Revision] = [.revision1]
    public var descriptor: RequestDescriptor { .coreMLRequest(revision) }
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }

    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? {
        devices[computeStage]
    }
    public mutating func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public var description: String { String(describing: descriptor) }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (a: Self, b: Self) -> Bool { a.descriptor == b.descriptor && a.regionOfInterest == b.regionOfInterest }

    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Self.Result {
        try await performOnHandler(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }

    func performOnHandler(_ handler: VNImageRequestHandler) async throws -> Result {
        throw VisionError.invalidModel("Linux has no Apple model for \(String(describing: descriptor))")
    }

}


public final class TrackObjectRequest: @unchecked Sendable {
    public typealias Result = DetectedObjectObservation?
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision2
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }
    public let revision: Revision
    public let inputObservation: any BoundingBoxProviding & VisionObservation
    public let frameAnalysisSpacing: CMTime
    public var regionOfInterest: NormalizedRect = .fullImage
    public var minimumLatencyFrameCount: Int { 0 }
    public static let supportedRevisions: [Revision] = [.revision2]
    public var descriptor: RequestDescriptor { .trackObjectRequest(revision) }
    public var description: String { "TrackObjectRequest" }
    public var hashValue: Int { descriptor.hashValue }
    private var devices: [ComputeStage: MLComputeDevice] = [:]
    private var inner = VNTrackObjectRequest(detectedObjectObservation: VNDetectedObjectObservation(boundingBox: VNNormalizedIdentityRect))
    public init(detectedObject: any BoundingBoxProviding & VisionObservation, _ revision: Revision? = nil, frameAnalysisSpacing: CMTime = .zero) {
        self.inputObservation = detectedObject
        self.revision = revision ?? .revision2
        self.frameAnalysisSpacing = frameAnalysisSpacing
        self.inner = VNTrackObjectRequest(
            detectedObjectObservation: VNDetectedObjectObservation(boundingBox: detectedObject.boundingBox.cgRect)
        )
    }
    public func computeDevice(for computeStage: ComputeStage) -> MLComputeDevice? { devices[computeStage] }
    public func setComputeDevice(_ computeDevice: MLComputeDevice?, for computeStage: ComputeStage) {
        devices[computeStage] = computeDevice
    }
    public func hash(into hasher: inout Hasher) { hasher.combine(descriptor) }
    public static func == (lhs: TrackObjectRequest, rhs: TrackObjectRequest) -> Bool { lhs.descriptor == rhs.descriptor }
    public func perform(on url: URL, orientation: CGImagePropertyOrientation? = nil) async throws -> Result {
        try await run(VNImageRequestHandler(url: url, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on data: Data, orientation: CGImagePropertyOrientation? = nil) async throws -> Result {
        try await run(VNImageRequestHandler(data: data, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CGImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Result {
        try await run(VNImageRequestHandler(cgImage: image, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Result {
        try await run(VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation? = nil) async throws -> Result {
        try await run(VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation ?? .up, options: [:]))
    }
    public func perform(on image: CIImage, orientation: CGImagePropertyOrientation? = nil) async throws -> Result {
        try await run(VNImageRequestHandler(ciImage: image, orientation: orientation ?? .up, options: [:]))
    }
    private func run(_ handler: VNImageRequestHandler) async throws -> Result {
        try handler.perform([inner])
        guard let obs = inner.results?.first as? VNDetectedObjectObservation else { return nil }
        return DetectedObjectObservation(obs)
    }
}

public struct TrackRectangleRequest: Hashable, Sendable {
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }
    public enum TrackingLevel: UInt, Hashable, Sendable { case accurate, fast }
    public let revision: Revision
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }
}
public struct TrackOpticalFlowRequest: Hashable, Sendable {
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }
    public enum ComputationAccuracy: UInt, Hashable, Sendable { case low, medium, high, veryHigh }
    public let revision: Revision
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }
}
public struct TrackHomographicImageRegistrationRequest: Hashable, Sendable {
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }
    public let revision: Revision
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }
}
public struct TrackTranslationalImageRegistrationRequest: Hashable, Sendable {
    public enum Revision: Int, Codable, Hashable, Sendable, Comparable {
        case revision1
        public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }
    public let revision: Revision
    public init(_ revision: Revision? = nil) { self.revision = revision ?? .revision1 }
}
