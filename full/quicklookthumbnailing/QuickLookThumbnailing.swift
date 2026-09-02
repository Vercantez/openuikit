@_exported import Foundation

/// Apple's public QuickLookThumbnailing error domain. The string value matches
/// the `NS_ERROR_ENUM` constant name and the pinned `dotnet/macios`
/// `[ErrorDomain ("QLThumbnailErrorDomain")]` annotation. Independent logs of
/// the Apple runtime also print `Error Domain=QLThumbnailErrorDomain`.
public let QLThumbnailErrorDomain = "QLThumbnailErrorDomain"

/// Portable counterpart of QuickLookThumbnailing's bridged `NS_ERROR_ENUM`.
///
/// Numeric codes follow the public header / API-digester child order and the
/// pinned macios enum: `generationFailed = 0` through `requestCancelled = 5`.
/// Caller-supplied `userInfo` is stored exactly; this overlay does not insert a
/// default localized-description entry.
public struct QLThumbnailError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case generationFailed = 0
        case savingToURLFailed = 1
        case noCachedThumbnail = 2
        case noCloudThumbnail = 3
        case requestInvalid = 4
        case requestCancelled = 5
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { QLThumbnailErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var generationFailed: Code { .generationFailed }
    public static var savingToURLFailed: Code { .savingToURLFailed }
    public static var noCachedThumbnail: Code { .noCachedThumbnail }
    public static var noCloudThumbnail: Code { .noCloudThumbnail }
    public static var requestInvalid: Code { .requestInvalid }
    public static var requestCancelled: Code { .requestCancelled }

    public static func == (lhs: QLThumbnailError, rhs: QLThumbnailError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension QLThumbnailError.Code {
    public static func ~= (match: QLThumbnailError.Code, error: any Error) -> Bool {
        (error as? QLThumbnailError)?.code == match
    }
}

/// Linux has no Quick Look thumbnail service, icon cache, or iCloud thumbnail
/// pipeline. Generation APIs therefore fail closed and never write image bytes.
open class QLThumbnailGenerator: NSObject {
    open class Request: NSObject, NSCopying, NSSecureCoding {
        public struct RepresentationTypes: OptionSet, Hashable, Sendable {
            public let rawValue: UInt

            public init(rawValue: UInt) {
                self.rawValue = rawValue
            }

            public static let icon = RepresentationTypes(rawValue: 1 << 0)
            public static let lowQualityThumbnail = RepresentationTypes(rawValue: 1 << 1)
            public static let thumbnail = RepresentationTypes(rawValue: 1 << 2)
            public static let all = RepresentationTypes(rawValue: UInt.max)
        }

        private let fileURL: URL
        private let storedSize: CGSize
        private let storedScale: CGFloat
        private let storedRepresentationTypes: RepresentationTypes

        /// Unconfirmed against Apple's runtime default; stored as `false` until
        /// an Apple-oracle observation lands.
        open var iconMode: Bool

        /// Unconfirmed against Apple's runtime default; stored as `0` until an
        /// Apple-oracle observation lands.
        open var minimumDimension: CGFloat

        open var size: CGSize { storedSize }
        open var scale: CGFloat { storedScale }
        open var representationTypes: RepresentationTypes { storedRepresentationTypes }

        public init(
            fileAt url: URL,
            size: CGSize,
            scale: CGFloat,
            representationTypes: RepresentationTypes
        ) {
            self.fileURL = url
            self.storedSize = size
            self.storedScale = scale
            self.storedRepresentationTypes = representationTypes
            self.iconMode = false
            self.minimumDimension = 0
            super.init()
        }

        public convenience init(
            fileAtURL url: URL,
            size: CGSize,
            scale: CGFloat,
            representationTypes: RepresentationTypes
        ) {
            self.init(
                fileAt: url,
                size: size,
                scale: scale,
                representationTypes: representationTypes
            )
        }

        /// Secure-coding layout is not recorded in the pinned public inputs.
        /// Decoding therefore fails closed instead of inventing an archive.
        public required init?(coder: NSCoder) {
            return nil
        }

        public func encode(with coder: NSCoder) {
            _ = coder
        }

        public static var supportsSecureCoding: Bool { true }

        public func copy(with zone: NSZone? = nil) -> Any {
            _ = zone
            let copied = Request(
                fileAt: fileURL,
                size: storedSize,
                scale: storedScale,
                representationTypes: storedRepresentationTypes
            )
            copied.iconMode = iconMode
            copied.minimumDimension = minimumDimension
            return copied
        }

        open override var description: String {
            "QLThumbnailGenerator.Request(fileURL: \(fileURL), size: \(storedSize), scale: \(storedScale), representationTypes: \(storedRepresentationTypes), iconMode: \(iconMode), minimumDimension: \(minimumDimension))"
        }
    }

    private static let sharedGenerator = QLThumbnailGenerator()
    private let stateLock = NSLock()
    private var cancelledRequestIDs = Set<ObjectIdentifier>()

    open class var shared: QLThumbnailGenerator { sharedGenerator }

    public override init() {
        super.init()
    }

    open func cancel(_ request: Request) {
        stateLock.lock()
        cancelledRequestIDs.insert(ObjectIdentifier(request))
        stateLock.unlock()
    }

    open func generateBestRepresentation(
        for request: Request
    ) async throws -> QLThumbnailRepresentation {
        throw failure(for: request)
    }

    open func generateBestRepresentation(
        for request: Request,
        completion completionHandler: @escaping (QLThumbnailRepresentation?, (any Error)?) -> Void
    ) {
        completionHandler(nil, failure(for: request))
    }

    open func generateRepresentations(
        for request: Request,
        update updateHandler: (
            (QLThumbnailRepresentation?, QLThumbnailRepresentation.RepresentationType, (any Error)?) -> Void
        )? = nil
    ) {
        guard let updateHandler else { return }
        updateHandler(nil, mostRepresentativeType(in: request.representationTypes), failure(for: request))
    }

    open func saveBestRepresentation(
        for request: Request,
        to fileURL: URL,
        contentType: String
    ) async throws {
        _ = (fileURL, contentType)
        throw failure(for: request)
    }

    open func saveBestRepresentation(
        for request: Request,
        to fileURL: URL,
        contentType: String,
        completion completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (fileURL, contentType)
        completionHandler(failure(for: request))
    }

    private func failure(for request: Request) -> QLThumbnailError {
        stateLock.lock()
        let cancelled = cancelledRequestIDs.contains(ObjectIdentifier(request))
        stateLock.unlock()
        if cancelled {
            return QLThumbnailError(.requestCancelled)
        }
        return QLThumbnailError(.generationFailed)
    }

    private func mostRepresentativeType(
        in types: Request.RepresentationTypes
    ) -> QLThumbnailRepresentation.RepresentationType {
        if types.contains(.thumbnail) {
            return .thumbnail
        }
        if types.contains(.lowQualityThumbnail) {
            return .lowQualityThumbnail
        }
        return .icon
    }
}

/// Thumbnail extension provider. Linux has no Quick Look extension host, so
/// the default implementation reports `generationFailed` and never draws.
open class QLThumbnailProvider: NSObject {
    open func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, (any Error)?) -> Void
    ) {
        _ = request
        handler(nil, QLThumbnailError(.generationFailed))
    }
}

/// Request object the system would pass into a thumbnail extension. Apple does
/// not publish a constructor; Linux exposes a designated initializer so hosts
/// and tests can supply the documented stored properties.
open class QLFileThumbnailRequest: NSObject {
    open private(set) var fileURL: URL
    open private(set) var maximumSize: CGSize
    open private(set) var minimumSize: CGSize
    open private(set) var scale: CGFloat

    public init(fileURL: URL, maximumSize: CGSize, minimumSize: CGSize, scale: CGFloat) {
        self.fileURL = fileURL
        self.maximumSize = maximumSize
        self.minimumSize = minimumSize
        self.scale = scale
        super.init()
    }
}

/// Reply a thumbnail extension would return. Drawing blocks that require a
/// `CGContext` are deferred because CoreGraphics is not available to this
/// isolated module. Current-context and file-URL replies are stored and never
/// rasterized on Linux.
open class QLThumbnailReply: NSObject {
    open var extensionBadge: String
    private let imageFileURL: URL?
    private let contextSize: CGSize
    private let currentContextDrawingBlock: (() -> Bool)?

    private init(
        imageFileURL: URL?,
        contextSize: CGSize,
        currentContextDrawingBlock: (() -> Bool)?,
        extensionBadge: String
    ) {
        self.imageFileURL = imageFileURL
        self.contextSize = contextSize
        self.currentContextDrawingBlock = currentContextDrawingBlock
        self.extensionBadge = extensionBadge
        super.init()
    }

    public convenience init(imageFileURL fileURL: URL) {
        self.init(
            imageFileURL: fileURL,
            contextSize: .zero,
            currentContextDrawingBlock: nil,
            extensionBadge: ""
        )
    }

    public convenience init(
        contextSize: CGSize,
        currentContextDrawing drawingBlock: @escaping () -> Bool
    ) {
        self.init(
            imageFileURL: nil,
            contextSize: contextSize,
            currentContextDrawingBlock: drawingBlock,
            extensionBadge: ""
        )
    }

    public convenience init(
        contextSize: CGSize,
        currentContextDrawingBlock drawingBlock: @escaping () -> Bool
    ) {
        self.init(contextSize: contextSize, currentContextDrawing: drawingBlock)
    }

    open override var description: String {
        "QLThumbnailReply(imageFileURL: \(String(describing: imageFileURL)), contextSize: \(contextSize), hasCurrentContextDrawingBlock: \(currentContextDrawingBlock != nil), extensionBadge: \(extensionBadge))"
    }
}

/// A generated thumbnail representation. Linux never produces one: generation
/// APIs fail closed, and `CGImage` / `UIImage` accessors are deferred because
/// those types are owned by CoreGraphics / UIKit.
open class QLThumbnailRepresentation: NSObject {
    public enum RepresentationType: Int, Hashable, Sendable {
        case icon = 0
        case lowQualityThumbnail = 1
        case thumbnail = 2
    }

    private let storedType: RepresentationType
    private let storedContentRect: CGRect

    open var type: RepresentationType { storedType }
    open var contentRect: CGRect { storedContentRect }

    init(type: RepresentationType, contentRect: CGRect) {
        self.storedType = type
        self.storedContentRect = contentRect
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError("QLThumbnailRepresentation is not constructible without a generated thumbnail")
    }
}
