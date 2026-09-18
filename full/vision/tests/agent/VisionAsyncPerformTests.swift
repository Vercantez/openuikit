#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

/// In-process async coverage for the `ImageProcessingRequest.perform(on:orientation:)`
/// family and the `ImageRequestHandler` / `TargetedImageRequestHandler` async
/// `perform` overloads. Every async `perform` below delegates synchronously to
/// the matching `performOnHandler` / `performNow` path (no frame waits, no
/// semaphore, no run-loop), so awaiting them in-process returns immediately.
/// Classical requests succeed on the valid QR fixture; model-backed requests
/// fail closed with `VisionError.invalidModel`, matching their synchronous path.

func visionAsyncExpectInvalidModel(_ label: String, _ work: () async throws -> Void) async {
    do {
        try await work()
        visionExpect(false, label + " should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            return
        }
        visionExpect(false, "\(label) unexpected \(error)")
    } catch {
        visionExpect(false, "\(label) wrong error type \(error)")
    }
}

func visionAsyncTrackSeed() -> DetectedObjectObservation {
    DetectedObjectObservation(boundingBox: NormalizedRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4))
}

func testAsyncPerformOnURL() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("vision-async-perform.ppm")
    try! VisionHost.encodeNetpbm(qrImage).write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    let barcodeHits = try! await DetectBarcodesRequest().perform(on: url, orientation: nil)
    visionExpect(barcodeHits.contains(where: { $0.payloadString == "HELLO" }), "async url QR")
    _ = try! await DetectRectanglesRequest().perform(on: url, orientation: nil)
    _ = try! await DetectContoursRequest().perform(on: url, orientation: nil)
    _ = try! await GenerateImageFeaturePrintRequest().perform(on: url, orientation: nil)
    _ = try! await DetectHorizonRequest().perform(on: url, orientation: nil)
    _ = try! await DetectLensSmudgeRequest().perform(on: url, orientation: nil)
    _ = try! await DetectTrajectoriesRequest().perform(on: url, orientation: nil)
    _ = try! await DetectTextRectanglesRequest().perform(on: url, orientation: nil)
    _ = try! await DetectDocumentSegmentationRequest().perform(on: url, orientation: nil)
    _ = try! await CalculateImageAestheticsScoresRequest().perform(on: url, orientation: nil)
    _ = try! await GenerateForegroundInstanceMaskRequest().perform(on: url, orientation: nil)
    _ = try! await GenerateAttentionBasedSaliencyImageRequest().perform(on: url, orientation: nil)
    _ = try! await GenerateObjectnessBasedSaliencyImageRequest().perform(on: url, orientation: nil)
    _ = try! await TrackObjectRequest(detectedObject: visionAsyncTrackSeed()).perform(on: url, orientation: nil)
    _ = try! await TrackRectangleRequest().perform(on: url, orientation: nil)
    _ = try! await TrackOpticalFlowRequest().perform(on: url, orientation: nil)
    _ = try! await TrackHomographicImageRegistrationRequest().perform(on: url, orientation: nil)
    _ = try! await TrackTranslationalImageRegistrationRequest().perform(on: url, orientation: nil)
    await visionAsyncExpectInvalidModel("ClassifyImageRequest url") {
        _ = try await ClassifyImageRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest url") {
        _ = try await RecognizeTextRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceRectanglesRequest url") {
        _ = try await DetectFaceRectanglesRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPoseRequest url") {
        _ = try await DetectHumanBodyPoseRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeAnimalsRequest url") {
        _ = try await RecognizeAnimalsRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeDocumentsRequest url") {
        _ = try await RecognizeDocumentsRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceLandmarksRequest url") {
        _ = try await DetectFaceLandmarksRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanHandPoseRequest url") {
        _ = try await DetectHumanHandPoseRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectAnimalBodyPoseRequest url") {
        _ = try await DetectAnimalBodyPoseRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanRectanglesRequest url") {
        _ = try await DetectHumanRectanglesRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceCaptureQualityRequest url") {
        _ = try await DetectFaceCaptureQualityRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonInstanceMaskRequest url") {
        _ = try await GeneratePersonInstanceMaskRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonSegmentationRequest url") {
        _ = try await GeneratePersonSegmentationRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPose3DRequest url") {
        _ = try await DetectHumanBodyPose3DRequest().perform(on: url, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("CoreMLRequest url") {
        _ = try await CoreMLRequest(.revision1).perform(on: url, orientation: nil)
    }
}

func testAsyncPerformOnData() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let data = VisionHost.encodeNetpbm(qrImage)
    let barcodeHits = try! await DetectBarcodesRequest().perform(on: data, orientation: nil)
    visionExpect(barcodeHits.contains(where: { $0.payloadString == "HELLO" }), "async data QR")
    _ = try! await DetectRectanglesRequest().perform(on: data, orientation: nil)
    _ = try! await DetectContoursRequest().perform(on: data, orientation: nil)
    _ = try! await GenerateImageFeaturePrintRequest().perform(on: data, orientation: nil)
    _ = try! await DetectHorizonRequest().perform(on: data, orientation: nil)
    _ = try! await DetectLensSmudgeRequest().perform(on: data, orientation: nil)
    _ = try! await DetectTrajectoriesRequest().perform(on: data, orientation: nil)
    _ = try! await DetectTextRectanglesRequest().perform(on: data, orientation: nil)
    _ = try! await DetectDocumentSegmentationRequest().perform(on: data, orientation: nil)
    _ = try! await CalculateImageAestheticsScoresRequest().perform(on: data, orientation: nil)
    _ = try! await GenerateForegroundInstanceMaskRequest().perform(on: data, orientation: nil)
    _ = try! await GenerateAttentionBasedSaliencyImageRequest().perform(on: data, orientation: nil)
    _ = try! await GenerateObjectnessBasedSaliencyImageRequest().perform(on: data, orientation: nil)
    _ = try! await TrackObjectRequest(detectedObject: visionAsyncTrackSeed()).perform(on: data, orientation: nil)
    _ = try! await TrackRectangleRequest().perform(on: data, orientation: nil)
    _ = try! await TrackOpticalFlowRequest().perform(on: data, orientation: nil)
    _ = try! await TrackHomographicImageRegistrationRequest().perform(on: data, orientation: nil)
    _ = try! await TrackTranslationalImageRegistrationRequest().perform(on: data, orientation: nil)
    await visionAsyncExpectInvalidModel("ClassifyImageRequest data") {
        _ = try await ClassifyImageRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest data") {
        _ = try await RecognizeTextRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceRectanglesRequest data") {
        _ = try await DetectFaceRectanglesRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPoseRequest data") {
        _ = try await DetectHumanBodyPoseRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeAnimalsRequest data") {
        _ = try await RecognizeAnimalsRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeDocumentsRequest data") {
        _ = try await RecognizeDocumentsRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceLandmarksRequest data") {
        _ = try await DetectFaceLandmarksRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanHandPoseRequest data") {
        _ = try await DetectHumanHandPoseRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectAnimalBodyPoseRequest data") {
        _ = try await DetectAnimalBodyPoseRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanRectanglesRequest data") {
        _ = try await DetectHumanRectanglesRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceCaptureQualityRequest data") {
        _ = try await DetectFaceCaptureQualityRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonInstanceMaskRequest data") {
        _ = try await GeneratePersonInstanceMaskRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonSegmentationRequest data") {
        _ = try await GeneratePersonSegmentationRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPose3DRequest data") {
        _ = try await DetectHumanBodyPose3DRequest().perform(on: data, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("CoreMLRequest data") {
        _ = try await CoreMLRequest(.revision1).perform(on: data, orientation: nil)
    }
}

func testAsyncPerformOnCGImage() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let barcodeHits = try! await DetectBarcodesRequest().perform(on: qrImage, orientation: nil)
    visionExpect(barcodeHits.contains(where: { $0.payloadString == "HELLO" }), "async cgimage QR")
    _ = try! await DetectRectanglesRequest().perform(on: qrImage, orientation: nil)
    _ = try! await DetectContoursRequest().perform(on: qrImage, orientation: nil)
    _ = try! await GenerateImageFeaturePrintRequest().perform(on: qrImage, orientation: nil)
    _ = try! await DetectHorizonRequest().perform(on: qrImage, orientation: nil)
    _ = try! await DetectLensSmudgeRequest().perform(on: qrImage, orientation: nil)
    _ = try! await DetectTrajectoriesRequest().perform(on: qrImage, orientation: nil)
    _ = try! await DetectTextRectanglesRequest().perform(on: qrImage, orientation: nil)
    _ = try! await DetectDocumentSegmentationRequest().perform(on: qrImage, orientation: nil)
    _ = try! await CalculateImageAestheticsScoresRequest().perform(on: qrImage, orientation: nil)
    _ = try! await GenerateForegroundInstanceMaskRequest().perform(on: qrImage, orientation: nil)
    _ = try! await GenerateAttentionBasedSaliencyImageRequest().perform(on: qrImage, orientation: nil)
    _ = try! await GenerateObjectnessBasedSaliencyImageRequest().perform(on: qrImage, orientation: nil)
    _ = try! await TrackObjectRequest(detectedObject: visionAsyncTrackSeed()).perform(on: qrImage, orientation: nil)
    _ = try! await TrackRectangleRequest().perform(on: qrImage, orientation: nil)
    _ = try! await TrackOpticalFlowRequest().perform(on: qrImage, orientation: nil)
    _ = try! await TrackHomographicImageRegistrationRequest().perform(on: qrImage, orientation: nil)
    _ = try! await TrackTranslationalImageRegistrationRequest().perform(on: qrImage, orientation: nil)
    await visionAsyncExpectInvalidModel("ClassifyImageRequest cgimage") {
        _ = try await ClassifyImageRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest cgimage") {
        _ = try await RecognizeTextRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceRectanglesRequest cgimage") {
        _ = try await DetectFaceRectanglesRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPoseRequest cgimage") {
        _ = try await DetectHumanBodyPoseRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeAnimalsRequest cgimage") {
        _ = try await RecognizeAnimalsRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeDocumentsRequest cgimage") {
        _ = try await RecognizeDocumentsRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceLandmarksRequest cgimage") {
        _ = try await DetectFaceLandmarksRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanHandPoseRequest cgimage") {
        _ = try await DetectHumanHandPoseRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectAnimalBodyPoseRequest cgimage") {
        _ = try await DetectAnimalBodyPoseRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanRectanglesRequest cgimage") {
        _ = try await DetectHumanRectanglesRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceCaptureQualityRequest cgimage") {
        _ = try await DetectFaceCaptureQualityRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonInstanceMaskRequest cgimage") {
        _ = try await GeneratePersonInstanceMaskRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonSegmentationRequest cgimage") {
        _ = try await GeneratePersonSegmentationRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPose3DRequest cgimage") {
        _ = try await DetectHumanBodyPose3DRequest().perform(on: qrImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("CoreMLRequest cgimage") {
        _ = try await CoreMLRequest(.revision1).perform(on: qrImage, orientation: nil)
    }
}

func testAsyncPerformOnPixelBuffer() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let pixelBuffer = VisionRaster(cgImage: qrImage).makePixelBuffer()
    let barcodeHits = try! await DetectBarcodesRequest().perform(on: pixelBuffer, orientation: nil)
    visionExpect(barcodeHits.contains(where: { $0.payloadString == "HELLO" }), "async pixelbuffer QR")
    _ = try! await DetectRectanglesRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await DetectContoursRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await GenerateImageFeaturePrintRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await DetectHorizonRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await DetectLensSmudgeRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await DetectTrajectoriesRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await DetectTextRectanglesRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await DetectDocumentSegmentationRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await CalculateImageAestheticsScoresRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await GenerateForegroundInstanceMaskRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await GenerateAttentionBasedSaliencyImageRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await GenerateObjectnessBasedSaliencyImageRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await TrackObjectRequest(detectedObject: visionAsyncTrackSeed()).perform(on: pixelBuffer, orientation: nil)
    _ = try! await TrackRectangleRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await TrackOpticalFlowRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await TrackHomographicImageRegistrationRequest().perform(on: pixelBuffer, orientation: nil)
    _ = try! await TrackTranslationalImageRegistrationRequest().perform(on: pixelBuffer, orientation: nil)
    await visionAsyncExpectInvalidModel("ClassifyImageRequest pixelbuffer") {
        _ = try await ClassifyImageRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest pixelbuffer") {
        _ = try await RecognizeTextRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceRectanglesRequest pixelbuffer") {
        _ = try await DetectFaceRectanglesRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPoseRequest pixelbuffer") {
        _ = try await DetectHumanBodyPoseRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeAnimalsRequest pixelbuffer") {
        _ = try await RecognizeAnimalsRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeDocumentsRequest pixelbuffer") {
        _ = try await RecognizeDocumentsRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceLandmarksRequest pixelbuffer") {
        _ = try await DetectFaceLandmarksRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanHandPoseRequest pixelbuffer") {
        _ = try await DetectHumanHandPoseRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectAnimalBodyPoseRequest pixelbuffer") {
        _ = try await DetectAnimalBodyPoseRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanRectanglesRequest pixelbuffer") {
        _ = try await DetectHumanRectanglesRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceCaptureQualityRequest pixelbuffer") {
        _ = try await DetectFaceCaptureQualityRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonInstanceMaskRequest pixelbuffer") {
        _ = try await GeneratePersonInstanceMaskRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonSegmentationRequest pixelbuffer") {
        _ = try await GeneratePersonSegmentationRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPose3DRequest pixelbuffer") {
        _ = try await DetectHumanBodyPose3DRequest().perform(on: pixelBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("CoreMLRequest pixelbuffer") {
        _ = try await CoreMLRequest(.revision1).perform(on: pixelBuffer, orientation: nil)
    }
}

func testAsyncPerformOnSampleBuffer() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let sampleBuffer = CMSampleBuffer(pixelBuffer: VisionRaster(cgImage: qrImage).makePixelBuffer())
    let barcodeHits = try! await DetectBarcodesRequest().perform(on: sampleBuffer, orientation: nil)
    visionExpect(barcodeHits.contains(where: { $0.payloadString == "HELLO" }), "async samplebuffer QR")
    _ = try! await DetectRectanglesRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await DetectContoursRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await GenerateImageFeaturePrintRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await DetectHorizonRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await DetectLensSmudgeRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await DetectTrajectoriesRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await DetectTextRectanglesRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await DetectDocumentSegmentationRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await CalculateImageAestheticsScoresRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await GenerateForegroundInstanceMaskRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await GenerateAttentionBasedSaliencyImageRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await GenerateObjectnessBasedSaliencyImageRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await TrackObjectRequest(detectedObject: visionAsyncTrackSeed()).perform(on: sampleBuffer, orientation: nil)
    _ = try! await TrackRectangleRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await TrackOpticalFlowRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await TrackHomographicImageRegistrationRequest().perform(on: sampleBuffer, orientation: nil)
    _ = try! await TrackTranslationalImageRegistrationRequest().perform(on: sampleBuffer, orientation: nil)
    await visionAsyncExpectInvalidModel("ClassifyImageRequest samplebuffer") {
        _ = try await ClassifyImageRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest samplebuffer") {
        _ = try await RecognizeTextRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceRectanglesRequest samplebuffer") {
        _ = try await DetectFaceRectanglesRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPoseRequest samplebuffer") {
        _ = try await DetectHumanBodyPoseRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeAnimalsRequest samplebuffer") {
        _ = try await RecognizeAnimalsRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeDocumentsRequest samplebuffer") {
        _ = try await RecognizeDocumentsRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceLandmarksRequest samplebuffer") {
        _ = try await DetectFaceLandmarksRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanHandPoseRequest samplebuffer") {
        _ = try await DetectHumanHandPoseRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectAnimalBodyPoseRequest samplebuffer") {
        _ = try await DetectAnimalBodyPoseRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanRectanglesRequest samplebuffer") {
        _ = try await DetectHumanRectanglesRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceCaptureQualityRequest samplebuffer") {
        _ = try await DetectFaceCaptureQualityRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonInstanceMaskRequest samplebuffer") {
        _ = try await GeneratePersonInstanceMaskRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonSegmentationRequest samplebuffer") {
        _ = try await GeneratePersonSegmentationRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPose3DRequest samplebuffer") {
        _ = try await DetectHumanBodyPose3DRequest().perform(on: sampleBuffer, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("CoreMLRequest samplebuffer") {
        _ = try await CoreMLRequest(.revision1).perform(on: sampleBuffer, orientation: nil)
    }
}

func testAsyncPerformOnCIImage() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let ciImage = VisionRaster(cgImage: qrImage).makeCIImage()
    let barcodeHits = try! await DetectBarcodesRequest().perform(on: ciImage, orientation: nil)
    visionExpect(barcodeHits.contains(where: { $0.payloadString == "HELLO" }), "async ciimage QR")
    _ = try! await DetectRectanglesRequest().perform(on: ciImage, orientation: nil)
    _ = try! await DetectContoursRequest().perform(on: ciImage, orientation: nil)
    _ = try! await GenerateImageFeaturePrintRequest().perform(on: ciImage, orientation: nil)
    _ = try! await DetectHorizonRequest().perform(on: ciImage, orientation: nil)
    _ = try! await DetectLensSmudgeRequest().perform(on: ciImage, orientation: nil)
    _ = try! await DetectTrajectoriesRequest().perform(on: ciImage, orientation: nil)
    _ = try! await DetectTextRectanglesRequest().perform(on: ciImage, orientation: nil)
    _ = try! await DetectDocumentSegmentationRequest().perform(on: ciImage, orientation: nil)
    _ = try! await CalculateImageAestheticsScoresRequest().perform(on: ciImage, orientation: nil)
    _ = try! await GenerateForegroundInstanceMaskRequest().perform(on: ciImage, orientation: nil)
    _ = try! await GenerateAttentionBasedSaliencyImageRequest().perform(on: ciImage, orientation: nil)
    _ = try! await GenerateObjectnessBasedSaliencyImageRequest().perform(on: ciImage, orientation: nil)
    _ = try! await TrackObjectRequest(detectedObject: visionAsyncTrackSeed()).perform(on: ciImage, orientation: nil)
    _ = try! await TrackRectangleRequest().perform(on: ciImage, orientation: nil)
    _ = try! await TrackOpticalFlowRequest().perform(on: ciImage, orientation: nil)
    _ = try! await TrackHomographicImageRegistrationRequest().perform(on: ciImage, orientation: nil)
    _ = try! await TrackTranslationalImageRegistrationRequest().perform(on: ciImage, orientation: nil)
    await visionAsyncExpectInvalidModel("ClassifyImageRequest ciimage") {
        _ = try await ClassifyImageRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest ciimage") {
        _ = try await RecognizeTextRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceRectanglesRequest ciimage") {
        _ = try await DetectFaceRectanglesRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPoseRequest ciimage") {
        _ = try await DetectHumanBodyPoseRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeAnimalsRequest ciimage") {
        _ = try await RecognizeAnimalsRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("RecognizeDocumentsRequest ciimage") {
        _ = try await RecognizeDocumentsRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceLandmarksRequest ciimage") {
        _ = try await DetectFaceLandmarksRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanHandPoseRequest ciimage") {
        _ = try await DetectHumanHandPoseRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectAnimalBodyPoseRequest ciimage") {
        _ = try await DetectAnimalBodyPoseRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanRectanglesRequest ciimage") {
        _ = try await DetectHumanRectanglesRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectFaceCaptureQualityRequest ciimage") {
        _ = try await DetectFaceCaptureQualityRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonInstanceMaskRequest ciimage") {
        _ = try await GeneratePersonInstanceMaskRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("GeneratePersonSegmentationRequest ciimage") {
        _ = try await GeneratePersonSegmentationRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("DetectHumanBodyPose3DRequest ciimage") {
        _ = try await DetectHumanBodyPose3DRequest().perform(on: ciImage, orientation: nil)
    }
    await visionAsyncExpectInvalidModel("CoreMLRequest ciimage") {
        _ = try await CoreMLRequest(.revision1).perform(on: ciImage, orientation: nil)
    }
}

func testAsyncImageRequestHandlerPerform() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let handler = ImageRequestHandler(qrImage)
    let barcodeResults = try! await handler.perform(DetectBarcodesRequest())
    visionExpect(barcodeResults.contains(where: { $0.payloadString == "HELLO" }), "async handler QR")
    let rectangleResults = try! await handler.perform(DetectRectanglesRequest())
    _ = rectangleResults
    let printResults = try! await handler.perform(GenerateImageFeaturePrintRequest())
    _ = printResults
    await visionAsyncExpectInvalidModel("ClassifyImageRequest handler") {
        _ = try await handler.perform(ClassifyImageRequest())
    }
    await visionAsyncExpectInvalidModel("RecognizeTextRequest handler") {
        _ = try await handler.perform(RecognizeTextRequest())
    }
}

func testAsyncTargetedImageRequestHandlerPerform() async {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    let handler = TargetedImageRequestHandler(source: qrImage, target: qrImage)
    let seed = visionAsyncTrackSeed()
    await visionAsyncExpectInvalidModel("TrackObjectRequest targeted") {
        _ = try await handler.perform(TrackObjectRequest(detectedObject: seed))
    }
    await visionAsyncExpectInvalidModel("TrackObjectRequest targeted repeat") {
        _ = try await handler.perform(TrackObjectRequest(detectedObject: visionAsyncTrackSeed()))
    }
    let empty = TargetedImageRequestHandler(source: Data(), target: Data())
    do {
        _ = try await empty.perform(TrackObjectRequest(detectedObject: seed))
        visionExpect(false, "empty targeted should throw")
    } catch let error as VisionError {
        if case .invalidImage = error {
            return
        }
        visionExpect(false, "empty targeted unexpected \(error)")
    } catch {
        visionExpect(false, "empty targeted wrong error type \(error)")
    }
}
