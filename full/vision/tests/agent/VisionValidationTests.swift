#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testRequestROIValidation() {
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let request = VNDetectRectanglesRequest()
    request.regionOfInterest = CGRect(x: -0.1, y: 0, width: 0.5, height: 0.5)
    do {
        try handler.perform([request])
        visionExpect(false, "negative origin ROI should throw")
    } catch let error as NSError {
        visionExpectEqual(error.domain, VNErrorDomain, "roi domain")
        visionExpectEqual(error.code, VNErrorCode.outOfBoundsError.rawValue, "roi out of bounds")
        visionExpect(request.results == nil, "roi failure results nil")
    }
    let oversized = VNDetectBarcodesRequest()
    oversized.regionOfInterest = CGRect(x: 0.2, y: 0.2, width: 0.9, height: 0.9)
    do {
        try handler.perform([oversized])
        visionExpect(false, "oversized ROI should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.outOfBoundsError.rawValue, "roi overflow")
    }
    let negative = VNDetectContoursRequest()
    negative.regionOfInterest = CGRect(x: 0.2, y: 0.2, width: -0.1, height: 0.2)
    do {
        try handler.perform([negative])
        visionExpect(false, "negative size ROI should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidArgument.rawValue, "negative size")
    }
}

func testRequestRevisionValidation() {
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let request = VNDetectRectanglesRequest()
    request.revision = 99
    do {
        try handler.perform([request])
        visionExpect(false, "unsupported revision should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.unsupportedRevision.rawValue, "unsupported revision")
        visionExpect(request.results == nil, "revision failure results nil")
    }
    visionExpect(VNDetectRectanglesRequest.supportedRevisions.contains(VNDetectRectanglesRequestRevision1), "supported")
    visionExpectEqual(VNDetectFaceLandmarksRequest.currentRevision, VNDetectFaceLandmarksRequestRevision3, "face landmarks rev")
    visionExpectEqual(VNDetectHumanHandPoseRequestRevision1, 1, "hand revision constant")
    visionExpectEqual(VNDetectAnimalBodyPoseRequestRevision1, 1, "animal revision")
    visionExpectEqual(VNDetectHumanBodyPose3DRequestRevision1, 1, "3d revision")
}

func testTrackObjectRequestState() {
    let seed = VNDetectedObjectObservation(boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))
    let tracker = VNTrackObjectRequest(detectedObjectObservation: seed)
    visionExpectEqual(tracker.inputObservation.boundingBox, seed.boundingBox, "input observation")
    tracker.trackingLevel = .fast
    visionExpectEqual(tracker.trackingLevel, .fast, "tracking level")
    tracker.isLastFrame = true
    visionExpectEqual(tracker.isLastFrame, true, "last frame")
    visionExpectEqual(VNTrackObjectRequest.currentRevision, VNTrackObjectRequestRevision2, "tracker revision")
    visionExpectEqual(tracker.supportedNumber(ofTrackersAndReturnError: nil), 1, "tracker count")
}

func testSequenceHandlerInvalidImageAndOrientation() {
    let sequence = VNSequenceRequestHandler()
    let request = VNDetectRectanglesRequest()
    do {
        try sequence.perform([request], onImageData: Data([0, 1, 2]), orientation: .down)
        visionExpect(false, "garbage data invalid image")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidImage.rawValue, "sequence invalid image")
    }
    let image = visionRectangleImage()
    request.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    request.revision = VNDetectRectanglesRequestRevision1
    request.minimumSize = 0.05
    try! sequence.perform([request], on: image, orientation: .up)
    visionExpect(request.results != nil, "oriented sequence perform")
}

func testDetectHumanHandPoseFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNDetectHumanHandPoseRequest()
    visionExpectEqual(request.revision, VNDetectHumanHandPoseRequestRevision1, "hand default revision")
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "hand invalidModel")
        visionExpect(request.results == nil, "hand results nil")
    }
    let animal = VNDetectAnimalBodyPoseRequest()
    do {
        try handler.perform([animal])
        visionExpect(false, "animal expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "animal invalidModel")
    }
    let pose3d = VNDetectHumanBodyPose3DRequest()
    do {
        try handler.perform([pose3d])
        visionExpect(false, "3d expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "3d invalidModel")
    }
    let horizonReq = VNDetectHorizonRequest()
    do {
        try handler.perform([horizonReq])
        visionExpect(false, "horizon expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "horizon invalidModel")
    }
    let textRects = VNDetectTextRectanglesRequest()
    do {
        try handler.perform([textRects])
        visionExpect(false, "text rect expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "text rect invalidModel")
    }
    let landmarksReq = VNDetectFaceLandmarksRequest()
    do {
        try handler.perform([landmarksReq])
        visionExpect(false, "landmarks expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "landmarks invalidModel")
    }
}

func testOverlayRecognizeTextFailClosedSync() {
    let request = RecognizeTextRequest()
    visionExpectEqual(request.revision, .revision3, "overlay text revision")
    visionExpectEqual(request.recognitionLevel, .accurate, "overlay text level")
    visionExpectEqual(RecognizeTextRequest.supportedRevisions, [.revision3], "overlay supported")
    visionExpectEqual(request.regionOfInterest, .fullImage, "overlay text roi")
    let face = DetectFaceRectanglesRequest()
    visionExpectEqual(face.revision, .revision3, "overlay face revision")
    visionExpectEqual(face.regionOfInterest, .fullImage, "overlay roi default")
    visionExpectEqual(DetectFaceRectanglesRequest.supportedRevisions, [.revision3], "overlay face supported")
}
