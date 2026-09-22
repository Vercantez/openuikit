// AVFoundation / AVKit / MediaPlayer surface ios-oss uses, read on a private
// iPhone 16 / iOS 26.1 simulator (scripts/avmedia_probe_sim.sh). One
// `key=value` line per measurement; transcript:
// docs/agent_reports/ios-oss-launch3-avmedia-oracle-ios26.1.json.
//
// Reads: AVAudioSession defaults, raw strings of the categories / modes the
// app sets, setCategory / setActive outcomes, notification names;
// AVPlayer / AVPlayerItem defaults, what play() does to rate before and
// after an item, an unreachable URL's item status after a run-loop turn,
// seek completion, periodic observer; AVPlayerLayer defaults and gravity raw
// strings; AVAssetImageGenerator defaults and its answer for an unreachable
// asset; AVPlayerViewController and MPVolumeView defaults.
import UIKit
import AVFoundation
import AVKit
import MediaPlayer

func out(_ key: String, _ value: Any?) {
    if let value { print("\(key)=\(value)") } else { print("\(key)=nil") }
}

func spin(_ seconds: Double) { RunLoop.main.run(until: Date().addingTimeInterval(seconds)) }

func timeDesc(_ t: CMTime) -> String {
    "value=\(t.value) timescale=\(t.timescale) flags=\(t.flags.rawValue) numeric=\(t.isNumeric) seconds=\(CMTimeGetSeconds(t))"
}

@MainActor
func measure() {
    let s = AVAudioSession.sharedInstance()
    out("session.category", s.category.rawValue)
    out("session.mode", s.mode.rawValue)
    out("session.categoryOptions", s.categoryOptions.rawValue)
    out("session.outputVolume", s.outputVolume)
    out("category.playback", AVAudioSession.Category.playback.rawValue)
    out("category.ambient", AVAudioSession.Category.ambient.rawValue)
    out("category.soloAmbient", AVAudioSession.Category.soloAmbient.rawValue)
    out("mode.default", AVAudioSession.Mode.default.rawValue)
    out("mode.moviePlayback", AVAudioSession.Mode.moviePlayback.rawValue)
    out("setActiveOptions.notifyOthers", AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation.rawValue)
    out("note.outputMuteState", AVAudioSession.outputMuteStateChangeNotification.rawValue)
    do {
        try s.setCategory(.playback, mode: .default, options: [])
        out("setCategory.playback", "ok")
    } catch { out("setCategory.playback", "throws \((error as NSError).code)") }
    out("session.category.afterSet", s.category.rawValue)
    do {
        try s.setActive(true)
        out("setActive.true", "ok")
    } catch { out("setActive.true", "throws \((error as NSError).code)") }
    do {
        try s.setActive(false, options: .notifyOthersOnDeactivation)
        out("setActive.false", "ok")
    } catch { out("setActive.false", "throws \((error as NSError).code)") }

    out("note.didPlayToEnd", NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue)
    out("note.failedToPlayToEnd", NSNotification.Name.AVPlayerItemFailedToPlayToEndTime.rawValue)
    out("note.playbackStalled", AVPlayerItem.playbackStalledNotification.rawValue)

    let p = AVPlayer()
    out("player.rate", p.rate)
    out("player.status", p.status.rawValue)
    out("player.currentItem.isNil", p.currentItem == nil)
    out("player.isMuted", p.isMuted)
    out("player.volume", p.volume)
    out("player.timeControlStatus", p.timeControlStatus.rawValue)
    out("player.currentTime", timeDesc(p.currentTime()))
    p.play()
    out("player.noItem.play.rate", p.rate)
    out("player.noItem.play.timeControlStatus", p.timeControlStatus.rawValue)
    p.pause()
    out("player.noItem.pause.rate", p.rate)

    let bad = URL(string: "https://example.invalid/video.mp4")!
    let item = AVPlayerItem(url: bad)
    out("item.status", item.status.rawValue)
    out("item.error.isNil", item.error == nil)
    out("item.duration", timeDesc(item.duration))
    p.replaceCurrentItem(with: item)
    out("player.withItem.currentItem.same", p.currentItem === item)
    p.play()
    out("player.withItem.play.rate", p.rate)
    out("player.withItem.play.timeControlStatus", p.timeControlStatus.rawValue)
    spin(3)
    out("item.after3s.status", item.status.rawValue)
    out("item.after3s.error", (item.error as NSError?).map { "\($0.domain) \($0.code)" })
    out("player.after3s.rate", p.rate)
    out("player.after3s.status", p.status.rawValue)
    out("player.after3s.timeControlStatus", p.timeControlStatus.rawValue)
    var seekResult: Bool?
    p.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { seekResult = $0 }
    spin(0.5)
    out("player.seek.finished", seekResult)
    var ticks = 0
    let token = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main) { _ in ticks += 1 }
    spin(0.5)
    out("player.periodicObserver.ticks.0.5s", ticks)
    p.removeTimeObserver(token)
    p.isMuted = true
    out("player.isMuted.set", p.isMuted)
    p.replaceCurrentItem(with: nil)
    out("player.replaceNil.currentItem.isNil", p.currentItem == nil)
    let p2 = AVPlayer(url: bad)
    out("player.url.currentItem.isNil", p2.currentItem == nil)

    let layer = AVPlayerLayer()
    out("layer.videoGravity", layer.videoGravity.rawValue)
    out("gravity.resizeAspectFill", AVLayerVideoGravity.resizeAspectFill.rawValue)
    out("gravity.resize", AVLayerVideoGravity.resize.rawValue)
    out("layer.player.isNil", layer.player == nil)
    out("layer.isReadyForDisplay", layer.isReadyForDisplay)
    out("layer.chain", String(describing: type(of: layer).superclass()!))

    let asset = AVURLAsset(url: bad)
    let gen = AVAssetImageGenerator(asset: asset)
    out("generator.appliesPreferredTrackTransform", gen.appliesPreferredTrackTransform)
    out("generator.maximumSize", gen.maximumSize)
    var genResult = "none"
    gen.generateCGImagesAsynchronously(forTimes: [NSValue(time: .zero)]) { _, image, _, result, error in
        genResult = "result=\(result.rawValue) image=\(image != nil) error=\((error as NSError?).map { "\($0.domain) \($0.code)" } ?? "nil")"
    }
    spin(3)
    out("generator.unreachable", genResult)

    let vc = AVPlayerViewController()
    out("playerVC.player.isNil", vc.player == nil)
    out("playerVC.showsPlaybackControls", vc.showsPlaybackControls)
    out("playerVC.videoGravity", vc.videoGravity.rawValue)
    out("playerVC.chain", String(describing: AVPlayerViewController.superclass()!))

    let vol = MPVolumeView(frame: .zero)
    out("volumeView.frame", vol.frame)
    out("volumeView.subviews", vol.subviews.count)
    out("volumeView.intrinsic", vol.intrinsicContentSize)
}

MainActor.assumeIsolated { measure() }
print("done=1")
