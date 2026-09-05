import CoreFoundation
import CoreMedia
import Foundation

func testCMClockHostTime() {
    let clock = CMClockGetHostTimeClock()
    let t1 = CMClockGetTime(clock)
    precondition(t1.isNumeric)
    precondition(t1.timescale == 1_000_000_000)
    let units = CMClockConvertHostTimeToSystemUnits(t1)
    let roundTrip = CMClockMakeHostTimeFromSystemUnits(units)
    precondition(roundTrip.timescale == 1_000_000_000)
    precondition(roundTrip.value == t1.value || abs(roundTrip.value - t1.value) <= 1)
    precondition(CMClock.hostTimeClock === clock)
    precondition(clock.time.isNumeric)
    precondition(!CMClockMightDrift(clock, otherClock: clock))
    let other = CMClock(referencing: clock)
    precondition(CMClockMightDrift(clock, otherClock: other) || other !== clock)
    precondition(CMClockGetTypeID() != 0)
    precondition(CMClock.typeID == CMClockGetTypeID())
    var anchor = CMTime.invalid
    var reference = CMTime.invalid
    precondition(CMClockGetAnchorTime(clock, clockTimeOut: &anchor, referenceClockTimeOut: &reference) == 0)
    precondition(anchor.isNumeric)
    precondition(CMClock.Error.allocationFailed.code == Int(kCMClockError_AllocationFailed))
    precondition(kCMClockError_MissingRequiredParameter == -12745)
    precondition(kCMClockError_InvalidParameter == -12746)
    precondition(kCMClockError_AllocationFailed == -12747)
    precondition(kCMClockError_UnsupportedOperation == -12756)
    let converted = CMClock.convertHostTimeToSystemUnits(t1)
    precondition(converted == units)
    let fromUnits = CMClock.convertSystemUnitsToHostTime(units)
    precondition(fromUnits.value == roundTrip.value)
}

func testCMTimebaseRateAndAnchor() {
    let clock = CMClockGetHostTimeClock()
    var timebase: CMTimebase?
    precondition(
        CMTimebaseCreateWithSourceClock(allocator: nil, sourceClock: clock, timebaseOut: &timebase) == 0
    )
    let tb = timebase!
    precondition(CMTimebaseGetRate(tb) == 0)
    precondition(CMTimebaseGetTime(tb) == .zero)
    precondition(CMTimebaseSetRate(tb, rate: 1.0) == 0)
    precondition(CMTimebaseGetRate(tb) == 1.0)
    let before = CMTimebaseGetTime(tb)
    Thread.sleep(forTimeInterval: 0.02)
    let after = CMTimebaseGetTime(tb)
    precondition(CMTimeCompare(after, before) > 0)
    precondition(CMTimebaseSetTime(tb, time: .zero) == 0)
    precondition(abs(CMTimeGetSeconds(CMTimebaseGetTime(tb))) < 0.01)
    let anchor = CMTime(value: 10, timescale: 1)
    let reference = CMTime(value: 5, timescale: 1)
    precondition(
        CMTimebaseSetRateAndAnchorTime(
            tb,
            rate: 2.0,
            timebaseTime: anchor,
            immediateSourceTime: reference
        ) == 0
    )
    precondition(tb.rate == 2.0)
    let mapped = CMTimebaseGetTimeWithTimeScale(tb, timescale: 1, method: .default)
    precondition(mapped.isNumeric || mapped.isPositiveInfinity)
    precondition(CMTimebaseGetEffectiveRate(tb) == 2.0)
    precondition(CMTimebaseCopySourceClock(tb) === clock)
    precondition(CMTimebaseCopyUltimateSourceClock(tb) === clock)
    precondition(CMTimebaseGetTypeID() != 0)
    precondition(kCMTimebaseError_MissingRequiredParameter == -12748)
    precondition(kCMTimebaseError_ReadOnly == -12757)
    precondition(CMTimebase.farFuture > 1.0e50)
    precondition(CMTimebase.veryLongTimeInterval > 1.0e50)
    precondition(CMSyncGetTime(clock).isNumeric)
    let identity = CMSyncConvertTime(.zero, from: clock, to: clock)
    precondition(identity == .zero)
    var child: CMTimebase?
    precondition(
        CMTimebaseCreateWithSourceTimebase(allocator: nil, sourceTimebase: tb, timebaseOut: &child) == 0
    )
    precondition(CMTimebaseGetEffectiveRate(child!) == 2.0 * child!.rate)
    precondition(kCMSyncError_RateMustBeNonZero == -12755)
}

func testCMTimeDocumentedArithmetic() {
    testCMTimeMakeValid()
    testCMTimeAddCommonTimescale()
    testCMTimeConvertScaleRounding()
    testCMTimeMultiplyAndRatio()
    testCMTimeInfinityArithmetic()
    testCMTimeCompareEpochOrdering()
    precondition(CMTIME_IS_VALID(CMTime.zero))
    precondition(CMTIME_IS_INVALID(CMTime.invalid))
    precondition(CMTIME_IS_NUMERIC(CMTime.zero))
    precondition(CMTIME_IS_POSITIVEINFINITY(CMTime.positiveInfinity))
    precondition(CMTIME_IS_NEGATIVEINFINITY(CMTime.negativeInfinity))
    precondition(CMTIME_IS_INDEFINITE(CMTime.indefinite))
    let rounded = CMTimeMakeWithSeconds(1.5, preferredTimescale: 1)
    precondition(CMTIME_HAS_BEEN_ROUNDED(rounded) || rounded.value == 2 || rounded.value == 1)
    let a = CMTime(value: 1, timescale: 2)
    let b = CMTime(value: 2, timescale: 4)
    precondition(a == b)
    precondition(a != .zero)
    precondition(a < CMTime(value: 1, timescale: 1))
    precondition(a <= b)
    precondition(CMTime(value: 1, timescale: 1) > a)
    precondition(a >= a)
    _ = a.hashValue
    let hashed = CMTime(value: 3, timescale: 2)
    var hasher = Hasher()
    hashed.hash(into: &hasher)
    _ = hasher.finalize()
    let flags = CMTimeFlags(rawValue: 1)
    precondition(flags.contains(.valid))
    precondition(CMTimeRoundingMethod(rawValue: 1) == .roundHalfAwayFromZero)
}
