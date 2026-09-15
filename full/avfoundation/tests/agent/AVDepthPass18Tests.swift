import Foundation
import AVFoundation

// Depth pass 18 (wave 9 leftover sweep): convert the remaining synchronous
// declared rows that compile with fail-closed bodies. Seven NSCoding
// init(coder:) witnesses decode Apple archives, which is impossible on
// Linux, so every one returns nil (never Apple round-trip success). The two
// CALayer-backed AVVideoCompositionCoreAnimationTool factory inits store
// their layers and render nothing. Every test is top-level, synchronous,
// and takes no arguments. No hardware, daemon, FairPlay, codec, or Apple
// service success is claimed.

/// Concrete NSCoder with no Apple keyed-archiver payload: fail-closed
/// decoding tests only need an instance to pass in.
final class Wave9StubCoder: NSCoder, @unchecked Sendable {}

func testWave9CaptionInitWithCoderFailsClosed() {
    precondition(AVCaption(coder: Wave9StubCoder()) == nil)
}

func testWave9CaptionRubyInitWithCoderFailsClosed() {
    precondition(AVCaption.Ruby(coder: Wave9StubCoder()) == nil)
}

func testWave9CaptionRegionInitWithCoderFailsClosed() {
    precondition(AVCaptionRegion(coder: Wave9StubCoder()) == nil)
}

func testWave9FormatDescriptionReplacementInitWithCoderFailsClosed() {
    precondition(AVCompositionTrackFormatDescriptionReplacement(coder: Wave9StubCoder()) == nil)
}

func testWave9MetricEventInitWithCoderFailsClosed() {
    precondition(AVMetricEvent(coder: Wave9StubCoder()) == nil)
}

func testWave9MetricMediaRenditionInitWithCoderFailsClosed() {
    precondition(AVMetricMediaRendition(coder: Wave9StubCoder()) == nil)
}

func testWave9LayerInstructionInitWithCoderFailsClosed() {
    precondition(AVVideoCompositionLayerInstruction(coder: Wave9StubCoder()) == nil)
}

func testWave9CoreAnimationToolSingleVideoLayerFactory() {
    let video = CALayer()
    let parent = CALayer()
    let tool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: video, in: parent)
    precondition(tool.portableVideoLayers.count == 1)
    precondition(tool.portableVideoLayers.first === video)
    precondition(tool.portableAnimationLayer === parent)
}

func testWave9CoreAnimationToolMultipleVideoLayersFactory() {
    let first = CALayer()
    let second = CALayer()
    let parent = CALayer()
    let tool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [first, second], in: parent)
    precondition(tool.portableVideoLayers.count == 2)
    precondition(tool.portableVideoLayers[0] === first)
    precondition(tool.portableVideoLayers[1] === second)
    precondition(tool.portableAnimationLayer === parent)
}
