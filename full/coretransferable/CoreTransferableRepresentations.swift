public struct ProxyRepresentation<Item, ProxyRepresentation>:
    TransferRepresentation, Sendable
where Item: Transferable, ProxyRepresentation: Transferable {
    public typealias Body = Never

    private let asyncExporter:
        (@Sendable (Item) async throws -> ProxyRepresentation)?
    private let syncExporter: (@Sendable (Item) throws -> ProxyRepresentation)?
    private let asyncImporter:
        (@Sendable (ProxyRepresentation) async throws -> Item)?
    private let syncImporter: (@Sendable (ProxyRepresentation) throws -> Item)?

    public init(
        exporting: @escaping @Sendable (Item) async throws -> ProxyRepresentation,
        importing: @escaping @Sendable (ProxyRepresentation) async throws -> Item
    ) {
        asyncExporter = exporting
        syncExporter = nil
        asyncImporter = importing
        syncImporter = nil
    }

    public init(
        exporting: @escaping @Sendable (Item) throws -> ProxyRepresentation,
        importing: @escaping @Sendable (ProxyRepresentation) async throws -> Item
    ) {
        asyncExporter = nil
        syncExporter = exporting
        asyncImporter = importing
        syncImporter = nil
    }

    public init(
        exporting: @escaping @Sendable (Item) throws -> ProxyRepresentation,
        importing: @escaping @Sendable (ProxyRepresentation) throws -> Item
    ) {
        asyncExporter = nil
        syncExporter = exporting
        asyncImporter = nil
        syncImporter = importing
    }

    public init(
        exporting: @escaping @Sendable (Item) async throws -> ProxyRepresentation
    ) {
        asyncExporter = exporting
        syncExporter = nil
        asyncImporter = nil
        syncImporter = nil
    }

    public init(
        exporting: @escaping @Sendable (Item) throws -> ProxyRepresentation
    ) {
        asyncExporter = nil
        syncExporter = exporting
        asyncImporter = nil
        syncImporter = nil
    }

    public init(
        importing: @escaping @Sendable (ProxyRepresentation) async throws -> Item
    ) {
        asyncExporter = nil
        syncExporter = nil
        asyncImporter = importing
        syncImporter = nil
    }

    public init(
        importing: @escaping @Sendable (ProxyRepresentation) throws -> Item
    ) {
        asyncExporter = nil
        syncExporter = nil
        asyncImporter = nil
        syncImporter = importing
    }

    func _exportProxy(_ item: Item) async throws -> ProxyRepresentation {
        if let asyncExporter {
            return try await asyncExporter(item)
        }
        if let syncExporter {
            return try syncExporter(item)
        }
        throw TransferableError.exportNotSupported(contentType: "proxy")
    }

    func _importProxy(_ proxy: ProxyRepresentation) async throws -> Item {
        if let asyncImporter {
            return try await asyncImporter(proxy)
        }
        if let syncImporter {
            return try syncImporter(proxy)
        }
        throw TransferableError.importNotSupported(contentType: "proxy")
    }

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        guard asyncExporter != nil || syncExporter != nil else { return [] }
        return ProxyRepresentation.exportedContentTypes(visibility: visibility)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        guard asyncImporter != nil || syncImporter != nil else { return [] }
        return ProxyRepresentation.importedContentTypes()
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Item) -> Bool {
        _ = item
        return asyncExporter != nil || syncExporter != nil
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(
        _ item: Item,
        contentType: UTType?
    ) async throws -> Data {
        let proxy = try await _exportProxy(item)
        return try await proxy.exported(as: contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(
        _ item: Item,
        contentType: UTType?
    ) async throws -> SentTransferredFile {
        let proxy = try await _exportProxy(item)
        return try await proxy._hostSentFile(contentType: contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(
        _ data: Data,
        contentType: UTType?
    ) async throws -> Item {
        let proxy = try await ProxyRepresentation(importing: data, contentType: contentType)
        return try await _importProxy(proxy)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item {
        let proxy = try await ProxyRepresentation(
            importing: file.file,
            contentType: contentType
        )
        return try await _importProxy(proxy)
    }
}

@preconcurrency
public struct CodableRepresentation<Item, Encoder, Decoder>:
    TransferRepresentation, Sendable
where
    Item: Transferable,
    Item: Decodable,
    Item: Encodable,
    Encoder: TopLevelEncoder,
    Encoder: Sendable,
    Decoder: TopLevelDecoder,
    Decoder: Sendable,
    Encoder.Output == Data,
    Decoder.Input == Data
{
    public typealias Body = Never

    public let contentType: UTType
    let encoder: Encoder
    let decoder: Decoder

    public init(
        for itemType: Item.Type = Item.self,
        contentType: UTType,
        encoder: Encoder,
        decoder: Decoder
    ) {
        _ = itemType
        self.contentType = contentType
        self.encoder = encoder
        self.decoder = decoder
    }

    public init(
        for itemType: Item.Type = Item.self,
        contentType: UTType
    ) where Encoder == JSONEncoder, Decoder == JSONDecoder {
        self.init(
            for: itemType,
            contentType: contentType,
            encoder: JSONEncoder(),
            decoder: JSONDecoder()
        )
    }

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        _ = visibility
        return [contentType]
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        [contentType]
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(
        _ item: Item,
        contentType: UTType?
    ) async throws -> Data {
        _ = contentType
        return try encoder.encode(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(
        _ item: Item,
        contentType: UTType?
    ) async throws -> SentTransferredFile {
        let data = try await _hostExportData(item, contentType: contentType)
        return try _hostWriteTempFile(data: data, preferredName: nil)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(
        _ data: Data,
        contentType: UTType?
    ) async throws -> Item {
        _ = contentType
        return try decoder.decode(Item.self, from: data)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item {
        let data = try Data(contentsOf: file.file)
        return try await _hostImportData(data, contentType: contentType)
    }
}
