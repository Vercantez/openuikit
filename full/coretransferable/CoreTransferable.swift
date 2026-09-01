@_exported import Foundation
@_exported import UniformTypeIdentifiers

public enum TransferableError: Error, Equatable, Sendable {
    case exportNotSupported(contentType: String)
    case importNotSupported(contentType: String)
}

public protocol TransferRepresentation<Item>: Sendable {
    associatedtype Item: Transferable
}

@resultBuilder
public struct TransferRepresentationBuilder<Item> where Item: Transferable {
    public static func buildExpression<Content>(
        _ content: Content
    ) -> Content where Content: TransferRepresentation, Content.Item == Item {
        content
    }

    public static func buildBlock<Content>(
        _ content: Content
    ) -> Content where Content: TransferRepresentation, Content.Item == Item {
        content
    }

    public static func buildBlock<First, Second>(
        _ first: First,
        _ second: Second
    ) -> TupleTransferRepresentation<Item, (First, Second)>
    where
        First: TransferRepresentation,
        Second: TransferRepresentation,
        First.Item == Item,
        Second.Item == Item
    {
        TupleTransferRepresentation((first, second))
    }

    public static func buildBlock<First, Second, Third>(
        _ first: First,
        _ second: Second,
        _ third: Third
    ) -> TupleTransferRepresentation<Item, (First, Second, Third)>
    where
        First: TransferRepresentation,
        Second: TransferRepresentation,
        Third: TransferRepresentation,
        First.Item == Item,
        Second.Item == Item,
        Third.Item == Item
    {
        TupleTransferRepresentation((first, second, third))
    }
}

public protocol Transferable: Sendable {
    associatedtype Representation: TransferRepresentation

    @TransferRepresentationBuilder<Self>
    static var transferRepresentation: Representation { get }
}

public struct TupleTransferRepresentation<Transferred, Value>:
    TransferRepresentation, Sendable
where Transferred: Transferable, Value: Sendable {
    public typealias Item = Transferred

    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}

public struct DataRepresentation<Transferred>: TransferRepresentation,
    Sendable
where Transferred: Transferable {
    public typealias Item = Transferred

    public let exportedContentType: UTType?
    public let importedContentType: UTType?

    private let exporter: (@Sendable (Transferred) async throws -> Data)?
    private let importer: (@Sendable (Data) async throws -> Transferred)?

    public init(
        contentType: UTType,
        exporting: @escaping @Sendable (Transferred) async throws -> Data,
        importing: @escaping @Sendable (Data) async throws -> Transferred
    ) {
        exportedContentType = contentType
        importedContentType = contentType
        exporter = exporting
        importer = importing
    }

    public init(
        exportedContentType: UTType,
        exporting: @escaping @Sendable (Transferred) async throws -> Data
    ) {
        self.exportedContentType = exportedContentType
        importedContentType = nil
        exporter = exporting
        importer = nil
    }

    public init(
        importedContentType: UTType,
        importing: @escaping @Sendable (Data) async throws -> Transferred
    ) {
        exportedContentType = nil
        self.importedContentType = importedContentType
        exporter = nil
        importer = importing
    }

    @_spi(OpenUIKitHost)
    public func _export(_ item: Transferred) async throws -> Data {
        guard let exporter else {
            throw TransferableError.exportNotSupported(
                contentType: importedContentType?.identifier ?? "public.data"
            )
        }
        return try await exporter(item)
    }

    @_spi(OpenUIKitHost)
    public func _import(_ data: Data) async throws -> Transferred {
        guard let importer else {
            throw TransferableError.importNotSupported(
                contentType: exportedContentType?.identifier ?? "public.data"
            )
        }
        return try await importer(data)
    }
}

public struct SentTransferredFile: Sendable {
    public let file: URL
    public let allowAccessingOriginalFile: Bool

    public init(_ file: URL, allowAccessingOriginalFile: Bool = false) {
        self.file = file
        self.allowAccessingOriginalFile = allowAccessingOriginalFile
    }
}

public struct ReceivedTransferredFile: Sendable {
    public let file: URL
    public let isOriginalFile: Bool

    @_spi(OpenUIKitHost)
    public init(file: URL, isOriginalFile: Bool) {
        self.file = file
        self.isOriginalFile = isOriginalFile
    }
}

public struct FileRepresentation<Transferred>: TransferRepresentation,
    Sendable
where Transferred: Transferable {
    public typealias Item = Transferred

    public let exportedContentType: UTType?
    public let importedContentType: UTType?
    public let shouldAttemptToOpenInPlace: Bool

    private let exporter:
        (@Sendable (Transferred) async throws -> SentTransferredFile)?
    private let importer:
        (@Sendable (ReceivedTransferredFile) async throws -> Transferred)?

    public init(
        contentType: UTType,
        shouldAttemptToOpenInPlace: Bool = false,
        exporting: @escaping @Sendable (Transferred) async throws
            -> SentTransferredFile,
        importing: @escaping @Sendable (ReceivedTransferredFile) async throws
            -> Transferred
    ) {
        exportedContentType = contentType
        importedContentType = contentType
        self.shouldAttemptToOpenInPlace = shouldAttemptToOpenInPlace
        exporter = exporting
        importer = importing
    }

    public init(
        exportedContentType: UTType,
        shouldAllowToOpenInPlace: Bool = false,
        exporting: @escaping @Sendable (Transferred) async throws
            -> SentTransferredFile
    ) {
        self.exportedContentType = exportedContentType
        importedContentType = nil
        shouldAttemptToOpenInPlace = shouldAllowToOpenInPlace
        exporter = exporting
        importer = nil
    }

    public init(
        importedContentType: UTType,
        shouldAttemptToOpenInPlace: Bool = false,
        importing: @escaping @Sendable (ReceivedTransferredFile) async throws
            -> Transferred
    ) {
        exportedContentType = nil
        self.importedContentType = importedContentType
        self.shouldAttemptToOpenInPlace = shouldAttemptToOpenInPlace
        exporter = nil
        importer = importing
    }

    @_spi(OpenUIKitHost)
    public func _export(_ item: Transferred) async throws
        -> SentTransferredFile
    {
        guard let exporter else {
            throw TransferableError.exportNotSupported(
                contentType: importedContentType?.identifier ?? "public.data"
            )
        }
        return try await exporter(item)
    }

    @_spi(OpenUIKitHost)
    public func _import(
        _ file: ReceivedTransferredFile
    ) async throws -> Transferred {
        guard let importer else {
            throw TransferableError.importNotSupported(
                contentType: exportedContentType?.identifier ?? "public.data"
            )
        }
        return try await importer(file)
    }
}
