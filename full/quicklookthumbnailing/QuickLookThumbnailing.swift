@_exported import Foundation
import Dispatch

#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Apple's public QuickLookThumbnailing error domain. The string value matches
/// the `NS_ERROR_ENUM` constant name and the pinned `dotnet/macios`
/// `[ErrorDomain ("QLThumbnailErrorDomain")]` annotation.
public let QLThumbnailErrorDomain = "QLThumbnailErrorDomain"

/// Bridged QuickLook thumbnail error.
///
/// The pinned API digester records a stored `_nsError: NSError` and
/// `init(_nsError:)`. Linux Foundation exposes
/// `Foundation._BridgedStoredNSError` and `Foundation._ErrorCodeProtocol`;
/// this overlay conforms to those protocols instead of a lookalike
/// `CustomNSError` wrapper. `Code` uses `QLThumbnailError` as `_ErrorType`.
///
/// Foundation's protocol-default `hash(into:)` / `hashValue` witnesses trap
/// (`__HALT`) on this toolchain, so those two Hashable members are provided
/// here. Typed `NSError as? QLThumbnailError` round-trips are not claimed:
/// Linux Foundation special-cases Cocoa/POSIX/URL errors and does not wrap
/// arbitrary domains.
@frozen
public struct QLThumbnailError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = QLThumbnailError

        case generationFailed = 0
        case savingToURLFailed = 1
        case noCachedThumbnail = 2
        case noCloudThumbnail = 3
        case requestInvalid = 4
        case requestCancelled = 5
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { QLThumbnailErrorDomain }

    public static var generationFailed: Code { .generationFailed }
    public static var savingToURLFailed: Code { .savingToURLFailed }
    public static var noCachedThumbnail: Code { .noCachedThumbnail }
    public static var noCloudThumbnail: Code { .noCloudThumbnail }
    public static var requestInvalid: Code { .requestInvalid }
    public static var requestCancelled: Code { .requestCancelled }

    /// Foundation's `_BridgedStoredNSError` hash witnesses trap on Linux.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

/// Linux has no Quick Look thumbnail service, icon cache, or iCloud thumbnail
/// pipeline. Generation APIs therefore fail closed and never write image bytes.
///
/// **Cancellation (iOS 26.1):** `cancel(_:)` before any generation does not
/// poison the request. Cancellation is generator-owned active-operation state,
/// not a flag on `Request`. Pre-cancel is a no-op. Cancel affects only
/// operations this generator currently holds for that request instance (`===`).
/// Terminal callback delivery removes the operation, so request reuse and
/// allocator address reuse cannot inherit cancellation.
///
/// **Completion APIs (iOS 26.1):** `generateBestRepresentation(for:completion:)`,
/// `generateRepresentations(for:update:)`, and
/// `saveBestRepresentation(for:to:contentType:completion:)` return before their
/// callbacks run (`callback_after_return=true`). This port delivers those
/// callbacks asynchronously, exactly once, on `callbackQueue`. That queue is
/// the documented stable Linux delivery target; Apple's queue identity is
/// unconfirmed. `QLThumbnailProvider.provideThumbnail(for:_:)` is a different
/// API and was not in the measured generator set; it stays synchronous here.
#if canImport(ObjectiveC)
@objc(QLThumbnailGenerationRequest)
#endif
open class QLThumbnailGenerationRequest: NSObject, NSCopying, NSSecureCoding {
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

    /// Linux overlay keyed-archive identifiers. Apple's archive keys are
    /// not in the pinned public inputs and remain an oracle question.
    fileprivate enum ArchiveKey {
        static let version = "QLThumbnailGenerator.Request.version"
        static let fileURL = "QLThumbnailGenerator.Request.fileURL"
        static let width = "QLThumbnailGenerator.Request.size.width"
        static let height = "QLThumbnailGenerator.Request.size.height"
        static let scale = "QLThumbnailGenerator.Request.scale"
        static let representationTypes = "QLThumbnailGenerator.Request.representationTypes"
        static let iconMode = "QLThumbnailGenerator.Request.iconMode"
        static let minimumDimension = "QLThumbnailGenerator.Request.minimumDimension"
    }

    fileprivate static let archiveVersion: Int32 = 1

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

#if canImport(UniformTypeIdentifiers)
    /// Seeded `contentType` surface. Isolated Linux hosts do not stage
    /// UniformTypeIdentifiers, so this member is omitted from that dylib.
    open var contentType: UTType!
#endif

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

    /// Bounded keyed archive of the overlay request state: file URL, size,
    /// scale, representation flags, iconMode, and minimumDimension.
    /// `contentType` is owned by UniformTypeIdentifiers and is not part of
    /// this archive; when that member exists it is restored as `nil`.
    public required init?(coder: NSCoder) {
        guard coder.containsValue(forKey: ArchiveKey.version) else { return nil }
        let version = coder.decodeInt32(forKey: ArchiveKey.version)
        guard version == Self.archiveVersion else { return nil }
        guard coder.containsValue(forKey: ArchiveKey.fileURL),
              let fileURL = coder.decodeObject(of: NSURL.self, forKey: ArchiveKey.fileURL) as URL?
        else { return nil }
        guard fileURL.isFileURL else { return nil }
        guard coder.containsValue(forKey: ArchiveKey.width),
              coder.containsValue(forKey: ArchiveKey.height),
              coder.containsValue(forKey: ArchiveKey.scale),
              coder.containsValue(forKey: ArchiveKey.representationTypes),
              coder.containsValue(forKey: ArchiveKey.iconMode),
              coder.containsValue(forKey: ArchiveKey.minimumDimension)
        else { return nil }
        let width = coder.decodeDouble(forKey: ArchiveKey.width)
        let height = coder.decodeDouble(forKey: ArchiveKey.height)
        let scale = coder.decodeDouble(forKey: ArchiveKey.scale)
        let minimumDimension = coder.decodeDouble(forKey: ArchiveKey.minimumDimension)
        guard width.isFinite, height.isFinite, scale.isFinite, minimumDimension.isFinite else {
            return nil
        }
        let typesRaw = UInt(truncatingIfNeeded: UInt64(bitPattern: coder.decodeInt64(forKey: ArchiveKey.representationTypes)))
        self.fileURL = fileURL
        self.storedSize = CGSize(width: width, height: height)
        self.storedScale = CGFloat(scale)
        self.storedRepresentationTypes = RepresentationTypes(rawValue: typesRaw)
        self.iconMode = coder.decodeBool(forKey: ArchiveKey.iconMode)
        self.minimumDimension = CGFloat(minimumDimension)
#if canImport(UniformTypeIdentifiers)
        self.contentType = nil
#endif
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(Self.archiveVersion, forKey: ArchiveKey.version)
        coder.encode(fileURL as NSURL, forKey: ArchiveKey.fileURL)
        coder.encode(Double(storedSize.width), forKey: ArchiveKey.width)
        coder.encode(Double(storedSize.height), forKey: ArchiveKey.height)
        coder.encode(Double(storedScale), forKey: ArchiveKey.scale)
        coder.encode(Int64(bitPattern: UInt64(storedRepresentationTypes.rawValue)), forKey: ArchiveKey.representationTypes)
        coder.encode(iconMode, forKey: ArchiveKey.iconMode)
        coder.encode(Double(minimumDimension), forKey: ArchiveKey.minimumDimension)
    }

    public static var supportsSecureCoding: Bool { true }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copied = QLThumbnailGenerationRequest(
            fileAt: fileURL,
            size: storedSize,
            scale: storedScale,
            representationTypes: storedRepresentationTypes
        )
        copied.iconMode = iconMode
        copied.minimumDimension = minimumDimension
#if canImport(UniformTypeIdentifiers)
        copied.contentType = contentType
#endif
        return copied
    }

    open override var description: String {
        "QLThumbnailGenerator.Request(fileURL: \(fileURL), size: \(storedSize), scale: \(storedScale), representationTypes: \(storedRepresentationTypes), iconMode: \(iconMode), minimumDimension: \(minimumDimension))"
    }
}

open class QLThumbnailGenerator: NSObject {
    public typealias Request = QLThumbnailGenerationRequest

    /// Serial queue used by this Linux port for completion and update
    /// delivery. Apple's callback queue is an open oracle question; do not
    /// treat this label as an Apple identity. SPI so focused tests can
    /// suspend delivery without adding graph-absent public API.
    @_spi(LinuxPort) public let callbackQueue = DispatchQueue(
        label: "com.apple.quicklookthumbnailing.QLThumbnailGenerator.callback"
    )

    private let stateLock = NSLock()
    private var nextOperationID: UInt64 = 0
    private var operations: [UInt64: ActiveOperation] = [:]

    private final class ActiveOperation {
        let id: UInt64
        let request: Request
        var cancelled = false
        let kind: Kind

        enum Kind {
            case best((QLThumbnailRepresentation?, (any Error)?) -> Void)
            case representations(
                (QLThumbnailRepresentation?, QLThumbnailRepresentation.RepresentationType, (any Error)?) -> Void
            )
            case save(((any Error)?) -> Void)
        }

        init(id: UInt64, request: Request, kind: Kind) {
            self.id = id
            self.request = request
            self.kind = kind
        }
    }


    private static let sharedGenerator = QLThumbnailGenerator()

    open class var shared: QLThumbnailGenerator { sharedGenerator }

    public override init() {
        super.init()
    }

    /// Cancels in-flight operations this generator owns for `request`.
    /// If this generator has no active operation for `request`, this is a
    /// no-op: the request is not poisoned and a later generate/save on this
    /// or another generator can proceed (and still fail closed with
    /// `generationFailed` on Linux).
    open func cancel(_ request: Request) {
        stateLock.lock()
        defer { stateLock.unlock() }
        for operation in operations.values where operation.request === request {
            operation.cancelled = true
        }
    }

    /// Completion-based API. Returns before `completionHandler` runs.
    /// Delivers exactly once on `callbackQueue`.
    open func generateBestRepresentation(
        for request: Request,
        completion completionHandler: @escaping (QLThumbnailRepresentation?, (any Error)?) -> Void
    ) {
        let operation = register(request, kind: .best(completionHandler))
        enqueueDelivery(operation)
    }

    open func generateBestRepresentation(
        for request: Request
    ) async throws -> QLThumbnailRepresentation {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QLThumbnailRepresentation, any Error>) in
                self.generateBestRepresentation(for: request) { representation, error in
                    if let representation {
                        continuation.resume(returning: representation)
                    } else {
                        continuation.resume(throwing: error ?? QLThumbnailError(.generationFailed))
                    }
                }
            }
        } onCancel: {
            self.cancel(request)
        }
    }

    /// Completion-based API. Returns before `updateHandler` runs. A `nil`
    /// handler is a no-op and does not register an operation. Delivers
    /// exactly once on `callbackQueue` when a handler is provided.
    open func generateRepresentations(
        for request: Request,
        update updateHandler: (
            (QLThumbnailRepresentation?, QLThumbnailRepresentation.RepresentationType, (any Error)?) -> Void
        )? = nil
    ) {
        guard let updateHandler else { return }
        let operation = register(request, kind: .representations(updateHandler))
        enqueueDelivery(operation)
    }

    /// Completion-based API. Returns before `completionHandler` runs. Never
    /// writes `fileURL`. Linux fail-closed result is `generationFailed`
    /// unless this generator cancelled the matching in-flight operation.
    open func saveBestRepresentation(
        for request: Request,
        to fileURL: URL,
        contentType: String,
        completion completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = (fileURL, contentType)
        let operation = register(request, kind: .save(completionHandler))
        enqueueDelivery(operation)
    }

    open func saveBestRepresentation(
        for request: Request,
        to fileURL: URL,
        contentType: String
    ) async throws {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                self.saveBestRepresentation(
                    for: request,
                    to: fileURL,
                    contentType: contentType
                ) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } onCancel: {
            self.cancel(request)
        }
    }

#if canImport(UniformTypeIdentifiers)
    /// Seeded `saveBestRepresentation(for:to:as:)` surface. Isolated Linux
    /// hosts do not stage UniformTypeIdentifiers, so this member is omitted
    /// from that dylib. When present it still never writes the file.
    open func saveBestRepresentation(
        for request: Request,
        to fileURL: URL,
        as contentType: UTType,
        completion completionHandler: @escaping ((any Error)?) -> Void
    ) {
        saveBestRepresentation(
            for: request,
            to: fileURL,
            contentType: contentType.identifier,
            completion: completionHandler
        )
    }

    open func saveBestRepresentation(
        for request: Request,
        to fileURL: URL,
        as contentType: UTType
    ) async throws {
        try await saveBestRepresentation(
            for: request,
            to: fileURL,
            contentType: contentType.identifier
        )
    }
#endif

    private func register(_ request: Request, kind: ActiveOperation.Kind) -> ActiveOperation {
        stateLock.lock()
        defer { stateLock.unlock() }
        nextOperationID += 1
        let operation = ActiveOperation(id: nextOperationID, request: request, kind: kind)
        operations[operation.id] = operation
        return operation
    }

    private func enqueueDelivery(_ operation: ActiveOperation) {
        callbackQueue.async {
            self.deliver(operation)
        }
    }

    private func deliver(_ operation: ActiveOperation) {
        stateLock.lock()
        guard operations.removeValue(forKey: operation.id) != nil else {
            stateLock.unlock()
            return
        }
        let cancelled = operation.cancelled
        let request = operation.request
        stateLock.unlock()

        let error: any Error = QLThumbnailError(cancelled ? .requestCancelled : .generationFailed)
        switch operation.kind {
        case .best(let handler):
            handler(nil, error)
        case .representations(let handler):
            handler(nil, Self.mostRepresentativeType(in: request.representationTypes), error)
        case .save(let handler):
            handler(error)
        }
    }

    private static func mostRepresentativeType(
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

// No other type in this module conforms to NSCoding / NSSecureCoding.

/// Thumbnail extension provider. Linux has no Quick Look extension host, so
/// the default implementation reports `generationFailed` and never draws.
///
/// The iOS 26.1 `callback_after_return=true` observation was measured on
/// `QLThumbnailGenerator` completion APIs, not on this provider method. This
/// overlay does not claim unmeasured Apple provider timing and keeps the
/// handler synchronous.
open class QLThumbnailProvider: NSObject {
    open func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, (any Error)?) -> Void
    ) {
        _ = request
        handler(nil, QLThumbnailError(.generationFailed))
    }
}

/// Request object the system would pass into a thumbnail extension. iOS
/// typechecking accepts the inherited `init()` and rejects a public
/// `init(fileURL:maximumSize:minimumSize:scale:)`. Properties that an
/// extension host would populate are fail-closed placeholders until a host
/// exists. Tests that need populated URLs use the internal SPI fixture
/// below; that initializer is not public API.
open class QLFileThumbnailRequest: NSObject {
    open private(set) var fileURL: URL
    open private(set) var maximumSize: CGSize
    open private(set) var minimumSize: CGSize
    open private(set) var scale: CGFloat

    public override init() {
        self.fileURL = URL(fileURLWithPath: "")
        self.maximumSize = .zero
        self.minimumSize = .zero
        self.scale = 0
        super.init()
    }

    /// Internal/SPI fixture for tests and provider probes. Not public; iOS
    /// rejects this as a public convenience initializer.
    init(fileURL: URL, maximumSize: CGSize, minimumSize: CGSize, scale: CGFloat) {
        self.fileURL = fileURL
        self.maximumSize = maximumSize
        self.minimumSize = minimumSize
        self.scale = scale
        super.init()
    }
}

/// Reply a thumbnail extension would return. Drawing blocks that require a
/// `CGContext` are compiled only when CoreGraphics can be imported; they
/// store the block and never invoke it. Current-context and file-URL replies
/// are stored and never rasterized on Linux.
open class QLThumbnailReply: NSObject {
    open var extensionBadge: String
    private let imageFileURL: URL?
    private let contextSize: CGSize
    private let currentContextDrawingBlock: (() -> Bool)?
#if canImport(CoreGraphics)
    private let cgContextDrawingBlock: ((CGContext) -> Bool)?
#endif

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
#if canImport(CoreGraphics)
        self.cgContextDrawingBlock = nil
#endif
        super.init()
    }

#if canImport(CoreGraphics)
    private init(
        imageFileURL: URL?,
        contextSize: CGSize,
        currentContextDrawingBlock: (() -> Bool)?,
        extensionBadge: String,
        cgContextDrawingBlock: ((CGContext) -> Bool)?
    ) {
        self.imageFileURL = imageFileURL
        self.contextSize = contextSize
        self.currentContextDrawingBlock = currentContextDrawingBlock
        self.extensionBadge = extensionBadge
        self.cgContextDrawingBlock = cgContextDrawingBlock
        super.init()
    }
#endif

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

#if canImport(CoreGraphics)
    public convenience init(
        contextSize: CGSize,
        drawing drawingBlock: @escaping (CGContext) -> Bool
    ) {
        self.init(
            imageFileURL: nil,
            contextSize: contextSize,
            currentContextDrawingBlock: nil,
            extensionBadge: "",
            cgContextDrawingBlock: drawingBlock
        )
    }

    public convenience init(
        contextSize: CGSize,
        drawingBlock: @escaping (CGContext) -> Bool
    ) {
        self.init(contextSize: contextSize, drawing: drawingBlock)
    }
#endif

    open override var description: String {
        "QLThumbnailReply(imageFileURL: \(String(describing: imageFileURL)), contextSize: \(contextSize), hasCurrentContextDrawingBlock: \(currentContextDrawingBlock != nil), extensionBadge: \(extensionBadge))"
    }
}

/// A generated thumbnail representation. Public `init()` is accepted on iOS
/// 26.1; the oracle observed `type == .icon` and `contentRect == .zero` for
/// that initializer. `cgImage` / `uiImage` remain unstaged: this overlay will
/// not fabricate pixel buffers.
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

    public override init() {
        self.storedType = .icon
        self.storedContentRect = .zero
        super.init()
    }

#if canImport(CoreGraphics)
    /// Seeded `cgImage` surface. Isolated Linux hosts do not stage
    /// CoreGraphics as a module, so this member is omitted from that dylib.
    /// When CoreGraphics is present this port still has no thumbnail pixels
    /// to return; callers must not treat a missing image as success.
    open var cgImage: CGImage {
        preconditionFailure("QLThumbnailRepresentation.cgImage is unavailable on this Linux port; no thumbnail backend is staged")
    }
#endif

#if canImport(UIKit)
    /// Seeded `uiImage` surface. Isolated Linux hosts do not stage UIKit, so
    /// this member is omitted from that dylib. When UIKit is present this
    /// port still has no thumbnail pixels to return.
    open var uiImage: UIImage {
        preconditionFailure("QLThumbnailRepresentation.uiImage is unavailable on this Linux port; no thumbnail backend is staged")
    }
#endif
}
