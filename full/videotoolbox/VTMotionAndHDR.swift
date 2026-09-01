public final class VTMotionEstimationSession: @unchecked Sendable {
    public struct FrameFlags: OptionSet, Hashable, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let currentBufferWillBeNextReferenceBuffer = FrameFlags(rawValue: 1 << 0)
    }

    public enum BlockSize: Int, Hashable, Sendable {
        case blockSize16x16 = 0
        case blockSize4x4 = 1
    }

    public struct Motion: Sendable {
        public var motionVector: CVReadOnlyPixelBuffer
    }

    public let useMultiPassSearch: Bool
    public let sourcePixelBufferAttributes: [String: any Sendable]
    public let label: String?

    private let storedMotionVectorSize: BlockSize

    public var motionVectorSize: BlockSize {
        get throws { storedMotionVectorSize }
    }

    public init(
        width: UInt32,
        height: UInt32,
        motionVectorSize: BlockSize = .blockSize16x16,
        useMultiPassSearch: Bool = false,
        label: String? = nil
    ) throws {
        _ = (width, height, motionVectorSize, useMultiPassSearch, label)
        throw VTFrameProcessorError(.initializationFailed)
    }

    public func motion(
        of currentImage: CVReadOnlyPixelBuffer,
        comparedTo referenceImage: CVReadOnlyPixelBuffer,
        flags: FrameFlags = .init(rawValue: 0)
    ) async throws -> Motion {
        _ = (currentImage, referenceImage, flags)
        throw VTFrameProcessorError(.initializationFailed)
    }
}

public class VTHDRPerFrameMetadataGenerationSession: @unchecked Sendable {
    public enum HDRFormat: Int, Hashable, Sendable {
        case dolbyVision = 1
    }

    public init(
        framesPerSecond: Float,
        hdrFormats: [HDRFormat]? = nil
    ) throws {
        _ = (framesPerSecond, hdrFormats)
        throw VTFrameProcessorError(.initializationFailed)
    }

    public func attachMetadata(to: CVPixelBuffer, sceneChange: Bool = false) throws {
        _ = (to, sceneChange)
        throw VTFrameProcessorError(.initializationFailed)
    }
}
