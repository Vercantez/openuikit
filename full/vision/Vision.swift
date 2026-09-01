//===----------------------------------------------------------------------===//
// Vision — Linux starting point for Apple's public Vision module.
//
// Geometry, request configuration, observation construction, and error
// identity are real. Machine-learning detection, tracking, Core ML, video,
// and hardware pose paths fail closed: they never invent Apple model output.
// Isolated host compilation has Foundation only; CGImage / CIImage /
// CVPixelBuffer / CMSampleBuffer entry points are omitted until those
// modules are linked by central review.
//===----------------------------------------------------------------------===//

@_exported import Foundation

public typealias VNAspectRatio = Float
public typealias VNConfidence = Float
public typealias VNDegrees = Float
public typealias vector_float2 = SIMD2<Float>

public typealias VNRequestCompletionHandler = (VNRequest, (any Error)?) -> Void
public typealias VNRequestProgressHandler = (VNRequest, Double, (any Error)?) -> Void
public typealias NSErrorPointer = UnsafeMutablePointer<NSError?>?

/// NSError domain for Vision failures. Exact Apple string is still an oracle
/// question; this token matches the public constant name until probed.
public let VNErrorDomain = "VNErrorDomain"

public let VNRequestRevisionUnspecified: Int = 0
public let VNNormalizedIdentityRect = CGRect(x: 0, y: 0, width: 1, height: 1)

public let VNCalculateImageAestheticsScoresRequestRevision1: Int = 1
public let VNClassifyImageRequestRevision1: Int = 1
public let VNClassifyImageRequestRevision2: Int = 2
public let VNCoreMLRequestRevision1: Int = 1
public let VNDetectAnimalBodyPoseRequestRevision1: Int = 1
public let VNDetectBarcodesRequestRevision1: Int = 1
public let VNDetectBarcodesRequestRevision2: Int = 2
public let VNDetectBarcodesRequestRevision3: Int = 3
public let VNDetectBarcodesRequestRevision4: Int = 4
public let VNDetectContourRequestRevision1: Int = 1
public let VNDetectDocumentSegmentationRequestRevision1: Int = 1
public let VNDetectFaceCaptureQualityRequestRevision1: Int = 1
public let VNDetectFaceCaptureQualityRequestRevision2: Int = 2
public let VNDetectFaceCaptureQualityRequestRevision3: Int = 3
public let VNDetectFaceLandmarksRequestRevision1: Int = 1
public let VNDetectFaceLandmarksRequestRevision2: Int = 2
public let VNDetectFaceLandmarksRequestRevision3: Int = 3
public let VNDetectFaceRectanglesRequestRevision1: Int = 1
public let VNDetectFaceRectanglesRequestRevision2: Int = 2
public let VNDetectFaceRectanglesRequestRevision3: Int = 3
public let VNDetectHorizonRequestRevision1: Int = 1
public let VNDetectHumanBodyPose3DRequestRevision1: Int = 1
public let VNDetectHumanBodyPoseRequestRevision1: Int = 1
public let VNDetectHumanHandPoseRequestRevision1: Int = 1
public let VNDetectHumanRectanglesRequestRevision1: Int = 1
public let VNDetectHumanRectanglesRequestRevision2: Int = 2
public let VNDetectRectanglesRequestRevision1: Int = 1
public let VNDetectTextRectanglesRequestRevision1: Int = 1
public let VNDetectTrajectoriesRequestRevision1: Int = 1
public let VNGenerateAttentionBasedSaliencyImageRequestRevision1: Int = 1
public let VNGenerateAttentionBasedSaliencyImageRequestRevision2: Int = 2
public let VNGenerateForegroundInstanceMaskRequestRevision1: Int = 1
public let VNGenerateImageFeaturePrintRequestRevision1: Int = 1
public let VNGenerateImageFeaturePrintRequestRevision2: Int = 2
public let VNGenerateObjectnessBasedSaliencyImageRequestRevision1: Int = 1
public let VNGenerateObjectnessBasedSaliencyImageRequestRevision2: Int = 2
public let VNGenerateOpticalFlowRequestRevision1: Int = 1
public let VNGenerateOpticalFlowRequestRevision2: Int = 2
public let VNGeneratePersonInstanceMaskRequestRevision1: Int = 1
public let VNGeneratePersonSegmentationRequestRevision1: Int = 1
public let VNHomographicImageRegistrationRequestRevision1: Int = 1
public let VNRecognizeAnimalsRequestRevision1: Int = 1
public let VNRecognizeAnimalsRequestRevision2: Int = 2
public let VNRecognizeTextRequestRevision1: Int = 1
public let VNRecognizeTextRequestRevision2: Int = 2
public let VNRecognizeTextRequestRevision3: Int = 3
public let VNTrackHomographicImageRegistrationRequestRevision1: Int = 1
public let VNTrackObjectRequestRevision1: Int = 1
public let VNTrackObjectRequestRevision2: Int = 2
public let VNTrackOpticalFlowRequestRevision1: Int = 1
public let VNTrackRectangleRequestRevision1: Int = 1
public let VNTrackTranslationalImageRegistrationRequestRevision1: Int = 1
public let VNTranslationalImageRegistrationRequestRevision1: Int = 1

/// Bridged `NS_ERROR_ENUM` overlay. Numeric codes follow the public
/// `VNErrorCode` case order in the pinned graph (`OK` = 0, then sequential).
/// `turiCoreErrorCode` is isolated at 10_000 pending an Apple-oracle probe.
public enum VNErrorCode: Int, Sendable, Hashable {
    case OK = 0
    case requestCancelled = 1
    case invalidFormat = 2
    case operationFailed = 3
    case outOfBoundsError = 4
    case invalidOption = 5
    case ioError = 6
    case missingOption = 7
    case notImplemented = 8
    case internalError = 9
    case outOfMemory = 10
    case unknownError = 11
    case invalidOperation = 12
    case invalidImage = 13
    case invalidArgument = 14
    case invalidModel = 15
    case unsupportedRevision = 16
    case dataUnavailable = 17
    case timeStampNotFound = 18
    case unsupportedRequest = 19
    case timeout = 20
    case unsupportedComputeStage = 21
    case unsupportedComputeDevice = 22
    case turiCoreErrorCode = 10_000
}

public struct VNError: Error, CustomNSError, Hashable, @unchecked Sendable {
    public let code: VNErrorCode
    public let userInfo: [String: Any]

    public init(_ code: VNErrorCode, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { VNErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static func == (lhs: VNError, rhs: VNError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

internal func visionError(
    _ code: VNErrorCode,
    _ message: String
) -> VNError {
    VNError(code, userInfo: [NSLocalizedDescriptionKey: message])
}

public func VNElementTypeSize(_ elementType: VNElementType) -> Int {
    switch elementType {
    case .unknown:
        return 0
    case .float:
        return MemoryLayout<Float>.size
    case .double:
        return MemoryLayout<Double>.size
    }
}

public func VNNormalizedRectIsIdentityRect(_ normalizedRect: CGRect) -> Bool {
    normalizedRect.origin.x == 0
        && normalizedRect.origin.y == 0
        && normalizedRect.size.width == 1
        && normalizedRect.size.height == 1
}

public func VNImagePointForNormalizedPoint(
    _ normalizedPoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    CGPoint(
        x: normalizedPoint.x * CGFloat(imageWidth),
        y: normalizedPoint.y * CGFloat(imageHeight)
    )
}

public func VNNormalizedPointForImagePoint(
    _ imagePoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    guard imageWidth != 0, imageHeight != 0 else { return .zero }
    return CGPoint(
        x: imagePoint.x / CGFloat(imageWidth),
        y: imagePoint.y / CGFloat(imageHeight)
    )
}

public func VNImageRectForNormalizedRect(
    _ normalizedRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGRect {
    CGRect(
        x: normalizedRect.origin.x * CGFloat(imageWidth),
        y: normalizedRect.origin.y * CGFloat(imageHeight),
        width: normalizedRect.size.width * CGFloat(imageWidth),
        height: normalizedRect.size.height * CGFloat(imageHeight)
    )
}

public func VNNormalizedRectForImageRect(
    _ imageRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGRect {
    guard imageWidth != 0, imageHeight != 0 else { return .zero }
    return CGRect(
        x: imageRect.origin.x / CGFloat(imageWidth),
        y: imageRect.origin.y / CGFloat(imageHeight),
        width: imageRect.size.width / CGFloat(imageWidth),
        height: imageRect.size.height / CGFloat(imageHeight)
    )
}

public func VNImagePointForNormalizedPointUsingRegionOfInterest(
    _ normalizedPoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGPoint {
    let imageROI = VNImageRectForNormalizedRect(roi, imageWidth, imageHeight)
    return CGPoint(
        x: imageROI.origin.x + normalizedPoint.x * imageROI.size.width,
        y: imageROI.origin.y + normalizedPoint.y * imageROI.size.height
    )
}

public func VNNormalizedPointForImagePointUsingRegionOfInterest(
    _ imagePoint: CGPoint,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGPoint {
    let imageROI = VNImageRectForNormalizedRect(roi, imageWidth, imageHeight)
    guard imageROI.size.width != 0, imageROI.size.height != 0 else { return .zero }
    return CGPoint(
        x: (imagePoint.x - imageROI.origin.x) / imageROI.size.width,
        y: (imagePoint.y - imageROI.origin.y) / imageROI.size.height
    )
}

public func VNImageRectForNormalizedRectUsingRegionOfInterest(
    _ normalizedRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGRect {
    let imageROI = VNImageRectForNormalizedRect(roi, imageWidth, imageHeight)
    return CGRect(
        x: imageROI.origin.x + normalizedRect.origin.x * imageROI.size.width,
        y: imageROI.origin.y + normalizedRect.origin.y * imageROI.size.height,
        width: normalizedRect.size.width * imageROI.size.width,
        height: normalizedRect.size.height * imageROI.size.height
    )
}

public func VNNormalizedRectForImageRectUsingRegionOfInterest(
    _ imageRect: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int,
    _ roi: CGRect
) -> CGRect {
    let imageROI = VNImageRectForNormalizedRect(roi, imageWidth, imageHeight)
    guard imageROI.size.width != 0, imageROI.size.height != 0 else { return .zero }
    return CGRect(
        x: (imageRect.origin.x - imageROI.origin.x) / imageROI.size.width,
        y: (imageRect.origin.y - imageROI.origin.y) / imageROI.size.height,
        width: imageRect.size.width / imageROI.size.width,
        height: imageRect.size.height / imageROI.size.height
    )
}

public func VNImagePointForFaceLandmarkPoint(
    _ faceLandmarkPoint: vector_float2,
    _ faceBoundingBox: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    let normalized = CGPoint(
        x: faceBoundingBox.origin.x
            + CGFloat(faceLandmarkPoint.x) * faceBoundingBox.size.width,
        y: faceBoundingBox.origin.y
            + CGFloat(faceLandmarkPoint.y) * faceBoundingBox.size.height
    )
    return VNImagePointForNormalizedPoint(normalized, imageWidth, imageHeight)
}

public func VNNormalizedFaceBoundingBoxPointForLandmarkPoint(
    _ faceLandmarkPoint: vector_float2,
    _ faceBoundingBox: CGRect,
    _ imageWidth: Int,
    _ imageHeight: Int
) -> CGPoint {
    let imagePoint = VNImagePointForFaceLandmarkPoint(
        faceLandmarkPoint,
        faceBoundingBox,
        imageWidth,
        imageHeight
    )
    return VNNormalizedPointForImagePoint(imagePoint, imageWidth, imageHeight)
}
