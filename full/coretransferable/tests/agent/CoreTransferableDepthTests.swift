import Dispatch
import Foundation
@_spi(OpenUIKitHost) import CoreTransferable

private enum DepthBox<T>: @unchecked Sendable {
    case unset
    case value(T)
    case failure(Error)
}

private func depthWait<T>(_ work: @escaping @Sendable () async throws -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = DepthLockedBox<T>()
    Task.detached {
        do {
            box.store(.value(try await work()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + .seconds(10)) == .success)
    switch box.take() {
    case .value(let value):
        return value
    case .failure(let error):
        preconditionFailure("async depth work failed: \(error)")
    case .unset:
        preconditionFailure("async depth work produced no result")
    }
}

private final class DepthLockedBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: DepthBox<T> = .unset

    func store(_ value: DepthBox<T>) {
        lock.lock()
        storage = value
        lock.unlock()
    }

    func take() -> DepthBox<T> {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

private struct DepthNote: Transferable, Equatable, Codable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .utf8PlainText) { note in
            Data(note.text.utf8)
        } importing: { data in
            DepthNote(text: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

private struct DepthFile: Transferable, Equatable, Sendable {
    var url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .data) { item in
            SentTransferredFile(item.url)
        } importing: { received in
            DepthFile(url: received.file)
        }
    }
}

private struct DepthProxy: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { (item: DepthProxy) in
            item.text
        } importing: { (text: String) in
            DepthProxy(text: text)
        }
    }
}

private struct DepthCodable: Transferable, Equatable, Codable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: DepthCodable.self, contentType: .json)
    }
}

private struct DualPayload: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .jpeg) { item in
            Data("jpeg:\(item.text)".utf8)
        } importing: { data in
            DualPayload(text: String(data: data, encoding: .utf8) ?? "")
        }
        DataRepresentation(contentType: .png) { item in
            Data("png:\(item.text)".utf8)
        } importing: { data in
            DualPayload(text: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

private struct LimitedNote: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        TransferRepresentationBuilder<LimitedNote>.buildLimitedAvailability(
            DataRepresentation(contentType: .utf8PlainText) { note in
                Data(note.text.utf8)
            } importing: { data in
                LimitedNote(text: String(data: data, encoding: .utf8) ?? "")
            }
        )
    }
}

func testFirstMatchingRepresentationWins() {
    let item = DualPayload(text: "x")
    let asImage = depthWait { try await item.exported(as: .image) }
    precondition(String(data: asImage, encoding: .utf8) == "jpeg:x")
    let asPng = depthWait { try await item.exported(as: .png) }
    precondition(String(data: asPng, encoding: .utf8) == "png:x")
    let asJpeg = depthWait { try await item.exported(as: .jpeg) }
    precondition(String(data: asJpeg, encoding: .utf8) == "jpeg:x")
    let imported = depthWait {
        try await DualPayload(importing: Data("png:z".utf8), contentType: .png)
    }
    precondition(imported.text == "png:z")
}

func testUTTypeConformanceHierarchyMatching() {
    let text = "hello transferable"
    let asText = depthWait { try await text.exported(as: .text) }
    precondition(String(data: asText, encoding: .utf8) == text)
    let asData = depthWait { try await text.exported(as: .data) }
    precondition(String(data: asData, encoding: .utf8) == text)
    let asItem = depthWait { try await Data("bytes".utf8).exported(as: .item) }
    precondition(asItem == Data("bytes".utf8))
}

func testFileRepresentationImportCopiesToTemporaryLocation() {
    let source = FileManager.default.temporaryDirectory
        .appendingPathComponent("ct-orig-\(UUID().uuidString).bin")
    try! Data("orig-bytes".utf8).write(to: source)
    let representation = FileRepresentation<DepthFile>(
        contentType: .data,
        exporting: { SentTransferredFile($0.url) },
        importing: { DepthFile(url: $0.file) }
    )
    let imported = depthWait {
        try await representation._hostImportFile(
            ReceivedTransferredFile(file: source, isOriginalFile: true),
            contentType: .data
        )
    }
    precondition(imported.url != source)
    precondition(imported.url.lastPathComponent == source.lastPathComponent)
    precondition(try! Data(contentsOf: imported.url) == Data("orig-bytes".utf8))
    precondition(FileManager.default.fileExists(atPath: source.path))
    let viaInit = depthWait {
        try await DepthFile(importing: source, contentType: .data)
    }
    precondition(viaInit.url != source)
    precondition(try! Data(contentsOf: viaInit.url) == Data("orig-bytes".utf8))
}

func testCodableRepresentationPropertyListRoundTrip() {
    let representation = CodableRepresentation<
        DepthCodable, PropertyListEncoder, PropertyListDecoder
    >(
        for: DepthCodable.self,
        contentType: .data,
        encoder: PropertyListEncoder(),
        decoder: PropertyListDecoder()
    )
    let note = DepthCodable(text: "plist")
    let data = depthWait {
        try await representation._hostExportData(note, contentType: .data)
    }
    let decoded = depthWait {
        try await representation._hostImportData(data, contentType: .data)
    }
    precondition(decoded == note)
}

func testBuildLimitedAvailability() {
    let wrapped = TransferRepresentationBuilder<LimitedNote>.buildLimitedAvailability(
        DataRepresentation<LimitedNote>(
            contentType: .utf8PlainText,
            exporting: { Data($0.text.utf8) },
            importing: { LimitedNote(text: String(data: $0, encoding: .utf8) ?? "") }
        )
    )
    let types = wrapped._hostExportedContentTypes(visibility: .all)
    precondition(types.contains { $0.identifier == "public.utf8-plain-text" })
    let exported = depthWait {
        try await wrapped._hostExportData(LimitedNote(text: "lim"), contentType: .utf8PlainText)
    }
    precondition(String(data: exported, encoding: .utf8) == "lim")
    let again = depthWait { try await LimitedNote(text: "avail").exported(as: .utf8PlainText) }
    precondition(String(data: again, encoding: .utf8) == "avail")
}

func testBuilderOptionalAndEither() {
    let present = TransferRepresentationBuilder<DepthNote>.buildOptional(
        DataRepresentation<DepthNote>(
            exportedContentType: .data,
            exporting: { Data($0.text.utf8) }
        )
    )
    let missing = TransferRepresentationBuilder<DepthNote>.buildOptional(
        Optional<DataRepresentation<DepthNote>>.none
    )
    let types = present._hostExportedContentTypes(visibility: .all)
    precondition(types.contains { $0.identifier == "public.data" })
    precondition(missing._hostExportedContentTypes(visibility: .all).isEmpty)

    let first = TransferRepresentationBuilder<DepthNote>.buildEither(
        first: DataRepresentation<DepthNote>(
            exportedContentType: .json,
            exporting: { Data($0.text.utf8) }
        )
    )
    let second = TransferRepresentationBuilder<DepthNote>.buildEither(
        second: DataRepresentation<DepthNote>(
            exportedContentType: .rtf,
            exporting: { Data($0.text.utf8) }
        )
    )
    precondition(first._hostExportedContentTypes(visibility: .all).contains {
        $0.identifier == "public.json"
    })
    precondition(second._hostExportedContentTypes(visibility: .all).contains {
        $0.identifier == "public.rtf"
    })
}

func testBuilderThreeRepresentations() {
    struct Triple: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
        }
    }
    precondition(Triple.exportedContentTypes().count == 3)
}

func testBuilderFiveThroughTenRepresentations() {
    struct Five: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
            DataRepresentation(exportedContentType: .rtf) { _ in Data() }
        }
    }
    struct Six: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
            DataRepresentation(exportedContentType: .rtf) { _ in Data() }
            DataRepresentation(exportedContentType: .url) { _ in Data() }
        }
    }
    struct Seven: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
            DataRepresentation(exportedContentType: .rtf) { _ in Data() }
            DataRepresentation(exportedContentType: .url) { _ in Data() }
            DataRepresentation(exportedContentType: .fileURL) { _ in Data() }
        }
    }
    struct Eight: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
            DataRepresentation(exportedContentType: .rtf) { _ in Data() }
            DataRepresentation(exportedContentType: .url) { _ in Data() }
            DataRepresentation(exportedContentType: .fileURL) { _ in Data() }
            DataRepresentation(exportedContentType: .jpeg) { _ in Data() }
        }
    }
    struct Nine: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
            DataRepresentation(exportedContentType: .rtf) { _ in Data() }
            DataRepresentation(exportedContentType: .url) { _ in Data() }
            DataRepresentation(exportedContentType: .fileURL) { _ in Data() }
            DataRepresentation(exportedContentType: .jpeg) { _ in Data() }
            DataRepresentation(exportedContentType: .png) { _ in Data() }
        }
    }
    struct Ten: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
            DataRepresentation(exportedContentType: .rtf) { _ in Data() }
            DataRepresentation(exportedContentType: .url) { _ in Data() }
            DataRepresentation(exportedContentType: .fileURL) { _ in Data() }
            DataRepresentation(exportedContentType: .jpeg) { _ in Data() }
            DataRepresentation(exportedContentType: .png) { _ in Data() }
            DataRepresentation(exportedContentType: .image) { _ in Data() }
        }
    }
    precondition(Five.exportedContentTypes().count == 5)
    precondition(Six.exportedContentTypes().count == 6)
    precondition(Seven.exportedContentTypes().count == 7)
    precondition(Eight.exportedContentTypes().count == 8)
    precondition(Nine.exportedContentTypes().count == 9)
    precondition(Ten.exportedContentTypes().count == 10)
}

func testModifiersOnFileProxyCodableAndTuple() {
    let source = FileManager.default.temporaryDirectory
        .appendingPathComponent("ct-mod-\(UUID().uuidString).bin")
    try! Data("file-mod".utf8).write(to: source)
    let file = FileRepresentation<DepthFile>(
        contentType: .data,
        exporting: { SentTransferredFile($0.url) },
        importing: { DepthFile(url: $0.file) }
    )
    _ = file.visibility(.ownProcess)
    _ = file.suggestedFileName("clip.bin")
    _ = file.suggestedFileName { $0.url.lastPathComponent }
    _ = file.exportingCondition { _ in true }
    let namedFile = file.suggestedFileName("clip.bin")
    let sent = depthWait {
        try await namedFile._hostExportFile(DepthFile(url: source), contentType: .data)
    }
    precondition(sent.file.lastPathComponent == "clip.bin")

    let proxy = ProxyRepresentation<DepthProxy, String>(
        exporting: { $0.text },
        importing: { DepthProxy(text: $0) }
    )
    _ = proxy.visibility(.team)
    _ = proxy.suggestedFileName("proxy.txt")
    _ = proxy.suggestedFileName { $0.text + ".txt" }
    _ = proxy.exportingCondition { !$0.text.isEmpty }
    precondition(proxy.suggestedFileName("proxy.txt")._hostSuggestedFileName(
        DepthProxy(text: "n")
    ) == "proxy.txt")

    let codable = CodableRepresentation<DepthCodable, JSONEncoder, JSONDecoder>(
        contentType: .json
    )
    _ = codable.visibility(.all)
    _ = codable.suggestedFileName("note.json")
    _ = codable.suggestedFileName { $0.text + ".json" }
    _ = codable.exportingCondition { _ in true }
    precondition(
        DepthCodable(text: "c").suggestedFilename == nil
            || DepthCodable(text: "c").suggestedFilename != "missing"
    )

    let jpeg = DataRepresentation<DualPayload>(
        contentType: .jpeg,
        exporting: { Data("jpeg:\($0.text)".utf8) },
        importing: { DualPayload(text: String(data: $0, encoding: .utf8) ?? "") }
    )
    let png = DataRepresentation<DualPayload>(
        contentType: .png,
        exporting: { Data("png:\($0.text)".utf8) },
        importing: { DualPayload(text: String(data: $0, encoding: .utf8) ?? "") }
    )
    let tuple = TransferRepresentationBuilder<DualPayload>.buildBlock(jpeg, png)
    _ = tuple.visibility(.all)
    _ = tuple.suggestedFileName("dual.bin")
    _ = tuple.suggestedFileName { $0.text }
    _ = tuple.exportingCondition { _ in true }
    let named = tuple.suggestedFileName("dual.bin")
    precondition(named._hostSuggestedFileName(DualPayload(text: "n")) == "dual.bin")
}

func testRepresentationAssociatedTypesAndBody() {
    let _: Data.Representation = Data.transferRepresentation
    let dataBody: DataRepresentation<Data>.Body.Type = Never.self
    let fileBody: FileRepresentation<DepthFile>.Body.Type = Never.self
    let proxyBody: ProxyRepresentation<DepthProxy, String>.Body.Type = Never.self
    let codableBody: CodableRepresentation<
        DepthCodable, JSONEncoder, JSONDecoder
    >.Body.Type = Never.self
    precondition(dataBody == Never.self)
    precondition(fileBody == Never.self)
    precondition(proxyBody == Never.self)
    precondition(codableBody == Never.self)

    let item: DataRepresentation<DepthNote>.Item.Type = DepthNote.self
    precondition(item == DepthNote.self)

    let jpeg = DataRepresentation<DualPayload>(
        contentType: .jpeg,
        exporting: { Data("jpeg:\($0.text)".utf8) },
        importing: { DualPayload(text: String(data: $0, encoding: .utf8) ?? "") }
    )
    let png = DataRepresentation<DualPayload>(
        contentType: .png,
        exporting: { Data("png:\($0.text)".utf8) },
        importing: { DualPayload(text: String(data: $0, encoding: .utf8) ?? "") }
    )
    let tuple = TransferRepresentationBuilder<DualPayload>.buildBlock(jpeg, png)
    let forwarded = tuple.body
    let types = forwarded._hostExportedContentTypes(visibility: .all)
    precondition(types.contains { $0.identifier == "public.jpeg" })
    precondition(types.contains { $0.identifier == "public.png" })
    let exported = depthWait {
        try await forwarded._hostExportData(
            DualPayload(text: "body"),
            contentType: .image
        )
    }
    precondition(String(data: exported, encoding: .utf8) == "jpeg:body")
}

func testNeverProtocolWitnessesExist() {
    func swallow<T>(_ value: T) {
        _ = String(describing: type(of: value))
    }

    swallow(Never.exportedContentTypes(visibility:))
    swallow(\Never.suggestedFilename)
    swallow(\Never.body)
    let unreadTransfer: () -> Never = { Never.transferRepresentation }
    swallow(unreadTransfer)
    let fromData: (Data, UTType?) async throws -> Never =
        Never.init(importing:contentType:)
    swallow(fromData)
    let fromURL: (URL, UTType?) async throws -> Never =
        Never.init(importing:contentType:)
    swallow(fromURL)
    swallow(Never.exported(as:))
    swallow(Never.export(to:contentType:))
    swallow(Never.exportedContentTypes(_:))
    swallow(Never.importedContentTypes)
    swallow(Never.visibility(_:))
    swallow(Never.exportingCondition(_:))
}

func testProxyRepresentationChain() {
    let item = DepthProxy(text: "chain")
    let exported = depthWait { try await item.exported(as: .utf8PlainText) }
    precondition(String(data: exported, encoding: .utf8) == "chain")
    let imported = depthWait {
        try await DepthProxy(importing: exported, contentType: .utf8PlainText)
    }
    precondition(imported == item)
}
