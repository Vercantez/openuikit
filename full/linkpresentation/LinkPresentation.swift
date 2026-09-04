// Portable LinkPresentation metadata model. Linux has no system link-preview
// service, but applications can create, populate, and pass exact metadata
// objects through UIKit activity-item APIs without source changes.

import Foundation
import FoundationNetworking

/// Apple's `NS_ERROR_ENUM` domain. The string matches the pinned
/// `dotnet/macios` `[ErrorDomain ("LPErrorDomain")]` annotation and the TBD
/// export `_LPErrorDomain`.
public let LPErrorDomain = "LPErrorDomain"

/// Linux overlay keyed-archive identifiers. Apple's NSSecureCoding keys are
/// not in the pinned public inputs and remain an oracle question.
private enum LPPortableArchive {
    static let versionKey = "OpenUIKit.LinkPresentation.archiveVersion"
    static let titleKey = "OpenUIKit.LinkPresentation.title"
    static let urlKey = "OpenUIKit.LinkPresentation.url"
    static let originalURLKey = "OpenUIKit.LinkPresentation.originalURL"
    static let remoteVideoURLKey = "OpenUIKit.LinkPresentation.remoteVideoURL"
    static let version: Int32 = 1
}

/// Bridged LinkPresentation error.
///
/// The pinned API digester records a stored `_nsError: NSError` overlay.
/// Linux Foundation exposes `Foundation._BridgedStoredNSError` and
/// `Foundation._ErrorCodeProtocol`. Foundation's protocol-default
/// `hash(into:)` / `hashValue` witnesses trap (`__HALT`) on this toolchain,
/// so those two Hashable members are provided here.
///
/// `Code` raw values match the pinned macios `[Native]` order starting at
/// `Unknown = 1`.
@frozen
public struct LPError: Foundation._BridgedStoredNSError, @unchecked Sendable {
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = LPError

        case unknown = 1
        case metadataFetchFailed = 2
        case metadataFetchCancelled = 3
        case metadataFetchTimedOut = 4
        case metadataFetchNotAllowed = 5
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { LPErrorDomain }

    public static var unknown: Code { .unknown }
    public static var metadataFetchFailed: Code { .metadataFetchFailed }
    public static var metadataFetchCancelled: Code { .metadataFetchCancelled }
    public static var metadataFetchTimedOut: Code { .metadataFetchTimedOut }
    public static var metadataFetchNotAllowed: Code { .metadataFetchNotAllowed }

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

open class LPLinkMetadata: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    open var title: String?
    open var url: URL?
    open var originalURL: URL?
    open var remoteVideoURL: URL?

    public override init() {
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard coder.containsValue(forKey: LPPortableArchive.versionKey) else {
            return nil
        }
        let version = coder.decodeInt32(forKey: LPPortableArchive.versionKey)
        guard version == LPPortableArchive.version else { return nil }
        title = coder.decodeObject(of: NSString.self, forKey: LPPortableArchive.titleKey) as String?
        url = coder.decodeObject(of: NSURL.self, forKey: LPPortableArchive.urlKey) as URL?
        originalURL = coder.decodeObject(
            of: NSURL.self, forKey: LPPortableArchive.originalURLKey
        ) as URL?
        remoteVideoURL = coder.decodeObject(
            of: NSURL.self, forKey: LPPortableArchive.remoteVideoURLKey
        ) as URL?
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(LPPortableArchive.version, forKey: LPPortableArchive.versionKey)
        coder.encode(title as NSString?, forKey: LPPortableArchive.titleKey)
        coder.encode(url as NSURL?, forKey: LPPortableArchive.urlKey)
        coder.encode(originalURL as NSURL?, forKey: LPPortableArchive.originalURLKey)
        coder.encode(remoteVideoURL as NSURL?, forKey: LPPortableArchive.remoteVideoURLKey)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copied = LPLinkMetadata()
        copied.title = title
        copied.url = url
        copied.originalURL = originalURL
        copied.remoteVideoURL = remoteVideoURL
        return copied
    }
}

/// Link preview view. Isolated Linux subclasses `NSObject` because UIKit is
/// not a declared dependency. This is not a public UIView lookalike and does
/// not render Apple's preview chrome.
@preconcurrency @MainActor
open class LPLinkView: NSObject {
    @NSCopying open var metadata: LPLinkMetadata

    @MainActor
    public init(metadata: LPLinkMetadata) {
        // `@NSCopying` does not copy during initialization on this Linux
        // runtime; copy explicitly so the view does not alias the caller.
        let copied = (metadata.copy() as? LPLinkMetadata) ?? LPLinkMetadata()
        self.metadata = copied
        super.init()
    }

    @MainActor
    public init(url URL: URL) {
        let metadata = LPLinkMetadata()
        metadata.originalURL = URL
        self.metadata = metadata
        super.init()
    }

    @MainActor
    public init(URL: URL) {
        let metadata = LPLinkMetadata()
        metadata.originalURL = URL
        self.metadata = metadata
        super.init()
    }
}

/// Metadata fetcher. Linux has no Apple link-preview service, so every fetch
/// fail-closes with `LPError.metadataFetchFailed`. Stored `timeout` /
/// `shouldFetchSubresources` values are local only.
open class LPMetadataProvider: NSObject, @unchecked Sendable {
    /// Linux stored default is `false` (do not fetch subresources). Darwin's
    /// default is unobserved.
    open var shouldFetchSubresources: Bool = false

    /// Linux stored default is `0` (no wait). Darwin's default is unobserved.
    open var timeout: TimeInterval = 0

    public override init() {
        super.init()
    }

    /// No in-flight Apple fetch exists on this host. The method is retained
    /// so callers can invoke it without a crash.
    open func cancel() {}

    open func startFetchingMetadata(for URL: URL) async throws -> LPLinkMetadata {
        _ = URL
        throw LPError(.metadataFetchFailed)
    }

    open func startFetchingMetadata(for request: URLRequest) async throws -> LPLinkMetadata {
        _ = request
        throw LPError(.metadataFetchFailed)
    }
}
