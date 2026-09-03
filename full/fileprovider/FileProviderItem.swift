import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Finder type/creator pair carried on some File Provider items.
public struct NSFileProviderTypeAndCreator: Hashable, Sendable {
    public var type: OSType
    public var creator: OSType

    public init() {
        self.type = 0
        self.creator = 0
    }

    public init(type: OSType, creator: OSType) {
        self.type = type
        self.creator = creator
    }
}

/// Content and metadata versions of an item.
open class NSFileProviderItemVersion: NSObject, @unchecked Sendable {
    public let contentVersion: Data
    public let metadataVersion: Data

    public init(contentVersion: Data, metadataVersion: Data) {
        self.contentVersion = contentVersion
        self.metadataVersion = metadataVersion
        super.init()
    }

    /// Sentinel component that sorts before any provider-issued version.
    /// Exact Apple bytes are not in the public graph; this portable value is
    /// empty `Data` and must not be treated as an Apple-oracle observation.
    public class var beforeFirstSyncComponent: Data { Data() }
}

/// Metadata for a File Provider item. Optional ObjC properties are supplied
/// with protocol-extension defaults so Linux Swift can adopt the protocol
/// without an ObjC runtime.
public protocol NSFileProviderItemProtocol: NSObjectProtocol {
    var itemIdentifier: NSFileProviderItemIdentifier { get }
    var parentItemIdentifier: NSFileProviderItemIdentifier { get }
    var filename: String { get }

    var capabilities: NSFileProviderItemCapabilities { get }
    var childItemCount: NSNumber? { get }
    var contentModificationDate: Date? { get }
    var contentPolicy: NSFileProviderContentPolicy { get }
    var creationDate: Date? { get }
    var documentSize: NSNumber? { get }
    var isDownloaded: Bool { get }
    var isDownloading: Bool { get }
    var downloadingError: (any Error)? { get }
    var extendedAttributes: [String: Data] { get }
    var favoriteRank: NSNumber? { get }
    var fileSystemFlags: NSFileProviderFileSystemFlags { get }
    var itemVersion: NSFileProviderItemVersion? { get }
    var lastUsedDate: Date? { get }
    var mostRecentEditorNameComponents: PersonNameComponents? { get }
    var isMostRecentVersionDownloaded: Bool { get }
    var ownerNameComponents: PersonNameComponents? { get }
    var isShared: Bool { get }
    var isSharedByCurrentUser: Bool { get }
    var symlinkTargetPath: String? { get }
    var tagData: Data? { get }
    var isTrashed: Bool { get }
    var typeAndCreator: NSFileProviderTypeAndCreator { get }
    var typeIdentifier: String? { get }
#if canImport(UniformTypeIdentifiers)
    var contentType: UTType? { get }
#endif
    var isUploaded: Bool { get }
    var isUploading: Bool { get }
    var uploadingError: (any Error)? { get }
    var userInfo: [AnyHashable: Any]? { get }
    var versionIdentifier: Data? { get }
}

extension NSFileProviderItemProtocol {
    public var capabilities: NSFileProviderItemCapabilities { .allowsReading }
    public var childItemCount: NSNumber? { nil }
    public var contentModificationDate: Date? { nil }
    public var contentPolicy: NSFileProviderContentPolicy { .inherited }
    public var creationDate: Date? { nil }
    public var documentSize: NSNumber? { nil }
    public var isDownloaded: Bool { true }
    public var isDownloading: Bool { false }
    public var downloadingError: (any Error)? { nil }
    public var extendedAttributes: [String: Data] { [:] }
    public var favoriteRank: NSNumber? { nil }
    public var fileSystemFlags: NSFileProviderFileSystemFlags { [.userReadable] }
    public var itemVersion: NSFileProviderItemVersion? { nil }
    public var lastUsedDate: Date? { nil }
    public var mostRecentEditorNameComponents: PersonNameComponents? { nil }
    public var isMostRecentVersionDownloaded: Bool { true }
    public var ownerNameComponents: PersonNameComponents? { nil }
    public var isShared: Bool { false }
    public var isSharedByCurrentUser: Bool { false }
    public var symlinkTargetPath: String? { nil }
    public var tagData: Data? { nil }
    public var isTrashed: Bool { false }
    public var typeAndCreator: NSFileProviderTypeAndCreator { NSFileProviderTypeAndCreator() }
    public var typeIdentifier: String? { nil }
#if canImport(UniformTypeIdentifiers)
    public var contentType: UTType? { nil }
#endif
    public var isUploaded: Bool { true }
    public var isUploading: Bool { false }
    public var uploadingError: (any Error)? { nil }
    public var userInfo: [AnyHashable: Any]? { nil }
    public var versionIdentifier: Data? { itemVersion?.metadataVersion }
}

/// Existential alias matching Apple's `NSFileProviderItem` typedef.
public typealias NSFileProviderItem = any NSFileProviderItemProtocol

/// Item that also reports decoration identifiers.
public protocol NSFileProviderItemDecorating: NSFileProviderItemProtocol {
    var decorations: [NSFileProviderItemDecorationIdentifier]? { get }
}
