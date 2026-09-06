import CoreFoundation
import CoreMedia
import Foundation

func testCMSampleBufferDataReadinessStateMachine() {
    let pending = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [0],
        dataReady: false
    )
    precondition(pending.dataReadiness == .notReady)
    try! pending.setDataReadiness(.ready)
    precondition(pending.dataReadiness == .ready)
    try! pending.setDataReadiness(.notReady)
    precondition(pending.dataReadiness == .notReady)
    try! pending.setDataReadiness(.failed(kCMSampleBufferError_DataFailed))
    if case .failed(let status) = pending.dataReadiness {
        precondition(status == kCMSampleBufferError_DataFailed)
    } else {
        preconditionFailure("expected failed readiness")
    }
    var hasher = Hasher()
    CMSampleBuffer.DataReadiness.ready.hash(into: &hasher)
    _ = hasher.finalize()
    _ = CMSampleBuffer.DataReadiness.notReady.hashValue
    precondition(CMSampleBuffer.DataReadiness.ready != .notReady)
}

func testCMSampleBufferTrackDataReadinessMethod() {
    let ready = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1],
        dataReady: true
    )
    let follower = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: [],
        dataReady: false
    )
    try! follower.trackDataReadiness(ready)
    precondition(follower.dataIsReady)
}

func testCMSampleBufferContentTypeAndNotificationKey() {
    let marker = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: []
    )
    precondition(marker.contentType == .markerOnly)
    let withData = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1]
    )
    precondition(withData.contentType == .dataBuffer)
    precondition(CMSampleBuffer.ContentType.dataBuffer != .pixelBuffer)
    precondition(CMSampleBuffer.ContentType.taggedBuffers != .sampleReference)
    var hasher = Hasher()
    CMSampleBuffer.ContentType.markerOnly.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        CFEqual(CMSampleBuffer.NotificationKey.status.rawValue, kCMSampleBufferNotificationParameter_OSStatus)
    )
    precondition(CMSampleBuffer.NotificationKey(rawValue: kCMSampleBufferNotificationParameter_OSStatus) == .status)
}

func testCMSampleBufferSizeAndTimingPerSample() {
    let uniform: CMSampleBuffer.SizePerSample = .uniform(8)
    let distinct: CMSampleBuffer.SizePerSample = .distinct([2, 4, 6])
    let literal: CMSampleBuffer.SizePerSample = [8]
    precondition(uniform == .uniform(8))
    precondition(distinct != uniform)
    precondition(literal == .uniform(8))
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: .zero,
        decodeTimeStamp: .invalid
    )
    let sequential = CMSampleBuffer.TimingPerSample.sequential(startingAt: timing)
    let fromFactory = CMSampleBuffer.TimingPerSample.sequential(
        presentationTimeOfFirstSample: .zero,
        uniformDuration: CMTime(value: 1, timescale: 30)
    )
    precondition(sequential == .sequential(startingAt: timing))
    if case .sequential(let start) = fromFactory {
        precondition(start.duration.timescale == 30)
    } else {
        preconditionFailure("expected sequential timing")
    }
    let distinctTiming: CMSampleBuffer.TimingPerSample = [timing, timing]
    if case .distinct(let values) = distinctTiming {
        precondition(values.count == 2)
    } else {
        preconditionFailure("expected distinct timings")
    }
}

func testCMSampleBufferSamplePropertiesAndAttachments() {
    var attachments = CMSampleBuffer.SampleAttachments()
    attachments.doNotDisplay = true
    attachments.displayImmediately = true
    attachments.isNotSync = true
    attachments.isPartialSync = true
    attachments.dependsOnOthers = true
    attachments.isDependedOnByOthers = false
    attachments.hasRedundantCoding = true
    attachments.earlierDisplayTimesAllowed = true
    attachments.hevcTemporalSubLayerAccess = true
    attachments.hevcStepwiseTemporalSubLayerAccess = true
    attachments.hevcSyncSampleNALUnitType = 19
    attachments.audioIndependentSampleDecoderRefreshCount = 2
    attachments.hdr10PlusPerFrameData = Data([1, 2])
    attachments.cryptorSubsampleAuxiliaryData = Data([3])
    let info = CMSampleBuffer.HEVCTemporalInfo(
        temporalLayerID: 1,
        profileSpace: 0,
        tierFlag: 0,
        profileIndex: 1,
        profileCompatibilityFlags: Data([0]),
        constraintIndicatorFlags: nil,
        levelIndex: 4
    )
    attachments.hevcTemporalInfo = info
    attachments["raw"] = "value"
    attachments[rawAttachment: "extra"] = 7
    precondition(attachments[rawAttachment: "extra"] as? Int == 7)
    precondition(attachments.doNotDisplay)
    precondition(attachments.displayImmediately)
    precondition(attachments.isNotSync)
    precondition(attachments.hevcSyncSampleNALUnitType == 19)
    precondition(attachments.hevcTemporalInfo == info)
    precondition(attachments.dictionaryRepresentation["raw"] as? String == "value")
    let properties = CMSampleBuffer.SampleProperties(
        size: 12,
        timing: CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid),
        attachments: attachments
    )
    precondition(properties.size == 12)
    var collection = CMSampleBuffer.SamplePropertiesCollection(
        sampleCount: 2,
        sizes: .uniform(8),
        timings: .sequential(startingAt: properties.timing),
        attachments: [attachments, attachments]
    )
    precondition(collection.count == 2)
    precondition(collection.startIndex == 0)
    precondition(collection.endIndex == 2)
    precondition(collection[0].size == 8)
    collection[1] = properties
    precondition(collection.sizes != nil)
    precondition(collection.timings != nil)
    precondition(collection.attachments?.count == 2)
    precondition(collection == collection)
    precondition(properties == properties)
    precondition(attachments == attachments)
    let fromArray: CMSampleBuffer.SamplePropertiesCollection = [properties]
    precondition(fromArray.count == 1)
    let empty = CMSampleBuffer.SamplePropertiesCollection()
    precondition(empty.count == 0)
}

func testCMSampleBufferPerSampleAttachmentsDictionary() {
    var dictionary = CMSampleBuffer.PerSampleAttachmentsDictionary()
    dictionary[.doNotDisplay] = true
    dictionary[.notSync] = true
    dictionary[.displayImmediately] = false
    dictionary[.partialSync] = true
    dictionary[.dependsOnOthers] = true
    dictionary[.hasRedundantCoding] = false
    dictionary[.isDependedOnByOthers] = false
    dictionary[.hevcTemporalLevelInfo] = 1
    dictionary[.earlierDisplayTimesAllowed] = true
    dictionary[.hevcTemporalSubLayerAccess] = true
    dictionary[.hevcStepwiseTemporalSubLayerAccess] = false
    dictionary[.hevcSyncSampleNALUnitType] = 5
    dictionary[.audioIndependentSampleDecoderRefreshCount] = 3
    precondition(dictionary[.doNotDisplay] as? Bool == true)
    precondition(dictionary[.notSync] as? Bool == true)
    var seen = 0
    for (key, _) in dictionary {
        _ = key.rawValue
        seen += 1
    }
    precondition(seen >= 2)
    var array = CMSampleBuffer.SampleAttachmentsArray(count: 2)
    precondition(array.startIndex == 0)
    precondition(array.endIndex == 2)
    precondition(array.index(after: 0) == 1)
    array[0] = dictionary
    precondition(array[0][.doNotDisplay] as? Bool == true)
}

func testCMSampleBufferTimingArrayAndRangeCopy() {
    let t0 = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 10),
        presentationTimeStamp: .zero,
        decodeTimeStamp: .invalid
    )
    let t1 = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 10),
        presentationTimeStamp: CMTime(value: 1, timescale: 10),
        decodeTimeStamp: .invalid
    )
    let timings = [t0, t1]
    let sizes = [4, 4]
    var created: CMSampleBuffer?
    precondition(
        timings.withUnsafeBufferPointer { timingPtr in
            sizes.withUnsafeBufferPointer { sizePtr in
                CMSampleBufferCreateReady(
                    allocator: nil,
                    dataBuffer: CMBlockBuffer(data: Data([1, 2, 3, 4, 5, 6, 7, 8])),
                    formatDescription: nil,
                    sampleCount: 2,
                    sampleTimingEntryCount: 2,
                    sampleTimingArray: timingPtr.baseAddress,
                    sampleSizeEntryCount: 2,
                    sampleSizeArray: sizePtr.baseAddress,
                    sampleBufferOut: &created
                )
            }
        } == 0
    )
    let sample = created!
    var needed: CMItemCount = 0
    precondition(
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &needed) == 0
    )
    precondition(needed == 2)
    var recovered = [CMSampleTimingInfo](repeating: .invalid, count: 2)
    precondition(
        recovered.withUnsafeMutableBufferPointer { dest in
            CMSampleBufferGetSampleTimingInfoArray(
                sample,
                entryCount: 2,
                arrayToFill: dest.baseAddress,
                entriesNeededOut: &needed
            )
        } == 0
    )
    precondition(recovered[1].presentationTimeStamp.value == 1)
    var sliced: CMSampleBuffer?
    precondition(
        CMSampleBufferCopySampleBufferForRange(
            allocator: nil,
            sampleBuffer: sample,
            sampleRange: CFRange(location: 1, length: 1),
            sampleBufferOut: &sliced
        ) == 0
    )
    precondition(sliced!.numSamples == 1)
    precondition(try! sliced!.sampleTimingInfo(at: 0).presentationTimeStamp.value == 1)
    var retimed: CMSampleBuffer?
    let newTiming = CMSampleTimingInfo(
        duration: CMTime(value: 2, timescale: 10),
        presentationTimeStamp: CMTime(value: 9, timescale: 10),
        decodeTimeStamp: .invalid
    )
    let newTimings = [newTiming]
    precondition(
        newTimings.withUnsafeBufferPointer { ptr in
            CMSampleBufferCreateCopyWithNewTiming(
                allocator: nil,
                sampleBuffer: sample,
                sampleTimingEntryCount: 1,
                sampleTimingArray: ptr.baseAddress,
                sampleBufferOut: &retimed
            )
        } == 0
    )
    precondition(try! retimed!.sampleTimingInfo(at: 0).presentationTimeStamp.value == 9)
    precondition(try! sample.sampleSize(at: 0) == 4)
    precondition(sample.totalSampleSize == 8)
    precondition(sample.outputDuration.timescale == 10 || sample.outputDuration.isValid)
    _ = sample.outputPresentationTimeStamp
    try! sample.setOutputPresentationTimeStamp(CMTime(value: 4, timescale: 10))
    precondition(sample.outputPresentationTimeStamp.value == 4)
    precondition(CMSampleBuffer.typeID == CMSampleBufferGetTypeID())
    let errors: [NSError] = [
        CMSampleBuffer.Error.alreadyHasDataBuffer,
        CMSampleBuffer.Error.invalidMediaTypeForOperation,
        CMSampleBuffer.Error.invalidMediaFormat,
        CMSampleBuffer.Error.dataFailed,
        CMSampleBuffer.Error.dataCanceled,
        CMSampleBuffer.Error.arrayTooSmall,
        CMSampleBuffer.Error.bufferNotReady,
        CMSampleBuffer.Error.cannotSubdivide,
        CMSampleBuffer.Error.invalidEntryCount,
        CMSampleBuffer.Error.invalidSampleData,
        CMSampleBuffer.Error.sampleIndexOutOfRange,
        CMSampleBuffer.Error.bufferHasNoSampleSizes,
        CMSampleBuffer.Error.sampleTimingInfoInvalid,
        CMSampleBuffer.Error.bufferHasNoSampleTimingInfo,
    ]
    for error in errors {
        precondition(error.code != 0)
    }
    precondition(CMSampleBuffer.Error.sampleIndexOutOfRange.code == -12734)
    precondition(CMSampleBuffer.Error.bufferHasNoSampleTimingInfo.code == -12736)
    precondition(CMSampleBuffer.Flags(rawValue: 1).rawValue == 1)
    precondition(CMSampleBuffer.Flags.audioBufferListAssure16ByteAlignment.rawValue == 1)
}
