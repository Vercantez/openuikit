#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

/// Translation components of a homographic warp in the port's Linux-local
/// convention: warpTransform maps source (targeted/previous) pixel coordinates
/// to reference (handler/current) pixel coordinates, column-major.
func visionWarpTranslation(_ warp: matrix_float3x3) -> (tx: Float, ty: Float) {
    (warp.columns.2.x, warp.columns.2.y)
}

func visionMovingSquareFrames() -> [CGImage] {
    var frames: [CGImage] = []
    for step in 0..<3 {
        var raster = VisionRaster(width: 80, height: 80, filled: (0, 0, 0, 255))
        let originX = 10 + step * 8
        let originY = 10 + step * 4
        for y in originY..<(originY + 12) {
            for x in originX..<(originX + 12) {
                raster[x, y] = (255, 255, 255, 255)
            }
        }
        frames.append(raster.makeCGImage())
    }
    return frames
}

func testHomographicRegistrationClassical() {
    let base = visionNoiseTextureImage()
    let shifted = visionNoiseTextureImage(shiftX: 6, shiftY: 2)
    let request = VNHomographicImageRegistrationRequest(targetedCGImage: base)
    visionExpect(request.results == nil, "homography results begin nil")
    try! VNImageRequestHandler(cgImage: shifted).perform([request])
    guard let observation = request.results?.first as? VNImageHomographicAlignmentObservation else {
        visionExpect(false, "homography produces an alignment observation")
        return
    }
    let warp = observation.warpTransform
    let shift = visionWarpTranslation(warp)
    visionExpect(abs(shift.tx - 6) <= 2.5, "homography tx recovers shift: \(shift.tx)")
    visionExpect(abs(shift.ty - 2) <= 2.5, "homography ty recovers shift: \(shift.ty)")
    visionExpect(observation.confidence > 0, "homography confidence positive")
}

func testHomographicRegistrationIdentical() {
    let frame = visionNoiseTextureImage()
    let request = VNHomographicImageRegistrationRequest(targetedCGImage: frame)
    try! VNImageRequestHandler(cgImage: frame).perform([request])
    guard let observation = request.results?.first as? VNImageHomographicAlignmentObservation else {
        visionExpect(false, "identical homography produces an observation")
        return
    }
    let shift = visionWarpTranslation(observation.warpTransform)
    visionExpect(abs(shift.tx) < 1.5, "identical homography tx ~0: \(shift.tx)")
    visionExpect(abs(shift.ty) < 1.5, "identical homography ty ~0: \(shift.ty)")
    visionExpect(abs(observation.warpTransform.columns.0.x - 1) < 0.15, "identical homography scale ~1")
    visionExpect(abs(observation.warpTransform.columns.1.y - 1) < 0.15, "identical homography scale ~1")
}

func testHomographicRegistrationMissingTarget() {
    let request = VNHomographicImageRegistrationRequest()
    do {
        try VNImageRequestHandler(cgImage: visionNoiseTextureImage()).perform([request])
        visionExpect(false, "missing targeted image must throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.missingOption.rawValue, "missing targeted image code")
        visionExpect(request.results == nil, "failed request has no fabricated results")
    }
}

func testTrackHomographicSequential() {
    let frames = [visionNoiseTextureImage(), visionNoiseTextureImage(shiftX: 6, shiftY: 2)]
    let request = VNTrackHomographicImageRegistrationRequest()
    visionExpect(request.results == nil, "track results begin nil")
    let sequence = VNSequenceRequestHandler()
    try! sequence.perform([request], on: frames[0])
    guard let first = request.results?.first as? VNImageHomographicAlignmentObservation else {
        visionExpect(false, "first track frame produces an observation")
        return
    }
    visionExpect(first.warpTransform == .identity, "first track frame is identity")
    visionExpectEqual(first.confidence, 1, "first track frame confidence")
    try! sequence.perform([request], on: frames[1])
    guard let second = request.results?.first as? VNImageHomographicAlignmentObservation else {
        visionExpect(false, "second track frame produces an observation")
        return
    }
    let shift = visionWarpTranslation(second.warpTransform)
    visionExpect(abs(shift.tx - 6) <= 2.5, "track tx recovers shift: \(shift.tx)")
    visionExpect(abs(shift.ty - 2) <= 2.5, "track ty recovers shift: \(shift.ty)")
}

func testOverlayTrackHomographicSequential() {
    let request = TrackHomographicImageRegistrationRequest()
    let first = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionNoiseTextureImage()))
    visionExpect(first.warpTransform == .identity, "overlay first frame is identity")
    let second = try! request.performOnHandler(
        VNImageRequestHandler(cgImage: visionNoiseTextureImage(shiftX: 6, shiftY: 2))
    )
    let shift = visionWarpTranslation(second.warpTransform)
    visionExpect(abs(shift.tx - 6) <= 2.5, "overlay tx recovers shift: \(shift.tx)")
    visionExpect(abs(shift.ty - 2) <= 2.5, "overlay ty recovers shift: \(shift.ty)")
    let mapped = ImageHomographicAlignmentObservation(warpTransform: second.warpTransform)
    visionExpect(mapped.warpTransform == second.warpTransform, "overlay warp round trip")
}

func testOverlayHomographicObservationValues() {
    let warp = matrix_float3x3(columns: (
        SIMD3<Float>(1, 0.02, 0.001),
        SIMD3<Float>(-0.01, 1, 0.002),
        SIMD3<Float>(6, 2, 1)
    ))
    var observation = ImageHomographicAlignmentObservation(warpTransform: warp, confidence: 0.8)
    visionExpectEqual(observation.warpTransform, warp, "overlay warp stored")
    visionExpectEqual(observation.confidence, 0.8, "overlay confidence")
    visionExpect(observation.description.contains("ImageHomographic"), "overlay description")
    observation.warpTransform = .identity
    visionExpectEqual(observation.warpTransform, .identity, "overlay warp settable")
    visionExpect(observation == observation, "overlay equal")
    visionExpect(observation != ImageHomographicAlignmentObservation(), "overlay inequality")
    _ = observation.hashValue
    var hasher = Hasher()
    observation.hash(into: &hasher)
    let image = visionRectangleImage()
    let applied = observation.applyTransform(to: CIImage(cgImage: image))
    visionExpect(applied.cgImage != nil, "overlay applyTransform passes through")
    let vnObservation = VNImageHomographicAlignmentObservation(confidence: 0.6)
    vnObservation.warpTransform = warp
    let mapped = ImageHomographicAlignmentObservation(vnObservation)
    visionExpectEqual(mapped.warpTransform, warp, "overlay init from VN observation")
    visionExpectEqual(mapped.confidence, 0.6, "overlay confidence from VN observation")
    visionExpectEqual(mapped.uuid, vnObservation.uuid, "overlay uuid from VN observation")
    let encoded = try! JSONEncoder().encode(ImageHomographicAlignmentObservation(warpTransform: warp, confidence: 0.8))
    let decoded = try! JSONDecoder().decode(ImageHomographicAlignmentObservation.self, from: encoded)
    visionExpectEqual(decoded.warpTransform, warp, "overlay warp codable round trip")
    visionExpectEqual(decoded.confidence, 0.8, "overlay confidence codable round trip")
}

func testForegroundInstanceMaskClassical() {
    let request = VNGenerateForegroundInstanceMaskRequest()
    visionExpect(request.results == nil, "foreground results begin nil")
    try! VNImageRequestHandler(cgImage: visionRectangleImage()).perform([request])
    guard let observation = request.results?.first as? VNInstanceMaskObservation else {
        visionExpect(false, "foreground mask produces an observation")
        return
    }
    visionExpectEqual(observation.allInstances, IndexSet(integer: 1), "foreground labels")
    visionExpect(observation.confidence > 0, "foreground confidence positive")
    let mask = try! observation.generateMask(forInstances: IndexSet(integer: 1))
    visionExpectEqual(mask.width, 80, "foreground mask width")
    visionExpectEqual(mask.height, 80, "foreground mask height")
    var white = 0
    for y in 0..<mask.height {
        for x in 0..<mask.width {
            let offset = (y * mask.width + x) * 4
            if mask.pixels[offset] > 0 { white += 1 }
        }
    }
    visionExpect(white > 100, "foreground mask covers the square: \(white)")
    let centerOffset = (40 * mask.width + 40) * 4
    visionExpect(mask.pixels[centerOffset] == 255, "foreground hole filled at center")
    let uniform = VNGenerateForegroundInstanceMaskRequest()
    try! VNImageRequestHandler(cgImage: visionUniformGrayImage()).perform([uniform])
    guard let empty = uniform.results?.first as? VNInstanceMaskObservation else {
        visionExpect(false, "uniform foreground produces an observation")
        return
    }
    visionExpect(empty.allInstances.isEmpty, "uniform foreground has no instances")
    visionExpectEqual(empty.confidence, 0, "uniform foreground confidence is zero")
}

func testOverlayForegroundInstanceMask() {
    let request = GenerateForegroundInstanceMaskRequest(.revision1)
    let found = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    guard let observation = found else {
        visionExpect(false, "overlay foreground mask is non-nil")
        return
    }
    visionExpectEqual(observation.allInstances, IndexSet(integer: 1), "overlay foreground labels")
    let scaled = try! observation.generateScaledMask(
        for: IndexSet(integer: 1),
        scaledToImageFrom: ImageRequestHandler(visionRectangleImage())
    )
    visionExpectEqual(scaled.width, 80, "overlay scaled mask width")
    let uniformRequest = GenerateForegroundInstanceMaskRequest(.revision1)
    let uniform = try! uniformRequest.performOnHandler(VNImageRequestHandler(cgImage: visionUniformGrayImage()))
    visionExpect(uniform?.allInstances.isEmpty == true, "overlay uniform foreground is empty")
}

func testDetectTrajectoriesClassical() {
    let frames = visionMovingSquareFrames()
    let request = VNDetectTrajectoriesRequest(
        frameAnalysisSpacing: CMTime(value: 1, timescale: 30),
        trajectoryLength: 3
    )
    request.objectMinimumNormalizedRadius = 0.01
    let sequence = VNSequenceRequestHandler()
    try! sequence.perform([request], on: frames[0])
    visionExpect((request.results ?? []).isEmpty, "first frame seeds tracklets")
    try! sequence.perform([request], on: frames[1])
    visionExpect((request.results ?? []).isEmpty, "second frame is below latency")
    try! sequence.perform([request], on: frames[2])
    let found = (request.results ?? []).compactMap { $0 as? VNTrajectoryObservation }
    visionExpect(!found.isEmpty, "moving square yields a trajectory")
    guard let trajectory = found.first else { return }
    visionExpect(trajectory.detectedPoints.count >= 3, "trajectory has latency points")
    visionExpect(!trajectory.projectedPoints.isEmpty, "trajectory projects forward")
    guard let first = trajectory.detectedPoints.first, let last = trajectory.detectedPoints.last else {
        visionExpect(false, "trajectory endpoints exist")
        return
    }
    visionExpect(last.x > first.x, "trajectory moves right: \(first.x) -> \(last.x)")
    visionExpect(last.y < first.y, "trajectory moves down in pixels: \(first.y) -> \(last.y)")
    visionExpect(trajectory.equationCoefficients.x > 0, "trajectory velocity vx positive")
    visionExpect(trajectory.movingAverageRadius > 0, "trajectory radius positive")
    visionExpect(trajectory.confidence > 0, "trajectory confidence positive")
}

func testDetectTrajectoriesStaticEmpty() {
    let frame = visionMovingSquareFrames()[0]
    let request = VNDetectTrajectoriesRequest(
        frameAnalysisSpacing: CMTime(value: 1, timescale: 30),
        trajectoryLength: 2
    )
    let sequence = VNSequenceRequestHandler()
    try! sequence.perform([request], on: frame)
    try! sequence.perform([request], on: frame)
    try! sequence.perform([request], on: frame)
    visionExpect((request.results ?? []).isEmpty, "static frames yield no trajectories")
}

func testOverlayDetectTrajectories() {
    let frames = visionMovingSquareFrames()
    let request = DetectTrajectoriesRequest(trajectoryLength: 3, .revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    request.objectMinimumNormalizedRadius = 0.01
    let first = try! request.performOnHandler(VNImageRequestHandler(cgImage: frames[0]))
    visionExpect(first.isEmpty, "overlay first frame seeds tracklets")
    _ = try! request.performOnHandler(VNImageRequestHandler(cgImage: frames[1]))
    let third = try! request.performOnHandler(VNImageRequestHandler(cgImage: frames[2]))
    visionExpect(!third.isEmpty, "overlay moving square yields a trajectory")
    guard let trajectory = third.first else { return }
    visionExpect(!trajectory.detectedPoints.isEmpty, "overlay trajectory points")
    visionExpect(!trajectory.projectedPoints.isEmpty, "overlay trajectory projection")
    guard let head = trajectory.detectedPoints.first, let tail = trajectory.detectedPoints.last else {
        visionExpect(false, "overlay trajectory endpoints exist")
        return
    }
    visionExpect(tail.x > head.x, "overlay trajectory moves right")
}
