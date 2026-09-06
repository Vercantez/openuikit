import Dispatch
import Foundation

open class AVCoordinatedPlaybackParticipant: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var suspensionReasons: [AVCoordinatedPlaybackSuspension.Reason] { [] }
  public var isReadyToPlay: Bool { false }
  public var identifier: UUID { UUID() }
}

open class AVCoordinatedPlaybackSuspension: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct Reason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let audioSessionInterrupted = Reason(rawValue: "audioSessionInterrupted")
    public static let stallRecovery = Reason(rawValue: "stallRecovery")
    public static let playingInterstitial = Reason(rawValue: "playingInterstitial")
    public static let coordinatedPlaybackNotPossible = Reason(rawValue: "coordinatedPlaybackNotPossible")
    public static let userActionRequired = Reason(rawValue: "userActionRequired")
    public static let userIsChangingCurrentTime = Reason(rawValue: "userIsChangingCurrentTime")
  }
  public var reason: AVCoordinatedPlaybackSuspension.Reason { AVCoordinatedPlaybackSuspension.Reason(rawValue: "") }
  public var beginDate: Date { Date.distantPast }
  public func end() {}
  public func end(proposingNewTime time: CMTime) {}
}

open class AVDelegatingPlaybackCoordinator: AVPlaybackCoordinator, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(playbackControlDelegate: any AVPlaybackCoordinatorPlaybackControlDelegate) { self.init() }
  public var playbackControlDelegate: (any AVPlaybackCoordinatorPlaybackControlDelegate)? { nil }
  public func coordinateRateChange(to rate: Float, options: AVDelegatingPlaybackCoordinatorRateChangeOptions = []) {}
  public func coordinateSeek(to time: CMTime, options: AVDelegatingPlaybackCoordinatorSeekOptions = []) {}
  public func transitionToItem(withIdentifier itemIdentifier: String?, proposingInitialTimingBasedOn snapshotTimebase: CMTimebase?) {}
  public var currentItemIdentifier: String? { nil }
  public func reapplyCurrentItemStateToPlaybackControlDelegate() {}
}

open class AVDelegatingPlaybackCoordinatorBufferingCommand: AVDelegatingPlaybackCoordinatorPlaybackControlCommand, @unchecked Sendable {
  public override init() { super.init() }
  public var anticipatedPlaybackRate: Float { 0 }
  public var completionDueDate: Date? { nil }
}

open class AVDelegatingPlaybackCoordinatorPauseCommand: AVDelegatingPlaybackCoordinatorPlaybackControlCommand, @unchecked Sendable {
  public override init() { super.init() }
  public var shouldBufferInAnticipationOfPlayback: Bool { false }
  public var anticipatedPlaybackRate: Float { 0 }
}

open class AVDelegatingPlaybackCoordinatorPlayCommand: AVDelegatingPlaybackCoordinatorPlaybackControlCommand, @unchecked Sendable {
  public override init() { super.init() }
  public var rate: Float { 0 }
  public var itemTime: CMTime { .zero }
  public var hostClockTime: CMTime { .zero }
}

open class AVDelegatingPlaybackCoordinatorPlaybackControlCommand: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var originator: AVCoordinatedPlaybackParticipant? { nil }
  public var expectedCurrentItemIdentifier: String { "" }
}

public struct AVDelegatingPlaybackCoordinatorRateChangeOptions: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let playImmediately = AVDelegatingPlaybackCoordinatorRateChangeOptions(rawValue: 1 << 0)
}

open class AVDelegatingPlaybackCoordinatorSeekCommand: AVDelegatingPlaybackCoordinatorPlaybackControlCommand, @unchecked Sendable {
  public override init() { super.init() }
  public var itemTime: CMTime { .zero }
  public var shouldBufferInAnticipationOfPlayback: Bool { false }
  public var anticipatedPlaybackRate: Float { 0 }
  public var completionDueDate: Date? { nil }
}

public struct AVDelegatingPlaybackCoordinatorSeekOptions: OptionSet, Hashable, Sendable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let resumeImmediately = AVDelegatingPlaybackCoordinatorSeekOptions(rawValue: 1 << 0)
}

public enum AVExternalContentProtectionStatus: Int, Hashable, Sendable {
  case pending = 0
  case sufficient = 1
  case insufficient = 2
}

open class AVExternalStorageDevice: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var displayName: String? { nil }
  public var freeSize: Int { 0 }
  public var totalSize: Int { 0 }
  public var isConnected: Bool { false }
  public var uuid: UUID? { nil }
  public var isNotRecommendedForCaptureUse: Bool { false }
  public func nextAvailableURLs(withPathExtensions extensionArray: [String]) throws -> [URL] { return [] }
  public class var authorizationStatus: AVAuthorizationStatus { AVAuthorizationStatus(rawValue: 0)! }
  public class func requestAccess() async -> Bool { false }
}

open class AVExternalStorageDeviceDiscoverySession: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public class var shared: AVExternalStorageDeviceDiscoverySession? { nil }
  public var externalStorageDevices: [AVExternalStorageDevice] { [] }
  public class var isSupported: Bool { false }
}

open class AVExternalSyncDevice: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class DiscoverySession: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public class var shared: AVExternalSyncDevice.DiscoverySession? { nil }
    public class var isSupported: Bool { false }
    public var devices: [AVExternalSyncDevice] { [] }
  }
  public var status: AVExternalSyncDeviceStatus { AVExternalSyncDeviceStatus(rawValue: 0)! }
  public var clock: CMClock? { nil }
  public var signalCompensationDelay: CMTime {
      get { .zero }
      set { _ = newValue }
    }
  public var uuid: UUID { UUID() }
  public var vendorID: UInt32 { 0 }
  public var productID: UInt32 { 0 }
}

public protocol AVExternalSyncDeviceDelegate : AnyObject {
  func externalSyncDeviceStatusDidChange(_ device: AVExternalSyncDevice)
  func externalSyncDevice(_ device: AVExternalSyncDevice, failedWithError error: (any Error)?)
}

public enum AVExternalSyncDeviceStatus: Int, Hashable, Sendable {
  case unavailable = 0
  case ready = 1
  case calibrating = 2
  case activeSync = 3
  case freeRunSync = 4
}

open class AVPlaybackCoordinationMedium: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var connectedPlaybackCoordinators: [AVPlayerPlaybackCoordinator] { [] }
}

open class AVPlaybackCoordinator: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var otherParticipants: [AVCoordinatedPlaybackParticipant] { [] }
  public var suspensionReasons: [AVCoordinatedPlaybackSuspension.Reason] { [] }
  public func beginSuspension(for suspensionReason: AVCoordinatedPlaybackSuspension.Reason) -> AVCoordinatedPlaybackSuspension { AVCoordinatedPlaybackSuspension() }
  public func expectedItemTime(atHostTime hostClockTime: CMTime) -> CMTime { .zero }
  public func setParticipantLimit(_ participantLimit: Int, forWaitingOutSuspensionsWithReason reason: AVCoordinatedPlaybackSuspension.Reason) {}
  public func participantLimitForWaitingOutSuspensions(withReason reason: AVCoordinatedPlaybackSuspension.Reason) -> Int { 0 }
  public var suspensionReasonsThatTriggerWaiting: [AVCoordinatedPlaybackSuspension.Reason] {
      get { [] }
      set { _ = newValue }
    }
  public var pauseSnapsToMediaTimeOfOriginator: Bool {
      get { false }
      set { _ = newValue }
    }
  public static let otherParticipantsDidChangeNotification: Notification.Name = Notification.Name("otherParticipantsDidChangeNotification")
  public static let suspensionReasonsDidChangeNotification: Notification.Name = Notification.Name("suspensionReasonsDidChangeNotification")
}

public protocol AVPlaybackCoordinatorPlaybackControlDelegate : AnyObject, Sendable {
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue playCommand: AVDelegatingPlaybackCoordinatorPlayCommand, completionHandler: @escaping () -> Void)
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue playCommand: AVDelegatingPlaybackCoordinatorPlayCommand) async
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue pauseCommand: AVDelegatingPlaybackCoordinatorPauseCommand, completionHandler: @escaping () -> Void)
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue pauseCommand: AVDelegatingPlaybackCoordinatorPauseCommand) async
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue seekCommand: AVDelegatingPlaybackCoordinatorSeekCommand, completionHandler: @escaping () -> Void)
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue seekCommand: AVDelegatingPlaybackCoordinatorSeekCommand) async
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue bufferingCommand: AVDelegatingPlaybackCoordinatorBufferingCommand, completionHandler: @escaping () -> Void)
  func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue bufferingCommand: AVDelegatingPlaybackCoordinatorBufferingCommand) async
}

extension AVPlayer {
  public enum ActionAtItemEnd: Int, Hashable, Sendable {
    case advance = 0
    case pause = 1
    case none = 2
  }
  public struct HDRMode: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let hlg = HDRMode(rawValue: 1 << 0)
    public static let hdr10 = HDRMode(rawValue: 1 << 1)
    public static let dolbyVision = HDRMode(rawValue: 1 << 2)
  }
  public enum NetworkResourcePriority: Int, Hashable, Sendable {
    case `default` = 0
    case low = 1
    case high = 2
  }
  public struct RateDidChangeReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let setRateCalled = RateDidChangeReason(rawValue: "setRateCalled")
    public static let setRateFailed = RateDidChangeReason(rawValue: "setRateFailed")
    public static let audioSessionInterrupted = RateDidChangeReason(rawValue: "audioSessionInterrupted")
    public static let appBackgrounded = RateDidChangeReason(rawValue: "appBackgrounded")
  }
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case readyToPlay = 1
    case failed = 2
  }
  public enum TimeControlStatus: Int, Hashable, Sendable {
    case paused = 0
    case waitingToPlayAtSpecifiedRate = 1
    case playing = 2
  }
  public struct WaitingReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let interstitialEvent = WaitingReason(rawValue: "interstitialEvent")
    public static let toMinimizeStalls = WaitingReason(rawValue: "toMinimizeStalls")
    public static let evaluatingBufferingRate = WaitingReason(rawValue: "evaluatingBufferingRate")
    public static let noItemToPlay = WaitingReason(rawValue: "noItemToPlay")
    public static let waitingForCoordinatedPlayback = WaitingReason(rawValue: "waitingForCoordinatedPlayback")
  }

  public var status: AVPlayer.Status {
    playbackEngine.lock.withLock { playbackEngine.status() }
  }

  public var error: (any Error)? { nil }

  public var timeControlStatus: AVPlayer.TimeControlStatus {
    playbackEngine.lock.withLock { playbackEngine.timeControlStatus() }
  }

  public var reasonForWaitingToPlay: AVPlayer.WaitingReason? { nil }

  public func playImmediately(atRate rate: Float) {
    playbackEngine.lock.withLock { playbackEngine.setRate(rate) }
    AVFoundationPortable.emit(
      .play(player: ObjectIdentifier(self), url: currentItem?.url)
    )
  }

  public var actionAtItemEnd: AVPlayer.ActionAtItemEnd {
    get { playbackEngine.lock.withLock { playbackEngine.actionAtItemEnd } }
    set { playbackEngine.lock.withLock { playbackEngine.actionAtItemEnd = newValue } }
  }

  public var automaticallyWaitsToMinimizeStalling: Bool {
    get { playbackEngine.lock.withLock { playbackEngine.automaticallyWaitsToMinimizeStalling } }
    set { playbackEngine.lock.withLock { playbackEngine.automaticallyWaitsToMinimizeStalling = newValue } }
  }

  public func setRate(_ rate: Float, time itemTime: CMTime, atHostTime hostClockTime: CMTime) {
    _ = hostClockTime
    playbackEngine.lock.lock()
    _ = playbackEngine.seek(to: itemTime)
    playbackEngine.setRate(rate)
    playbackEngine.lock.unlock()
  }

  public func preroll(atRate rate: Float) async -> Bool {
    _ = rate
    return false
  }

  public func preroll(atRate rate: Float, completionHandler: @escaping (Bool) -> Void) {
    _ = rate
    completionHandler(false)
  }

  public func cancelPendingPrerolls() {}

  public var sourceClock: CMClock? {
    get { playbackEngine.lock.withLock { playbackEngine.sourceClock } }
    set { playbackEngine.lock.withLock { playbackEngine.sourceClock = newValue } }
  }

  public func addPeriodicTimeObserver(
    forInterval interval: CMTime,
    queue: DispatchQueue?,
    using block: @escaping (CMTime) -> Void
  ) -> Any {
    let token = AVPlayerTimeObserverToken(
      kind: .periodic(interval: interval, block: block),
      queue: queue ?? playbackEngine.pulseQueue
    )
    playbackEngine.lock.lock()
    token.lastPeriodicFire = playbackEngine.currentSeconds()
    playbackEngine.observers[ObjectIdentifier(token)] = token
    playbackEngine.ensurePulse()
    playbackEngine.lock.unlock()
    return token
  }

  public func addBoundaryTimeObserver(
    forTimes times: [NSValue],
    queue: DispatchQueue?,
    using block: @escaping () -> Void
  ) -> Any {
    let boundaries = times.map(avTime(from:))
    let token = AVPlayerTimeObserverToken(
      kind: .boundary(times: boundaries, block: block),
      queue: queue ?? playbackEngine.pulseQueue
    )
    playbackEngine.lock.lock()
    playbackEngine.observers[ObjectIdentifier(token)] = token
    playbackEngine.ensurePulse()
    playbackEngine.lock.unlock()
    return token
  }

  public func removeTimeObserver(_ observer: Any) {
    guard let token = observer as? AVPlayerTimeObserverToken else { return }
    playbackEngine.lock.withLock {
      _ = playbackEngine.observers.removeValue(forKey: ObjectIdentifier(token))
    }
  }

  public var appliesMediaSelectionCriteriaAutomatically: Bool {
    get { playbackEngine.lock.withLock { playbackEngine.appliesMediaSelectionCriteriaAutomatically } }
    set { playbackEngine.lock.withLock { playbackEngine.appliesMediaSelectionCriteriaAutomatically = newValue } }
  }

  public func setMediaSelectionCriteria(
    _ criteria: AVPlayerMediaSelectionCriteria?,
    forMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic
  ) {
    playbackEngine.lock.withLock {
      if let criteria {
        playbackEngine.mediaSelection[mediaCharacteristic.rawValue] = criteria
      } else {
        playbackEngine.mediaSelection.removeValue(forKey: mediaCharacteristic.rawValue)
      }
    }
  }

  public func mediaSelectionCriteria(
    forMediaCharacteristic mediaCharacteristic: AVMediaCharacteristic
  ) -> AVPlayerMediaSelectionCriteria? {
    playbackEngine.lock.withLock {
      playbackEngine.mediaSelection[mediaCharacteristic.rawValue]
    }
  }

  public var allowsExternalPlayback: Bool {
    get { playbackEngine.lock.withLock { playbackEngine.allowsExternalPlayback } }
    set { playbackEngine.lock.withLock { playbackEngine.allowsExternalPlayback = newValue } }
  }

  public var isExternalPlaybackActive: Bool { false }

  public var usesExternalPlaybackWhileExternalScreenIsActive: Bool {
    get { playbackEngine.lock.withLock { playbackEngine.usesExternalPlaybackWhileExternalScreenIsActive } }
    set { playbackEngine.lock.withLock { playbackEngine.usesExternalPlaybackWhileExternalScreenIsActive = newValue } }
  }

  public var externalPlaybackVideoGravity: AVLayerVideoGravity {
    get { playbackEngine.lock.withLock { playbackEngine.externalPlaybackVideoGravity } }
    set { playbackEngine.lock.withLock { playbackEngine.externalPlaybackVideoGravity = newValue } }
  }

  public var isOutputObscuredDueToInsufficientExternalProtection: Bool { false }
  public class var availableHDRModes: AVPlayer.HDRMode { [] }
  public class var eligibleForHDRPlayback: Bool { false }
  public var playbackCoordinator: AVPlayerPlaybackCoordinator { AVPlayerPlaybackCoordinator() }

  public var videoOutput: AVPlayerVideoOutput? {
    get { playbackEngine.lock.withLock { playbackEngine.videoOutput } }
    set { playbackEngine.lock.withLock { playbackEngine.videoOutput = newValue } }
  }

  public var networkResourcePriority: AVPlayer.NetworkResourcePriority {
    get { playbackEngine.lock.withLock { playbackEngine.networkResourcePriority } }
    set { playbackEngine.lock.withLock { playbackEngine.networkResourcePriority = newValue } }
  }

  public var audioOutputSuppressedDueToNonMixableAudioRoute: Bool { false }

  public class var isObservationEnabled: Bool {
    get { false }
    set { _ = newValue }
  }

  public var isClosedCaptionDisplayEnabled: Bool {
    get { playbackEngine.lock.withLock { playbackEngine.closedCaptionDisplayEnabled } }
    set { playbackEngine.lock.withLock { playbackEngine.closedCaptionDisplayEnabled = newValue } }
  }

  public var masterClock: CMClock? {
    get { playbackEngine.lock.withLock { playbackEngine.masterClock } }
    set { playbackEngine.lock.withLock { playbackEngine.masterClock = newValue } }
  }

  public func seek(to time: CMTime) async -> Bool {
    let finished = playbackEngine.lock.withLock { playbackEngine.seek(to: time) }
    if finished {
      AVFoundationPortable.emit(.seek(player: ObjectIdentifier(self), time: time))
    }
    return finished
  }

  public func seek(to time: CMTime, completionHandler: @escaping (Bool) -> Void) {
    let finished = playbackEngine.lock.withLock { playbackEngine.seek(to: time) }
    if finished {
      AVFoundationPortable.emit(.seek(player: ObjectIdentifier(self), time: time))
    }
    completionHandler(finished)
  }

  public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
    _ = (toleranceBefore, toleranceAfter)
    seek(to: time)
  }

  public func seek(
    to time: CMTime,
    toleranceBefore: CMTime,
    toleranceAfter: CMTime
  ) async -> Bool {
    _ = (toleranceBefore, toleranceAfter)
    return await seek(to: time)
  }

  public func seek(to date: Date) {
    _ = date
  }

  public func seek(to date: Date) async -> Bool {
    _ = date
    return false
  }

  public static let rateDidChangeNotification: Notification.Name = Notification.Name("AVPlayerRateDidChangeNotification")
  public static let rateDidChangeReasonKey: String = "AVPlayerRateDidChangeReasonKey"
  public static let rateDidChangeOriginatingParticipantKey: String = "AVPlayerRateDidChangeOriginatingParticipantKey"
  public static let eligibleForHDRPlaybackDidChangeNotification: Notification.Name = Notification.Name("AVPlayerEligibleForHDRPlaybackDidChangeNotification")
}

public struct AVPlayerIntegratedTimelineSnapshotsOutOfSyncReason: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
  public let rawValue: String
  public init(rawValue: String) { self.rawValue = rawValue }
  public init(stringLiteral value: String) { self.init(rawValue: value) }
  public static let segmentsChanged = AVPlayerIntegratedTimelineSnapshotsOutOfSyncReason(rawValue: "segmentsChanged")
  public static let currentSegmentChanged = AVPlayerIntegratedTimelineSnapshotsOutOfSyncReason(rawValue: "currentSegmentChanged")
  public static let loadedTimeRangesChanged = AVPlayerIntegratedTimelineSnapshotsOutOfSyncReason(rawValue: "loadedTimeRangesChanged")
}

open class AVPlayerInterstitialEvent: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct Cue: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let noCue = Cue(rawValue: "noCue")
    public static let joinCue = Cue(rawValue: "joinCue")
    public static let leaveCue = Cue(rawValue: "leaveCue")
  }
  public struct Restrictions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let constrainsSeekingForwardInPrimaryContent = Restrictions(rawValue: 1 << 0)
    public static let requiresPlaybackAtPreferredRateForAdvancement = Restrictions(rawValue: 1 << 1)
  }
  public enum SkippableEventState: Int, Hashable, Sendable {
    case notSkippable = 0
    case notYetEligible = 1
    case eligible = 2
    case noLongerEligible = 3
  }
  public enum TimelineOccupancy: Int, Hashable, Sendable {
    case singlePoint = 0
    case fill = 1
  }
  weak var storedPrimaryItem: AVPlayerItem?
  var storedIdentifier = ""
  var storedTime = CMTime.zero
  var storedDate: Date?
  var storedTemplateItems: [AVPlayerItem] = []
  var storedRestrictions = Restrictions()
  var storedResumptionOffset = CMTime.indefinite
  var storedPlayoutLimit = CMTime.invalid
  var storedUserDefinedAttributes: [AnyHashable : any Sendable] = [:]
  var storedAlignsStart = false
  var storedAlignsResumption = false
  var storedCue = Cue.noCue
  var storedWillPlayOnce = false
  var storedTimelineOccupancy = TimelineOccupancy.singlePoint
  var storedSupplementsPrimaryContent = false
  var storedContentMayVary = true
  var storedSkipControlTimeRange = CMTimeRange.zero
  var storedSkipControlLocalizedLabelBundleKey: String?
  var storedPlannedDuration = CMTime.invalid

  public convenience init(primaryItem: AVPlayerItem, identifier: String?, time: CMTime, templateItems: [AVPlayerItem], restrictions: AVPlayerInterstitialEvent.Restrictions = [], resumptionOffset: CMTime = .indefinite, playoutLimit: CMTime = .invalid, userDefinedAttributes: [String : Any] = [:]) {
    self.init()
    storedPrimaryItem = primaryItem
    storedIdentifier = identifier ?? UUID().uuidString
    storedTime = time
    storedTemplateItems = templateItems
    storedRestrictions = restrictions
    storedResumptionOffset = resumptionOffset
    storedPlayoutLimit = playoutLimit
    storedUserDefinedAttributes = Dictionary(uniqueKeysWithValues: userDefinedAttributes.map { ($0.key as AnyHashable, $0.value as any Sendable) })
  }
  public convenience init(primaryItem: AVPlayerItem, identifier: String?, date: Date, templateItems: [AVPlayerItem], restrictions: AVPlayerInterstitialEvent.Restrictions = [], resumptionOffset: CMTime = .indefinite, playoutLimit: CMTime = .invalid, userDefinedAttributes: [String : Any] = [:]) {
    self.init()
    storedPrimaryItem = primaryItem
    storedIdentifier = identifier ?? UUID().uuidString
    storedDate = date
    storedTemplateItems = templateItems
    storedRestrictions = restrictions
    storedResumptionOffset = resumptionOffset
    storedPlayoutLimit = playoutLimit
    storedUserDefinedAttributes = Dictionary(uniqueKeysWithValues: userDefinedAttributes.map { ($0.key as AnyHashable, $0.value as any Sendable) })
  }
  public convenience init(primaryItem: AVPlayerItem, time: CMTime) {
    self.init(primaryItem: primaryItem, identifier: nil, time: time, templateItems: [])
  }
  public convenience init(primaryItem: AVPlayerItem, date: Date) {
    self.init(primaryItem: primaryItem, identifier: nil, date: date, templateItems: [])
  }
  public var primaryItem: AVPlayerItem? { storedPrimaryItem }
  public var identifier: String {
      get { storedIdentifier }
      set { storedIdentifier = newValue }
    }
  public var time: CMTime {
      get { storedTime }
      set { storedTime = newValue }
    }
  public var date: Date? {
      get { storedDate }
      set { storedDate = newValue }
    }
  public var templateItems: [AVPlayerItem] {
      get { storedTemplateItems }
      set { storedTemplateItems = newValue }
    }
  public var restrictions: AVPlayerInterstitialEvent.Restrictions {
      get { storedRestrictions }
      set { storedRestrictions = newValue }
    }
  public var resumptionOffset: CMTime {
      get { storedResumptionOffset }
      set { storedResumptionOffset = newValue }
    }
  public var playoutLimit: CMTime {
      get { storedPlayoutLimit }
      set { storedPlayoutLimit = newValue }
    }
  public var alignsStartWithPrimarySegmentBoundary: Bool {
      get { storedAlignsStart }
      set { storedAlignsStart = newValue }
    }
  public var alignsResumptionWithPrimarySegmentBoundary: Bool {
      get { storedAlignsResumption }
      set { storedAlignsResumption = newValue }
    }
  public var cue: AVPlayerInterstitialEvent.Cue {
      get { storedCue }
      set { storedCue = newValue }
    }
  public var willPlayOnce: Bool {
      get { storedWillPlayOnce }
      set { storedWillPlayOnce = newValue }
    }
  public var userDefinedAttributes: [AnyHashable : any Sendable] {
      get { storedUserDefinedAttributes }
      set { storedUserDefinedAttributes = newValue }
    }
  public var assetListResponse: [AnyHashable : any Sendable]? { nil }
  public var timelineOccupancy: AVPlayerInterstitialEvent.TimelineOccupancy {
      get { storedTimelineOccupancy }
      set { storedTimelineOccupancy = newValue }
    }
  public var supplementsPrimaryContent: Bool {
      get { storedSupplementsPrimaryContent }
      set { storedSupplementsPrimaryContent = newValue }
    }
  public var contentMayVary: Bool {
      get { storedContentMayVary }
      set { storedContentMayVary = newValue }
    }
  public var skipControlTimeRange: CMTimeRange {
      get { storedSkipControlTimeRange }
      set { storedSkipControlTimeRange = newValue }
    }
  public var skipControlLocalizedLabelBundleKey: String? {
      get { storedSkipControlLocalizedLabelBundleKey }
      set { storedSkipControlLocalizedLabelBundleKey = newValue }
    }
  public var plannedDuration: CMTime {
      get { storedPlannedDuration }
      set { storedPlannedDuration = newValue }
    }
}

public enum AVPlayerInterstitialEventAssetListResponseStatus: Int, Hashable, Sendable {
  case available = 0
  case cleared = 1
  case unavailable = 2
}

open class AVPlayerInterstitialEventController: AVPlayerInterstitialEventMonitor, @unchecked Sendable {
  public override init() { super.init() }
  public override var events: [AVPlayerInterstitialEvent] {
    get { storedEvents }
    set { storedEvents = newValue }
  }
  public func cancelCurrentEvent(withResumptionOffset resumptionOffset: CMTime) {
    _ = resumptionOffset
    storedEvents.removeAll()
  }
  public func skipCurrentEvent() {}
  public var localizedStringsBundle: Bundle? {
      get { nil }
      set { _ = newValue }
    }
  public var localizedStringsTableName: String? {
      get { nil }
      set { _ = newValue }
    }
}

open class AVPlayerInterstitialEventMonitor: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  weak var storedPrimaryPlayer: AVPlayer?
  var storedEvents: [AVPlayerInterstitialEvent] = []
  public convenience init(primaryPlayer: AVPlayer) {
    self.init()
    storedPrimaryPlayer = primaryPlayer
  }
  public var primaryPlayer: AVPlayer? { storedPrimaryPlayer }
  public var interstitialPlayer: AVQueuePlayer { AVQueuePlayer() }
  public var events: [AVPlayerInterstitialEvent] { storedEvents }
  public var currentEvent: AVPlayerInterstitialEvent? { nil }
  public var currentEventSkippableState: AVPlayerInterstitialEvent.SkippableEventState { .notSkippable }
  public var currentEventSkipControlLabel: String? { nil }
  public static let eventsDidChangeNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorEventsDidChangeNotification")
  public static let currentEventDidChangeNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorCurrentEventDidChangeNotification")
  public static let assetListResponseStatusDidChangeNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeNotification")
  public static let assetListResponseStatusDidChangeEventKey: String = "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeEventKey"
  public static let assetListResponseStatusDidChangeStatusKey: String = "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeStatusKey"
  public static let assetListResponseStatusDidChangeErrorKey: String = "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeErrorKey"
  public static let currentEventSkippableStateDidChangeNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeNotification")
  public static let currentEventSkippableStateDidChangeEventKey: String = "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeEventKey"
  public static let currentEventSkippableStateDidChangeStateKey: String = "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeStateKey"
  public static let currentEventSkippableStateDidChangeSkipControlLabelKey: String = "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeSkipControlLabelKey"
  public static let currentEventSkippedNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorCurrentEventSkippedNotification")
  public static let currentEventSkippedEventKey: String = "AVPlayerInterstitialEventMonitorCurrentEventSkippedEventKey"
  public static let interstitialEventWasUnscheduledNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorInterstitialEventWasUnscheduledNotification")
  public static let interstitialEventWasUnscheduledEventKey: String = "AVPlayerInterstitialEventMonitorInterstitialEventWasUnscheduledEventKey"
  public static let interstitialEventWasUnscheduledErrorKey: String = "AVPlayerInterstitialEventMonitorInterstitialEventWasUnscheduledErrorKey"
  public static let interstitialEventDidFinishNotification: Notification.Name = Notification.Name("AVPlayerInterstitialEventMonitorInterstitialEventDidFinishNotification")
  public static let interstitialEventDidFinishEventKey: String = "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishEventKey"
  public static let interstitialEventDidFinishPlayoutTimeKey: String = "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishPlayoutTimeKey"
  public static let interstitialEventDidFinishDidPlayEntireEventKey: String = "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishDidPlayEntireEventKey"
}

extension AVPlayerItem {
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case readyToPlay = 1
    case failed = 2
  }
  public convenience init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
    self.init(asset: asset)
    portableAutomaticallyLoadedAssetKeys = automaticallyLoadedAssetKeys ?? []
  }
  public func copy(with zone: NSZone? = nil) -> Any { self }
  public var status: AVPlayerItem.Status { .readyToPlay }
  public var error: (any Error)? { nil }
  public var tracks: [AVPlayerItemTrack] {
    asset.tracks.map { assetTrack in
      let itemTrack = AVPlayerItemTrack()
      itemTrack.portableAssetTrack = assetTrack
      return itemTrack
    }
  }
  public var duration: CMTime { asset.duration }
  public var presentationSize: CGSize {
    asset.tracks.first(where: { $0.mediaType == .video })?.naturalSize ?? .zero
  }
  public var timedMetadata: [AVMetadataItem]? { nil }
  public var automaticallyLoadedAssetKeys: [String] { portableAutomaticallyLoadedAssetKeys }
  public var canPlayFastForward: Bool { false }
  public var canPlaySlowForward: Bool { false }
  public var canPlayReverse: Bool { false }
  public var canPlaySlowReverse: Bool { false }
  public var canPlayFastReverse: Bool { false }
  public var canStepForward: Bool { false }
  public var canStepBackward: Bool { false }
  public var configuredTimeOffsetFromLive: CMTime {
      get { portableConfiguredTimeOffsetFromLive }
      set { portableConfiguredTimeOffsetFromLive = newValue }
    }
  public var recommendedTimeOffsetFromLive: CMTime { .zero }
  public var automaticallyPreservesTimeOffsetFromLive: Bool {
      get { portableAutomaticallyPreservesTimeOffsetFromLive }
      set { portableAutomaticallyPreservesTimeOffsetFromLive = newValue }
    }
  public var forwardPlaybackEndTime: CMTime {
      get { portableForwardPlaybackEndTime }
      set { portableForwardPlaybackEndTime = newValue }
    }
  public var reversePlaybackEndTime: CMTime {
      get { portableReversePlaybackEndTime }
      set { portableReversePlaybackEndTime = newValue }
    }
  public var seekableTimeRanges: [NSValue] { loadedTimeRanges }
  public var audioMix: AVAudioMix? {
      get { portableAudioMix }
      set { portableAudioMix = newValue }
    }
  public var videoComposition: AVVideoComposition? {
      get { portableVideoComposition }
      set { portableVideoComposition = newValue }
    }
  public var seekingWaitsForVideoCompositionRendering: Bool {
      get { portableSeekingWaitsForVideoCompositionRendering }
      set { portableSeekingWaitsForVideoCompositionRendering = newValue }
    }
  public var videoApertureMode: AVVideoApertureMode {
      get { portableVideoApertureMode }
      set { portableVideoApertureMode = newValue }
    }
  public var audioTimePitchAlgorithm: AVAudioTimePitchAlgorithm {
      get { portableAudioTimePitchAlgorithm }
      set { portableAudioTimePitchAlgorithm = newValue }
    }
  public var preferredForwardBufferDuration: TimeInterval {
      get { portablePreferredForwardBufferDuration }
      set { portablePreferredForwardBufferDuration = newValue }
    }
  public var loadedTimeRanges: [NSValue] {
    let duration = self.duration
    guard duration.isValid, duration.seconds > 0 else { return [] }
    return [AVCMTimeRangeValue.nsValue(for: CMTimeRange(start: .zero, duration: duration))]
  }
  public var isPlaybackLikelyToKeepUp: Bool { duration.isValid && duration.seconds > 0 }
  public var isPlaybackBufferFull: Bool { false }
  public var isPlaybackBufferEmpty: Bool { loadedTimeRanges.isEmpty }
  public func seek(to time: CMTime) async -> Bool {
    _portableSetCurrentTime(time)
    return time.isValid
  }
  public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) async -> Bool {
    _ = (toleranceBefore, toleranceAfter)
    return await seek(to: time)
  }
  public func cancelPendingSeeks() {}
  public func currentDate() -> Date? { nil }
  public func seek(to date: Date, completionHandler: ((Bool) -> Void)? = nil) -> Bool {
    _ = date
    completionHandler?(false)
    return false
  }
  public func seek(to date: Date) async -> Bool {
    _ = date
    return false
  }
  public func step(byCount stepCount: Int) { _ = stepCount }
  public var timebase: CMTimebase? { nil }
  public var customVideoCompositor: (any AVVideoCompositing)? { nil }
  public var textStyleRules: [AVTextStyleRule]? {
      get { portableTextStyleRules }
      set { portableTextStyleRules = newValue }
    }
  public var appliesPerFrameHDRDisplayMetadata: Bool {
      get { false }
      set { _ = newValue }
    }
  public var isAudioSpatializationAllowed: Bool {
      get { false }
      set { _ = newValue }
    }
  public var allowedAudioSpatializationFormats: AVAudioSpatializationFormats {
      get { portableAllowedAudioSpatializationFormats }
      set { portableAllowedAudioSpatializationFormats = newValue }
    }
  public var canUseNetworkResourcesForLiveStreamingWhilePaused: Bool {
      get { false }
      set { _ = newValue }
    }
  public var preferredPeakBitRate: Double {
      get { portablePreferredPeakBitRate }
      set { portablePreferredPeakBitRate = newValue }
    }
  public var preferredPeakBitRateForExpensiveNetworks: Double {
      get { portablePreferredPeakBitRateForExpensiveNetworks }
      set { portablePreferredPeakBitRateForExpensiveNetworks = newValue }
    }
  public var preferredMaximumResolution: CGSize {
      get { portablePreferredMaximumResolution }
      set { portablePreferredMaximumResolution = newValue }
    }
  public var preferredMaximumResolutionForExpensiveNetworks: CGSize {
      get { portablePreferredMaximumResolutionForExpensiveNetworks }
      set { portablePreferredMaximumResolutionForExpensiveNetworks = newValue }
    }
  public var startsOnFirstEligibleVariant: Bool {
      get { portableStartsOnFirstEligibleVariant }
      set { portableStartsOnFirstEligibleVariant = newValue }
    }
  public var variantPreferences: AVVariantPreferences {
      get { portableVariantPreferences }
      set { portableVariantPreferences = newValue }
    }
  public func select(_ mediaSelectionOption: AVMediaSelectionOption?, in mediaSelectionGroup: AVMediaSelectionGroup) {}
  public func selectMediaOptionAutomatically(in mediaSelectionGroup: AVMediaSelectionGroup) {}
  public var currentMediaSelection: AVMediaSelection { AVMediaSelection() }
  public var preferredCustomMediaSelectionSchemes: [AVCustomMediaSelectionScheme] {
      get { portablePreferredCustomMediaSelectionSchemes }
      set { portablePreferredCustomMediaSelectionSchemes = newValue }
    }
  public func selectMediaPresentationLanguage(_ language: String, for mediaSelectionGroup: AVMediaSelectionGroup) {
    portablePresentationLanguages[ObjectIdentifier(mediaSelectionGroup)] = language
  }
  public func selectedMediaPresentationLanguage(for mediaSelectionGroup: AVMediaSelectionGroup) -> String? {
    portablePresentationLanguages[ObjectIdentifier(mediaSelectionGroup)]
  }
  public func select(_ mediaPresentationSetting: AVMediaPresentationSetting, for mediaSelectionGroup: AVMediaSelectionGroup) {
    _ = (mediaPresentationSetting, mediaSelectionGroup)
  }
  public func effectiveMediaPresentationSettings(for mediaSelectionGroup: AVMediaSelectionGroup) -> [AVMediaPresentationSelector : Any] {
    _ = mediaSelectionGroup
    return [:]
  }
  public func selectedMediaPresentationSettings(for mediaSelectionGroup: AVMediaSelectionGroup) -> [AVMediaPresentationSelector : Any] {
    _ = mediaSelectionGroup
    return [:]
  }
  public func accessLog() -> AVPlayerItemAccessLog? { portableAccessLog }
  public func errorLog() -> AVPlayerItemErrorLog? { portableErrorLog }
  public func add(_ output: AVPlayerItemOutput) {
    portableOutputs.append(output)
  }
  public func remove(_ output: AVPlayerItemOutput) {
    portableOutputs.removeAll { $0 === output }
  }
  public var outputs: [AVPlayerItemOutput] { portableOutputs }
  public func add(_ collector: AVPlayerItemMediaDataCollector) {
    portableCollectors.append(collector)
  }
  public func remove(_ collector: AVPlayerItemMediaDataCollector) {
    portableCollectors.removeAll { $0 === collector }
  }
  public var mediaDataCollectors: [AVPlayerItemMediaDataCollector] { portableCollectors }
  public func seek(to time: CMTime) {
    _portableSetCurrentTime(time)
  }
  public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
    _ = (toleranceBefore, toleranceAfter)
    seek(to: time)
  }
  public func seek(
    to time: CMTime,
    toleranceBefore: CMTime,
    toleranceAfter: CMTime,
    completionHandler: @escaping (Bool) -> Void
  ) {
    seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter)
    completionHandler(time.isValid)
  }
  public func seek(to date: Date) -> Bool { false }
  public func selectedMediaOption(in mediaSelectionGroup: AVMediaSelectionGroup) -> AVMediaSelectionOption? { nil }
  public static let timeJumpedNotification: Notification.Name = Notification.Name("AVPlayerItemTimeJumpedNotification")
  public static let didPlayToEndTimeNotification: Notification.Name = Notification.Name("AVPlayerItemDidPlayToEndTimeNotification")
  public static let failedToPlayToEndTimeNotification: Notification.Name = Notification.Name("AVPlayerItemFailedToPlayToEndTimeNotification")
  public static let playbackStalledNotification: Notification.Name = Notification.Name("AVPlayerItemPlaybackStalledNotification")
  public static let newAccessLogEntryNotification: Notification.Name = Notification.Name("AVPlayerItemNewAccessLogEntryNotification")
  public static let newErrorLogEntryNotification: Notification.Name = Notification.Name("AVPlayerItemNewErrorLogEntryNotification")
  public static let recommendedTimeOffsetFromLiveDidChangeNotification: Notification.Name = Notification.Name("AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification")
  public static let mediaSelectionDidChangeNotification: Notification.Name = Notification.Name("AVPlayerItemMediaSelectionDidChangeNotification")
  public static let timeJumpedOriginatingParticipantKey: String = "AVPlayerItemTimeJumpedOriginatingParticipantKey"
  public var integratedTimeline: AVPlayerItemIntegratedTimeline { AVPlayerItemIntegratedTimeline() }
  public var automaticallyHandlesInterstitialEvents: Bool {
      get { portableAutomaticallyHandlesInterstitialEvents }
      set { portableAutomaticallyHandlesInterstitialEvents = newValue }
    }
  public var template: AVPlayerItem? { nil }
}

open class AVPlayerItemAccessLog: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func extendedLogData() -> Data? { nil }
  public var extendedLogDataStringEncoding: UInt { String.Encoding.utf8.rawValue }
  public var events: [AVPlayerItemAccessLogEvent] { [] }
}

open class AVPlayerItemAccessLogEvent: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var numberOfMediaRequests: Int { 0 }
  public var playbackStartDate: Date? { nil }
  public var uri: String? { nil }
  public var serverAddress: String? { nil }
  public var numberOfServerAddressChanges: Int { 0 }
  public var playbackSessionID: String? { nil }
  public var playbackStartOffset: TimeInterval { 0 }
  public var segmentsDownloadedDuration: TimeInterval { 0 }
  public var durationWatched: TimeInterval { 0 }
  public var numberOfStalls: Int { 0 }
  public var numberOfBytesTransferred: Int64 { 0 }
  public var transferDuration: TimeInterval { 0 }
  public var observedBitrate: Double { 0 }
  public var indicatedBitrate: Double { 0 }
  public var indicatedAverageBitrate: Double { 0 }
  public var averageVideoBitrate: Double { 0 }
  public var averageAudioBitrate: Double { 0 }
  public var numberOfDroppedVideoFrames: Int { 0 }
  public var startupTime: TimeInterval { 0 }
  public var downloadOverdue: Int { 0 }
  public var observedMaxBitrate: Double { 0 }
  public var observedMinBitrate: Double { 0 }
  public var observedBitrateStandardDeviation: Double { 0 }
  public var playbackType: String? { nil }
  public var mediaRequestsWWAN: Int { 0 }
  public var switchBitrate: Double { 0 }
}

open class AVPlayerItemErrorLog: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func extendedLogData() -> Data? { nil }
  public var extendedLogDataStringEncoding: UInt { String.Encoding.utf8.rawValue }
  public var events: [AVPlayerItemErrorLogEvent] { [] }
}

open class AVPlayerItemErrorLogEvent: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var date: Date? { nil }
  public var uri: String? { nil }
  public var serverAddress: String? { nil }
  public var playbackSessionID: String? { nil }
  public var errorStatusCode: Int { 0 }
  public var errorDomain: String { "" }
  public var errorComment: String? { nil }
  public var allHTTPResponseHeaderFields: [String : String]? { nil }
}

open class AVPlayerItemIntegratedTimeline: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public struct BoundaryTimes: Sendable {
    public init() {}
    public typealias Element = CMTime
    public func makeAsyncIterator() -> AVPlayerItemIntegratedTimeline.BoundaryTimes.Iterator { AVPlayerItemIntegratedTimeline.BoundaryTimes.Iterator() }
    public typealias AsyncIterator = AVPlayerItemIntegratedTimeline.BoundaryTimes.Iterator
    public struct Iterator: Sendable {
      public init() {}
      public mutating func next() async -> AVPlayerItemIntegratedTimeline.BoundaryTimes.Element? { nil }
      public typealias Element = AVPlayerItemIntegratedTimeline.BoundaryTimes.Element
    }
  }
  public struct PeriodicTimes: Sendable {
    public init() {}
    public typealias Element = CMTime
    public func makeAsyncIterator() -> AVPlayerItemIntegratedTimeline.PeriodicTimes.Iterator { AVPlayerItemIntegratedTimeline.PeriodicTimes.Iterator() }
    public typealias AsyncIterator = AVPlayerItemIntegratedTimeline.PeriodicTimes.Iterator
    public struct Iterator: Sendable {
      public init() {}
      public mutating func next() async -> AVPlayerItemIntegratedTimeline.PeriodicTimes.Element? { nil }
      public typealias Element = AVPlayerItemIntegratedTimeline.PeriodicTimes.Element
    }
  }
  public func periodicTimes(forInterval: CMTime) -> AVPlayerItemIntegratedTimeline.PeriodicTimes { AVPlayerItemIntegratedTimeline.PeriodicTimes() }
  public func boundaryTimes(for segment: AVPlayerItemSegment, offsetsIntoSegment: [CMTime]) -> AVPlayerItemIntegratedTimeline.BoundaryTimes { AVPlayerItemIntegratedTimeline.BoundaryTimes() }
  public var currentSnapshot: AVPlayerItemIntegratedTimelineSnapshot { AVPlayerItemIntegratedTimelineSnapshot() }
  public var currentTime: CMTime { .zero }
  public var currentDate: Date? { nil }
  public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) async -> Bool { false }
  public func seek(to date: Date) async -> Bool { false }
  public static let snapshotsOutOfSyncNotification: Notification.Name = Notification.Name("snapshotsOutOfSyncNotification")
  public static let snapshotsOutOfSyncReasonKey: String = "snapshotsOutOfSyncReasonKey"
}

public protocol AVPlayerItemIntegratedTimelineObserver : AnyObject {
}

open class AVPlayerItemIntegratedTimelineSnapshot: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func segmentAndOffsetIntoSegment(forTimelineTime: CMTime) -> (AVPlayerItemSegment, CMTime) { (AVPlayerItemSegment(), .zero) }
  public var duration: CMTime { .zero }
  public var currentSegment: AVPlayerItemSegment? { nil }
  public var segments: [AVPlayerItemSegment] { [] }
  public var currentTime: CMTime { .zero }
  public var currentDate: Date? { nil }
}

open class AVPlayerItemLegibleOutput: AVPlayerItemOutput, @unchecked Sendable {
  public override init() { super.init() }
  public struct TextStylingResolution: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.init(rawValue: value) }
    public static let `default` = TextStylingResolution(rawValue: "default")
    public static let sourceAndRulesOnly = TextStylingResolution(rawValue: "sourceAndRulesOnly")
  }
  public func setDelegate(_ delegate: (any AVPlayerItemLegibleOutputPushDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public var delegate: (any AVPlayerItemLegibleOutputPushDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
  public var advanceIntervalForDelegateInvocation: TimeInterval {
      get { 0 }
      set { _ = newValue }
    }
  convenience init(mediaSubtypesForNativeRepresentation subtypes: [NSNumber]) { self.init() }
  public var textStylingResolution: AVPlayerItemLegibleOutput.TextStylingResolution {
      get { AVPlayerItemLegibleOutput.TextStylingResolution(rawValue: "") }
      set { _ = newValue }
    }
}

public protocol AVPlayerItemLegibleOutputPushDelegate : AVPlayerItemOutputPushDelegate {
  func legibleOutput(_ output: AVPlayerItemLegibleOutput, didOutputAttributedStrings strings: [NSAttributedString], nativeSampleBuffers nativeSamples: [Any], forItemTime itemTime: CMTime)
}

open class AVPlayerItemMediaDataCollector: NSObject, @unchecked Sendable {
  public override init() { super.init() }
}

open class AVPlayerItemMetadataCollector: AVPlayerItemMediaDataCollector, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(identifiers: [String]?, classifyingLabels: [String]?) { self.init() }
  public func setDelegate(_ delegate: (any AVPlayerItemMetadataCollectorPushDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public var delegate: (any AVPlayerItemMetadataCollectorPushDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
}

public protocol AVPlayerItemMetadataCollectorPushDelegate : AnyObject, Sendable {
  func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector, didCollect metadataGroups: sending [AVDateRangeMetadataGroup], indexesOfNewGroups: IndexSet, indexesOfModifiedGroups: IndexSet)
}

open class AVPlayerItemMetadataOutput: AVPlayerItemOutput, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(identifiers: [String]?) { self.init() }
  public func setDelegate(_ delegate: (any AVPlayerItemMetadataOutputPushDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public var delegate: (any AVPlayerItemMetadataOutputPushDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
  public var advanceIntervalForDelegateInvocation: TimeInterval {
      get { 0 }
      set { _ = newValue }
    }
}

public protocol AVPlayerItemMetadataOutputPushDelegate : AVPlayerItemOutputPushDelegate {
  func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: sending [AVTimedMetadataGroup], from track: AVPlayerItemTrack?)
}

open class AVPlayerItemOutput: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public func itemTime(forHostTime hostTimeInSeconds: TimeInterval) -> CMTime { .zero }
  public func itemTime(forMachAbsoluteTime machAbsoluteTime: Int64) -> CMTime { .zero }
  public var suppressesPlayerRendering: Bool {
      get { false }
      set { _ = newValue }
    }
}

public protocol AVPlayerItemOutputPullDelegate : AnyObject, Sendable {
  func outputMediaDataWillChange(_ sender: AVPlayerItemOutput)
  func outputSequenceWasFlushed(_ output: AVPlayerItemOutput)
}

public protocol AVPlayerItemOutputPushDelegate : AnyObject, Sendable {
  func outputSequenceWasFlushed(_ output: AVPlayerItemOutput)
}

open class AVPlayerItemRenderedLegibleOutput: AVPlayerItemOutput, @unchecked Sendable {
  public override init() { super.init() }
  convenience init(videoDisplay videoDisplaySize: CGSize) { self.init() }
  public func setDelegate(_ delegate: (any AVPlayerItemRenderedLegibleOutputPushDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public var delegate: (any AVPlayerItemRenderedLegibleOutputPushDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
  public var advanceIntervalForDelegateInvocation: TimeInterval {
      get { 0 }
      set { _ = newValue }
    }
  public var videoDisplaySize: CGSize {
      get { .zero }
      set { _ = newValue }
    }
}

public protocol AVPlayerItemRenderedLegibleOutputPushDelegate : AVPlayerItemOutputPushDelegate {
  func renderedLegibleOutput(_ output: AVPlayerItemRenderedLegibleOutput, didOutputRenderedCaptionImages captionImages: [AVRenderedCaptionImage], forItemTime itemTime: CMTime)
}

open class AVPlayerItemSegment: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum SegmentType: Int, Hashable, Sendable {
    case primary = 0
    case interstitial = 1
  }
  public var loadedTimeRanges: [CMTimeRange] { [] }
  public var segmentType: AVPlayerItemSegment.SegmentType { AVPlayerItemSegment.SegmentType(rawValue: 0)! }
  public var timeMapping: CMTimeMapping { CMTimeMapping() }
  public var startDate: Date? { nil }
  public var interstitialEvent: AVPlayerInterstitialEvent? { nil }
}

open class AVPlayerItemTrack: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  var portableAssetTrack: AVAssetTrack?
  public var assetTrack: AVAssetTrack? { portableAssetTrack }
  public var isEnabled: Bool {
      get { portableAssetTrack?.isEnabled ?? false }
      set { _ = newValue }
    }
  public var currentVideoFrameRate: Float { portableAssetTrack?.nominalFrameRate ?? 0 }
}

open class AVPlayerItemVideoOutput: AVPlayerItemOutput, @unchecked Sendable {
  public override init() { super.init() }
  public convenience init(pixelBufferAttributes: CVPixelBufferAttributes) { self.init() }
  public func pixelBufferAndDisplayTime(forItemTime itemTime: CMTime) -> (pixelBuffer: CVReadOnlyPixelBuffer?, itemTimeForDisplay: CMTime) {
    _ = itemTime
    return (pixelBuffer: nil, itemTimeForDisplay: .zero)
  }
  public convenience init(pixelBufferAttributes: [String : any Sendable]? = nil) { self.init() }
  public convenience init(outputSettings: [String : any Sendable]?) { self.init() }
  public func hasNewPixelBuffer(forItemTime itemTime: CMTime) -> Bool { false }
  public func copyPixelBuffer(forItemTime itemTime: CMTime, itemTimeForDisplay outItemTimeForDisplay: UnsafeMutablePointer<CMTime>?) -> CVPixelBuffer? { nil }
  public func setDelegate(_ delegate: (any AVPlayerItemOutputPullDelegate)?, queue delegateQueue: DispatchQueue?) {}
  public func requestNotificationOfMediaDataChange(withAdvanceInterval interval: TimeInterval) {}
  public var delegate: (any AVPlayerItemOutputPullDelegate)? { nil }
  public var delegateQueue: DispatchQueue? { nil }
}

open class AVPlayerLooper: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public enum ItemOrdering: Int, Hashable, Sendable {
    case loopingItemsPrecedeExistingItems = 0
    case loopingItemsFollowExistingItems = 1
  }
  public enum Status: Int, Hashable, Sendable {
    case unknown = 0
    case ready = 1
    case failed = 2
    case cancelled = 3
  }
  private weak var queuePlayer: AVQueuePlayer?
  private var template: AVPlayerItem?
  private var storedItems: [AVPlayerItem] = []
  private var storedStatus = Status.unknown
  private var storedLoopCount = 0

  public convenience init(player: AVQueuePlayer, templateItem itemToLoop: AVPlayerItem) {
    self.init(player: player, templateItem: itemToLoop, timeRange: .zero)
  }
  public convenience init(player: AVQueuePlayer, templateItem itemToLoop: AVPlayerItem, timeRange loopRange: CMTimeRange) {
    self.init(player: player, templateItem: itemToLoop, timeRange: loopRange, existingItemsOrdering: .loopingItemsPrecedeExistingItems)
  }
  public convenience init(
    player: AVQueuePlayer,
    templateItem itemToLoop: AVPlayerItem,
    timeRange loopRange: CMTimeRange,
    existingItemsOrdering itemOrdering: AVPlayerLooper.ItemOrdering
  ) {
    self.init()
    _ = loopRange
    queuePlayer = player
    template = itemToLoop
    let copy = AVPlayerItem(asset: itemToLoop.asset)
    storedItems = [copy]
    storedStatus = .ready
    if itemOrdering == .loopingItemsPrecedeExistingItems {
      player.insert(copy, after: nil)
    } else if let last = player.items().last {
      player.insert(copy, after: last)
    } else {
      player.insert(copy, after: nil)
    }
  }
  public var status: AVPlayerLooper.Status { storedStatus }
  public var error: (any Error)? { nil }
  public func disableLooping() { storedStatus = .cancelled }
  public var loopCount: Int { storedLoopCount }
  public var loopingPlayerItems: [AVPlayerItem] { storedItems }
}

open class AVPlayerMediaSelectionCriteria: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  public var preferredLanguages: [String]? { nil }
  public var preferredMediaCharacteristics: [AVMediaCharacteristic]? { nil }
  public var principalMediaCharacteristics: [AVMediaCharacteristic]? { nil }
  convenience init(preferredLanguages: [String]?, preferredMediaCharacteristics: [AVMediaCharacteristic]?) { self.init() }
  convenience init(principalMediaCharacteristics: [AVMediaCharacteristic]?, preferredLanguages: [String]?, preferredMediaCharacteristics: [AVMediaCharacteristic]?) { self.init() }
}

open class AVPlayerPlaybackCoordinator: AVPlaybackCoordinator, @unchecked Sendable {
  public override init() { super.init() }
  public var player: AVPlayer? { nil }
  public var delegate: (any AVPlayerPlaybackCoordinatorDelegate)? {
      get { nil }
      set { _ = newValue }
    }
  public func coordinate(using coordinationMedium: AVPlaybackCoordinationMedium?) throws { throw AVFoundationPortableError.mediaServiceUnavailable }
  public var playbackCoordinationMedium: AVPlaybackCoordinationMedium? { nil }
}

public protocol AVPlayerPlaybackCoordinatorDelegate : AnyObject, Sendable {
  func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, identifierFor playerItem: AVPlayerItem) -> String
  func playbackCoordinator(_ coordinator: AVPlayerPlaybackCoordinator, interstitialTimeRangesFor playerItem: AVPlayerItem) -> [NSValue]
}

open class AVPlayerVideoOutput: NSObject, @unchecked Sendable {
  public override init() { super.init() }
  open class Configuration: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public var dataChannelDescription: [[CMTag]] { [] }
    public var sourcePlayerItem: AVPlayerItem? { nil }
    public var preferredTransform: CGAffineTransform { .identity }
    public var activationTime: CMTime { .zero }
  }
  public struct Sample: Sendable {
    public init() {}
    public var taggedBuffers: [CMTaggedDynamicBuffer] = []
    public var presentationTime: CMTime = .zero
    public var activeConfiguration: AVPlayerVideoOutput.Configuration = AVPlayerVideoOutput.Configuration()
  }
  public func sample(forHostTime hostTime: CMTime) -> AVPlayerVideoOutput.Sample? { nil }
  convenience init(specification: AVVideoOutputSpecification) { self.init() }
}
