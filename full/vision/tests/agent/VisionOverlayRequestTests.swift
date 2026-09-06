#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testRequestDescriptorCatalog() {
    let cases: [RequestDescriptor] = [
        .detectBarcodesRequest(.revision4),
        .detectRectanglesRequest(.revision1),
        .detectContoursRequest(.revision1),
        .generateImageFeaturePrintRequest(.revision2),
        .classifyImageRequest(.revision2),
        .recognizeTextRequest(.revision3),
        .detectFaceRectanglesRequest(.revision3),
        .detectHumanBodyPoseRequest(.revision1),
        .detectHorizonRequest(.revision1),
        .detectLensSmudgeRequest(.revision1),
        .recognizeAnimalsRequest(.revision1),
        .detectTrajectoriesRequest(.revision1),
        .recognizeDocumentsRequest(.revision1),
        .detectFaceLandmarksRequest(.revision1),
        .detectHumanHandPoseRequest(.revision1),
        .detectAnimalBodyPoseRequest(.revision1),
        .detectTextRectanglesRequest(.revision1),
        .detectHumanRectanglesRequest(.revision1),
        .detectFaceCaptureQualityRequest(.revision1),
        .detectDocumentSegmentationRequest(.revision1),
        .generatePersonInstanceMaskRequest(.revision1),
        .generatePersonSegmentationRequest(.revision1),
        .calculateImageAestheticsScoresRequest(.revision1),
        .generateForegroundInstanceMaskRequest(.revision1),
        .generateAttentionBasedSaliencyImageRequest(.revision1),
        .generateObjectnessBasedSaliencyImageRequest(.revision1),
        .detectHumanBodyPose3DRequest(.revision1),
        .coreMLRequest(.revision1),
        .trackObjectRequest(.revision2),
        .trackRectangleRequest(.revision1),
        .trackOpticalFlowRequest(.revision1),
        .trackHomographicImageRegistrationRequest(.revision1),
        .trackTranslationalImageRegistrationRequest(.revision1)
    ]
    visionExpectEqual(Set(cases).count, cases.count, "descriptor unique")
    for item in cases {
        visionExpect(!item.description.isEmpty, "descriptor description")
        visionExpect(item == item, "descriptor equal")
        visionExpect(item != .detectBarcodesRequest(.revision4) || item == .detectBarcodesRequest(.revision4), "descriptor !=")
        _ = item.hashValue
        var hasher = Hasher()
        item.hash(into: &hasher)
        _ = hasher.finalize()
        let encoded = try! JSONEncoder().encode(item)
        let decoded = try! JSONDecoder().decode(RequestDescriptor.self, from: encoded)
        visionExpectEqual(decoded, item, "descriptor roundtrip \(item)")
    }
    visionExpect(RequestDescriptor.detectBarcodesRequest(.revision4) != .recognizeDocumentsRequest(.revision1), "distinct cases")
}

func testVisionResultCatalog() {
    let barcodes = DetectBarcodesRequest()
    let contours = DetectContoursRequest()
    let rectangles = DetectRectanglesRequest()
    let feature = GenerateImageFeaturePrintRequest()
    let classify = ClassifyImageRequest()
    let text = RecognizeTextRequest()
    let face = DetectFaceRectanglesRequest()
    let pose = DetectHumanBodyPoseRequest()
    let horizon = DetectHorizonRequest()
    let smudge = DetectLensSmudgeRequest()
    let animals = RecognizeAnimalsRequest()
    let trajectories = DetectTrajectoriesRequest()
    let documents = RecognizeDocumentsRequest()
    let landmarks = DetectFaceLandmarksRequest()
    let hands = DetectHumanHandPoseRequest()
    let animalPose = DetectAnimalBodyPoseRequest()
    let textRects = DetectTextRectanglesRequest()
    let humans = DetectHumanRectanglesRequest()
    let capture = DetectFaceCaptureQualityRequest()
    let segmentation = DetectDocumentSegmentationRequest()
    let personMask = GeneratePersonInstanceMaskRequest()
    let personSeg = GeneratePersonSegmentationRequest()
    let aesthetics = CalculateImageAestheticsScoresRequest()
    let foreground = GenerateForegroundInstanceMaskRequest()
    let attention = GenerateAttentionBasedSaliencyImageRequest()
    let objectness = GenerateObjectnessBasedSaliencyImageRequest()
    let pose3d = DetectHumanBodyPose3DRequest()
    let coreml = CoreMLRequest()
    let seed = DetectedObjectObservation(boundingBox: .fullImage)
    let track = TrackObjectRequest(detectedObject: seed)
    let trackRect = TrackRectangleRequest()
    let flow = TrackOpticalFlowRequest()
    let homo = TrackHomographicImageRegistrationRequest()
    let trans = TrackTranslationalImageRegistrationRequest()

    let results: [VisionResult] = [
        .detectBarcodes(barcodes, []),
        .detectContours(contours, ContoursObservation(VNContoursObservation(topLevelContours: []))),
        .detectRectangles(rectangles, []),
        .generateImageFeaturePrint(feature, FeaturePrintObservation(VNFeaturePrintObservation(elementType: .float, data: Data(repeating: 0, count: 4)))),
        .classifyImage(classify, []),
        .recognizeText(text, []),
        .detectFaceRectangles(face, []),
        .detectHumanBodyPose(pose, []),
        .detectHorizon(horizon, nil),
        .detectLensSmudge(smudge, SmudgeObservation(confidence: 0, uuid: UUID(), timeRange: nil, originatingRequestDescriptor: nil)),
        .recognizeAnimals(animals, []),
        .detectTrajectories(trajectories, []),
        .recognizeDocuments(documents, []),
        .detectFaceLandmarks(landmarks, []),
        .detectHumanHandPose(hands, []),
        .detectAnimalBodyPose(animalPose, []),
        .detectTextRectangles(textRects, []),
        .detectHumanRectangles(humans, []),
        .detectFaceCaptureQuality(capture, []),
        .detectDocumentSegmentation(segmentation, nil),
        .generatePersonInstanceMask(personMask, nil),
        .generatePersonSegmentation(personSeg, PixelBufferObservation()),
        .calculateImageAestheticsScores(aesthetics, ImageAestheticsScoresObservation()),
        .generateForegroundInstanceMask(foreground, nil),
        .generateAttentionBasedSaliencyImage(attention, SaliencyImageObservation()),
        .generateObjectnessBasedSaliencyImage(objectness, SaliencyImageObservation()),
        .detectHumanBodyPose3D(pose3d, []),
        .coreML(coreml, []),
        .trackObject(track, nil),
        .trackRectangle(trackRect, nil),
        .trackOpticalFlow(flow, nil),
        .trackHomographicImageRegistration(homo, ImageHomographicAlignmentObservation()),
        .trackTranslationalImageRegistration(trans, ImageTranslationAlignmentObservation(VNImageTranslationAlignmentObservation(alignmentTransform: .identity))),
        .error(barcodes, VisionError.invalidModel("catalog"))
    ]
    for item in results {
        visionExpect(!item.description.isEmpty, "result description")
    }
    visionExpectEqual(results.count, 34, "vision result cases")
}

func testBarcodeObservationOverlayValues() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO")
    let handler = VNImageRequestHandler(cgImage: qrImage)
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]
    try! handler.perform([request])
    let vn = (request.results ?? []).compactMap { $0 as? VNBarcodeObservation }.first!
    let overlay = BarcodeObservation(vn)
    visionExpectEqual(overlay.payloadString, "HELLO", "payload string")
    visionExpect(overlay.payloadData != nil || overlay.payloadData == nil, "payload data readable")
    visionExpectEqual(overlay.symbology, .qr, "symbology")
    visionExpectEqual(overlay.isGS1DataCarrier, false, "gs1")
    visionExpectEqual(overlay.isColorInverted, false, "inverted")
    visionExpect(overlay.supplementalCompositeType == nil, "no supplemental composite")
    visionExpect(overlay.supplementalPayloadString == nil, "no supplemental string")
    visionExpect(overlay.supplementalPayloadData == nil, "no supplemental data")
    visionExpect(overlay.confidence > 0, "confidence")
    visionExpectEqual(overlay.uuid, vn.uuid, "uuid")
    visionExpectEqual(overlay.timeRange, vn.timeRange, "timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(overlay.boundingBox.width > 0 && overlay.boundingBox.height > 0, "bounding box")
    visionExpect(overlay.boundingRegion.pointCount >= 4, "bounding region")
    visionExpect(overlay.topLeft.x >= 0 && overlay.topRight.x >= overlay.topLeft.x, "corners")
    visionExpectEqual(overlay.description, "HELLO", "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(!(overlay != overlay), "not unequal to self")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    _ = hasher.finalize()
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(BarcodeObservation.self, from: encoded)
    visionExpectEqual(decoded.payloadString, "HELLO", "codable payload")
    visionExpectEqual(BarcodeObservation.CompositeType.linked.rawValue, "linked", "linked")
    visionExpectEqual(BarcodeObservation.CompositeType.gs1TypeA.rawValue, "gs1TypeA", "a")
    visionExpectEqual(BarcodeObservation.CompositeType.gs1TypeB.rawValue, "gs1TypeB", "b")
    visionExpectEqual(BarcodeObservation.CompositeType.gs1TypeC.rawValue, "gs1TypeC", "c")
    visionExpect(BarcodeObservation.CompositeType.linked != .gs1TypeA, "composite !=")
    visionExpect(BarcodeObservation.CompositeType.linked == .linked, "composite ==")
    let compositeEncoded = try! JSONEncoder().encode(BarcodeObservation.CompositeType.gs1TypeB)
    let compositeDecoded = try! JSONDecoder().decode(BarcodeObservation.CompositeType.self, from: compositeEncoded)
    visionExpectEqual(compositeDecoded, .gs1TypeB, "composite roundtrip")
    _ = BarcodeObservation.CompositeType.gs1TypeC.hashValue
    var compositeHasher = Hasher()
    BarcodeObservation.CompositeType.gs1TypeA.hash(into: &compositeHasher)
    _ = compositeHasher.finalize()
}

func testRecognizeDocumentsRequestConfig() {
    var request = RecognizeDocumentsRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(RecognizeDocumentsRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.regionOfInterest, .fullImage, "roi")
    visionExpectEqual(request.descriptor, .recognizeDocumentsRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("recognizeDocuments"), "description")
    visionExpect(request.supportedBarcodeSymbologies.contains(.qr), "supported barcodes")
    visionExpect(request.supportedRecognitionLanguages.isEmpty, "no Apple languages")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(MLComputeDevice.cpu) == true, "cpu stage")
    visionExpect(request.computeDevice(for: .main) == nil, "unset device")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "set device")
    request.textRecognitionOptions.customWords = ["OpenUIKit"]
    request.textRecognitionOptions.minimumTextHeightFraction = 0.02
    request.textRecognitionOptions.maximumCandidateCount = 3
    request.textRecognitionOptions.useLanguageCorrection = false
    request.textRecognitionOptions.automaticallyDetectLanguage = false
    visionExpectEqual(request.textRecognitionOptions.customWords, ["OpenUIKit"], "custom words")
    visionExpectEqual(request.textRecognitionOptions.minimumTextHeightFraction, 0.02, "min height")
    visionExpectEqual(request.textRecognitionOptions.maximumCandidateCount, 3, "candidates")
    visionExpectEqual(request.textRecognitionOptions.useLanguageCorrection, false, "correction")
    visionExpectEqual(request.textRecognitionOptions.automaticallyDetectLanguage, false, "autodetect")
    request.barcodeDetectionOptions.enabled = true
    request.barcodeDetectionOptions.symbologies = [.qr]
    request.barcodeDetectionOptions.coalesceCompositeSymbologies = true
    visionExpectEqual(request.barcodeDetectionOptions.enabled, true, "barcode enabled")
    visionExpectEqual(request.barcodeDetectionOptions.symbologies, [.qr], "barcode symbologies")
    visionExpectEqual(request.barcodeDetectionOptions.coalesceCompositeSymbologies, true, "coalesce")
    let encodedOptions = try! JSONEncoder().encode(request.textRecognitionOptions)
    let decodedOptions = try! JSONDecoder().decode(RecognizeDocumentsRequest.TextRecognitionOptions.self, from: encodedOptions)
    visionExpectEqual(decodedOptions.customWords, ["OpenUIKit"], "text options roundtrip")
    let encodedBarcode = try! JSONEncoder().encode(request.barcodeDetectionOptions)
    let decodedBarcode = try! JSONDecoder().decode(RecognizeDocumentsRequest.BarcodeDetectionOptions.self, from: encodedBarcode)
    visionExpectEqual(decodedBarcode.enabled, true, "barcode options roundtrip")
    visionExpect(request == request, "equal")
    visionExpect(request != RecognizeDocumentsRequest(), "config inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpect(RecognizeDocumentsRequest.Revision.revision1 == .revision1, "rev ==")
    visionExpect(!(RecognizeDocumentsRequest.Revision.revision1 < .revision1), "rev <")
    _ = RecognizeDocumentsRequest.Revision.revision1.hashValue

    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    do {
        _ = try request.performOnHandler(handler)
        visionExpect(false, "documents should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "documents invalidModel")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong error type \(error)")
    }
}

func testTrackOpticalFlowRequestConfig() {
    let request = TrackOpticalFlowRequest(.revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackOpticalFlowRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 1, "latency")
    visionExpectEqual(request.computationAccuracy, .medium, "accuracy default")
    request.computationAccuracy = .high
    visionExpectEqual(request.computationAccuracy, .high, "accuracy set")
    visionExpectEqual(request.outputPixelFormatType, kCVPixelFormatType_32BGRA, "format")
    visionExpectEqual(request.supportedOutputPixelFormatTypes, [kCVPixelFormatType_32BGRA], "supported formats")
    visionExpectEqual(request.descriptor, .trackOpticalFlowRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackOpticalFlow"), "description")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackOpticalFlowRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpectEqual(Set(TrackOpticalFlowRequest.ComputationAccuracy.allCases).count, 4, "accuracy cases")
    visionExpect(TrackOpticalFlowRequest.ComputationAccuracy.low != .veryHigh, "accuracy !=")
    let encoded = try! JSONEncoder().encode(TrackOpticalFlowRequest.ComputationAccuracy.medium)
    let decoded = try! JSONDecoder().decode(TrackOpticalFlowRequest.ComputationAccuracy.self, from: encoded)
    visionExpectEqual(decoded, .medium, "accuracy roundtrip")
    visionExpect(TrackOpticalFlowRequest.Revision.revision1 == .revision1, "rev ==")
    visionExpect(!(TrackOpticalFlowRequest.Revision.revision1 < .revision1), "rev <")
    let range = TrackOpticalFlowRequest.Revision.revision1...TrackOpticalFlowRequest.Revision.revision1
    visionExpect(range.contains(.revision1), "closed range")
    let half = TrackOpticalFlowRequest.Revision.revision1..<TrackOpticalFlowRequest.Revision.revision1
    visionExpect(half.isEmpty, "empty half range")
    let upTo: PartialRangeUpTo<TrackOpticalFlowRequest.Revision> = ..<TrackOpticalFlowRequest.Revision.revision1
    visionExpect(!upTo.contains(.revision1), "up to")
    let from: PartialRangeFrom<TrackOpticalFlowRequest.Revision> = TrackOpticalFlowRequest.Revision.revision1...
    visionExpect(from.contains(.revision1), "from")
    let through: PartialRangeThrough<TrackOpticalFlowRequest.Revision> = ...TrackOpticalFlowRequest.Revision.revision1
    visionExpect(through.contains(.revision1), "through")
    visionExpect(TrackOpticalFlowRequest.Revision.revision1 <= .revision1, "<=")
    visionExpect(TrackOpticalFlowRequest.Revision.revision1 >= .revision1, ">=")
    visionExpect(!(TrackOpticalFlowRequest.Revision.revision1 > .revision1), ">")

    let image = visionRectangleImage()
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(cgImage: image))
        visionExpect(false, "optical flow should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "optical flow invalidModel")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong error type \(error)")
    }
}

func testOverlayRequestProtocolSurface() {
    var barcodes = DetectBarcodesRequest()
    visionExpectEqual(barcodes.descriptor, .detectBarcodesRequest(.revision4), "barcode descriptor")
    visionExpectEqual(barcodes.regionOfInterest, .fullImage, "roi")
    visionExpectEqual(DetectBarcodesRequest.supportedRevisions, [.revision4], "supported")
    visionExpect(barcodes.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    visionExpect(barcodes.computeDevice(for: .main) == nil, "unset")
    barcodes.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(barcodes.computeDevice(for: .main)?.identifier, "cpu", "set")
    visionExpect(barcodes == barcodes, "equal")
    _ = barcodes.hashValue
    var hasher = Hasher()
    barcodes.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpect(!barcodes.description.isEmpty, "description")
    barcodes.coalescesCompositeSymbologies = true
    visionExpectEqual(barcodes.coalescesCompositeSymbologies, true, "coalesce")

    var text = RecognizeTextRequest()
    visionExpectEqual(text.descriptor, .recognizeTextRequest(.revision3), "text descriptor")
    visionExpectEqual(text.regionOfInterest, .fullImage, "text roi")
    visionExpect(text.supportedComputeStageDevices[.postProcessing]?.contains(.cpu) == true, "text cpu")
    text.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(text.computeDevice(for: .postProcessing)?.identifier, "cpu", "text device")

    var face = DetectFaceRectanglesRequest()
    visionExpectEqual(face.descriptor, .detectFaceRectanglesRequest(.revision3), "face descriptor")
    face.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
    visionExpectEqual(face.regionOfInterest.width, 0.5, "face roi")
    visionExpect(face.supportedComputeStageDevices[.main]?.isEmpty == false, "face devices")

    let proto: any VisionRequest = barcodes
    visionExpect(!proto.description.isEmpty, "existential description")
    visionExpect(proto.supportedComputeStageDevices[.main] != nil, "existential devices")
}

func testOverlayRevisionComparableOperators() {
    func exercise<T: Comparable & Hashable>(_ a: T, _ b: T, _ message: String) {
        visionExpect(a == a, message + " ==")
        visionExpect(!(a != a), message + " !=")
        visionExpect(a <= b, message + " <=")
        visionExpect(a >= a, message + " >=")
        visionExpect(!(a > b) || a != b, message + " >")
        _ = a...b
        _ = a..<b
        _ = a...
        _ = ...a
        _ = ..<b
    }
    exercise(DetectBarcodesRequest.Revision.revision4, .revision4, "barcode")
    exercise(DetectRectanglesRequest.Revision.revision1, .revision1, "rect")
    exercise(DetectContoursRequest.Revision.revision1, .revision1, "contour")
    exercise(GenerateImageFeaturePrintRequest.Revision.revision2, .revision2, "feature")
    exercise(ClassifyImageRequest.Revision.revision2, .revision2, "classify")
    exercise(RecognizeTextRequest.Revision.revision3, .revision3, "text")
    exercise(DetectFaceRectanglesRequest.Revision.revision3, .revision3, "face")
    exercise(DetectHumanBodyPoseRequest.Revision.revision1, .revision1, "body")
    exercise(DetectHorizonRequest.Revision.revision1, .revision1, "horizon")
    exercise(DetectLensSmudgeRequest.Revision.revision1, .revision1, "smudge")
    exercise(RecognizeAnimalsRequest.Revision.revision1, .revision1, "animals")
    exercise(DetectTrajectoriesRequest.Revision.revision1, .revision1, "traj")
    exercise(RecognizeDocumentsRequest.Revision.revision1, .revision1, "docs")
    exercise(DetectFaceLandmarksRequest.Revision.revision1, .revision1, "landmarks")
    exercise(DetectHumanHandPoseRequest.Revision.revision1, .revision1, "hand")
    exercise(DetectAnimalBodyPoseRequest.Revision.revision1, .revision1, "animal")
    exercise(DetectTextRectanglesRequest.Revision.revision1, .revision1, "textrects")
    exercise(DetectHumanRectanglesRequest.Revision.revision1, .revision1, "humans")
    exercise(DetectFaceCaptureQualityRequest.Revision.revision1, .revision1, "capture")
    exercise(DetectDocumentSegmentationRequest.Revision.revision1, .revision1, "docseg")
    exercise(GeneratePersonInstanceMaskRequest.Revision.revision1, .revision1, "personmask")
    exercise(GeneratePersonSegmentationRequest.Revision.revision1, .revision1, "personseg")
    exercise(CalculateImageAestheticsScoresRequest.Revision.revision1, .revision1, "aesthetics")
    exercise(GenerateForegroundInstanceMaskRequest.Revision.revision1, .revision1, "foreground")
    exercise(GenerateAttentionBasedSaliencyImageRequest.Revision.revision1, .revision1, "attention")
    exercise(GenerateObjectnessBasedSaliencyImageRequest.Revision.revision1, .revision1, "objectness")
    exercise(DetectHumanBodyPose3DRequest.Revision.revision1, .revision1, "pose3d")
    exercise(CoreMLRequest.Revision.revision1, .revision1, "coreml")
    exercise(TrackObjectRequest.Revision.revision2, .revision2, "trackobj")
    exercise(TrackRectangleRequest.Revision.revision1, .revision1, "trackrect")
    exercise(TrackOpticalFlowRequest.Revision.revision1, .revision1, "flow")
    exercise(TrackHomographicImageRegistrationRequest.Revision.revision1, .revision1, "homo")
    exercise(TrackTranslationalImageRegistrationRequest.Revision.revision1, .revision1, "trans")
}

func testOverlayROIAndInvalidImage() {
    var request = RecognizeDocumentsRequest()
    request.regionOfInterest = NormalizedRect(x: 0.2, y: 0.2, width: -0.1, height: 0.2)
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
        visionExpect(false, "negative size should throw")
    } catch let error as VisionError {
        if case .invalidArgument = error {
            visionExpect(true, "overlay negative size")
        } else {
            visionExpect(false, "expected invalidArgument, got \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }

    request.regionOfInterest = NormalizedRect(x: 0.2, y: 0.2, width: 0.9, height: 0.9)
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
        visionExpect(false, "overflow should throw")
    } catch let error as VisionError {
        if case .outOfBoundsError = error {
            visionExpect(true, "overlay overflow")
        } else {
            visionExpect(false, "expected outOfBounds, got \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }

    request.regionOfInterest = .fullImage
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(data: Data([0, 1, 2])))
        visionExpect(false, "garbage should throw")
    } catch let error as VisionError {
        if case .invalidImage = error {
            visionExpect(true, "overlay invalid image")
        } else {
            visionExpect(false, "expected invalidImage, got \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }
}

func testVNTrackOpticalFlowRequestConfig() {
    let request = VNTrackOpticalFlowRequest()
    visionExpectEqual(request.computationAccuracy, .medium, "accuracy")
    request.computationAccuracy = .low
    visionExpectEqual(request.computationAccuracy, .low, "accuracy set")
    visionExpectEqual(request.keepNetworkOutput, false, "keep default")
    request.keepNetworkOutput = true
    visionExpectEqual(request.keepNetworkOutput, true, "keep set")
    visionExpectEqual(request.outputPixelFormat, kCVPixelFormatType_32BGRA, "pixel format")
    request.outputPixelFormat = kCVPixelFormatType_32BGRA
    visionExpect(request.results == nil, "results nil")
    visionExpectEqual(VNTrackOpticalFlowRequest.currentRevision, VNTrackOpticalFlowRequestRevision1, "current")
    visionExpectEqual(VNTrackOpticalFlowRequest.defaultRevision, VNTrackOpticalFlowRequestRevision1, "default")
    visionExpect(VNTrackOpticalFlowRequest.supportedRevisions.contains(VNTrackOpticalFlowRequestRevision1), "supported")
    let withHandler = VNTrackOpticalFlowRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    do {
        try handler.perform([request])
        visionExpect(false, "vn optical flow should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(request.results == nil, "results stay nil")
    }
}

func testImageRequestHandlerOverlayPerformNow() {
    let image = visionRectangleImage()
    let data = VisionHost.encodeNetpbm(image)
    _ = ImageRequestHandler(data)
    _ = ImageRequestHandler(image)
    let ci = CIImage(cgImage: image)
    _ = ImageRequestHandler(ci)
    let buffer = CVPixelBuffer(width: image.width, height: image.height)
    _ = ImageRequestHandler(buffer)
    let sample = CMSampleBuffer(pixelBuffer: buffer)
    _ = ImageRequestHandler(sample)
    let handler = ImageRequestHandler(image)
    var barcodes = DetectBarcodesRequest()
    barcodes.symbologies = [.qr]
    let qr = try! VisionHost.makeQRImage(payload: "HELLO")
    let qrHandler = ImageRequestHandler(qr)
    let hits: [BarcodeObservation] = try! qrHandler.performNow(barcodes)
    visionExpect(hits.contains(where: { $0.payloadString == "HELLO" }), "handler performNow QR")
    do {
        _ = try handler.performNow(RecognizeDocumentsRequest())
        visionExpect(false, "handler documents fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "handler documents")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }
}

func testOverlayEquatableInequality() {
    visionExpect(DetectBarcodesRequest() == DetectBarcodesRequest(), "barcodes ==")
    visionExpect(!(DetectBarcodesRequest() != DetectBarcodesRequest()), "barcodes !=")
    visionExpect(RecognizeDocumentsRequest() != RecognizeDocumentsRequest(.revision1) || RecognizeDocumentsRequest() == RecognizeDocumentsRequest(), "docs")
    visionExpect(TrackOpticalFlowRequest() == TrackOpticalFlowRequest(), "flow ==")
    visionExpect(TrackRectangleRequest() == TrackRectangleRequest(), "rect ==")
    visionExpect(TrackHomographicImageRegistrationRequest() == TrackHomographicImageRegistrationRequest(), "homo ==")
    visionExpect(TrackTranslationalImageRegistrationRequest() == TrackTranslationalImageRegistrationRequest(), "trans ==")
    visionExpect(RecognizeTextRequest() == RecognizeTextRequest(), "text ==")
    visionExpect(ClassifyImageRequest() == ClassifyImageRequest(), "classify ==")
    visionExpect(CoreMLRequest() == CoreMLRequest(), "coreml ==")
    visionExpect(DetectHorizonRequest() == DetectHorizonRequest(), "horizon ==")
    let seed = DetectedObjectObservation(boundingBox: .fullImage)
    visionExpect(TrackObjectRequest(detectedObject: seed) == TrackObjectRequest(detectedObject: seed), "track ==")
    _ = DetectBarcodesRequest().hashValue
    _ = RecognizeDocumentsRequest().hashValue
}

func testPixelBufferObservationValues() {
    let buffer = CVPixelBuffer(width: 2, height: 2)
    let observation = VNPixelBufferObservation(pixelBuffer: buffer, featureName: "flow")
    visionExpectEqual(observation.featureName, "flow", "feature name")
    visionExpectEqual(observation.pixelBuffer.width, 2, "pixel width")
    visionExpectEqual(observation.pixelBuffer.height, 2, "pixel height")
    let overlay = OpticalFlowObservation(observation)
    visionExpect(overlay != nil, "optical overlay")
    visionExpectEqual(overlay?.pixelBuffer?.width, 2, "overlay buffer")
    visionExpectEqual(overlay?.confidence, 1, "overlay confidence")
}
