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

public let VNClassifyImageRequestRevision1: Int = 1
public let VNClassifyImageRequestRevision2: Int = 2
public let VNCoreMLRequestRevision1: Int = 1
/// Public graph spelling omits the plural *s* used by the class name.
public let VNDetectContourRequestRevision1: Int = 1
public let VNDetectContoursRequestRevision1: Int = VNDetectContourRequestRevision1
public let VNDetectHumanBodyPoseRequestRevision1: Int = 1
public let VNGenerateImageFeaturePrintRequestRevision1: Int = 1
public let VNGenerateImageFeaturePrintRequestRevision2: Int = 2
public let VNHomographicImageRegistrationRequestRevision1: Int = 1
public let VNTrackObjectRequestRevision1: Int = 1
public let VNTrackObjectRequestRevision2: Int = 2
public let VNTranslationalImageRegistrationRequestRevision1: Int = 1
public let VNDetectAnimalBodyPoseRequestRevision1: Int = 1
public let VNDetectFaceCaptureQualityRequestRevision1: Int = 1
public let VNDetectFaceCaptureQualityRequestRevision2: Int = 2
public let VNDetectFaceCaptureQualityRequestRevision3: Int = 3
public let VNDetectFaceLandmarksRequestRevision1: Int = 1
public let VNDetectFaceLandmarksRequestRevision2: Int = 2
public let VNDetectFaceLandmarksRequestRevision3: Int = 3
public let VNDetectHorizonRequestRevision1: Int = 1
public let VNDetectHumanBodyPose3DRequestRevision1: Int = 1
public let VNDetectHumanHandPoseRequestRevision1: Int = 1
public let VNDetectHumanRectanglesRequestRevision1: Int = 1
public let VNDetectHumanRectanglesRequestRevision2: Int = 2
public let VNDetectTextRectanglesRequestRevision1: Int = 1
public let VNDetectTrajectoriesRequestRevision1: Int = 1
public let VNCalculateImageAestheticsScoresRequestRevision1: Int = 1
public let VNGenerateForegroundInstanceMaskRequestRevision1: Int = 1
public let VNGenerateObjectnessBasedSaliencyImageRequestRevision1: Int = 1
public let VNGenerateObjectnessBasedSaliencyImageRequestRevision2: Int = 2
public let VNGenerateOpticalFlowRequestRevision1: Int = 1
public let VNGenerateOpticalFlowRequestRevision2: Int = 2
public let VNGeneratePersonInstanceMaskRequestRevision1: Int = 1
public let VNGeneratePersonSegmentationRequestRevision1: Int = 1
public let VNRecognizeAnimalsRequestRevision1: Int = 1
public let VNRecognizeAnimalsRequestRevision2: Int = 2
public let VNTrackHomographicImageRegistrationRequestRevision1: Int = 1
public let VNTrackOpticalFlowRequestRevision1: Int = 1
public let VNTrackRectangleRequestRevision1: Int = 1
public let VNTrackTranslationalImageRegistrationRequestRevision1: Int = 1

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

    public static func makeCGImage(width: Int, height: Int, rgba: [UInt8]) -> CGImage {
        CGImage(width: width, height: height, pixels: rgba)
    }

    public static func encodeNetpbm(_ image: CGImage) -> Data {
        VisionRaster(cgImage: image).netpbmData()
    }

    public static func encodeRaw(_ image: CGImage) -> Data {
        VisionImageCodec.encodeRaw(VisionRaster(cgImage: image))
    }

    public static func makeQRImage(payload: String, moduleSize: Int = 4, quietZone: Int = 4) throws -> CGImage {
        try QRCode.encode(payload).raster(moduleSize: moduleSize, quietZone: quietZone).makeCGImage()
    }

    public static func makeCode128Image(
        payload: String,
        moduleWidth: Int = 2,
        barHeight: Int = 48,
        quiet: Int = 16
    ) throws -> CGImage {
        try Code128.encode(payload).raster(
            moduleWidth: moduleWidth,
            barHeight: barHeight,
            quiet: quiet
        ).makeCGImage()
    }

    public static func makeEAN13Image(
        payload: String,
        moduleWidth: Int = 2,
        barHeight: Int = 48,
        quiet: Int = 16
    ) throws -> CGImage {
        try EAN13.encode(payload).raster(
            moduleWidth: moduleWidth,
            barHeight: barHeight,
            quiet: quiet
        ).makeCGImage()
    }
}
