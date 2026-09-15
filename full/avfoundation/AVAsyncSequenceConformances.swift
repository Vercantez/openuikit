import Foundation

// Wave 10: formal AsyncSequence conformances for the five metric/image/
// timeline sequence families. Every requirement is already satisfied by the
// existing Apple-mirroring members (`Element`, `AsyncIterator`,
// `makeAsyncIterator()`, and the fail-closed `async next()` that returns
// nil); these empty extensions only publish the conformance the iPhoneOS
// 26.1 graph records through its SYNTHESIZED witness rows. No daemon,
// hardware, codec, or Apple service behavior is added: iteration still
// yields nothing on this host.

extension AVAssetImageGenerator.Images: AsyncSequence, AsyncIteratorProtocol {}

extension AVPlayerItemIntegratedTimeline.BoundaryTimes: AsyncSequence {}

extension AVPlayerItemIntegratedTimeline.BoundaryTimes.Iterator: AsyncIteratorProtocol {}

extension AVPlayerItemIntegratedTimeline.PeriodicTimes: AsyncSequence {}

extension AVPlayerItemIntegratedTimeline.PeriodicTimes.Iterator: AsyncIteratorProtocol {}

extension AVMetrics: AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
}

extension AVMetrics.AsyncIterator: AsyncIteratorProtocol {}

extension AVMergedMetrics: AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
}

extension AVMergedMetrics.AsyncIterator: AsyncIteratorProtocol {}
