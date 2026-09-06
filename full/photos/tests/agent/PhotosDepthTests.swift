@_spi(OpenUIKitHost) import Photos
import Foundation

private func photosAuthorizeInline() {
    PHPhotoLibraryPortable._reset()
    PHPhotoLibraryPortable._setStatus(.authorized, for: .readWrite)
}

private func photosCreateAssets(_ count: Int) -> [PHAsset] {
    var identifiers: [String] = []
    try! PHPhotoLibrary.shared().performChangesAndWait {
        for _ in 0..<count {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
            identifiers.append(request.placeholderForCreatedAsset!.localIdentifier)
        }
    }
    return identifiers.map {
        PHAsset.fetchAssets(withLocalIdentifiers: [$0], options: nil)[0]
    }
}

func testAlbumMembershipInsertMoveRemoveReplace() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(3)
    var albumID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
            withTitle: "Membership"
        )
        album.addAssets(assets)
        albumID = album.placeholderForCreatedAssetCollection.localIdentifier
    }
    let album = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    var order = PHAsset.fetchAssets(in: album, options: nil)
    precondition(order.count == 3)
    precondition(order[0].localIdentifier == assets[0].localIdentifier)

    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHAssetCollectionChangeRequest(for: album)!
        change.moveAssets(at: IndexSet(integer: 0), to: 2)
    }
    let movedAlbum = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    order = PHAsset.fetchAssets(in: movedAlbum, options: nil)
    precondition(order[0].localIdentifier == assets[1].localIdentifier)
    precondition(order[2].localIdentifier == assets[0].localIdentifier)

    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHAssetCollectionChangeRequest(for: movedAlbum)!
        change.removeAssets(at: IndexSet(integer: 2))
        change.insertAssets([assets[0]], at: IndexSet(integer: 0))
        change.replaceAssets(at: IndexSet(integer: 1), withAssets: [assets[2]])
        change.removeAssets([assets[2]])
    }
    let finalAlbum = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    let finalOrder = PHAsset.fetchAssets(in: finalAlbum, options: nil)
    precondition(finalOrder.count == 2)
    precondition(finalOrder[0].localIdentifier == assets[0].localIdentifier)
}

func testAlbumChangeRequestFromFetchResultSeedsMembership() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(2)
    var albumID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
            withTitle: "Seed"
        )
        album.addAssets(assets)
        albumID = album.placeholderForCreatedAssetCollection.localIdentifier
    }
    let album = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    let onlySecond = PHAsset.fetchAssets(
        withLocalIdentifiers: [assets[1].localIdentifier],
        options: nil
    )
    _ = PHAssetCollectionChangeRequest(forAssetCollection: album, assets: onlySecond)
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHAssetCollectionChangeRequest(for: album, assets: onlySecond)
        change?.title = "Seeded"
    }
    let updated = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    let members = PHAsset.fetchAssets(in: updated, options: nil)
    precondition(updated.localizedTitle == "Seeded")
    precondition(members.count == 1)
    precondition(members[0].localIdentifier == assets[1].localIdentifier)
}

func testDeleteAssetCollectionsRemovesAlbum() {
    photosAuthorizeInline()
    var albumID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
            withTitle: "Doomed"
        )
        albumID = album.placeholderForCreatedAssetCollection.localIdentifier
    }
    let album = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    try! PHPhotoLibrary.shared().performChangesAndWait {
        PHAssetCollectionChangeRequest.deleteAssetCollections([album])
    }
    precondition(
        PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumID!],
            options: nil
        ).count == 0
    )
}

func testCollectionListChildrenMutations() {
    photosAuthorizeInline()
    var albumIDs: [String] = []
    var listID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        for title in ["A", "B", "C"] {
            let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                withTitle: title
            )
            albumIDs.append(album.placeholderForCreatedAssetCollection.localIdentifier)
        }
        let list = PHCollectionListChangeRequest.creationRequestForCollectionList(
            withTitle: "Folder"
        )
        listID = list.placeholderForCreatedCollectionList.localIdentifier
    }
    let albums = albumIDs.map {
        PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [$0], options: nil)[0]
    }
    let list = PHCollectionList.fetchCollectionLists(
        withLocalIdentifiers: [listID!],
        options: nil
    )[0]
    precondition(list.collectionListSubtype == .regularFolder)

    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHCollectionListChangeRequest(for: list)!
        change.addChildCollections(albums)
        change.title = "Folder+"
    }
    var live = PHCollectionList.fetchCollectionLists(
        withLocalIdentifiers: [listID!],
        options: nil
    )[0]
    var children = PHCollection.fetchCollections(in: live, options: nil)
    precondition(children.count == 3)
    precondition(live.localizedTitle == "Folder+")

    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHCollectionListChangeRequest(for: live)!
        change.moveChildCollections(at: IndexSet(integer: 0), to: 2)
        change.removeChildCollections(at: IndexSet(integer: 2))
        change.insertChildCollections([albums[0]], at: IndexSet(integer: 0))
        change.replaceChildCollections(at: IndexSet(integer: 1), withChildCollections: [albums[2]])
        change.removeChildCollections([albums[2]])
    }
    live = PHCollectionList.fetchCollectionLists(
        withLocalIdentifiers: [listID!],
        options: nil
    )[0]
    children = PHCollection.fetchCollections(in: live, options: nil)
    precondition(children.count == 2)
    precondition(children[0].localIdentifier == albums[0].localIdentifier)
}

func testCollectionListChangeRequestFromChildrenAndContaining() {
    photosAuthorizeInline()
    var albumID: String?
    var listID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
            withTitle: "Child"
        )
        albumID = album.placeholderForCreatedAssetCollection.localIdentifier
        let list = PHCollectionListChangeRequest.creationRequestForCollectionList(
            withTitle: "Parent"
        )
        listID = list.placeholderForCreatedCollectionList.localIdentifier
    }
    let album = PHAssetCollection.fetchAssetCollections(
        withLocalIdentifiers: [albumID!],
        options: nil
    )[0]
    let list = PHCollectionList.fetchCollectionLists(
        withLocalIdentifiers: [listID!],
        options: nil
    )[0]
    let childFetch = PHFetchResult<PHCollection>(hostObjects: [album])
    try! PHPhotoLibrary.shared().performChangesAndWait {
        _ = PHCollectionListChangeRequest(for: list, childCollections: childFetch)
        _ = PHCollectionListChangeRequest(
            forCollectionList: list,
            childCollections: childFetch
        )
    }
    let containing = PHCollectionList.fetchCollectionListsContaining(album, options: nil)
    precondition(containing.count == 1)
    precondition(containing[0].localIdentifier == listID)
    precondition(containing[0].collectionListSubtype == .regularFolder)
}

func testTopLevelUserCollectionsReorder() {
    photosAuthorizeInline()
    var albumIDs: [String] = []
    try! PHPhotoLibrary.shared().performChangesAndWait {
        for title in ["One", "Two"] {
            let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                withTitle: title
            )
            albumIDs.append(album.placeholderForCreatedAssetCollection.localIdentifier)
        }
    }
    let before = PHCollection.fetchTopLevelUserCollections(with: nil)
    precondition(before.count >= 2)
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let reversedItems = (0..<before.count).map { before[$0] }.reversed()
        let reversed = PHFetchResult(hostObjects: Array(reversedItems))
        _ = PHCollectionListChangeRequest(
            forTopLevelCollectionListUserCollections: reversed
        )
    }
    let after = PHCollection.fetchTopLevelUserCollections(with: nil)
    precondition(after.count == before.count)
    precondition(after[0].localIdentifier == before[before.count - 1].localIdentifier)
}

func testMomentListsRemainEmpty() {
    photosAuthorizeInline()
    let moment = PHAssetCollection(
        localIdentifier: "moment-probe",
        title: "Moment",
        type: .moment,
        subtype: .albumRegular
    )
    let empty = PHCollectionList.fetchMomentLists(with: .momentListYear, options: nil)
    precondition(empty.count == 0)
    let containing = PHCollectionList.fetchMomentLists(
        with: .momentListCluster,
        containingMoment: moment,
        options: nil
    )
    precondition(containing.count == 0)
}

func testObjectChangeDetailsFavoriteAndDelete() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(1)
    let observer = PhotosSynchronousObserver()
    PHPhotoLibrary.shared().register(observer)
    let before = assets[0]
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let change = PHAssetChangeRequest(for: before)
        change.isFavorite = true
        _ = PHAssetChangeRequest(forAsset: before)
    }
    let favoriteChange = observer.lastChange
    precondition(favoriteChange != nil)
    let favoriteDetails = favoriteChange!.changeDetails(for: before)
    precondition(favoriteDetails != nil)
    precondition(favoriteDetails!.objectBeforeChanges.localIdentifier == before.localIdentifier)
    precondition(favoriteDetails!.objectAfterChanges?.isFavorite == true)
    precondition(favoriteDetails!.objectWasDeleted == false)
    precondition(favoriteDetails!.assetContentChanged)

    let favorite = PHAsset.fetchAssets(
        withLocalIdentifiers: [before.localIdentifier],
        options: nil
    )[0]
    try! PHPhotoLibrary.shared().performChangesAndWait {
        PHAssetChangeRequest.deleteAssets([favorite])
    }
    let deleteChange = observer.lastChange
    let deleted = deleteChange!.changeDetails(for: favorite)
    precondition(deleted?.objectWasDeleted == true)
    precondition(deleted?.objectAfterChanges == nil)
    PHPhotoLibrary.shared().unregisterChangeObserver(observer)
}

func testPersistentObjectChangeDetailsUpdatedAndDeleted() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(1)
    var albumID: String?
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
            withTitle: "Persist"
        )
        albumID = album.placeholderForCreatedAssetCollection.localIdentifier
    }
    let token = PHPhotoLibrary.shared().currentChangeToken
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let asset = PHAsset.fetchAssets(
            withLocalIdentifiers: [assets[0].localIdentifier],
            options: nil
        )[0]
        let change = PHAssetChangeRequest(for: asset)
        change.isHidden = true
        let album = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumID!],
            options: nil
        )[0]
        PHAssetCollectionChangeRequest.deleteAssetCollections([album])
    }
    let result = try! PHPhotoLibrary.shared().fetchPersistentChanges(since: token)
    precondition(result is PHPersistentChangeFetchResult)
    let iterator = PHPersistentChangeFetchResult.Iterator(fetchResult: result)
    let change = iterator.next()
    precondition(change != nil)
    let assetDetails = try! change!.changeDetails(for: .asset)
    precondition(assetDetails.objectType == .asset)
    precondition(assetDetails.updatedLocalIdentifiers.contains(assets[0].localIdentifier))
    let collectionDetails = try! change!.changeDetails(for: .assetCollection)
    precondition(collectionDetails.deletedLocalIdentifiers.contains(albumID!))
    _ = PHPhotoLibrary.shared().currentChangeToken
}

func testFetchResultChangeDetailsMoves() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(3)
    let before = PHFetchResult(hostObjects: assets)
    let after = PHFetchResult(hostObjects: [assets[2], assets[0], assets[1]])
    let details = PHFetchResultChangeDetails(
        from: before,
        to: after,
        changedObjects: [assets[0]]
    )
    precondition(details.hasMoves)
    precondition(details.changedObjects.count == 1)
    var moves: [(Int, Int)] = []
    details.enumerateMoves { from, to in
        moves.append((from, to))
    }
    precondition(moves.isEmpty == false)
    let synthesized = PHFetchResultChangeDetails(
        fromFetchResult: before,
        toFetchResult: after,
        changedObjects: []
    )
    precondition(synthesized.hasIncrementalChanges)
}

func testLivePhotoEditingContextFailClosed() {
    let input = PHContentEditingInput()
    precondition(PHLivePhotoEditingContext(livePhotoEditingInput: input) == nil)
    input.livePhoto = PHLivePhoto()
    let context = PHLivePhotoEditingContext(livePhotoEditingInput: input)
    precondition(context != nil)
    context!.audioVolume = 0.25
    precondition(context!.audioVolume == 0.25)
    context!.orientation = .down
    precondition(context!.orientation == .down)
    var playbackError: (any Error)?
    var playbackPhoto: PHLivePhoto? = PHLivePhoto()
    context!.prepareLivePhotoForPlayback(withTargetSize: .zero, options: nil) { photo, error in
        playbackPhoto = photo
        playbackError = error
    }
    precondition(playbackPhoto == nil)
    precondition((playbackError as? PHPhotosError)?.code == .requestNotSupportedForAsset)
    let output = PHContentEditingOutput(
        placeholderForCreatedAsset: PHObjectPlaceholder(placeholderIdentifier: "edit")
    )
    var saved = true
    var saveError: (any Error)?
    context!.saveLivePhoto(to: output, options: nil) { success, error in
        saved = success
        saveError = error
    }
    precondition(saved == false)
    precondition((saveError as? PHPhotosError)?.code == .requestNotSupportedForAsset)
    context!.cancel()
    var cancelledError: (any Error)?
    context!.prepareLivePhotoForPlayback(withTargetSize: .zero) { _, error in
        cancelledError = error
    }
    precondition((cancelledError as? PHPhotosError)?.code == .operationInterrupted)
}

func testUploadJobChangeRequestFailClosed() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(1)
    let resources = PHAssetResource.assetResources(for: assets[0])
    precondition(resources.isEmpty == false)
    precondition(resources[0].assetLocalIdentifier == assets[0].localIdentifier)
    let job = PHAssetResourceUploadJob._hostJob(resource: resources[0], state: .pending)
    precondition(job.resource.assetLocalIdentifier == assets[0].localIdentifier)
    precondition(job.state == .pending)
    let request = PHAssetResourceUploadJobChangeRequest(for: job)
    precondition(request != nil)
    _ = PHAssetResourceUploadJobChangeRequest(forUploadJob: job)
    request?.acknowledge()
    precondition(PHAssetResourceUploadJob.fetchJobs(action: .acknowledge, options: nil).count == 0)
}

func testImageProgressHandlerStopFlag() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(1)
    let options = PHImageRequestOptions()
    var fractions: [Double] = []
    options.progressHandler = { fraction, _, stop, _ in
        fractions.append(fraction)
        stop.pointee = true
    }
    var cancelled = false
    _ = PHImageManager.default().requestImageDataAndOrientation(
        for: assets[0],
        options: options
    ) { data, _, _, info in
        cancelled = data == nil && (info?[PHImageCancelledKey] as? Bool == true)
    }
    precondition(fractions.isEmpty == false)
    precondition(cancelled)
}

func testResourceProgressAndCancel() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(1)
    let resources = PHAssetResource.assetResources(for: assets[0])
    var progress = 0.0
    let options = PHAssetResourceRequestOptions()
    options.progressHandler = { value in
        progress = value
    }
    let requestID = PHAssetResourceManager.default().requestData(
        for: resources[0],
        options: options,
        dataReceivedHandler: { _ in },
        completionHandler: { _ in }
    )
    precondition(requestID > PHInvalidAssetResourceDataRequestID)
    precondition(progress == 1.0)
    PHAssetResourceManager.default().cancelDataRequest(requestID)
    PHAssetResourceManager.default().cancelDataRequest(PHInvalidAssetResourceDataRequestID)
}

func testContentEditingInputRequestFailClosed() {
    photosAuthorizeInline()
    let assets = photosCreateAssets(1)
    let options = PHContentEditingInputRequestOptions()
    var delivered: PHContentEditingInput? = PHContentEditingInput()
    var info: [AnyHashable: Any] = [:]
    let requestID = assets[0].requestContentEditingInput(with: options) { input, payload in
        delivered = input
        info = payload
    }
    precondition(requestID == 0)
    precondition(delivered == nil)
    precondition(info[PHContentEditingInputErrorKey] != nil)
    assets[0].cancelContentEditingInputRequest(requestID)
}

func testNSCodingInitsFailClosed() {
    let payload = try! NSKeyedArchiver.archivedData(
        withRootObject: "photos-probe",
        requiringSecureCoding: false
    )
    let coder = try! NSKeyedUnarchiver(forReadingFrom: payload)
    precondition(PHCloudIdentifier(coder: coder) == nil)
    precondition(PHLivePhoto(coder: coder) == nil)
    precondition(PHPersistentChangeToken(coder: coder) == nil)
}

func testChangeRequestBaseAndEmptyChange() {
    let changeRequest = PHChangeRequest()
    precondition(changeRequest is NSObject)
    let created = PHAssetChangeRequest.creationRequestForAsset(from: UIImage())
    precondition(created is PHChangeRequest)
    let empty = PHChange()
    let asset = PHAsset(localIdentifier: "none", mediaType: .image)
    precondition(empty.changeDetails(for: asset) == nil)
}

func testTypealiasHandlersAndRequestIDs() {
    var imageProgress: PHAssetImageProgressHandler = { _, _, stop, _ in
        stop.pointee = false
    }
    var stop = ObjCBool(false)
    imageProgress(0.5, nil, &stop, nil)
    precondition(stop.boolValue == false)

    var videoProgress: PHAssetVideoProgressHandler = { fraction, _, _, _ in
        precondition(fraction == 0.25)
    }
    videoProgress(0.25, nil, &stop, nil)
    let video = PHVideoRequestOptions()
    video.progressHandler = videoProgress

    var resourceProgress: PHAssetResourceProgressHandler = { value in
        precondition(value == 0.75)
    }
    resourceProgress(0.75)

    let liveID: PHLivePhotoRequestID = PHLivePhotoRequestIDInvalid
    precondition(liveID == 0)
    let resourceID: PHAssetResourceDataRequestID = PHInvalidAssetResourceDataRequestID
    precondition(resourceID == 0)
    let editingID: PHContentEditingInputRequestID = 0
    precondition(editingID == 0)
}

func testPhotosErrorPatternMatchAndEquality() {
    let left = PHPhotosError(.userCancelled)
    let right = PHPhotosError(.userCancelled)
    precondition(left == right)
    precondition(left != PHPhotosError(.accessUserDenied))
    let error: any Error = left
    precondition(PHPhotosError.Code.userCancelled ~= error)
    precondition(PHPhotosError.Code.accessUserDenied ~= error == false)
}

func testOptionSetSynthesizedAlgebra() {
    let emptyBurst = PHAssetBurstSelectionType()
    precondition(emptyBurst.isEmpty)
    let emptyMedia = PHAssetMediaSubtype()
    precondition(emptyMedia.isEmpty)
    let emptySource = PHAssetSourceType()
    precondition(emptySource.isEmpty)

    var burst: PHAssetBurstSelectionType = [.autoPick]
    let replaced = burst.update(with: .userPick)
    precondition(replaced == .autoPick)
    precondition(burst.contains(.userPick))
    burst.subtract(.userPick)
    precondition(burst.contains(.userPick) == false)

    var media: PHAssetMediaSubtype = [.photoLive, .photoHDR]
    _ = media.update(with: .photoScreenshot)
    media.subtract(.photoHDR)
    precondition(media.contains(.photoLive))
    precondition(media.contains(.photoHDR) == false)

    var source: PHAssetSourceType = [.typeUserLibrary]
    _ = source.update(with: .typeCloudShared)
    source.subtract(.typeCloudShared)
    precondition(source.contains(.typeUserLibrary))

    precondition(PHAssetBurstSelectionType.autoPick.isStrictSubset(of: [.autoPick, .userPick]))
    precondition(PHAssetMediaSubtype.photoLive.isStrictSubset(of: [.photoLive, .photoHDR]))
    precondition(PHAssetSourceType.typeUserLibrary.isStrictSubset(of: [.typeUserLibrary, .typeCloudShared]))
    precondition(
        PHAssetBurstSelectionType([.autoPick, .userPick]).isStrictSuperset(of: .autoPick)
    )
    precondition(
        PHAssetMediaSubtype([.photoLive, .photoHDR]).isStrictSuperset(of: .photoLive)
    )
    precondition(
        PHAssetSourceType([.typeUserLibrary, .typeCloudShared]).isStrictSuperset(of: .typeUserLibrary)
    )

    let burstFromSequence = PHAssetBurstSelectionType([.autoPick, .userPick])
    precondition(burstFromSequence.contains(.autoPick) && burstFromSequence.contains(.userPick))
    let mediaFromSequence = PHAssetMediaSubtype([.photoLive])
    precondition(mediaFromSequence == .photoLive)
    let sourceFromSequence = PHAssetSourceType([.typeiTunesSynced])
    precondition(sourceFromSequence == .typeiTunesSynced)
}

func testEnumRawValueInitsAndInequality() {
    precondition(PHAccessLevel(rawValue: 1) == .addOnly)
    precondition(PHAccessLevel.addOnly != .readWrite)
    precondition(PHAssetBurstSelectionType.autoPick != .userPick)
    precondition(PHAssetCollectionSubtype(rawValue: 2) == .albumRegular)
    precondition(PHAssetCollectionSubtype.albumRegular != .any)
    precondition(PHAssetCollectionType(rawValue: 1) == .album)
    precondition(PHAssetCollectionType.album != .smartAlbum)
    precondition(PHAssetEditOperation(rawValue: 1) == .delete)
    precondition(PHAssetEditOperation.delete != .content)
    precondition(PHAssetMediaSubtype.photoLive != .photoHDR)
    precondition(PHAssetMediaType(rawValue: 1) == .image)
    precondition(PHAssetMediaType.image != .video)
    precondition(PHAsset.PlaybackStyle(rawValue: 1) == .image)
    precondition(PHAsset.PlaybackStyle.image != .video)
    precondition(PHAssetResourceType(rawValue: 1) == .photo)
    precondition(PHAssetResourceType.photo != .video)
    precondition(PHAssetResourceUploadJob.Action(rawValue: 0) == .acknowledge)
    precondition(PHAssetResourceUploadJob.Action.acknowledge != .retry)
    precondition(PHAssetResourceUploadJob.State(rawValue: 0) == .pending)
    precondition(PHAssetResourceUploadJob.State.pending != .failed)
    precondition(PHAssetSourceType.typeUserLibrary != .typeCloudShared)
    precondition(PHAuthorizationStatus(rawValue: 2) == .denied)
    precondition(PHAuthorizationStatus.denied != .authorized)
    precondition(PHCollectionEditOperation(rawValue: 6) == .delete)
    precondition(PHCollectionEditOperation.delete != .rename)
    precondition(PHCollectionListSubtype(rawValue: 100) == .regularFolder)
    precondition(PHCollectionListSubtype.regularFolder != .any)
    precondition(PHCollectionListType(rawValue: 2) == .folder)
    precondition(PHCollectionListType.folder != .momentList)
    precondition(PHImageContentMode(rawValue: 0) == .aspectFit)
    precondition(PHImageContentMode.aspectFit != .aspectFill)
    precondition(PHImageRequestOptionsDeliveryMode(rawValue: 0) == .opportunistic)
    precondition(PHImageRequestOptionsDeliveryMode.opportunistic != .fastFormat)
    precondition(PHImageRequestOptionsResizeMode(rawValue: 1) == .fast)
    precondition(PHImageRequestOptionsResizeMode.fast != .exact)
    precondition(PHImageRequestOptionsVersion(rawValue: 0) == .current)
    precondition(PHImageRequestOptionsVersion.current != .original)
    precondition(PHLivePhotoFrameType(rawValue: 0) == .photo)
    precondition(PHLivePhotoFrameType.photo != .video)
    precondition(PHObjectType(rawValue: 1) == .asset)
    precondition(PHObjectType.asset != .collectionList)
    precondition(PHPhotosError.Code.userCancelled != .accessUserDenied)
    precondition(PHVideoRequestOptionsDeliveryMode(rawValue: 0) == .automatic)
    precondition(PHVideoRequestOptionsDeliveryMode.automatic != .fastFormat)
    precondition(PHVideoRequestOptionsVersion(rawValue: 0) == .current)
    precondition(PHVideoRequestOptionsVersion.current != .original)
    precondition(PHLivePhotoEditingOption(rawValue: "x") != .shouldRenderAtPlaybackTime)
    precondition(PHBackgroundResourceUploadProcessingResult(rawValue: 0) == .failure)
    precondition(PHBackgroundResourceUploadProcessingResult.failure != .completed)
    typealias ProcessingRaw = PHBackgroundResourceUploadProcessingResult.RawValue
    precondition(ProcessingRaw.self == Int.self)
}

private final class PhotosSynchronousObserver: NSObject, PHPhotoLibraryChangeObserver {
    var lastChange: PHChange?

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        lastChange = changeInstance
    }
}
