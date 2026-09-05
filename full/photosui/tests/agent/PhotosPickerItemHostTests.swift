import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private struct HostDocument: Transferable, Equatable {
    let bytes: Data
}

private final class TransferBox: @unchecked Sendable {
    var document: HostDocument?
    var error: Error?
}

func testPhotosPickerItemHostProviderLoad() {
    let payload = HostDocument(bytes: Data("picker-item".utf8))
    let item = PhotosPickerItem(
        itemIdentifier: "host-item",
        supportedContentTypes: [.jpeg, .image]
    )
    item._installTransferable(payload)
    precondition(item.itemIdentifier == "host-item")
    precondition(item.supportedContentTypes == [.jpeg, .image])

    let box = TransferBox()
    let progress = item.loadTransferable(type: HostDocument.self) { result in
        switch result {
        case .success(let document):
            box.document = document
        case .failure(let error):
            box.error = error
        }
    }
    precondition(progress.isFinished)
    precondition(box.error == nil)
    precondition(box.document == payload)
}

func testPhotosPickerItemHostProviderMissing() {
    let item = PhotosPickerItem(itemIdentifier: "empty")
    let box = TransferBox()
    let progress = item.loadTransferable(type: HostDocument.self) { result in
        box.document = try? result.get()
    }
    precondition(progress.isFinished)
    precondition(box.document == nil)
    precondition(item.supportedContentTypes.isEmpty)
}

func testPhotosPickerItemLoadTransferableThrows() {
    let payload = HostDocument(bytes: Data("inline".utf8))
    let item = PhotosPickerItem(
        itemIdentifier: "inline-item",
        supportedContentTypes: [.jpeg]
    )
    item._installTransferable(payload)
    let loaded = try? item.loadTransferable(type: HostDocument.self)
    precondition(loaded == payload)

    let missing = PhotosPickerItem(itemIdentifier: "missing")
    let empty = try? missing.loadTransferable(type: HostDocument.self)
    precondition(empty == nil)
}
