import Foundation

// Depth pass 15 (wave 6): Apple-mirrored Linux shims for leftover declared
// surface. Every addition is synchronous, in-process, and fail-closed: no
// camera, encoder, FairPlay daemon, or Apple service success is claimed.

// Apple's AVCaptureSynchronizedDataCollection adopts NSFastEnumeration
// (AVCaptureDataOutputSynchronizer.h), which Swift imports as Sequence.
// Mirroring that conformance taps the existing makeIterator/Element.
extension AVCaptureSynchronizedDataCollection: Sequence {}

extension AVCaptureReactionType {
  // Swift spelling of AVCaptureReactionSystemImageNameForType
  // (NS_SWIFT_NAME getter:AVCaptureReactionType.systemImageName).
  // Values pinned by an Xcode 26.1 `import AVFoundation` probe on this Mac:
  // thumbsUp=hand.thumbsup.fill, thumbsDown=hand.thumbsdown.fill,
  // balloons=balloon.2.fill, heart=heart.fill, fireworks=fireworks,
  // rain=cloud.rain.fill, confetti=party.popper.fill, lasers=laser.burst.
  // Unknown future types stay fail-closed as "".
  public var systemImageName: String {
    switch rawValue {
    case "thumbsUp": return "hand.thumbsup.fill"
    case "thumbsDown": return "hand.thumbsdown.fill"
    case "balloons": return "balloon.2.fill"
    case "heart": return "heart.fill"
    case "fireworks": return "fireworks"
    case "rain": return "cloud.rain.fill"
    case "confetti": return "party.popper.fill"
    case "lasers": return "laser.burst"
    default: return ""
    }
  }
}

extension AVCaptureDevice {
  // Synchronous completion-handler twins of the existing async setters.
  // Block shapes pinned from the iPhoneOS 26.1 headers: the focus, custom
  // exposure, bias, and white-balance handlers receive (CMTime); only
  // setDynamicAspectRatio also receives an optional error. Linux has no
  // device: handlers run synchronously on the caller with the same .zero
  // timestamp the async twins return, and nil error. No hardware state
  // changes.
  public func setFocusModeLocked(lensPosition: Float, completionHandler handler: ((CMTime) -> Void)?) {
    _ = lensPosition
    handler?(.zero)
  }
  public func setExposureModeCustom(duration: CMTime, iso ISO: Float, completionHandler handler: ((CMTime) -> Void)?) {
    _ = (duration, ISO)
    handler?(.zero)
  }
  public func setExposureTargetBias(_ bias: Float, completionHandler handler: ((CMTime) -> Void)?) {
    _ = bias
    handler?(.zero)
  }
  public func setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(_ whiteBalanceGains: AVCaptureDevice.WhiteBalanceGains, completionHandler handler: ((CMTime) -> Void)?) {
    _ = whiteBalanceGains
    handler?(.zero)
  }
  public func setWhiteBalanceModeLocked(whiteBalanceTemperatureAndTintValues: AVCaptureDevice.WhiteBalanceTemperatureAndTintValues, handler: ((CMTime) -> Void)?) {
    _ = whiteBalanceTemperatureAndTintValues
    handler?(.zero)
  }
  public func setDynamicAspectRatio(_ dynamicAspectRatio: AVCaptureDevice.AspectRatio, completionHandler handler: ((CMTime, (any Error)?) -> Void)?) {
    _ = dynamicAspectRatio
    handler?(.zero, nil)
  }
}

// Apple's ObjC spellings for these string/option-set families are top-level
// (NS_STRING_ENUM / NS_OPTIONS / NS_TYPED_ENUM); the Linux port nests some
// of them, so these aliases restore the exact graph spellings without
// changing behavior.
public typealias AVPlayerHDRMode = AVPlayer.HDRMode
public typealias AVPlayerRateDidChangeReason = AVPlayer.RateDidChangeReason
public typealias AVPlayerWaitingReason = AVPlayer.WaitingReason
public typealias AVCaptureSystemPressureLevel = AVCaptureDevice.SystemPressureState.Level
public typealias AVCaptureSystemPressureFactors = AVCaptureDevice.SystemPressureState.Factors
public typealias AVCapturePrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions = AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions

// Apple's AVPlayerItem adopts AVMetricEventStreamPublisher via the
// AVPlayerItem (AVMetricEventStreamPublisher) category. Linux has no metric
// service: both queries return empty in-process metrics.
extension AVPlayerItem: AVMetricEventStreamPublisher {
  public func metrics<MetricEvent>(forType metricType: MetricEvent.Type) -> AVMetrics<MetricEvent> where MetricEvent: AVMetricEvent {
    _ = metricType
    return AVMetrics()
  }
  public func allMetrics() -> AVMetrics<AVMetricEvent> {
    return AVMetrics()
  }
}
