@_spi(OpenUIKitHost) import Photos
import Foundation

func photosWait(_ body: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await body()
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success)
}

func testAuthorizationFailClosed() {
    PHPhotoLibraryPortable._reset()
    precondition(PHPhotoLibrary.authorizationStatus(for: .readWrite) == .notDetermined)
    precondition(PHPhotoLibrary.authorizationStatus() == .notDetermined)
    photosWait {
        let denied = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        precondition(denied == .denied)
        precondition(PHPhotoLibrary.authorizationStatus(for: .readWrite) == .denied)
        precondition(PHAsset.fetchAssets(with: .image, options: nil).count == 0)
    }
}

func testHostDrivenAuthorizationAndFetch() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._installAuthorizationHandler { level in
        level == .readWrite ? .limited : .authorized
    }
    photosWait {
        let limited = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        precondition(limited == .limited)
    }

    let older = PHAsset(
        localIdentifier: "older",
        mediaType: .image,
        creationDate: Date(timeIntervalSince1970: 1),
        data: Data("older".utf8),
        image: UIImage()
    )
    let newer = PHAsset(
        localIdentifier: "newer",
        mediaType: .image,
        creationDate: Date(timeIntervalSince1970: 2),
        data: Data("newer".utf8),
        image: UIImage()
    )
    PHPhotoLibraryPortable._installAssets([older, newer])

    let options = PHFetchOptions()
    options.hostSortsByCreationDateAscending = false
    options.fetchLimit = 1
    let result = PHAsset.fetchAssets(with: .image, options: options)
    precondition(result.count == 1)
    precondition(result[0].localIdentifier == "newer")
    precondition(result.firstObject?.localIdentifier == "newer")
    precondition(result.contains(newer))
    precondition(result.index(of: newer) != NSNotFound)
    precondition(result.object(at: 0).localIdentifier == "newer")

    let byIdentifier = PHAsset.fetchAssets(
        withLocalIdentifiers: ["older"],
        options: nil
    )
    precondition(byIdentifier.count == 1)
    precondition(byIdentifier[0].localIdentifier == "older")
}

func testImageDataAndThumbnail() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._installAuthorizationHandler { _ in .authorized }
    photosWait {
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    let image = UIImage()
    let asset = PHAsset(
        localIdentifier: "img",
        mediaType: .image,
        creationDate: Date(),
        data: Data("payload".utf8),
        image: image
    )
    PHPhotoLibraryPortable._installAssets([asset])
    let fetched = PHAsset.fetchAssets(with: .image, options: nil)[0]

    var data: Data?
    let dataRequest = PHImageManager.default().requestImageDataAndOrientation(
        for: fetched,
        options: nil
    ) { value, _, orientation, _ in
        data = value
        precondition(orientation == .up)
    }
    precondition(dataRequest > PHInvalidImageRequestID)
    precondition(data == Data("payload".utf8))

    var deliveredImage = false
    let imageRequest = PHImageManager.default().requestImage(
        for: fetched,
        targetSize: CGSize(width: 1, height: 1),
        contentMode: .aspectFill,
        options: PHImageRequestOptions()
    ) { value, _ in
        deliveredImage = value != nil
    }
    precondition(imageRequest > dataRequest)
    precondition(deliveredImage)
}

func testEnumRawValues() {
    precondition(PHAccessLevel.addOnly.rawValue == 1)
    precondition(PHAccessLevel.readWrite.rawValue == 2)
    precondition(PHAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(PHAuthorizationStatus.restricted.rawValue == 1)
    precondition(PHAuthorizationStatus.denied.rawValue == 2)
    precondition(PHAuthorizationStatus.authorized.rawValue == 3)
    precondition(PHAuthorizationStatus.limited.rawValue == 4)
    precondition(PHAssetMediaType.unknown.rawValue == 0)
    precondition(PHAssetMediaType.image.rawValue == 1)
    precondition(PHAssetMediaType.video.rawValue == 2)
    precondition(PHAssetMediaType.audio.rawValue == 3)
    precondition(PHImageContentMode.aspectFit.rawValue == 0)
    precondition(PHImageContentMode.aspectFill.rawValue == 1)
    precondition(PHImageContentMode.default == .aspectFit)
    precondition(PHImageRequestOptionsDeliveryMode.opportunistic.rawValue == 0)
    precondition(PHImageRequestOptionsDeliveryMode.highQualityFormat.rawValue == 1)
    precondition(PHImageRequestOptionsDeliveryMode.fastFormat.rawValue == 2)
    precondition(PHImageRequestOptionsResizeMode.none.rawValue == 0)
    precondition(PHImageRequestOptionsResizeMode.fast.rawValue == 1)
    precondition(PHImageRequestOptionsResizeMode.exact.rawValue == 2)
    precondition(PHImageRequestOptionsVersion.current.rawValue == 0)
    precondition(PHAssetCollectionType.album.rawValue == 1)
    precondition(PHAssetCollectionSubtype.albumRegular.rawValue == 2)
    precondition(PHAssetCollectionSubtype.any.rawValue == 9223372036854775807)
    precondition(PHAssetResourceType.photo.rawValue == 1)
    precondition(PHAssetResourceType.photoProxy.rawValue == 19)
    precondition(PHObjectType.asset.rawValue == 1)
    precondition(PHAsset.PlaybackStyle.image.rawValue == 1)
}

func testOptionSets() {
    var subtypes: PHAssetMediaSubtype = [.photoLive, .photoHDR]
    precondition(subtypes.contains(.photoLive))
    precondition(subtypes.contains(.photoHDR))
    subtypes.remove(.photoHDR)
    precondition(subtypes.contains(.photoHDR) == false)
    precondition(PHAssetBurstSelectionType.autoPick.rawValue == 1)
    precondition(PHAssetBurstSelectionType.userPick.rawValue == 2)
    precondition(PHAssetSourceType.typeUserLibrary.rawValue == 1)
    precondition(PHAssetSourceType.typeCloudShared.rawValue == 2)
    precondition(PHAssetMediaSubtype.spatialMedia.rawValue == 1 << 10)
}

func testFetchResultEnumeration() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._installAuthorizationHandler { _ in .authorized }
    photosWait {
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    let first = PHAsset(localIdentifier: "a", mediaType: .image, data: Data("a".utf8))
    let second = PHAsset(localIdentifier: "b", mediaType: .video)
    PHPhotoLibraryPortable._installAssets([first, second])
    let all = PHAsset.fetchAssets(with: nil as PHFetchOptions?)
    precondition(all.count == 2)
    var seen: [String] = []
    all.enumerateObjects { asset, _, _ in
        seen.append(asset.localIdentifier)
    }
    precondition(seen == ["a", "b"])
    precondition(all.countOfAssets(with: .image) == 1)
    precondition(all.countOfAssets(with: .video) == 1)
    let slice = all.objects(at: IndexSet(integer: 1))
    precondition(slice.count == 1)
    precondition(slice[0].localIdentifier == "b")
}

func testPhotosErrorCodes() {
    PHPhotoLibraryPortable._reset()
    precondition(PHPhotosErrorDomain == "PHPhotosErrorDomain")
    precondition(PHPhotosError.Code.internalError.rawValue == -1)
    precondition(PHPhotosError.Code.userCancelled.rawValue == 3072)
    precondition(PHPhotosError.Code.accessUserDenied.rawValue == 3311)
    precondition(PHPhotosError.Code.changeNotSupported.rawValue == 3300)
    precondition(PHPhotosErrorUserCancelled == 3072)
    precondition(PHPhotosErrorLibraryVolumeOffline == 3114)
    let error = PHPhotosError(.changeNotSupported)
    precondition(error.code == .changeNotSupported)
    precondition(error.errorCode == 3300)
    precondition(PHPhotosError.errorDomain == PHPhotosErrorDomain)
    do {
        try PHPhotoLibrary.shared().performChangesAndWait {}
        precondition(false, "performChangesAndWait must fail closed")
    } catch {
        let photosError = error as? PHPhotosError
        precondition(photosError?.code == .accessUserDenied)
    }
}

func testCollectionsTransientAndEmpty() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._installAuthorizationHandler { _ in .authorized }
    photosWait {
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    let asset = PHAsset(localIdentifier: "c", mediaType: .image, data: Data("c".utf8))
    PHPhotoLibraryPortable._installAssets([asset])
    let transient = PHAssetCollection.transientAssetCollection(
        with: [asset],
        title: "Transient"
    )
    precondition(transient.localizedTitle == "Transient")
    precondition(transient.canContainAssets)
    precondition(transient.assetCollectionType == .album)
    let fetched = PHAsset.fetchAssets(in: transient, options: nil)
    precondition(fetched.count == 1)
    let smart = PHAssetCollection.fetchAssetCollections(
        with: .smartAlbum,
        subtype: .any,
        options: nil
    )
    precondition(smart.count == 21)
    let recents = PHAssetCollection.fetchAssetCollections(
        with: .smartAlbum,
        subtype: .smartAlbumUserLibrary,
        options: nil
    )
    precondition(recents.count == 1)
    precondition(recents[0].localizedTitle == "Recents")
    _ = recents[0].assetCollectionSubtype
    _ = recents[0].estimatedAssetCount
    _ = recents[0].startDate
    _ = recents[0].endDate
    _ = recents[0].localizedLocationNames
    precondition(PHAsset.fetchAssets(in: recents[0], options: nil).count == 1)
    let list = PHCollectionList.transientCollectionList(with: [transient], title: "Folder")
    precondition(list.canContainCollections)
    precondition(list.collectionListType == .folder)
}

func testChangeRequestsAreLocalOnly() {
    let image = UIImage()
    let created = PHAssetChangeRequest.creationRequestForAsset(from: image)
    precondition(created.placeholderForCreatedAsset != nil)
    precondition(PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: "/tmp/missing.jpg")) == nil)
    let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Album")
    precondition(album.title == "Album")
    precondition(PHAssetCreationRequest.supportsAssetResourceTypes([]) == false)
}

func testImageRequestOptionsAndConstants() {
    let options = PHImageRequestOptions()
    precondition(options.deliveryMode == .opportunistic)
    precondition(options.resizeMode == .fast)
    precondition(options.isSynchronous == false)
    precondition(options.version == .current)
    precondition(PHInvalidImageRequestID == 0)
    precondition(PHLivePhotoRequestIDInvalid == 0)
    precondition(PHImageManagerMaximumSize.width > 0)
    precondition(PHImageCancelledKey == "PHImageCancelledKey")
    let live = PHLivePhotoRequestOptions()
    precondition(live.deliveryMode == .opportunistic)
    let video = PHVideoRequestOptions()
    precondition(video.deliveryMode == .automatic)
}

func testCloudIdentifierMappingsFailClosed() {
    let mappings = PHPhotoLibrary.shared().cloudIdentifierMappings(
        forLocalIdentifiers: ["missing"]
    )
    precondition(mappings.count == 1)
    switch mappings["missing"] {
    case .failure(let error):
        precondition((error as? PHPhotosError)?.code == .identifierNotFound)
    default:
        precondition(false, "expected identifierNotFound")
    }
    let cloud = PHCloudIdentifier(stringValue: "cloud-1")
    precondition(cloud.stringValue == "cloud-1")
    let reverse = PHPhotoLibrary.shared().localIdentifierMappings(for: [cloud])
    switch reverse[cloud] {
    case .failure(let error):
        precondition((error as? PHPhotosError)?.code == .identifierNotFound)
    default:
        precondition(false, "expected identifierNotFound")
    }
}

func testResourceManagerFailClosed() {
    PHPhotoLibraryPortable._reset()
    let empty = PHAssetResource.assetResources(
        for: PHAsset(localIdentifier: "none", mediaType: .image)
    )
    precondition(empty.isEmpty)
    PHPhotoLibraryPortable._installAuthorizationHandler { _ in .authorized }
    photosWait {
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    let asset = PHAsset(
        localIdentifier: "res",
        mediaType: .image,
        data: Data("x".utf8)
    )
    PHPhotoLibraryPortable._installAssets([asset])
    let resources = PHAssetResource.assetResources(for: asset)
    precondition(resources.count == 1)
    precondition(resources[0].type == .photo)
    var received = false
    var completionError: (any Error)?
    var payload: Data?
    _ = PHAssetResourceManager.default().requestData(
        for: resources[0],
        options: nil,
        dataReceivedHandler: {
            received = true
            payload = $0
        },
        completionHandler: { completionError = $0 }
    )
    precondition(received)
    precondition(payload == Data("x".utf8))
    precondition(completionError == nil)
}

func testCachingImageManagerNoOps() {
    let manager = PHCachingImageManager()
    precondition(manager.allowsCachingHighQualityImages)
    manager.startCachingImages(
        for: [],
        targetSize: .zero,
        contentMode: .aspectFit,
        options: nil
    )
    manager.stopCachingImagesForAllAssets()
    PHImageManager.default().cancelImageRequest(PHInvalidImageRequestID)
}

func testAdjustmentAndEditingTypes() {
    let data = PHAdjustmentData(
        formatIdentifier: "fmt",
        formatVersion: "1.0",
        data: Data("adj".utf8)
    )
    precondition(data.formatIdentifier == "fmt")
    precondition(data.formatVersion == "1.0")
    precondition(data.data == Data("adj".utf8))
    let input = PHContentEditingInput()
    input.mediaType = .image
    let output = PHContentEditingOutput(contentEditingInput: input)
    precondition(output.renderedContentURL.isFileURL)
    let options = PHContentEditingInputRequestOptions()
    precondition(options.isNetworkAccessAllowed == false)
    precondition(options.canHandleAdjustmentData(data) == false)
    let asset = PHAsset(localIdentifier: "edit", mediaType: .image)
    asset.cancelContentEditingInputRequest(0)
    _ = asset.requestContentEditingInput(with: options) { _, _ in }
    _ = PHAssetCollection.fetchMoments(with: nil)
    _ = PHAssetCollection.fetchMoments(
        inMomentList: PHCollectionList.transientCollectionList(with: [], title: nil),
        options: nil
    )
}
