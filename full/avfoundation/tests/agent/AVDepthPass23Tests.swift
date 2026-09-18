import Foundation
import AVFoundation

// Depth pass 23 (wave 14): async key-value-loading twins for AVAssetTrack /
// AVMetadataItem plus the Equatable-constrained `AsyncSequence.contains`
// witness on AVMetrics. The sealed runner awaits each `async` test, so
// throwing calls are caught inside their tests (the runner invokes
// `await name()`, never `try`). Nothing awaits a service, daemon, or
// hardware: track/item loads project stored state synchronously and the
// metrics sequence is empty, so every `await` completes immediately.

func testWave14TrackAsyncPropertyLoad() async {
    let track = AVAssetTrack()
    switch track.status(of: AVPartialAsyncProperty<AVAssetTrack>.isPlayable) {
    case .notYetLoaded:
        break
    default:
        preconditionFailure("isPlayable must start notYetLoaded")
    }
    do {
        let playable: Bool = try await track.load(AVPartialAsyncProperty<AVAssetTrack>.isPlayable)
        precondition(playable == false)
    } catch {
        preconditionFailure("track isPlayable load must complete, not throw")
    }
    switch track.status(of: AVPartialAsyncProperty<AVAssetTrack>.isPlayable) {
    case .loaded(let playable):
        precondition(playable == false)
    default:
        preconditionFailure("isPlayable should be loaded after load()")
    }
    do {
        let size: CGSize = try await track.load(AVPartialAsyncProperty<AVAssetTrack>.naturalSize)
        precondition(size.width == 0 && size.height == 0)
    } catch {
        preconditionFailure("track naturalSize load must complete, not throw")
    }
    // `formatDescriptions` projects `[Any]` while its token is
    // `[CMFormatDescription]`; it stays fail-closed rather than
    // fabricating media data.
    do {
        let _: [CMFormatDescription] = try await track.load(AVPartialAsyncProperty<AVAssetTrack>.formatDescriptions)
        preconditionFailure("formatDescriptions must stay fail-closed")
    } catch {
    }
}

func testWave14TrackAsyncTripleLoad() async {
    let track = AVAssetTrack()
    do {
        let triple: (Bool, CMTimeRange, CGSize) = try await track.load(
            AVPartialAsyncProperty<AVAssetTrack>.isPlayable,
            AVPartialAsyncProperty<AVAssetTrack>.timeRange,
            AVPartialAsyncProperty<AVAssetTrack>.naturalSize
        )
        precondition(triple.0 == false)
        precondition(!triple.1.duration.isValid || triple.1.duration.seconds == 0)
        precondition(triple.2.width == 0 && triple.2.height == 0)
    } catch {
        preconditionFailure("track triple load must complete, not throw")
    }
}

func testWave14ItemAsyncPropertyLoad() async {
    let item = AVMutableMetadataItem()
    switch item.status(of: AVPartialAsyncProperty<AVMetadataItem>.dateValue) {
    case .notYetLoaded:
        break
    default:
        preconditionFailure("dateValue must start notYetLoaded")
    }
    item.value = "hello" as NSString
    do {
        let string: String? = try await item.load(AVPartialAsyncProperty<AVMetadataItem>.stringValue)
        precondition(string == "hello")
    } catch {
        preconditionFailure("item stringValue load must complete, not throw")
    }
    switch item.status(of: AVPartialAsyncProperty<AVMetadataItem>.stringValue) {
    case .loaded(let string):
        precondition(string == "hello")
    default:
        preconditionFailure("stringValue should be loaded after load()")
    }
}

func testWave14ItemAsyncTripleLoad() async {
    let item = AVMutableMetadataItem()
    item.value = "hello" as NSString
    item.extraAttributes = [:]
    do {
        let triple: (String?, (any NSCopying & NSObjectProtocol)?, [AVMetadataExtraAttributeKey: Any]?) = try await item.load(
            AVPartialAsyncProperty<AVMetadataItem>.stringValue,
            AVPartialAsyncProperty<AVMetadataItem>.value,
            AVPartialAsyncProperty<AVMetadataItem>.extraAttributes
        )
        precondition(triple.0 == "hello")
        precondition((triple.1 as? NSString) as String? == "hello")
        precondition(triple.2?.isEmpty == true)
    } catch {
        preconditionFailure("item triple load must complete, not throw")
    }
}

func testWave14MetricsContainsElement() async {
    let metrics = AVMetrics<AVMetricEvent>()
    let event = AVMetricEvent()
    do {
        let found = try await metrics.contains(event)
        precondition(found == false)
    } catch {
        preconditionFailure("contains over empty metrics must complete, not throw")
    }
}
