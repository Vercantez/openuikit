@_exported import Foundation

#if canImport(UniformTypeIdentifiers)
@_exported import UniformTypeIdentifiers
#endif

public enum TransferableError: Error, Equatable, Sendable {
    case exportNotSupported(contentType: String)
    case importNotSupported(contentType: String)
}

public protocol TransferRepresentation<Item>: Sendable {
    associatedtype Item: Transferable
    associatedtype Body: TransferRepresentation

    var body: Body { get }

    @_spi(OpenUIKitHost)
    func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType]

    @_spi(OpenUIKitHost)
    func _hostImportedContentTypes() -> [UTType]

    @_spi(OpenUIKitHost)
    func _hostSuggestedFileName(_ item: Item) -> String?

    @_spi(OpenUIKitHost)
    func _hostAllowsExport(_ item: Item) -> Bool

    @_spi(OpenUIKitHost)
    func _hostExportData(_ item: Item, contentType: UTType?) async throws -> Data

    @_spi(OpenUIKitHost)
    func _hostExportFile(_ item: Item, contentType: UTType?) async throws
        -> SentTransferredFile

    @_spi(OpenUIKitHost)
    func _hostImportData(_ data: Data, contentType: UTType?) async throws -> Item

    @_spi(OpenUIKitHost)
    func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item
}

extension TransferRepresentation {
    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        []
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        []
    }

    @_spi(OpenUIKitHost)
    public func _hostSuggestedFileName(_ item: Item) -> String? {
        nil
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Item) -> Bool {
        true
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(_ item: Item, contentType: UTType?) async throws
        -> Data
    {
        throw TransferableError.exportNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(_ item: Item, contentType: UTType?) async throws
        -> SentTransferredFile
    {
        throw TransferableError.exportNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(_ data: Data, contentType: UTType?) async throws
        -> Item
    {
        throw TransferableError.importNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Item {
        throw TransferableError.importNotSupported(
            contentType: contentType?.identifier ?? "public.data"
        )
    }
}

extension TransferRepresentation where Body == Never {
    public var body: Never {
        preconditionFailure("leaf TransferRepresentation has no body")
    }
}

@resultBuilder
public struct TransferRepresentationBuilder<Item> where Item: Transferable {
    public static func buildExpression<Content>(
        _ content: Content
    ) -> Content where Content: TransferRepresentation, Content.Item == Item {
        content
    }

    public static func buildExpression<Encoder, Decoder>(
        _ content: CodableRepresentation<Item, Encoder, Decoder>
    ) -> CodableRepresentation<Item, Encoder, Decoder>
    where
        Item: Decodable,
        Item: Encodable,
        Encoder: TopLevelEncoder,
        Decoder: TopLevelDecoder,
        Encoder.Output == Data,
        Decoder.Input == Data
    {
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
        TupleTransferRepresentation(
            (first, second),
            node: .concat([.leaf(first), .leaf(second)])
        )
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
        TupleTransferRepresentation(
            (first, second, third),
            node: .concat([.leaf(first), .leaf(second), .leaf(third)])
        )
    }

    public static func buildBlock<C1, C2, C3, C4>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4
    ) -> TupleTransferRepresentation<Item, (C1, C2, C3, C4)>
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3), .leaf(content4),
            ])
        )
    }

    public static func buildBlock<C1, C2, C3, C4, C5>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4,
        _ content5: C5
    ) -> TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5)>
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C5: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item,
        C5.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4, content5),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3),
                .leaf(content4), .leaf(content5),
            ])
        )
    }

    public static func buildBlock<C1, C2, C3, C4, C5, C6>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4,
        _ content5: C5, _ content6: C6
    ) -> TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6)>
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C5: TransferRepresentation, C6: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item,
        C5.Item == Item, C6.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4, content5, content6),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3),
                .leaf(content4), .leaf(content5), .leaf(content6),
            ])
        )
    }

    public static func buildBlock<C1, C2, C3, C4, C5, C6, C7>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4,
        _ content5: C5, _ content6: C6, _ content7: C7
    ) -> TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7)>
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C5: TransferRepresentation, C6: TransferRepresentation,
        C7: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item,
        C5.Item == Item, C6.Item == Item, C7.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4, content5, content6, content7),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3),
                .leaf(content4), .leaf(content5), .leaf(content6), .leaf(content7),
            ])
        )
    }

    public static func buildBlock<C1, C2, C3, C4, C5, C6, C7, C8>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4,
        _ content5: C5, _ content6: C6, _ content7: C7, _ content8: C8
    ) -> TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7, C8)>
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C5: TransferRepresentation, C6: TransferRepresentation,
        C7: TransferRepresentation, C8: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item,
        C5.Item == Item, C6.Item == Item, C7.Item == Item, C8.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4, content5, content6, content7,
             content8),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3), .leaf(content4),
                .leaf(content5), .leaf(content6), .leaf(content7), .leaf(content8),
            ])
        )
    }

    public static func buildBlock<C1, C2, C3, C4, C5, C6, C7, C8, C9>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4,
        _ content5: C5, _ content6: C6, _ content7: C7, _ content8: C8,
        _ content9: C9
    ) -> TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7, C8, C9)>
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C5: TransferRepresentation, C6: TransferRepresentation,
        C7: TransferRepresentation, C8: TransferRepresentation,
        C9: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item,
        C5.Item == Item, C6.Item == Item, C7.Item == Item, C8.Item == Item,
        C9.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4, content5, content6, content7,
             content8, content9),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3), .leaf(content4),
                .leaf(content5), .leaf(content6), .leaf(content7), .leaf(content8),
                .leaf(content9),
            ])
        )
    }

    public static func buildBlock<C1, C2, C3, C4, C5, C6, C7, C8, C9, C10>(
        _ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4,
        _ content5: C5, _ content6: C6, _ content7: C7, _ content8: C8,
        _ content9: C9, _ content10: C10
    ) -> TupleTransferRepresentation<
        Item, (C1, C2, C3, C4, C5, C6, C7, C8, C9, C10)
    >
    where
        C1: TransferRepresentation, C2: TransferRepresentation,
        C3: TransferRepresentation, C4: TransferRepresentation,
        C5: TransferRepresentation, C6: TransferRepresentation,
        C7: TransferRepresentation, C8: TransferRepresentation,
        C9: TransferRepresentation, C10: TransferRepresentation,
        C1.Item == Item, C2.Item == Item, C3.Item == Item, C4.Item == Item,
        C5.Item == Item, C6.Item == Item, C7.Item == Item, C8.Item == Item,
        C9.Item == Item, C10.Item == Item
    {
        TupleTransferRepresentation(
            (content1, content2, content3, content4, content5, content6, content7,
             content8, content9, content10),
            node: .concat([
                .leaf(content1), .leaf(content2), .leaf(content3), .leaf(content4),
                .leaf(content5), .leaf(content6), .leaf(content7), .leaf(content8),
                .leaf(content9), .leaf(content10),
            ])
        )
    }

    public static func buildLimitedAvailability<Content>(
        _ content: Content
    ) -> Content where Content: TransferRepresentation, Content.Item == Item {
        content
    }

    public static func buildOptional<Content>(
        _ content: Content?
    ) -> _HostNodeRepresentation<Item>
    where Content: TransferRepresentation, Content.Item == Item {
        guard let content else {
            return _HostNodeRepresentation(node: .empty())
        }
        return _HostNodeRepresentation(node: .leaf(content))
    }

    public static func buildEither<TrueContent>(
        first component: TrueContent
    ) -> _HostNodeRepresentation<Item>
    where TrueContent: TransferRepresentation, TrueContent.Item == Item {
        _HostNodeRepresentation(node: .leaf(component))
    }

    public static func buildEither<FalseContent>(
        second component: FalseContent
    ) -> _HostNodeRepresentation<Item>
    where FalseContent: TransferRepresentation, FalseContent.Item == Item {
        _HostNodeRepresentation(node: .leaf(component))
    }
}

@preconcurrency
public protocol Transferable: Sendable {
    associatedtype Representation: TransferRepresentation

    @TransferRepresentationBuilder<Self>
    static var transferRepresentation: Representation { get }
}

public struct TransferRepresentationVisibility: Equatable, Hashable, Sendable {
    public static let all = TransferRepresentationVisibility(code: "all")
    public static let team = TransferRepresentationVisibility(code: "team")
    public static let ownProcess = TransferRepresentationVisibility(code: "ownProcess")

    let code: String

    public static func == (
        a: TransferRepresentationVisibility,
        b: TransferRepresentationVisibility
    ) -> Bool {
        a.code == b.code
    }
}

struct _TransferNode<Item: Transferable>: Sendable {
    let exportedTypes: @Sendable (TransferRepresentationVisibility) -> [UTType]
    let importedTypes: @Sendable () -> [UTType]
    let suggestedFileName: @Sendable (Item) -> String?
    let allowsExport: @Sendable (Item) -> Bool
    let matchesExport: @Sendable (UTType?) -> Bool
    let matchesImport: @Sendable (UTType?) -> Bool
    let exportData: @Sendable (Item, UTType?) async throws -> Data
    let exportFile: @Sendable (Item, UTType?) async throws -> SentTransferredFile
    let importData: @Sendable (Data, UTType?) async throws -> Item
    let importFile:
        @Sendable (ReceivedTransferredFile, UTType?) async throws -> Item

    static func empty() -> _TransferNode<Item> {
        let missing = "public.data"
        return _TransferNode(
            exportedTypes: { _ in [] },
            importedTypes: { [] },
            suggestedFileName: { _ in nil },
            allowsExport: { _ in false },
            matchesExport: { _ in false },
            matchesImport: { _ in false },
            exportData: { _, type in
                throw TransferableError.exportNotSupported(
                    contentType: type?.identifier ?? missing
                )
            },
            exportFile: { _, type in
                throw TransferableError.exportNotSupported(
                    contentType: type?.identifier ?? missing
                )
            },
            importData: { _, type in
                throw TransferableError.importNotSupported(
                    contentType: type?.identifier ?? missing
                )
            },
            importFile: { _, type in
                throw TransferableError.importNotSupported(
                    contentType: type?.identifier ?? missing
                )
            }
        )
    }

    static func leaf<R: TransferRepresentation>(
        _ representation: R
    ) -> _TransferNode<Item> where R.Item == Item {
        _TransferNode(
            exportedTypes: {
                representation._hostExportedContentTypes(visibility: $0)
            },
            importedTypes: { representation._hostImportedContentTypes() },
            suggestedFileName: { representation._hostSuggestedFileName($0) },
            allowsExport: { representation._hostAllowsExport($0) },
            matchesExport: { want in
                let types = representation._hostExportedContentTypes(
                    visibility: .all
                )
                guard let want else { return representation._hostAllowsExportPlaceholder() }
                return types.contains { _hostUTType($0, matches: want) }
            },
            matchesImport: { want in
                let types = representation._hostImportedContentTypes()
                guard let want else { return !types.isEmpty }
                return types.contains { _hostUTType($0, matches: want) }
            },
            exportData: {
                try await representation._hostExportData($0, contentType: $1)
            },
            exportFile: {
                try await representation._hostExportFile($0, contentType: $1)
            },
            importData: {
                try await representation._hostImportData($0, contentType: $1)
            },
            importFile: {
                try await representation._hostImportFile($0, contentType: $1)
            }
        )
    }

    static func concat(_ nodes: [_TransferNode<Item>]) -> _TransferNode<Item> {
        let copied = nodes
        return _TransferNode(
            exportedTypes: { visibility in
                copied.flatMap { $0.exportedTypes(visibility) }
            },
            importedTypes: { copied.flatMap { $0.importedTypes() } },
            suggestedFileName: { item in
                for node in copied {
                    if let name = node.suggestedFileName(item) {
                        return name
                    }
                }
                return nil
            },
            allowsExport: { item in copied.contains { $0.allowsExport(item) } },
            matchesExport: { want in copied.contains { $0.matchesExport(want) } },
            matchesImport: { want in copied.contains { $0.matchesImport(want) } },
            exportData: { item, type in
                try await _hostFirstSuccess(copied, type: type) { node in
                    guard node.allowsExport(item), node.matchesExport(type) else {
                        throw TransferableError.exportNotSupported(
                            contentType: type?.identifier ?? "public.data"
                        )
                    }
                    return try await node.exportData(item, type)
                }
            },
            exportFile: { item, type in
                try await _hostFirstSuccess(copied, type: type) { node in
                    guard node.allowsExport(item), node.matchesExport(type) else {
                        throw TransferableError.exportNotSupported(
                            contentType: type?.identifier ?? "public.data"
                        )
                    }
                    return try await node.exportFile(item, type)
                }
            },
            importData: { data, type in
                try await _hostFirstSuccess(copied, type: type) { node in
                    guard node.matchesImport(type) else {
                        throw TransferableError.importNotSupported(
                            contentType: type?.identifier ?? "public.data"
                        )
                    }
                    return try await node.importData(data, type)
                }
            },
            importFile: { file, type in
                try await _hostFirstSuccess(copied, type: type) { node in
                    guard node.matchesImport(type) else {
                        throw TransferableError.importNotSupported(
                            contentType: type?.identifier ?? "public.data"
                        )
                    }
                    return try await node.importFile(file, type)
                }
            }
        )
    }
}

extension TransferRepresentation {
    fileprivate func _hostAllowsExportPlaceholder() -> Bool {
        !_hostExportedContentTypes(visibility: .all).isEmpty
    }
}

private func _hostFirstSuccess<Item, Result>(
    _ nodes: [_TransferNode<Item>],
    type: UTType?,
    _ body: (_TransferNode<Item>) async throws -> Result
) async throws -> Result {
    var last: Error = TransferableError.exportNotSupported(
        contentType: type?.identifier ?? "public.data"
    )
    var sawUnsupported = false
    for node in nodes {
        do {
            return try await body(node)
        } catch let error as TransferableError {
            switch error {
            case .exportNotSupported, .importNotSupported:
                last = error
                sawUnsupported = true
                continue
            }
        } catch {
            throw error
        }
    }
    if sawUnsupported {
        throw last
    }
    throw last
}

public struct _HostNodeRepresentation<Transferred>: TransferRepresentation, Sendable
where Transferred: Transferable {
    public typealias Item = Transferred
    public typealias Body = Never

    let node: _TransferNode<Transferred>

    init(node: _TransferNode<Transferred>) {
        self.node = node
    }

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        node.exportedTypes(visibility)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        node.importedTypes()
    }

    @_spi(OpenUIKitHost)
    public func _hostSuggestedFileName(_ item: Transferred) -> String? {
        node.suggestedFileName(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Transferred) -> Bool {
        node.allowsExport(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> Data {
        try await node.exportData(item, contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> SentTransferredFile {
        try await node.exportFile(item, contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(
        _ data: Data,
        contentType: UTType?
    ) async throws -> Transferred {
        try await node.importData(data, contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Transferred {
        try await node.importFile(file, contentType)
    }
}

public struct TupleTransferRepresentation<Transferred, Value>:
    TransferRepresentation, Sendable
where Transferred: Transferable, Value: Sendable {
    public typealias Item = Transferred
    public typealias Body = _HostNodeRepresentation<Transferred>

    let value: Value
    let node: _TransferNode<Transferred>

    init(_ value: Value, node: _TransferNode<Transferred>) {
        self.value = value
        self.node = node
    }

    init(_ value: Value) {
        self.value = value
        self.node = .empty()
    }

    public var body: _HostNodeRepresentation<Transferred> {
        _HostNodeRepresentation(node: node)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        node.exportedTypes(visibility)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        node.importedTypes()
    }

    @_spi(OpenUIKitHost)
    public func _hostSuggestedFileName(_ item: Transferred) -> String? {
        node.suggestedFileName(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Transferred) -> Bool {
        node.allowsExport(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> Data {
        try await node.exportData(item, contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> SentTransferredFile {
        try await node.exportFile(item, contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(
        _ data: Data,
        contentType: UTType?
    ) async throws -> Transferred {
        try await node.importData(data, contentType)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Transferred {
        try await node.importFile(file, contentType)
    }
}

public struct DataRepresentation<Transferred>: TransferRepresentation,
    Sendable
where Transferred: Transferable {
    public typealias Item = Transferred
    public typealias Body = Never

    public let exportedContentType: UTType?
    public let importedContentType: UTType?

    let exporter: (@Sendable (Transferred) async throws -> Data)?
    let importer: (@Sendable (Data) async throws -> Transferred)?

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

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        _ = visibility
        guard let exportedContentType else { return [] }
        return [exportedContentType]
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        guard let importedContentType else { return [] }
        return [importedContentType]
    }

    @_spi(OpenUIKitHost)
    public func _hostSuggestedFileName(_ item: Transferred) -> String? {
        _ = item
        return nil
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Transferred) -> Bool {
        _ = item
        return exporter != nil
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> Data {
        try await _export(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> SentTransferredFile {
        let data = try await _export(item)
        return try _hostWriteTempFile(
            data: data,
            preferredName: _hostSuggestedFileName(item)
        )
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(
        _ data: Data,
        contentType: UTType?
    ) async throws -> Transferred {
        try await _import(data)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Transferred {
        let data = try Data(contentsOf: file.file)
        return try await _import(data)
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
    public typealias Body = Never

    public let exportedContentType: UTType?
    public let importedContentType: UTType?
    public let shouldAttemptToOpenInPlace: Bool

    let exporter: (@Sendable (Transferred) async throws -> SentTransferredFile)?
    let importer: (@Sendable (ReceivedTransferredFile) async throws -> Transferred)?

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

    @_spi(OpenUIKitHost)
    public func _hostExportedContentTypes(
        visibility: TransferRepresentationVisibility
    ) -> [UTType] {
        _ = visibility
        guard let exportedContentType else { return [] }
        return [exportedContentType]
    }

    @_spi(OpenUIKitHost)
    public func _hostImportedContentTypes() -> [UTType] {
        guard let importedContentType else { return [] }
        return [importedContentType]
    }

    @_spi(OpenUIKitHost)
    public func _hostSuggestedFileName(_ item: Transferred) -> String? {
        _ = item
        return nil
    }

    @_spi(OpenUIKitHost)
    public func _hostAllowsExport(_ item: Transferred) -> Bool {
        _ = item
        return exporter != nil
    }

    @_spi(OpenUIKitHost)
    public func _hostExportData(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> Data {
        let sent = try await _export(item)
        return try Data(contentsOf: sent.file)
    }

    @_spi(OpenUIKitHost)
    public func _hostExportFile(
        _ item: Transferred,
        contentType: UTType?
    ) async throws -> SentTransferredFile {
        try await _export(item)
    }

    @_spi(OpenUIKitHost)
    public func _hostImportData(
        _ data: Data,
        contentType: UTType?
    ) async throws -> Transferred {
        let sent = try _hostWriteTempFile(data: data, preferredName: nil)
        return try await _import(
            ReceivedTransferredFile(file: sent.file, isOriginalFile: false)
        )
    }

    @_spi(OpenUIKitHost)
    public func _hostImportFile(
        _ file: ReceivedTransferredFile,
        contentType: UTType?
    ) async throws -> Transferred {
        // Documented FileRepresentation import copies into a temporary
        // location. In-place delivery (`shouldAttemptToOpenInPlace` plus a
        // sender that set allowAccessingOriginalFile) is unobserved on Linux,
        // so this host always copies and reports isOriginalFile = false.
        _ = contentType
        let copied = try _hostCopyToTemporaryLocation(file.file)
        return try await _import(
            ReceivedTransferredFile(file: copied, isOriginalFile: false)
        )
    }
}

func _hostCopyToTemporaryLocation(_ source: URL) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(
            "coretransferable-import-\(UUID().uuidString)",
            isDirectory: true
        )
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    let name = source.lastPathComponent.isEmpty ? "payload.bin" : source.lastPathComponent
    let destination = directory.appendingPathComponent(name)
    try FileManager.default.copyItem(at: source, to: destination)
    return destination
}

func _hostWriteTempFile(
    data: Data,
    preferredName: String?
) throws -> SentTransferredFile {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("coretransferable-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    let name = (preferredName?.isEmpty == false) ? preferredName! : "payload.bin"
    let url = directory.appendingPathComponent(name)
    try data.write(to: url)
    return SentTransferredFile(url)
}
