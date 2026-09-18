import Foundation
import AVFoundation

// Depth pass 22 (wave 13 async sweep): convert the remaining async-shaped
// `declared` rows. The sealed runner is now `@main async` and awaits
// top-level `func test*() async`, so every fail-closed `async` method and
// every async `AsyncSequence` terminal consumer is exercised directly.
// No RunLoop, DispatchQueue.main, or semaphore is used. The runner invokes
// each test as `await name()` (never `try`), so every throwing call below
// is caught inside its test; `await` never appears inside a `precondition`
// autoclosure.
//
// Every sequence below is empty on this host (each fail-closed `next()`
// returns nil immediately), so every awaited terminal completes without
// waiting on hardware, a daemon, a codec, or a service:
// - `allSatisfy` over zero elements is true; `first(where:)` is nil;
//   `contains(where:)` is false; `reduce`/`reduce(into:)` return the seed.
// - `max(by:)` / `min(by:)` over zero elements are nil (predicate never runs).
// - `max()` / `min()` / `contains(_:)` (Comparable/Equatable elements) over
//   zero `CMTime` values are nil / nil / false.
// Throwing-base families (`AVMetrics`, `AVMergedMetrics`) need `try await`;
// Never-base families (`Images`, `BoundaryTimes`, `PeriodicTimes`) need only
// `await`. Service `append` / `image` / configuration methods throw the same
// fail-closed errors the synchronous twins already pin
// (`mediaServiceUnavailable`, `noImageAtTime`); `seek(to: Date)` reports
// false and chapter loads return [].

typealias Wave13Merged = AVMergedMetrics<AVMetricEvent, AVMetricEvent, String>

func testWave13AsyncPlayerItemSeekToDate() async {
    let item = AVPlayerItem(asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave13-missing.mp4")))
    let seeker: (Date) async -> Bool = item.seek(to:)
    let finished = await seeker(Date())
    precondition(!finished)
}

func testWave13AsyncCaptionReceiverAppends() async {
    let receiver = AVAssetWriterInput.CaptionReceiver()
    let caption = AVCaption("wave13", timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600)))
    do {
        try await receiver.append(caption)
        preconditionFailure("caption append must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
    do {
        try await receiver.append(AVCaptionGroup())
        preconditionFailure("caption-group append must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
}

func testWave13AsyncMetadataReceiverAppend() async {
    let receiver = AVAssetWriterInput.MetadataReceiver()
    let group = AVTimedMetadataGroup(items: [], timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600)))
    do {
        try await receiver.append(group)
        preconditionFailure("metadata append must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
}

func testWave13AsyncPixelBufferReceiverAppend() async {
    let receiver = AVAssetWriterInput.PixelBufferReceiver()
    do {
        try await receiver.append(CVReadOnlyPixelBuffer(), with: .zero)
        preconditionFailure("pixel-buffer append must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
}

func testWave13AsyncSampleBufferReceiverAppend() async {
    let receiver = AVAssetWriterInput.SampleBufferReceiver()
    do {
        try await receiver.append(CMReadySampleBuffer(content: CMSampleBuffer.DynamicContent.portable))
        preconditionFailure("sample-buffer append must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
}

func testWave13AsyncTaggedPixelBufferGroupReceiverAppend() async {
    let receiver = AVAssetWriterInput.TaggedPixelBufferGroupReceiver()
    do {
        try await receiver.append([CMTaggedDynamicBuffer()], with: .zero)
        preconditionFailure("tagged-buffer-group append must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
}

func testWave13AsyncVideoCompositionConfiguration() async {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave13-missing.mp4"))
    do {
        let _ = try await AVVideoComposition.Configuration(for: asset, prototypeInstruction: nil)
        preconditionFailure("configuration(for:) must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
    do {
        let _ = try await AVVideoComposition(applyingFiltersTo: asset, applier: { _ in AVCIImageFilteringResult() })
        preconditionFailure("applyingFiltersTo must fail closed")
    } catch {
        precondition((error as? AVFoundationPortableError) == .mediaServiceUnavailable)
    }
}

func testWave13AsyncReaderProviderNext() async {
    let reader = AVAssetReader()
    let provider: AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>> = reader.outputProvider(for: AVAssetReaderOutput())
    do {
        let next = try await provider.next()
        precondition(next == nil)
    } catch {
        preconditionFailure("empty provider next must not throw")
    }
}

func testWave13AsyncImageAtTime() async {
    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave13-missing.mp4")))
    do {
        let _ = try await generator.image(at: .zero)
        preconditionFailure("image(at:) must fail closed")
    } catch {
        precondition((error as? AVError)?.code == .noImageAtTime)
    }
}

func testWave13AsyncImagesIteratorNext() async {
    var images = AVAssetImageGenerator.Images()
    let first = await images.next()
    precondition(first == nil)
    let second = await images.next()
    precondition(second == nil)
}

func testWave13AsyncBoundaryTimesIteratorNext() async {
    var iterator = AVPlayerItemIntegratedTimeline.BoundaryTimes.Iterator()
    let first = await iterator.next()
    precondition(first == nil)
    let second = await iterator.next()
    precondition(second == nil)
}

func testWave13AsyncPeriodicTimesIteratorNext() async {
    var iterator = AVPlayerItemIntegratedTimeline.PeriodicTimes.Iterator()
    let first = await iterator.next()
    precondition(first == nil)
    let second = await iterator.next()
    precondition(second == nil)
}

func testWave13AsyncMetricsIteratorNext() async {
    var iterator = AVMetrics<AVMetricEvent>.AsyncIterator()
    do {
        let first = try await iterator.next()
        precondition(first == nil)
        let second = try await iterator.next()
        precondition(second == nil)
    } catch {
        preconditionFailure("empty metrics iterator next must not throw")
    }
}

func testWave13AsyncMergedMetricsIteratorNext() async {
    var iterator = Wave13Merged.AsyncIterator()
    do {
        let first = try await iterator.next()
        precondition(first == nil)
        let second = try await iterator.next()
        precondition(second == nil)
    } catch {
        preconditionFailure("empty merged-metrics iterator next must not throw")
    }
}

func testWave13AsyncChapterMetadataGroups() async {
    let asset = AVURLAsset(url: URL(fileURLWithPath: "/tmp/wave13-missing.mp4"))
    do {
        let groups = try await asset.loadChapterMetadataGroups(withTitleLocale: Locale(identifier: "en"), containingItemsWithCommonKeys: [])
        precondition(groups.isEmpty)
    } catch {
        preconditionFailure("chapter load over no media must not throw")
    }
}

func testWave13AsyncAllSatisfy() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().allSatisfy { _ in true }
        precondition(metrics)
        let merged = try await Wave13Merged().allSatisfy { _ in true }
        precondition(merged)
    } catch {
        preconditionFailure("empty allSatisfy must not throw")
    }
    let images = await AVAssetImageGenerator.Images().allSatisfy { _ in true }
    precondition(images)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().allSatisfy { _ in true }
    precondition(boundary)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().allSatisfy { _ in true }
    precondition(periodic)
}

func testWave13AsyncMaxByElement() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().max { _, _ in true }
        precondition(metrics == nil)
        let merged = try await Wave13Merged().max { _, _ in true }
        precondition(merged == nil)
    } catch {
        preconditionFailure("empty max(by:) must not throw")
    }
    let images = await AVAssetImageGenerator.Images().max { _, _ in true }
    precondition(images == nil)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().max { _, _ in true }
    precondition(boundary == nil)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().max { _, _ in true }
    precondition(periodic == nil)
}

func testWave13AsyncMinByElement() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().min { _, _ in true }
        precondition(metrics == nil)
        let merged = try await Wave13Merged().min { _, _ in true }
        precondition(merged == nil)
    } catch {
        preconditionFailure("empty min(by:) must not throw")
    }
    let images = await AVAssetImageGenerator.Images().min { _, _ in true }
    precondition(images == nil)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().min { _, _ in true }
    precondition(boundary == nil)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().min { _, _ in true }
    precondition(periodic == nil)
}

func testWave13AsyncFirstWhere() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().first { _ in true }
        precondition(metrics == nil)
        let merged = try await Wave13Merged().first { _ in true }
        precondition(merged == nil)
    } catch {
        preconditionFailure("empty first(where:) must not throw")
    }
    let images = await AVAssetImageGenerator.Images().first { _ in true }
    precondition(images == nil)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().first { _ in true }
    precondition(boundary == nil)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().first { _ in true }
    precondition(periodic == nil)
}

func testWave13AsyncReduceInto() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().reduce(into: 0) { count, _ in count += 1 }
        precondition(metrics == 0)
        let merged = try await Wave13Merged().reduce(into: 0) { count, _ in count += 1 }
        precondition(merged == 0)
    } catch {
        preconditionFailure("empty reduce(into:) must not throw")
    }
    let images = await AVAssetImageGenerator.Images().reduce(into: 0) { count, _ in count += 1 }
    precondition(images == 0)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().reduce(into: 0) { count, _ in count += 1 }
    precondition(boundary == 0)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().reduce(into: 0) { count, _ in count += 1 }
    precondition(periodic == 0)
}

func testWave13AsyncReduce() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().reduce(0) { count, _ in count + 1 }
        precondition(metrics == 0)
        let merged = try await Wave13Merged().reduce(0) { count, _ in count + 1 }
        precondition(merged == 0)
    } catch {
        preconditionFailure("empty reduce must not throw")
    }
    let images = await AVAssetImageGenerator.Images().reduce(0) { count, _ in count + 1 }
    precondition(images == 0)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().reduce(0) { count, _ in count + 1 }
    precondition(boundary == 0)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().reduce(0) { count, _ in count + 1 }
    precondition(periodic == 0)
}

func testWave13AsyncContainsWhere() async {
    do {
        let metrics = try await AVMetrics<AVMetricEvent>().contains { _ in true }
        precondition(!metrics)
        let merged = try await Wave13Merged().contains { _ in true }
        precondition(!merged)
    } catch {
        preconditionFailure("empty contains(where:) must not throw")
    }
    let images = await AVAssetImageGenerator.Images().contains { _ in true }
    precondition(!images)
    let boundary = await AVPlayerItemIntegratedTimeline.BoundaryTimes().contains { _ in true }
    precondition(!boundary)
    let periodic = await AVPlayerItemIntegratedTimeline.PeriodicTimes().contains { _ in true }
    precondition(!periodic)
}

func testWave13AsyncTimelineComparableMinMax() async {
    let boundary = AVPlayerItemIntegratedTimeline.BoundaryTimes()
    let boundaryMax = await boundary.max()
    precondition(boundaryMax == nil)
    let boundaryMin = await boundary.min()
    precondition(boundaryMin == nil)
    let periodic = AVPlayerItemIntegratedTimeline.PeriodicTimes()
    let periodicMax = await periodic.max()
    precondition(periodicMax == nil)
    let periodicMin = await periodic.min()
    precondition(periodicMin == nil)
}

func testWave13AsyncTimelineContainsElement() async {
    let boundaryContains = await AVPlayerItemIntegratedTimeline.BoundaryTimes().contains(.zero)
    precondition(!boundaryContains)
    let periodicContains = await AVPlayerItemIntegratedTimeline.PeriodicTimes().contains(.zero)
    precondition(!periodicContains)
}
