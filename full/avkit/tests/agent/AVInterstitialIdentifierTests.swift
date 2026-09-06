import Foundation
import AVKit

func testInterstitialTimeRangeClassRoundTrip() {
    let range = CMTimeRange(
        start: CMTime(value: 10, timescale: 1),
        duration: CMTime(value: 5, timescale: 1)
    )
    let interstitial = AVInterstitialTimeRange(timeRange: range)
    _ = interstitial
    precondition(interstitial.isEqual(AVInterstitialTimeRange(timeRange: range)))
    let copy = interstitial.copy() as! AVInterstitialTimeRange
    precondition(copy.isEqual(interstitial))
    precondition(copy !== interstitial)
}

func testInterstitialTimeRangeTimeRange() {
    let range = CMTimeRange(
        start: CMTime(value: 10, timescale: 1),
        duration: CMTime(value: 5, timescale: 1)
    )
    let interstitial = AVInterstitialTimeRange(timeRange: range)
    precondition(interstitial.timeRange.start.value == 10)
    precondition(interstitial.timeRange.duration.value == 5)
}

func testInterstitialTimeRangeInitCoder() {
    let range = CMTimeRange(
        start: CMTime(value: 3, timescale: 1),
        duration: CMTime(value: 4, timescale: 1)
    )
    let interstitial = AVInterstitialTimeRange(timeRange: range)
    precondition(AVInterstitialTimeRange.supportsSecureCoding == true)
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: interstitial,
        requiringSecureCoding: true
    )
    let restored = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: AVInterstitialTimeRange.self,
        from: data
    )
    precondition(restored?.isEqual(interstitial) == true)
    precondition(restored?.timeRange.start.value == 3)
}

func testPlayerItemExternalMetadata() {
    avkitOnMain {
        let item = AVPlayerItem()
        precondition(item.externalMetadata.isEmpty)
        item.externalMetadata = [AVMetadataItem()]
        precondition(item.externalMetadata.count == 1)
    }
}

func testPlayerItemInterstitialTimeRanges() {
    avkitOnMain {
        let item = AVPlayerItem()
        precondition(item.interstitialTimeRanges.isEmpty)
        let range = AVInterstitialTimeRange(
            timeRange: CMTimeRange(start: .zero, duration: .zero)
        )
        item.interstitialTimeRanges = [range]
        precondition(item.interstitialTimeRanges.count == 1)
        precondition(item.interstitialTimeRanges[0].isEqual(range))
    }
}
