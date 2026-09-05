import Foundation
import AVKit

func testVideoPlayerStructStoresPlayer() {
    avkitOnMain {
        let video = VideoPlayer(player: nil)
        precondition(video.player == nil)
        let player = AVPlayer()
        let playing = VideoPlayer(player: player)
        precondition(playing.player === player)
    }
}

func testVideoPlayerBodyTypealias() {
    avkitOnMain {
        _ = VideoPlayer<EmptyView>.Body.self
        let video = VideoPlayer(player: nil)
        _ = video.body
    }
}

func testVideoPlayerBody() {
    avkitOnMain {
        let video = VideoPlayer(player: AVPlayer()) {
            EmptyView()
        }
        _ = video.body
    }
}

func testVideoPlayerInitPlayerVideoOverlay() {
    avkitOnMain {
        let player = AVPlayer()
        let video = VideoPlayer(player: player) {
            EmptyView()
        }
        precondition(video.player === player)
        _ = video.body
    }
}

func testVideoPlayerInitPlayer() {
    avkitOnMain {
        let player = AVPlayer(url: URL(fileURLWithPath: "/tmp/clip.m4v"))
        player.rate = 1
        let video = VideoPlayer(player: player)
        precondition(video.player === player)
        precondition(video.openUIKitHostCaption == "clip.m4v\nPlaying")
        player.rate = 0
        precondition(VideoPlayer(player: player).openUIKitHostCaption == "clip.m4v\nPaused")
        precondition(VideoPlayer(player: nil).openUIKitHostCaption == "No Video")
    }
}
