import Foundation
import AVKit

func testOnCameraCaptureEventPrimarySecondarySync() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        let primary: (AVCaptureEvent) -> Void = { _ in }
        let secondary: (AVCaptureEvent) -> Void = { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: true, primaryAction: primary, secondaryAction: secondary)
        precondition(video.player == nil)
    }
}

func testOnCameraCaptureEventPrimarySecondaryAsync() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        let primary: (AVCaptureEvent) async -> Void = { _ in }
        let secondary: (AVCaptureEvent) async -> Void = { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: true, defaultSoundDisabled: true, primaryAction: primary, secondaryAction: secondary)
        precondition(video.player == nil)
    }
}

func testOnCameraCaptureEventDefaultSoundDisabledPrimarySecondary() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        let primary: (AVCaptureEvent) -> Void = { _ in }
        let secondary: (AVCaptureEvent) -> Void = { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: false, defaultSoundDisabled: true, primaryAction: primary, secondaryAction: secondary)
        precondition(video.player == nil)
    }
}

func testOnCameraCaptureEventAsyncAction() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        let action: (AVCaptureEvent) async -> Void = { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: true, defaultSoundDisabled: false, action: action)
        precondition(video.player == nil)
    }
}

func testOnCameraCaptureEventDefaultSoundDisabledAction() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        let action: (AVCaptureEvent) -> Void = { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: false, defaultSoundDisabled: true, action: action)
        precondition(video.player == nil)
    }
}

func testOnCameraCaptureEventAction() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        let action: (AVCaptureEvent) -> Void = { _ in }
        _ = video.onCameraCaptureEvent(isEnabled: true, action: action)
        precondition(video.player == nil)
    }
}
