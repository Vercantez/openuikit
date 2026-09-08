import Foundation
import AVFoundation

// Re-run focused behavioral probes as one depth-family audit. Each probe
// performs state transitions, parses local files, checks values, or verifies
// a Linux fail-closed result; this is not a declaration/identity-only check.
func testDepthPass9BehavioralFamilies() {
    testISOBMFFLocalAssetProbe()
    testISOBMFFAudioAndVideoTracks()
    testLocalAssetLoadAccessors()
    testAVMutableCompositionInsertsLocalTracks()
    testAVPlayerStatusAndTimeControl()
    testAVPlayerSeekCompletionAndTolerances()
    testAVPlayerItemStateMachine()
    testAVPlayerPeriodicAndBoundaryObservers()
    testAVAssetImageGeneratorGenerateTimesFailsClosedWithNoImageAtTime()
    testAVAssetWriterStoredConfigurationAndCancel()
    testAVAssetReaderOutputsStoredConfiguration()
    testAVContentKeySessionFailClosedWithoutFairPlay()
    testAVCaptureDeviceFailClosedDiscoveryModel()
    testAVCaptureSessionControlsAndConnectionsFailClosed()
    testAVCapturePhotoOutputFailClosedModel()
    testAVAudioMixAndVideoCompositionInstructionModels()
    testAVMetadataIdentifierRawValues()
    testAVMetadataKeyRawValues()
    testRawRepresentableEnumHashableSynthesis()
    testOptionSetAlgebraSynthesis()

    var dimension = AVCaptionDimension()
    dimension.value = 25
    dimension.units = .percent
    var point = AVCaptionPoint()
    point.x = dimension
    point.y = dimension
    var size = AVCaptionSize()
    size.width = dimension
    size.height = dimension
    precondition(point.x.value == 25 && size.height.units == .percent)

    var edges = AVEdgeWidths()
    edges.left = 1
    edges.top = 2
    edges.right = 3
    edges.bottom = 4
    precondition(edges.left + edges.top + edges.right + edges.bottom == 10)

    var aspect = AVPixelAspectRatio()
    aspect.horizontalSpacing = 4
    aspect.verticalSpacing = 3
    precondition(aspect.horizontalSpacing == 4 && aspect.verticalSpacing == 3)

    var timecode = AVCaptureTimecode()
    timecode.hours = 1
    timecode.minutes = 2
    timecode.seconds = 3
    timecode.frames = 4
    timecode.userBits = 5
    timecode.frameDuration = CMTime(value: 1, timescale: 30)
    timecode.sourceType = .frameCount
    precondition(timecode.hours == 1 && timecode.frames == 4)
}
