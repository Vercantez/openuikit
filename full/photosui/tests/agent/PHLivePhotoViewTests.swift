import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private final class SilentLivePhotoDelegate: PHLivePhotoViewDelegate {
    var willBegin = false
    var didEnd = false

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        _ = livePhotoView
        _ = playbackStyle
        willBegin = true
    }

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        _ = livePhotoView
        _ = playbackStyle
        didEnd = true
    }
}

func testLivePhotoViewMuted() {
    let view = PHLivePhotoView()
    precondition(!view.isMuted)
    view.isMuted = true
    precondition(view.isMuted)
}

func testLivePhotoViewContentsRect() {
    let view = PHLivePhotoView()
    view.contentsRect = CGRect(x: 1, y: 2, width: 3, height: 4)
    precondition(view.contentsRect.origin.x == 1)
    precondition(view.contentsRect.size.width == 3)
}

func testLivePhotoViewLivePhotoProperty() {
    let view = PHLivePhotoView()
    precondition(view.livePhoto == nil)
    let photo = PHLivePhoto()
    view.livePhoto = photo
    precondition(view.livePhoto === photo)
}

func testLivePhotoViewPlaybackGestureRecognizer() {
    let view = PHLivePhotoView()
    precondition(view.playbackGestureRecognizer === view.playbackGestureRecognizer)
}

func testLivePhotoViewStartStopPlayback() {
    let view = PHLivePhotoView()
    let probe = SilentLivePhotoDelegate()
    view.delegate = probe
    precondition(view.delegate === probe)
    view.startPlayback(with: .hint)
    precondition(view._lastPlaybackStyle == .hint)
    precondition(view._playbackActive)
    precondition(!probe.willBegin)
    view.startPlayback(with: .full)
    precondition(view._lastPlaybackStyle == .full)
    view.stopPlayback()
    precondition(!view._playbackActive)
    precondition(view._lastPlaybackStyle == .undefined)
    precondition(!probe.didEnd)
}

func testLivePhotoViewBadgeImage() {
    let over = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
    let off = PHLivePhotoView.livePhotoBadgeImage(options: .liveOff)
    precondition(over === over)
    precondition(off === off)
}

func testLivePhotoViewDelegateDefaults() {
    let view = PHLivePhotoView()
    let probe = SilentLivePhotoDelegate()
    precondition(probe.livePhotoView(view, canBeginPlaybackWith: .hint))
    probe.livePhotoView(view, willBeginPlaybackWith: .hint)
    probe.livePhotoView(view, didEndPlaybackWith: .full)
    precondition(probe.willBegin)
    precondition(probe.didEnd)
    precondition(
        probe.livePhotoView(view, extraMinimumTouchDurationFor: UITouch(), with: .full) == 0
    )
}
