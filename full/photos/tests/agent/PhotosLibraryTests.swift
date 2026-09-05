@_spi(OpenUIKitHost) import Photos
import Foundation

private let photosProbePNG = Data([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0xF7, 0x03, 0x41, 0x43, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
])

func photosAuthorizeReadWrite() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._installAuthorizationHandler { _ in .authorized }
    photosWait {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        precondition(status == .authorized)
    }
}

private func photosProbePNGFile() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-photos-probe.png")
    try! photosProbePNG.write(to: url)
    return url
}

private final class PhotosTestObserver: NSObject, PHPhotoLibraryChangeObserver {
    let lock = NSLock()
    var lastChange: PHChange?
    let semaphore = DispatchSemaphore(value: 0)

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        lock.lock()
        lastChange = changeInstance
        lock.unlock()
        semaphore.signal()
    }
}

func testOnDiskLibraryCreateFromFile() {
    photosAuthorizeReadWrite()
    let fileURL = photosProbePNGFile()
    var placeholder: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
        placeholder = request?.placeholderForCreatedAsset?.localIdentifier
    }
    precondition(placeholder != nil)
    let fetched = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder!], options: nil)
    precondition(fetched.count == 1)
    let asset = fetched[0]
    precondition(asset.mediaType == .image)
    precondition(asset.pixelWidth == 1)
    precondition(asset.pixelHeight == 1)
    precondition(asset.isFavorite == false)
    precondition(asset.isHidden == false)
    precondition(asset.duration == 0)
    precondition(asset.canPerform(.properties))
    precondition(asset.playbackStyle == .image)
    precondition(asset.sourceType.contains(.typeUserLibrary))
    precondition(asset.originalFilename.hasSuffix(".png"))
    _ = asset.addedDate
    _ = asset.modificationDate
    _ = asset.burstIdentifier
    _ = asset.burstSelectionTypes
    _ = asset.hasAdjustments
    _ = asset.representsBurst
    _ = asset.adjustmentFormatIdentifier
    _ = asset.mediaSubtypes

    var data: Data?
    var uti: String?
    var info: [AnyHashable: Any]?
    _ = PHImageManager.default().requestImageDataAndOrientation(
        for: asset,
        options: nil
    ) { value, type, orientation, payload in
        data = value
        uti = type
        info = payload
        precondition(orientation == .up)
    }
    precondition(data == photosProbePNG)
    precondition(uti == "public.png")
    precondition(info?[PHImageResultIsDegradedKey] as? Bool == false)
    precondition(info?[PHImageResultIsInCloudKey] as? Bool == false)
    precondition(info?[PHImageResultRequestIDKey] as? PHImageRequestID != nil)

    var image: UIImage?
    var imageInfo: [AnyHashable: Any]?
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = false
    options.version = .current
    _ = PHImageManager.default().requestImage(
        for: asset,
        targetSize: PHImageManagerMaximumSize,
        contentMode: .aspectFit,
        options: options
    ) { value, payload in
        image = value
        imageInfo = payload
    }
    if image == nil {
        precondition(imageInfo?[PHImageErrorKey] != nil)
    }

    let resources = PHAssetResource.assetResources(for: asset)
    precondition(resources.count == 1)
    precondition(resources[0].pixelWidth == 1)
    precondition(resources[0].pixelHeight == 1)
    let dest = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-photos-written.png")
    photosWait {
        do {
            try await PHAssetResourceManager.default().writeData(
                for: resources[0],
                toFile: dest,
                options: PHAssetResourceRequestOptions()
            )
        } catch {
            precondition(false, "writeData failed: \(error)")
        }
    }
    precondition(try! Data(contentsOf: dest) == photosProbePNG)
}

func testPerformChangesFavoriteDeleteAndAlbum() {
    photosAuthorizeReadWrite()
    var assetID: String?
    var albumID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let created = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
        assetID = created.placeholderForCreatedAsset?.localIdentifier
        let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
            withTitle: "Album"
        )
        albumID = album.placeholderForCreatedAssetCollection.localIdentifier
    }
    precondition(assetID != nil)
    precondition(albumID != nil)
    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetID!], options: nil)[0]
    _ = PHAssetChangeRequest(forAsset: asset)
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHAssetChangeRequest(for: asset)
        change.isFavorite = true
        change.revertAssetContentToOriginal()
        _ = change.contentEditingOutput
        let album = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumID!],
            options: nil
        )[0]
        let albumChange = PHAssetCollectionChangeRequest(for: album)
        albumChange?.addAssets([asset])
        albumChange?.title = "Renamed"
    }
    let favorites = PHAssetCollection.fetchAssetCollections(
        with: .smartAlbum,
        subtype: .smartAlbumFavorites,
        options: nil
    )[0]
    precondition(PHAsset.fetchAssets(in: favorites, options: nil).count == 1)
    let renamed = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    precondition(renamed.localizedTitle == "Renamed")
    precondition(PHAsset.fetchAssets(in: renamed, options: nil).count == 1)
    let containing = PHAssetCollection.fetchAssetCollectionsContaining(
        PHAsset.fetchAssets(withLocalIdentifiers: [assetID!], options: nil)[0],
        with: .album,
        options: nil
    )
    precondition(containing.count == 1)

    try! PHPhotoLibrary.shared().performChangesAndWait {
        PHAssetChangeRequest.deleteAssets([
            PHAsset.fetchAssets(withLocalIdentifiers: [assetID!], options: nil)[0]
        ])
    }
    precondition(PHAsset.fetchAssets(withLocalIdentifiers: [assetID!], options: nil).count == 0)
}

func testChangeObserverIncrementalDetails() {
    photosAuthorizeReadWrite()
    let observer = PhotosTestObserver()
    PHPhotoLibrary.shared().register(observer)
    let before = PHAsset.fetchAssets(with: .image, options: nil)
    var createdID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let request = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
        createdID = request.placeholderForCreatedAsset?.localIdentifier
    }
    precondition(observer.semaphore.wait(timeout: .now() + 5) == .success)
    let change = observer.lastChange
    precondition(change != nil)
    let details = change!.changeDetails(for: before)
    precondition(details != nil)
    precondition(details!.hasIncrementalChanges)
    precondition(details!.insertedObjects.count == 1)
    precondition(details!.insertedIndexes?.count == 1)
    precondition(details!.fetchResultAfterChanges.count == before.count + 1)
    let created = PHAsset.fetchAssets(withLocalIdentifiers: [createdID!], options: nil)[0]
    let objectDetails = change!.changeDetails(for: created)
    precondition(objectDetails == nil || objectDetails?.objectWasDeleted == false)
    PHPhotoLibrary.shared().unregisterChangeObserver(observer)
}

func testFetchOptionsPredicateSortAndHidden() {
    photosAuthorizeReadWrite()
    let older = PHAsset(
        localIdentifier: "pred-old",
        mediaType: .image,
        creationDate: Date(timeIntervalSince1970: 1),
        data: photosProbePNG
    )
    let hidden = PHAsset(
        localIdentifier: "pred-hidden",
        mediaType: .image,
        creationDate: Date(timeIntervalSince1970: 2),
        data: photosProbePNG
    )
    // Hidden is a stored property; install a hidden record via performChanges + change request.
    PHPhotoLibraryPortable._installAssets([older])
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let created = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
        created.isHidden = true
        created.creationDate = Date(timeIntervalSince1970: 2)
        _ = hidden
    }
    let hiddenOptions = PHFetchOptions()
    hiddenOptions.includeHiddenAssets = true
    #if os(Linux)
    hiddenOptions.hostSortsByCreationDateAscending = true
    #else
    hiddenOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    #endif
    let withHidden = PHAsset.fetchAssets(with: .image, options: hiddenOptions)
    precondition(withHidden.count >= 2)
    precondition(withHidden.lastObject != nil)
    let favoritePredicate = PHFetchOptions()
    #if os(Linux)
    favoritePredicate.hostPredicateEvaluates = { $0.isFavorite }
    #else
    favoritePredicate.predicate = NSPredicate(format: "isFavorite == YES")
    #endif
    precondition(PHAsset.fetchAssets(with: favoritePredicate).count == 0)
    let typePredicate = PHFetchOptions()
    #if os(Linux)
    typePredicate.hostPredicateEvaluates = { $0.mediaType == .image }
    #else
    typePredicate.predicate = NSPredicate(
        format: "mediaType == %d",
        PHAssetMediaType.image.rawValue
    )
    #endif
    typePredicate.fetchLimit = 1
    typePredicate.includeHiddenAssets = false
    typePredicate.includeAllBurstAssets = false
    typePredicate.includeAssetSourceTypes = .typeUserLibrary
    typePredicate.wantsIncrementalChangeDetails = true
    let limited = PHAsset.fetchAssets(with: typePredicate)
    precondition(limited.count == 1)
    var seen = 0
    limited.enumerateObjects(options: .reverse) { _, _, stop in
        seen += 1
        stop.pointee = true
    }
    precondition(seen == 1)
    let burst = PHAsset.fetchAssets(withBurstIdentifier: "none", options: nil)
    precondition(burst.count == 0)
    let al = PHAsset.fetchAssets(withALAssetURLs: [URL(fileURLWithPath: "/tmp/x")], options: nil)
    precondition(al.count == 0)
    let keys = PHAsset.fetchKeyAssets(
        in: PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil
        )[0],
        options: nil
    )
    precondition(keys != nil)
}

func testAuthorizationCallbackAndShortCircuit() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._installAuthorizationHandler { _ in .authorized }
    let semaphore = DispatchSemaphore(value: 0)
    var status = PHAuthorizationStatus.notDetermined
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { value in
        status = value
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success)
    precondition(status == .authorized)
    photosWait {
        let again = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        precondition(again == .authorized)
    }
    PHPhotoLibrary.requestAuthorization { value in
        _ = value
    }
}

func testLivePhotoFailClosed() {
    photosAuthorizeReadWrite()
    let asset = PHAsset(localIdentifier: "live", mediaType: .image, data: photosProbePNG)
    PHPhotoLibraryPortable._installAssets([asset])
    var live: PHLivePhoto?
    var info: [AnyHashable: Any]?
    _ = PHImageManager.default().requestLivePhoto(
        for: asset,
        targetSize: .zero,
        contentMode: .default,
        options: PHLivePhotoRequestOptions()
    ) { photo, payload in
        live = photo
        info = payload
    }
    precondition(live == nil)
    precondition(info?[PHLivePhotoInfoErrorKey] != nil)
    var requested: PHLivePhoto?
    _ = PHLivePhoto.request(
        withResourceFileURLs: [],
        placeholderImage: nil,
        targetSize: .zero,
        contentMode: .aspectFill
    ) { photo, payload in
        requested = photo
        precondition(payload[PHLivePhotoInfoErrorKey] != nil)
    }
    precondition(requested == nil)
    PHLivePhoto.cancelRequest(withRequestID: PHLivePhotoRequestIDInvalid)
    precondition(PHLivePhoto().size == .zero)
}

func testPersistentChangeSequence() {
    photosAuthorizeReadWrite()
    let token = PHPhotoLibrary.shared().currentChangeToken
    try! PHPhotoLibrary.shared().performChangesAndWait {
        _ = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
    }
    let result = try! PHPhotoLibrary.shared().fetchPersistentChanges(since: token)
    precondition(result.contains { _ in true })
    precondition(result.contains(where: { _ in true }))
    precondition(result.allSatisfy { _ in true })
    precondition(result.map(\.changeToken).isEmpty == false)
    precondition(result.compactMap { $0 as PHPersistentChange? }.isEmpty == false)
    precondition(result.filter { _ in true }.count >= 1)
    precondition(result.first(where: { _ in true }) != nil)
    precondition(result.min(by: { _, _ in false }) != nil)
    precondition(result.max(by: { _, _ in true }) != nil)
    _ = result.enumerated()
    _ = result.lazy
    _ = result.underestimatedCount
    _ = result.prefix(1)
    _ = result.prefix(while: { _ in true })
    _ = result.suffix(1)
    _ = result.dropFirst()
    _ = result.dropLast()
    _ = result.drop(while: { _ in false })
    _ = result.reversed()
    _ = result.shuffled()
    var generator = SystemRandomNumberGenerator()
    _ = result.shuffled(using: &generator)
    _ = result.sorted(by: { _, _ in false })
    _ = result.reduce(0) { partial, _ in partial + 1 }
    _ = result.reduce(into: 0) { partial, _ in partial += 1 }
    _ = result.flatMap { [$0] }
    result.forEach { _ in }
    _ = result.count(where: { _ in true })
    _ = result.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: { _ in false })
    _ = result.elementsEqual(Array<PHPersistentChange>())
    _ = result.elementsEqual(Array<PHPersistentChange>(), by: { _, _ in true })
    _ = result.lexicographicallyPrecedes(Array<PHPersistentChange>(), by: { _, _ in false })
    _ = result.starts(with: Array<PHPersistentChange>())
    _ = result.starts(with: Array<PHPersistentChange>(), by: { _, _ in true })
    _ = result.withContiguousStorageIfAvailable { _ in 0 }
    let iterator = result.makeIterator()
    precondition(iterator.next() != nil)
    let change = result.first(where: { _ in true })!
    let details = try! change.changeDetails(for: .asset)
    precondition(details.insertedLocalIdentifiers.isEmpty == false)
    _ = PHObjectType.assetCollection
    _ = PHObjectType.collectionList
}

func testCollectionListChangeRequest() {
    photosAuthorizeReadWrite()
    var listID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let list = PHCollectionListChangeRequest.creationRequestForCollectionList(
            withTitle: "Folder"
        )
        listID = list.placeholderForCreatedCollectionList.localIdentifier
    }
    let fetched = PHCollectionList.fetchCollectionLists(
        with: .folder,
        subtype: .regularFolder,
        options: nil
    )
    precondition(fetched.count == 1)
    precondition(fetched[0].localIdentifier == listID)
    let byID = PHCollectionList.fetchCollectionLists(
        withLocalIdentifiers: [listID!],
        options: nil
    )
    precondition(byID.count == 1)
    try! PHPhotoLibrary.shared().performChangesAndWait {
        PHCollectionListChangeRequest.deleteCollectionLists([byID[0]])
    }
    precondition(
        PHCollectionList.fetchCollectionLists(
            withLocalIdentifiers: [listID!],
            options: nil
        ).count == 0
    )
}

func testCachingImageManagerAndCreationRequest() {
    photosAuthorizeReadWrite()
    let manager = PHCachingImageManager()
    manager.startCachingImages(
        for: [],
        targetSize: CGSize(width: 8, height: 8),
        contentMode: .aspectFill,
        options: nil
    )
    manager.stopCachingImages(
        for: [],
        targetSize: .zero,
        contentMode: .aspectFit,
        options: nil
    )
    manager.stopCachingImagesForAllAssets()
    manager.cancelImageRequest(PHInvalidImageRequestID)
    let missing = PHAssetChangeRequest.creationRequestForAssetFromVideo(
        atFileURL: URL(fileURLWithPath: "/tmp/missing.mov")
    )
    precondition(missing == nil)
    let creation = PHAssetCreationRequest.forAsset()
    creation.addResource(with: .photo, data: photosProbePNG, options: nil)
    try! PHPhotoLibrary.shared().performChangesAndWait {
        _ = PHAssetCreationRequest.forAsset()
    }
}

func testAvailabilityObserverAndUnavailability() {
    photosAuthorizeReadWrite()
    final class Availability: NSObject, PHPhotoLibraryAvailabilityObserver {
        func photoLibraryDidBecomeUnavailable(_ photoLibrary: PHPhotoLibrary) {
            _ = photoLibrary
        }
    }
    let observer = Availability()
    PHPhotoLibrary.shared().register(observer)
    precondition(PHPhotoLibrary.shared().unavailabilityReason == nil)
    PHPhotoLibrary.shared().unregisterAvailabilityObserver(observer)
    do {
        try PHPhotoLibrary.shared().setUploadJobExtensionEnabled(true)
        precondition(false)
    } catch {
        precondition((error as? PHPhotosError)?.code == .changeNotSupported)
    }
    precondition(PHPhotoLibrary.shared().uploadJobExtensionEnabled == false)
}

func testFetchResultIndexInRange() {
    photosAuthorizeReadWrite()
    let first = PHAsset(localIdentifier: "idx-a", mediaType: .image, data: photosProbePNG)
    let second = PHAsset(localIdentifier: "idx-b", mediaType: .video)
    PHPhotoLibraryPortable._installAssets([first, second])
    let all = PHAsset.fetchAssets(with: nil as PHFetchOptions?)
    precondition(all.index(of: second, in: NSRange(location: 0, length: 2)) != NSNotFound)
    precondition(all.index(of: first, in: NSRange(location: 1, length: 1)) == NSNotFound)
    all.enumerateObjects(at: IndexSet(integer: 0), options: []) { asset, _, _ in
        precondition(asset.localIdentifier == "idx-a")
    }
}

func testCloudAndUploadJobsRemainFailClosed() {
    photosAuthorizeReadWrite()
    let jobs = PHAssetResourceUploadJob.fetchJobs(action: .acknowledge, options: nil)
    precondition(jobs.count == 0)
    precondition(PHAssetResourceUploadJob.jobLimit == 0)
    _ = PHAssetResourceUploadJob.Action.retry
    _ = PHAssetResourceUploadJob.State.pending
    _ = PHAssetResourceUploadJob.State.registered
    _ = PHAssetResourceUploadJob.State.failed
    _ = PHAssetResourceUploadJob.State.succeeded
    let mappings = PHPhotoLibrary.shared().cloudIdentifierMappings(
        forLocalIdentifiers: ["x"]
    )
    switch mappings["x"] {
    case .failure(let error):
        precondition((error as? PHPhotosError)?.code == .identifierNotFound)
    default:
        precondition(false)
    }
}
