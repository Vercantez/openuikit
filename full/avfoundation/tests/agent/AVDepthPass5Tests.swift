import Foundation
import AVFoundation

func testAVMutableMetadataItemStoredValuesAndFiltering() {
    let title = AVMutableMetadataItem()
    title.identifier = .commonIdentifierTitle
    title.keySpace = .common
    title.key = AVMetadataKey.commonKeyTitle.rawValue as NSString
    title.value = "OpenUIKit" as NSString
    title.time = CMTime(seconds: 1, preferredTimescale: 600)
    title.duration = CMTime(seconds: 2, preferredTimescale: 600)
    title.extendedLanguageTag = "en"
    title.locale = Locale(identifier: "en")
    title.dataType = "com.apple.metadata.datatype.UTF-8"
    title.startDate = Date(timeIntervalSince1970: 1)
    title.extraAttributes = [.info: "probe"]
    AVMetadataItemValueRequest().respond(error: AVError(.unknown))
    precondition(title.identifier == .commonIdentifierTitle)
    precondition(title.keySpace == .common)
    precondition(title.commonKey == .commonKeyTitle)
    precondition(title.stringValue == "OpenUIKit")
    precondition(title.numberValue == nil)
    precondition(abs(title.time.seconds - 1) < 0.001)
    precondition(abs(title.duration.seconds - 2) < 0.001)
    precondition(title.extendedLanguageTag == "en")
    precondition(title.locale?.identifier == "en")
    precondition(title.dataType == "com.apple.metadata.datatype.UTF-8")
    precondition(title.startDate?.timeIntervalSince1970 == 1)
    precondition(title.extraAttributes?[.info] as? String == "probe")

    let count = AVMutableMetadataItem()
    count.identifier = .commonIdentifierType
    count.value = NSNumber(value: 7)
    count.locale = Locale(identifier: "fr")
    count.extendedLanguageTag = "fr"
    precondition(count.numberValue?.intValue == 7)
    precondition(count.stringValue == nil)

    let when = AVMutableMetadataItem()
    when.value = NSDate(timeIntervalSince1970: 42)
    precondition(when.dateValue?.timeIntervalSince1970 == 42)

    let blob = AVMutableMetadataItem()
    blob.value = NSData(data: Data([0x01, 0x02]))
    precondition(blob.dataValue?.count == 2)

    let mapped = AVMetadataItem.identifier(forKey: AVMetadataKey.commonKeyTitle, keySpace: .common)
    precondition(mapped == .commonIdentifierTitle)
    precondition(AVMetadataItem.keySpace(forIdentifier: .commonIdentifierTitle) == .common)
    precondition((AVMetadataItem.key(forIdentifier: .commonIdentifierTitle) as? AVMetadataKey) == .commonKeyTitle)

    let byID = AVMetadataItem.metadataItems(from: [title, count], filteredByIdentifier: .commonIdentifierTitle)
    precondition(byID.count == 1)
    precondition(byID[0].stringValue == "OpenUIKit")
    let byLocale = AVMetadataItem.metadataItems(from: [title, count], with: Locale(identifier: "fr"))
    precondition(byLocale.count == 1)
    let byKey = AVMetadataItem.metadataItems(
        from: [title, count],
        withKey: AVMetadataKey.commonKeyTitle,
        keySpace: .common
    )
    precondition(byKey.count == 1)
    let preferred = AVMetadataItem.metadataItems(
        from: [title, count],
        filteredAndSortedAccordingToPreferredLanguages: ["fr", "en"]
    )
    precondition(preferred.count == 2)
    precondition(preferred[0].extendedLanguageTag == "fr")
    let shared = AVMetadataItem.metadataItems(from: [title], filteredBy: .forSharing())
    precondition(shared.count == 1)

    let loaded = AVMetadataItem(propertiesOfMetadataItem: title) { request in
        request.respond(value: "loaded" as NSString)
    }
    precondition(loaded.identifier == .commonIdentifierTitle)
    precondition(loaded.stringValue == "loaded")
}

func testAVCompositionTrackSegmentsAndProperties() {
    var wav = Data()
    func le32(_ value: UInt32) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 4)
    }
    func le16(_ value: UInt16) -> Data {
        var v = value.littleEndian
        return Data(bytes: &v, count: 2)
    }
    wav.append(contentsOf: Array("RIFF".utf8))
    wav.append(le32(36 + 16000))
    wav.append(contentsOf: Array("WAVE".utf8))
    wav.append(contentsOf: Array("fmt ".utf8))
    wav.append(le32(16))
    wav.append(le16(1))
    wav.append(le16(1))
    wav.append(le32(8000))
    wav.append(le32(16000))
    wav.append(le16(2))
    wav.append(le16(16))
    wav.append(contentsOf: Array("data".utf8))
    wav.append(le32(16000))
    wav.append(Data(count: 16000))
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("openav-comp-\(UUID().uuidString).wav")
    try! wav.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }

    let asset = AVURLAsset(url: url)
    precondition(asset.tracks.count == 1)
    let source = asset.tracks[0]
    let composition = AVMutableComposition()
    let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 1)!
    try! track.insertTimeRange(
        CMTimeRange(start: .zero, duration: CMTime(seconds: 0.5, preferredTimescale: 8000)),
        of: source,
        at: .zero
    )
    precondition(track.segments.count == 1)
    let sourced = track.segments[0] as! AVCompositionTrackSegment
    precondition(!sourced.isEmpty)
    precondition(sourced.sourceTrackID == source.trackID)
    precondition(sourced.sourceURL == url)
    let found = track.segment(forTrackTime: CMTime(seconds: 0.1, preferredTimescale: 8000))
    precondition(found === sourced)
    let mapped = track.samplePresentationTime(forTrackTime: CMTime(seconds: 0.1, preferredTimescale: 8000))
    precondition(abs(mapped.seconds - 0.1) < 0.02)
    precondition(track.hasMediaCharacteristic(.audible))
    precondition(track.mediaType == .audio)
    precondition(track.languageCode == source.languageCode)
    precondition(track.isEnabled)
    precondition(!track.isPlayable)
    precondition(!track.isDecodable)
    precondition(!track.canProvideSampleCursors)
    precondition(track.formatDescriptions.isEmpty)
    precondition(track.commonMetadata.isEmpty)
    precondition(track.metadata.isEmpty)
    precondition(track.availableMetadataFormats.isEmpty)
    precondition(track.metadata(forFormat: .quickTimeMetadata).isEmpty)
    precondition(!track.hasAudioSampleDependencies)
    precondition(!track.requiresFrameReordering)
    precondition(track.preferredVolume == source.preferredVolume)
    precondition(track.minFrameDuration.seconds >= 0)
    precondition(track.totalSampleDataLength >= 0)
    precondition(track.estimatedDataRate >= 0)
    precondition(track.timeRange.start == .zero)
}

func testAVMutableCompositionTrackEditsAndValidation() {
    let composition = AVMutableComposition()
    let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2)!
    track.languageCode = "fra"
    track.extendedLanguageTag = "fra"
    track.naturalTimeScale = 44100
    track.isEnabled = false
    track.preferredVolume = 0.25
    track.preferredTransform = .identity
    precondition(track.languageCode == "fra")
    precondition(track.extendedLanguageTag == "fra")
    precondition(track.naturalTimeScale == 44100)
    precondition(!track.isEnabled)
    precondition(abs(track.preferredVolume - 0.25) < 0.001)
    track.isEnabled = true

    track.insertEmptyTimeRange(CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1)))
    precondition(track.segments.count == 1)
    precondition((track.segments[0] as! AVCompositionTrackSegment).isEmpty)
    let currentSegments = track.segments.compactMap { $0 as? AVCompositionTrackSegment }
    try! track.validateSegments(currentSegments)

    let gap = AVCompositionTrackSegment(
        timeRange: CMTimeRange(start: CMTime(seconds: 3, preferredTimescale: 1), duration: CMTime(seconds: 1, preferredTimescale: 1))
    )
    do {
        try track.validateSegments(currentSegments + [gap])
        preconditionFailure("gapped segments must fail closed")
    } catch let error as AVError {
        precondition(error.code == .compositionTrackSegmentsNotContiguous)
    } catch {
        preconditionFailure("unexpected \(error)")
    }

    let invalidDuration = AVCompositionTrackSegment(
        timeRange: CMTimeRange(start: .zero, duration: .invalid)
    )
    do {
        try track.validateSegments([invalidDuration])
        preconditionFailure("invalid duration must fail closed")
    } catch let error as AVError {
        precondition(error.code == .invalidCompositionTrackSegmentDuration)
    } catch {
        preconditionFailure("unexpected \(error)")
    }

    let other = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 3)!
    track.addTrackAssociation(to: other, type: .audioFallback)
    precondition(track.associatedTracks(ofType: .audioFallback).count == 1)
    precondition(track.availableTrackAssociationTypes.contains(.audioFallback))
    track.removeTrackAssociation(to: other, type: .audioFallback)
    precondition(track.associatedTracks(ofType: .audioFallback).isEmpty)
    track.replaceFormatDescription(CMFormatDescription(), with: CMFormatDescription())
    precondition(track.formatDescriptionReplacements.count == 1)
    _ = track.formatDescriptionReplacements[0].originalFormatDescription
    _ = track.formatDescriptionReplacements[0].replacementFormatDescription
}

func testAVCompositionTrackSegmentModel() {
    let empty = AVCompositionTrackSegment(
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 2, preferredTimescale: 1))
    )
    precondition(empty.isEmpty)
    precondition(empty.sourceURL == nil)
    precondition(empty.sourceTrackID == 0)
    precondition(abs(empty.timeMapping.target.duration.seconds - 2) < 0.001)

    let url = URL(fileURLWithPath: "/tmp/openav-seg.mp4")
    let sourced = AVCompositionTrackSegment(
        url: url,
        trackID: 7,
        sourceTimeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1)),
        targetTimeRange: CMTimeRange(start: CMTime(seconds: 1, preferredTimescale: 1), duration: CMTime(seconds: 1, preferredTimescale: 1))
    )
    precondition(!sourced.isEmpty)
    precondition(sourced.sourceURL == url)
    precondition(sourced.sourceTrackID == 7)
    let aliased = AVCompositionTrackSegment(
        URL: url,
        trackID: 8,
        sourceTimeRange: sourced.timeMapping.source,
        targetTimeRange: sourced.timeMapping.target
    )
    precondition(aliased.sourceTrackID == 8)
}

func testAVAssetWriterInputStoredPropertiesFailClosed() {
    let hint = CMFormatDescription()
    let input = AVAssetWriterInput(
        mediaType: .video,
        outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264.rawValue],
        sourceFormatHint: hint
    )
    precondition(input.mediaType == .video)
    precondition(input.outputSettings?[AVVideoCodecKey] as? String == AVVideoCodecType.h264.rawValue)
    precondition(input.sourceFormatHint === hint)
    input.languageCode = "eng"
    input.extendedLanguageTag = "en-US"
    input.naturalSize = CGSize(width: 1920, height: 1080)
    input.transform = .identity
    input.preferredVolume = 0.5
    input.marksOutputTrackAsEnabled = true
    input.mediaTimeScale = 600
    input.preferredMediaChunkDuration = CMTime(seconds: 2, preferredTimescale: 1)
    input.preferredMediaChunkAlignment = 1
    input.sampleReferenceBaseURL = URL(fileURLWithPath: "/tmp")
    input.mediaDataLocation = .beforeMainMediaDataNotInterleaved
    precondition(AVAssetWriterInput.MediaDataLocation(rawValue: "custom").rawValue == "custom")
    input.expectsMediaDataInRealTime = true
    input.performsMultiPassEncodingIfSupported = true
    let meta = AVMutableMetadataItem()
    meta.identifier = .commonIdentifierTitle
    input.metadata = [meta]
    precondition(input.languageCode == "eng")
    precondition(input.extendedLanguageTag == "en-US")
    precondition(input.naturalSize.width == 1920)
    precondition(input.preferredVolume == 0.5)
    precondition(input.marksOutputTrackAsEnabled)
    precondition(input.mediaTimeScale == 600)
    precondition(input.preferredMediaChunkDuration.seconds == 2)
    precondition(input.preferredMediaChunkAlignment == 1)
    precondition(input.sampleReferenceBaseURL?.path == "/tmp")
    precondition(input.mediaDataLocation == .beforeMainMediaDataNotInterleaved)
    precondition(input.expectsMediaDataInRealTime)
    precondition(input.performsMultiPassEncodingIfSupported)
    precondition(input.metadata.count == 1)
    precondition(!input.isReadyForMoreMediaData)
    precondition(!input.canPerformMultiplePasses)
    precondition(input.currentPassDescription == nil)
    precondition(!input.append(CMSampleBuffer()))
    input.markAsFinished()
    input.markCurrentPassAsFinished()
    let audio = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
    precondition(!input.canAddTrackAssociation(withTrackOf: audio, type: AVAssetTrack.AssociationType.audioFallback.rawValue))
    input.addTrackAssociation(withTrackOf: audio, type: AVAssetTrack.AssociationType.audioFallback.rawValue)

    let caption = AVAssetWriterInputCaptionAdaptor(assetWriterInput: input)
    precondition(caption.assetWriterInput === input)
    precondition(!caption.append(AVCaption()))
    precondition(!caption.append(AVCaptionGroup()))
    let metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    precondition(metadataAdaptor.assetWriterInput === input)
    precondition(!metadataAdaptor.append(AVTimedMetadataGroup()))
    let receiver = AVAssetWriterInput.CaptionReceiver()
    precondition((try? receiver.appendImmediately(AVCaption())) == false)
    receiver.finish()
    let metadataReceiver = AVAssetWriterInput.MetadataReceiver()
    metadataReceiver.finish()
    _ = AVAssetWriterInput.MultiPassController()
    let sampleReceiver = AVAssetWriterInput.SampleBufferReceiver()
    sampleReceiver.finish()
}

func testAVPlayerInterstitialEventStoredModel() {
    let primary = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-primary.mp4"))
    let filler = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-fill.mp4"))
    let event = AVPlayerInterstitialEvent(
        primaryItem: primary,
        identifier: "ad-1",
        time: CMTime(seconds: 15, preferredTimescale: 1),
        templateItems: [filler],
        restrictions: [.constrainsSeekingForwardInPrimaryContent],
        resumptionOffset: CMTime(seconds: 1, preferredTimescale: 1),
        playoutLimit: CMTime(seconds: 30, preferredTimescale: 1),
        userDefinedAttributes: ["campaign": "linux"]
    )
    precondition(event.primaryItem === primary)
    precondition(event.identifier == "ad-1")
    precondition(event.time.seconds == 15)
    precondition(event.templateItems.count == 1)
    precondition(event.restrictions.contains(.constrainsSeekingForwardInPrimaryContent))
    precondition(event.resumptionOffset.seconds == 1)
    precondition(event.playoutLimit.seconds == 30)
    event.cue = .joinCue
    event.willPlayOnce = true
    event.alignsStartWithPrimarySegmentBoundary = true
    event.alignsResumptionWithPrimarySegmentBoundary = true
    event.timelineOccupancy = .fill
    event.supplementsPrimaryContent = true
    event.contentMayVary = false
    event.plannedDuration = CMTime(seconds: 30, preferredTimescale: 1)
    event.skipControlTimeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 5, preferredTimescale: 1))
    event.skipControlLocalizedLabelBundleKey = "skip"
    event.date = Date(timeIntervalSince1970: 10)
    precondition(event.cue == .joinCue)
    precondition(event.willPlayOnce)
    precondition(event.alignsStartWithPrimarySegmentBoundary)
    precondition(event.alignsResumptionWithPrimarySegmentBoundary)
    precondition(event.timelineOccupancy == .fill)
    precondition(event.supplementsPrimaryContent)
    precondition(!event.contentMayVary)
    precondition(event.plannedDuration.seconds == 30)
    precondition(event.skipControlLocalizedLabelBundleKey == "skip")
    precondition(event.date?.timeIntervalSince1970 == 10)
    precondition(event.assetListResponse == nil)
    precondition(AVPlayerInterstitialEvent.Cue.noCue.rawValue == "noCue")
    precondition(AVPlayerInterstitialEvent.Cue.leaveCue.rawValue == "leaveCue")
    precondition(AVPlayerInterstitialEvent.Cue.joinCue.rawValue == "joinCue")
    precondition(AVPlayerInterstitialEvent.Restrictions.requiresPlaybackAtPreferredRateForAdvancement.rawValue == 1 << 1)
    precondition(AVPlayerInterstitialEvent.SkippableEventState.notSkippable.rawValue == 0)
    precondition(AVPlayerInterstitialEvent.SkippableEventState.notYetEligible.rawValue == 1)
    precondition(AVPlayerInterstitialEvent.SkippableEventState.eligible.rawValue == 2)
    precondition(AVPlayerInterstitialEvent.SkippableEventState.noLongerEligible.rawValue == 3)
    precondition(AVPlayerInterstitialEvent.TimelineOccupancy.singlePoint.rawValue == 0)
    precondition(AVPlayerInterstitialEvent.TimelineOccupancy.fill.rawValue == 1)

    let dated = AVPlayerInterstitialEvent(primaryItem: primary, date: Date(timeIntervalSince1970: 1))
    precondition(dated.date?.timeIntervalSince1970 == 1)
    let timed = AVPlayerInterstitialEvent(primaryItem: primary, time: .zero)
    precondition(timed.time == .zero)
}

func testAVPlayerInterstitialEventMonitorNotificationNames() {
    let player = AVPlayer()
    let monitor = AVPlayerInterstitialEventMonitor(primaryPlayer: player)
    precondition(monitor.primaryPlayer === player)
    precondition(monitor.events.isEmpty)
    precondition(monitor.currentEvent == nil)
    precondition(monitor.currentEventSkippableState == .notSkippable)
    precondition(monitor.currentEventSkipControlLabel == nil)
    precondition(
        AVPlayerInterstitialEventMonitor.eventsDidChangeNotification.rawValue
            == "AVPlayerInterstitialEventMonitorEventsDidChangeNotification"
    )
    precondition(
        AVPlayerInterstitialEventMonitor.currentEventDidChangeNotification.rawValue
            == "AVPlayerInterstitialEventMonitorCurrentEventDidChangeNotification"
    )
    precondition(
        AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeNotification.rawValue
            == "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeNotification"
    )
    precondition(
        AVPlayerInterstitialEventMonitor.currentEventSkippableStateDidChangeNotification.rawValue
            == "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeNotification"
    )
    precondition(
        AVPlayerInterstitialEventMonitor.currentEventSkippedNotification.rawValue
            == "AVPlayerInterstitialEventMonitorCurrentEventSkippedNotification"
    )
    precondition(
        AVPlayerInterstitialEventMonitor.interstitialEventWasUnscheduledNotification.rawValue
            == "AVPlayerInterstitialEventMonitorInterstitialEventWasUnscheduledNotification"
    )
    precondition(
        AVPlayerInterstitialEventMonitor.interstitialEventDidFinishNotification.rawValue
            == "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishNotification"
    )
    precondition(AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeEventKey == "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeEventKey")
    precondition(AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeStatusKey == "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeStatusKey")
    precondition(AVPlayerInterstitialEventMonitor.assetListResponseStatusDidChangeErrorKey == "AVPlayerInterstitialEventMonitorAssetListResponseStatusDidChangeErrorKey")
    precondition(AVPlayerInterstitialEventMonitor.currentEventSkippableStateDidChangeEventKey == "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeEventKey")
    precondition(AVPlayerInterstitialEventMonitor.currentEventSkippableStateDidChangeStateKey == "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeStateKey")
    precondition(AVPlayerInterstitialEventMonitor.currentEventSkippableStateDidChangeSkipControlLabelKey == "AVPlayerInterstitialEventMonitorCurrentEventSkippableStateDidChangeSkipControlLabelKey")
    precondition(AVPlayerInterstitialEventMonitor.currentEventSkippedEventKey == "AVPlayerInterstitialEventMonitorCurrentEventSkippedEventKey")
    precondition(AVPlayerInterstitialEventMonitor.interstitialEventWasUnscheduledEventKey == "AVPlayerInterstitialEventMonitorInterstitialEventWasUnscheduledEventKey")
    precondition(AVPlayerInterstitialEventMonitor.interstitialEventWasUnscheduledErrorKey == "AVPlayerInterstitialEventMonitorInterstitialEventWasUnscheduledErrorKey")
    precondition(AVPlayerInterstitialEventMonitor.interstitialEventDidFinishEventKey == "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishEventKey")
    precondition(AVPlayerInterstitialEventMonitor.interstitialEventDidFinishPlayoutTimeKey == "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishPlayoutTimeKey")
    precondition(AVPlayerInterstitialEventMonitor.interstitialEventDidFinishDidPlayEntireEventKey == "AVPlayerInterstitialEventMonitorInterstitialEventDidFinishDidPlayEntireEventKey")

    let controller = AVPlayerInterstitialEventController()
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-ie.mp4"))
    let event = AVPlayerInterstitialEvent(primaryItem: item, time: .zero)
    controller.events = [event]
    precondition(controller.events.count == 1)
    controller.cancelCurrentEvent(withResumptionOffset: .zero)
    precondition(controller.events.isEmpty)
    controller.skipCurrentEvent()
}

func testAVPlayerItemAccessLogEmptyOnLinux() {
    let item = AVPlayerItem(url: URL(fileURLWithPath: "/tmp/openav-access-log.mp4"))
    let log = item.accessLog()
    precondition(log != nil)
    precondition(log?.events.isEmpty == true)
    precondition(log?.extendedLogData() == nil)
    precondition(log?.extendedLogDataStringEncoding == String.Encoding.utf8.rawValue)
    let errorLog = item.errorLog()
    precondition(errorLog?.events.isEmpty == true)
    precondition(errorLog?.extendedLogDataStringEncoding == String.Encoding.utf8.rawValue)

    let event = AVPlayerItemAccessLogEvent()
    precondition(event.numberOfMediaRequests == 0)
    precondition(event.playbackStartDate == nil)
    precondition(event.uri == nil)
    precondition(event.serverAddress == nil)
    precondition(event.numberOfServerAddressChanges == 0)
    precondition(event.playbackSessionID == nil)
    precondition(event.playbackStartOffset == 0)
    precondition(event.segmentsDownloadedDuration == 0)
    precondition(event.durationWatched == 0)
    precondition(event.numberOfStalls == 0)
    precondition(event.numberOfBytesTransferred == 0)
    precondition(event.transferDuration == 0)
    precondition(event.observedBitrate == 0)
    precondition(event.indicatedBitrate == 0)
    precondition(event.indicatedAverageBitrate == 0)
    precondition(event.averageVideoBitrate == 0)
    precondition(event.averageAudioBitrate == 0)
    precondition(event.numberOfDroppedVideoFrames == 0)
    precondition(event.startupTime == 0)
    precondition(event.downloadOverdue == 0)
    precondition(event.observedMaxBitrate == 0)
    precondition(event.observedMinBitrate == 0)
    precondition(event.observedBitrateStandardDeviation == 0)
    precondition(event.playbackType == nil)
    precondition(event.mediaRequestsWWAN == 0)
    precondition(event.switchBitrate == 0)

    let err = AVPlayerItemErrorLogEvent()
    precondition(err.date == nil)
    precondition(err.uri == nil)
    precondition(err.serverAddress == nil)
    precondition(err.playbackSessionID == nil)
    precondition(err.errorStatusCode == 0)
    precondition(err.errorDomain == "")
    precondition(err.errorComment == nil)
    precondition(err.allHTTPResponseHeaderFields == nil)
}

func testAVPlayerItemNotificationNamesAndStoredPolicies() {
    let keys = ["duration", "tracks"]
    let item = AVPlayerItem(asset: AVURLAsset(url: URL(fileURLWithPath: "/tmp/openav-item-keys.mp4")), automaticallyLoadedAssetKeys: keys)
    precondition(item.automaticallyLoadedAssetKeys == keys)
    item.configuredTimeOffsetFromLive = CMTime(seconds: 8, preferredTimescale: 1)
    precondition(item.configuredTimeOffsetFromLive.seconds == 8)
    item.automaticallyHandlesInterstitialEvents = true
    precondition(item.automaticallyHandlesInterstitialEvents)
    item.variantPreferences = []
    precondition(item.variantPreferences.rawValue == 0)
    item.allowedAudioSpatializationFormats = []
    precondition(item.allowedAudioSpatializationFormats.rawValue == 0)
    item.textStyleRules = []
    precondition(item.textStyleRules?.isEmpty == true)
    item.audioTimePitchAlgorithm = .spectral
    precondition(item.audioTimePitchAlgorithm == .spectral)
    precondition(item.customVideoCompositor == nil)
    precondition(item.template == nil)
    precondition(item.recommendedTimeOffsetFromLive == .zero)
    _ = item.currentMediaSelection
    let group = AVMediaSelectionGroup()
    item.select(nil, in: group)
    item.selectMediaOptionAutomatically(in: group)
    precondition(item.selectedMediaOption(in: group) == nil)
    let copied = item.copy() as? AVPlayerItem
    precondition(copied != nil)
    _ = item.copy(with: nil)
    _ = AVPlayerItem(URL: URL(fileURLWithPath: "/tmp/openav-item-url.mp4"))
    _ = AVPlayerItem(asset: AVAsset())
    precondition(!item.seek(to: Date()))
    var dateSeeked = false
    precondition(!item.seek(to: Date()) { ok in
        dateSeeked = ok
    })
    precondition(!dateSeeked)
    item.selectMediaPresentationLanguage("en", for: group)
    precondition(item.selectedMediaPresentationLanguage(for: group) == "en")
    _ = item.integratedTimeline
    item.preferredCustomMediaSelectionSchemes = []
    precondition(item.preferredCustomMediaSelectionSchemes.isEmpty)
    _ = item.effectiveMediaPresentationSettings(for: group)
    _ = item.selectedMediaPresentationSettings(for: group)
    item.select(AVMediaPresentationSetting(), for: group)
    precondition(AVPlayerItem.failedToPlayToEndTimeNotification.rawValue == "AVPlayerItemFailedToPlayToEndTimeNotification")
    precondition(AVPlayerItem.playbackStalledNotification.rawValue == "AVPlayerItemPlaybackStalledNotification")
    precondition(AVPlayerItem.newAccessLogEntryNotification.rawValue == "AVPlayerItemNewAccessLogEntryNotification")
    precondition(AVPlayerItem.newErrorLogEntryNotification.rawValue == "AVPlayerItemNewErrorLogEntryNotification")
    precondition(AVPlayerItem.timeJumpedNotification.rawValue == "AVPlayerItemTimeJumpedNotification")
    precondition(AVPlayerItem.mediaSelectionDidChangeNotification.rawValue == "AVPlayerItemMediaSelectionDidChangeNotification")
    precondition(AVPlayerItem.recommendedTimeOffsetFromLiveDidChangeNotification.rawValue == "AVPlayerItemRecommendedTimeOffsetFromLiveDidChangeNotification")
    precondition(AVPlayerItem.timeJumpedOriginatingParticipantKey == "AVPlayerItemTimeJumpedOriginatingParticipantKey")
    precondition(AVPlayerItemFailedToPlayToEndTimeErrorKey == "AVPlayerItemFailedToPlayToEndTimeErrorKey")
    precondition(Notification.Name.AVPlayerItemFailedToPlayToEndTime == AVPlayerItem.failedToPlayToEndTimeNotification)
    precondition(Notification.Name.AVPlayerItemTimeJumped == AVPlayerItem.timeJumpedNotification)
    precondition(Notification.Name.AVPlayerItemNewAccessLogEntry == AVPlayerItem.newAccessLogEntryNotification)
    precondition(Notification.Name.AVPlayerItemNewErrorLogEntry == AVPlayerItem.newErrorLogEntryNotification)
    precondition(AVPlayerItemSegment.SegmentType.primary.rawValue == 0)
    precondition(AVPlayerItemSegment.SegmentType.interstitial.rawValue == 1)
    let segment = AVPlayerItemSegment()
    precondition(segment.segmentType == .primary)
    precondition(segment.interstitialEvent == nil)
    precondition(segment.startDate == nil)
    precondition(segment.loadedTimeRanges.isEmpty)
    _ = segment.timeMapping
}

func testAVCaptureSessionControlsAndConnectionsFailClosed() {
    let session = AVCaptureSession()
    session.automaticallyConfiguresCaptureDeviceForWideColor = false
    precondition(!session.automaticallyConfiguresCaptureDeviceForWideColor)
    session.configuresApplicationAudioSessionForBluetoothHighQualityRecording = true
    precondition(session.configuresApplicationAudioSessionForBluetoothHighQualityRecording)
    session.automaticallyRunsDeferredStart = true
    precondition(session.automaticallyRunsDeferredStart)
    precondition(!session.supportsControls)
    precondition(session.maxControlsCount == 0)
    precondition(session.controls.isEmpty)
    precondition(!session.canAddControl(AVCaptureControl()))
    session.addControl(AVCaptureControl())
    session.removeControl(AVCaptureControl())
    session.setControlsDelegate(nil, queue: nil)
    precondition(session.controlsDelegate == nil)
    session.setDeferredStartDelegate(nil, deferredStartDelegateCallbackQueue: nil)
    precondition(session.deferredStartDelegate == nil)
    session.runDeferredStartWhenNeeded()
    precondition(!session.isManualDeferredStartSupported)
    precondition(session.masterClock == nil)
    precondition(session.synchronizationClock == nil)
    let connection = AVCaptureConnection()
    precondition(!session.canAddConnection(connection))
    session.addConnection(connection)
    session.removeConnection(connection)
    session.addInputWithNoConnections(AVCaptureInput())
    session.addOutputWithNoConnections(AVCaptureOutput())
    session.removeInput(AVCaptureInput())
    session.removeOutput(AVCaptureOutput())
    precondition(session.inputs.isEmpty)
    precondition(session.outputs.isEmpty)
    precondition(session.connections.isEmpty)
    precondition(Notification.Name.AVCaptureSessionDidStartRunning == AVCaptureSession.didStartRunningNotification)
    precondition(Notification.Name.AVCaptureSessionDidStopRunning == AVCaptureSession.didStopRunningNotification)
    precondition(Notification.Name.AVCaptureSessionRuntimeError == AVCaptureSession.runtimeErrorNotification)
    precondition(Notification.Name.AVCaptureSessionWasInterrupted == AVCaptureSession.wasInterruptedNotification)
    precondition(Notification.Name.AVCaptureSessionInterruptionEnded == AVCaptureSession.interruptionEndedNotification)
    precondition(AVCaptureSessionInterruptionSystemPressureStateKey == "AVCaptureSessionInterruptionSystemPressureStateKey")
}

func testAVCapturePhotoFailClosedRepresentations() {
    let photo = AVCapturePhoto()
    precondition(!photo.timestamp.isValid)
    precondition(!photo.isRawPhoto)
    precondition(photo.pixelBuffer == nil)
    precondition(photo.previewPixelBuffer == nil)
    precondition(photo.embeddedThumbnailPhotoFormat == nil)
    precondition(photo.depthData == nil)
    precondition(photo.portraitEffectsMatte == nil)
    precondition(photo.semanticSegmentationMatte(for: .skin) == nil)
    precondition(photo.metadata.isEmpty)
    precondition(photo.cameraCalibrationData == nil)
    precondition(photo.photoCount == 0)
    precondition(photo.sourceDeviceType == nil)
    precondition(photo.constantColorConfidenceMap == nil)
    precondition(photo.constantColorCenterWeightedMeanConfidenceLevel == 0)
    precondition(!photo.isConstantColorFallbackPhoto)
    precondition(photo.fileDataRepresentation() == nil)
    precondition(photo.cgImageRepresentation() == nil)
    precondition(photo.previewCGImageRepresentation() == nil)
    precondition(photo.sequenceCount == 0)
    precondition(photo.fileDataRepresentation(withReplacementMetadata: nil, replacementEmbeddedThumbnailPhotoFormat: nil, replacementEmbeddedThumbnailPixelBuffer: nil, replacementDepthData: nil) == nil)
    final class Customizer: NSObject, AVCapturePhotoFileDataRepresentationCustomizer {}
    precondition(photo.fileDataRepresentation(with: Customizer()) == nil)
}

func testAVCaptureVideoDataOutputStoredFailClosedRecommendations() {
    let output = AVCaptureVideoDataOutput()
    output.alwaysDiscardsLateVideoFrames = false
    output.automaticallyConfiguresOutputBufferDimensions = false
    output.deliversPreviewSizedOutputBuffers = true
    output.preparesCellularRadioForNetworkConnection = true
    output.preservesDynamicHDRMetadata = true
    output.videoSettings = [AVVideoCodecKey: AVVideoCodecType.h264.rawValue]
    precondition(!output.alwaysDiscardsLateVideoFrames)
    precondition(!output.automaticallyConfiguresOutputBufferDimensions)
    precondition(output.deliversPreviewSizedOutputBuffers)
    precondition(output.preparesCellularRadioForNetworkConnection)
    precondition(output.preservesDynamicHDRMetadata)
    precondition(output.videoSettings[AVVideoCodecKey] as? String == AVVideoCodecType.h264.rawValue)
    precondition(output.availableVideoPixelFormatTypes.isEmpty)
    precondition(output.availableVideoCodecTypes.isEmpty)
    precondition(output.recommendedVideoSettingsForAssetWriter(writingTo: .mp4) == nil)
    precondition(output.availableVideoCodecTypesForAssetWriter(writingTo: .mov).isEmpty)
    precondition(output.recommendedVideoSettings(forVideoCodecType: .h264, assetWriterOutputFileType: .mp4) == nil)
    precondition(output.recommendedVideoSettings(forVideoCodecType: .h264, assetWriterOutputFileType: .mp4, outputFileURL: nil) == nil)
    precondition(output.recommendedMovieMetadata(forVideoCodecType: .h264, assetWriterOutputFileType: .mp4) == nil)
    precondition(output.recommendedMediaTimeScaleForAssetWriter == 0)
    output.setSampleBufferDelegate(nil, queue: nil)
    precondition(output.sampleBufferDelegate == nil)
}

func testAVSampleCursorFailClosedWithoutMedia() {
    let cursor = AVSampleCursor()
    precondition(cursor.stepInDecodeOrder(byCount: 4) == 0)
    precondition(cursor.stepInPresentationOrder(byCount: 4) == 0)
    var pinned = false
    precondition(cursor.step(byDecodeTime: CMTime(seconds: 1, preferredTimescale: 1), wasPinned: &pinned) == .zero)
    precondition(pinned)
    pinned = false
    precondition(cursor.step(byPresentationTime: CMTime(seconds: 1, preferredTimescale: 1), wasPinned: &pinned) == .zero)
    precondition(pinned)
    precondition(!cursor.presentationTimeStamp.isValid)
    precondition(!cursor.decodeTimeStamp.isValid)
    precondition(!cursor.maySamplesWithEarlierDecodeTimeStampsHavePresentationTimeStamps(laterThan: cursor))
    precondition(!cursor.maySamplesWithLaterDecodeTimeStampsHavePresentationTimeStamps(earlierThan: cursor))
    precondition(cursor.currentSampleDuration == .zero)
    _ = cursor.copyCurrentSampleFormatDescription()
    precondition(cursor.currentSampleDependencyAttachments == nil)
    precondition(cursor.currentChunkStorageURL == nil)
    precondition(cursor.currentSampleIndexInChunk == 0)
    precondition(cursor.samplesRequiredForDecoderRefresh == 0)

    let sync = AVSampleCursorSyncInfo(sampleIsFullSync: true, sampleIsPartialSync: false, sampleIsDroppable: true)
    precondition(sync.sampleIsFullSync)
    precondition(!sync.sampleIsPartialSync)
    precondition(sync.sampleIsDroppable)
    let dep = AVSampleCursorDependencyInfo(
        sampleIndicatesWhetherItHasDependentSamples: true,
        sampleHasDependentSamples: true,
        sampleIndicatesWhetherItDependsOnOthers: true,
        sampleDependsOnOthers: false,
        sampleIndicatesWhetherItHasRedundantCoding: true,
        sampleHasRedundantCoding: false
    )
    precondition(dep.sampleIndicatesWhetherItHasDependentSamples)
    precondition(dep.sampleHasDependentSamples)
    precondition(dep.sampleIndicatesWhetherItDependsOnOthers)
    precondition(!dep.sampleDependsOnOthers)
    precondition(dep.sampleIndicatesWhetherItHasRedundantCoding)
    precondition(!dep.sampleHasRedundantCoding)
    let chunk = AVSampleCursorChunkInfo(
        chunkSampleCount: 12,
        chunkHasUniformSampleSizes: true,
        chunkHasUniformSampleDurations: false,
        chunkHasUniformFormatDescriptions: true
    )
    precondition(chunk.chunkSampleCount == 12)
    precondition(chunk.chunkHasUniformSampleSizes)
    precondition(!chunk.chunkHasUniformSampleDurations)
    precondition(chunk.chunkHasUniformFormatDescriptions)
    let range = AVSampleCursorStorageRange(offset: 8, length: 16)
    precondition(range.offset == 8)
    precondition(range.length == 16)
    let audio = AVSampleCursorAudioDependencyInfo(audioSampleIsIndependentlyDecodable: true, audioSamplePacketRefreshCount: 2)
    precondition(audio.audioSampleIsIndependentlyDecodable)
    precondition(audio.audioSamplePacketRefreshCount == 2)
    precondition(cursor.currentSampleSyncInfo.sampleIsFullSync == false)
    precondition(cursor.currentChunkInfo.chunkSampleCount == 0)
    precondition(cursor.currentChunkStorageRange.length == 0)
    precondition(cursor.currentSampleStorageRange.offset == 0)
    precondition(cursor.currentSampleAudioDependencyInfo.audioSamplePacketRefreshCount == 0)
}

func testAVVideoCompositionLayerInstructionConfigurationRamps() {
    var configuration = AVVideoCompositionLayerInstruction.Configuration(trackID: 4)
    configuration.setOpacity(0.25, at: .zero)
    configuration.setTransform(.identity, at: .zero)
    configuration.setCropRectangle(CGRect(x: 0, y: 0, width: 10, height: 10), at: .zero)
    let opacityRamp = AVVideoCompositionLayerInstruction.OpacityRamp(
        timeRange: CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 1)),
        start: 0,
        end: 1
    )
    configuration.addOpacityRamp(opacityRamp)
    let transformRamp = AVVideoCompositionLayerInstruction.TransformRamp(
        timeRange: opacityRamp.timeRange,
        start: .identity,
        end: .identity
    )
    configuration.addTransformRamp(transformRamp)
    let cropRamp = AVVideoCompositionLayerInstruction.CropRectangleRamp(
        timeRange: opacityRamp.timeRange,
        start: CGRect(x: 0, y: 0, width: 1, height: 1),
        end: CGRect(x: 0, y: 0, width: 2, height: 2)
    )
    configuration.addCropRectangleRamp(cropRamp)
    precondition(configuration.opacityRamp(at: .zero) == Optional(opacityRamp))
    precondition(configuration.transformRamp(at: .zero) == Optional(transformRamp))
    precondition(configuration.cropRectangleRamp(at: .zero) == Optional(cropRamp))

    let instruction = AVVideoCompositionLayerInstruction(configuration: configuration)
    precondition(instruction.trackID == 4)
    var startOpacity: Float = 0
    var endOpacity: Float = 0
    var range = CMTimeRange.invalid
    precondition(instruction.getOpacityRamp(for: .zero, startOpacity: &startOpacity, endOpacity: &endOpacity, timeRange: &range))
    precondition(startOpacity == 0)
    precondition(endOpacity == 1)
    var startTransform = CGAffineTransform.identity
    var endTransform = CGAffineTransform.identity
    precondition(instruction.getTransformRamp(for: .zero, start: &startTransform, end: &endTransform, timeRange: &range))
    var startCrop = CGRect.zero
    var endCrop = CGRect.zero
    precondition(instruction.getCropRectangleRamp(for: .zero, startCropRectangle: &startCrop, endCropRectangle: &endCrop, timeRange: &range))
    precondition(endCrop.width == 2)
    precondition(instruction.opacityRamp(at: .zero) == Optional(opacityRamp))
    precondition(instruction.transformRamp(at: .zero) == Optional(transformRamp))
    precondition(instruction.cropRectangleRamp(at: .zero) == Optional(cropRamp))

    let fromTrack = AVVideoCompositionLayerInstruction.Configuration(assetTrack: AVAssetTrack())
    precondition(fromTrack.trackID == 0)

    let composition = AVMutableVideoComposition()
    composition.sourceSampleDataTrackIDs = [1, 2]
    composition.spatialVideoConfigurations = []
    composition.outputBufferDescription = nil
    composition.colorPrimaries = "ITU_R_709_2"
    composition.colorTransferFunction = "ITU_R_709_2"
    composition.colorYCbCrMatrix = "ITU_R_709_2"
    composition.perFrameHDRDisplayMetadataPolicy = .generate
    precondition(composition.sourceSampleDataTrackIDs == [1, 2])
    precondition(composition.perFrameHDRDisplayMetadataPolicy == .generate)
    precondition(composition.animationTool == nil)
    precondition(composition.customVideoCompositorClass == nil)
    _ = AVVideoComposition(propertiesOf: AVAsset())
    _ = AVVideoComposition(asset: AVAsset(), applyingCIFiltersWithHandler: { _ in })
    precondition(opacityRamp != AVVideoCompositionLayerInstruction.OpacityRamp())
    precondition(transformRamp != AVVideoCompositionLayerInstruction.TransformRamp())
    precondition(cropRamp != AVVideoCompositionLayerInstruction.CropRectangleRamp())
    precondition(AVVideoComposition.PerFrameHDRDisplayMetadataPolicy.propagate.rawValue == "propagate")
    precondition(AVVideoComposition.PerFrameHDRDisplayMetadataPolicy.generate.rawValue == "generate")
    let built = AVVideoComposition(
        configuration: AVVideoComposition.Configuration(
            frameDuration: CMTime(value: 1, timescale: 30),
            renderSize: CGSize(width: 1280, height: 720),
            sourceSampleDataTrackIDs: [9]
        )
    )
    precondition(built.sourceSampleDataTrackIDs == [9])
    precondition(built.renderSize.width == 1280)
    precondition(!built.isValid(for: nil, timeRange: .zero, validationDelegate: nil))
    precondition(!built.isValid(for: [], assetDuration: .zero, timeRange: .zero, validationDelegate: nil))
    let hint = AVVideoCompositionRenderHint()
    precondition(hint.startCompositionTime == .zero)
    precondition(hint.endCompositionTime == .zero)
}
