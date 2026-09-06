import Foundation
import AVKit

func testRouteSelectionNotEqual() {
    precondition(AVAudioSession.RouteSelection.none != .local)
    precondition(AVAudioSession.RouteSelection.local != .external)
}

func testRouteSelectionHashValue() {
    precondition(AVAudioSession.RouteSelection.none.hashValue == AVAudioSession.RouteSelection.none.hashValue)
    precondition(AVAudioSession.RouteSelection.none.hashValue != AVAudioSession.RouteSelection.local.hashValue)
}

func testRouteSelectionHashInto() {
    var hasher = Hasher()
    AVAudioSession.RouteSelection.external.hash(into: &hasher)
    _ = hasher.finalize()
}

func testRouteSelectionInitRawValue() {
    precondition(AVAudioSession.RouteSelection(rawValue: 0) == AVAudioSession.RouteSelection.none)
    precondition(AVAudioSession.RouteSelection(rawValue: 1) == .local)
    precondition(AVAudioSession.RouteSelection(rawValue: 2) == .external)
    precondition(AVAudioSession.RouteSelection(rawValue: 99) == nil)
}

func testDisplayDynamicRangeNotEqual() {
    precondition(AVDisplayDynamicRange.automatic != .high)
    precondition(AVDisplayDynamicRange.standard != .constrainedHigh)
}

func testDisplayDynamicRangeHashValue() {
    precondition(AVDisplayDynamicRange.automatic.hashValue == AVDisplayDynamicRange.automatic.hashValue)
    precondition(AVDisplayDynamicRange.automatic.hashValue != AVDisplayDynamicRange.high.hashValue)
}

func testDisplayDynamicRangeHashInto() {
    var hasher = Hasher()
    AVDisplayDynamicRange.constrainedHigh.hash(into: &hasher)
    _ = hasher.finalize()
}

func testDisplayDynamicRangeInitRawValue() {
    precondition(AVDisplayDynamicRange(rawValue: 0) == .automatic)
    precondition(AVDisplayDynamicRange(rawValue: 1) == .standard)
    precondition(AVDisplayDynamicRange(rawValue: 2) == .constrainedHigh)
    precondition(AVDisplayDynamicRange(rawValue: 3) == .high)
    precondition(AVDisplayDynamicRange(rawValue: -1) == nil)
}

func testCaptureEventPhaseNotEqual() {
    precondition(AVCaptureEventPhase.began != .ended)
    precondition(AVCaptureEventPhase.ended != .cancelled)
}

func testCaptureEventPhaseHashValue() {
    precondition(AVCaptureEventPhase.began.hashValue != AVCaptureEventPhase.ended.hashValue)
}

func testCaptureEventPhaseHashInto() {
    var hasher = Hasher()
    AVCaptureEventPhase.cancelled.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCaptureEventPhaseInitRawValue() {
    precondition(AVCaptureEventPhase(rawValue: 0) == .began)
    precondition(AVCaptureEventPhase(rawValue: 1) == .ended)
    precondition(AVCaptureEventPhase(rawValue: 2) == .cancelled)
    precondition(AVCaptureEventPhase(rawValue: 9) == nil)
}

func testAVKitErrorCodeInitRawValue() {
    precondition(AVKitError.Code(rawValue: -1000) == .unknown)
    precondition(AVKitError.Code(rawValue: -1001) == .pictureInPictureStartFailed)
    precondition(AVKitError.Code(rawValue: 0) == nil)
}
