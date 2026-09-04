import AVFoundation
import Foundation

/// Isolated-host identity probe: Foundation values pass through public AVFoundation APIs.
func avfoundationDependencyIdentityProbe() {
    let url = URL(fileURLWithPath: "/tmp/openav-identity.mp4")
    let asset = AVURLAsset(url: url)
    precondition(asset.url == url)
    let item = AVPlayerItem(url: url)
    precondition(item.url == url)
    let player = AVPlayer(playerItem: item)
    precondition(player.currentItem === item)
    let name: Notification.Name = .AVPlayerItemDidPlayToEndTime
    precondition(!name.rawValue.isEmpty)
    _ = FileManager.default
}
