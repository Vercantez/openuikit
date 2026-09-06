import Foundation
import CoreTransferable

private struct ProviderNote: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .utf8PlainText) { note in
            Data(note.text.utf8)
        } importing: { data in
            ProviderNote(text: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

private struct ProviderFile: Transferable, Equatable, Sendable {
    var url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .data) { item in
            SentTransferredFile(item.url)
        } importing: { received in
            ProviderFile(url: received.file)
        }
    }
}

private struct ProviderProxy: Transferable, Equatable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { (item: ProviderProxy) in
            item.text
        } importing: { (text: String) in
            ProviderProxy(text: text)
        }
    }
}

private struct ProviderCodable: Transferable, Equatable, Codable, Sendable {
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: ProviderCodable.self, contentType: .json)
    }
}

private func loadExactly<T: Transferable>(_ provider: NSItemProvider, as type: T.Type) -> T {
    var loaded: T?
    var loadError: Error?
    let progress = provider.loadTransferable(type: type) { result in
        switch result {
        case .success(let value):
            loaded = value
        case .failure(let error):
            loadError = error
        }
    }
    precondition(progress.completedUnitCount == 1)
    precondition(progress.isFinished)
    if let loadError {
        preconditionFailure("loadTransferable failed: \(loadError)")
    }
    guard let loaded else {
        preconditionFailure("loadTransferable produced no value")
    }
    return loaded
}

func testItemProviderRegisterDataRoundTrip() {
    let provider = NSItemProvider()
    let payload = Data("item-provider-bytes".utf8)
    provider.register(payload)
    let loaded = loadExactly(provider, as: Data.self)
    precondition(loaded == payload)
    precondition(Data.exportedContentTypes().contains { $0.identifier == "public.data" })
}

func testItemProviderLoadFileProxyCodableRoundTrip() {
    let source = FileManager.default.temporaryDirectory
        .appendingPathComponent("ct-provider-\(UUID().uuidString).bin")
    try! Data("file-bytes".utf8).write(to: source)

    let fileProvider = NSItemProvider()
    fileProvider.register(ProviderFile(url: source))
    let loadedFile = loadExactly(fileProvider, as: ProviderFile.self)
    precondition(loadedFile.url == source)

    let proxyProvider = NSItemProvider()
    proxyProvider.register(ProviderProxy(text: "proxy-item"))
    let loadedProxy = loadExactly(proxyProvider, as: ProviderProxy.self)
    precondition(loadedProxy == ProviderProxy(text: "proxy-item"))

    let codableProvider = NSItemProvider()
    codableProvider.register(ProviderCodable(text: "codable-item"))
    let loadedCodable = loadExactly(codableProvider, as: ProviderCodable.self)
    precondition(loadedCodable == ProviderCodable(text: "codable-item"))
}

func testItemProviderStringURLAttributedStringRoundTrip() {
    let textProvider = NSItemProvider()
    textProvider.register("plain-item")
    precondition(loadExactly(textProvider, as: String.self) == "plain-item")

    let url = URL(string: "https://example.invalid/provider")!
    let urlProvider = NSItemProvider()
    urlProvider.register(url)
    precondition(loadExactly(urlProvider, as: URL.self) == url)

    let attributed = AttributedString("attributed-item")
    let richProvider = NSItemProvider()
    richProvider.register(attributed)
    let loaded = loadExactly(richProvider, as: AttributedString.self)
    precondition(String(loaded.characters) == "attributed-item")
}

func testItemProviderCustomDataRepresentationRoundTrip() {
    let provider = NSItemProvider()
    provider.register(ProviderNote(text: "note-item"))
    let loaded = loadExactly(provider, as: ProviderNote.self)
    precondition(loaded == ProviderNote(text: "note-item"))
}

func testItemProviderMissingTypeFailsClosed() {
    let provider = NSItemProvider()
    provider.register("only-string")
    var sawUnsupported = false
    let progress = provider.loadTransferable(type: Data.self) { result in
        switch result {
        case .success:
            preconditionFailure("missing type loaded as Data")
        case .failure(let error):
            guard let transferable = error as? TransferableError else {
                preconditionFailure("unexpected error \(error)")
            }
            precondition(
                transferable == .importNotSupported(contentType: "item-provider")
            )
            sawUnsupported = true
        }
    }
    precondition(sawUnsupported)
    precondition(progress.completedUnitCount == 1)
    precondition(progress.isFinished)
}

func testItemProviderAutoclosureIsEvaluated() {
    let provider = NSItemProvider()
    var evaluated = false
    func makeNote() -> ProviderNote {
        evaluated = true
        return ProviderNote(text: "auto")
    }
    provider.register(makeNote())
    precondition(evaluated)
    precondition(loadExactly(provider, as: ProviderNote.self).text == "auto")
}
