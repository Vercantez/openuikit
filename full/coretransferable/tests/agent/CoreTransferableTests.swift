import Dispatch
import Foundation
@_spi(OpenUIKitHost) import CoreTransferable

private enum TestBox<T>: @unchecked Sendable {
    case unset
    case value(T)
    case failure(Error)
}

private func waitFor<T>(_ work: @escaping @Sendable () async throws -> T) -> T {
    let semaphore = DispatchSemaphore(value: 0)
    let box = LockedBox<T>()
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
        preconditionFailure("async work failed: \(error)")
    case .unset:
        preconditionFailure("async work produced no result")
    }
}

private final class LockedBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: TestBox<T> = .unset

    func store(_ value: TestBox<T>) {
        lock.lock()
        storage = value
        lock.unlock()
    }

    func take() -> TestBox<T> {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

private struct Note: Transferable, Equatable, Codable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .utf8PlainText) { note in
            Data(note.text.utf8)
        } importing: { data in
            Note(text: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

private struct NamedNote: Transferable, Equatable, Sendable {
    var text: String
    var exportable: Bool

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .utf8PlainText) { note in
            Data(note.text.utf8)
        } importing: { data in
            NamedNote(
                text: String(data: data, encoding: .utf8) ?? "",
                exportable: true
            )
        }
        .exportingCondition { $0.exportable }
        .suggestedFileName("note.txt")
        .visibility(.all)
    }
}

private struct DualNote: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .utf8PlainText) { note in
            Data(note.text.utf8)
        } importing: { data in
            DualNote(text: String(data: data, encoding: .utf8) ?? "")
        }
        DataRepresentation(exportedContentType: .json) { note in
            Data(note.text.utf8)
        }
    }
}

private struct FileNote: Transferable, Equatable, Sendable {
    var url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .data) { note in
            SentTransferredFile(note.url)
        } importing: { received in
            FileNote(url: received.file)
        }
    }
}

private struct ProxyNote: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { (note: ProxyNote) in
            note.text
        } importing: { (text: String) in
            ProxyNote(text: text)
        }
    }
}

private struct CodableNote: Transferable, Equatable, Codable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: CodableNote.self, contentType: .json)
    }
}

func testTransferRepresentationVisibility() {
    precondition(TransferRepresentationVisibility.all == .all)
    precondition(TransferRepresentationVisibility.team == .team)
    precondition(TransferRepresentationVisibility.ownProcess == .ownProcess)
    precondition(TransferRepresentationVisibility.all != .team)
    precondition(TransferRepresentationVisibility.team != .ownProcess)
    precondition(!(TransferRepresentationVisibility.all != .all))
    var hasher = Hasher()
    TransferRepresentationVisibility.all.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDataRepresentationRoundTrip() {
    let representation = DataRepresentation<Note>(
        contentType: .utf8PlainText,
        exporting: { Data($0.text.utf8) },
        importing: { Note(text: String(data: $0, encoding: .utf8) ?? "") }
    )
    let exported = waitFor { try await representation._export(Note(text: "hello")) }
    precondition(exported == Data("hello".utf8))
    let imported = waitFor { try await representation._import(exported) }
    precondition(imported == Note(text: "hello"))
}

func testDataRepresentationExportOnlyFailsClosed() {
    let representation = DataRepresentation<Note>(
        exportedContentType: .data
    ) { note in
        Data(note.text.utf8)
    }
    let exported = waitFor { try await representation._export(Note(text: "x")) }
    precondition(exported == Data("x".utf8))
    waitFor {
        do {
            _ = try await representation._import(exported)
            preconditionFailure("export-only data representation imported")
        } catch let error as TransferableError {
            precondition(error == .importNotSupported(contentType: "public.data"))
        }
    }
}

func testDataRepresentationImportOnlyFailsClosed() {
    let representation = DataRepresentation<Note>(
        importedContentType: .data
    ) { data in
        Note(text: String(data: data, encoding: .utf8) ?? "")
    }
    waitFor {
        do {
            _ = try await representation._export(Note(text: "x"))
            preconditionFailure("import-only data representation exported")
        } catch let error as TransferableError {
            precondition(error == .exportNotSupported(contentType: "public.data"))
        }
    }
}

func testFileRepresentationRoundTrip() {
    let source = FileManager.default.temporaryDirectory
        .appendingPathComponent("ct-file-\(UUID().uuidString).bin")
    try! Data("movie".utf8).write(to: source)
    let representation = FileRepresentation<FileNote>(
        contentType: .data,
        shouldAttemptToOpenInPlace: true,
        exporting: { SentTransferredFile($0.url) },
        importing: { FileNote(url: $0.file) }
    )
    precondition(representation.shouldAttemptToOpenInPlace == true)
    let sent = waitFor { try await representation._export(FileNote(url: source)) }
    precondition(sent.file == source)
    precondition(sent.allowAccessingOriginalFile == false)
    let imported = waitFor {
        try await representation._import(
            ReceivedTransferredFile(file: source, isOriginalFile: false)
        )
    }
    precondition(imported.url == source)
}

func testFileRepresentationImportOnly() {
    let representation = FileRepresentation<FileNote>(
        importedContentType: .movie
    ) { received in
        FileNote(url: received.file)
    }
    precondition(representation.shouldAttemptToOpenInPlace == false)
    let url = URL(fileURLWithPath: "/tmp/openui-transfer.mov")
    let imported = waitFor {
        try await representation._import(
            ReceivedTransferredFile(file: url, isOriginalFile: false)
        )
    }
    precondition(imported.url == url)
    waitFor {
        do {
            _ = try await representation._export(FileNote(url: url))
            preconditionFailure("import-only file representation exported")
        } catch let error as TransferableError {
            precondition(error == .exportNotSupported(contentType: "public.movie"))
        }
    }
}

func testSentTransferredFileDefaults() {
    let url = URL(fileURLWithPath: "/tmp/payload.bin")
    let sent = SentTransferredFile(url)
    precondition(sent.file == url)
    precondition(sent.allowAccessingOriginalFile == false)
    let allowed = SentTransferredFile(url, allowAccessingOriginalFile: true)
    precondition(allowed.allowAccessingOriginalFile == true)
}

func testReceivedTransferredFileProperties() {
    let url = URL(fileURLWithPath: "/tmp/received.bin")
    let received = ReceivedTransferredFile(file: url, isOriginalFile: true)
    precondition(received.file == url)
    precondition(received.isOriginalFile == true)
}

func testProxyRepresentationRoundTrip() {
    let representation = ProxyRepresentation<ProxyNote, String>(
        exporting: { $0.text },
        importing: { ProxyNote(text: $0) }
    )
    let exported = waitFor {
        try await representation._hostExportData(
            ProxyNote(text: "proxy"),
            contentType: .utf8PlainText
        )
    }
    precondition(String(data: exported, encoding: .utf8) == "proxy")
    let imported = waitFor {
        try await representation._hostImportData(exported, contentType: .utf8PlainText)
    }
    precondition(imported == ProxyNote(text: "proxy"))
}

func testProxyRepresentationExportOnly() {
    let representation = ProxyRepresentation<ProxyNote, String>(
        exporting: { $0.text }
    )
    let exported = waitFor {
        try await representation._hostExportData(
            ProxyNote(text: "one-way"),
            contentType: .utf8PlainText
        )
    }
    precondition(String(data: exported, encoding: .utf8) == "one-way")
}

func testCodableRepresentationJSONRoundTrip() {
    let representation = CodableRepresentation<CodableNote, JSONEncoder, JSONDecoder>(
        for: CodableNote.self,
        contentType: .json
    )
    let note = CodableNote(text: "json")
    let data = waitFor {
        try await representation._hostExportData(note, contentType: .json)
    }
    let decoded = waitFor {
        try await representation._hostImportData(data, contentType: .json)
    }
    precondition(decoded == note)
    let inferred = CodableRepresentation<CodableNote, JSONEncoder, JSONDecoder>(
        contentType: .json
    )
    let again = waitFor {
        try await inferred._hostExportData(note, contentType: .json)
    }
    precondition(!again.isEmpty)
}

func testBuilderSingleAndTuple() {
    _ = Note.transferRepresentation
    _ = DualNote.transferRepresentation
    let types = DualNote.exportedContentTypes()
    precondition(types.contains { $0.identifier == "public.utf8-plain-text" })
    precondition(types.contains { $0.identifier == "public.json" })
}

func testBuilderFourRepresentations() {
    struct Quad: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .utf8PlainText) { _ in Data() }
            DataRepresentation(exportedContentType: .json) { _ in Data() }
            DataRepresentation(exportedContentType: .data) { _ in Data() }
            DataRepresentation(exportedContentType: .plainText) { _ in Data() }
        }
    }
    let types = Quad.exportedContentTypes()
    precondition(types.count == 4)
}

func testVisibilityModifierFilters() {
    struct Hidden: Transferable {
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .data) { _ in Data("x".utf8) }
                .visibility(.ownProcess)
        }
    }
    let all = Hidden.exportedContentTypes(visibility: .all)
    precondition(all.contains { $0.identifier == "public.data" })
    let own = Hidden.exportedContentTypes(visibility: .ownProcess)
    precondition(own.contains { $0.identifier == "public.data" })
    let team = Hidden.exportedContentTypes(visibility: .team)
    precondition(team.isEmpty)
}

func testSuggestedFileNameAndExportingCondition() {
    let allowed = NamedNote(text: "ok", exportable: true)
    precondition(allowed.suggestedFilename == "note.txt")
    let exported = waitFor { try await allowed.exported(as: .utf8PlainText) }
    precondition(exported == Data("ok".utf8))
    let blocked = NamedNote(text: "no", exportable: false)
    waitFor {
        do {
            _ = try await blocked.exported(as: .utf8PlainText)
            preconditionFailure("blocked export succeeded")
        } catch let error as TransferableError {
            precondition(
                error == .exportNotSupported(contentType: "public.utf8-plain-text")
                    || error == .exportNotSupported(contentType: "public.data")
            )
        }
    }
}

func testDataTransferableExportImport() {
    let payload = Data("portable-transfer".utf8)
    let exported = waitFor { try await payload.exported(as: .data) }
    precondition(exported == payload)
    let imported = waitFor { try await Data(importing: exported, contentType: .data) }
    precondition(imported == payload)
    precondition(Data.exportedContentTypes().contains { $0.identifier == "public.data" })
    precondition(payload.importedContentTypes().contains { $0.identifier == "public.data" })
    precondition(payload.suggestedFilename == nil)
}

func testStringTransferableExportImport() {
    let text = "hello transferable"
    let exported = waitFor { try await text.exported(as: .utf8PlainText) }
    precondition(String(data: exported, encoding: .utf8) == text)
    let imported = waitFor {
        try await String(importing: exported, contentType: .utf8PlainText)
    }
    precondition(imported == text)
}

func testURLTransferableExportImport() {
    let url = URL(string: "https://example.invalid/item")!
    let exported = waitFor { try await url.exported(as: .url) }
    let imported = waitFor { try await URL(importing: exported, contentType: .url) }
    precondition(imported == url)
}

func testAttributedStringTransferable() {
    let value = AttributedString("rich")
    let exported = waitFor { try await value.exported(as: .utf8PlainText) }
    precondition(String(data: exported, encoding: .utf8) == "rich")
    let imported = waitFor {
        try await AttributedString(importing: exported, contentType: .utf8PlainText)
    }
    precondition(String(imported.characters) == "rich")
}

func testExportToDirectoryAndWithExportedFile() {
    let note = Note(text: "disk")
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ct-export-\(UUID().uuidString)", isDirectory: true)
    let url = waitFor {
        try await note.export(to: directory, contentType: .utf8PlainText)
    }
    precondition(FileManager.default.fileExists(atPath: url.path))
    let bytes = waitFor {
        try await note.withExportedFile(contentType: .utf8PlainText) { file in
            try Data(contentsOf: file)
        }
    }
    precondition(bytes == Data("disk".utf8))
}

func testImportedContentTypesStaticAndInstance() {
    precondition(Note.importedContentTypes().contains { $0.identifier == "public.utf8-plain-text" })
    precondition(Note(text: "x").importedContentTypes().contains { $0.identifier == "public.utf8-plain-text" })
    precondition(Note.exportedContentTypes(visibility: .all).contains { $0.identifier == "public.utf8-plain-text" })
}

func testNeverTypeAliasesExist() {
    let representation: Never.Representation.Type = Never.self
    let item: Never.Item.Type = Never.self
    let body: Never.Body.Type = Never.self
    precondition(representation == Never.self)
    precondition(item == Never.self)
    precondition(body == Never.self)
}

func testFileRepresentationExportOnlyInit() {
    let representation = FileRepresentation<FileNote>(
        exportedContentType: .data,
        shouldAllowToOpenInPlace: true
    ) { note in
        SentTransferredFile(note.url, allowAccessingOriginalFile: true)
    }
    precondition(representation.shouldAttemptToOpenInPlace == true)
}

func testProxyThrowingOverloads() {
    let both = ProxyRepresentation<ProxyNote, String>(
        exporting: { (note: ProxyNote) throws in note.text },
        importing: { (text: String) throws in ProxyNote(text: text) }
    )
    let exported = waitFor {
        try await both._hostExportData(ProxyNote(text: "t"), contentType: .utf8PlainText)
    }
    precondition(!exported.isEmpty)
    let exportOnly = ProxyRepresentation<ProxyNote, String>(
        exporting: { (note: ProxyNote) throws in note.text }
    )
    _ = exportOnly
    let importOnly = ProxyRepresentation<ProxyNote, String>(
        importing: { (text: String) throws in ProxyNote(text: text) }
    )
    _ = importOnly
}

func testSuggestedFileNameClosure() {
    struct Named: Transferable {
        var title: String
        static var transferRepresentation: some TransferRepresentation {
            DataRepresentation(exportedContentType: .data) { _ in Data("x".utf8) }
                .suggestedFileName { $0.title }
        }
    }
    precondition(Named(title: "doc.bin").suggestedFilename == "doc.bin")
}

func testInitImportingFromFile() {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("ct-import-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let file = directory.appendingPathComponent("n.txt")
    try! Data("from-file".utf8).write(to: file)
    let note = waitFor { try await Note(importing: file, contentType: .utf8PlainText) }
    precondition(note.text == "from-file")
}

func testTransferableErrorEquatable() {
    precondition(
        TransferableError.exportNotSupported(contentType: "public.data")
            == .exportNotSupported(contentType: "public.data")
    )
    precondition(
        TransferableError.importNotSupported(contentType: "public.data")
            != .exportNotSupported(contentType: "public.data")
    )
}
