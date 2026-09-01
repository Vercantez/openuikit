@_spi(OpenUIKitHost) import _PhotosUI_SwiftUI
import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

private struct PickedDocument: Transferable, Equatable {
    let bytes: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) { item in
            item.bytes
        }
    }
}

private final class CompletionRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: PickedDocument?

    func store(_ document: PickedDocument?) {
        lock.withLock { stored = document }
    }

    var document: PickedDocument? { lock.withLock { stored } }
}

@MainActor
private final class PresentationRecorder {
    var events: [PhotosUIPortable.Event] = []
    var selection: [PhotosPickerItem] = []
    var dismissed = false
}

@main
private struct PhotosUIHostRuntime {
    @MainActor
    static func main() async throws {
        let filter = PHPickerFilter.any(of: [.images, .videos])
        precondition(filter._matches([.jpeg]))
        precondition(filter._matches([.movie]))
        precondition(!PHPickerFilter.images._matches([.movie]))
        precondition(
            PHPickerFilter.all(of: [.images, .not(.videos)])
                ._matches([.jpeg])
        )

        let payload = PickedDocument(bytes: Data("picked".utf8))
        let first = PhotosPickerItem(
            itemIdentifier: "first",
            supportedContentTypes: [.data]
        )
        first._installTransferable(payload)
        let second = PhotosPickerItem(itemIdentifier: "second")
        let third = PhotosPickerItem(itemIdentifier: "third")
        precondition(first.itemIdentifier == "first")
        precondition(first.supportedContentTypes == [.data])
        let loaded = try await first.loadTransferable(type: PickedDocument.self)
        let missing = try await second.loadTransferable(type: PickedDocument.self)
        precondition(loaded == payload)
        precondition(missing == nil)

        let completion = CompletionRecorder()
        let progress = first.loadTransferable(type: PickedDocument.self) { result in
            completion.store(try? result.get())
        }
        precondition(progress.isFinished)
        precondition(completion.document == payload)

        PhotosUIPortable._reset()
        precondition(!PhotosUIPortable.supportsSystemPicker)
        precondition(
            !PhotosUIPortable._requestPresentation(
                maxSelectionCount: 2,
                filter: filter,
                selection: { _ in },
                dismissal: {}
            )
        )

        let recorder = PresentationRecorder()
        PhotosUIPortable._installEventHandler { recorder.events.append($0) }
        precondition(PhotosUIPortable.supportsSystemPicker)
        precondition(
            PhotosUIPortable._requestPresentation(
                maxSelectionCount: 2,
                filter: filter,
                selection: { recorder.selection = $0 },
                dismissal: { recorder.dismissed = true }
            )
        )
        precondition(recorder.events == [.present(maxSelectionCount: 2, filter: filter)])
        PhotosUIPortable._hostDidSelect([first, second, third])
        precondition(recorder.selection == [first, second])
        precondition(recorder.dismissed)
        precondition(recorder.events.last == .dismiss)

        var isPresented = false
        var selected: [PhotosPickerItem] = []
        let view = Text("Photos")
            .photosPicker(
                isPresented: Binding(
                    get: { isPresented },
                    set: { isPresented = $0 }
                ),
                selection: Binding(
                    get: { selected },
                    set: { selected = $0 }
                ),
                maxSelectionCount: 4,
                matching: filter
            )
        withExtendedLifetime(view) {}
        PhotosUIPortable._reset()

        print(
            "PHOTOSUI_HOST_OK filter=images,videos transfer=typed,async,completion "
                + "presentation=fail-closed,host-driven selection=bounded,binding"
        )
    }
}
