@_exported import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Linux starting point for Apple's public `ImagePlayground` module.
///
/// Image generation is an Apple-device, Apple-model service. This module
/// reconstructs the public value types and fail-closes every path that would
/// require those models or a system Image Playground UI.
///
/// UIKit, SwiftUI, PencilKit, CoreGraphics, and ImageIO surfaces are compiled
/// only when those modules can be imported. The isolated host gate does not
/// link them; that is not integrated Linux success.

/// Generates images programmatically from concepts and a style.
///
/// Linux has no Image Playground / Apple Intelligence image-generation
/// hardware or models. ``ImageCreator/init()`` therefore always throws
/// ``ImageCreator/Error/notSupported``.
public final class ImageCreator: Sendable {
    /// The styles this creator can apply. Always empty on Linux because
    /// ``init()`` never returns an instance.
    public let availableStyles: [ImagePlaygroundStyle]

    /// Creates a creator. Always throws ``Error/notSupported`` on Linux.
    public init() async throws {
        availableStyles = []
        throw Error.notSupported
    }

    /// Starts image creation. Unreachable after a successful ``init()`` on
    /// Linux; if an instance existed, the returned sequence would throw
    /// ``Error/notSupported`` rather than yield images.
    public func images(
        for concepts: [ImagePlaygroundConcept],
        style: ImagePlaygroundStyle,
        limit: Int
    ) -> some AsyncSequence<CreatedImage, any Swift.Error> {
        _ = (concepts, style, limit)
        return ImagePlaygroundCreationSequence()
    }
}

extension ImageCreator {
    /// A generated image. Apple's public stored property is `cgImage: CGImage`.
    /// That property is compiled only when CoreGraphics can be imported.
    /// There is no public initializer; generation never succeeds here.
    public struct CreatedImage: @unchecked Sendable {
        #if canImport(CoreGraphics)
        public let cgImage: CGImage

        init(cgImage: CGImage) {
            self.cgImage = cgImage
        }

        /// Host-test wrapper. Does not claim Apple generation produced the bitmap.
        @_spi(OpenUIKitHost)
        public init(_hostCGImage image: CGImage) {
            self.init(cgImage: image)
        }
        #else
        private init() {}
        #endif
    }

    /// Errors that can occur during image generation.
    ///
    /// `CustomNSError` / `LocalizedError` use Swift protocol defaults. Apple's
    /// `errorDomain`, numeric `errorCode` values, `errorUserInfo` keys, and
    /// localized copy are not in the pinned public inputs.
    public enum Error: Swift.Error, LocalizedError, CustomNSError, Hashable, CaseIterable, Sendable {
        case notSupported
        case unavailable
        case creationCancelled
        case faceInImageTooSmall
        case unsupportedLanguage
        case unsupportedInputImage
        case backgroundCreationForbidden
        case creationFailed
        case conceptsRequirePersonIdentity
    }
}

struct ImagePlaygroundCreationSequence: AsyncSequence {
    typealias Element = ImageCreator.CreatedImage
    typealias Failure = any Swift.Error

    struct AsyncIterator: AsyncIteratorProtocol {
        typealias Element = ImageCreator.CreatedImage
        typealias Failure = any Swift.Error

        mutating func next() async throws(any Swift.Error) -> ImageCreator.CreatedImage? {
            throw ImageCreator.Error.notSupported
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator()
    }
}
