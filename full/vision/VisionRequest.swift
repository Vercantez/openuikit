import Foundation

open class VNRequest: NSObject {
    public class var currentRevision: Int { VNRequestRevisionUnspecified }
    public class var defaultRevision: Int { VNRequestRevisionUnspecified }
    public class var supportedRevisions: IndexSet { IndexSet(integer: VNRequestRevisionUnspecified) }

    public let completionHandler: VNRequestCompletionHandler?
    public var preferBackgroundProcessing: Bool = false
    public var usesCPUOnly: Bool = false
    public var revision: Int
    public internal(set) var results: [VNObservation]?
    var isCancelled: Bool = false

    private var hostResults: [VNObservation]?

    public convenience override init() {
        self.init(completionHandler: nil)
    }

    public init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.completionHandler = completionHandler
        self.revision = type(of: self).defaultRevision
        super.init()
    }

    public func cancel() {
        isCancelled = true
        results = nil
        hostResults = nil
    }

    func hostAttachResults(_ results: [VNObservation]) {
        hostResults = results
        isCancelled = false
    }

    func consumeHostResults() -> [VNObservation]? {
        let attached = hostResults
        hostResults = nil
        return attached
    }

    func finish(_ observations: [VNObservation]?, error: Error?) {
        results = observations
        completionHandler?(self, error)
    }

    open func perform(on context: VisionImageContext) throws -> [VNObservation] {
        throw vnMakeError(
            .notImplemented,
            description: "Vision request \(type(of: self)) is unavailable on this Linux host"
        )
    }
}

open class VNImageBasedRequest: VNRequest {
    public var regionOfInterest: CGRect = VNNormalizedIdentityRect
}

open class VNDetectRectanglesRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectRectanglesRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectRectanglesRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectRectanglesRequestRevision1)
    }

    public var minimumAspectRatio: VNAspectRatio = 0.5
    public var maximumAspectRatio: VNAspectRatio = 1.0
    public var quadratureTolerance: VNDegrees = 30
    public var minimumSize: Float = 0.2
    public var minimumConfidence: VNConfidence = 0
    public var maximumObservations: Int = 8

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        visionDetectRectangles(in: context.rasterForROI(regionOfInterest), request: self)
    }
}

open class VNDetectBarcodesRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectBarcodesRequestRevision4 }
    public override class var defaultRevision: Int { VNDetectBarcodesRequestRevision4 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectBarcodesRequestRevision1...VNDetectBarcodesRequestRevision4)
    }

    public class var supportedSymbologies: [VNBarcodeSymbology] {
        VNBarcodeSymbology.knownSymbologies
    }

    public var symbologies: [VNBarcodeSymbology] = VNBarcodeSymbology.knownSymbologies
    public var coalesceCompositeSymbologies: Bool = false

    public func supportedSymbologies() throws -> [VNBarcodeSymbology] {
        Self.supportedSymbologies
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        visionDetectBarcodes(in: context.rasterForROI(regionOfInterest), symbologies: symbologies)
    }
}

open class VNDetectContoursRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectContoursRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectContoursRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectContoursRequestRevision1)
    }

    public var contrastAdjustment: Float = 2
    public var contrastPivot: NSNumber? = NSNumber(value: 0.5)
    public var detectDarkOnLight: Bool = true
    public var detectsDarkOnLight: Bool {
        get { detectDarkOnLight }
        set { detectDarkOnLight = newValue }
    }
    public var maximumImageDimension: Int = 512

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionDetectContours(in: context.rasterForROI(regionOfInterest), request: self)]
    }
}

open class VNGenerateImageFeaturePrintRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNGenerateImageFeaturePrintRequestRevision2 }
    public override class var defaultRevision: Int { VNGenerateImageFeaturePrintRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNGenerateImageFeaturePrintRequestRevision1...VNGenerateImageFeaturePrintRequestRevision2
        )
    }

    public var imageCropAndScaleOption: VNImageCropAndScaleOption = .scaleFill

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionFeaturePrint(in: context.rasterForROI(regionOfInterest))]
    }
}

open class VNRecognizeTextRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNRecognizeTextRequestRevision3 }
    public override class var defaultRevision: Int { VNRecognizeTextRequestRevision3 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNRecognizeTextRequestRevision1...VNRecognizeTextRequestRevision3)
    }

    public var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    public var usesLanguageCorrection: Bool = true
    public var automaticallyDetectsLanguage: Bool = false
    public var minimumTextHeight: Float = 0
    public var customWords: [String] = []
    public var recognitionLanguages: [String] = []

    public class func supportedRecognitionLanguages(
        for recognitionLevel: VNRequestTextRecognitionLevel,
        revision requestRevision: Int
    ) throws -> [String] {
        _ = recognitionLevel
        _ = requestRevision
        return []
    }

    public func supportedRecognitionLanguages() throws -> [String] {
        try Self.supportedRecognitionLanguages(for: recognitionLevel, revision: revision)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNRecognizeTextRequest")
    }
}

open class VNDetectFaceRectanglesRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectFaceRectanglesRequestRevision3 }
    public override class var defaultRevision: Int { VNDetectFaceRectanglesRequestRevision3 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectFaceRectanglesRequestRevision1...VNDetectFaceRectanglesRequestRevision3)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectFaceRectanglesRequest")
    }
}

open class VNDetectFaceLandmarksRequest: VNImageBasedRequest {
    public var constellation: VNRequestFaceLandmarksConstellation = .constellationNotDefined

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectFaceLandmarksRequest")
    }
}

open class VNDetectDocumentSegmentationRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectDocumentSegmentationRequest")
    }
}

open class VNGenerateAttentionBasedSaliencyImageRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNGenerateAttentionBasedSaliencyImageRequestRevision2 }
    public override class var defaultRevision: Int { VNGenerateAttentionBasedSaliencyImageRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNGenerateAttentionBasedSaliencyImageRequestRevision1...VNGenerateAttentionBasedSaliencyImageRequestRevision2
        )
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNGenerateAttentionBasedSaliencyImageRequest")
    }
}

open class VNClassifyImageRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNClassifyImageRequestRevision2 }
    public override class var defaultRevision: Int { VNClassifyImageRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNClassifyImageRequestRevision1...VNClassifyImageRequestRevision2)
    }

    public class func knownClassifications(forRevision requestRevision: Int) throws -> [VNClassificationObservation] {
        _ = requestRevision
        throw visionUnavailableModel("VNClassifyImageRequest.knownClassifications")
    }

    public func supportedIdentifiers() throws -> [String] {
        throw visionUnavailableModel("VNClassifyImageRequest.supportedIdentifiers")
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNClassifyImageRequest")
    }
}

open class VNDetectHumanBodyPoseRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectHumanBodyPoseRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectHumanBodyPoseRequestRevision1 }

    public class func supportedJointNames(forRevision revision: Int) throws -> [VNHumanBodyPoseObservation.JointName] {
        _ = revision
        throw visionUnavailableModel("VNDetectHumanBodyPoseRequest.supportedJointNames")
    }

    public class func supportedJointsGroupNames(
        forRevision revision: Int
    ) throws -> [VNHumanBodyPoseObservation.JointsGroupName] {
        _ = revision
        throw visionUnavailableModel("VNDetectHumanBodyPoseRequest.supportedJointsGroupNames")
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectHumanBodyPoseRequest")
    }
}

open class VNHumanBodyPoseObservation: VNRecognizedPointsObservation {
    public struct JointName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointKey
        public init(rawValue: VNRecognizedPointKey) { self.rawValue = rawValue }
        public static let nose = JointName(rawValue: VNRecognizedPointKey(rawValue: "nose"))
    }

    public struct JointsGroupName: RawRepresentable, Hashable, Sendable {
        public let rawValue: VNRecognizedPointGroupKey
        public init(rawValue: VNRecognizedPointGroupKey) { self.rawValue = rawValue }
        public static let all = JointsGroupName(rawValue: VNRecognizedPointGroupKey(rawValue: "all"))
    }
}

open class VNRecognizedPointsObservation: VNObservation {}

public struct VNRecognizedPointKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public struct VNRecognizedPointGroupKey: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

open class VNTargetedImageRequest: VNImageBasedRequest {
    var targetedRaster: VisionRaster?

    public init(
        targetedCGImage cgImage: CGImage,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        super.init(completionHandler: completionHandler)
        targetedRaster = VisionRaster(cgImage: cgImage)
    }

    public convenience init(
        targetedCGImage cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(targetedCGImage: cgImage, options: options, completionHandler: completionHandler)
        targetedRaster = VisionRaster(cgImage: cgImage).applying(orientation: orientation)
    }

    public init(
        targetedCIImage ciImage: CIImage,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        super.init(completionHandler: completionHandler)
        targetedRaster = try? VisionRaster(ciImage: ciImage)
    }

    public convenience init(
        targetedCIImage ciImage: CIImage,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(targetedCIImage: ciImage, options: options, completionHandler: completionHandler)
        targetedRaster = targetedRaster?.applying(orientation: orientation)
    }

    public init(
        targetedImageData imageData: Data,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        super.init(completionHandler: completionHandler)
        targetedRaster = try? VisionImageCodec.decode(imageData)
    }

    public convenience init(
        targetedImageData imageData: Data,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(targetedImageData: imageData, options: options, completionHandler: completionHandler)
        targetedRaster = targetedRaster?.applying(orientation: orientation)
    }

    public init(
        targetedImageURL imageURL: URL,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        super.init(completionHandler: completionHandler)
        targetedRaster = try? VisionImageCodec.decode(url: imageURL)
    }

    public convenience init(
        targetedImageURL imageURL: URL,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(targetedImageURL: imageURL, options: options, completionHandler: completionHandler)
        targetedRaster = targetedRaster?.applying(orientation: orientation)
    }

    public init(
        targetedCVPixelBuffer pixelBuffer: CVPixelBuffer,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        super.init(completionHandler: completionHandler)
        targetedRaster = VisionRaster(pixelBuffer: pixelBuffer)
    }

    public convenience init(
        targetedCVPixelBuffer pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(targetedCVPixelBuffer: pixelBuffer, options: options, completionHandler: completionHandler)
        targetedRaster = targetedRaster?.applying(orientation: orientation)
    }

    public convenience init(
        targetedCMSampleBuffer sampleBuffer: CMSampleBuffer,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(
            targetedCVPixelBuffer: sampleBuffer.pixelBuffer,
            options: options,
            completionHandler: completionHandler
        )
    }

    public convenience init(
        targetedCMSampleBuffer sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.init(
            targetedCMSampleBuffer: sampleBuffer,
            options: options,
            completionHandler: completionHandler
        )
        targetedRaster = targetedRaster?.applying(orientation: orientation)
    }

    public required override init(completionHandler: VNRequestCompletionHandler? = nil) {
        super.init(completionHandler: completionHandler)
    }
}

open class VNGenerateOpticalFlowRequest: VNTargetedImageRequest {
    public enum ComputationAccuracy: UInt, CaseIterable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        case veryHigh = 3
    }

    public var computationAccuracy: ComputationAccuracy = .medium

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNGenerateOpticalFlowRequest")
    }
}

open class VNGeneratePersonSegmentationRequest: VNImageBasedRequest {
    public enum QualityLevel: UInt, CaseIterable, Sendable {
        case accurate = 0
        case balanced = 1
        case fast = 2
    }

    public var qualityLevel: QualityLevel = .balanced

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNGeneratePersonSegmentationRequest")
    }
}

open class VNTrackingRequest: VNImageBasedRequest {
    public var trackingLevel: VNRequestTrackingLevel = .accurate
    public var isLastFrame: Bool = false
    public var inputObservation: VNDetectedObjectObservation = VNDetectedObjectObservation(
        boundingBox: VNNormalizedIdentityRect
    )

    public func supportedNumber(ofTrackersAndReturnError error: UnsafeMutablePointer<NSError?>?) -> Int {
        error?.pointee = nil
        return 1
    }
}

open class VNTrackObjectRequest: VNTrackingRequest {
    public override class var currentRevision: Int { VNTrackObjectRequestRevision2 }
    public override class var defaultRevision: Int { VNTrackObjectRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNTrackObjectRequestRevision1...VNTrackObjectRequestRevision2)
    }

    var templateGray: [UInt8]?
    var templateSize: (Int, Int) = (0, 0)

    public init(detectedObjectObservation observation: VNDetectedObjectObservation) {
        super.init(completionHandler: nil)
        inputObservation = observation
    }

    public init(
        detectedObjectObservation observation: VNDetectedObjectObservation,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        super.init(completionHandler: completionHandler)
        inputObservation = observation
    }

    public required override init(completionHandler: VNRequestCompletionHandler? = nil) {
        super.init(completionHandler: completionHandler)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionTrackObject(in: context.rasterForROI(regionOfInterest), request: self)]
    }
}

open class VNTrackRectangleRequest: VNTrackingRequest {}

open class VNTrackOpticalFlowRequest: VNTrackingRequest {
    public enum ComputationAccuracy: UInt, CaseIterable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        case veryHigh = 3
    }

    public var computationAccuracy: ComputationAccuracy = .medium

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNTrackOpticalFlowRequest")
    }
}

open class VNImageRegistrationRequest: VNTargetedImageRequest {}

open class VNTranslationalImageRegistrationRequest: VNImageRegistrationRequest {
    public override class var currentRevision: Int { VNTranslationalImageRegistrationRequestRevision1 }
    public override class var defaultRevision: Int { VNTranslationalImageRegistrationRequestRevision1 }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        guard let targetedRaster else {
            throw vnMakeError(.missingOption, description: "targeted image is required")
        }
        return [
            visionTranslationalAlignment(
                source: targetedRaster,
                target: context.rasterForROI(regionOfInterest)
            )
        ]
    }
}

open class VNHomographicImageRegistrationRequest: VNImageRegistrationRequest {
    public override class var currentRevision: Int { VNHomographicImageRegistrationRequestRevision1 }
    public override class var defaultRevision: Int { VNHomographicImageRegistrationRequestRevision1 }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw vnMakeError(
            .unsupportedRequest,
            description: "homographic registration is fail-closed on Linux; no 3x3 warp is invented"
        )
    }
}

open class VNCoreMLModel: NSObject {
    public var inputImageFeatureName: String = "image"
    public var featureProvider: (any MLFeatureProvider)?
    public let model: MLModel

    public init(for model: MLModel) throws {
        _ = model
        throw visionUnavailableModel("VNCoreMLModel")
    }

    public convenience init(forMLModel model: MLModel) throws {
        try self.init(for: model)
    }

    init(unchecked model: MLModel) {
        self.model = model
        super.init()
    }
}

open class VNCoreMLRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNCoreMLRequestRevision1 }
    public override class var defaultRevision: Int { VNCoreMLRequestRevision1 }

    public let model: VNCoreMLModel
    public var imageCropAndScaleOption: VNImageCropAndScaleOption = .centerCrop

    public convenience init(model: VNCoreMLModel) {
        self.init(model: model, completionHandler: nil)
    }

    public init(model: VNCoreMLModel, completionHandler: VNRequestCompletionHandler? = nil) {
        self.model = model
        super.init(completionHandler: completionHandler)
    }

    public required override init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.model = VNCoreMLModel(unchecked: MLModel())
        super.init(completionHandler: completionHandler)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNCoreMLRequest")
    }
}

open class VNImageRequestHandler: NSObject {
    @_spi(OpenUIKitHost)
    public enum Source: Equatable {
        case data(Data)
        case url(URL)
        case cgImage
        case ciImage
        case pixelBuffer
        case sampleBuffer
    }

    @_spi(OpenUIKitHost)
    public let source: Source
    public let options: [VNImageOption: Any]
    let raster: VisionRaster
    let orientation: CGImagePropertyOrientation

    public init(data imageData: Data, options: [VNImageOption: Any] = [:]) {
        self.source = .data(imageData)
        self.options = options
        self.orientation = .up
        self.raster = (try? VisionImageCodec.decode(imageData)) ?? VisionRaster(width: 0, height: 0)
        super.init()
    }

    public init(
        data imageData: Data,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.source = .data(imageData)
        self.options = options
        self.orientation = orientation
        let decoded = (try? VisionImageCodec.decode(imageData)) ?? VisionRaster(width: 0, height: 0)
        self.raster = decoded.applying(orientation: orientation)
        super.init()
    }

    public init(url imageURL: URL, options: [VNImageOption: Any] = [:]) {
        self.source = .url(imageURL)
        self.options = options
        self.orientation = .up
        self.raster = (try? VisionImageCodec.decode(url: imageURL)) ?? VisionRaster(width: 0, height: 0)
        super.init()
    }

    public convenience init(URL imageURL: URL, options: [VNImageOption: Any] = [:]) {
        self.init(url: imageURL, options: options)
    }

    public init(
        url imageURL: URL,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.source = .url(imageURL)
        self.options = options
        self.orientation = orientation
        let decoded = (try? VisionImageCodec.decode(url: imageURL)) ?? VisionRaster(width: 0, height: 0)
        self.raster = decoded.applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        URL imageURL: URL,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(url: imageURL, orientation: orientation, options: options)
    }

    public init(cgImage image: CGImage, options: [VNImageOption: Any] = [:]) {
        self.source = .cgImage
        self.options = options
        self.orientation = .up
        self.raster = VisionRaster(cgImage: image)
        super.init()
    }

    public convenience init(CGImage image: CGImage, options: [VNImageOption: Any] = [:]) {
        self.init(cgImage: image, options: options)
    }

    public init(
        cgImage image: CGImage,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.source = .cgImage
        self.options = options
        self.orientation = orientation
        self.raster = VisionRaster(cgImage: image).applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        CGImage image: CGImage,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(cgImage: image, orientation: orientation, options: options)
    }

    public init(ciImage image: CIImage, options: [VNImageOption: Any] = [:]) {
        self.source = .ciImage
        self.options = options
        self.orientation = .up
        self.raster = (try? VisionRaster(ciImage: image)) ?? VisionRaster(width: 0, height: 0)
        super.init()
    }

    public convenience init(CIImage image: CIImage, options: [VNImageOption: Any] = [:]) {
        self.init(ciImage: image, options: options)
    }

    public init(
        ciImage image: CIImage,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.source = .ciImage
        self.options = options
        self.orientation = orientation
        let decoded = (try? VisionRaster(ciImage: image)) ?? VisionRaster(width: 0, height: 0)
        self.raster = decoded.applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        CIImage image: CIImage,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(ciImage: image, orientation: orientation, options: options)
    }

    public init(cvPixelBuffer pixelBuffer: CVPixelBuffer, options: [VNImageOption: Any] = [:]) {
        self.source = .pixelBuffer
        self.options = options
        self.orientation = .up
        self.raster = VisionRaster(pixelBuffer: pixelBuffer)
        super.init()
    }

    public convenience init(CVPixelBuffer pixelBuffer: CVPixelBuffer, options: [VNImageOption: Any] = [:]) {
        self.init(cvPixelBuffer: pixelBuffer, options: options)
    }

    public init(
        cvPixelBuffer pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.source = .pixelBuffer
        self.options = options
        self.orientation = orientation
        self.raster = VisionRaster(pixelBuffer: pixelBuffer).applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        CVPixelBuffer pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(cvPixelBuffer: pixelBuffer, orientation: orientation, options: options)
    }

    public init(
        cvPixelBuffer pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        _ = depthData
        self.source = .pixelBuffer
        self.options = options
        self.orientation = orientation
        self.raster = VisionRaster(pixelBuffer: pixelBuffer).applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        CVPixelBuffer pixelBuffer: CVPixelBuffer,
        depthData: AVDepthData,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(
            cvPixelBuffer: pixelBuffer,
            depthData: depthData,
            orientation: orientation,
            options: options
        )
    }

    public init(cmSampleBuffer sampleBuffer: CMSampleBuffer, options: [VNImageOption: Any] = [:]) {
        self.source = .sampleBuffer
        self.options = options
        self.orientation = .up
        self.raster = VisionRaster(pixelBuffer: sampleBuffer.pixelBuffer)
        super.init()
    }

    public convenience init(CMSampleBuffer sampleBuffer: CMSampleBuffer, options: [VNImageOption: Any] = [:]) {
        self.init(cmSampleBuffer: sampleBuffer, options: options)
    }

    public init(
        cmSampleBuffer sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.source = .sampleBuffer
        self.options = options
        self.orientation = orientation
        self.raster = VisionRaster(pixelBuffer: sampleBuffer.pixelBuffer).applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        CMSampleBuffer sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(cmSampleBuffer: sampleBuffer, orientation: orientation, options: options)
    }

    public init(
        cmSampleBuffer sampleBuffer: CMSampleBuffer,
        depthData: AVDepthData,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        _ = depthData
        self.source = .sampleBuffer
        self.options = options
        self.orientation = orientation
        self.raster = VisionRaster(pixelBuffer: sampleBuffer.pixelBuffer).applying(orientation: orientation)
        super.init()
    }

    public convenience init(
        CMSampleBuffer sampleBuffer: CMSampleBuffer,
        depthData: AVDepthData,
        orientation: CGImagePropertyOrientation,
        options: [VNImageOption: Any] = [:]
    ) {
        self.init(
            cmSampleBuffer: sampleBuffer,
            depthData: depthData,
            orientation: orientation,
            options: options
        )
    }

    public func perform(_ requests: [VNRequest]) throws {
        let context = VisionImageContext(raster: raster, orientation: orientation, options: options)
        for request in requests {
            if request.isCancelled {
                let error = vnMakeError(.requestCancelled, description: "request cancelled")
                request.finish(nil, error: error)
                throw error
            }
            if let attached = request.consumeHostResults() {
                request.finish(attached, error: nil)
                continue
            }
            if raster.width == 0 || raster.height == 0 {
                let error = vnMakeError(.invalidImage, description: "image could not be decoded")
                request.finish(nil, error: error)
                throw error
            }
            do {
                let observations = try request.perform(on: context)
                request.finish(observations, error: nil)
            } catch {
                request.finish(nil, error: error)
                throw error
            }
        }
    }
}

open class VNSequenceRequestHandler: NSObject {
    public override init() {
        super.init()
    }

    public func perform(_ requests: [VNRequest], onImageData imageData: Data) throws {
        try VNImageRequestHandler(data: imageData, options: [:]).perform(requests)
    }

    public func perform(
        _ requests: [VNRequest],
        onImageData imageData: Data,
        orientation: CGImagePropertyOrientation
    ) throws {
        try VNImageRequestHandler(data: imageData, orientation: orientation, options: [:]).perform(requests)
    }

    public func perform(_ requests: [VNRequest], onImageURL imageURL: URL) throws {
        try VNImageRequestHandler(url: imageURL, options: [:]).perform(requests)
    }

    public func perform(
        _ requests: [VNRequest],
        onImageURL imageURL: URL,
        orientation: CGImagePropertyOrientation
    ) throws {
        try VNImageRequestHandler(url: imageURL, orientation: orientation, options: [:]).perform(requests)
    }

    public func perform(_ requests: [VNRequest], on image: CGImage) throws {
        try VNImageRequestHandler(cgImage: image, options: [:]).perform(requests)
    }

    public func perform(
        _ requests: [VNRequest],
        on image: CGImage,
        orientation: CGImagePropertyOrientation
    ) throws {
        try VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:]).perform(requests)
    }

    public func perform(_ requests: [VNRequest], on image: CIImage) throws {
        try VNImageRequestHandler(ciImage: image, options: [:]).perform(requests)
    }

    public func perform(
        _ requests: [VNRequest],
        on image: CIImage,
        orientation: CGImagePropertyOrientation
    ) throws {
        try VNImageRequestHandler(ciImage: image, orientation: orientation, options: [:]).perform(requests)
    }

    public func perform(_ requests: [VNRequest], on pixelBuffer: CVPixelBuffer) throws {
        try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform(requests)
    }

    public func perform(
        _ requests: [VNRequest],
        on pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) throws {
        try VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        ).perform(requests)
    }

    public func perform(_ requests: [VNRequest], on sampleBuffer: CMSampleBuffer) throws {
        try VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:]).perform(requests)
    }

    public func perform(
        _ requests: [VNRequest],
        on sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation
    ) throws {
        try VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: orientation,
            options: [:]
        ).perform(requests)
    }
}

func visionUnavailableModel(_ operation: String) -> NSError {
    vnMakeError(
        .invalidModel,
        description: "Vision has no Apple ML models on Linux: \(operation)"
    )
}
