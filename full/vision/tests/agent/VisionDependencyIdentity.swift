import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreImage)
import CoreImage
#endif
import Vision

enum VisionDependencyFailure: Error {
    case message(String)
}

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw VisionDependencyFailure.message(message) }
}

public func visionDependencyIdentityMain() throws {
#if canImport(CoreGraphics)
    let box = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let detected = VNDetectedObjectObservation(boundingBox: box)
    var assigned: CGRect = .zero
    assigned = detected.boundingBox
    try require(assigned == box, "CGRect identity")
    let point = VNImagePointForNormalizedPoint(CGPoint(x: 0.5, y: 0.5), 10, 20)
    try require(point.x == 5 && point.y == 10, "CGPoint mapping")
#else
    throw VisionDependencyFailure.message("CoreGraphics is required")
#endif
#if canImport(CoreImage)
    _ = CIImage.self
#else
    throw VisionDependencyFailure.message("CoreImage is required")
#endif
    print("VISION_DEPENDENCY_IDENTITY_OK")
}
