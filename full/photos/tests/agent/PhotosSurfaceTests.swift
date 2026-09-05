@_spi(OpenUIKitHost) import Photos
import Foundation

func testAllEnumRawValues() {
    precondition(PHAssetCollectionSubtype.albumSyncedEvent.rawValue == 3)
    precondition(PHAssetCollectionSubtype.albumSyncedFaces.rawValue == 4)
    precondition(PHAssetCollectionSubtype.albumSyncedAlbum.rawValue == 5)
    precondition(PHAssetCollectionSubtype.albumImported.rawValue == 6)
    precondition(PHAssetCollectionSubtype.albumMyPhotoStream.rawValue == 100)
    precondition(PHAssetCollectionSubtype.albumCloudShared.rawValue == 101)
    precondition(PHAssetCollectionSubtype.smartAlbumGeneric.rawValue == 200)
    precondition(PHAssetCollectionSubtype.smartAlbumPanoramas.rawValue == 201)
    precondition(PHAssetCollectionSubtype.smartAlbumVideos.rawValue == 202)
    precondition(PHAssetCollectionSubtype.smartAlbumFavorites.rawValue == 203)
    precondition(PHAssetCollectionSubtype.smartAlbumTimelapses.rawValue == 204)
    precondition(PHAssetCollectionSubtype.smartAlbumAllHidden.rawValue == 205)
    precondition(PHAssetCollectionSubtype.smartAlbumRecentlyAdded.rawValue == 206)
    precondition(PHAssetCollectionSubtype.smartAlbumBursts.rawValue == 207)
    precondition(PHAssetCollectionSubtype.smartAlbumSlomoVideos.rawValue == 208)
    precondition(PHAssetCollectionSubtype.smartAlbumUserLibrary.rawValue == 209)
    precondition(PHAssetCollectionSubtype.smartAlbumSelfPortraits.rawValue == 210)
    precondition(PHAssetCollectionSubtype.smartAlbumScreenshots.rawValue == 211)
    precondition(PHAssetCollectionSubtype.smartAlbumDepthEffect.rawValue == 212)
    precondition(PHAssetCollectionSubtype.smartAlbumLivePhotos.rawValue == 213)
    precondition(PHAssetCollectionSubtype.smartAlbumAnimated.rawValue == 214)
    precondition(PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue == 215)
    precondition(PHAssetCollectionSubtype.smartAlbumUnableToUpload.rawValue == 216)
    precondition(PHAssetCollectionSubtype.smartAlbumRAW.rawValue == 217)
    precondition(PHAssetCollectionSubtype.smartAlbumCinematic.rawValue == 218)
    precondition(PHAssetCollectionSubtype.smartAlbumSpatial.rawValue == 219)
    precondition(PHAssetCollectionSubtype.smartAlbumScreenRecordings.rawValue == 220)
    precondition(PHAssetCollectionType.smartAlbum.rawValue == 2)
    precondition(PHAssetCollectionType.moment.rawValue == 3)
    precondition(PHAssetEditOperation.delete.rawValue == 1)
    precondition(PHAssetEditOperation.content.rawValue == 2)
    precondition(PHAssetEditOperation.properties.rawValue == 3)
    precondition(PHAsset.PlaybackStyle.unsupported.rawValue == 0)
    precondition(PHAsset.PlaybackStyle.imageAnimated.rawValue == 2)
    precondition(PHAsset.PlaybackStyle.livePhoto.rawValue == 3)
    precondition(PHAsset.PlaybackStyle.video.rawValue == 4)
    precondition(PHAsset.PlaybackStyle.videoLooping.rawValue == 5)
    precondition(PHAsset.PlaybackStyle(rawValue: 1) == .image)
    precondition(PHAsset.PlaybackStyle.image != .video)
    precondition(PHCollectionEditOperation.deleteContent.rawValue == 1)
    precondition(PHCollectionEditOperation.removeContent.rawValue == 2)
    precondition(PHCollectionEditOperation.addContent.rawValue == 3)
    precondition(PHCollectionEditOperation.createContent.rawValue == 4)
    precondition(PHCollectionEditOperation.rearrangeContent.rawValue == 5)
    precondition(PHCollectionEditOperation.delete.rawValue == 6)
    precondition(PHCollectionEditOperation.rename.rawValue == 7)
    precondition(PHCollectionListType.momentList.rawValue == 1)
    precondition(PHCollectionListType.folder.rawValue == 2)
    precondition(PHCollectionListType.smartFolder.rawValue == 3)
    precondition(PHCollectionListSubtype.momentListCluster.rawValue == 1)
    precondition(PHCollectionListSubtype.momentListYear.rawValue == 2)
    precondition(PHCollectionListSubtype.regularFolder.rawValue == 100)
    precondition(PHCollectionListSubtype.smartFolderEvents.rawValue == 200)
    precondition(PHCollectionListSubtype.smartFolderFaces.rawValue == 201)
    precondition(PHCollectionListSubtype.any.rawValue == 9223372036854775807)
    precondition(PHLivePhotoFrameType.photo.rawValue == 0)
    precondition(PHLivePhotoFrameType.video.rawValue == 1)
    precondition(PHVideoRequestOptionsVersion.current.rawValue == 0)
    precondition(PHVideoRequestOptionsVersion.original.rawValue == 1)
    precondition(PHVideoRequestOptionsDeliveryMode.mediumQualityFormat.rawValue == 2)
    precondition(PHVideoRequestOptionsDeliveryMode.fastFormat.rawValue == 3)
    precondition(PHImageRequestOptionsVersion.unadjusted.rawValue == 1)
    precondition(PHImageRequestOptionsVersion.original.rawValue == 2)
    precondition(PHBackgroundResourceUploadProcessingResult.failure.rawValue == 0)
    precondition(PHBackgroundResourceUploadProcessingResult.processing.rawValue == 1)
    precondition(PHBackgroundResourceUploadProcessingResult.completed.rawValue == 2)
    precondition(PHAssetResourceType.video.rawValue == 2)
    precondition(PHAssetResourceType.audio.rawValue == 3)
    precondition(PHAssetResourceType.alternatePhoto.rawValue == 4)
    precondition(PHAssetResourceType.fullSizePhoto.rawValue == 5)
    precondition(PHAssetResourceType.fullSizeVideo.rawValue == 6)
    precondition(PHAssetResourceType.adjustmentData.rawValue == 7)
    precondition(PHAssetResourceType.adjustmentBasePhoto.rawValue == 8)
    precondition(PHAssetResourceType.pairedVideo.rawValue == 9)
    precondition(PHAssetResourceType.fullSizePairedVideo.rawValue == 10)
    precondition(PHAssetResourceType.adjustmentBasePairedVideo.rawValue == 11)
    precondition(PHAssetResourceType.adjustmentBaseVideo.rawValue == 12)
}

func testOptionSetAlgebra() {
    var subtypes: PHAssetMediaSubtype = []
    subtypes.insert(.photoPanorama)
    subtypes.insert(.photoScreenshot)
    subtypes.insert(.photoDepthEffect)
    subtypes.insert(.videoStreamed)
    subtypes.insert(.videoHighFrameRate)
    subtypes.insert(.videoTimelapse)
    subtypes.insert(.videoScreenRecording)
    subtypes.insert(.videoCinematic)
    precondition(subtypes.contains(.photoPanorama))
    subtypes.remove(.photoPanorama)
    precondition(subtypes.contains(.photoPanorama) == false)
    let union = PHAssetMediaSubtype.photoLive.union(.photoHDR)
    precondition(union.contains(.photoLive) && union.contains(.photoHDR))
    let inter = union.intersection(.photoLive)
    precondition(inter == .photoLive)
    let sym = PHAssetMediaSubtype.photoLive.symmetricDifference(.photoHDR)
    precondition(sym.contains(.photoLive) && sym.contains(.photoHDR))
    precondition(PHAssetMediaSubtype.photoLive.isSubset(of: union))
    precondition(PHAssetMediaSubtype.photoLive.isDisjoint(with: .photoHDR))
    precondition(union.isSuperset(of: .photoLive))
    var burst: PHAssetBurstSelectionType = [.autoPick]
    burst.formUnion(.userPick)
    burst.formIntersection(.userPick)
    burst.formSymmetricDifference(.autoPick)
    _ = burst.subtracting(.userPick)
    var source: PHAssetSourceType = [.typeUserLibrary]
    source.insert(.typeiTunesSynced)
    source.insert(.typeCloudShared)
    precondition(source.contains(.typeiTunesSynced))
    precondition(PHAssetMediaSubtype.photoPanorama != PHAssetMediaSubtype.photoHDR)
    precondition(PHAssetBurstSelectionType.autoPick != .userPick)
    precondition(PHAssetSourceType.typeUserLibrary != .typeCloudShared)
    precondition(PHAccessLevel.addOnly != .readWrite)
    precondition(PHAssetCollectionType.album != .smartAlbum)
    precondition(PHAssetEditOperation.delete != .content)
    precondition(PHAuthorizationStatus.denied != .authorized)
    precondition(PHAssetMediaType.image != .video)
}

func testPhotosErrorCodeSurface() {
    let codes: [PHPhotosError.Code] = [
        .internalError,
        .userCancelled,
        .persistentChangeTokenExpired,
        .libraryVolumeOffline,
        .relinquishingLibraryBundleToWriter,
        .switchingSystemPhotoLibrary,
        .networkAccessRequired,
        .networkError,
        .identifierNotFound,
        .multipleIdentifiersFound,
        .persistentChangeDetailsUnavailable,
        .changeNotSupported,
        .operationInterrupted,
        .invalidResource,
        .missingResource,
        .notEnoughSpace,
        .requestNotSupportedForAsset,
        .limitExceeded,
        .accessRestricted,
        .accessUserDenied,
        .libraryInFileProviderSyncRoot,
    ]
    for code in codes {
        let error = PHPhotosError(code)
        precondition(error.code == code)
        precondition(error.errorCode == code.rawValue)
        precondition(error.errorUserInfo.isEmpty)
        precondition(PHPhotosError.errorDomain == PHPhotosErrorDomain)
        precondition(error == PHPhotosError(code))
        precondition(error.hashValue == PHPhotosError(code).hashValue)
        var hasher = Hasher()
        error.hash(into: &hasher)
        _ = hasher.finalize()
        _ = error.localizedDescription
        _ = error.userInfo
        switch error {
        case code:
            break
        default:
            precondition(false)
        }
    }
    precondition(PHPhotosError.internalError == .internalError)
    precondition(PHPhotosError.userCancelled == .userCancelled)
    precondition(PHPhotosError.persistentChangeTokenExpired == .persistentChangeTokenExpired)
    precondition(PHPhotosError.libraryVolumeOffline == .libraryVolumeOffline)
    precondition(PHPhotosError.relinquishingLibraryBundleToWriter == .relinquishingLibraryBundleToWriter)
    precondition(PHPhotosError.switchingSystemPhotoLibrary == .switchingSystemPhotoLibrary)
    precondition(PHPhotosError.networkAccessRequired == .networkAccessRequired)
    precondition(PHPhotosError.networkError == .networkError)
    precondition(PHPhotosError.identifierNotFound == .identifierNotFound)
    precondition(PHPhotosError.multipleIdentifiersFound == .multipleIdentifiersFound)
    precondition(PHPhotosError.persistentChangeDetailsUnavailable == .persistentChangeDetailsUnavailable)
    precondition(PHPhotosError.changeNotSupported == .changeNotSupported)
    precondition(PHPhotosError.operationInterrupted == .operationInterrupted)
    precondition(PHPhotosError.invalidResource == .invalidResource)
    precondition(PHPhotosError.missingResource == .missingResource)
    precondition(PHPhotosError.notEnoughSpace == .notEnoughSpace)
    precondition(PHPhotosError.requestNotSupportedForAsset == .requestNotSupportedForAsset)
    precondition(PHPhotosError.limitExceeded == .limitExceeded)
    precondition(PHPhotosError.accessRestricted == .accessRestricted)
    precondition(PHPhotosError.accessUserDenied == .accessUserDenied)
    precondition(PHPhotosError.libraryInFileProviderSyncRoot == .libraryInFileProviderSyncRoot)
    precondition(PHPhotosErrorRelinquishingLibraryBundleToWriter == 3142)
    precondition(PHPhotosErrorSwitchingSystemPhotoLibrary == 3143)
}

func testInfoDictionaryAndConstantKeys() {
    precondition(PHImageErrorKey == "PHImageErrorKey")
    precondition(PHImageResultIsDegradedKey == "PHImageResultIsDegradedKey")
    precondition(PHImageResultIsInCloudKey == "PHImageResultIsInCloudKey")
    precondition(PHImageResultRequestIDKey == "PHImageResultRequestIDKey")
    precondition(PHContentEditingInputCancelledKey == "PHContentEditingInputCancelledKey")
    precondition(PHContentEditingInputErrorKey == "PHContentEditingInputErrorKey")
    precondition(PHContentEditingInputResultIsInCloudKey == "PHContentEditingInputResultIsInCloudKey")
    precondition(PHLivePhotoInfoCancelledKey == "PHLivePhotoInfoCancelledKey")
    precondition(PHLivePhotoInfoErrorKey == "PHLivePhotoInfoErrorKey")
    precondition(PHLivePhotoInfoIsDegradedKey == "PHLivePhotoInfoIsDegradedKey")
    precondition(PHLocalIdentifiersErrorKey == "PHLocalIdentifiersErrorKey")
    precondition(PHInvalidAssetResourceDataRequestID == 0)
    _ = PHLivePhotoEditingOption.shouldRenderAtPlaybackTime
    let live = PHLivePhotoRequestOptions()
    live.isNetworkAccessAllowed = true
    live.version = .original
    live.deliveryMode = .highQualityFormat
    let video = PHVideoRequestOptions()
    video.isNetworkAccessAllowed = true
    video.version = .original
    video.deliveryMode = .highQualityFormat
    let imageOptions = PHImageRequestOptions()
    imageOptions.allowSecondaryDegradedImage = true
    imageOptions.normalizedCropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    imageOptions.progressHandler = nil
    let resourceOptions = PHAssetResourceRequestOptions()
    resourceOptions.isNetworkAccessAllowed = true
    resourceOptions.progressHandler = nil
    let createOptions = PHAssetResourceCreationOptions()
    createOptions.originalFilename = "a.png"
    createOptions.shouldMoveFile = false
    createOptions.uniformTypeIdentifier = "public.png"
}

func testContentEditingAndAdjustmentSurface() {
    let input = PHContentEditingInput()
    input.creationDate = Date()
    input.displaySizeImage = UIImage()
    input.fullSizeImageOrientation = 1
    input.fullSizeImageURL = URL(fileURLWithPath: "/tmp/full.jpg")
    input.mediaSubtypes = .photoLive
    input.playbackStyle = .livePhoto
    input.uniformTypeIdentifier = "public.jpeg"
    let output = PHContentEditingOutput(placeholderForCreatedAsset: PHObjectPlaceholder(placeholderIdentifier: "p"))
    precondition(output.renderedContentURL.isFileURL)
    let options = PHContentEditingInputRequestOptions()
    options.isNetworkAccessAllowed = true
    let data = PHAdjustmentData(formatIdentifier: "f", formatVersion: "1", data: Data())
    precondition(options.canHandleAdjustmentData(data) == false)
    let context = PHLivePhotoEditingContext(livePhotoEditingInput: input)
    precondition(context == nil)
}

func testFetchResultChangeDetailsManualInit() {
    photosAuthorizeReadWrite()
    let a = PHAsset(localIdentifier: "d1", mediaType: .image)
    let b = PHAsset(localIdentifier: "d2", mediaType: .image)
    PHPhotoLibraryPortable._installAssets([a, b])
    let before = PHAsset.fetchAssets(with: nil as PHFetchOptions?)
    PHPhotoLibraryPortable._installAssets([b])
    let after = PHAsset.fetchAssets(with: nil as PHFetchOptions?)
    let details = PHFetchResultChangeDetails(from: before, to: after, changedObjects: [])
    precondition(details.hasIncrementalChanges)
    precondition(details.removedObjects.count == 1)
    _ = details.changedIndexes
    _ = details.hasMoves
    precondition(details.fetchResultBeforeChanges.count == 2)
    precondition(details.fetchResultAfterChanges.count == 1)
    let alt = PHFetchResultChangeDetails(
        fromFetchResult: before,
        toFetchResult: after,
        changedObjects: []
    )
    precondition(alt.removedIndexes != nil)
    details.enumerateMoves { _, _ in }
}
