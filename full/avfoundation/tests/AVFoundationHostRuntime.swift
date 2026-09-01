@_spi(OpenUIKitHost) import AVFoundation
import CoreGraphics
import Foundation

private final class EventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [AVFoundationPortable.PlayerEvent] = []

    func append(_ event: AVFoundationPortable.PlayerEvent) {
        lock.withLock { storage.append(event) }
    }

    var count: Int { lock.withLock { storage.count } }
}

@main
struct AVFoundationHostRuntime {
    static func main() async throws {
        let half = CMTime(value: 1, timescale: 2)
        let third = CMTime(value: 1, timescale: 3)
        let sum = CMTimeAdd(half, third)
        precondition(sum.value == 5 && sum.timescale == 6)
        precondition(CMTimeCompare(sum, CMTime(value: 5, timescale: 6)) == 0)
        precondition(CMTimeSubtract(sum, half) == third)
        precondition(CMTime(seconds: 1.25, preferredTimescale: 4).value == 5)
        let range = CMTimeRange(
            start: half,
            duration: CMTime(value: 2, timescale: 1)
        )
        precondition(range.containsTime(CMTime(value: 2, timescale: 1)))
        precondition(!range.containsTime(range.end))

        AVFoundationPortable._resetHostServices()
        precondition(AVFoundationPortable.playbackCapability == .stateOnly)
        precondition(AVFoundationPortable.exportCapability == .stateOnly)

        let sourceURL = URL(fileURLWithPath: "/tmp/openav-input.mp4")
        let player = AVPlayer(url: sourceURL)
        let events = EventRecorder()
        AVFoundationPortable._installPlayerEventHandler { event in
            events.append(event)
        }
        precondition(AVFoundationPortable.playbackCapability == .hostDriven)
        player.play()
        player.seek(to: half)
        player.isMuted = true
        player.pause()
        precondition(player.rate == 0)
        precondition(player.currentTime() == half)
        precondition(player.isMuted)
        precondition(events.count == 4)

        let audio = AVAudioSession.sharedInstance()
        try audio.setCategory(.playback, options: [.duckOthers, .mixWithOthers])
        try audio.setActive(true)
        precondition(audio._portableState.category == .playback)
        precondition(audio._portableState.categoryOptions.contains(.duckOthers))
        precondition(audio._portableState.isActive)

        let asset = AVURLAsset(url: sourceURL)
        let defaultExport = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1280x720
        )!
        do {
            try await defaultExport.export(
                to: URL(fileURLWithPath: "/tmp/openav-default.mp4"),
                as: .mp4
            )
            preconditionFailure("default export must fail closed")
        } catch let error as AVFoundationPortableError {
            precondition(
                error == .exportUnavailable(preset: AVAssetExportPreset1280x720)
            )
        }
        precondition(defaultExport.status == .failed)

        let outputURL = URL(fileURLWithPath: "/tmp/openav-host-output.mp4")
        defer { try? FileManager.default.removeItem(at: outputURL) }
        AVFoundationPortable._installExportHandler { request in
            precondition(request.sourceURL == sourceURL)
            precondition(request.outputFileType == .mp4)
            try Data("portable-media".utf8).write(to: request.outputURL)
        }
        let hostExport = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1920x1080
        )!
        hostExport.shouldOptimizeForNetworkUse = true
        try await hostExport.export(to: outputURL, as: .mp4)
        precondition(hostExport.status == .completed)
        precondition(hostExport.progress == 1)
        let exportedData = try Data(contentsOf: outputURL)
        precondition(exportedData == Data("portable-media".utf8))

        let generator = AVAssetImageGenerator(asset: asset)
        var defaultFrameError: AVFoundationPortableError?
        generator.generateCGImageAsynchronously(for: .zero) { image, _, error in
            precondition(image == nil)
            defaultFrameError = error as? AVFoundationPortableError
        }
        precondition(defaultFrameError == .frameGenerationUnavailable(sourceURL))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        let expectedImage = context.makeImage()!
        AVFoundationPortable._installFrameHandler { url, time in
            precondition(url == sourceURL)
            precondition(time == .zero)
            return expectedImage
        }
        var generated = false
        generator.generateCGImageAsynchronously(for: .zero) { image, time, error in
            precondition(image != nil)
            precondition(time == .zero)
            precondition(error == nil)
            generated = true
        }
        precondition(generated)

        precondition(
            Notification.Name.AVPlayerItemDidPlayToEndTime.rawValue
                == "AVPlayerItemDidPlayToEndTimeNotification"
        )
        AVFoundationPortable._resetHostServices()

        print(
            "AVFOUNDATION_HOST_OK time=rational player=host-driven "
                + "audio=state export=fail-closed,host-driven frame=fail-closed,host-driven"
        )
    }
}
