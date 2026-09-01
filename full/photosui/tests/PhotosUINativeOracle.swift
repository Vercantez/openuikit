import PhotosUI
import SwiftUI

@main
private struct PhotosUINativeOracle {
    @MainActor
    static func main() {
        let filter = PHPickerFilter.any(of: [.images, .videos])
        precondition(filter == PHPickerFilter.any(of: [.images, .videos]))
        precondition(filter != .images)
        precondition(Set([filter, filter]).count == 1)

        let item = PhotosPickerItem(itemIdentifier: "native-item")
        precondition(item.itemIdentifier == "native-item")
        precondition(item.supportedContentTypes.isEmpty)
        let view = Text("Photos")
            .photosPicker(
                isPresented: .constant(false),
                selection: .constant([]),
                maxSelectionCount: 4,
                matching: filter
            )
        withExtendedLifetime(view) {}
        print(
            "PHOTOSUI_APPLE_OK filter=images,videos item=identified "
                + "modifier=multiple-selection"
        )
    }
}
