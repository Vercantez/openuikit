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
    let t = CMTime(value: 1, timescale: 2)
    let up = t.convertScale(1, method: .roundTowardPositiveInfinity)
    precondition(up.value == 1)
    let down = t.convertScale(1, method: .roundTowardZero)
    precondition(down.value == 0)
    precondition(down.hasBeenRounded)
    let away = CMTimeConvertScale(t, timescale: 1, method: .roundAwayFromZero)
    precondition(away.value == 1)
    let half = CMTime(value: 1, timescale: 2).convertScale(1, method: .roundHalfAwayFromZero)
    precondition(half.value == 1)
    let neg = CMTime(value: -1, timescale: 2)
    let negDown = CMTimeConvertScale(neg, timescale: 1, method: .roundTowardNegativeInfinity)
    precondition(negDown.value == -1)
    let zeroScale = CMTimeConvertScale(t, timescale: 0, method: .default)
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
    _ = a.hashValue
    _ = CMTimeRoundingMethod.roundTowardZero.hashValue
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
