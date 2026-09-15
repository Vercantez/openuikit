import CoreFoundation
import CoreMedia
import Foundation

private func cmSyncProbe<S: CMSyncProtocol>(_ sync: S, relativeTo other: S) {
    let now = sync.time
    precondition(now.isValid)
    let moved = sync.convertTime(now, to: other)
    precondition(moved.isValid)
    precondition(sync.rate(relativeTo: other) == 1)
    let anchored = try! sync.rateAndAnchorTime(relativeTo: other)
    precondition(anchored.anchorTime.isValid)
    precondition(anchored.relativeAnchorTime.isValid)
    _ = sync.mightDrift(relativeTo: other)
    precondition(CMSyncGetTime(sync).isValid)
}

private func cmSyncSample() -> CMSampleBuffer {
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 1),
        presentationTimeStamp: CMTime(value: 0, timescale: 1),
        decodeTimeStamp: .invalid
    )
    return try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [timing],
        sampleSizes: [1],
        dataReady: true
    )
}

func testCMSyncProtocolOverlayMembers() {
    let clock = CMClockGetHostTimeClock()
    let otherClock = CMClock(referencing: clock)
    cmSyncProbe(clock, relativeTo: clock)
    cmSyncProbe(otherClock, relativeTo: clock)
    var timebase: CMTimebase?
    precondition(
        CMTimebaseCreateWithSourceClock(allocator: nil, sourceClock: clock, timebaseOut: &timebase) == 0
    )
    let tb = timebase!
    precondition(CMTimebaseSetRate(tb, rate: 1.0) == 0)
    cmSyncProbe(tb, relativeTo: tb)
    let anys: [any CMSyncProtocol] = [clock, tb]
    for item in anys {
        precondition(item.time.isValid)
    }
    precondition(CMSync.Error.missingRequiredParameter.code == Int(kCMSyncError_MissingRequiredParameter))
    precondition(CMSync.Error.invalidParameter.code == Int(kCMSyncError_InvalidParameter))
    precondition(CMSync.Error.allocationFailed.code == Int(kCMSyncError_AllocationFailed))
    precondition(CMSync.Error.rateMustBeNonZero.code == Int(kCMSyncError_RateMustBeNonZero))
    precondition(clock.time.isNumeric)
    precondition(clock.mightDrift(relativeTo: clock) == false)
    precondition(clock.mightDrift(relativeTo: otherClock) == true)
    precondition(clock.convertTime(clock.time, to: otherClock).isNumeric)
    precondition(clock.rate(relativeTo: clock) == 1)
    let anchored = try! clock.rateAndAnchorTime(relativeTo: clock)
    precondition(anchored.anchorTime.isNumeric)
    precondition(anchored.relativeAnchorTime.isNumeric)
    let pair = try! clock.anchorTime()
    precondition(pair.anchorTime.isNumeric)
    precondition(pair.referenceTime.isNumeric)
    otherClock.invalidate()
    precondition(CMClock.Error.invalidParameter.code == Int(kCMClockError_InvalidParameter))
    precondition(CMClock.Error.unsupportedOperation.code == Int(kCMClockError_UnsupportedOperation))
    precondition(CMClock.Error.missingRequiredParameter.code == Int(kCMClockError_MissingRequiredParameter))
    precondition(
        CMTimebaseSetAnchorTime(
            tb,
            timebaseTime: CMTime(value: 3, timescale: 1),
            immediateMasterTime: CMTime(value: 1, timescale: 1)
        ) == 0
    )
    precondition(
        CMTimebaseSetRateAndAnchorTime(
            tb,
            rate: 1.0,
            anchorTime: CMTime(value: 3, timescale: 1),
            immediateMasterTime: CMTime(value: 1, timescale: 1)
        ) == 0
    )
    precondition(tb.rate == 1.0)
}

func testCMHostTypeAliasAndInitTrampolines() {
    let clock = CMClockGetHostTimeClock()
    let clockCopy = CMClock(referencing: clock)
    precondition(clockCopy.time.isNumeric)
    let tbCopy = CMTimebase(referencing: CMTimebase(sourceClock: clock))
    precondition(tbCopy.rate == 0)
    let bbCopy = CMBlockBuffer(referencing: CMBlockBuffer(length: 4))
    precondition(bbCopy.dataLength == 4)
    let t1 = CMTimebase(sourceClock: clock)
    let t2 = CMTimebase(masterClock: clock)
    let t3 = CMTimebase(sourceTimebase: t1)
    let t4 = CMTimebase(masterTimebase: t1)
    precondition(t2.masterClock === clock)
    precondition(t3.sourceTimebase === t1)
    precondition(t4.masterTimebase === t1)
    let q = CMBufferQueue(capacity: 4, handlers: .unsortedSampleBuffers)
    precondition(q.bufferCount == 0)
    let sq = try! CMSimpleQueue(capacity: 2)
    precondition(sq.capacity == 2)
    let _: CMBufferQueue.T = q
    let _: CMSimpleQueue.T = sq
    var token: CMBufferQueueTriggerToken?
    precondition(
        CMBufferQueueInstallTrigger(
            q,
            callback: nil,
            refcon: nil,
            condition: kCMBufferQueueTrigger_WhenDataBecomesReady,
            time: .invalid,
            triggerTokenOut: &token
        ) == 0
    )
    precondition(token != nil)
    let _: CMBufferQueue.TriggerToken = token!
    let sample = cmSyncSample()
    let bearer: CMAttachmentBearer = sample
    precondition((bearer as AnyObject) === sample)
    let buf: CMBuffer = sample
    precondition((buf as AnyObject) === sample)
    let cot: CMClockOrTimebase = clock
    precondition((cot as AnyObject) === clock)
    let fmt = try! CMFormatDescription(
        mediaType: .video,
        mediaSubType: CMFormatDescription.MediaSubType(rawValue: kCMVideoCodecType_H264)
    )
    let _: CMAudioFormatDescription = fmt
    let _: CMVideoFormatDescription = fmt
    let _: CMMuxedFormatDescription = fmt
    let _: CMClosedCaptionFormatDescription = fmt
    let _: CMTextFormatDescription = fmt
    let _: CMTimeCodeFormatDescription = fmt
    let _: CMMetadataFormatDescription = fmt
    let media: CMMediaType = kCMMediaType_Video
    precondition(media == kCMMediaType_Video)
    let audioCodec: CMAudioCodecType = kCMAudioCodecType_AAC_LCProtected
    precondition(audioCodec == kCMAudioCodecType_AAC_LCProtected)
    let ccType: CMClosedCaptionFormatType = kCMClosedCaptionFormatType_CEA608
    precondition(ccType == kCMClosedCaptionFormatType_CEA608)
    let muxed: CMMuxedStreamType = kCMMuxedStreamType_DV
    precondition(muxed == kCMMuxedStreamType_DV)
    let subtitle: CMSubtitleFormatType = kCMSubtitleFormatType_WebVTT
    precondition(subtitle == kCMSubtitleFormatType_WebVTT)
    let metadata: CMMetadataFormatType = kCMMetadataFormatType_ID3
    precondition(metadata == kCMMetadataFormatType_ID3)
    let text: CMTextFormatType = kCMTextFormatType_QTText
    precondition(text == kCMTextFormatType_QTText)
    let timecode: CMTimeCodeFormatType = kCMTimeCodeFormatType_TimeCode32
    precondition(timecode == kCMTimeCodeFormatType_TimeCode32)
    let pixel: CMPixelFormatType = kCMPixelFormat_32BGRA
    precondition(pixel == kCMPixelFormat_32BGRA)
    let track: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    precondition(track == 0)
    let flags: CMBlockBufferFlags = kCMBlockBufferAssureMemoryNowFlag
    precondition(flags == kCMBlockBufferAssureMemoryNowFlag)
    let index: CMItemIndex = 0
    precondition(index == 0)
    let baseVersion: CMBaseClassVersion = 0
    precondition(baseVersion == 0)
    let structVersion: CMStructVersion = 0
    precondition(structVersion == 0)
}
