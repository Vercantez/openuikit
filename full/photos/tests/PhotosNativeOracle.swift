import Photos
import UIKit

private func provePhotosSurface(asset: PHAsset) async {
    var status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    if status == .notDetermined {
        status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    _ = status == .authorized || status == .limited

    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [
        NSSortDescriptor(key: "creationDate", ascending: false)
    ]
    fetchOptions.fetchLimit = 20
    let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    assets.enumerateObjects { _, _, _ in }

    let imageOptions = PHImageRequestOptions()
    imageOptions.isNetworkAccessAllowed = true
    imageOptions.deliveryMode = .highQualityFormat
    imageOptions.resizeMode = .exact
    imageOptions.isSynchronous = false
    PHImageManager.default().requestImageDataAndOrientation(
        for: asset,
        options: imageOptions
    ) { _, _, _, _ in }
    PHImageManager.default().requestImage(
        for: asset,
        targetSize: CGSize(width: 1, height: 1),
        contentMode: .aspectFill,
        options: imageOptions
    ) { _, _ in }
}
