import Foundation

// MARK: - Style

/// A generation style token. The four static members match the canonical graph.
/// `id` strings are Linux-host identity (the static member names). Darwin string
/// payloads and `Codable` layout are unobserved.
public struct ImagePlaygroundStyle: Hashable, Sendable, Identifiable {
    public typealias ID = String

    public let id: String

    public static let animation = ImagePlaygroundStyle(hostID: "animation")
    public static let illustration = ImagePlaygroundStyle(hostID: "illustration")
    public static let sketch = ImagePlaygroundStyle(hostID: "sketch")
    public static let externalProvider = ImagePlaygroundStyle(hostID: "externalProvider")

    /// Linux-host inventory of the four graph statics. Darwin may omit
    /// `externalProvider` depending on device configuration (unobserved).
    public static var all: [ImagePlaygroundStyle] {
        [.animation, .illustration, .sketch, .externalProvider]
    }

    init(hostID: String) {
        self.id = hostID
    }

    public static func == (a: ImagePlaygroundStyle, b: ImagePlaygroundStyle) -> Bool {
        a.id == b.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ImagePlaygroundStyle: Codable {
    /// Linux-host single-value `id` coding. Apple's keyed layout is unobserved.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let token = try container.decode(String.self)
        guard !token.isEmpty else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "ImagePlaygroundStyle id must be nonempty (Linux-host Codable)"
            )
        }
        self.init(hostID: token)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

// MARK: - Personalization policy

/// Personalization policy cases from the canonical graph. Integer raw values are
/// a Linux-host mapping (automatic=0, enabled=1, disabled=2); Darwin values are
/// unobserved.
public enum ImagePlaygroundPersonalizationPolicy: Sendable, Hashable {
    case automatic
    case enabled
    case disabled
}

extension ImagePlaygroundPersonalizationPolicy: RawRepresentable {
    public typealias RawValue = Int

    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .automatic
        case 1: self = .enabled
        case 2: self = .disabled
        default: return nil
        }
    }

    public var rawValue: Int {
        switch self {
        case .automatic: return 0
        case .enabled: return 1
        case .disabled: return 2
        }
    }
}

// MARK: - Concept

/// An opaque generation concept. Public factories record caller input; this
/// module does not run language extraction or decode image bytes.
public struct ImagePlaygroundConcept {
    enum Storage {
        case text(String)
        case extracted(text: String, title: String?)
        case imageURL(URL)
        case boxed(Any)
    }

    var storage: Storage

    public static func text(_ text: String) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .text(text))
    }

    public static func extracted(from text: String, title: String? = nil) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .extracted(text: text, title: title))
    }

    /// Records `url` as an image concept without ImageIO validation.
    /// Darwin nil conditions (unreadable files, unsupported types) are unobserved.
    public static func image(_ url: URL) -> ImagePlaygroundConcept? {
        ImagePlaygroundConcept(storage: .imageURL(url))
    }

    init(storage: Storage) {
        self.storage = storage
    }
}

// MARK: - ImageCreator

/// Programmatic image generation. On this Linux host the public initializer
/// always throws ``ImageCreator/Error/unavailable``; no Apple generative
/// service is contacted and no image bytes are produced.
public final class ImageCreator: Sendable {
    public let availableStyles: [ImagePlaygroundStyle]

    public init() async throws {
        self.availableStyles = []
        throw Error.unavailable
    }

    init(hostAvailableStyles: [ImagePlaygroundStyle]) {
        self.availableStyles = hostAvailableStyles
    }

    public enum Error: Swift.Error, Sendable, Hashable, CaseIterable {
        case unsupportedInputImage
        case faceInImageTooSmall
        case unavailable
        case notSupported
        case creationFailed
        case creationCancelled
        case unsupportedLanguage
        case backgroundCreationForbidden
        case conceptsRequirePersonIdentity
    }
}

extension ImageCreator.Error: CustomNSError, LocalizedError {
    /// Linux-host domain using the Swift `CustomNSError` module.type convention.
    /// Darwin `errorDomain` payload is unobserved.
    public static var errorDomain: String {
        "ImagePlayground.ImageCreator.Error"
    }

    /// Linux-host codes in `allCases` order starting at 0. Darwin codes unobserved.
    public var errorCode: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    public var errorUserInfo: [String: Any] {
        [:]
    }

    public var errorDescription: String? { nil }
    public var failureReason: String? { nil }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}

// MARK: - Host SPI (not Apple surface)

@_spi(OpenUIKitHost)
public enum ImagePlaygroundHostControl {
    public static func makeImageCreator() -> ImageCreator {
        ImageCreator(hostAvailableStyles: ImagePlaygroundStyle.all)
    }

    public static func conceptKind(_ concept: ImagePlaygroundConcept) -> String {
        switch concept.storage {
        case .text: return "text"
        case .extracted: return "extracted"
        case .imageURL: return "imageURL"
        case .boxed: return "boxed"
        }
    }

    public static func conceptText(_ concept: ImagePlaygroundConcept) -> String? {
        switch concept.storage {
        case .text(let text): return text
        case .extracted(let text, _): return text
        case .imageURL, .boxed: return nil
        }
    }

    public static func conceptTitle(_ concept: ImagePlaygroundConcept) -> String? {
        switch concept.storage {
        case .extracted(_, let title): return title
        case .text, .imageURL, .boxed: return nil
        }
    }

    public static func conceptImageURL(_ concept: ImagePlaygroundConcept) -> URL? {
        switch concept.storage {
        case .imageURL(let url): return url
        case .text, .extracted, .boxed: return nil
        }
    }
}
