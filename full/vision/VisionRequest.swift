import Foundation

open class VNRequest: NSObject, VNRequestProgressProviding {
    public class var currentRevision: Int { VNRequestRevisionUnspecified }
    public class var defaultRevision: Int { VNRequestRevisionUnspecified }
    public class var supportedRevisions: IndexSet { IndexSet(integer: VNRequestRevisionUnspecified) }

    public let completionHandler: VNRequestCompletionHandler?
    public var preferBackgroundProcessing: Bool = false
    public var usesCPUOnly: Bool = false
    public var revision: Int
    public internal(set) var results: [VNObservation]?
    public var progressHandler: VNRequestProgressHandler = { _, _, _ in }
    /// Linux never emits model-progress callbacks; the handler is stored only.
    public var indeterminate: Bool { true }
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

open class VNDetectFaceLandmarksRequest: VNImageBasedRequest, VNFaceObservationAccepting {
    public override class var currentRevision: Int { VNDetectFaceLandmarksRequestRevision3 }
    public override class var defaultRevision: Int { VNDetectFaceLandmarksRequestRevision3 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectFaceLandmarksRequestRevision1...VNDetectFaceLandmarksRequestRevision3)
    }

    public var constellation: VNRequestFaceLandmarksConstellation = .constellationNotDefined
    public var inputFaceObservations: [VNFaceObservation]?

    public class func revision(
        _ requestRevision: Int,
        supportsConstellation constellation: VNRequestFaceLandmarksConstellation
    ) -> Bool {
        guard supportedRevisions.contains(requestRevision) else { return false }
        switch constellation {
        case .constellationNotDefined, .constellation65Points, .constellation76Points:
            return true
        @unknown default:
            return false
        }
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectFaceLandmarksRequest")
    }
}

open class VNDetectHumanRectanglesRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectHumanRectanglesRequestRevision2 }
    public override class var defaultRevision: Int { VNDetectHumanRectanglesRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectHumanRectanglesRequestRevision1...VNDetectHumanRectanglesRequestRevision2)
    }

    public var upperBodyOnly: Bool = false

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectHumanRectanglesRequest")
    }
}

open class VNDetectFaceCaptureQualityRequest: VNImageBasedRequest, VNFaceObservationAccepting {
    public override class var currentRevision: Int { VNDetectFaceCaptureQualityRequestRevision3 }
    public override class var defaultRevision: Int { VNDetectFaceCaptureQualityRequestRevision3 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectFaceCaptureQualityRequestRevision1...VNDetectFaceCaptureQualityRequestRevision3)
    }

    public var inputFaceObservations: [VNFaceObservation]?

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectFaceCaptureQualityRequest")
    }
}

open class VNCalculateImageAestheticsScoresRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNCalculateImageAestheticsScoresRequestRevision1 }
    public override class var defaultRevision: Int { VNCalculateImageAestheticsScoresRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNCalculateImageAestheticsScoresRequestRevision1)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionAestheticsScores(in: context.rasterForROI(regionOfInterest))]
    }
}

open class VNGeneratePersonInstanceMaskRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNGeneratePersonInstanceMaskRequestRevision1 }
    public override class var defaultRevision: Int { VNGeneratePersonInstanceMaskRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNGeneratePersonInstanceMaskRequestRevision1)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNGeneratePersonInstanceMaskRequest")
    }
}

open class VNGenerateForegroundInstanceMaskRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNGenerateForegroundInstanceMaskRequestRevision1 }
    public override class var defaultRevision: Int { VNGenerateForegroundInstanceMaskRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNGenerateForegroundInstanceMaskRequestRevision1)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionForegroundInstanceMask(in: context.rasterForROI(regionOfInterest))]
    }
}

/// A classical corner tracklet: Harris point history in working-grid pixels.
struct VisionTracklet {
    var points: [CGPoint]
    var score: Float
}

open class VNDetectDocumentSegmentationRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        if let quad = visionDetectDocumentQuad(in: context.rasterForROI(regionOfInterest)) {
            return [quad]
        }
        return []
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
        [visionSaliencyMap(in: context.rasterForROI(regionOfInterest))]
    }
}

open class VNGenerateObjectnessBasedSaliencyImageRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNGenerateObjectnessBasedSaliencyImageRequestRevision2 }
    public override class var defaultRevision: Int { VNGenerateObjectnessBasedSaliencyImageRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNGenerateObjectnessBasedSaliencyImageRequestRevision1...VNGenerateObjectnessBasedSaliencyImageRequestRevision2
        )
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionSaliencyMap(in: context.rasterForROI(regionOfInterest))]
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
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectHumanBodyPoseRequestRevision1)
    }

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

open class VNDetectHumanHandPoseRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectHumanHandPoseRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectHumanHandPoseRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectHumanHandPoseRequestRevision1)
    }

    public var maximumHandCount: Int = 2

    public class func supportedJointNames(forRevision revision: Int) throws -> [VNHumanHandPoseObservation.JointName] {
        _ = revision
        throw visionUnavailableModel("VNDetectHumanHandPoseRequest.supportedJointNames")
    }

    public class func supportedJointsGroupNames(
        forRevision revision: Int
    ) throws -> [VNHumanHandPoseObservation.JointsGroupName] {
        _ = revision
        throw visionUnavailableModel("VNDetectHumanHandPoseRequest.supportedJointsGroupNames")
    }

    public var supportedJointNames: [VNHumanHandPoseObservation.JointName] {
        get throws {
            throw visionUnavailableModel("VNDetectHumanHandPoseRequest.supportedJointNames")
        }
    }

    public var supportedJointsGroupNames: [VNHumanHandPoseObservation.JointsGroupName] {
        get throws {
            throw visionUnavailableModel("VNDetectHumanHandPoseRequest.supportedJointsGroupNames")
        }
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectHumanHandPoseRequest")
    }
}

open class VNDetectAnimalBodyPoseRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectAnimalBodyPoseRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectAnimalBodyPoseRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectAnimalBodyPoseRequestRevision1)
    }

    public var supportedJointNames: [VNAnimalBodyPoseObservation.JointName] {
        get throws {
            throw visionUnavailableModel("VNDetectAnimalBodyPoseRequest.supportedJointNames")
        }
    }

    public var supportedJointsGroupNames: [VNAnimalBodyPoseObservation.JointsGroupName] {
        get throws {
            throw visionUnavailableModel("VNDetectAnimalBodyPoseRequest.supportedJointsGroupNames")
        }
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectAnimalBodyPoseRequest")
    }
}

open class VNDetectHumanBodyPose3DRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectHumanBodyPose3DRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectHumanBodyPose3DRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectHumanBodyPose3DRequestRevision1)
    }

    public var supportedJointNames: [VNHumanBodyPose3DObservation.JointName] {
        get throws {
            throw visionUnavailableModel("VNDetectHumanBodyPose3DRequest.supportedJointNames")
        }
    }

    public var supportedJointsGroupNames: [VNHumanBodyPose3DObservation.JointsGroupName] {
        get throws {
            throw visionUnavailableModel("VNDetectHumanBodyPose3DRequest.supportedJointsGroupNames")
        }
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNDetectHumanBodyPose3DRequest")
    }
}

open class VNDetectTextRectanglesRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectTextRectanglesRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectTextRectanglesRequestRevision1 }
    public var reportCharacterBoxes: Bool = false

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        visionDetectTextRectangles(in: context.rasterForROI(regionOfInterest), request: self)
    }
}

open class VNRecognizeAnimalsRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNRecognizeAnimalsRequestRevision2 }
    public override class var defaultRevision: Int { VNRecognizeAnimalsRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNRecognizeAnimalsRequestRevision1...VNRecognizeAnimalsRequestRevision2)
    }

    public class func knownAnimalIdentifiers(forRevision requestRevision: Int) throws -> [VNAnimalIdentifier] {
        _ = requestRevision
        throw visionUnavailableModel("VNRecognizeAnimalsRequest.knownAnimalIdentifiers")
    }

    public func supportedIdentifiers() throws -> [VNAnimalIdentifier] {
        throw visionUnavailableModel("VNRecognizeAnimalsRequest.supportedIdentifiers")
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        _ = context
        throw visionUnavailableModel("VNRecognizeAnimalsRequest")
    }
}

open class VNStatefulRequest: VNImageBasedRequest {
    public let frameAnalysisSpacing: CMTime
    public var minimumLatencyFrameCount: Int { 0 }

    public init(
        frameAnalysisSpacing: CMTime,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.frameAnalysisSpacing = frameAnalysisSpacing
        super.init(completionHandler: completionHandler)
    }

    public required override init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.frameAnalysisSpacing = .zero
        super.init(completionHandler: completionHandler)
    }
}

open class VNDetectTrajectoriesRequest: VNStatefulRequest {
    public override class var currentRevision: Int { VNDetectTrajectoriesRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectTrajectoriesRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNDetectTrajectoriesRequestRevision1)
    }

    public let trajectoryLength: Int
    public var targetFrameTime: CMTime = .zero
    public var objectMinimumNormalizedRadius: Float = 0
    public var objectMaximumNormalizedRadius: Float = 1
    public var minimumObjectSize: Float {
        get { objectMinimumNormalizedRadius }
        set { objectMinimumNormalizedRadius = newValue }
    }
    public var maximumObjectSize: Float {
        get { objectMaximumNormalizedRadius }
        set { objectMaximumNormalizedRadius = newValue }
    }

    public init(
        frameAnalysisSpacing: CMTime,
        trajectoryLength: Int,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        self.trajectoryLength = max(1, trajectoryLength)
        super.init(frameAnalysisSpacing: frameAnalysisSpacing, completionHandler: completionHandler)
    }

    public required init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.trajectoryLength = 5
        super.init(frameAnalysisSpacing: .zero, completionHandler: completionHandler)
    }

    var previousTrackRaster: VisionRaster?
    var tracklets: [VisionTracklet] = []

    /// Classical sparse trajectory detection. Harris corners are tracked across
    /// frames with NCC block matching; tracklets with at least
    /// `max(2, trajectoryLength)` points and net motion inside the normalized
    /// radius bounds are reported as `VNTrajectoryObservation` with a linear
    /// least-squares velocity in `equationCoefficients` and up to 3 extrapolated
    /// `projectedPoints`. Static points and radius outliers are dropped. This is
    /// a documented Linux-local stand-in, not Apple's trajectory model.
    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        let raster = context.rasterForROI(regionOfInterest)
        let maxDim = max(1, max(raster.width, raster.height))
        let scale = min(1, 64 / Double(maxDim))
        let gridWidth = max(8, Int((Double(raster.width) * scale).rounded()))
        let gridHeight = max(8, Int((Double(raster.height) * scale).rounded()))
        let work = raster.resized(width: gridWidth, height: gridHeight)
        let gray = work.grayscale()
        let needed = max(2, trajectoryLength)
        defer { previousTrackRaster = work }
        let corners = visionHarrisCorners(gray: gray, width: gridWidth, height: gridHeight, maxCount: 24)
        guard let previous = previousTrackRaster,
            previous.width == gridWidth, previous.height == gridHeight
        else {
            tracklets = corners.map {
                VisionTracklet(points: [CGPoint(x: $0.x, y: $0.y)], score: 1)
            }
            return []
        }
        let previousGray = previous.grayscale()
        var next: [VisionTracklet] = []
        for var tracklet in tracklets {
            guard let head = tracklet.points.last else { continue }
            let anchor = (x: Int(head.x.rounded()), y: Int(head.y.rounded()))
            guard let hit = visionMatchCorner(
                first: previousGray, second: gray,
                width: gridWidth, height: gridHeight,
                a: anchor, searchRadius: 8, patchRadius: 3, threshold: 0.6
            ) else { continue }
            tracklet.points.append(CGPoint(x: hit.x, y: hit.y))
            if tracklet.points.count > needed {
                tracklet.points.removeFirst(tracklet.points.count - needed)
            }
            tracklet.score = min(1, (tracklet.score + hit.score) / 2)
            next.append(tracklet)
        }
        for corner in corners {
            if next.count >= 32 { break }
            var clear = true
            for tracklet in next {
                guard let head = tracklet.points.last else { continue }
                let dx = Double(corner.x) - head.x
                let dy = Double(corner.y) - head.y
                if dx * dx + dy * dy < 36 {
                    clear = false
                    break
                }
            }
            if clear {
                next.append(VisionTracklet(points: [CGPoint(x: corner.x, y: corner.y)], score: 1))
            }
        }
        tracklets = Array(next.prefix(32))
        func normalized(_ point: CGPoint) -> VNPoint {
            let nx = min(1, max(0, (Double(point.x) / scale) / Double(max(1, raster.width))))
            let ny = min(1, max(0, 1 - (Double(point.y) / scale) / Double(max(1, raster.height))))
            return VNPoint(x: nx, y: ny)
        }
        var observations: [VNObservation] = []
        let ordered = tracklets.sorted {
            let aFirst = $0.points.first ?? .zero
            let aLast = $0.points.last ?? .zero
            let bFirst = $1.points.first ?? .zero
            let bLast = $1.points.last ?? .zero
            let aDx = aLast.x - aFirst.x
            let aDy = aLast.y - aFirst.y
            let bDx = bLast.x - bFirst.x
            let bDy = bLast.y - bFirst.y
            return aDx * aDx + aDy * aDy > bDx * bDx + bDy * bDy
        }
        for tracklet in ordered {
            if observations.count >= 16 { break }
            guard tracklet.points.count >= needed,
                let first = tracklet.points.first, let last = tracklet.points.last
            else { continue }
            let dx = last.x - first.x
            let dy = last.y - first.y
            let distance = (dx * dx + dy * dy).squareRoot()
            guard distance >= 0.5 else { continue }
            let radius = distance / Double(max(gridWidth, gridHeight))
            guard radius >= Double(objectMinimumNormalizedRadius),
                radius <= Double(objectMaximumNormalizedRadius)
            else { continue }
            let steps = Double(max(1, tracklet.points.count - 1))
            let velocity = SIMD2<Double>(dx / steps, dy / steps)
            let detected = tracklet.points.map { normalized($0) }
            var projected: [VNPoint] = []
            for step in 1...min(3, needed) {
                let px = min(Double(gridWidth - 1), max(0, last.x + velocity.x * Double(step)))
                let py = min(Double(gridHeight - 1), max(0, last.y + velocity.y * Double(step)))
                projected.append(normalized(CGPoint(x: px, y: py)))
            }
            observations.append(
                VNTrajectoryObservation(
                    detectedPoints: detected,
                    projectedPoints: projected,
                    equationCoefficients: SIMD3<Float>(
                        Float(velocity.x / scale / Double(max(1, raster.width))),
                        Float(-velocity.y / scale / Double(max(1, raster.height))),
                        0
                    ),
                    movingAverageRadius: CGFloat(radius),
                    confidence: tracklet.score
                )
            )
        }
        return observations
    }
}

open class VNDetectHorizonRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectHorizonRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectHorizonRequestRevision1 }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        [visionDetectHorizon(in: context.rasterForROI(regionOfInterest))]
    }
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

    /// Oracle-pinned (macOS Vision, Xcode 26.1, 2026-09-14): supported [1, 2],
    /// current 2, default 2.
    public override class var currentRevision: Int { VNGenerateOpticalFlowRequestRevision2 }
    public override class var defaultRevision: Int { VNGenerateOpticalFlowRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNGenerateOpticalFlowRequestRevision1...VNGenerateOpticalFlowRequestRevision2)
    }

    public var computationAccuracy: ComputationAccuracy = .medium
    /// Oracle-pinned default (macOS Vision, Xcode 26.1, 2026-09-14).
    public var outputPixelFormat: OSType = kCVPixelFormatType_TwoComponent32Float
    public var keepNetworkOutput: Bool = false

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        guard let targetedRaster else {
            throw vnMakeError(.missingOption, description: "targeted image is required")
        }
        let reference = context.rasterForROI(regionOfInterest)
        let flow = visionOpticalFlowVectors(
            from: reference,
            to: targetedRaster,
            searchRadius: visionOpticalFlowSearchRadius(accuracy: Int(computationAccuracy.rawValue))
        )
        return [
            VNPixelBufferObservation(
                pixelBuffer: CVPixelBuffer(flowWidth: flow.width, flowHeight: flow.height, vectors: flow.vectors),
                confidence: flow.confidence
            )
        ]
    }
}

open class VNGeneratePersonSegmentationRequest: VNImageBasedRequest {
    public enum QualityLevel: UInt, CaseIterable, Sendable {
        case accurate = 0
        case balanced = 1
        case fast = 2
    }

    public override class var currentRevision: Int { VNGeneratePersonSegmentationRequestRevision1 }
    public override class var defaultRevision: Int { VNGeneratePersonSegmentationRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNGeneratePersonSegmentationRequestRevision1)
    }

    public var qualityLevel: QualityLevel = .balanced
    public var outputPixelFormat: OSType = kCVPixelFormatType_32BGRA

    public func supportedOutputPixelFormats() throws -> [NSNumber] {
        [NSNumber(value: kCVPixelFormatType_32BGRA)]
    }

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
    var templateGray: [UInt8]?
    var templateSize: (Int, Int) = (0, 0)

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

open class VNTrackRectangleRequest: VNTrackingRequest {
    public override class var currentRevision: Int { VNTrackRectangleRequestRevision1 }
    public override class var defaultRevision: Int { VNTrackRectangleRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNTrackRectangleRequestRevision1)
    }

    public convenience init(rectangleObservation observation: VNRectangleObservation) {
        self.init(rectangleObservation: observation, completionHandler: nil)
    }

    public init(
        rectangleObservation observation: VNRectangleObservation,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        super.init(completionHandler: completionHandler)
        inputObservation = observation
    }

    public required override init(completionHandler: VNRequestCompletionHandler? = nil) {
        super.init(completionHandler: completionHandler)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        let tracked = visionTrackObject(
            in: context.rasterForROI(regionOfInterest),
            request: self
        )
        let box = tracked.boundingBox
        return [
            VNRectangleObservation(
                requestRevision: VNTrackRectangleRequestRevision1,
                topLeft: CGPoint(x: box.minX, y: box.maxY),
                topRight: CGPoint(x: box.maxX, y: box.maxY),
                bottomRight: CGPoint(x: box.maxX, y: box.minY),
                bottomLeft: CGPoint(x: box.minX, y: box.minY),
                confidence: tracked.confidence,
                uuid: tracked.uuid
            )
        ]
    }
}

open class VNTrackHomographicImageRegistrationRequest: VNStatefulRequest {
    public override class var currentRevision: Int { VNTrackHomographicImageRegistrationRequestRevision1 }
    public override class var defaultRevision: Int { VNTrackHomographicImageRegistrationRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNTrackHomographicImageRegistrationRequestRevision1)
    }

    public override init(
        frameAnalysisSpacing: CMTime,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        super.init(frameAnalysisSpacing: frameAnalysisSpacing, completionHandler: completionHandler)
    }

    public required init(completionHandler: VNRequestCompletionHandler? = nil) {
        super.init(completionHandler: completionHandler)
    }

    var previousHomographyRaster: VisionRaster?

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        let current = context.rasterForROI(regionOfInterest)
        defer { previousHomographyRaster = current }
        guard let previous = previousHomographyRaster else {
            return [VNImageHomographicAlignmentObservation(confidence: 1)]
        }
        return [visionHomographicAlignment(source: previous, target: current)]
    }
}

open class VNTrackTranslationalImageRegistrationRequest: VNStatefulRequest {
    public override class var currentRevision: Int { VNTrackTranslationalImageRegistrationRequestRevision1 }
    public override class var defaultRevision: Int { VNTrackTranslationalImageRegistrationRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNTrackTranslationalImageRegistrationRequestRevision1)
    }

    var previousRaster: VisionRaster?

    public override init(
        frameAnalysisSpacing: CMTime,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        super.init(frameAnalysisSpacing: frameAnalysisSpacing, completionHandler: completionHandler)
    }

    public required init(completionHandler: VNRequestCompletionHandler? = nil) {
        super.init(completionHandler: completionHandler)
    }

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        let current = context.rasterForROI(regionOfInterest)
        defer { previousRaster = current }
        guard let previous = previousRaster else {
            return [VNImageTranslationAlignmentObservation(alignmentTransform: .identity)]
        }
        return [visionTranslationalAlignment(source: previous, target: current)]
    }
}

open class VNTrackOpticalFlowRequest: VNTrackingRequest {
    public enum ComputationAccuracy: UInt, CaseIterable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        case veryHigh = 3
    }

    public override class var currentRevision: Int { VNTrackOpticalFlowRequestRevision1 }
    public override class var defaultRevision: Int { VNTrackOpticalFlowRequestRevision1 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integer: VNTrackOpticalFlowRequestRevision1)
    }

    public var computationAccuracy: ComputationAccuracy = .medium
    public var keepNetworkOutput: Bool = false
    /// Oracle-pinned default (macOS Vision, Xcode 26.1, 2026-09-14).
    public var outputPixelFormat: OSType = kCVPixelFormatType_TwoComponent32Float

    var previousRaster: VisionRaster?

    open override func perform(on context: VisionImageContext) throws -> [VNObservation] {
        let current = context.rasterForROI(regionOfInterest)
        defer { previousRaster = current }
        guard let previous = previousRaster else {
            let zero = visionZeroFlowVectors(width: current.width, height: current.height)
            return [
                VNPixelBufferObservation(
                    pixelBuffer: CVPixelBuffer(flowWidth: current.width, flowHeight: current.height, vectors: zero.vectors),
                    confidence: zero.confidence
                )
            ]
        }
        let flow = visionOpticalFlowVectors(
            from: previous,
            to: current,
            searchRadius: visionOpticalFlowSearchRadius(accuracy: Int(computationAccuracy.rawValue))
        )
        return [
            VNPixelBufferObservation(
                pixelBuffer: CVPixelBuffer(flowWidth: flow.width, flowHeight: flow.height, vectors: flow.vectors),
                confidence: flow.confidence
            )
        ]
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
        guard let targetedRaster else {
            throw vnMakeError(.missingOption, description: "targeted image is required")
        }
        return [
            visionHomographicAlignment(
                source: targetedRaster,
                target: context.rasterForROI(regionOfInterest)
            )
        ]
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
                try visionValidateRequestConfiguration(request)
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
