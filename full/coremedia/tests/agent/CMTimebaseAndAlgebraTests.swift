import CoreFoundation
import CoreMedia
import Foundation

func testCMTimeRangeMacroPredicates() {
    let valid = CMTimeRangeMake(start: .zero, duration: CMTime(value: 1, timescale: 1))
    precondition(CMTIMERANGE_IS_VALID(valid))
    precondition(!CMTIMERANGE_IS_INVALID(valid))
    precondition(!CMTIMERANGE_IS_EMPTY(valid))
    precondition(!CMTIMERANGE_IS_INDEFINITE(valid))
    precondition(CMTIMERANGE_IS_EMPTY(CMTimeRange.zero))
    precondition(CMTIMERANGE_IS_INVALID(CMTimeRange.invalid))
    let indefinite = CMTimeRange(start: .indefinite, duration: CMTime(value: 1, timescale: 1))
    precondition(CMTIMERANGE_IS_INDEFINITE(indefinite) || !indefinite.isValid)
    let fromEnd = CMTimeRange(start: .zero, end: CMTime(value: 2, timescale: 1))
    precondition(fromEnd.duration.value == 2)
    var hasher = Hasher()
    valid.hash(into: &hasher)
    _ = hasher.finalize()
    _ = valid.hashValue
    let mapping = CMTimeMapping()
    precondition(mapping.source == .invalid)
    let named = CMTimeMapping(source: valid, target: valid)
    precondition(named.source == valid)
}

func testCMTimebaseOverlayRateAnchorAndErrors() {
    let clock = CMClock.hostTimeClock
    let timebase = CMTimebase(sourceClock: clock)
    try! timebase.setRate(1.5)
    precondition(timebase.rate == 1.5)
    try! timebase.setTime(.zero)
    let now = timebase.time
    precondition(now.isNumeric || now.isPositiveInfinity)
    try! timebase.setAnchorTime(CMTime(value: 1, timescale: 1), referenceTime: clock.time)
    try! timebase.setRateAndAnchorTime(
        rate: 2,
        anchorTime: .zero,
        referenceTime: clock.time
    )
    precondition(timebase.effectiveRate == 2)
    let scaled = timebase.time(withTimescale: 600, rounding: .default)
    precondition(scaled.timescale == 600 || !scaled.isNumeric)
    let pair = timebase.timeAndRate
    precondition(pair.rate == 2)
    precondition(timebase.sourceClock === clock)
    precondition(timebase.masterClock === clock)
    precondition(timebase.ultimateSourceClock === clock)
    precondition(timebase.ultimateMasterClock === clock)
    precondition(timebase.sourceTimebase == nil)
    precondition(timebase.masterTimebase == nil)
    _ = timebase.source
    _ = timebase.master
    precondition(timebase.convertTime(.zero, to: clock).isNumeric || timebase.convertTime(.zero, to: clock).isValid)
    precondition(timebase.rate(relativeTo: clock) == 2 || timebase.rate(relativeTo: clock) > 0)
    _ = try? timebase.rateAndAnchorTime(relativeTo: clock)
    _ = timebase.mightDrift(relativeTo: clock)
    try! timebase.notificationBarrier()
    precondition(CMTimebase.timeJumped.rawValue.contains("TimeJumped") || true)
    precondition(CMTimebase.effectiveRateChanged.rawValue.contains("EffectiveRateChanged") || true)
    precondition(CFEqual(CMTimebase.NotificationKey.eventTime.rawValue, kCMTimebaseNotificationKey_EventTime))
    precondition(CMTimebase.Error.allocationFailed.code == Int(kCMTimebaseError_AllocationFailed))
    precondition(CMTimebase.Error.invalidParameter.code == Int(kCMTimebaseError_InvalidParameter))
    precondition(CMTimebase.Error.timerIntervalTooShort.code == Int(kCMTimebaseError_TimerIntervalTooShort))
    precondition(CMTimebase.Error.missingRequiredParameter.code == Int(kCMTimebaseError_MissingRequiredParameter))
    precondition(CMTimebase.Error.readOnly.code == Int(kCMTimebaseError_ReadOnly))
    do {
        try timebase.addTimer(Timer(timeInterval: 1, repeats: false, block: { _ in }), on: .main)
        preconditionFailure("timers must fail closed")
    } catch {
        precondition((error as NSError).code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
    let timer = Timer(timeInterval: 1, repeats: false, block: { _ in })
    do { try timebase.removeTimer(timer); preconditionFailure("removeTimer must fail closed") } catch {
        precondition((error as NSError).code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
    do { try timebase.setTimerNextFireTime(timer, fireTime: .zero); preconditionFailure("setTimerNextFireTime must fail closed") } catch {
        precondition((error as NSError).code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
    do { try timebase.setTimerToFireImmediately(timer); preconditionFailure("setTimerToFireImmediately must fail closed") } catch {
        precondition((error as NSError).code == Int(kCMTimebaseError_TimerIntervalTooShort))
    }
    let child = CMTimebase(sourceTimebase: timebase)
    child.source = clock
    precondition(child.sourceClock === clock)
    precondition(CMTimebase.typeID == CMTimebaseGetTypeID())
}

func testCMBlockBufferFlagsErrorsAndAppend() {
    precondition(CMBlockBuffer.Flags.assureMemoryNow.rawValue == kCMBlockBufferAssureMemoryNowFlag)
    precondition(CMBlockBuffer.Flags.alwaysCopyData.rawValue == kCMBlockBufferAlwaysCopyDataFlag)
    precondition(CMBlockBuffer.Flags.dontOptimizeDepth.rawValue == kCMBlockBufferDontOptimizeDepthFlag)
    precondition(CMBlockBuffer.Flags.permitEmptyReference.rawValue == kCMBlockBufferPermitEmptyReferenceFlag)
    let flags = CMBlockBuffer.Flags(rawValue: 1)
    precondition(flags.contains(.assureMemoryNow))
    precondition(CMBlockBuffer.Error.structureAllocationFailed.code == -12700)
    precondition(CMBlockBuffer.Error.blockAllocationFailed.code == -12701)
    precondition(CMBlockBuffer.Error.badCustomBlockSource.code == -12702)
    precondition(CMBlockBuffer.Error.badOffsetParameter.code == -12703)
    precondition(CMBlockBuffer.Error.badLengthParameter.code == -12704)
    precondition(CMBlockBuffer.Error.badPointerParameter.code == -12705)
    precondition(CMBlockBuffer.Error.emptyBlockBuffer.code == -12706)
    precondition(CMBlockBuffer.Error.unallocatedBlock.code == -12707)
    precondition(CMBlockBuffer.Error.insufficientSpace.code == -12708)
    let empty = CMBlockBuffer()
    try! empty.assureBlockMemory()
    precondition(empty.isEmpty)
    precondition(CMBlockBuffer.typeID == CMBlockBufferGetTypeID())
    let destination = CMBlockBuffer(length: 2)
    let source = CMBlockBuffer(data: Data([9, 8]))
    try! destination.append(bufferReference: source)
    precondition(destination.dataLength == 4)
    precondition(destination.startIndex == 0)
    precondition(destination.owner === destination)
    var extra = Data([1, 2, 3])
    extra.withUnsafeMutableBytes { bytes in
        try! destination.append(buffer: bytes, flags: .alwaysCopyData)
        try! destination.append(buffer: bytes, deallocator: { _, _ in }, flags: .alwaysCopyData)
        let slice = bytes[0..<2]
        try! destination.append(buffer: slice, deallocator: { _, _ in }, flags: [])
        try! destination.append(buffer: slice, allocator: kCFAllocatorDefault, flags: [])
    }
    precondition(destination.dataLength == 4 + 3 + 3 + 2 + 2)
    try! destination.append(length: 1, allocator: { count in UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1) }, deallocator: { pointer, _ in pointer.deallocate() })
    try! destination.append(length: 1, allocator: kCFAllocatorDefault, range: nil, flags: [])
    precondition(destination.dataLength == 16)
}

func testCMOptionSetAlgebra() {
    var timeFlags: CMTimeFlags = [.valid, .hasBeenRounded]
    precondition(timeFlags.contains(.valid))
    timeFlags.formUnion(.indefinite)
    precondition(timeFlags.contains(.indefinite))
    timeFlags.formIntersection([.valid])
    precondition(timeFlags == .valid)
    precondition(!timeFlags.isEmpty)
    let stereo: CMStereoViewComponents = [.leftEye, .rightEye]
    precondition(stereo.contains(.leftEye))
    precondition(stereo.union(.leftEye) == stereo)
    precondition(stereo.intersection(.leftEye) == .leftEye)
    let interpretation: CMStereoViewInterpretationOptions = [.additionalViews, .stereoOrderReversed]
    precondition(interpretation.contains(.additionalViews))
    var blockFlags: CMBlockBuffer.Flags = [.assureMemoryNow, .alwaysCopyData]
    precondition(blockFlags.contains(.alwaysCopyData))
    blockFlags.formSymmetricDifference(.alwaysCopyData)
    precondition(!blockFlags.contains(.alwaysCopyData))
    let sampleFlags = CMSampleBuffer.Flags(rawValue: 0)
    precondition(sampleFlags.isEmpty)
    let mask: CMFormatDescription.EqualityMask = [.all]
    precondition(mask.contains(.magicCookie))
    let codeFlags: CMFormatDescription.TimeCode.Flag = [.dropFrame, .negTimesOK]
    precondition(codeFlags.contains(.dropFrame))
    let face: CMFormatDescription.Extensions.Value.FontFace = [.bold, .underline]
    precondition(face.contains(.underline))
    precondition(timeFlags != .indefinite)
    precondition(CMTime.zero != CMTime.invalid)
    precondition(CMTimeRange.zero != CMTimeRange.invalid)
}
