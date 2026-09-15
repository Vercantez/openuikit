import Foundation
import AVFoundation

// Depth pass 19 (wave 10 leftover sweep): convert the synchronous lazy
// AsyncSequence combinator witnesses. `AVAsyncSequenceConformances.swift`
// publishes the formal AsyncSequence conformances the iPhoneOS 26.1 graph
// records (every requirement already existed as an Apple-mirroring member),
// so the stdlib's lazy `map` / `compactMap` / `filter` / `drop(while:)` /
// `prefix(while:)` / `prefix(_:)` / `dropFirst` / `flatMap` constructors are
// now callable. Each only builds a lazy sequence value; nothing is
// iterated, so no daemon, hardware, codec, or Apple service success is
// claimed and no `await` appears. Result-type annotations pin which
// overload each call shape selects:
//
// - non-throwing transform -> AsyncMapSequence / AsyncCompactMapSequence /
//   AsyncFlatMapSequence; throwing transform -> AsyncThrowingMapSequence /
//   AsyncThrowingCompactMapSequence / AsyncThrowingFlatMapSequence.
// - non-throwing flatMap over a throwing base selects the overload whose
//   Failure constraint the segment satisfies: an AsyncThrowingStream
//   segment (Failure == any Error) selects `Self.Failure == Segment.Failure`;
//   an AsyncStream segment (Failure == Never) selects
//   `Segment.Failure == Never`.
// - `prefix(while:)` is rethrows, so over a throwing base it needs `try?`
//   (still synchronous); over a Never base it needs none.
// - The three non-throwing `flatMap` overloads are indistinguishable on a
//   Never base (all three where-clauses hold), so those rows stay declared.
// - Async terminal witnesses (`first`, `contains`, `allSatisfy`, `reduce`,
//   `max`/`min`), async `next()`, `Combine` publishers, `FormatStyle` /
//   `SortComparator` / `Equatable`-constrained Sequence witnesses, and
//   service `append`/`load`/`seek`/`image` methods stay declared/deferred.
//
// Every test is top-level, synchronous, and takes no arguments.

enum Wave10CombinatorError: Error { case boom }

func testWave10ImagesLazyCombinators() {
    let images = AVAssetImageGenerator.Images()
    let mapped: AsyncMapSequence<AVAssetImageGenerator.Images, Int> = images.map { _ in 0 }
    _ = mapped
    let mappedThrowing: AsyncThrowingMapSequence<AVAssetImageGenerator.Images, Int> = images.map { (_: AVAssetImageGenerator.Images.Element) -> Int in throw Wave10CombinatorError.boom }
    _ = mappedThrowing
    let compacted: AsyncCompactMapSequence<AVAssetImageGenerator.Images, Int> = images.compactMap { _ in Optional(0) }
    _ = compacted
    let compactedThrowing: AsyncThrowingCompactMapSequence<AVAssetImageGenerator.Images, Int> = images.compactMap { (_: AVAssetImageGenerator.Images.Element) -> Int? in throw Wave10CombinatorError.boom }
    _ = compactedThrowing
    let filtered: AsyncFilterSequence<AVAssetImageGenerator.Images> = images.filter { _ in true }
    _ = filtered
    let dropped: AsyncDropWhileSequence<AVAssetImageGenerator.Images> = images.drop { _ in true }
    _ = dropped
    let prefixedWhile: AsyncPrefixWhileSequence<AVAssetImageGenerator.Images> = images.prefix { _ in true }
    _ = prefixedWhile
    let prefixed: AsyncPrefixSequence<AVAssetImageGenerator.Images> = images.prefix(2)
    _ = prefixed
    let droppedFirst: AsyncDropFirstSequence<AVAssetImageGenerator.Images> = images.dropFirst(1)
    _ = droppedFirst
    let flatThrowing: AsyncThrowingFlatMapSequence<AVAssetImageGenerator.Images, AsyncStream<Int>> = images.flatMap { (_: AVAssetImageGenerator.Images.Element) -> AsyncStream<Int> in throw Wave10CombinatorError.boom }
    _ = flatThrowing
    precondition(true)
}

func testWave10BoundaryTimesLazyCombinators() {
    let times = AVPlayerItemIntegratedTimeline.BoundaryTimes()
    let mapped: AsyncMapSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes, Int> = times.map { _ in 0 }
    _ = mapped
    let mappedThrowing: AsyncThrowingMapSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes, Int> = times.map { (_: CMTime) -> Int in throw Wave10CombinatorError.boom }
    _ = mappedThrowing
    let compacted: AsyncCompactMapSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes, Int> = times.compactMap { _ in Optional(0) }
    _ = compacted
    let compactedThrowing: AsyncThrowingCompactMapSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes, Int> = times.compactMap { (_: CMTime) -> Int? in throw Wave10CombinatorError.boom }
    _ = compactedThrowing
    let filtered: AsyncFilterSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes> = times.filter { _ in true }
    _ = filtered
    let dropped: AsyncDropWhileSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes> = times.drop { _ in true }
    _ = dropped
    let prefixedWhile: AsyncPrefixWhileSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes> = times.prefix { _ in true }
    _ = prefixedWhile
    let prefixed: AsyncPrefixSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes> = times.prefix(2)
    _ = prefixed
    let droppedFirst: AsyncDropFirstSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes> = times.dropFirst(1)
    _ = droppedFirst
    let flatThrowing: AsyncThrowingFlatMapSequence<AVPlayerItemIntegratedTimeline.BoundaryTimes, AsyncStream<Int>> = times.flatMap { (_: CMTime) -> AsyncStream<Int> in throw Wave10CombinatorError.boom }
    _ = flatThrowing
    precondition(true)
}

func testWave10PeriodicTimesLazyCombinators() {
    let times = AVPlayerItemIntegratedTimeline.PeriodicTimes()
    let mapped: AsyncMapSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes, Int> = times.map { _ in 0 }
    _ = mapped
    let mappedThrowing: AsyncThrowingMapSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes, Int> = times.map { (_: CMTime) -> Int in throw Wave10CombinatorError.boom }
    _ = mappedThrowing
    let compacted: AsyncCompactMapSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes, Int> = times.compactMap { _ in Optional(0) }
    _ = compacted
    let compactedThrowing: AsyncThrowingCompactMapSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes, Int> = times.compactMap { (_: CMTime) -> Int? in throw Wave10CombinatorError.boom }
    _ = compactedThrowing
    let filtered: AsyncFilterSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes> = times.filter { _ in true }
    _ = filtered
    let dropped: AsyncDropWhileSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes> = times.drop { _ in true }
    _ = dropped
    let prefixedWhile: AsyncPrefixWhileSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes> = times.prefix { _ in true }
    _ = prefixedWhile
    let prefixed: AsyncPrefixSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes> = times.prefix(2)
    _ = prefixed
    let droppedFirst: AsyncDropFirstSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes> = times.dropFirst(1)
    _ = droppedFirst
    let flatThrowing: AsyncThrowingFlatMapSequence<AVPlayerItemIntegratedTimeline.PeriodicTimes, AsyncStream<Int>> = times.flatMap { (_: CMTime) -> AsyncStream<Int> in throw Wave10CombinatorError.boom }
    _ = flatThrowing
    precondition(true)
}

func testWave10MetricsLazyCombinators() {
    let metrics = AVMetrics<AVMetricEvent>()
    let mapped: AsyncMapSequence<AVMetrics<AVMetricEvent>, Int> = metrics.map { _ in 0 }
    _ = mapped
    let mappedThrowing: AsyncThrowingMapSequence<AVMetrics<AVMetricEvent>, Int> = metrics.map { (_: AVMetricEvent) -> Int in throw Wave10CombinatorError.boom }
    _ = mappedThrowing
    let compacted: AsyncCompactMapSequence<AVMetrics<AVMetricEvent>, Int> = metrics.compactMap { _ in Optional(0) }
    _ = compacted
    let compactedThrowing: AsyncThrowingCompactMapSequence<AVMetrics<AVMetricEvent>, Int> = metrics.compactMap { (_: AVMetricEvent) -> Int? in throw Wave10CombinatorError.boom }
    _ = compactedThrowing
    let filtered: AsyncFilterSequence<AVMetrics<AVMetricEvent>> = metrics.filter { _ in true }
    _ = filtered
    let dropped: AsyncDropWhileSequence<AVMetrics<AVMetricEvent>> = metrics.drop { _ in true }
    _ = dropped
    let prefixedWhile: AsyncPrefixWhileSequence<AVMetrics<AVMetricEvent>>? = try? metrics.prefix { _ in true }
    precondition(prefixedWhile != nil)
    let prefixed: AsyncPrefixSequence<AVMetrics<AVMetricEvent>> = metrics.prefix(2)
    _ = prefixed
    let droppedFirst: AsyncDropFirstSequence<AVMetrics<AVMetricEvent>> = metrics.dropFirst(1)
    _ = droppedFirst
    let flatMatchingFailure: AsyncFlatMapSequence<AVMetrics<AVMetricEvent>, AsyncThrowingStream<Int, any Error>> = metrics.flatMap { _ in AsyncThrowingStream<Int, any Error> { $0.finish() } }
    _ = flatMatchingFailure
    let flatNeverFailure: AsyncFlatMapSequence<AVMetrics<AVMetricEvent>, AsyncStream<Int>> = metrics.flatMap { _ in AsyncStream<Int> { $0.finish() } }
    _ = flatNeverFailure
    let flatThrowing: AsyncThrowingFlatMapSequence<AVMetrics<AVMetricEvent>, AsyncThrowingStream<Int, any Error>> = metrics.flatMap { (_: AVMetricEvent) -> AsyncThrowingStream<Int, any Error> in throw Wave10CombinatorError.boom }
    _ = flatThrowing
}

func testWave10MergedMetricsLazyCombinators() {
    typealias Merged = AVMergedMetrics<AVMetricEvent, AVMetricEvent, String>
    typealias MergedElement = (AVMetricEvent, any AVMetricEventStreamPublisher)
    let metrics = Merged()
    let mapped: AsyncMapSequence<Merged, Int> = metrics.map { _ in 0 }
    _ = mapped
    let mappedThrowing: AsyncThrowingMapSequence<Merged, Int> = metrics.map { (_: MergedElement) -> Int in throw Wave10CombinatorError.boom }
    _ = mappedThrowing
    let compacted: AsyncCompactMapSequence<Merged, Int> = metrics.compactMap { _ in Optional(0) }
    _ = compacted
    let compactedThrowing: AsyncThrowingCompactMapSequence<Merged, Int> = metrics.compactMap { (_: MergedElement) -> Int? in throw Wave10CombinatorError.boom }
    _ = compactedThrowing
    let filtered: AsyncFilterSequence<Merged> = metrics.filter { _ in true }
    _ = filtered
    let dropped: AsyncDropWhileSequence<Merged> = metrics.drop { _ in true }
    _ = dropped
    let prefixedWhile: AsyncPrefixWhileSequence<Merged>? = try? metrics.prefix { _ in true }
    precondition(prefixedWhile != nil)
    let prefixed: AsyncPrefixSequence<Merged> = metrics.prefix(2)
    _ = prefixed
    let droppedFirst: AsyncDropFirstSequence<Merged> = metrics.dropFirst(1)
    _ = droppedFirst
    let flatMatchingFailure: AsyncFlatMapSequence<Merged, AsyncThrowingStream<Int, any Error>> = metrics.flatMap { _ in AsyncThrowingStream<Int, any Error> { $0.finish() } }
    _ = flatMatchingFailure
    let flatNeverFailure: AsyncFlatMapSequence<Merged, AsyncStream<Int>> = metrics.flatMap { _ in AsyncStream<Int> { $0.finish() } }
    _ = flatNeverFailure
    let flatThrowing: AsyncThrowingFlatMapSequence<Merged, AsyncThrowingStream<Int, any Error>> = metrics.flatMap { (_: MergedElement) -> AsyncThrowingStream<Int, any Error> in throw Wave10CombinatorError.boom }
    _ = flatThrowing
}

func testWave10MetricsAsyncIteratorElement() {
    let event = AVMetricEvent()
    let element: AVMetrics<AVMetricEvent>.AsyncIterator.Element = event
    precondition(element === event)
}

func testWave10MergedMetricsAsyncIteratorElement() {
    let element: AVMergedMetrics<AVMetricEvent, AVMetricEvent, String>.AsyncIterator.Element = (AVMetricEvent(), AVPlayerItem())
    precondition((element.1 as? AVPlayerItem) != nil)
}
