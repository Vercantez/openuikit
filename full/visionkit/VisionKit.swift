@_exported import Foundation

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

/// Linux-local analyzer failure. Not part of Apple's public VisionKit graph;
/// `analyze` overloads that exist only when dependency modules import throw
/// this instead of inventing an Apple error domain.
enum ImageAnalyzerHostError: Error, Equatable, Sendable {
    case unsupported
}

/// Live Text / Visual Look Up analyzer. Linux has no Apple analysis service,
/// so `isSupported` is false and every `analyze` path that compiles throws.
public final class ImageAnalyzer: @unchecked Sendable {
    public init() {}

    public static var isSupported: Bool { false }

    public static var supportedTextRecognitionLanguages: [String] { [] }

    public struct AnalysisTypes: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let text = AnalysisTypes(rawValue: 1 << 0)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let visualLookUp = AnalysisTypes(rawValue: 1 << 1)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let machineReadableCode = AnalysisTypes(rawValue: 1 << 2)
    }

    public struct Configuration: Sendable {
        public let analysisTypes: AnalysisTypes
        public var locales: [String]

        public init(_ types: AnalysisTypes) {
            self.analysisTypes = types
            self.locales = []
        }
    }

    private func refuseAnalysis() throws -> ImageAnalysis {
        throw ImageAnalyzerHostError.unsupported
    }

#if canImport(ImageIO) || canImport(CoreGraphics)
    public func analyze(
        imageAt url: URL,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = url
        _ = orientation
        _ = configuration
        return try refuseAnalysis()
    }
#endif

#if canImport(CoreGraphics)
    public func analyze(
        _ cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = cgImage
        _ = orientation
        _ = configuration
        return try refuseAnalysis()
    }
#endif

#if canImport(CoreVideo) && (canImport(ImageIO) || canImport(CoreGraphics))
    public func analyze(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = pixelBuffer
        _ = orientation
        _ = configuration
        return try refuseAnalysis()
    }
#endif

#if canImport(CoreImage) && (canImport(ImageIO) || canImport(CoreGraphics))
    public func analyze(
        _ ciImage: CIImage,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = ciImage
        _ = orientation
        _ = configuration
        return try refuseAnalysis()
    }
#endif

#if canImport(UIKit)
    public func analyze(
        _ image: UIImage,
        orientation: UIImage.Orientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = image
        _ = orientation
        _ = configuration
        return try refuseAnalysis()
    }

    public func analyze(
        _ image: UIImage,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = image
        _ = configuration
        return try refuseAnalysis()
    }
#endif
}

/// Result of a successful `ImageAnalyzer.analyze`. Apple does not publish a
/// public initializer; Linux tests build fixtures only through
/// `@_spi(OpenUIKitHost)`.
public final class ImageAnalysis: @unchecked Sendable {
    private let storedTranscript: String
    private let storedTypes: ImageAnalyzer.AnalysisTypes

    fileprivate init(transcript: String, resultTypes: ImageAnalyzer.AnalysisTypes) {
        self.storedTranscript = transcript
        self.storedTypes = resultTypes
    }

    public var transcript: String { storedTranscript }

    public func hasResults(for analysisTypes: ImageAnalyzer.AnalysisTypes) -> Bool {
        !storedTypes.intersection(analysisTypes).isEmpty
    }
}

extension ImageAnalysis {
    /// Test-only analysis object. Not Apple's public constructor.
    @_spi(OpenUIKitHost)
    public static func hostFixture(
        transcript: String,
        resultTypes: ImageAnalyzer.AnalysisTypes
    ) -> ImageAnalysis {
        ImageAnalysis(transcript: transcript, resultTypes: resultTypes)
    }
}
