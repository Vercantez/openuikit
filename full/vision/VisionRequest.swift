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
}

open class VNDetectFaceRectanglesRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectFaceRectanglesRequestRevision3 }
    public override class var defaultRevision: Int { VNDetectFaceRectanglesRequestRevision3 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNDetectFaceRectanglesRequestRevision1...VNDetectFaceRectanglesRequestRevision3)
    }
}

open class VNDetectFaceLandmarksRequest: VNImageBasedRequest {
    public var constellation: VNRequestFaceLandmarksConstellation = .constellationNotDefined
}

open class VNDetectDocumentSegmentationRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }
    public override class var defaultRevision: Int { VNDetectDocumentSegmentationRequestRevision1 }
}

open class VNGenerateAttentionBasedSaliencyImageRequest: VNImageBasedRequest {
    public override class var currentRevision: Int { VNGenerateAttentionBasedSaliencyImageRequestRevision2 }
    public override class var defaultRevision: Int { VNGenerateAttentionBasedSaliencyImageRequestRevision2 }
    public override class var supportedRevisions: IndexSet {
        IndexSet(integersIn: VNGenerateAttentionBasedSaliencyImageRequestRevision1...VNGenerateAttentionBasedSaliencyImageRequestRevision2)
    }
}

open class VNTargetedImageRequest: VNImageBasedRequest {}

open class VNGenerateOpticalFlowRequest: VNTargetedImageRequest {
    public enum ComputationAccuracy: UInt, CaseIterable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        case veryHigh = 3
    }

    public var computationAccuracy: ComputationAccuracy = .medium
}

open class VNGeneratePersonSegmentationRequest: VNImageBasedRequest {
    public enum QualityLevel: UInt, CaseIterable, Sendable {
        case accurate = 0
        case balanced = 1
        case fast = 2
    }

    public var qualityLevel: QualityLevel = .balanced
}

open class VNTrackingRequest: VNImageBasedRequest {
    public var trackingLevel: VNRequestTrackingLevel = .accurate
    public var isLastFrame: Bool = false
}

open class VNTrackObjectRequest: VNTrackingRequest {}

open class VNTrackRectangleRequest: VNTrackingRequest {}

open class VNTrackOpticalFlowRequest: VNTrackingRequest {
    public enum ComputationAccuracy: UInt, CaseIterable, Sendable {
        case low = 0
        case medium = 1
        case high = 2
        case veryHigh = 3
    }

    public var computationAccuracy: ComputationAccuracy = .medium
}

open class VNImageRegistrationRequest: VNTargetedImageRequest {}

open class VNTranslationalImageRegistrationRequest: VNImageRegistrationRequest {}

open class VNHomographicImageRegistrationRequest: VNImageRegistrationRequest {}

open class VNImageRequestHandler: NSObject {
    @_spi(OpenUIKitHost)
    public enum Source: Equatable {
        case data(Data)
        case url(URL)
    }

    @_spi(OpenUIKitHost)
    public let source: Source
    public let options: [VNImageOption: Any]

    public init(data imageData: Data, options: [VNImageOption: Any] = [:]) {
        self.source = .data(imageData)
        self.options = options
        super.init()
    }

    public init(url imageURL: URL, options: [VNImageOption: Any] = [:]) {
        self.source = .url(imageURL)
        self.options = options
        super.init()
    }

    public convenience init(URL imageURL: URL, options: [VNImageOption: Any] = [:]) {
        self.init(url: imageURL, options: options)
    }

    public func perform(_ requests: [VNRequest]) throws {
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
            let error = vnMakeError(
                .notImplemented,
                description: "Vision ML / model execution is unavailable on this Linux host"
            )
            request.finish(nil, error: error)
            throw error
        }
    }
}

open class VNSequenceRequestHandler: NSObject {
    public override init() {
        super.init()
    }

    public func perform(_ requests: [VNRequest], onImageData imageData: Data) throws {
        _ = imageData
        try VNImageRequestHandler(data: imageData, options: [:]).perform(requests)
    }

    public func perform(_ requests: [VNRequest], onImageURL imageURL: URL) throws {
        try VNImageRequestHandler(url: imageURL, options: [:]).perform(requests)
    }
}
