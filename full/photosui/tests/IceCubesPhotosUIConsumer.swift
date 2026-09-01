import PhotosUI
import SwiftUI

@MainActor
private struct IceCubesPhotosUIConsumer: View {
    @Binding var isPresented: Bool
    @Binding var items: [PhotosPickerItem]

    var body: some View {
        Text("Photos")
            .photosPicker(
                isPresented: $isPresented,
                selection: $items,
                maxSelectionCount: 4,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .automatic
            )
    }
}

private func loadIceCubesTransfer<T: Transferable>(
    from item: PhotosPickerItem,
    as type: T.Type
) async throws -> T? {
    try await item.loadTransferable(type: type)
}
