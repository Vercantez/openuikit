import AVFoundation
import AVKit
import SwiftUI

@MainActor
private func consumeView<V: View>(_ view: V) {
    _ = view
}

@MainActor
private func iceCubesMediaConsumer(url: URL, muted: Bool) async {
    let player = AVPlayer(url: url)
    player.audiovisualBackgroundPlaybackPolicy = .pauses
    player.preventsDisplaySleepDuringVideoPlayback = false
    player.isMuted = muted
    player.play()
    player.seek(to: CMTime.zero)
    player.pause()
    let _: Notification.Name = .AVPlayerItemDidPlayToEndTime

    try? AVAudioSession.sharedInstance().setActive(
        false,
        options: .notifyOthersOnDeactivation
    )
    try? AVAudioSession.sharedInstance().setCategory(
        .playback,
        options: .duckOthers
    )
    try? AVAudioSession.sharedInstance().setActive(true)

    let asset = AVURLAsset(url: url, options: nil)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.generateCGImageAsynchronously(for: .zero) { _, _, _ in }

    if let session = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPreset1920x1080
    ) {
        session.outputURL = url
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true
        try? await session.export(to: url, as: .mp4)
    }

    consumeView(VideoPlayer(player: player) { EmptyView() })
}
