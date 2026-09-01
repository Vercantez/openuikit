@_spi(OpenUIKitHost) import CoreTransferable
import Foundation
import UniformTypeIdentifiers

private struct Document: Transferable {
    let bytes: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) { item in
            item.bytes
        }
    }
}

private struct ImportedFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            ImportedFile(url: received.file)
        }
        FileRepresentation(importedContentType: .video) { received in
            ImportedFile(url: received.file)
        }
    }
}

@main
private struct CoreTransferableHostRuntime {
    static func main() async throws {
        let dataRepresentation = DataRepresentation<Document>(
            exportedContentType: .data
        ) { item in
            item.bytes
        }
        let payload = Data("portable-transfer".utf8)
        let exported = try await dataRepresentation._export(
            Document(bytes: payload)
        )
        precondition(exported == payload)
        do {
            _ = try await dataRepresentation._import(payload)
            preconditionFailure("export-only data representation imported")
        } catch let error as TransferableError {
            precondition(error == .importNotSupported(contentType: "public.data"))
        }

        let fileRepresentation = FileRepresentation<ImportedFile>(
            importedContentType: .movie
        ) { received in
            ImportedFile(url: received.file)
        }
        let url = URL(fileURLWithPath: "/tmp/openui-transfer.mov")
        let imported = try await fileRepresentation._import(
            ReceivedTransferredFile(file: url, isOriginalFile: false)
        )
        precondition(imported.url == url)
        precondition(fileRepresentation.shouldAttemptToOpenInPlace == false)

        _ = Document.transferRepresentation
        _ = ImportedFile.transferRepresentation
        print(
            "CORETRANSFERABLE_HOST_OK data=export file=import "
                + "multi-representation=builder unsupported=fail-closed"
        )
    }
}
