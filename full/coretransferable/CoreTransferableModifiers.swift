extension TransferRepresentation {
    public func visibility(
        _ visibility: TransferRepresentationVisibility
    ) -> some TransferRepresentation<Item> {
        _VisibilityTransferRepresentation(base: self, visibility: visibility)
    }

    public func suggestedFileName(
        _ fileName: String
    ) -> some TransferRepresentation<Item> {
        _SuggestedFileNameTransferRepresentation(
            base: self,
            constant: fileName,
            provider: nil
        )
    }

    public func suggestedFileName(
        _ fileName: @escaping @Sendable (Item) -> String?
    ) -> some TransferRepresentation<Item> {
        _SuggestedFileNameTransferRepresentation(
            base: self,
            constant: nil,
            provider: fileName
        )
    }

    public func exportingCondition(
        _ condition: @escaping @Sendable (Item) -> Bool
    ) -> _ConditionalTransferRepresentation<Self> {
        _ConditionalTransferRepresentation(base: self, condition: condition)
    }
}

struct _VisibilityTransferRepresentation<Base: TransferRepresentation>:
    TransferRepresentation
{
    typealias Item = Base.Item
    typealias Body = Never

    let base: Base
    let visibility: TransferRepresentationVisibility

    func _hostExportedContentTypes(
        visibility requested: TransferRepresentationVisibility
    ) -> [UTType] {
        if requested == .all {
            return base._hostExportedContentTypes(visibility: requested)
        }
        guard visibility == requested || visibility == .all else {
            return []
        }
        return base._hostExportedContentTypes(visibility: requested)
    }

    func _hostImportedContentTypes() -> [UTType] {
        base._hostImportedContentTypes()
    }

    func _hostSuggestedFileName(_ item: Item) -> String? {
        base._hostSuggestedFileName(item)
    }

    func _hostAllowsExport(_ item: Item) -> Bool {
        base._hostAllowsExport(item)
    }

    func _hostExportData(_ item: Item, contentType: UTType?) async throws -> Data {
        try await base._hostExportData(item, contentType: contentType)
    }

    func _hostExportFile(_ item: Item, contentType: UTType?) async throws
        -> SentTransferredFile
    {
        try await base._hostExportFile(item, contentType: contentType)
    }

    func _hostImportData(_ data: Data, contentType: UTType?) async throws -> Item {
        try await base._hostImportData(data, contentType: contentType)
    }

    func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item {
        try await base._hostImportFile(file, contentType: contentType)
    }
}

struct _SuggestedFileNameTransferRepresentation<Base: TransferRepresentation>:
    TransferRepresentation
{
    typealias Item = Base.Item
    typealias Body = Never

    let base: Base
    let constant: String?
    let provider: (@Sendable (Item) -> String?)?

    func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        base._hostExportedContentTypes(visibility: visibility)
    }

    func _hostImportedContentTypes() -> [UTType] {
        base._hostImportedContentTypes()
    }

    func _hostSuggestedFileName(_ item: Item) -> String? {
        if let provider {
            return provider(item)
        }
        if let constant {
            return constant
        }
        return base._hostSuggestedFileName(item)
    }

    func _hostAllowsExport(_ item: Item) -> Bool {
        base._hostAllowsExport(item)
    }

    func _hostExportData(_ item: Item, contentType: UTType?) async throws -> Data {
        try await base._hostExportData(item, contentType: contentType)
    }

    func _hostExportFile(_ item: Item, contentType: UTType?) async throws
        -> SentTransferredFile
    {
        let sent = try await base._hostExportFile(item, contentType: contentType)
        guard let name = _hostSuggestedFileName(item),
            sent.file.lastPathComponent != name
        else {
            return sent
        }
        let renamed = sent.file.deletingLastPathComponent()
            .appendingPathComponent(name)
        if renamed != sent.file {
            try? FileManager.default.removeItem(at: renamed)
            try FileManager.default.copyItem(at: sent.file, to: renamed)
            return SentTransferredFile(
                renamed,
                allowAccessingOriginalFile: sent.allowAccessingOriginalFile
            )
        }
        return sent
    }

    func _hostImportData(_ data: Data, contentType: UTType?) async throws -> Item {
        try await base._hostImportData(data, contentType: contentType)
    }

    func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item {
        try await base._hostImportFile(file, contentType: contentType)
    }
}

public struct _ConditionalTransferRepresentation<Base: TransferRepresentation>:
    TransferRepresentation
{
    public typealias Item = Base.Item
    public typealias Body = Never

    let base: Base
    let condition: @Sendable (Base.Item) -> Bool

    init(base: Base, condition: @escaping @Sendable (Base.Item) -> Bool) {
        self.base = base
        self.condition = condition
    }

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        base._hostExportedContentTypes(visibility: visibility)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        base._hostImportedContentTypes()
    }

    @_spi(OpenUIKitHost)
    public func _hostSuggestedFileName(_ item: Item) -> String? {
        base._hostSuggestedFileName(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Item) -> Bool {
        condition(item) && base._hostAllowsExport(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(_ item: Item, contentType: UTType?) async throws
        -> Data
    {
        guard condition(item) else {
            throw TransferableError.exportNotSupported(
                contentType: contentType?.identifier ?? "public.data"
            )
        }
        return try await base._hostExportData(item, contentType: contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(_ item: Item, contentType: UTType?) async throws
        -> SentTransferredFile
    {
        guard condition(item) else {
            throw TransferableError.exportNotSupported(
                contentType: contentType?.identifier ?? "public.data"
            )
        }
        return try await base._hostExportFile(item, contentType: contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(_ data: Data, contentType: UTType?) async throws
        -> Item
    {
        try await base._hostImportData(data, contentType: contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item {
        try await base._hostImportFile(file, contentType: contentType)
    }
}
