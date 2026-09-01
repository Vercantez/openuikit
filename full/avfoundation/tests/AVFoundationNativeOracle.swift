import AVFoundation
import AVKit
import SwiftUI

@MainActor
private func consumeView<V: View>(_ view: V) {
    _ = view
}

@MainActor
private func nativeOracle(url: URL, muted: Bool) {
    let half = CMTime(value: 1, timescale: 2)
    let _: CMTime = .zero
    let _: Double = half.seconds

    let player = AVPlayer(url: url)
    player.audiovisualBackgroundPlaybackPolicy = .pauses
    player.preventsDisplaySleepDuringVideoPlayback = false
    player.isMuted = muted
    player.play()
    player.seek(to: .zero)
    player.pause()
    let _: AVPlayerItem? = player.currentItem
    let _: Notification.Name = .AVPlayerItemDidPlayToEndTime

    let audio = AVAudioSession.sharedInstance()
    try? audio.setCategory(.ambient, options: .mixWithOthers)
    try? audio.setCategory(.playback, options: .duckOthers)
    try? audio.setActive(false, options: .notifyOthersOnDeactivation)

    let asset = AVURLAsset(url: url, options: nil)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.generateCGImageAsynchronously(for: .zero) { _, _, _ in }

    let session = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPreset1280x720
    )
    session?.outputURL = url
    session?.outputFileType = .mp4
    session?.shouldOptimizeForNetworkUse = true

    consumeView(VideoPlayer(player: player) { EmptyView() })
    consumeView(VideoPlayer(player: player))
}

private func nativeExport(asset: AVURLAsset, outputURL: URL) async {
    let session = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPreset1920x1080
    )
    try? await session?.export(to: outputURL, as: .mp4)
}
