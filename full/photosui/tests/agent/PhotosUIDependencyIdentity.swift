import Foundation
@_spi(OpenUIKitHost)
import PhotosUI

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation
/// values through public PhotosUI APIs; this file is not compiled by the
/// sealed host gate.
func photosUIDependencyIdentityProbe() {
    let configuration = PHPickerConfiguration()
    precondition(configuration.selectionLimit == 1)
    precondition(configuration.mode == .default)
    precondition(configuration.preferredAssetRepresentationMode == .automatic)
    precondition(configuration.filter == nil)
    precondition(configuration.preselectedAssetIdentifiers.isEmpty)

    let withLibrary = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared)
    precondition(withLibrary.selectionLimit == 1)

    let filter = PHPickerFilter.any(of: [.images, .videos])
    precondition(filter == PHPickerFilter.any(of: [.images, .videos]))

    let item = PhotosPickerItem(itemIdentifier: "identity")
    precondition(item.itemIdentifier == "identity")
    precondition(item.supportedContentTypes.isEmpty)

    let provider = NSItemProvider()
    let result = PHPickerResult(itemProvider: provider, assetIdentifier: "identity")
    precondition(result.assetIdentifier == "identity")
    precondition(result.itemProvider === provider)

    _ = PHPickerCapabilities.search
    _ = PhotosPickerSelectionBehavior.default
    _ = PhotosPickerStyle.presentation
    _ = Foundation.Progress.self
    _ = Foundation.Date.self
}
