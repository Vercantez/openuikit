import Foundation

public typealias VNConfidence = Float
public typealias VNAspectRatio = Float
public typealias VNDegrees = Float

public typealias VNRequestCompletionHandler = (VNRequest, (any Error)?) -> Void
public typealias VNRequestProgressHandler = (VNRequest, Double, (any Error)?) -> Void

/// Named “unspecified” in the public graph and in independent macios bindings.
public let VNRequestRevisionUnspecified: Int = 0

public let VNDetectBarcodesRequestRevision1: Int = 1
public let VNDetectBarcodesRequestRevision2: Int = 2
public let VNDetectBarcodesRequestRevision3: Int = 3
public let VNDetectBarcodesRequestRevision4: Int = 4

public let VNDetectFaceRectanglesRequestRevision1: Int = 1
public let VNDetectFaceRectanglesRequestRevision2: Int = 2
public let VNDetectFaceRectanglesRequestRevision3: Int = 3

public let VNDetectRectanglesRequestRevision1: Int = 1

public let VNRecognizeTextRequestRevision1: Int = 1
public let VNRecognizeTextRequestRevision2: Int = 2
public let VNRecognizeTextRequestRevision3: Int = 3

public let VNDetectDocumentSegmentationRequestRevision1: Int = 1

public let VNGenerateAttentionBasedSaliencyImageRequestRevision1: Int = 1
public let VNGenerateAttentionBasedSaliencyImageRequestRevision2: Int = 2

/// Identity rectangle in Vision's normalized coordinate space.
public let VNNormalizedIdentityRect = CGRect(x: 0, y: 0, width: 1, height: 1)

/// Linux-local process identity. The C-string payload of `_VNErrorDomain`
/// is not an Apple-runtime observation in this tree.
public let VNErrorDomain: String = "VNErrorDomain"

/// Unobserved on this host; kept as a finite Double so clients can read it.
public var VNVisionVersionNumber: Double = 0

@_spi(OpenUIKitHost)
public enum VisionHost {
    public static let callbackQueue = DispatchQueue(label: "Vision.callback")

    public static func attachResults(_ results: [VNObservation], to request: VNRequest) {
        request.hostAttachResults(results)
    }

    public static func makeError(_ code: VNErrorCode, description: String? = nil) -> NSError {
        vnMakeError(code, description: description)
    }
}
