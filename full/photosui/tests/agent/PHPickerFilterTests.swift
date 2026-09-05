import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private func imageAsset(
    _ identifier: String,
    playbackStyle: PHAsset.PlaybackStyle = .image,
    representsBurst: Bool = false,
    isLivePhoto: Bool = false,
    isScreenshot: Bool = false,
    isPanorama: Bool = false,
    isDepthEffect: Bool = false,
    isSpatial: Bool = false
) -> PHPickerHostAsset {
    PHPickerHostAsset(
        identifier: identifier,
        mediaKind: .image,
        typeIdentifier: UTType.jpeg.identifier,
        payload: Data(identifier.utf8),
        playbackStyle: playbackStyle,
        representsBurst: representsBurst,
        isLivePhoto: isLivePhoto,
        isScreenshot: isScreenshot,
        isPanorama: isPanorama,
        isDepthEffect: isDepthEffect,
        isSpatial: isSpatial
    )
}

private func videoAsset(
    _ identifier: String,
    playbackStyle: PHAsset.PlaybackStyle = .video,
    isCinematic: Bool = false,
    isSlomo: Bool = false,
    isTimelapse: Bool = false,
    isScreenRecording: Bool = false
) -> PHPickerHostAsset {
    PHPickerHostAsset(
        identifier: identifier,
        mediaKind: .video,
        typeIdentifier: UTType.movie.identifier,
        payload: Data(identifier.utf8),
        playbackStyle: playbackStyle,
        isCinematic: isCinematic,
        isSlomo: isSlomo,
        isTimelapse: isTimelapse,
        isScreenRecording: isScreenRecording
    )
}

func testPickerFilterAssetCatalog() {
    let jpeg = imageAsset("jpeg")
    let live = imageAsset("live", playbackStyle: .livePhoto, isLivePhoto: true)
    let shot = imageAsset("shot", isScreenshot: true)
    let pan = imageAsset("pan", isPanorama: true)
    let depth = imageAsset("depth", isDepthEffect: true)
    let burst = imageAsset("burst", representsBurst: true)
    let spatial = imageAsset("spatial", isSpatial: true)
    let movie = videoAsset("movie")
    let cine = videoAsset("cine", isCinematic: true)
    let slomo = videoAsset("slomo", playbackStyle: .videoLooping, isSlomo: true)
    let time = videoAsset("time", isTimelapse: true)
    let rec = videoAsset("rec", isScreenRecording: true)

    precondition(PHPickerFilter.images._matches(jpeg))
    precondition(PHPickerFilter.images._matches(live))
    precondition(!PHPickerFilter.images._matches(movie))

    precondition(PHPickerFilter.videos._matches(movie))
    precondition(!PHPickerFilter.videos._matches(jpeg))

    precondition(PHPickerFilter.livePhotos._matches(live))
    precondition(!PHPickerFilter.livePhotos._matches(jpeg))

    precondition(PHPickerFilter.screenshots._matches(shot))
    precondition(!PHPickerFilter.screenshots._matches(jpeg))

    precondition(PHPickerFilter.panoramas._matches(pan))
    precondition(PHPickerFilter.depthEffectPhotos._matches(depth))
    precondition(PHPickerFilter.bursts._matches(burst))
    precondition(PHPickerFilter.spatialMedia._matches(spatial))

    precondition(PHPickerFilter.cinematicVideos._matches(cine))
    precondition(PHPickerFilter.slomoVideos._matches(slomo))
    precondition(PHPickerFilter.timelapseVideos._matches(time))
    precondition(PHPickerFilter.screenRecordings._matches(rec))
    precondition(!PHPickerFilter.cinematicVideos._matches(movie))
    precondition(!PHPickerFilter.slomoVideos._matches(movie))
    precondition(!PHPickerFilter.timelapseVideos._matches(movie))
    precondition(!PHPickerFilter.screenRecordings._matches(jpeg))
}

func testPickerFilterAssetAlgebra() {
    let jpeg = imageAsset("jpeg")
    let live = imageAsset("live", playbackStyle: .livePhoto, isLivePhoto: true)
    let movie = videoAsset("movie")
    let shot = imageAsset("shot", isScreenshot: true)

    let any = PHPickerFilter.any(of: [.images, .videos])
    precondition(any._matches(jpeg))
    precondition(any._matches(movie))
    precondition(!PHPickerFilter.any(of: [])._matches(jpeg))

    let stills = PHPickerFilter.all(of: [.images, .not(.livePhotos)])
    precondition(stills._matches(jpeg))
    precondition(!stills._matches(live))
    precondition(!stills._matches(movie))
    precondition(PHPickerFilter.all(of: [])._matches(jpeg))

    precondition(PHPickerFilter.not(.videos)._matches(jpeg))
    precondition(!PHPickerFilter.not(.videos)._matches(movie))
    precondition(!PHPickerFilter.not(.images)._matches(shot))

    let screenshotsOrLive = PHPickerFilter.any(of: [.screenshots, .livePhotos])
    precondition(screenshotsOrLive._matches(shot))
    precondition(screenshotsOrLive._matches(live))
    precondition(!screenshotsOrLive._matches(jpeg))
}

func testPickerFilterPlaybackStyleAssets() {
    let jpeg = imageAsset("jpeg", playbackStyle: .image)
    let animated = imageAsset("gif", playbackStyle: .imageAnimated)
    let live = imageAsset("live", playbackStyle: .livePhoto, isLivePhoto: true)
    let movie = videoAsset("movie", playbackStyle: .video)
    let loop = videoAsset("loop", playbackStyle: .videoLooping, isSlomo: true)

    precondition(PHPickerFilter.playbackStyle(.image)._matches(jpeg))
    precondition(!PHPickerFilter.playbackStyle(.image)._matches(animated))
    precondition(PHPickerFilter.playbackStyle(.imageAnimated)._matches(animated))
    precondition(PHPickerFilter.playbackStyle(.livePhoto)._matches(live))
    precondition(PHPickerFilter.playbackStyle(.video)._matches(movie))
    precondition(PHPickerFilter.playbackStyle(.videoLooping)._matches(loop))
    precondition(!PHPickerFilter.playbackStyle(.unsupported)._matches(jpeg))
    precondition(!PHPickerFilter.playbackStyle(.video)._matches(jpeg))
}
