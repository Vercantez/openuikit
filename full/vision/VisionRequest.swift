//===----------------------------------------------------------------------===//
// Request / observation protocols and the VNRequest class hierarchy core.
//===----------------------------------------------------------------------===//

public protocol VNRequestRevisionProviding {
    var requestRevision: Int { get }
}

public protocol VNRequestProgressProviding: NSObjectProtocol {
    var indeterminate: Bool { get }
    var progressHandler: VNRequestProgressHandler { get set }
}

public protocol VNFaceObservationAccepting: NSObjectProtocol {
    var inputFaceObservations: [VNFaceObservation]? { get set }
}

open class VNRequest: NSObject, @unchecked Sendable {
    public let completionHandler: VNRequestCompletionHandler?
    public var preferBackgroundProcessing = false
    public var usesCPUOnly = false
    public var revision: Int
    public internal(set) var results: [VNObservation]?
    public var progressHandler: VNRequestProgressHandler = { _, _, _ in }

    internal var cancelled = false

    open class var currentRevision: Int { 1 }
    open class var defaultRevision: Int { currentRevision }
    open class var supportedRevisions: IndexSet {
        IndexSet(integer: currentRevision)
    }

    public var indeterminate: Bool { true }

    public convenience override init() {
        self.init(completionHandler: nil)
    }

    public init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.completionHandler = completionHandler
        self.revision = 0
        super.init()
        self.revision = Swift.type(of: self).defaultRevision
    }

    public func cancel() {
        cancelled = true
    }

    internal func finish(error: (any Error)?) {
        if error != nil {
            results = nil
        }
        completionHandler?(self, error)
    }

    internal func modelUnavailableError() -> VNError {
        visionError(
            .notImplemented,
            "Linux Vision has no Apple ML model for \(Swift.type(of: self))"
        )
    }
}

open class VNImageBasedRequest: VNRequest, @unchecked Sendable {
    public var regionOfInterest: CGRect = VNNormalizedIdentityRect
}

open class VNStatefulRequest: VNImageBasedRequest, @unchecked Sendable {
    public var minimumLatencyFrameCount: Int { 0 }
}

open class VNTargetedImageRequest: VNImageBasedRequest, @unchecked Sendable {
    internal let targetedImageData: Data?
    internal let targetedImageURL: URL?

    public override init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.targetedImageData = nil
        self.targetedImageURL = nil
        super.init(completionHandler: completionHandler)
    }

    public init(
        targetedImageData imageData: Data,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        self.targetedImageData = imageData
        self.targetedImageURL = nil
        super.init(completionHandler: completionHandler)
    }

    public init(
        targetedImageURL imageURL: URL,
        options: [VNImageOption: Any] = [:],
        completionHandler: VNRequestCompletionHandler? = nil
    ) {
        _ = options
        self.targetedImageData = nil
        self.targetedImageURL = imageURL
        super.init(completionHandler: completionHandler)
    }
}

open class VNImageRegistrationRequest: VNTargetedImageRequest, @unchecked Sendable {}

open class VNTrackingRequest: VNImageBasedRequest, @unchecked Sendable {
    public var inputObservation: VNDetectedObjectObservation
    public var isLastFrame = false
    public var trackingLevel: VNRequestTrackingLevel = .accurate

    public override init(completionHandler: VNRequestCompletionHandler? = nil) {
        self.inputObservation = VNDetectedObjectObservation(boundingBox: .zero)
        super.init(completionHandler: completionHandler)
    }

    public func supportedNumber(
        ofTrackersAndReturnError error: UnsafeMutablePointer<NSError?>?
    ) -> Int {
        if let error {
            error.pointee = visionError(
                .notImplemented,
                "Linux Vision has no object-tracker runtime"
            ) as NSError
        }
        return 0
    }
}
