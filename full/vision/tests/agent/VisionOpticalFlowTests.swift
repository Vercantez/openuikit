#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

/// Median (dx, dy) over the central band of a flow buffer, in reference pixels.
func visionMedianFlow(_ buffer: CVPixelBuffer) -> SIMD2<Float> {
    var xs: [Float] = []
    var ys: [Float] = []
    xs.reserveCapacity(1024)
    ys.reserveCapacity(1024)
    let x0 = buffer.width / 4
    let x1 = buffer.width * 3 / 4
    let y0 = buffer.height / 4
    let y1 = buffer.height * 3 / 4
    for y in y0..<max(y0 + 1, y1) {
        for x in x0..<max(x0 + 1, x1) {
            if let vector = buffer.flowVector(x: x, y: y) {
                xs.append(vector.x)
                ys.append(vector.y)
            }
        }
    }
    visionExpect(!xs.isEmpty, "flow band is non-empty")
    xs.sort()
    ys.sort()
    return SIMD2<Float>(xs[xs.count / 2], ys[ys.count / 2])
}

func visionMaxFlowMagnitude(_ buffer: CVPixelBuffer) -> Float {
    var peak: Float = 0
    for y in 0..<buffer.height {
        for x in 0..<buffer.width {
            if let vector = buffer.flowVector(x: x, y: y) {
                peak = max(peak, abs(vector.x), abs(vector.y))
            }
        }
    }
    return peak
}

func testGenerateOpticalFlowClassical() {
    let reference = visionNoiseTextureImage()
    let target = visionNoiseTextureImage(shiftX: 6, shiftY: 2)
    let request = VNGenerateOpticalFlowRequest(targetedCGImage: target)
    visionExpectEqual(request.computationAccuracy, .medium, "flow accuracy default")
    visionExpectEqual(request.outputPixelFormat, kCVPixelFormatType_TwoComponent32Float, "flow format default")
    visionExpect(!request.keepNetworkOutput, "flow keep default")
    request.computationAccuracy = .high
    request.keepNetworkOutput = true
    visionExpectEqual(request.computationAccuracy, .high, "flow accuracy set")
    visionExpect(request.keepNetworkOutput, "flow keep set")
    visionExpect(request.results == nil, "flow results begin nil")
    try! VNImageRequestHandler(cgImage: reference).perform([request])
    guard let observation = request.results?.first as? VNPixelBufferObservation else {
        visionExpect(false, "flow produces a pixel-buffer observation")
        return
    }
    let buffer = observation.pixelBuffer
    visionExpectEqual(buffer.width, 80, "flow width matches reference")
    visionExpectEqual(buffer.height, 80, "flow height matches reference")
    visionExpectEqual(buffer.pixelFormat, kCVPixelFormatType_TwoComponent32Float, "flow buffer format")
    let median = visionMedianFlow(buffer)
    visionExpect(abs(median.x - 6) <= 2, "flow dx recovers shift: \(median.x)")
    visionExpect(abs(median.y - 2) <= 2, "flow dy recovers shift: \(median.y)")
}

func testGenerateOpticalFlowIdenticalFrames() {
    let frame = visionNoiseTextureImage()
    let request = VNGenerateOpticalFlowRequest(targetedCGImage: frame)
    try! VNImageRequestHandler(cgImage: frame).perform([request])
    guard let observation = request.results?.first as? VNPixelBufferObservation else {
        visionExpect(false, "identical flow produces a pixel-buffer observation")
        return
    }
    visionExpect(visionMaxFlowMagnitude(observation.pixelBuffer) < 0.5, "identical frames read ~0 flow")
}

func testGenerateOpticalFlowMissingTargetError() {
    let request = VNGenerateOpticalFlowRequest()
    do {
        try VNImageRequestHandler(cgImage: visionNoiseTextureImage()).perform([request])
        visionExpect(false, "missing targeted image must throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.missingOption.rawValue, "missing targeted image code")
        visionExpect(request.results == nil, "failed request has no fabricated results")
    }
}

func testGenerateOpticalFlowRevisions() {
    visionExpectEqual(VNGenerateOpticalFlowRequest.currentRevision, VNGenerateOpticalFlowRequestRevision2, "flow current")
    visionExpectEqual(VNGenerateOpticalFlowRequest.defaultRevision, VNGenerateOpticalFlowRequestRevision2, "flow default")
    visionExpectEqual(
        VNGenerateOpticalFlowRequest.supportedRevisions,
        IndexSet(integersIn: VNGenerateOpticalFlowRequestRevision1...VNGenerateOpticalFlowRequestRevision2),
        "flow supported"
    )
    let request = VNGenerateOpticalFlowRequest()
    visionExpectEqual(request.revision, VNGenerateOpticalFlowRequestRevision2, "flow request revision")
}

func testTrackOpticalFlowSequential() {
    let frames = [visionNoiseTextureImage(), visionNoiseTextureImage(shiftX: 6, shiftY: 2)]
    let request = VNTrackOpticalFlowRequest()
    visionExpectEqual(request.computationAccuracy, .medium, "track accuracy default")
    visionExpectEqual(request.outputPixelFormat, kCVPixelFormatType_TwoComponent32Float, "track format default")
    let sequence = VNSequenceRequestHandler()
    try! sequence.perform([request], on: frames[0])
    guard let first = request.results?.first as? VNPixelBufferObservation else {
        visionExpect(false, "first track frame produces a flow observation")
        return
    }
    visionExpect(visionMaxFlowMagnitude(first.pixelBuffer) < 0.5, "first track frame is zero flow")
    try! sequence.perform([request], on: frames[1])
    guard let second = request.results?.first as? VNPixelBufferObservation else {
        visionExpect(false, "second track frame produces a flow observation")
        return
    }
    let median = visionMedianFlow(second.pixelBuffer)
    visionExpect(abs(median.x - 6) <= 2, "track dx recovers shift: \(median.x)")
    visionExpect(abs(median.y - 2) <= 2, "track dy recovers shift: \(median.y)")
}

func testOverlayTrackOpticalFlowSequential() {
    let request = TrackOpticalFlowRequest()
    let first = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionNoiseTextureImage()))
    guard let firstBuffer = first?.pixelBuffer else {
        visionExpect(false, "overlay first frame produces flow")
        return
    }
    visionExpect(visionMaxFlowMagnitude(firstBuffer) < 0.5, "overlay first frame is zero flow")
    let second = try! request.performOnHandler(
        VNImageRequestHandler(cgImage: visionNoiseTextureImage(shiftX: 6, shiftY: 2))
    )
    guard let secondBuffer = second?.pixelBuffer else {
        visionExpect(false, "overlay second frame produces flow")
        return
    }
    let median = visionMedianFlow(secondBuffer)
    visionExpect(abs(median.x - 6) <= 2.5, "overlay dx recovers shift: \(median.x)")
    visionExpect(abs(median.y - 2) <= 2.5, "overlay dy recovers shift: \(median.y)")
}

func testOpticalFlowBufferRoundTrip() {
    visionExpectEqual(kCVPixelFormatType_TwoComponent32Float, 0x32433066, "flow fourcc")
    let vectors = [SIMD2<Float>(1.5, -2.5), SIMD2<Float>(0, 0), SIMD2<Float>(6, 2), SIMD2<Float>(-4, 8)]
    let buffer = CVPixelBuffer(flowWidth: 2, flowHeight: 2, vectors: vectors)
    visionExpectEqual(buffer.pixelFormat, kCVPixelFormatType_TwoComponent32Float, "flow pixel format")
    visionExpectEqual(buffer.pixels.count, 32, "flow byte count")
    for (index, expected) in vectors.enumerated() {
        guard let actual = buffer.flowVector(x: index % 2, y: index / 2) else {
            visionExpect(false, "flow vector readable")
            return
        }
        visionExpectEqual(actual, expected, "flow vector round trip")
    }
    visionExpect(buffer.flowVector(x: 2, y: 0) == nil, "flow out of bounds is nil")
    let rgba = CVPixelBuffer(width: 2, height: 2)
    visionExpectEqual(rgba.pixelFormat, kCVPixelFormatType_32BGRA, "rgba default format")
    visionExpect(rgba.flowVector(x: 0, y: 0) == nil, "rgba has no flow vectors")
}
