import Foundation
import AVFoundation

// Depth pass 17 (wave 8 leftover sweep): convert the remaining synchronous
// declared rows that already compile with fail-closed bodies. Every test is
// top-level, synchronous, and takes no arguments. No hardware, daemon,
// FairPlay, codec, or Apple service success is claimed.

func testDepth17CIImageFilteringRequest() {
    let request = AVAsynchronousCIImageFilteringRequest()
    precondition(request.renderSize.width == 0 && request.renderSize.height == 0)
    precondition(request.compositionTime == .zero)
    let source = request.sourceImage
    request.finish(with: source, context: nil)
    request.finish(with: source, context: CIContext())
    struct Depth17FilterError: Error {}
    request.finish(with: Depth17FilterError())
}

func testDepth17CoreAnimationTool() {
    _ = AVVideoCompositionCoreAnimationTool()
    let configured = AVVideoCompositionCoreAnimationTool(
        configuration: AVVideoCompositionCoreAnimationTool.Configuration())
    _ = configured
}

final class Depth17MetricPublisherWitness: NSObject, AVMetricEventStreamPublisher, @unchecked Sendable {
    func metrics<MetricEvent>(forType metricType: MetricEvent.Type) -> AVMetrics<MetricEvent> where MetricEvent: AVMetricEvent {
        return AVMetrics<MetricEvent>()
    }
    func allMetrics() -> AVMetrics<AVMetricEvent> {
        return AVMetrics<AVMetricEvent>()
    }
}

func testDepth17MetricEventStreamPublisher() {
    let witness = Depth17MetricPublisherWitness()
    let publisher: any AVMetricEventStreamPublisher = witness
    let perType: AVMetrics<AVMetricErrorEvent> = publisher.metrics(forType: AVMetricErrorEvent.self)
    let all: AVMetrics<AVMetricEvent> = publisher.allMetrics()
    _ = (perType, all)
}
