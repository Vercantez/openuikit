#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testVisionErrorCatalog() {
    let cases: [VisionError] = [
        .outOfBoundsError("oob"),
        .ioError("io"),
        .internalError("internal"),
        .outOfMemory("oom"),
        .invalidImage("image"),
        .invalidModel("model"),
        .invalidFormat("format"),
        .dataUnavailable("data"),
        .invalidArgument("arg"),
        .operationFailed("op"),
        .invalidOperation("invop"),
        .requestCancelled("cancel"),
        .timeStampNotFound("ts"),
        .unsupportedRequest("req"),
        .unsupportedRevision("rev"),
        .unsupportedComputeStage("stage"),
        .unsupportedComputeDevice("dev"),
        .pixelBufferCreationFailed(12),
        .timeout("timeout")
    ]
    for item in cases {
        visionExpect(!item.description.isEmpty, "description \(item)")
        visionExpect(item.errorDescription != nil, "errorDescription \(item)")
        visionExpectEqual(item.failureReason, item.errorDescription, "failureReason \(item)")
        visionExpect(item.recoverySuggestion == nil, "recovery \(item)")
        visionExpect(item.helpAnchor == nil, "help \(item)")
        visionExpect(!item.localizedDescription.isEmpty, "localized \(item)")
    }
    if case .invalidModel(let message) = VisionError.invalidModel("model") {
        visionExpectEqual(message, "model", "invalidModel payload")
    } else {
        visionExpect(false, "invalidModel case")
    }
}

func testContoursObservationOverlayGeometry() {
    let child = ContoursObservation.Contour(
        points: [
            NormalizedPoint(x: 0.2, y: 0.2),
            NormalizedPoint(x: 0.4, y: 0.2),
            NormalizedPoint(x: 0.3, y: 0.4)
        ],
        indexPath: IndexPath(indexes: [0, 0])
    )
    let parent = ContoursObservation.Contour(
        points: [
            NormalizedPoint(x: 0, y: 0),
            NormalizedPoint(x: 1, y: 0),
            NormalizedPoint(x: 1, y: 1),
            NormalizedPoint(x: 0, y: 1)
        ],
        indexPath: IndexPath(index: 0),
        childContours: [child]
    )
    visionExpectEqual(parent.pointCount, 4, "parent points")
    visionExpectEqual(parent.childContours.count, 1, "child contours")
    visionExpectEqual(parent.aspectRatio, 1, "unit square aspect")
    visionExpectEqual(parent.boundingBox.width, 1, "bbox width")
    visionExpectEqual(parent.boundingBox.height, 1, "bbox height")
    visionExpectEqual(parent.boundingQuad.topLeft.y, 1, "quad top")
    visionExpectEqual(parent.normalizedPoints.count, 4, "simd points")
    visionExpect(!parent.description.isEmpty, "contour description")
    visionExpectEqual(parent.indexPath.first, 0, "index path")
    _ = parent.normalizedPath
    visionExpect(abs(parent.calculateArea(useOrientedArea: false) - 1) < 1e-6, "area")
    visionExpect(abs(parent.calculatePerimeter() - 4) < 1e-6, "perimeter")
    let simplified = try! parent.polygonApproximation(epsilon: 0.5)
    visionExpect(simplified.pointCount >= 2, "approx")
    visionExpect(parent == parent, "contour ==")
    visionExpect(parent != child, "contour !=")
    _ = parent.hashValue
    var hasher = Hasher()
    parent.hash(into: &hasher)
    _ = hasher.finalize()

    let vn = VNContoursObservation(topLevelContours: [
        VNContour(
            normalizedPoints: [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(1, 0),
                SIMD2<Float>(1, 1),
                SIMD2<Float>(0, 1)
            ],
            childContours: [
                VNContour(normalizedPoints: [SIMD2<Float>(0.2, 0.2), SIMD2<Float>(0.3, 0.2), SIMD2<Float>(0.25, 0.3)])
            ]
        )
    ])
    let observation = ContoursObservation(vn)
    visionExpectEqual(observation.topLevelContours.count, 1, "top level")
    visionExpectEqual(observation.contourCount, 2, "count")
    visionExpectEqual(observation.confidence, 1, "confidence")
    visionExpect(observation.uuid != UUID(), "uuid")
    visionExpect(observation.timeRange == .zero || observation.timeRange == nil, "timeRange")
    visionExpect(observation.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!observation.description.isEmpty, "obs description")
    visionExpectEqual(observation.contourAtIndex(0)?.pointCount, 4, "at index")
    visionExpect(observation.contourAtIndex(9) == nil, "missing index")
    visionExpectEqual(observation.countourAtIndexPath(IndexPath(index: 0))?.pointCount, 4, "at path")
    visionExpectEqual(observation.boundingRegion.pointCount, 4, "bounding region")
    _ = observation.normalizedPath
    visionExpect(observation == observation, "obs ==")
    visionExpect(observation != ContoursObservation(VNContoursObservation(topLevelContours: [])), "obs !=")
    _ = observation.hashValue
    var obsHasher = Hasher()
    observation.hash(into: &obsHasher)
    _ = obsHasher.finalize()
    let encoded = try! JSONEncoder().encode(observation)
    let decoded = try! JSONDecoder().decode(ContoursObservation.self, from: encoded)
    visionExpectEqual(decoded.topLevelContours.first?.pointCount, 4, "codable")
}

func testGeneratePersonSegmentationRequestConfig() {
    let request = GeneratePersonSegmentationRequest(.revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(GeneratePersonSegmentationRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency default")
    visionExpectEqual(request.qualityLevel, .balanced, "quality default")
    request.qualityLevel = .fast
    visionExpectEqual(request.qualityLevel, .fast, "quality set")
    visionExpectEqual(Set(GeneratePersonSegmentationRequest.QualityLevel.allCases).count, 3, "quality cases")
    visionExpect(GeneratePersonSegmentationRequest.QualityLevel.accurate != .fast, "quality !=")
    visionExpect(GeneratePersonSegmentationRequest.QualityLevel.accurate == .accurate, "quality ==")
    let encoded = try! JSONEncoder().encode(GeneratePersonSegmentationRequest.QualityLevel.balanced)
    let decoded = try! JSONDecoder().decode(GeneratePersonSegmentationRequest.QualityLevel.self, from: encoded)
    visionExpectEqual(decoded, .balanced, "quality roundtrip")
    _ = GeneratePersonSegmentationRequest.QualityLevel.accurate.hashValue
    var qHasher = Hasher()
    GeneratePersonSegmentationRequest.QualityLevel.accurate.hash(into: &qHasher)
    visionExpectEqual(request.outputPixelFormatType, kCVPixelFormatType_32BGRA, "pixel format")
    visionExpectEqual(request.supportedOutputPixelFormats, [kCVPixelFormatType_32BGRA], "supported formats")
    request.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    visionExpectEqual(request.regionOfInterest.width, 0.8, "roi")
    visionExpectEqual(request.descriptor, .generatePersonSegmentationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("generatePerson"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu stage")
    visionExpect(request == request, "equal")
    visionExpect(request != GeneratePersonSegmentationRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "person segmentation")

    let vn = VNGeneratePersonSegmentationRequest()
    visionExpectEqual(vn.qualityLevel, .balanced, "vn quality")
    vn.qualityLevel = .accurate
    visionExpectEqual(vn.qualityLevel, .accurate, "vn quality set")
    visionExpectEqual(vn.outputPixelFormat, kCVPixelFormatType_32BGRA, "vn format")
    let formats = try! vn.supportedOutputPixelFormats()
    visionExpectEqual(formats.first?.uint32Value, kCVPixelFormatType_32BGRA, "vn supported")
    visionExpect(vn.results == nil, "vn results")
    let withHandler = VNGeneratePersonSegmentationRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn person segmentation should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testTrackRectangleRequestConfig() {
    let seed = RectangleObservation(
        topLeft: NormalizedPoint(x: 0.1, y: 0.6),
        topRight: NormalizedPoint(x: 0.5, y: 0.6),
        bottomRight: NormalizedPoint(x: 0.5, y: 0.2),
        bottomLeft: NormalizedPoint(x: 0.1, y: 0.2)
    )
    let request = TrackRectangleRequest(detectedRectangle: seed, .revision1, frameAnalysisSpacing: CMTime(value: 2, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackRectangleRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 2, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    visionExpectEqual(request.trackingLevel, .accurate, "level default")
    request.trackingLevel = .fast
    visionExpectEqual(request.trackingLevel, .fast, "level set")
    visionExpectEqual(Set(TrackRectangleRequest.TrackingLevel.allCases).count, 2, "level cases")
    let encoded = try! JSONEncoder().encode(TrackRectangleRequest.TrackingLevel.fast)
    let decoded = try! JSONDecoder().decode(TrackRectangleRequest.TrackingLevel.self, from: encoded)
    visionExpectEqual(decoded, .fast, "level roundtrip")
    _ = TrackRectangleRequest.TrackingLevel.accurate.hashValue
    var levelHasher = Hasher()
    TrackRectangleRequest.TrackingLevel.accurate.hash(into: &levelHasher)
    visionExpectEqual(request.inputObservation.boundingBox.width, seed.boundingBox.width, "input")
    visionExpectEqual(request.descriptor, .trackRectangleRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackRectangle"), "description")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackRectangleRequest(), "default inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    let tracked = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(tracked != nil, "tracked rectangle")
    visionExpect((tracked?.boundingBox.width ?? 0) > 0, "tracked width")

    let vnSeed = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0.1, y: 0.6),
        topRight: CGPoint(x: 0.5, y: 0.6),
        bottomRight: CGPoint(x: 0.5, y: 0.2),
        bottomLeft: CGPoint(x: 0.1, y: 0.2)
    )
    let vn = VNTrackRectangleRequest(rectangleObservation: vnSeed)
    let vnHandler = VNImageRequestHandler(cgImage: visionRectangleImage())
    try! vnHandler.perform([vn])
    let vnHit = vn.results?.first as? VNRectangleObservation
    visionExpect(vnHit != nil, "vn track rectangle")
    let withCompletion = VNTrackRectangleRequest(rectangleObservation: vnSeed, completionHandler: { _, _ in })
    visionExpect(withCompletion.completionHandler != nil, "vn completion")
}

func testRecognizeAnimalsRequestConfig() {
    var request = RecognizeAnimalsRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(RecognizeAnimalsRequest.supportedRevisions, [.revision1, .revision2], "supported")
    visionExpectEqual(request.supportedAnimals, [.cat, .dog], "animals")
    visionExpectEqual(RecognizeAnimalsRequest.Animal.cat.rawValue, "cat", "cat raw")
    visionExpectEqual(RecognizeAnimalsRequest.Animal(rawValue: "dog"), .dog, "dog raw")
    visionExpect(RecognizeAnimalsRequest.Animal.cat != .dog, "animal !=")
    let encoded = try! JSONEncoder().encode(RecognizeAnimalsRequest.Animal.cat)
    let decoded = try! JSONDecoder().decode(RecognizeAnimalsRequest.Animal.self, from: encoded)
    visionExpectEqual(decoded, .cat, "animal roundtrip")
    _ = RecognizeAnimalsRequest.Animal.dog.hashValue
    var animalHasher = Hasher()
    RecognizeAnimalsRequest.Animal.dog.hash(into: &animalHasher)
    visionExpectEqual(request.descriptor, .recognizeAnimalsRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("recognizeAnimals"), "description")
    request.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != RecognizeAnimalsRequest(), "roi inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "recognize animals")

    visionExpectEqual(VNAnimalIdentifier.cat.rawValue, "VNAnimalIdentifierCat", "cat token")
    visionExpectEqual(VNAnimalIdentifier.dog.rawValue, "VNAnimalIdentifierDog", "dog token")
    visionExpect(VNAnimalIdentifier.cat != .dog, "identifier !=")
    visionExpectEqual(VNAnimalIdentifier(rawValue: "VNAnimalIdentifierCat"), .cat, "init raw")
    _ = VNAnimalIdentifier.cat.hashValue
    var idHasher = Hasher()
    VNAnimalIdentifier.cat.hash(into: &idHasher)

    let vn = VNRecognizeAnimalsRequest()
    do {
        _ = try VNRecognizeAnimalsRequest.knownAnimalIdentifiers(forRevision: 2)
        visionExpect(false, "known identifiers should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "known identifiers")
    }
    do {
        _ = try vn.supportedIdentifiers()
        visionExpect(false, "supported identifiers should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "supported identifiers")
    }
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn animals should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn animals")
        visionExpect(vn.results == nil, "results nil")
    }
}

func testDetectTrajectoriesRequestConfig() {
    let request = DetectTrajectoriesRequest(trajectoryLength: 7, .revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 15))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectTrajectoriesRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.trajectoryLength, 7, "length")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 7, "latency")
    request.targetFrameTime = CMTime(value: 3, timescale: 15)
    visionExpectEqual(request.targetFrameTime.value, 3, "target")
    request.objectMinimumNormalizedRadius = 0.02
    request.objectMaximumNormalizedRadius = 0.4
    visionExpectEqual(request.objectMinimumNormalizedRadius, 0.02, "min radius")
    visionExpectEqual(request.objectMaximumNormalizedRadius, 0.4, "max radius")
    visionExpectEqual(request.descriptor, .detectTrajectoriesRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectTrajectories"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.postProcessing]?.contains(.cpu) == true, "cpu")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectTrajectoriesRequest(), "default inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "trajectories")

    let vn = VNDetectTrajectoriesRequest(frameAnalysisSpacing: CMTime(value: 1, timescale: 30), trajectoryLength: 6)
    visionExpectEqual(vn.trajectoryLength, 6, "vn length")
    visionExpectEqual(vn.frameAnalysisSpacing.value, 1, "vn spacing")
    vn.objectMinimumNormalizedRadius = 0.01
    vn.objectMaximumNormalizedRadius = 0.5
    visionExpectEqual(vn.minimumObjectSize, 0.01, "min size alias")
    visionExpectEqual(vn.maximumObjectSize, 0.5, "max size alias")
    vn.targetFrameTime = CMTime(value: 2, timescale: 30)
    visionExpectEqual(vn.targetFrameTime.value, 2, "vn target")
    visionExpect(vn.results == nil, "vn results")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn trajectories should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn trajectories")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testCoreMLRequestConfig() {
    var request = CoreMLRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(CoreMLRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.modelContainer.inputImageFeatureName, "image", "feature name")
    request.cropAndScaleAction = .scaleToFit
    visionExpectEqual(request.cropAndScaleAction, .scaleToFit, "crop")
    visionExpect(request.supportedIdentifiers == nil, "no identifiers without a model")
    visionExpectEqual(request.descriptor, .coreMLRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("coreML"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    do {
        _ = try CoreMLModelContainer(model: MLModel())
        visionExpect(false, "container should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "container invalidModel")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }
    let unchecked = CoreMLModelContainer(unchecked: MLModel())
    visionExpect(unchecked == unchecked, "container ==")
    visionExpect(unchecked != CoreMLModelContainer(unchecked: MLModel(), inputImageFeatureName: "other"), "container !=")
    _ = unchecked.hashValue
    var containerHasher = Hasher()
    unchecked.hash(into: &containerHasher)
    let fromModel = CoreMLRequest(model: unchecked)
    visionExpectEqual(fromModel.modelContainer.inputImageFeatureName, "image", "init model")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "coreml overlay")
}

func testDetectHumanBodyPoseRequestConfig() {
    var request = DetectHumanBodyPoseRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(DetectHumanBodyPoseRequest.supportedRevisions, [.revision1, .revision2], "supported")
    request.detectsHands = true
    visionExpectEqual(request.detectsHands, true, "hands")
    visionExpect(request.supportedJointNames.contains(.nose), "joints")
    visionExpect(request.supportedJointsGroupNames.contains(.torso), "groups")
    visionExpectEqual(request.descriptor, .detectHumanBodyPoseRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("detectHumanBodyPose"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "body pose")
}

func testDetectHumanHandPoseRequestConfig() {
    var request = DetectHumanHandPoseRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectHumanHandPoseRequest.supportedRevisions, [.revision1], "supported")
    request.maximumHandCount = 1
    visionExpectEqual(request.maximumHandCount, 1, "max hands")
    visionExpect(request.supportedJointNames.contains(.wrist), "joints")
    visionExpect(try! request.supportedJointsGroupNames.contains(.thumb), "groups")
    visionExpectEqual(request.descriptor, .detectHumanHandPoseRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectHumanHandPose"), "description")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "hand pose")

    let vn = VNDetectHumanHandPoseRequest()
    visionExpectEqual(vn.maximumHandCount, 2, "vn max default")
    vn.maximumHandCount = 1
    visionExpectEqual(vn.maximumHandCount, 1, "vn max set")
    do {
        _ = try VNDetectHumanHandPoseRequest.supportedJointNames(forRevision: 1)
        visionExpect(false, "vn hand joints revision should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand joints revision")
    }
    do {
        _ = try VNDetectHumanHandPoseRequest.supportedJointsGroupNames(forRevision: 1)
        visionExpect(false, "vn hand groups revision should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand groups revision")
    }
    do {
        _ = try vn.supportedJointNames
        visionExpect(false, "vn hand joints should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand joints")
    }
    do {
        _ = try vn.supportedJointsGroupNames
        visionExpect(false, "vn hand groups should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand groups")
    }
}

func testDetectAnimalBodyPoseRequestConfig() {
    var request = DetectAnimalBodyPoseRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectAnimalBodyPoseRequest.supportedRevisions, [.revision1], "supported")
    visionExpect(!request.supportedJointNames.isEmpty, "joints")
    visionExpect(request.supportedJointsGroupNames.contains(.head), "groups")
    visionExpectEqual(request.descriptor, .detectAnimalBodyPoseRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectAnimalBodyPose"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "animal pose")

    let vn = VNDetectAnimalBodyPoseRequest()
    do {
        _ = try vn.supportedJointNames
        visionExpect(false, "vn animal joints should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn animal joints")
    }
    do {
        _ = try vn.supportedJointsGroupNames
        visionExpect(false, "vn animal groups should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn animal groups")
    }
}

func testDetectTextRectanglesRequestConfig() {
    var request = DetectTextRectanglesRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectTextRectanglesRequest.supportedRevisions, [.revision1], "supported")
    request.reportCharacterBoxes = true
    visionExpectEqual(request.reportCharacterBoxes, true, "character boxes")
    visionExpectEqual(request.descriptor, .detectTextRectanglesRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectTextRectangles"), "description")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "text rectangles")

    let vn = VNDetectTextRectanglesRequest()
    visionExpectEqual(vn.reportCharacterBoxes, false, "vn default")
    vn.reportCharacterBoxes = true
    visionExpectEqual(vn.reportCharacterBoxes, true, "vn set")
}

func testDetectHumanBodyPose3DRequestConfig() {
    let request = DetectHumanBodyPose3DRequest(.revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 24))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectHumanBodyPose3DRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    visionExpect(request.supportedJointNames.contains(.root) || !request.supportedJointNames.isEmpty, "joints")
    visionExpect(!request.supportedJointsGroupNames.isEmpty, "groups")
    visionExpectEqual(request.descriptor, .detectHumanBodyPose3DRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectHumanBodyPose3D"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectHumanBodyPose3DRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "pose 3d")

    let vn = VNDetectHumanBodyPose3DRequest(completionHandler: { _, _ in })
    visionExpect(vn.completionHandler != nil, "completion")
    do {
        _ = try vn.supportedJointNames
        visionExpect(false, "vn 3d joints should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn 3d joints")
    }
    do {
        _ = try vn.supportedJointsGroupNames
        visionExpect(false, "vn 3d groups should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn 3d groups")
    }
}

func testClassifyImageRequestConfig() {
    var request = ClassifyImageRequest()
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(ClassifyImageRequest.supportedRevisions, [.revision2], "supported")
    visionExpectEqual(request.descriptor, .classifyImageRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("classifyImage"), "description")
    request.cropAndScaleAction = .centerCrop
    visionExpectEqual(request.cropAndScaleAction, .centerCrop, "crop")
    visionExpect(request.supportedIdentifiers.isEmpty, "no Apple taxonomy")
    request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 0.9, height: 0.9)
    visionExpectEqual(request.regionOfInterest.width, 0.9, "roi")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "classify")
}

func testDetectedDocumentObservationValues() {
    let quad = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0.1, y: 0.9),
        topRight: CGPoint(x: 0.9, y: 0.9),
        bottomRight: CGPoint(x: 0.9, y: 0.1),
        bottomLeft: CGPoint(x: 0.1, y: 0.1)
    )
    let observation = DetectedDocumentObservation(quad)!
    visionExpectEqual(observation.topLeft.x, 0.1, "topLeft")
    visionExpectEqual(observation.topRight.x, 0.9, "topRight")
    visionExpectEqual(observation.bottomRight.y, 0.1, "bottomRight")
    visionExpectEqual(observation.bottomLeft.x, 0.1, "bottomLeft")
    visionExpectEqual(observation.boundingBox.width, 0.8, "bbox")
    visionExpectEqual(observation.confidence, 1, "confidence")
    visionExpect(observation.uuid != UUID(), "uuid")
    visionExpect(observation.timeRange == .zero || observation.timeRange == nil, "timeRange")
    visionExpect(observation.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!observation.description.isEmpty, "description")
    visionExpectEqual(observation.globalSegmentationMask.confidence, 0, "mask")
    visionExpect(observation == observation, "equal")
    visionExpect(observation != DetectedDocumentObservation(
        topLeft: NormalizedPoint.zero,
        topRight: NormalizedPoint.zero,
        bottomRight: NormalizedPoint.zero,
        bottomLeft: NormalizedPoint.zero
    ), "unequal")
    _ = observation.hashValue
    var hasher = Hasher()
    observation.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(observation)
    let decoded = try! JSONDecoder().decode(DetectedDocumentObservation.self, from: encoded)
    visionExpectEqual(decoded.topLeft.x, 0.1, "codable")

    let document = DocumentObservation(
        document: DocumentObservation.Container(
            text: DocumentObservation.Container.Text(
                transcript: "Hello",
                detectedData: [
                    DocumentObservation.Container.DataDetectorMatch(
                        boundingRegion: ContoursObservation.Contour(points: [NormalizedPoint(x: 0, y: 0)], indexPath: IndexPath(index: 0)),
                        match: DataDetector.Match(matchedString: "Hello")
                    )
                ]
            ),
            lists: [
                DocumentObservation.Container.List(
                    items: [
                        DocumentObservation.Container.List.Item(itemString: "one", markerType: .bullet, markerString: "•")
                    ]
                )
            ],
            tables: [
                DocumentObservation.Container.Table(
                    rows: [[DocumentObservation.Container.Table.Cell(columnRange: 0...0, rowRange: 0...0)]],
                    columns: [[DocumentObservation.Container.Table.Cell(columnRange: 0...0, rowRange: 0...0)]]
                )
            ]
        )
    )
    let documentEncoded = try! JSONEncoder().encode(document)
    let documentDecoded = try! JSONDecoder().decode(DocumentObservation.self, from: documentEncoded)
    visionExpectEqual(documentDecoded.document.text.transcript, "Hello", "document codable")
    visionExpectEqual(documentDecoded.document.text.detectedData.first?.match.matchedString, "Hello", "detector")
    visionExpectEqual(documentDecoded.document.lists.first?.items.first?.itemString, "one", "list")
    visionExpectEqual(documentDecoded.document.tables.first?.rows.first?.first?.columnRange.lowerBound, 0, "table")
}

func testTrajectoryObservationValues() {
    let vn = VNTrajectoryObservation(
        detectedPoints: [VNPoint(x: 0.1, y: 0.2), VNPoint(x: 0.3, y: 0.4)],
        projectedPoints: [VNPoint(x: 0.5, y: 0.6)],
        equationCoefficients: SIMD3<Float>(1, 2, 3),
        movingAverageRadius: 0.12
    )
    visionExpectEqual(vn.detectedPoints.count, 2, "vn detected")
    visionExpectEqual(vn.projectedPoints.count, 1, "vn projected")
    visionExpectEqual(vn.equationCoefficients.y, 2, "vn coeffs")
    visionExpectEqual(vn.movingAverageRadius, 0.12, "vn radius")
    let overlay = TrajectoryObservation(vn)
    visionExpectEqual(overlay.detectedPoints.count, 2, "overlay detected")
    visionExpectEqual(overlay.projectedPoints.first?.x, 0.5, "overlay projected")
    visionExpectEqual(overlay.equationCoefficients.z, 3, "overlay coeffs")
    visionExpectEqual(overlay.movingAverageRadius, 0.12, "overlay radius")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != TrajectoryObservation(detectedPoints: []), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(TrajectoryObservation.self, from: encoded)
    visionExpectEqual(decoded.detectedPoints.count, 2, "codable")
}

func testStatefulRequestDefaults() {
    let spacing = VNStatefulRequest(frameAnalysisSpacing: CMTime(value: 4, timescale: 30))
    visionExpectEqual(spacing.frameAnalysisSpacing.value, 4, "spacing")
    visionExpectEqual(spacing.minimumLatencyFrameCount, 0, "latency")
}

func testPixelBufferObservationOverlayValues() {
    var pixels = [UInt8](repeating: 0, count: 2 * 2 * 4)
    pixels[0] = 10
    pixels[1] = 20
    pixels[2] = 30
    pixels[3] = 255
    let buffer = CVPixelBuffer(width: 2, height: 2, pixels: pixels)
    let vn = VNPixelBufferObservation(pixelBuffer: buffer, featureName: "mask")
    let overlay = PixelBufferObservation(vn)!
    visionExpectEqual(overlay.pixelFormat, kCVPixelFormatType_32BGRA, "format")
    visionExpectEqual(overlay.size.width, 2, "width")
    visionExpectEqual(overlay.size.height, 2, "height")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(overlay.uuid != UUID(), "uuid")
    visionExpect(overlay.timeRange == .zero || overlay.timeRange == nil, "timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!overlay.description.isEmpty, "description")
    let luma = overlay.pixel(at: NormalizedPoint(x: 0, y: 1))
    visionExpect(abs(luma - (10 + 20 + 30) / (3 * 255)) < 1e-5, "pixel at origin")
    let bytes = overlay.withUnsafePointer { ptr in
        ptr.load(as: UInt8.self)
    }
    visionExpectEqual(bytes, 10, "unsafe pointer")
    let image = try! overlay.cgImage
    visionExpectEqual(image.width, 2, "cgImage")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != PixelBufferObservation(), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(PixelBufferObservation.self, from: encoded)
    visionExpectEqual(decoded.size.width, 2, "codable size")
}

func visionInstanceMaskFixture() -> CVPixelBuffer {
    var pixels = [UInt8](repeating: 0, count: 4 * 4 * 4)
    for y in 0..<4 {
        for x in 0..<4 {
            let offset = (y * 4 + x) * 4
            let label: UInt8 = (x < 2 && y < 2) ? 1 : ((x >= 2 && y >= 2) ? 2 : 0)
            pixels[offset] = label
            pixels[offset + 3] = 255
        }
    }
    return CVPixelBuffer(width: 4, height: 4, pixels: pixels)
}

func visionExpectRevisionCodable<T: Codable & Equatable>(_ value: T, _ message: String) {
    let encoded = try! JSONEncoder().encode(value)
    let decoded = try! JSONDecoder().decode(T.self, from: encoded)
    visionExpectEqual(decoded, value, message)
}

func testDetectLensSmudgeRequestConfig() {
    var request = DetectLensSmudgeRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectLensSmudgeRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.cropAndScaleAction, .scaleToFill, "crop default")
    request.cropAndScaleAction = .centerCrop
    visionExpectEqual(request.cropAndScaleAction, .centerCrop, "crop set")
    request.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    visionExpectEqual(request.regionOfInterest.width, 0.8, "roi")
    visionExpectEqual(request.descriptor, .detectLensSmudgeRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectLensSmudge"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectLensSmudgeRequest(), "crop inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectLensSmudgeRequest.Revision.revision1, "revision codable")
    _ = DetectLensSmudgeRequest.Revision.revision1.hashValue
    visionExpect(DetectLensSmudgeRequest.Revision.revision1 != DetectLensSmudgeRequest.Revision.revision1 || request.revision == .revision1, "!=")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "lens smudge")
}

func testDetectFaceLandmarksRequestConfig() {
    var request = DetectFaceLandmarksRequest(.revision3)
    visionExpectEqual(request.revision, .revision3, "revision")
    visionExpectEqual(DetectFaceLandmarksRequest.supportedRevisions.contains(.revision3), true, "supported r3")
    visionExpectEqual(DetectFaceLandmarksRequest.supportedRevisions.contains(.revision1), true, "supported r1")
    visionExpectEqual(request.constellation, .constellationNotDefined, "constellation default")
    request.constellation = .constellation76Points
    visionExpectEqual(request.constellation, .constellation76Points, "constellation set")
    let face = FaceObservation(boundingBox: .fullImage, revision: .revision3)
    request.inputFaceObservations = [face]
    visionExpectEqual(request.inputFaceObservations?.count, 1, "input faces")
    request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: 1)
    visionExpectEqual(request.descriptor, .detectFaceLandmarksRequest(.revision3), "descriptor")
    visionExpect(request.description.contains("detectFaceLandmarks"), "description")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectFaceLandmarksRequest(), "constellation inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectFaceLandmarksRequest.Revision.revision3, "revision codable")
    visionExpect(DetectFaceLandmarksRequest.Revision.revision1 < .revision3, "revision <")
    visionExpect(VNDetectFaceLandmarksRequest.revision(VNDetectFaceLandmarksRequestRevision3, supportsConstellation: .constellation76Points), "vn constellation")
    visionExpect(!VNDetectFaceLandmarksRequest.revision(99, supportsConstellation: .constellation65Points), "unsupported rev")
    let vn = VNDetectFaceLandmarksRequest()
    vn.constellation = .constellation65Points
    visionExpectEqual(vn.constellation, .constellation65Points, "vn constellation set")
    let vnFace = VNFaceObservation(requestRevision: 3, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
    vn.inputFaceObservations = [vnFace]
    visionExpectEqual(vn.inputFaceObservations?.count, 1, "vn input faces")
    let accepting: any VNFaceObservationAccepting = vn
    visionExpectEqual(accepting.inputFaceObservations?.count, 1, "protocol faces")
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "face landmarks overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn landmarks should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testDetectHumanRectanglesRequestConfig() {
    var request = DetectHumanRectanglesRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(DetectHumanRectanglesRequest.supportedRevisions.contains(.revision2), true, "supported")
    visionExpectEqual(request.upperBodyOnly, false, "upper default")
    request.upperBodyOnly = true
    visionExpectEqual(request.upperBodyOnly, true, "upper set")
    request.regionOfInterest = NormalizedRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)
    visionExpectEqual(request.descriptor, .detectHumanRectanglesRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("detectHumanRectangles"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectHumanRectanglesRequest(), "upper inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectHumanRectanglesRequest.Revision.revision2, "revision codable")
    visionExpect(DetectHumanRectanglesRequest.Revision.revision1 < .revision2, "revision <")
    visionExpectEqual(VNDetectHumanRectanglesRequestRevision1, 1, "r1")
    visionExpectEqual(VNDetectHumanRectanglesRequestRevision2, 2, "r2")
    let vn = VNDetectHumanRectanglesRequest()
    visionExpectEqual(vn.upperBodyOnly, false, "vn upper")
    vn.upperBodyOnly = true
    visionExpectEqual(vn.upperBodyOnly, true, "vn upper set")
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "human rectangles overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn humans should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testDetectFaceCaptureQualityRequestConfig() {
    var request = DetectFaceCaptureQualityRequest(.revision3)
    visionExpectEqual(request.revision, .revision3, "revision")
    visionExpectEqual(DetectFaceCaptureQualityRequest.supportedRevisions.contains(.revision3), true, "supported")
    request.inputFaceObservations = [FaceObservation(boundingBox: .fullImage)]
    visionExpectEqual(request.inputFaceObservations?.count, 1, "input faces")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .detectFaceCaptureQualityRequest(.revision3), "descriptor")
    visionExpect(request.description.contains("detectFaceCaptureQuality"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectFaceCaptureQualityRequest(.revision1), "revision inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectFaceCaptureQualityRequest.Revision.revision3, "revision codable")
    let vn = VNDetectFaceCaptureQualityRequest()
    let vnFace = VNFaceObservation(requestRevision: 3, boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1))
    vn.inputFaceObservations = [vnFace]
    visionExpectEqual(vn.inputFaceObservations?.count, 1, "vn input faces")
    visionExpect(vn.results == nil, "vn results")
    visionExpectEqual(VNDetectFaceCaptureQualityRequest.currentRevision, VNDetectFaceCaptureQualityRequestRevision3, "vn rev")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "capture quality overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn capture quality should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testCalculateImageAestheticsScoresRequestConfig() {
    var request = CalculateImageAestheticsScoresRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(CalculateImageAestheticsScoresRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.cropAndScaleAction, .scaleToFill, "crop default")
    request.cropAndScaleAction = .scaleToFit
    visionExpectEqual(request.cropAndScaleAction, .scaleToFit, "crop set")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .calculateImageAestheticsScoresRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("calculateImageAesthetics"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != CalculateImageAestheticsScoresRequest(), "crop inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(CalculateImageAestheticsScoresRequest.Revision.revision1, "revision codable")
    let vn = VNCalculateImageAestheticsScoresRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "aesthetics overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn aesthetics should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testDetectDocumentSegmentationRequestConfig() {
    var request = DetectDocumentSegmentationRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectDocumentSegmentationRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: 1)
    visionExpectEqual(request.descriptor, .detectDocumentSegmentationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectDocumentSegmentation"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectDocumentSegmentationRequest() || request.regionOfInterest == .fullImage, "equal default")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectDocumentSegmentationRequest.Revision.revision1, "revision codable")
    let vn = VNDetectDocumentSegmentationRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "document segmentation overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn document segmentation should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testGeneratePersonInstanceMaskRequestConfig() {
    var request = GeneratePersonInstanceMaskRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(GeneratePersonInstanceMaskRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generatePersonInstanceMaskRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("generatePersonInstanceMask"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GeneratePersonInstanceMaskRequest.Revision.revision1, "revision codable")
    let vn = VNGeneratePersonInstanceMaskRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "person instance mask overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn person mask should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testGenerateForegroundInstanceMaskRequestConfig() {
    var request = GenerateForegroundInstanceMaskRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(GenerateForegroundInstanceMaskRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generateForegroundInstanceMaskRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("generateForegroundInstanceMask"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GenerateForegroundInstanceMaskRequest.Revision.revision1, "revision codable")
    let vn = VNGenerateForegroundInstanceMaskRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "foreground mask overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn foreground mask should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testGenerateAttentionBasedSaliencyImageRequestConfig() {
    var request = GenerateAttentionBasedSaliencyImageRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(GenerateAttentionBasedSaliencyImageRequest.supportedRevisions.contains(.revision2), true, "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generateAttentionBasedSaliencyImageRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("generateAttentionBasedSaliency"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != GenerateAttentionBasedSaliencyImageRequest(.revision1), "revision inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GenerateAttentionBasedSaliencyImageRequest.Revision.revision2, "revision codable")
    let vn = VNGenerateAttentionBasedSaliencyImageRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "attention saliency overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn attention should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testTrackObjectRequestOverlayConfig() {
    let seed = DetectedObjectObservation(boundingBox: NormalizedRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4))
    let request = TrackObjectRequest(detectedObject: seed, .revision2, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(TrackObjectRequest.supportedRevisions, [.revision2], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    visionExpectEqual(request.inputObservation.boundingBox.width, 0.4, "input")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .trackObjectRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("trackObject"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackObjectRequest(detectedObject: seed), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(TrackObjectRequest.Revision.revision2, "revision codable")
    let tracked = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(tracked != nil, "tracked object")
}

func testTrackHomographicImageRegistrationRequestConfig() {
    let request = TrackHomographicImageRegistrationRequest(.revision1, frameAnalysisSpacing: CMTime(value: 2, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackHomographicImageRegistrationRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 2, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .trackHomographicImageRegistrationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackHomographic"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackHomographicImageRegistrationRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(TrackHomographicImageRegistrationRequest.Revision.revision1, "revision codable")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "homographic track overlay")
    let vn = VNTrackHomographicImageRegistrationRequest()
    let withHandler = VNTrackHomographicImageRegistrationRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    visionExpect(vn.results == nil, "vn results")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn homographic track should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.unsupportedRequest.rawValue, "vn unsupportedRequest")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testTrackTranslationalImageRegistrationRequestConfig() {
    let request = TrackTranslationalImageRegistrationRequest(.revision1, frameAnalysisSpacing: CMTime(value: 3, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackTranslationalImageRegistrationRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 3, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .trackTranslationalImageRegistrationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackTranslational"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu stage")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackTranslationalImageRegistrationRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(TrackTranslationalImageRegistrationRequest.Revision.revision1, "revision codable")
    let first = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpectEqual(first.alignmentTransform, .identity, "first frame identity")
    let second = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(second.confidence >= 0, "second frame")
    let vn = VNTrackTranslationalImageRegistrationRequest()
    let withHandler = VNTrackTranslationalImageRegistrationRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    try! VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
    visionExpect((vn.results?.first as? VNImageTranslationAlignmentObservation) != nil, "vn first identity")
}

func testRecognizeTextRequestConfig() {
    var request = RecognizeTextRequest(.revision3)
    visionExpectEqual(request.revision, .revision3, "revision")
    visionExpectEqual(request.recognitionLevel, .accurate, "level")
    request.recognitionLevel = .fast
    visionExpectEqual(request.recognitionLevel, .fast, "level set")
    visionExpectEqual(RecognizeTextRequest.RecognitionLevel.allCases.count, 2, "levels")
    request.usesLanguageCorrection = false
    visionExpectEqual(request.usesLanguageCorrection, false, "correction")
    request.automaticallyDetectsLanguage = true
    visionExpectEqual(request.automaticallyDetectsLanguage, true, "autodetect")
    request.minimumTextHeightFraction = 0.05
    visionExpectEqual(request.minimumTextHeightFraction, 0.05, "height fraction")
    visionExpectEqual(request.minimumTextHeight, 0.05, "height alias")
    request.customWords = ["OpenUIKit"]
    visionExpectEqual(request.customWords.first, "OpenUIKit", "custom")
    request.recognitionLanguages = [Locale.Language(identifier: "en")]
    visionExpectEqual(request.recognitionLanguages.count, 1, "languages")
    visionExpectEqual(request.supportedRecognitionLanguages.isEmpty, true, "no apple languages")
    visionExpectEqual(request.descriptor, .recognizeTextRequest(.revision3), "descriptor")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "recognize text overlay")
}

func testDetectHorizonRequestConfig() {
    var request = DetectHorizonRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectHorizonRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .detectHorizonRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectHorizon"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectHorizonRequest.Revision.revision1, "revision codable")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "horizon overlay")
}

func testTextObservationOverlayValues() {
    let vnChar = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0.1, y: 0.6),
        topRight: CGPoint(x: 0.2, y: 0.6),
        bottomRight: CGPoint(x: 0.2, y: 0.4),
        bottomLeft: CGPoint(x: 0.1, y: 0.4)
    )
    let vn = VNTextObservation(
        topLeft: CGPoint(x: 0.1, y: 0.8),
        topRight: CGPoint(x: 0.9, y: 0.8),
        bottomRight: CGPoint(x: 0.9, y: 0.2),
        bottomLeft: CGPoint(x: 0.1, y: 0.2),
        characterBoxes: [vnChar],
        confidence: 0.9
    )
    visionExpectEqual(vn.characterBoxes?.count, 1, "vn character boxes")
    let overlay = TextObservation(vn)
    visionExpectEqual(overlay.topLeft.x, 0.1, "topLeft")
    visionExpectEqual(overlay.topRight.x, 0.9, "topRight")
    visionExpectEqual(overlay.bottomRight.y, 0.2, "bottomRight")
    visionExpectEqual(overlay.bottomLeft.y, 0.2, "bottomLeft")
    visionExpectEqual(overlay.confidence, 0.9, "confidence")
    visionExpectEqual(overlay.characterBoxes?.count, 1, "character boxes")
    visionExpect(overlay.boundingBox.width > 0.5, "boundingBox")
    visionExpect(overlay.uuid != UUID() || overlay.uuid == vn.uuid, "uuid")
    visionExpect(overlay.timeRange == .zero || overlay.timeRange == nil, "timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != TextObservation(topLeft: .zero, topRight: .zero, bottomRight: .zero, bottomLeft: .zero), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(TextObservation.self, from: encoded)
    visionExpectEqual(decoded.topLeft.x, 0.1, "codable")
}

func testHumanObservationOverlayValues() {
    let vn = VNHumanObservation(boundingBox: CGRect(x: 0.2, y: 0.1, width: 0.4, height: 0.5), upperBodyOnly: true)
    visionExpectEqual(vn.upperBodyOnly, true, "vn upper")
    let overlay = HumanObservation(vn)
    visionExpectEqual(overlay.boundingBox.width, 0.4, "bbox")
    visionExpectEqual(overlay.isUpperBodyOnly, true, "upper")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(!overlay.description.isEmpty, "description")
    let constructed = HumanObservation(boundingBox: .fullImage, revision: .revision2, isUpperBodyOnly: false)
    visionExpectEqual(constructed.boundingBox.width, 1, "constructed")
    visionExpectEqual(constructed.originatingRequestDescriptor, .detectHumanRectanglesRequest(.revision2), "descriptor")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != constructed, "unequal")
    _ = overlay.hashValue
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(HumanObservation.self, from: encoded)
    visionExpectEqual(decoded.isUpperBodyOnly, true, "codable")
}

func testSmudgeObservationOverlayValues() {
    let observation = SmudgeObservation(confidence: 0.4, uuid: UUID(), timeRange: .zero, originatingRequestDescriptor: .detectLensSmudgeRequest(.revision1))
    visionExpectEqual(observation.confidence, 0.4, "confidence")
    visionExpect(observation.timeRange != nil, "timeRange")
    visionExpectEqual(observation.originatingRequestDescriptor, .detectLensSmudgeRequest(.revision1), "descriptor")
    visionExpect(!observation.description.isEmpty, "description")
    visionExpect(observation == observation, "equal")
    visionExpect(observation != SmudgeObservation(), "unequal")
    _ = observation.hashValue
    var hasher = Hasher()
    observation.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(observation)
    let decoded = try! JSONDecoder().decode(SmudgeObservation.self, from: encoded)
    visionExpectEqual(decoded.confidence, 0.4, "codable")
}

func testInstanceMaskObservationSuppliedData() {
    let buffer = visionInstanceMaskFixture()
    let vn = VNInstanceMaskObservation(instanceMask: buffer)
    visionExpectEqual(vn.allInstances.contains(1), true, "vn label 1")
    visionExpectEqual(vn.allInstances.contains(2), true, "vn label 2")
    visionExpectEqual(vn.instanceMask.width, 4, "vn mask size")
    let mask1 = try! vn.generateMask(forInstances: IndexSet(integer: 1))
    visionExpectEqual(mask1.pixels[0], 255, "instance 1 white")
    visionExpectEqual(mask1.pixels[(3 * 4 + 3) * 4], 0, "instance 2 black in mask1")
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let scaled = try! vn.generateScaledMaskForImage(forInstances: IndexSet(integer: 1), from: handler)
    visionExpectEqual(scaled.width, 80, "scaled width")
    let masked = try! vn.generateMaskedImage(ofInstances: IndexSet(integer: 1), from: handler, croppedToInstancesExtent: true)
    visionExpect(masked.width > 0 && masked.height > 0, "cropped masked image")

    let overlay = InstanceMaskObservation(vn)!
    visionExpectEqual(overlay.allInstances.contains(1), true, "overlay labels")
    visionExpectEqual(overlay.allInstancesMask.size.width, 4, "allInstancesMask")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(!overlay.description.isEmpty, "description")
    let overlayMask = try! overlay.generateMask(for: IndexSet(integer: 2))
    visionExpectEqual(overlayMask.pixels[(3 * 4 + 3) * 4], 255, "overlay instance 2")
    let imageHandler = ImageRequestHandler(visionRectangleImage())
    let scaledOverlay = try! overlay.generateScaledMask(for: IndexSet(integer: 1), scaledToImageFrom: imageHandler)
    visionExpect(scaledOverlay.width > 4, "overlay scaled")
    let maskedOverlay = try! overlay.generateMaskedImage(for: IndexSet(integer: 1), imageFrom: imageHandler, croppedToInstancesExtent: false)
    visionExpectEqual(maskedOverlay.width, 80, "full image mask apply")
    let atPoint = overlay.instanceAtPoint(NormalizedPoint(x: 0.1, y: 0.9))
    visionExpectEqual(atPoint.contains(1), true, "instance at point")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != InstanceMaskObservation(instanceMask: CVPixelBuffer(width: 1, height: 1)), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(InstanceMaskObservation.self, from: encoded)
    visionExpectEqual(decoded.allInstances.contains(1), true, "codable")
}

func testSaliencyImageObservationValues() {
    let buffer = CVPixelBuffer(width: 2, height: 2, pixels: [UInt8](repeating: 128, count: 16))
    let rect = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let vn = VNSaliencyImageObservation(pixelBuffer: buffer, salientObjects: [rect])
    visionExpectEqual(vn.salientObjects?.count, 1, "vn salient")
    let overlay = SaliencyImageObservation(vn)!
    visionExpectEqual(overlay.salientObjects.count, 1, "overlay salient")
    visionExpectEqual(overlay.heatMap.size.width, 2, "heatMap")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != SaliencyImageObservation(), "unequal")
    _ = overlay.hashValue
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(SaliencyImageObservation.self, from: encoded)
    visionExpectEqual(decoded.salientObjects.count, 1, "codable")
}

func testImageAestheticsScoresObservationValues() {
    let vn = VNImageAestheticsScoresObservation(overallScore: 0.7, isUtility: true)
    visionExpectEqual(vn.overallScore, 0.7, "vn score")
    visionExpectEqual(vn.isUtility, true, "vn utility")
    let overlay = ImageAestheticsScoresObservation(vn)
    visionExpectEqual(overlay.overallScore, 0.7, "overlay score")
    visionExpectEqual(overlay.isUtility, true, "overlay utility")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != ImageAestheticsScoresObservation(), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(ImageAestheticsScoresObservation.self, from: encoded)
    visionExpectEqual(decoded.overallScore, 0.7, "codable")
}

func testGenerateObjectnessBasedSaliencyImageRequestConfig() {
    var request = GenerateObjectnessBasedSaliencyImageRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(GenerateObjectnessBasedSaliencyImageRequest.supportedRevisions.contains(.revision2), true, "supported")
    visionExpectEqual(GenerateObjectnessBasedSaliencyImageRequest.supportedRevisions.contains(.revision1), true, "supported r1")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generateObjectnessBasedSaliencyImageRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("generateObjectnessBasedSaliency"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != GenerateObjectnessBasedSaliencyImageRequest(.revision1), "revision inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GenerateObjectnessBasedSaliencyImageRequest.Revision.revision2, "revision codable")
    visionExpect(GenerateObjectnessBasedSaliencyImageRequest.Revision.revision1 < .revision2, "revision <")
    let vn = VNGenerateObjectnessBasedSaliencyImageRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectEqual(VNGenerateObjectnessBasedSaliencyImageRequest.currentRevision, VNGenerateObjectnessBasedSaliencyImageRequestRevision2, "vn rev")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "objectness overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn objectness should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testRequestProgressAndRevisionProviding() {
    let request = VNDetectBarcodesRequest()
    visionExpect(request.indeterminate, "linux progress is indeterminate")
    var ticks = 0
    request.progressHandler = { _, _, _ in ticks += 1 }
    request.progressHandler(request, 0.5, nil)
    visionExpectEqual(ticks, 1, "stored progress handler")
    let providing: any VNRequestProgressProviding = request
    visionExpect(providing.indeterminate, "protocol indeterminate")

    let observation = VNDetectedObjectObservation(
        requestRevision: 3,
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    )
    visionExpectEqual(observation.requestRevision, 3, "stored revision")
    let revisionProviding: any VNRequestRevisionProviding = observation
    visionExpectEqual(revisionProviding.requestRevision, 3, "protocol revision")
    let copy = observation.copy() as! VNDetectedObjectObservation
    visionExpectEqual(copy.requestRevision, 3, "copied revision")
    visionExpect(copy !== observation, "detected copy is independent")
    visionExpectEqual(copy.uuid, observation.uuid, "copied uuid")
    visionExpectEqual(copy.confidence, observation.confidence, "copied confidence")
    visionExpectEqual(copy.boundingBox, observation.boundingBox, "copied bounds")
    copy.requestRevision = 1
    visionExpectEqual(observation.requestRevision, 3, "copy mutation leaves source revision")

    let rectangle = VNRectangleObservation(
        requestRevision: 3,
        topLeft: CGPoint(x: 0.1, y: 0.8),
        topRight: CGPoint(x: 0.7, y: 0.8),
        bottomRight: CGPoint(x: 0.7, y: 0.2),
        bottomLeft: CGPoint(x: 0.1, y: 0.2)
    )
    let rectangleCopy = rectangle.copy() as! VNRectangleObservation
    visionExpectEqual(rectangleCopy.requestRevision, 3, "rectangle copied revision")
    visionExpect(rectangleCopy !== rectangle, "rectangle copy is independent")
    visionExpectEqual(rectangleCopy.uuid, rectangle.uuid, "rectangle copied uuid")
    visionExpectEqual(rectangleCopy.boundingBox, rectangle.boundingBox, "rectangle copied bounds")
    visionExpectEqual(rectangleCopy.topLeft, rectangle.topLeft, "rectangle copied top left")
    visionExpectEqual(rectangleCopy.topRight, rectangle.topRight, "rectangle copied top right")
    visionExpectEqual(rectangleCopy.bottomLeft, rectangle.bottomLeft, "rectangle copied bottom left")
    visionExpectEqual(rectangleCopy.bottomRight, rectangle.bottomRight, "rectangle copied bottom right")
    let base = VNObservation(requestRevision: 3)
    visionExpectEqual((base.copy() as! VNObservation).requestRevision, 3, "base copied revision")
}
