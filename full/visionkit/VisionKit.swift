import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(CoreImage)
import CoreImage
#endif
#if canImport(CoreVideo)
import CoreVideo
#endif
#if canImport(Vision)
import Vision
#endif

/// Linux starting point for Apple's public `VisionKit` module.
///
/// Hardware, camera, privacy, Neural Engine, and Apple-service paths are
/// fail-closed. Host-only errors and fixtures are SPI, not Apple surface.
@_spi(OpenUIKitHost)
public enum VisionKitHostError: Error, Equatable, Hashable, Sendable {
    /// `ImageAnalyzer` requires Apple on-device models (A12 / Neural Engine).
    case imageAnalysisUnsupported
    /// Live camera capture is not available on this host.
    case cameraUnavailable
    /// `VNDocumentCameraViewController` has no document-scan backend here.
    case documentCameraUnsupported
}
