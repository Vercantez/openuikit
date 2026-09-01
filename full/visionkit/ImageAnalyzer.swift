import Foundation

/// Results of analyzing an image for Live Text.
public final class ImageAnalysis: Sendable {
    private let resultTypes: ImageAnalyzer.AnalysisTypes
    private let storedTranscript: String

    public var transcript: String { storedTranscript }

    public func hasResults(for analysisTypes: ImageAnalyzer.AnalysisTypes) -> Bool {
        !resultTypes.intersection(analysisTypes).isEmpty
    }

    @_spi(OpenUIKitHost)
    public init(
        transcript: String = "",
        resultTypes: ImageAnalyzer.AnalysisTypes = []
    ) {
        self.storedTranscript = transcript
        self.resultTypes = resultTypes
    }
}

/// An on-device image analyzer for text, codes, and visual lookup.
///
/// Linux has no A12-class Neural Engine or Apple Live Text models, so
/// `isSupported` is `false` and every `analyze` overload throws
/// `VisionKitAvailabilityError.imageAnalysisUnsupported`.
public final class ImageAnalyzer: Sendable {
    public struct AnalysisTypes: OptionSet, Hashable, Sendable {
        public typealias ArrayLiteralElement = AnalysisTypes
        public typealias Element = AnalysisTypes
        public typealias RawValue = UInt

        public var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let text = AnalysisTypes(rawValue: 1 << 0)
        public static let machineReadableCode = AnalysisTypes(rawValue: 1 << 1)
        public static let visualLookUp = AnalysisTypes(rawValue: 1 << 2)
    }

    public struct Configuration: Sendable {
        public let analysisTypes: AnalysisTypes
        public var locales: [String]

        public init(_ types: AnalysisTypes) {
            analysisTypes = types
            locales = []
        }
    }

    /// Live Text analysis requires an A12 Bionic chip or later.
    public static var isSupported: Bool { false }

    /// No on-device recognition models are shipped with this Linux port.
    public static var supportedTextRecognitionLanguages: [String] { [] }

    public init() {}

    public func analyze(
        _ image: UIImage,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = image
        _ = configuration
        throw VisionKitAvailabilityError.imageAnalysisUnsupported
    }

    public func analyze(
        _ image: UIImage,
        orientation: UIImage.Orientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = image
        _ = orientation
        _ = configuration
        throw VisionKitAvailabilityError.imageAnalysisUnsupported
    }

    public func analyze(
        imageAt url: URL,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = url
        _ = orientation
        _ = configuration
        throw VisionKitAvailabilityError.imageAnalysisUnsupported
    }

    public func analyze(
        _ cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = cgImage
        _ = orientation
        _ = configuration
        throw VisionKitAvailabilityError.imageAnalysisUnsupported
    }

    public func analyze(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = pixelBuffer
        _ = orientation
        _ = configuration
        throw VisionKitAvailabilityError.imageAnalysisUnsupported
    }

    public func analyze(
        _ ciImage: CIImage,
        orientation: CGImagePropertyOrientation,
        configuration: Configuration
    ) async throws -> ImageAnalysis {
        _ = ciImage
        _ = orientation
        _ = configuration
        throw VisionKitAvailabilityError.imageAnalysisUnsupported
    }
}
