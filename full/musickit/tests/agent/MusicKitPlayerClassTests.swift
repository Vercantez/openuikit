import Foundation
import MusicKit

func testMusicPlayerClass() {
    let player: MusicPlayer = ApplicationMusicPlayer.shared
    precondition(player.state.playbackStatus == .stopped || player.state.playbackStatus == .paused
        || player.state.playbackStatus == .playing || player.state.playbackStatus == .interrupted
        || player.state.playbackStatus == .seekingForward || player.state.playbackStatus == .seekingBackward)
    player.pause()
    player.stop()
}
