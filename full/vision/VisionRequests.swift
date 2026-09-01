//===----------------------------------------------------------------------===//
// Concrete request types used by the 20-app corpus and the surrounding
// public VN* family. `perform` always fail-closes: these objects hold
// configuration, not Apple model output.
//===----------------------------------------------------------------------===//

open class VNDetectBarcodesRequest: VNImageBasedRequest, @unchecked Sendable {
    public var symbologies: [VNBarcodeSymbology] = VNBarcodeSymbology.allCases
    public var coalesceCompositeSymbologies = false

    open override class var currentRevision: Int { VNDetectBarcodesRequestRevision4 }
    open override class var defaultRevision: Int { VNDetectBarcodesRequestRevision4 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectBarcodesRequestRevision1...VNDetectBarcodesRequestRevision4)
    }

    public class var supportedSymbologies: [VNBarcodeSymbology] {
        VNBarcodeSymbology.allCases
    }

    public func supportedSymbologies() throws -> [VNBarcodeSymbology] {
        Self.supportedSymbologies
    }
}

open class VNDetectFaceRectanglesRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNDetectFaceRectanglesRequestRevision3 }
    open override class var defaultRevision: Int { VNDetectFaceRectanglesRequestRevision3 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNDetectFaceRectanglesRequestRevision1...VNDetectFaceRectanglesRequestRevision3
        )
    }
}

open class VNDetectFaceLandmarksRequest: VNImageBasedRequest, VNFaceObservationAccepting,
    @unchecked Sendable
{
    public var constellation: VNRequestFaceLandmarksConstellation = .constellationNotDefined
    public var inputFaceObservations: [VNFaceObservation]?

    open override class var currentRevision: Int { VNDetectFaceLandmarksRequestRevision3 }
    open override class var defaultRevision: Int { VNDetectFaceLandmarksRequestRevision3 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNDetectFaceLandmarksRequestRevision1...VNDetectFaceLandmarksRequestRevision3
        )
    }

    public class func revision(
        _ requestRevision: Int,
        supportsConstellation constellation: VNRequestFaceLandmarksConstellation
    ) -> Bool {
        if constellation == .constellationNotDefined {
            return true
        }
        return requestRevision >= VNDetectFaceLandmarksRequestRevision2
    }
}

open class VNDetectFaceCaptureQualityRequest: VNImageBasedRequest, VNFaceObservationAccepting,
    @unchecked Sendable
{
    public var inputFaceObservations: [VNFaceObservation]?

    open override class var currentRevision: Int { VNDetectFaceCaptureQualityRequestRevision3 }
    open override class var defaultRevision: Int { VNDetectFaceCaptureQualityRequestRevision3 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn:
                VNDetectFaceCaptureQualityRequestRevision1...VNDetectFaceCaptureQualityRequestRevision3
        )
    }
}

open class VNDetectRectanglesRequest: VNImageBasedRequest, @unchecked Sendable {
    public var minimumAspectRatio: VNAspectRatio = 0.5
    public var maximumAspectRatio: VNAspectRatio = 1.0
    public var quadratureTolerance: VNDegrees = 30
    public var minimumSize: Float = 0.2
    public var minimumConfidence: VNConfidence = 0
    public var maximumObservations: Int = 1

    open override class var currentRevision: Int { VNDetectRectanglesRequestRevision1 }
    open override class var defaultRevision: Int { VNDetectRectanglesRequestRevision1 }
}

open class VNDetectTextRectanglesRequest: VNImageBasedRequest, @unchecked Sendable {
    public var reportCharacterBoxes = false

    open override class var currentRevision: Int { VNDetectTextRectanglesRequestRevision1 }
    open override class var defaultRevision: Int { VNDetectTextRectanglesRequestRevision1 }
}

open class VNRecognizeTextRequest: VNImageBasedRequest, VNRequestProgressProviding,
    @unchecked Sendable
{
    public var recognitionLevel: VNRequestTextRecognitionLevel = .accurate
    public var recognitionLanguages: [String] = []
    public var customWords: [String] = []
    public var usesLanguageCorrection = false
    public var automaticallyDetectsLanguage = false
    public var minimumTextHeight: Float = 1.0 / 32.0

    open override class var currentRevision: Int { VNRecognizeTextRequestRevision3 }
    open override class var defaultRevision: Int { VNRecognizeTextRequestRevision3 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNRecognizeTextRequestRevision1...VNRecognizeTextRequestRevision3)
    }

    public class func supportedRecognitionLanguages(
        for recognitionLevel: VNRequestTextRecognitionLevel,
        revision requestRevision: Int
    ) throws -> [String] {
        _ = recognitionLevel
        _ = requestRevision
        throw visionError(
            .dataUnavailable,
            "Linux Vision has no Apple text-recognition language pack"
        )
    }

    public func supportedRecognitionLanguages() throws -> [String] {
        try Self.supportedRecognitionLanguages(for: recognitionLevel, revision: revision)
    }
}

open class VNClassifyImageRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNClassifyImageRequestRevision2 }
    open override class var defaultRevision: Int { VNClassifyImageRequestRevision2 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNClassifyImageRequestRevision1...VNClassifyImageRequestRevision2)
    }

    public class func knownClassifications(
        forRevision requestRevision: Int
    ) throws -> [VNClassificationObservation] {
        _ = requestRevision
        throw visionError(.dataUnavailable, "Linux Vision has no Apple image taxonomy")
    }

    public func supportedIdentifiers() throws -> [String] {
        throw visionError(.dataUnavailable, "Linux Vision has no Apple image taxonomy")
    }
}

open class VNRecognizeAnimalsRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNRecognizeAnimalsRequestRevision2 }
    open override class var defaultRevision: Int { VNRecognizeAnimalsRequestRevision2 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNRecognizeAnimalsRequestRevision1...VNRecognizeAnimalsRequestRevision2)
    }

    public class func knownAnimalIdentifiers(
        forRevision requestRevision: Int
    ) throws -> [VNAnimalIdentifier] {
        _ = requestRevision
        return [.cat, .dog]
    }

    public func supportedIdentifiers() throws -> [VNAnimalIdentifier] {
        try Self.knownAnimalIdentifiers(forRevision: revision)
    }
}

open class VNGenerateAttentionBasedSaliencyImageRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int {
        VNGenerateAttentionBasedSaliencyImageRequestRevision2
    }
    open override class var defaultRevision: Int {
        VNGenerateAttentionBasedSaliencyImageRequestRevision2
    }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: 1...2)
    }
}

open class VNGenerateObjectnessBasedSaliencyImageRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int {
        VNGenerateObjectnessBasedSaliencyImageRequestRevision2
    }
    open override class var defaultRevision: Int {
        VNGenerateObjectnessBasedSaliencyImageRequestRevision2
    }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: 1...2)
    }
}

open class VNDetectHorizonRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNDetectHorizonRequestRevision1 }
    open override class var defaultRevision: Int { VNDetectHorizonRequestRevision1 }
}

open class VNDetectContoursRequest: VNImageBasedRequest, @unchecked Sendable {
    public var contrastAdjustment: Float = 2
    public var contrastPivot: NSNumber? = NSNumber(value: 0.5)
    public var detectDarkOnLight = true
    public var detectsDarkOnLight: Bool {
        get { detectDarkOnLight }
        set { detectDarkOnLight = newValue }
    }
    public var maximumImageDimension: Int = 512

    open override class var currentRevision: Int { VNDetectContourRequestRevision1 }
    open override class var defaultRevision: Int { VNDetectContourRequestRevision1 }
}

open class VNDetectDocumentSegmentationRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }
    open override class var defaultRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }
}

open class VNDetectHumanRectanglesRequest: VNImageBasedRequest, @unchecked Sendable {
    public var upperBodyOnly = false

    open override class var currentRevision: Int { VNDetectHumanRectanglesRequestRevision2 }
    open override class var defaultRevision: Int { VNDetectHumanRectanglesRequestRevision2 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNDetectHumanRectanglesRequestRevision1...VNDetectHumanRectanglesRequestRevision2
        )
    }
}

open class VNCalculateImageAestheticsScoresRequest: VNImageBasedRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNCalculateImageAestheticsScoresRequestRevision1 }
    open override class var defaultRevision: Int { VNCalculateImageAestheticsScoresRequestRevision1 }
}

open class VNGeneratePersonSegmentationRequest: VNStatefulRequest, @unchecked Sendable {
    public enum QualityLevel: UInt, Sendable, Hashable {
        case accurate = 0
        case balanced = 1
        case fast = 2
    }

    public var qualityLevel: QualityLevel = .balanced
    public var outputPixelFormat: UInt32 = 0

    public override init(completionHandler: VNRequestCompletionHandler? = nil) {
        super.init(completionHandler: completionHandler)
    }

    open override class var currentRevision: Int { VNGeneratePersonSegmentationRequestRevision1 }
    open override class var defaultRevision: Int { VNGeneratePersonSegmentationRequestRevision1 }

    public func supportedOutputPixelFormats() throws -> [NSNumber] {
        throw visionError(
            .unsupportedRequest,
            "Linux Vision has no person-segmentation compute path"
        )
    }
}

open class VNTrackObjectRequest: VNTrackingRequest, @unchecked Sendable {
    public init(detectedObjectObservation observation: VNDetectedObjectObservation) {
        super.init(completionHandler: nil)
        self.inputObservation = observation
    }

    public init(
        detectedObjectObservation observation: VNDetectedObjectObservation,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        super.init(completionHandler: completionHandler)
        self.inputObservation = observation
    }

    open override class var currentRevision: Int { VNTrackObjectRequestRevision2 }
    open override class var defaultRevision: Int { VNTrackObjectRequestRevision2 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNTrackObjectRequestRevision1...VNTrackObjectRequestRevision2)
    }
}

open class VNTrackRectangleRequest: VNTrackingRequest, @unchecked Sendable {
    public convenience init(rectangleObservation observation: VNRectangleObservation) {
        self.init(rectangleObservation: observation, completionHandler: nil)
    }

    public init(
        rectangleObservation observation: VNRectangleObservation,
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        super.init(completionHandler: completionHandler)
        self.inputObservation = observation
    }

    open override class var currentRevision: Int { VNTrackRectangleRequestRevision1 }
    open override class var defaultRevision: Int { VNTrackRectangleRequestRevision1 }
}

open class VNHomographicImageRegistrationRequest: VNImageRegistrationRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNHomographicImageRegistrationRequestRevision1 }
    open override class var defaultRevision: Int { VNHomographicImageRegistrationRequestRevision1 }
}

open class VNTranslationalImageRegistrationRequest: VNImageRegistrationRequest, @unchecked Sendable {
    open override class var currentRevision: Int { VNTranslationalImageRegistrationRequestRevision1 }
    open override class var defaultRevision: Int { VNTranslationalImageRegistrationRequestRevision1 }
}

open class VNGenerateOpticalFlowRequest: VNTargetedImageRequest, @unchecked Sendable {
    public enum ComputationAccuracy: UInt, Sendable, Hashable {
        case low = 0
        case medium = 1
        case high = 2
        case veryHigh = 3
    }

    public var computationAccuracy: ComputationAccuracy = .medium

    open override class var currentRevision: Int { VNGenerateOpticalFlowRequestRevision2 }
    open override class var defaultRevision: Int { VNGenerateOpticalFlowRequestRevision2 }
    open override class var supportedRevisions: IndexSet {
        IndexSet(
            integersIn: VNGenerateOpticalFlowRequestRevision1...VNGenerateOpticalFlowRequestRevision2
        )
    }
}
