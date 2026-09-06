import Foundation

/// Metal cinematic renderer. Encode APIs return `false` because Linux has no
/// Apple cinematic shaders. Pixel-format lists are empty for the same reason.
public class CNRenderingSession: @unchecked Sendable {
    public struct Attributes: Sendable {
        public let renderingVersion: Int

        public init(asset: AVAsset) async throws {
            throw CNCinematicError(.unsupported)
        }

        /// Isolated-host attributes. Apple only exposes `init(asset:)`.
        public static func host_make(renderingVersion: Int) -> Attributes {
            Attributes(renderingVersion: renderingVersion)
        }

        init(renderingVersion: Int) {
            self.renderingVersion = renderingVersion
        }
    }

    public struct FrameAttributes: Sendable {
        public var focusDisparity: Float
        public var fNumber: Float

        public init?(
            sampleBuffer: CMSampleBuffer,
            sessionAttributes: Attributes
        ) {
            _ = sampleBuffer
            _ = sessionAttributes
            return nil
        }

        public init?(
            timedMetadataGroup metadataGroup: AVTimedMetadataGroup,
            sessionAttributes: Attributes
        ) {
            _ = metadataGroup
            _ = sessionAttributes
            return nil
        }

        /// Isolated-host frame attributes. Apple constructs these from
        /// cinematic sample metadata.
        public static func host_make(focusDisparity: Float, fNumber: Float) -> FrameAttributes {
            FrameAttributes(focusDisparity: focusDisparity, fNumber: fNumber)
        }

        init(focusDisparity: Float, fNumber: Float) {
            self.focusDisparity = focusDisparity
            self.fNumber = fNumber
        }
    }

    public let commandQueue: any MTLCommandQueue
    public let sessionAttributes: Attributes
    public let preferredTransform: CGAffineTransform
    public let quality: CNRenderingQuality

    public init(
        commandQueue: any MTLCommandQueue,
        sessionAttributes: Attributes,
        preferredTransform: CGAffineTransform,
        quality: CNRenderingQuality
    ) {
        self.commandQueue = commandQueue
        self.sessionAttributes = sessionAttributes
        self.preferredTransform = preferredTransform
        self.quality = quality
    }

    public static var sourcePixelFormatTypes: [OSType] { [] }
    public static var destinationPixelFormatTypes: [OSType] { [] }

    public func encodeRender(
        to commandBuffer: any MTLCommandBuffer,
        frameAttributes: FrameAttributes,
        sourceImage: CVPixelBuffer,
        sourceDisparity: CVPixelBuffer,
        destinationImage: CVPixelBuffer
    ) -> Bool {
        _ = commandBuffer
        _ = frameAttributes
        _ = sourceImage
        _ = sourceDisparity
        _ = destinationImage
        return false
    }

    public func encodeRender(
        to commandBuffer: any MTLCommandBuffer,
        frameAttributes: FrameAttributes,
        sourceImage: CVPixelBuffer,
        sourceDisparity: CVPixelBuffer,
        destinationRGBA: any MTLTexture
    ) -> Bool {
        _ = commandBuffer
        _ = frameAttributes
        _ = sourceImage
        _ = sourceDisparity
        _ = destinationRGBA
        return false
    }

    public func encodeRender(
        to commandBuffer: any MTLCommandBuffer,
        frameAttributes: FrameAttributes,
        sourceImage: CVPixelBuffer,
        sourceDisparity: CVPixelBuffer,
        destinationLuma: any MTLTexture,
        destinationChroma: any MTLTexture
    ) -> Bool {
        _ = commandBuffer
        _ = frameAttributes
        _ = sourceImage
        _ = sourceDisparity
        _ = destinationLuma
        _ = destinationChroma
        return false
    }
}
