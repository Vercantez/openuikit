import Foundation

@frozen
public enum VNBarcodeCompositeType: Int, CaseIterable, Sendable {
    case none = 0
    case linked = 1
    case gs1TypeA = 2
    case gs1TypeB = 3
    case gs1TypeC = 4
}

@frozen
public enum VNChirality: Int, CaseIterable, Sendable {
    case unknown = 0
    case left = -1
    case right = 1
}

public enum VNElementType: UInt, CaseIterable, Sendable {
    case unknown = 0
    case float = 1
    case double = 2
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

public enum VNImageCropAndScaleOption: UInt, CaseIterable, Sendable {
    case centerCrop = 0
    case scaleFit = 1
    case scaleFill = 2
    case scaleFitRotate90CCW = 257
    case scaleFillRotate90CCW = 258
}

@frozen
public enum VNPointsClassification: Int, CaseIterable, Sendable {
    case disconnected = 0
    case openPath = 1
    case closedPath = 2
}

public enum VNRequestFaceLandmarksConstellation: UInt, CaseIterable, Sendable {
    case constellationNotDefined = 0
    case constellation65Points = 1
    case constellation76Points = 2
}

public enum VNRequestTextRecognitionLevel: Int, CaseIterable, Sendable {
    case accurate = 0
    case fast = 1
}

public enum VNRequestTrackingLevel: UInt, CaseIterable, Sendable {
    case accurate = 0
    case fast = 1
}
