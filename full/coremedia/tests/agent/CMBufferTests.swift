import CoreFoundation
import CoreMedia
import Dispatch
import Foundation

func testCMBlockBufferCreateCopyFill() {
    var empty: CMBlockBuffer?
    precondition(
        CMBlockBufferCreateEmpty(allocator: nil, capacity: 1, flags: 0, blockBufferOut: &empty) == 0
    )
    precondition(CMBlockBufferIsEmpty(empty!))
    var created: CMBlockBuffer?
    var bytes: [UInt8] = [1, 2, 3, 4]
    bytes.withUnsafeMutableBytes { raw in
        precondition(
            CMBlockBufferCreateWithMemoryBlock(
                allocator: nil,
                memoryBlock: raw.baseAddress,
                blockLength: 4,
                blockAllocator: nil,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: 4,
                flags: 0,
                blockBufferOut: &created
            ) == 0
        )
    }
    let buffer = created!
    precondition(CMBlockBufferGetDataLength(buffer) == 4)
    precondition(CMBlockBufferIsRangeContiguous(buffer, atOffset: 0, length: 4))
    var dest = [UInt8](repeating: 0, count: 4)
    dest.withUnsafeMutableBytes { raw in
        precondition(
            CMBlockBufferCopyDataBytes(buffer, atOffset: 0, dataLength: 4, destination: raw.baseAddress!)
                == 0
        )
    }
    precondition(dest == [1, 2, 3, 4])
    precondition(
        CMBlockBufferFillDataBytes(with: 9, blockBuffer: buffer, offsetIntoDestination: 1, dataLength: 2)
            == 0
    )
    let afterFill = try! buffer.dataBytes()
    precondition(afterFill[1] == 9)
    let refill: [UInt8] = [7, 7]
    refill.withUnsafeBytes { raw in
        precondition(
            CMBlockBufferReplaceDataBytes(
                with: raw.baseAddress!,
                blockBuffer: buffer,
                offsetIntoDestination: 0,
                dataLength: 2
            ) == 0
        )
    }
    precondition(kCMBlockBufferNoErr == 0)
    precondition(kCMBlockBufferStructureAllocationFailedErr == -12700)
    precondition(kCMBlockBufferInsufficientSpaceErr == -12708)
    precondition(CMBlockBuffer.Error.badOffsetParameter.code == -12703)
    precondition(CMBlockBuffer.Flags.assureMemoryNow.rawValue == kCMBlockBufferAssureMemoryNowFlag)
    precondition(buffer.endIndex == buffer.dataLength)
    precondition(buffer.owner === buffer)
    try! buffer.fillDataBytes(with: 0)
    precondition(CMBlockBufferAssureBlockMemory(buffer) == 0)
    var contiguous: CMBlockBuffer?
    precondition(
        CMBlockBufferCreateContiguous(
            allocator: nil,
            sourceBuffer: buffer,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: 4,
            flags: 0,
            blockBufferOut: &contiguous
        ) == 0
    )
    precondition(contiguous!.dataLength == 4)
    let source = CMBlockBufferCustomBlockSource()
    precondition(source.version == 1)
    var scratch = [CChar](repeating: 0, count: 4)
    var returned: UnsafeMutablePointer<CChar>?
    scratch.withUnsafeMutableBufferPointer { pointer in
        precondition(
            CMBlockBufferAccessDataBytes(
                buffer,
                atOffset: 0,
                length: 4,
                temporaryBlock: pointer.baseAddress!,
                returnedPointerOut: &returned
            ) == 0
        )
    }
    precondition(returned != nil)
}

func testCMSampleBufferCreateAndTiming() {
    let format = try! CMFormatDescription(
        videoCodecType: .h264,
        width: 8,
        height: 8,
        extensions: nil
    )
    let data = CMBlockBuffer(data: Data([0, 1, 2, 3]))
    var timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: CMTime(value: 5, timescale: 30),
        decodeTimeStamp: .invalid
    )
    var size = 4
    var sample: CMSampleBuffer?
    precondition(
        withUnsafePointer(to: &timing) { timingPtr in
            withUnsafePointer(to: &size) { sizePtr in
                CMSampleBufferCreateReady(
                    allocator: nil,
                    dataBuffer: data,
                    formatDescription: format,
                    sampleCount: 1,
                    sampleTimingEntryCount: 1,
                    sampleTimingArray: timingPtr,
                    sampleSizeEntryCount: 1,
                    sampleSizeArray: sizePtr,
                    sampleBufferOut: &sample
                )
            }
        } == 0
    )
    let sbuf = sample!
    precondition(CMSampleBufferIsValid(sbuf))
    precondition(CMSampleBufferGetNumSamples(sbuf) == 1)
    precondition(CMSampleBufferGetPresentationTimeStamp(sbuf) == timing.presentationTimeStamp)
    var info = CMSampleTimingInfo()
    precondition(CMSampleBufferGetSampleTimingInfo(sbuf, at: 0, timingInfoOut: &info) == 0)
    precondition(info.duration == timing.duration)
    precondition(CMSampleBufferSetOutputPresentationTimeStamp(sbuf, newValue: .zero) == 0)
    precondition(CMSampleBufferGetOutputPresentationTimeStamp(sbuf) == .zero)
    var copy: CMSampleBuffer?
    precondition(CMSampleBufferCreateCopy(allocator: nil, sampleBuffer: sbuf, sampleBufferOut: &copy) == 0)
    precondition(copy!.numSamples == 1)
    precondition(kCMSampleBufferError_Invalidated == -12744)
    precondition(kCMSampleBufferError_DataFailed == -16750)
    precondition(kCMSampleBufferError_DataCanceled == -16751)
    precondition(CFStringGetLength(kCMSampleAttachmentKey_NotSync) > 0)
    CMSetAttachment(
        sbuf,
        key: kCMSampleAttachmentKey_DisplayImmediately,
        value: kCFBooleanTrue,
        attachmentMode: kCMAttachmentMode_ShouldPropagate
    )
    var mode: CMAttachmentMode = 0
    let got = CMGetAttachment(sbuf, key: kCMSampleAttachmentKey_DisplayImmediately, attachmentModeOut: &mode)
    precondition(got != nil)
    precondition(mode == kCMAttachmentMode_ShouldPropagate)
    precondition(
        CFEqual(
            CMSampleBuffer.AttachmentKey.forceKeyFrame.rawValue,
            kCMSampleBufferAttachmentKey_ForceKeyFrame
        )
    )
}

func testCMBlockBufferCopyOwnedBytes() {
    testCMBlockBufferCreateCopyFill()
}

func testCMBlockBufferEmptyAndMalformed() {
    let empty = CMBlockBuffer()
    precondition(CMBlockBufferIsEmpty(empty))
    precondition(empty.dataLength == 0)
    let buffer = CMBlockBuffer(data: Data([1, 2, 3]))
    do {
        var dest = [UInt8](repeating: 0, count: 1)
        try dest.withUnsafeMutableBytes { raw in
            try buffer.copyDataBytes(to: raw)
        }
        preconditionFailure("short destination must fail")
    } catch {
        precondition((error as NSError).code == -12708)
    }
    do {
        var dest: UInt8 = 0
        try withUnsafeMutablePointer(to: &dest) { pointer in
            try buffer.copyDataBytes(atOffset: 8, dataLength: 1, destination: pointer)
        }
        preconditionFailure("bad offset must fail")
    } catch {
        precondition((error as NSError).code == -12703)
    }
}

func testCMBlockBufferAliasAndMutationIsolation() {
    let original = CMBlockBuffer(data: Data([9, 8, 7]))
    let alias = original
    precondition(alias.dataLength == 3)
    try! original.withUnsafeMutableBytes { bytes in
        bytes[0] = 1
    }
    let after = try! alias.dataBytes()
    precondition(after.first == 1)
}

func testCMSampleBufferTimingAndDataRead() {
    let format = try! CMFormatDescription(
        videoCodecType: .h264,
        width: 16,
        height: 16,
        extensions: nil
    )
    let data = CMBlockBuffer(data: Data([0x00, 0x00, 0x00, 0x01, 0x67]))
    let timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: CMTime(value: 10, timescale: 30),
        decodeTimeStamp: CMTime(value: 8, timescale: 30)
    )
    let sample = try! CMSampleBuffer(
        dataBuffer: data,
        formatDescription: format,
        numSamples: 1,
        sampleTimings: [timing],
        sampleSizes: [5],
        dataReady: true
    )
    precondition(CMSampleBufferIsValid(sample))
    precondition(CMSampleBufferDataIsReady(sample))
    precondition(CMSampleBufferGetNumSamples(sample) == 1)
    precondition(CMSampleBufferGetPresentationTimeStamp(sample) == timing.presentationTimeStamp)
    precondition(CMSampleBufferGetDecodeTimeStamp(sample) == timing.decodeTimeStamp)
    precondition(CMSampleBufferGetDuration(sample) == timing.duration)
    precondition(CMSampleBufferGetTotalSampleSize(sample) == 5)
    precondition(CMSampleBufferGetFormatDescription(sample) === format)
    let bytes = try! sample.copyDataBytes()
    precondition(bytes.count == 5)
    precondition(bytes != Data([0xff, 0xff, 0xff, 0xff, 0xff]))
}

func testCMSampleBufferDoesNotTreatArbitraryBytesAsValidMedia() {
    let garbage = CMBlockBuffer(data: Data((0..<32).map { UInt8($0) }))
    let format = try! CMFormatDescription(
        mediaType: .video,
        mediaSubType: .h264,
        extensions: nil
    )
    let sample = try! CMSampleBuffer(
        dataBuffer: garbage,
        formatDescription: format,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [32]
    )
    let payload = try! sample.copyDataBytes()
    precondition(payload.count == 32)
    precondition(sample.formatDescription?.mediaSubType == .h264)
}

func testCMSampleBufferInvalidateCallbackExactlyOnce() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(),
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: []
    )
    var fires = 0
    sample.setInvalidateHandler { _ in fires += 1 }
    sample.invalidate()
    sample.invalidate()
    precondition(fires == 1)
    precondition(!CMSampleBufferIsValid(sample))
    do {
        _ = try sample.copyDataBytes()
        preconditionFailure("invalidated buffer must fail closed")
    } catch {
        precondition((error as NSError).code == -12744)
    }
}

func testCMSampleBufferNotReadyAndMakeReady() {
    let data = CMBlockBuffer(data: Data([1, 2]))
    let sample = try! CMSampleBuffer(
        dataBuffer: data,
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 1), presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [2],
        dataReady: false
    )
    precondition(!sample.dataIsReady)
    do {
        _ = try sample.copyDataBytes()
        preconditionFailure("not-ready buffer must fail")
    } catch {
        precondition((error as NSError).code == -12733)
    }
    try! sample.makeDataReady()
    precondition(sample.dataIsReady)
    precondition(try! sample.copyDataBytes().count == 2)
}

func testCMSampleBufferInvalidateBeforeReadyCancels() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [1],
        dataReady: false
    )
    sample.invalidate()
    do {
        try sample.makeDataReady()
        preconditionFailure("invalidated not-ready buffer must not become ready")
    } catch {
        precondition((error as NSError).code == -12744)
    }
}

func testCMSampleBufferConcurrentAccess() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([7, 7])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 1), presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
        ],
        sampleSizes: [2]
    )
    let group = DispatchGroup()
    for _ in 0..<8 {
        group.enter()
        DispatchQueue.global().async {
            _ = CMSampleBufferIsValid(sample)
            _ = CMSampleBufferGetPresentationTimeStamp(sample)
            group.leave()
        }
    }
    group.wait()
    sample.invalidate()
    precondition(!sample.isValid)
}

func testCMAttachmentPropagateAndNonPropagate() {
    let source = CMBlockBuffer()
    source.attachments["propagate"] = .shouldPropagate("keep")
    source.attachments["local"] = .shouldNotPropagate("drop")
    let dest = CMBlockBuffer()
    source.propagateAttachments(to: dest)
    precondition(dest.attachments.propagated["propagate"] as? String == "keep")
    precondition(dest.attachments["local"] == nil)
}

func testSampleBufferErrorContracts() {
    precondition(CMSampleBuffer.Error.allocationFailed.code == -12730)
    precondition(CMSampleBuffer.Error.requiredParameterMissing.code == -12731)
    precondition(CMSampleBuffer.Error.invalidated.code == -12744)
    precondition(CMBlockBuffer.Error.structureAllocationFailed.code == -12700)
    precondition(CMFormatDescription.Error.invalidParameter.code == -12710)
    precondition(CMSampleBuffer.Error.invalidated.domain == NSOSStatusErrorDomain)
}

func testCMPersistentTrackIDInvalid() {
    precondition(kCMPersistentTrackID_Invalid == 0)
}

func testCMBlockBufferGetDataPointerInterior() {
    let buffer = CMBlockBuffer(data: Data([9, 8, 7, 6]))
    var lengthAtOffset = 0
    var total = 0
    var pointer: UnsafeMutablePointer<CChar>?
    precondition(
        CMBlockBufferGetDataPointer(
            buffer,
            atOffset: 1,
            lengthAtOffsetOut: &lengthAtOffset,
            totalLengthOut: &total,
            dataPointerOut: &pointer
        ) == 0
    )
    precondition(total == 4)
    precondition(lengthAtOffset == 3)
    precondition(pointer != nil)
    precondition(UInt8(bitPattern: pointer!.pointee) == 8)
    precondition(CMBlockBufferGetTypeID() == CMBlockBuffer.typeID)
}

func testCMBlockBufferAppendMemoryAndReference() {
    var dest: CMBlockBuffer?
    precondition(CMBlockBufferCreateEmpty(allocator: nil, capacity: 4, flags: 0, blockBufferOut: &dest) == 0)
    var bytes: [UInt8] = [1, 2, 3]
    bytes.withUnsafeMutableBytes { raw in
        precondition(
            CMBlockBufferAppendMemoryBlock(
                dest!,
                memoryBlock: raw.baseAddress,
                length: 3,
                blockAllocator: nil,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: 3,
                flags: 0
            ) == 0
        )
    }
    let extra = CMBlockBuffer(data: Data([4, 5]))
    precondition(
        CMBlockBufferAppendBufferReference(
            dest!,
            targetBBuf: extra,
            offsetToData: 0,
            dataLength: 0,
            flags: 0
        ) == 0
    )
    precondition(CMBlockBufferGetDataLength(dest!) == 5)
    var referenced: CMBlockBuffer?
    precondition(
        CMBlockBufferCreateWithBufferReference(
            allocator: nil,
            referenceBuffer: extra,
            offsetToData: 0,
            dataLength: 2,
            flags: 0,
            blockBufferOut: &referenced
        ) == 0
    )
    precondition(referenced!.dataLength == 2)
    try! dest!.append(bufferReference: extra)
}

func testCMSampleBufferCreateNotReadyAndSizes() {
    let data = CMBlockBuffer(data: Data([1, 2, 3, 4]))
    var timing = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 1),
        presentationTimeStamp: .zero,
        decodeTimeStamp: .invalid
    )
    var size = 4
    var sample: CMSampleBuffer?
    precondition(
        withUnsafePointer(to: &timing) { timingPtr in
            withUnsafePointer(to: &size) { sizePtr in
                CMSampleBufferCreate(
                    allocator: nil,
                    dataBuffer: data,
                    dataReady: false,
                    makeDataReadyCallback: nil,
                    makeDataReadyRefcon: nil,
                    formatDescription: nil,
                    sampleCount: 1,
                    sampleTimingEntryCount: 1,
                    sampleTimingArray: timingPtr,
                    sampleSizeEntryCount: 1,
                    sampleSizeArray: sizePtr,
                    sampleBufferOut: &sample
                )
            }
        } == 0
    )
    precondition(!CMSampleBufferDataIsReady(sample!))
    precondition(CMSampleBufferGetDataBuffer(sample!) === data)
    precondition(CMSampleBufferGetSampleSize(sample!, at: 0) == 4)
    var needed: CMItemCount = 0
    var sizes = [0]
    precondition(
        CMSampleBufferGetSampleSizeArray(
            sample!,
            sizeArrayEntries: 1,
            sizeArrayOut: &sizes,
            sizeArrayEntriesNeededOut: &needed
        ) == 0
    )
    precondition(sizes[0] == 4)
    precondition(CMSampleBufferSetDataReady(sample!) == 0)
    precondition(CMSampleBufferGetTypeID() == CMSampleBuffer.typeID)
}

func testCMSampleBufferTimingArraysAndCopyRange() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1, 2])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [
            CMSampleTimingInfo(
                duration: CMTime(value: 2, timescale: 1),
                presentationTimeStamp: CMTime(value: 4, timescale: 1),
                decodeTimeStamp: CMTime(value: 3, timescale: 1)
            )
        ],
        sampleSizes: [2]
    )
    var needed: CMItemCount = 0
    var info = CMSampleTimingInfo()
    precondition(
        CMSampleBufferGetSampleTimingInfoArray(
            sample,
            entryCount: 1,
            arrayToFill: &info,
            entriesNeededOut: &needed
        ) == 0
    )
    precondition(info.presentationTimeStamp.value == 4)
    precondition(
        CMSampleBufferGetOutputSampleTimingInfoArray(
            sample,
            entryCount: 1,
            arrayToFill: &info,
            entriesNeededOut: &needed
        ) == 0
    )
    precondition(CMSampleBufferGetOutputDuration(sample).value == 2)
    precondition(CMSampleBufferGetOutputDecodeTimeStamp(sample).value == 3)
    var copy: CMSampleBuffer?
    precondition(
        CMSampleBufferCopySampleBufferForRange(
            allocator: nil,
            sampleBuffer: sample,
            sampleRange: CFRange(location: 0, length: 1),
            sampleBufferOut: &copy
        ) == 0
    )
    var retimed: CMSampleBuffer?
    precondition(
        CMSampleBufferCreateCopyWithNewTiming(
            allocator: nil,
            sampleBuffer: sample,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleBufferOut: &retimed
        ) == 0
    )
    var visits = 0
    precondition(
        CMSampleBufferCallForEachSample(sample, callback: { _, _, _ in
            visits += 1
            return 0
        }, refcon: nil) == 0
    )
    precondition(visits == 1)
    precondition(CMSampleBufferCallBlockForEachSample(sample) { _, _ in 0 } == 0)
}

func testCMSampleBufferInvalidateCallbackAndAttachmentsArray() {
    let sample = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [1]
    )
    var callbackFires = 0
    precondition(
        CMSampleBufferSetInvalidateCallback(sample, callback: { _, _ in callbackFires += 1 }, refcon: 9) == 0
    )
    var handlerFires = 0
    precondition(CMSampleBufferSetInvalidateHandler(sample, invalidateHandler: { _ in handlerFires += 1 }) == 0)
    precondition(CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: false) == nil)
    let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: true)
    precondition(attachments != nil)
    precondition(CFArrayGetCount(attachments!) == 1)
    precondition(CMSampleBufferInvalidate(sample) == 0)
    precondition(callbackFires == 1)
    precondition(handlerFires == 1)
}

func testCMSampleBufferDataFailedAndTrackReadiness() {
    let ready = try! CMSampleBuffer(
        dataBuffer: CMBlockBuffer(data: Data([1, 2])),
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [2],
        dataReady: true
    )
    let pending = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 1,
        sampleTimings: [CMSampleTimingInfo(duration: .zero, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)],
        sampleSizes: [2],
        dataReady: false
    )
    precondition(CMSampleBufferSetDataFailed(pending, status: kCMSampleBufferError_DataFailed) == 0)
    var status: OSStatus = 0
    precondition(CMSampleBufferHasDataFailed(pending, statusOut: &status))
    precondition(status == kCMSampleBufferError_DataFailed)
    let follower = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: [],
        dataReady: false
    )
    precondition(CMSampleBufferTrackDataReadiness(follower, sampleBufferToTrack: ready) == 0)
    precondition(CMSampleBufferDataIsReady(follower))
    let empty = try! CMSampleBuffer(
        dataBuffer: nil,
        formatDescription: nil,
        numSamples: 0,
        sampleTimings: [],
        sampleSizes: [],
        dataReady: false
    )
    precondition(
        CMSampleBufferSetDataBuffer(empty, dataBuffer: CMBlockBuffer(data: Data([9]))) == 0
    )
    var created: CMSampleBuffer?
    precondition(
        CMSampleBufferCreateWithMakeDataReadyHandler(
            nil,
            CMBlockBuffer(data: Data([1])),
            true,
            nil,
            1,
            0,
            nil,
            0,
            nil,
            &created,
            { _ in 0 }
        ) == 0
    )
}

func testCMDoesBigEndianSoundDescriptionFailClosed() {
    let buffer = CMBlockBuffer(data: Data([0, 1, 2, 3]))
    precondition(
        CMDoesBigEndianSoundDescriptionRequireLegacyCBRSampleTableLayout(buffer, flavor: nil) == false
    )
}
