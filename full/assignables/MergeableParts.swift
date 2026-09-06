import Foundation

/// Stable identifier for one mergeable document part.
///
/// Darwin raw strings for the well-known `PartIDs` constants are not in the
/// sealed graph. This overlay uses the public property names as `rawValue`.
public struct MergeablePartsContainerPartID: Hashable, Sendable {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static func == (a: MergeablePartsContainerPartID, b: MergeablePartsContainerPartID) -> Bool {
        a.rawValue == b.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

/// Bytes or a file URL for one mergeable part.
public enum MergeablePartData: Hashable, Sendable {
    case data(Data)
    case fileURL(URL)
}

/// Document that stores independently mergeable parts.
public protocol MergeablePartsContainer: Hashable {
    typealias PartID = MergeablePartsContainerPartID

    func exportParts(identifiedBy partIDs: [Self.PartID]) async throws -> [Self.PartID: MergeablePartData]
    mutating func merge(other: Self) throws -> Bool
    mutating func merge(partID: Self.PartID, partDataURL: URL) throws -> Bool
    mutating func merge(partData: MergeablePartData, into partID: Self.PartID) async throws -> Bool
    mutating func merge(_ other: Self) async throws -> Bool
    func export(partIDs: [Self.PartID]) async throws -> [Self.PartID: URL]
    var partIDs: [Self.PartID] { get }
    func makePart(for partID: Self.PartID) throws -> MergeablePartData?
    var isPartial: Bool { get }
}

/// Raster thumbnail of one mergeable document page. Linux never fills pixels.
public struct DocumentThumbnail<Document: MergeableDocument>: Hashable {
    public var pageID: Document.Page.ID

    public init(pageID: Document.Page.ID) {
        self.pageID = pageID
    }
}

/// Page in a mergeable document.
public protocol MergeableDocumentPage: Identifiable {
    associatedtype Document: MergeableDocument
    typealias Thumbnail = DocumentThumbnail<Document>
}

/// Mergeable document with pages and PDF export.
public protocol MergeableDocument: MergeablePartsContainer, Identifiable {
    associatedtype Page: MergeableDocumentPage where Page.Document == Self
    associatedtype Error: Swift.Error

    func exportToPDF(visibleParts: [Self.PartID]) async -> PDFDocument
    func pageThumbnails(visibleParts: [Self.PartID]) async -> [Self.Page.ID: Self.Page.Thumbnail]
    var pages: [Self.Page] { get }
}

// The sealed graph also records a constrained protocol-extension overlay of
// `pageThumbnails(visibleParts:)` where `Page.ID` is `Hashable`. Concrete
// documents implement the requirement; Swift synthesizes the overlay.

/// Element hosted by a mergeable document.
public protocol DocumentElement: Hashable {
    associatedtype Document: MergeableDocument
}

/// Codable identity of a `DocumentElement`.
public protocol DocumentElementID: Decodable, Encodable, Hashable {
    associatedtype Element: DocumentElement
}

/// UUID-backed element identity used by `AssignableDocument.Question`.
public struct BasicDocumentElementID<Element: DocumentElement>: DocumentElementID, Sendable {
    let raw: UUID

    init(_ raw: UUID = UUID()) {
        self.raw = raw
    }

    public static func == (
        a: BasicDocumentElementID<Element>,
        b: BasicDocumentElementID<Element>
    ) -> Bool {
        a.raw == b.raw
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(raw)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.raw = try container.decode(UUID.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

/// Marker for elements owned by an assignable document.
public protocol AssignableDocumentElement: DocumentElement {}

/// Marker for elements owned by an assigned-work document.
public protocol AssignedWorkDocumentElement: DocumentElement {}

enum AssignablesPartCodec {
    static func data(from part: MergeablePartData) throws -> Data {
        switch part {
        case .data(let data):
            return data
        case .fileURL(let url):
            guard let data = try? Data(contentsOf: url) else {
                throw AssignableDocument.Error.invalidURL
            }
            return data
        }
    }
}
