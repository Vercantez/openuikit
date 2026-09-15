import Foundation
import AVFoundation

// Depth pass 13: remaining declared non-capture data models that already
// compile (or needed only an access-level fix to an existing declaration).
// Every test is top-level, synchronous, and takes no arguments. No capture
// hardware, player chrome, async load, FairPlay, PiP, AirPlay, or CIImage
// filtering success is claimed. ObjC-projected names are noted where Swift
// uses its standard renamed spelling (isReadyToPlay, isConnected,
// wasReadFromCache, isRouteDetectionEnabled).

func testMetricBaseAndErrorEvents() {
    let event = AVMetricEvent()
    precondition(event.date == .distantPast)
    precondition(event.mediaTime == .zero)
    precondition(event.sessionID == nil)

    let errorEvent = AVMetricErrorEvent()
    precondition(errorEvent.didRecover == false)
    _ = errorEvent.error
    precondition(errorEvent.date == .distantPast)
}

func testMetricContentKeyAndDownloadEvents() {
    let keyEvent = AVMetricContentKeyRequestEvent()
    _ = keyEvent.contentKeySpecifier
    precondition(keyEvent.isClientInitiated == false)
    precondition(keyEvent.mediaResourceRequestEvent == nil)
    precondition(keyEvent.mediaType == AVMediaType(rawValue: ""))

    let summary = AVMetricDownloadSummaryEvent()
    precondition(summary.errorEvent == nil)
    precondition(summary.recoverableErrorCount == 0)
    precondition(summary.mediaResourceRequestCount == 0)
    precondition(summary.bytesDownloadedCount == 0)
    precondition(summary.downloadDuration == 0)
    precondition(summary.variants.isEmpty)
}

func testMetricHLSRequestEvents() {
    let segment = AVMetricHLSMediaSegmentRequestEvent()
    precondition(segment.url == nil)
    precondition(segment.isMapSegment == false)
    precondition(segment.mediaType == AVMediaType(rawValue: ""))
    precondition(segment.indexFileURL.path == "/dev/null")
    precondition(segment.segmentDuration == 0)
    precondition(segment.mediaResourceRequestEvent == nil)

    let playlist = AVMetricHLSPlaylistRequestEvent()
    precondition(playlist.url == nil)
    precondition(playlist.isMultivariantPlaylist == false)
    precondition(playlist.mediaType == AVMediaType(rawValue: ""))
    precondition(playlist.mediaResourceRequestEvent == nil)
}

func testMetricMediaResourceAndRendition() {
    let request = AVMetricMediaResourceRequestEvent()
    precondition(request.url == nil)
    precondition(request.serverAddress == nil)
    precondition(request.requestStartTime == .distantPast)
    precondition(request.requestEndTime == .distantPast)
    precondition(request.responseStartTime == .distantPast)
    precondition(request.responseEndTime == .distantPast)
    // ObjC property readFromCache is projected in Swift as wasReadFromCache.
    precondition(request.wasReadFromCache == false)
    precondition(request.errorEvent == nil)

    let rendition = AVMetricMediaRendition()
    precondition(rendition.stableID == nil)
    precondition(rendition.url == nil)
}

func testMetricPlayerItemLikelyEvents() {
    let likely = AVMetricPlayerItemLikelyToKeepUpEvent()
    precondition(likely.timeTaken == 0)
    precondition(likely.variant == nil)

    let initial = AVMetricPlayerItemInitialLikelyToKeepUpEvent()
    precondition(initial.playlistRequestEvents.isEmpty)
    precondition(initial.mediaSegmentRequestEvents.isEmpty)
    precondition(initial.contentKeyRequestEvents.isEmpty)
    precondition(initial.timeTaken == 0)
}

func testMetricPlayerItemSummaryAndRateEvents() {
    let summary = AVMetricPlayerItemPlaybackSummaryEvent()
    precondition(summary.errorEvent == nil)
    precondition(summary.recoverableErrorCount == 0)
    precondition(summary.stallCount == 0)
    precondition(summary.variantSwitchCount == 0)
    precondition(summary.playbackDuration == 0)
    precondition(summary.mediaResourceRequestCount == 0)
    precondition(summary.timeSpentRecoveringFromStall == 0)
    precondition(summary.timeSpentInInitialStartup == 0)
    precondition(summary.timeWeightedAverageBitrate == 0)
    precondition(summary.timeWeightedPeakBitrate == 0)

    let rateChange = AVMetricPlayerItemRateChangeEvent()
    precondition(rateChange.rate == 0)
    precondition(rateChange.previousRate == 0)
    precondition(rateChange.variant == nil)

    _ = AVMetricPlayerItemSeekEvent()
    _ = AVMetricPlayerItemStallEvent()
    let seekDone = AVMetricPlayerItemSeekDidCompleteEvent()
    precondition(seekDone.didSeekInBuffer == false)
    precondition(seekDone.rate == 0)
}

func testMetricVariantSwitchEvents() {
    let switched = AVMetricPlayerItemVariantSwitchEvent()
    precondition(switched.fromVariant == nil)
    _ = switched.toVariant
    _ = switched.videoRendition
    _ = switched.audioRendition
    _ = switched.subtitleRendition
    precondition(switched.didSucceed == false)
    precondition(switched.loadedTimeRanges.isEmpty)

    let starting = AVMetricPlayerItemVariantSwitchStartEvent()
    precondition(starting.fromVariant == nil)
    _ = starting.toVariant
    _ = starting.videoRendition
    _ = starting.audioRendition
    _ = starting.subtitleRendition
    precondition(starting.loadedTimeRanges.isEmpty)
}

func testCoordinatedPlaybackModels() {
    let participant = AVCoordinatedPlaybackParticipant()
    _ = participant.identifier
    precondition(participant.identifier.uuidString.count == 36)
    // ObjC property readyToPlay is projected in Swift as isReadyToPlay.
    precondition(participant.isReadyToPlay == false)
    precondition(participant.suspensionReasons.isEmpty)

    let suspension = AVCoordinatedPlaybackSuspension()
    precondition(suspension.reason == AVCoordinatedPlaybackSuspension.Reason(rawValue: ""))
    precondition(suspension.beginDate == .distantPast)
    suspension.end()
    suspension.end(proposingNewTime: .zero)

    precondition(AVCoordinatedPlaybackSuspension.Reason(rawValue: "stallRecovery") == .stallRecovery)
    let literalReason: AVCoordinatedPlaybackSuspension.Reason = "audioSessionInterrupted"
    precondition(literalReason == .audioSessionInterrupted)
}

func testDelegatingPlaybackCoordinatorModel() {
    let witness = DepthPass13PlaybackControlWitness()
    let coordinator = AVDelegatingPlaybackCoordinator(playbackControlDelegate: witness)
    precondition(coordinator.playbackControlDelegate == nil)
    precondition(coordinator.currentItemIdentifier == nil)
    coordinator.coordinateRateChange(to: 1.0, options: .playImmediately)
    coordinator.coordinateSeek(to: .zero, options: .resumeImmediately)
    coordinator.transitionToItem(withIdentifier: "item-1", proposingInitialTimingBasedOn: nil)
    coordinator.reapplyCurrentItemStateToPlaybackControlDelegate()

    let play = AVDelegatingPlaybackCoordinatorPlayCommand()
    precondition(play.rate == 0)
    precondition(play.itemTime == .zero)
    precondition(play.hostClockTime == .zero)
    precondition(play.expectedCurrentItemIdentifier.isEmpty)
    precondition(play.originator == nil)

    let pause = AVDelegatingPlaybackCoordinatorPauseCommand()
    precondition(pause.shouldBufferInAnticipationOfPlayback == false)
    precondition(pause.anticipatedPlaybackRate == 0)

    let seek = AVDelegatingPlaybackCoordinatorSeekCommand()
    precondition(seek.itemTime == .zero)
    precondition(seek.shouldBufferInAnticipationOfPlayback == false)
    precondition(seek.anticipatedPlaybackRate == 0)
    precondition(seek.completionDueDate == nil)

    let buffering = AVDelegatingPlaybackCoordinatorBufferingCommand()
    precondition(buffering.anticipatedPlaybackRate == 0)
    precondition(buffering.completionDueDate == nil)
}

final class DepthPass13PlaybackControlWitness: NSObject, AVPlaybackCoordinatorPlaybackControlDelegate, @unchecked Sendable {
    var plays = 0
    var pauses = 0
    var seeks = 0
    var bufferings = 0
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue playCommand: AVDelegatingPlaybackCoordinatorPlayCommand, completionHandler: @escaping () -> Void) {
        _ = (coordinator, playCommand)
        plays += 1
        completionHandler()
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue playCommand: AVDelegatingPlaybackCoordinatorPlayCommand) async {
        _ = (coordinator, playCommand)
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue pauseCommand: AVDelegatingPlaybackCoordinatorPauseCommand, completionHandler: @escaping () -> Void) {
        _ = (coordinator, pauseCommand)
        pauses += 1
        completionHandler()
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue pauseCommand: AVDelegatingPlaybackCoordinatorPauseCommand) async {
        _ = (coordinator, pauseCommand)
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue seekCommand: AVDelegatingPlaybackCoordinatorSeekCommand, completionHandler: @escaping () -> Void) {
        _ = (coordinator, seekCommand)
        seeks += 1
        completionHandler()
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue seekCommand: AVDelegatingPlaybackCoordinatorSeekCommand) async {
        _ = (coordinator, seekCommand)
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue bufferingCommand: AVDelegatingPlaybackCoordinatorBufferingCommand, completionHandler: @escaping () -> Void) {
        _ = (coordinator, bufferingCommand)
        bufferings += 1
        completionHandler()
    }
    func playbackCoordinator(_ coordinator: AVDelegatingPlaybackCoordinator, didIssue bufferingCommand: AVDelegatingPlaybackCoordinatorBufferingCommand) async {
        _ = (coordinator, bufferingCommand)
    }
}

func testPlaybackCoordinatorAndMedium() {
    let medium = AVPlaybackCoordinationMedium()
    precondition(medium.connectedPlaybackCoordinators.isEmpty)

    let coordinator = AVPlaybackCoordinator()
    precondition(coordinator.otherParticipants.isEmpty)
    precondition(coordinator.suspensionReasons.isEmpty)
    let suspension = coordinator.beginSuspension(for: "stallRecovery")
    precondition(suspension.reason.rawValue.isEmpty)
    precondition(coordinator.expectedItemTime(atHostTime: .zero) == .zero)
    coordinator.setParticipantLimit(2, forWaitingOutSuspensionsWithReason: "stallRecovery")
    precondition(coordinator.participantLimitForWaitingOutSuspensions(withReason: "stallRecovery") == 0)
    precondition(coordinator.pauseSnapsToMediaTimeOfOriginator == false)
    coordinator.pauseSnapsToMediaTimeOfOriginator = true
    precondition(coordinator.pauseSnapsToMediaTimeOfOriginator == false)
    precondition(coordinator.suspensionReasonsThatTriggerWaiting.isEmpty)
    coordinator.suspensionReasonsThatTriggerWaiting = ["stallRecovery"]
    precondition(coordinator.suspensionReasonsThatTriggerWaiting.isEmpty)
}

final class DepthPass13SyncDeviceWitness: NSObject, AVExternalSyncDeviceDelegate {
    var statusChanges = 0
    var failures = 0
    func externalSyncDeviceStatusDidChange(_ device: AVExternalSyncDevice) {
        _ = device
        statusChanges += 1
    }
    func externalSyncDevice(_ device: AVExternalSyncDevice, failedWithError error: (any Error)?) {
        _ = (device, error)
        failures += 1
    }
}

func testExternalSyncAndPlaybackControlDelegates() {
    let syncWitness = DepthPass13SyncDeviceWitness()
    let syncDelegate: any AVExternalSyncDeviceDelegate = syncWitness
    let device = AVExternalSyncDevice()
    syncDelegate.externalSyncDeviceStatusDidChange(device)
    syncDelegate.externalSyncDevice(device, failedWithError: nil)
    precondition(syncWitness.statusChanges == 1)
    precondition(syncWitness.failures == 1)

    let controlWitness = DepthPass13PlaybackControlWitness()
    let controlDelegate: any AVPlaybackCoordinatorPlaybackControlDelegate = controlWitness
    let coordinator = AVDelegatingPlaybackCoordinator()
    var completions = 0
    controlDelegate.playbackCoordinator(coordinator, didIssue: AVDelegatingPlaybackCoordinatorPlayCommand()) { completions += 1 }
    controlDelegate.playbackCoordinator(coordinator, didIssue: AVDelegatingPlaybackCoordinatorPauseCommand()) { completions += 1 }
    controlDelegate.playbackCoordinator(coordinator, didIssue: AVDelegatingPlaybackCoordinatorSeekCommand()) { completions += 1 }
    controlDelegate.playbackCoordinator(coordinator, didIssue: AVDelegatingPlaybackCoordinatorBufferingCommand()) { completions += 1 }
    precondition(controlWitness.plays == 1)
    precondition(controlWitness.pauses == 1)
    precondition(controlWitness.seeks == 1)
    precondition(controlWitness.bufferings == 1)
    precondition(completions == 4)
}

func testExternalStorageAndSyncDevices() {
    let storage = AVExternalStorageDevice()
    precondition(storage.displayName == nil)
    precondition(storage.freeSize == 0)
    precondition(storage.totalSize == 0)
    // ObjC property connected is projected in Swift as isConnected.
    precondition(storage.isConnected == false)
    precondition(storage.uuid == nil)
    // ObjC property notRecommendedForCaptureUse is projected with an is prefix.
    precondition(storage.isNotRecommendedForCaptureUse == false)
    let urls = try? storage.nextAvailableURLs(withPathExtensions: ["mp4"])
    precondition(urls?.isEmpty == true)

    let discovery = AVExternalStorageDeviceDiscoverySession()
    precondition(discovery.externalStorageDevices.isEmpty)
    precondition(AVExternalStorageDeviceDiscoverySession.shared == nil)

    let sync = AVExternalSyncDevice()
    precondition(sync.status == .unavailable)
    precondition(sync.clock == nil)
    precondition(sync.signalCompensationDelay == .zero)
    sync.signalCompensationDelay = CMTime(value: 1, timescale: 600)
    precondition(sync.signalCompensationDelay == .zero)
    precondition(sync.uuid.uuidString.count == 36)
    precondition(sync.vendorID == 0)
    precondition(sync.productID == 0)

    let syncDiscovery = AVExternalSyncDevice.DiscoverySession()
    precondition(syncDiscovery.devices.isEmpty)
}

func testMediaDataStorageAndFrameRateRange() {
    let storage = AVMediaDataStorage(url: URL(fileURLWithPath: "/tmp/media.dat"))
    precondition(storage.url() == nil)

    let range = AVFrameRateRange()
    precondition(range.minFrameDuration == .zero)
    precondition(range.maxFrameDuration == .zero)

    precondition(AVDepthData().availableDepthDataTypes.isEmpty)
}

func testMatteRouteAndVideoOutputModels() {
    let portrait = AVPortraitEffectsMatte()
    _ = portrait.mattingImage
    let replacedPortrait = try? portrait.replacingPortraitEffectsMatte(with: CVPixelBuffer())
    precondition(replacedPortrait == nil)
    let fromDictionary = try? AVPortraitEffectsMatte(fromDictionaryRepresentation: [:])
    precondition(fromDictionary == nil)

    let semantic = AVSemanticSegmentationMatte()
    precondition(semantic.matteType == AVSemanticSegmentationMatte.MatteType(rawValue: ""))
    _ = semantic.mattingImage
    let replacedSemantic = try? semantic.replacingSemanticSegmentationMatte(with: CVPixelBuffer())
    precondition(replacedSemantic == nil)
    precondition(AVSemanticSegmentationMatte.MatteType(rawValue: "skin") == .skin)

    let detector = AVRouteDetector()
    // ObjC property routeDetectionEnabled is projected with an is prefix.
    precondition(detector.isRouteDetectionEnabled == false)
    detector.isRouteDetectionEnabled = true
    precondition(detector.isRouteDetectionEnabled == false)
    precondition(detector.multipleRoutesDetected == false)
    precondition(detector.detectsCustomRoutes == false)
    detector.detectsCustomRoutes = true
    precondition(detector.detectsCustomRoutes == false)

    let spec = AVVideoOutputSpecification()
    precondition(spec.preferredTagCollections.isEmpty)
    precondition(spec.defaultOutputSettings == nil)
    precondition(spec.defaultPixelBufferAttributes == nil)
    spec.setOutputSettings(["key": "value"] as [String: any Sendable], for: [])
    spec.setOutputPixelBufferAttributes(["key": "value"], for: [])
    precondition(spec.defaultOutputSettings == nil)
    precondition(spec.defaultPixelBufferAttributes == nil)
    _ = AVVideoOutputSpecification(tagCollections: [])
}

func testSampleBufferContentKeyAndCMTags() {
    precondition(AVSampleBufferAttachContentKey(CMSampleBuffer(), AVContentKey(), nil) == false)
    let ready = CMReadySampleBuffer(content: CMSampleBuffer.DynamicContent.portable)
    let attached: Void? = try? ready.attach(contentKey: AVContentKey())
    precondition(attached == nil)

    precondition(Array<CMTag>.monoscopicForVideoOutput().isEmpty)
    precondition(Array<CMTag>.stereoscopicForVideoOutput().isEmpty)

    precondition(AVVideoRange(rawValue: "sdr") == .sdr)
    precondition(AVVariantPreferences(rawValue: 1) == .scalabilityToLosslessAudio)
    precondition(AVDelegatingPlaybackCoordinatorRateChangeOptions(rawValue: 1) == .playImmediately)
    precondition(AVDelegatingPlaybackCoordinatorSeekOptions(rawValue: 1) == .resumeImmediately)
}
