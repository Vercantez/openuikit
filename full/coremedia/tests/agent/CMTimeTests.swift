import CoreFoundation
import CoreMedia
import Foundation

func testCMTimeMakeValid() {
    let t = CMTimeMake(value: 1, timescale: 2)
    precondition(t.value == 1)
    precondition(t.timescale == 2)
    precondition(t.isValid)
    precondition(t.isNumeric)
    precondition(!t.isIndefinite)
    precondition(t.epoch == 0)
}

func testCMTimeMakeInvalidTimescale() {
    let t = CMTimeMake(value: 1, timescale: 0)
    precondition(!t.isValid)
    precondition(t == .invalid)
}

func testCMTimeMakeWithEpoch() {
    let t = CMTimeMakeWithEpoch(value: 3, timescale: 4, epoch: 7)
    precondition(t.value == 3)
    precondition(t.timescale == 4)
    precondition(t.epoch == 7)
    precondition(t.isNumeric)
}

func testCMTimeSpecialConstants() {
    precondition(!CMTime.invalid.isValid)
    precondition(CMTime.zero.isNumeric)
    precondition(CMTime.zero.value == 0)
    precondition(CMTime.zero.timescale == 1)
    precondition(CMTime.positiveInfinity.isPositiveInfinity)
    precondition(CMTime.negativeInfinity.isNegativeInfinity)
    precondition(CMTime.indefinite.isIndefinite)
    precondition(!CMTime.indefinite.isNumeric)
    precondition(kCMTimeZero == .zero)
    precondition(kCMTimeInvalid == .invalid)
    precondition(kCMTimeIndefinite == .indefinite)
    precondition(kCMTimePositiveInfinity == .positiveInfinity)
    precondition(kCMTimeNegativeInfinity == .negativeInfinity)
}

func testCMTimeFlagMacros() {
    precondition(CMTIME_IS_VALID(CMTime.zero))
    precondition(CMTIME_IS_INVALID(CMTime.invalid))
    precondition(CMTIME_IS_NUMERIC(CMTime.zero))
    precondition(CMTIME_IS_POSITIVEINFINITY(CMTime.positiveInfinity))
    precondition(CMTIME_IS_NEGATIVEINFINITY(CMTime.negativeInfinity))
    precondition(CMTIME_IS_INDEFINITE(CMTime.indefinite))
    let rounded = CMTimeMakeWithSeconds(1.5, preferredTimescale: 1)
    precondition(CMTIME_HAS_BEEN_ROUNDED(rounded) || rounded.value == 2 || rounded.value == 1)
}

func testCMTimeSecondsRoundTrip() {
    let t = CMTime(seconds: 1.25, preferredTimescale: 4)
    precondition(t.value == 5)
    precondition(t.timescale == 4)
    precondition(CMTimeGetSeconds(t) == 1.25)
    precondition(t.seconds == 1.25)
}

func testCMTimeSecondsInvalidAndInfinity() {
    precondition(CMTimeGetSeconds(.invalid).isNaN)
    precondition(CMTimeGetSeconds(.indefinite).isNaN)
    precondition(CMTimeGetSeconds(.positiveInfinity) == Double.infinity)
    precondition(CMTimeGetSeconds(.negativeInfinity) == -Double.infinity)
    let nan = CMTimeMakeWithSeconds(Double.nan, preferredTimescale: 1)
    precondition(!nan.isValid)
    let pos = CMTimeMakeWithSeconds(Double.infinity, preferredTimescale: 600)
    precondition(pos.isPositiveInfinity)
    let neg = CMTimeMakeWithSeconds(-Double.infinity, preferredTimescale: 600)
    precondition(neg.isNegativeInfinity)
    let badScale = CMTimeMakeWithSeconds(1, preferredTimescale: 0)
    precondition(!badScale.isValid)
}

func testCMTimeAddCommonTimescale() {
    let half = CMTime(value: 1, timescale: 2)
    let third = CMTime(value: 1, timescale: 3)
    let sum = CMTimeAdd(half, third)
    precondition(CMTimeCompare(sum, CMTime(value: 5, timescale: 6)) == 0)
    precondition(CMTimeSubtract(sum, half) == third)
    precondition((half + third) == sum)
    precondition((sum - half) == third)
}

func testCMTimeCompareEpochOrdering() {
    let early = CMTimeMakeWithEpoch(value: 100, timescale: 1, epoch: 0)
    let late = CMTimeMakeWithEpoch(value: 1, timescale: 1, epoch: 1)
    precondition(CMTimeCompare(early, late) < 0)
    precondition(early < late)
    precondition(late > early)
    precondition(CMTimeMinimum(early, late) == early)
    precondition(CMTimeMaximum(early, late) == late)
}

func testCMTimeInfinityArithmetic() {
    precondition(CMTimeAdd(.positiveInfinity, .zero).isPositiveInfinity)
    precondition(CMTimeAdd(.negativeInfinity, .zero).isNegativeInfinity)
    precondition(!CMTimeAdd(.positiveInfinity, .negativeInfinity).isValid)
    precondition(CMTimeAbsoluteValue(.negativeInfinity).isPositiveInfinity)
    let neg = CMTime(value: -4, timescale: 2)
    precondition(CMTimeAbsoluteValue(neg).value == 4)
    precondition(CMTimeCompare(.negativeInfinity, .zero) < 0)
    precondition(CMTimeCompare(.zero, .positiveInfinity) < 0)
    precondition(CMTimeCompare(.positiveInfinity, .positiveInfinity) == 0)
}

func testCMTimeMultiplyAndRatio() {
    let t = CMTime(value: 3, timescale: 2)
    precondition(CMTimeMultiply(t, multiplier: 4).value == 12)
    let halved = CMTimeMultiplyByRatio(t, multiplier: 1, divisor: 3)
    precondition(halved.value == 1)
    precondition(halved.timescale == 2)
    let zeroDiv = CMTimeMultiplyByRatio(t, multiplier: 1, divisor: 0)
    precondition(!zeroDiv.isValid)
    let scaled = CMTimeMultiplyByFloat64(t, multiplier: 2.0)
    precondition(CMTimeCompare(scaled, CMTime(value: 6, timescale: 2)) == 0)
}

func testCMTimeConvertScaleRounding() {
    // CMTime.h rounding methods (raw values 1...6; Default == RoundHalfAwayFromZero).
    // Sample: value=1 timescale=2 → new timescale 1 is the 0.5 halfway case.
    let half = CMTime(value: 1, timescale: 2)
    let negHalf = CMTime(value: -1, timescale: 2)
    func scaled(_ time: CMTime, _ method: CMTimeRoundingMethod) -> Int64 {
        CMTimeConvertScale(time, timescale: 1, method: method).value
    }
    precondition(scaled(half, .roundHalfAwayFromZero) == 1)
    precondition(scaled(negHalf, .roundHalfAwayFromZero) == -1)
    precondition(scaled(half, .roundTowardZero) == 0)
    precondition(scaled(negHalf, .roundTowardZero) == 0)
    precondition(scaled(half, .roundAwayFromZero) == 1)
    precondition(scaled(negHalf, .roundAwayFromZero) == -1)
    precondition(scaled(half, .roundTowardPositiveInfinity) == 1)
    precondition(scaled(negHalf, .roundTowardPositiveInfinity) == 0)
    precondition(scaled(half, .roundTowardNegativeInfinity) == 0)
    precondition(scaled(negHalf, .roundTowardNegativeInfinity) == -1)
    // QuickTime: Linux stand-in is toward +infinity (oracle-questions.tsv).
    precondition(scaled(half, .quickTime) == 1)
    precondition(scaled(negHalf, .quickTime) == 0)
    precondition(CMTimeRoundingMethod.default == .roundHalfAwayFromZero)
    precondition(scaled(half, .default) == 1)
    let viaMethod = half.convertScale(1, method: .roundTowardZero)
    precondition(viaMethod.value == 0)
    precondition(viaMethod.hasBeenRounded)
    let zeroScale = CMTimeConvertScale(half, timescale: 0, method: .default)
    precondition(!zeroScale.isValid)
}

func testCMTimeOverflowToInfinity() {
    let huge = CMTime(value: Int64.max, timescale: 1)
    let doubled = CMTimeMultiply(huge, multiplier: 2)
    precondition(doubled.isPositiveInfinity)
    let tiny = CMTime(value: Int64.min, timescale: 1)
    let doubledNeg = CMTimeMultiply(tiny, multiplier: 2)
    precondition(doubledNeg.isNegativeInfinity)
}

func testCMTimeFlagsOptionSet() {
    var flags: CMTimeFlags = [.valid]
    precondition(flags.contains(.valid))
    precondition(!flags.contains(.indefinite))
    flags.insert(.hasBeenRounded)
    precondition(flags.contains(.hasBeenRounded))
    let union = flags.union(.indefinite)
    precondition(union.contains(.indefinite))
    precondition(CMTimeFlags.impliedValueFlagsMask.contains(.positiveInfinity))
    precondition(CMTimeFlags.impliedValueFlagsMask.contains(.negativeInfinity))
    precondition(CMTimeFlags.impliedValueFlagsMask.contains(.indefinite))
    _ = flags.remove(.valid)
    precondition(!flags.contains(.valid))
}

func testCMTimeRoundingMethodRawValues() {
    precondition(CMTimeRoundingMethod.roundHalfAwayFromZero.rawValue == 1)
    precondition(CMTimeRoundingMethod.roundTowardZero.rawValue == 2)
    precondition(CMTimeRoundingMethod.roundAwayFromZero.rawValue == 3)
    precondition(CMTimeRoundingMethod.quickTime.rawValue == 4)
    precondition(CMTimeRoundingMethod.roundTowardPositiveInfinity.rawValue == 5)
    precondition(CMTimeRoundingMethod.roundTowardNegativeInfinity.rawValue == 6)
    precondition(CMTimeRoundingMethod.default == .roundHalfAwayFromZero)
    precondition(CMTimeRoundingMethod(rawValue: 1) == .roundHalfAwayFromZero)
    precondition(CMTimeRoundingMethod(rawValue: 99) == nil)
}

func testCMTimeHashableEquatable() {
    let a = CMTime(value: 1, timescale: 2)
    let b = CMTime(value: 2, timescale: 4)
    precondition(a == b)
    precondition(a != .zero)
    precondition(!(a != b))
    _ = a.hashValue
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
    _ = CMTimeRoundingMethod.roundTowardZero.hashValue
}

func testCMTimeComparableOperators() {
    // CMTime.h: CMTimeCompare is the total order; Swift Comparable is that sign.
    let a = CMTime(value: 1, timescale: 2)
    let b = CMTime(value: 1, timescale: 1)
    precondition(a < b)
    precondition(b > a)
    precondition(a <= a)
    precondition(b >= a)
    precondition(a <= b)
    precondition(b >= b)
    precondition(CMTimeCompare(a, b) < 0)
}

func testCMTimeDictionaryRoundTrip() {
    let original = CMTimeMakeWithEpoch(value: 9, timescale: 30, epoch: 2)
    let dict = CMTimeCopyAsDictionary(original, allocator: kCFAllocatorDefault)
    precondition(dict != nil)
    let restored = CMTimeMakeFromDictionary(dict)
    precondition(restored.value == 9)
    precondition(restored.timescale == 30)
    precondition(restored.epoch == 2)
    precondition(CMTimeMakeFromDictionary(nil) == .invalid)
}

func testCMTimeMaxTimescale() {
    precondition(kCMTimeMaxTimescale == Int(Int32.max))
}

func testCMTimeDescription() {
    let desc = CMTimeCopyDescription(allocator: nil, time: .zero)
    precondition(desc != nil)
}

func testCMTimeMapAndClamp() {
    let range = CMTimeRange(start: .zero, duration: CMTime(value: 10, timescale: 1))
    let clamped = CMTimeClampToRange(CMTime(value: 15, timescale: 1), range: range)
    precondition(clamped == CMTime(value: 10, timescale: 1))
    let mapped = CMTimeMapTimeFromRangeToRange(
        CMTime(value: 5, timescale: 1),
        fromRange: range,
        toRange: CMTimeRange(start: .zero, duration: CMTime(value: 20, timescale: 1))
    )
    precondition(abs(mapped.seconds - 10) < 0.0001)
}

func testCMTimeFoldIntoRange() {
    let range = CMTimeRange(start: .zero, duration: CMTime(value: 10, timescale: 1))
    let folded = CMTimeFoldIntoRange(CMTime(value: 25, timescale: 1), foldRange: range)
    precondition(folded == CMTime(value: 5, timescale: 1))
    let invalid = CMTimeFoldIntoRange(.invalid, foldRange: range)
    precondition(!invalid.isValid)
}

func testCMTimeLayoutFingerprint() {
    precondition(MemoryLayout<CMTime>.size == 24)
    precondition(MemoryLayout<CMTime>.stride == 24)
    precondition(MemoryLayout<CMTime>.alignment == 8)
    precondition(MemoryLayout<CMTime>.offset(of: \CMTime.value) == 0)
    precondition(MemoryLayout<CMTime>.offset(of: \CMTime.timescale) == 8)
    precondition(MemoryLayout<CMTime>.offset(of: \CMTime.flags) == 12)
    precondition(MemoryLayout<CMTime>.offset(of: \CMTime.epoch) == 16)
    precondition(MemoryLayout<CMTimeFlags>.size == 4)
    precondition(MemoryLayout<CMTimeRange>.size == 48)
    precondition(MemoryLayout<CMTimeMapping>.size == 96)
    precondition(MemoryLayout<CMSampleTimingInfo>.size == 72)
    precondition(MemoryLayout<CMVideoDimensions>.size == 8)
    precondition(MemoryLayout<CMVideoDimensions>.offset(of: \CMVideoDimensions.width) == 0)
    precondition(MemoryLayout<CMVideoDimensions>.offset(of: \CMVideoDimensions.height) == 4)
}
