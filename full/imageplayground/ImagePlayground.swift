@_exported import Foundation

/// Linux starting point for Apple's public `ImagePlayground` module.
///
/// Image generation is an Apple-device, Apple-model service. This module
/// reconstructs the public value types, error surface, and view-controller
/// configuration API from the pinned Xcode 26.1 symbol graphs, then fail-closes
/// every path that would require those models or a system Image Playground UI.

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
    /// A generated image. Apple's type stores a `CGImage`; this starting
    /// point cannot produce one without CoreGraphics and a generative
    /// backend, and it has no public initializer.
    public struct CreatedImage: Sendable {
        init() {}
    }

    /// Errors that can occur during image generation.
    public enum Error: Swift.Error, LocalizedError, CustomNSError, Hashable, CaseIterable, Sendable {
        /// The device does not support image generation.
        case notSupported
        /// Image creation is currently unavailable.
        case unavailable
        /// The parent task was cancelled.
        case creationCancelled
        /// A source image contained a face that is too small to use.
        case faceInImageTooSmall
        /// The input text uses an unsupported language.
        case unsupportedLanguage
        /// A specified source image cannot be used.
        case unsupportedInputImage
        /// Image creation was requested while the app is hidden or in the background.
        case backgroundCreationForbidden
        /// A general failure occurred during image creation.
        case creationFailed
        /// A source image containing a person's face is required to complete the request.
        case conceptsRequirePersonIdentity

        public static let errorDomain = "ImagePlayground.ImageCreator.Error"

        public var errorCode: Int {
            switch self {
            case .notSupported: return 0
            case .unavailable: return 1
            case .creationCancelled: return 2
            case .faceInImageTooSmall: return 3
            case .unsupportedLanguage: return 4
            case .unsupportedInputImage: return 5
            case .backgroundCreationForbidden: return 6
            case .creationFailed: return 7
            case .conceptsRequirePersonIdentity: return 8
            }
        }

        public var errorUserInfo: [String: Any] { [:] }

        public var errorDescription: String? {
            switch self {
            case .notSupported:
                return "The device does not support image generation."
            case .unavailable:
                return "Image creation is currently unavailable."
            case .creationCancelled:
                return "Image creation was cancelled."
            case .faceInImageTooSmall:
                return "The face in a source image is too small to use."
            case .unsupportedLanguage:
                return "The input text uses an unsupported language."
            case .unsupportedInputImage:
                return "A specified source image cannot be used."
            case .backgroundCreationForbidden:
                return "Image creation is forbidden while the app is in the background."
            case .creationFailed:
                return "Image creation failed."
            case .conceptsRequirePersonIdentity:
                return "A source image containing a person's face is required."
            }
        }

        public var failureReason: String? { errorDescription }

        public var recoverySuggestion: String? {
            switch self {
            case .notSupported:
                return "Use a device that supports Image Playground."
            case .unavailable:
                return "Retry after the on-device models have finished downloading."
            case .creationCancelled:
                return "Submit a new image-creation request."
            case .faceInImageTooSmall, .unsupportedInputImage:
                return "Provide a different source image."
            case .unsupportedLanguage:
                return "Retry with text in a supported language."
            case .backgroundCreationForbidden:
                return "Return the app to the foreground and retry."
            case .creationFailed:
                return "Retry the request."
            case .conceptsRequirePersonIdentity:
                return "Add a source image that includes a person's face."
            }
        }

        public var helpAnchor: String? { nil }
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
