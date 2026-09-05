#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testValueCatalog() {
    func roundtrip<T: CaseIterable & RawRepresentable & Equatable & Hashable>(_ values: T.Type, _ message: String)
    where T.RawValue: Equatable {
        visionExpectEqual(Set(T.allCases).count, Array(T.allCases).count, message + " unique")
        for value in T.allCases {
            visionExpect(T(rawValue: value.rawValue) == value, message + " roundtrip")
        }
    }

    roundtrip(VNBarcodeCompositeType.self, "composite")
    visionExpect(VNBarcodeCompositeType.none.rawValue == 0, "composite none")
    visionExpect(VNBarcodeCompositeType.linked.rawValue == 1, "composite linked")
    visionExpect(VNBarcodeCompositeType.gs1TypeA.rawValue == 2, "composite a")
    visionExpect(VNBarcodeCompositeType.gs1TypeB.rawValue == 3, "composite b")
    visionExpect(VNBarcodeCompositeType.gs1TypeC.rawValue == 4, "composite c")

    roundtrip(VNChirality.self, "chirality")
    visionExpect(VNChirality.unknown.rawValue == 0, "chirality unknown")
    visionExpect(VNChirality.left.rawValue == -1, "chirality left")
    visionExpect(VNChirality.right.rawValue == 1, "chirality right")

    roundtrip(VNElementType.self, "element")
    visionExpectEqual(VNElementTypeSize(.unknown), 0, "element unknown")
    visionExpectEqual(VNElementTypeSize(.float), MemoryLayout<Float>.size, "element float")
    visionExpectEqual(VNElementTypeSize(.double), MemoryLayout<Double>.size, "element double")

    roundtrip(VNImageCropAndScaleOption.self, "crop")
    visionExpect(VNImageCropAndScaleOption.centerCrop.rawValue == 0, "crop center")
    visionExpect(VNImageCropAndScaleOption.scaleFit.rawValue == 1, "crop fit")
    visionExpect(VNImageCropAndScaleOption.scaleFill.rawValue == 2, "crop fill")
    visionExpect(VNImageCropAndScaleOption.scaleFitRotate90CCW.rawValue == 257, "crop rotate fit")
    visionExpect(VNImageCropAndScaleOption.scaleFillRotate90CCW.rawValue == 258, "crop rotate fill")

    roundtrip(VNPointsClassification.self, "points")
    visionExpect(VNPointsClassification.disconnected.rawValue == 0, "points disconnected")
    visionExpect(VNPointsClassification.openPath.rawValue == 1, "points open")
    visionExpect(VNPointsClassification.closedPath.rawValue == 2, "points closed")

    roundtrip(VNRequestFaceLandmarksConstellation.self, "constellation")
    visionExpect(VNRequestFaceLandmarksConstellation.constellationNotDefined.rawValue == 0, "lm 0")
    visionExpect(VNRequestFaceLandmarksConstellation.constellation65Points.rawValue == 1, "lm 65")
    visionExpect(VNRequestFaceLandmarksConstellation.constellation76Points.rawValue == 2, "lm 76")

    roundtrip(VNRequestTextRecognitionLevel.self, "text level")
    visionExpect(VNRequestTextRecognitionLevel.accurate.rawValue == 0, "text accurate")
    visionExpect(VNRequestTextRecognitionLevel.fast.rawValue == 1, "text fast")

    roundtrip(VNRequestTrackingLevel.self, "tracking")
    visionExpect(VNRequestTrackingLevel.accurate.rawValue == 0, "track accurate")
    visionExpect(VNRequestTrackingLevel.fast.rawValue == 1, "track fast")

    roundtrip(VNGenerateOpticalFlowRequest.ComputationAccuracy.self, "flow")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.low.rawValue == 0, "flow low")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.medium.rawValue == 1, "flow med")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.high.rawValue == 2, "flow high")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.veryHigh.rawValue == 3, "flow very high")

    roundtrip(VNTrackOpticalFlowRequest.ComputationAccuracy.self, "track flow")
    visionExpect(VNTrackOpticalFlowRequest.ComputationAccuracy.medium.rawValue == 1, "track flow med")

    roundtrip(VNGeneratePersonSegmentationRequest.QualityLevel.self, "seg")
    visionExpect(VNGeneratePersonSegmentationRequest.QualityLevel.accurate.rawValue == 0, "seg acc")
    visionExpect(VNGeneratePersonSegmentationRequest.QualityLevel.balanced.rawValue == 1, "seg bal")
    visionExpect(VNGeneratePersonSegmentationRequest.QualityLevel.fast.rawValue == 2, "seg fast")

    roundtrip(VNHumanBodyPose3DObservation.HeightEstimation.self, "height")
    visionExpect(VNHumanBodyPose3DObservation.HeightEstimation.reference.rawValue == 0, "height ref")
    visionExpect(VNHumanBodyPose3DObservation.HeightEstimation.measured.rawValue == 1, "height measured")

    roundtrip(VNErrorCode.self, "error")
    visionExpect(VNErrorCode.turiCoreErrorCode.rawValue == -1, "error turi")
    visionExpect(VNErrorCode.OK.rawValue == 0, "error ok")
    visionExpect(VNErrorCode.requestCancelled.rawValue == 1, "error cancel")
    visionExpect(VNErrorCode.invalidImage.rawValue == 13, "error invalid image")
    visionExpect(VNErrorCode.invalidModel.rawValue == 15, "error invalid model")
    visionExpect(VNErrorCode.unsupportedRequest.rawValue == 19, "error unsupported")
    visionExpect(VNErrorCode.unsupportedComputeDevice.rawValue == 22, "error compute device")
    visionExpect(VNErrorCode.notImplemented != .requestCancelled, "error distinct")
    visionExpectEqual(VNErrorDomain, "VNErrorDomain", "error domain")
    var hasher = Hasher()
    VNErrorCode.OK.hash(into: &hasher)
    _ = hasher.finalize()

    visionExpectEqual(VNRequestRevisionUnspecified, 0, "unspecified revision")
    visionExpectEqual(VNDetectBarcodesRequestRevision1, 1, "barcode r1")
    visionExpectEqual(VNDetectBarcodesRequestRevision2, 2, "barcode r2")
    visionExpectEqual(VNDetectBarcodesRequestRevision3, 3, "barcode r3")
    visionExpectEqual(VNDetectBarcodesRequestRevision4, 4, "barcode r4")
    visionExpectEqual(VNDetectFaceRectanglesRequestRevision1, 1, "face r1")
    visionExpectEqual(VNDetectFaceRectanglesRequestRevision2, 2, "face r2")
    visionExpectEqual(VNDetectFaceRectanglesRequestRevision3, 3, "face r3")
    visionExpectEqual(VNDetectRectanglesRequestRevision1, 1, "rect r1")
    visionExpectEqual(VNRecognizeTextRequestRevision1, 1, "text r1")
    visionExpectEqual(VNRecognizeTextRequestRevision2, 2, "text r2")
    visionExpectEqual(VNRecognizeTextRequestRevision3, 3, "text r3")
    visionExpectEqual(VNDetectDocumentSegmentationRequestRevision1, 1, "doc r1")
    visionExpectEqual(VNGenerateAttentionBasedSaliencyImageRequestRevision1, 1, "sal r1")
    visionExpectEqual(VNGenerateAttentionBasedSaliencyImageRequestRevision2, 2, "sal r2")
    visionExpectEqual(VNClassifyImageRequestRevision1, 1, "cls r1")
    visionExpectEqual(VNClassifyImageRequestRevision2, 2, "cls r2")
    visionExpectEqual(VNCoreMLRequestRevision1, 1, "coreml r1")
    visionExpectEqual(VNDetectContourRequestRevision1, 1, "contour graph spelling")
    visionExpectEqual(VNDetectContoursRequestRevision1, VNDetectContourRequestRevision1, "contour alias")
    visionExpectEqual(VNDetectHumanBodyPoseRequestRevision1, 1, "body r1")
    visionExpectEqual(VNGenerateImageFeaturePrintRequestRevision1, 1, "print r1")
    visionExpectEqual(VNGenerateImageFeaturePrintRequestRevision2, 2, "print r2")
    visionExpectEqual(VNHomographicImageRegistrationRequestRevision1, 1, "homo r1")
    visionExpectEqual(VNTrackObjectRequestRevision1, 1, "track r1")
    visionExpectEqual(VNTrackObjectRequestRevision2, 2, "track r2")
    visionExpectEqual(VNTranslationalImageRegistrationRequestRevision1, 1, "trans r1")

    visionExpect(CoordinateOrigin.lowerLeft != .upperLeft, "overlay origin")
    visionExpect(ComputeStage.main != .postProcessing, "overlay stage")
    visionExpect(ElementType.float != .double, "overlay element")
    visionExpect(Chirality.left != .right, "overlay chirality")
    visionExpect(ImageCropAndScaleAction.allCases.contains(.scaleToFill), "overlay crop")
    visionExpect(BarcodeSymbology.allCases.contains(.qr), "overlay barcode cases")
    visionExpect(BarcodeSymbology.allCases.contains(.code128), "overlay code128")
    visionExpect(BarcodeSymbology.allCases.contains(.ean13), "overlay ean13")
    visionExpect(DetectBarcodesRequest.Revision.revision4 == .revision4, "overlay barcode revision")
    visionExpect(DetectRectanglesRequest.Revision.revision1 == .revision1, "overlay rect revision")
}
