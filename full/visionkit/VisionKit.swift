import Foundation

/// Linux starting point for Apple's public `VisionKit` module.
///
/// Type-complete APIs for document scanning, live-camera data scanning, and
/// Live Text image analysis are present and compile. Hardware, camera,
/// privacy, Neural Engine, and Apple-service paths are fail-closed: they
/// never report success on this host.
public enum VisionKitAvailabilityError: Error, Equatable, Hashable, Sendable {
    /// `ImageAnalyzer` requires Apple Silicon / A12-class on-device models.
    case imageAnalysisUnsupported
    /// Live camera capture is not available on this host.
    case cameraUnavailable
    /// `VNDocumentCameraViewController` has no document-scan backend here.
    case documentCameraUnsupported
}

extension VisionKitAvailabilityError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .imageAnalysisUnsupported:
            return "ImageAnalyzer is unsupported without Apple on-device analysis."
        case .cameraUnavailable:
            return "VisionKit camera capture is unavailable on this host."
        case .documentCameraUnsupported:
            return "VNDocumentCameraViewController has no document-scan backend on this host."
        }
    }
}
