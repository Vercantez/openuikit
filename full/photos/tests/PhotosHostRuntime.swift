@_spi(OpenUIKitHost) import Photos
import Foundation

@main
private struct PhotosHostRuntime {
    static func main() async {
        PHPhotoLibraryPortable._reset()
        precondition(
            PHPhotoLibrary.authorizationStatus(for: .readWrite)
                == .notDetermined
        )
        let denied = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        precondition(denied == .denied)
        precondition(PHAsset.fetchAssets(with: .image, options: nil).count == 0)

        PHPhotoLibraryPortable._reset()
        PHPhotoLibraryPortable._installAuthorizationHandler { level in
            level == .readWrite ? .limited : .authorized
        }
        let limited = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        precondition(limited == .limited)

        let image = UIImage()
        let older = PHAsset(
            localIdentifier: "older",
            mediaType: .image,
            creationDate: Date(timeIntervalSince1970: 1),
            data: Data("older".utf8),
            image: image
        )
        let newer = PHAsset(
            localIdentifier: "newer",
            mediaType: .image,
            creationDate: Date(timeIntervalSince1970: 2),
            data: Data("newer".utf8),
            image: image
        )
        PHPhotoLibraryPortable._installAssets([older, newer])

        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        options.fetchLimit = 1
        let result = PHAsset.fetchAssets(with: .image, options: options)
        precondition(result.count == 1)
        precondition(result[0].localIdentifier == "newer")

        var data: Data?
        let dataRequest = PHImageManager.default().requestImageDataAndOrientation(
            for: result[0],
            options: nil
        ) { value, _, orientation, _ in
            data = value
            precondition(orientation == .up)
        }
        precondition(dataRequest > 0)
        precondition(data == Data("newer".utf8))

        var deliveredImage = false
        let imageRequest = PHImageManager.default().requestImage(
            for: result[0],
            targetSize: CGSize(width: 1, height: 1),
            contentMode: .aspectFill,
            options: PHImageRequestOptions()
        ) { value, _ in
            deliveredImage = value != nil
        }
        precondition(imageRequest > dataRequest)
        precondition(deliveredImage)

        PHPhotoLibraryPortable._reset()
        print(
            "PHOTOS_HOST_OK authorization=fail-closed,host-driven "
                + "assets=volatile fetch=filtered,sorted,limited "
                + "image=data,thumbnail"
        )
    }
}
