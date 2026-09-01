import CoreTransferable
import Foundation
import UniformTypeIdentifiers

private struct OracleDocument: Transferable {
    let bytes: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { document in
            document.bytes
        }
    }
}

private final class OracleMovie: Transferable, @unchecked Sendable {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            OracleMovie(url: received.file)
        }
        FileRepresentation(importedContentType: .video) { received in
            OracleMovie(url: received.file)
        }
    }
}

private func proveCoreTransferableSurface() {
    _ = OracleDocument.transferRepresentation
    _ = OracleMovie.transferRepresentation
}
