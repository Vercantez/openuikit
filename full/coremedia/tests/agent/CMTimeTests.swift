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
    precondition(CMTime.invalid.value == 0 && CMTime.invalid.timescale == 0)
    precondition(CMTime.invalid.flags.rawValue == 0)
    precondition(CMTime.zero.isNumeric)
    precondition(CMTime.zero.value == 0)
    precondition(CMTime.zero.timescale == 1)
    precondition(CMTime.zero.flags.rawValue == CMTimeFlags.valid.rawValue)
    precondition(CMTime.positiveInfinity.isPositiveInfinity)
    precondition(CMTime.positiveInfinity.value == 0 && CMTime.positiveInfinity.timescale == 0)
    precondition(CMTime.positiveInfinity.flags.rawValue == 5)
    precondition(CMTime.negativeInfinity.isNegativeInfinity)
    precondition(CMTime.negativeInfinity.value == 0 && CMTime.negativeInfinity.timescale == 0)
    precondition(CMTime.negativeInfinity.flags.rawValue == 9)
    precondition(CMTime.indefinite.isIndefinite)
    precondition(!CMTime.indefinite.isNumeric)
    precondition(CMTime.indefinite.value == 0 && CMTime.indefinite.timescale == 0)
    precondition(CMTime.indefinite.flags.rawValue == 17)
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
    let nan = CMTimeMakeWithSeconds(Double.nan, preferredTimescale: 600)
    precondition(nan.isValid)
    precondition(nan.hasBeenRounded)
    precondition(nan.value == 0)
    precondition(nan.timescale == 600)
    precondition(nan.flags.rawValue == 3)
    precondition(CMTimeGetSeconds(nan) == 0)
    let pos = CMTimeMakeWithSeconds(Double.infinity, preferredTimescale: 600)
    precondition(pos.isPositiveInfinity)
    precondition(pos.timescale == 0 && pos.flags.rawValue == 5)
    let neg = CMTimeMakeWithSeconds(-Double.infinity, preferredTimescale: 600)
    precondition(neg.isNegativeInfinity)
    precondition(neg.timescale == 0 && neg.flags.rawValue == 9)
    let badScale = CMTimeMakeWithSeconds(1, preferredTimescale: 0)
    precondition(!badScale.isValid)
    let halfAtOne = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1)
    precondition(halfAtOne.value == 0)
    precondition(halfAtOne.timescale == 1)
    precondition(halfAtOne.flags.rawValue == 3)
    let exact = CMTimeMakeWithSeconds(1.5, preferredTimescale: 2)
    precondition(exact.value == 3)
    precondition(exact.timescale == 2)
    precondition(exact.flags.rawValue == 1)
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
    precondition(halved.value == 3)
    precondition(halved.timescale == 6)
    precondition(halved.seconds == 0.5)
    let half = CMTime(value: 1, timescale: 2)
    let ratio = CMTimeMultiplyByRatio(half, multiplier: 2, divisor: 3)
    precondition(ratio.value == 2)
    precondition(ratio.timescale == 6)
    precondition(ratio.flags.rawValue == 1)
    let zeroDiv = CMTimeMultiplyByRatio(t, multiplier: 1, divisor: 0)
    precondition(zeroDiv.isPositiveInfinity)
    let scaled = CMTimeMultiplyByFloat64(t, multiplier: 2.0)
    precondition(CMTimeCompare(scaled, CMTime(value: 6, timescale: 2)) == 0)
    let floatProduct = CMTimeMultiplyByFloat64(half, multiplier: 1.5)
    precondition(floatProduct.seconds == 0.75)
    precondition(floatProduct.isNumeric)
    precondition(!floatProduct.hasBeenRounded)
    precondition(floatProduct.flags.contains(.valid))
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
    // Apple 2026-09-14: QuickTime is not toward-+infinity.
    precondition(scaled(half, .quickTime) == 0)
    precondition(scaled(negHalf, .quickTime) == -1)
    let to3 = CMTimeConvertScale(half, timescale: 3, method: .quickTime)
    precondition(to3.value == 2 && to3.timescale == 3)
    let fiveThirds = CMTimeConvertScale(
        CMTime(value: 5, timescale: 3),
        timescale: 2,
        method: .quickTime
    )
    precondition(fiveThirds.value == 3 && fiveThirds.timescale == 2)
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
    let inserted = flags.insert(.hasBeenRounded)
    precondition(inserted.inserted)
    precondition(flags.contains(.hasBeenRounded))
    let updated = flags.update(with: .indefinite)
    precondition(updated == nil || !flags.isEmpty)
    precondition(flags.contains(.indefinite))
    let union = flags.union(.positiveInfinity)
    precondition(union.contains(.positiveInfinity))
    let intersection = flags.intersection([.valid, .hasBeenRounded])
    precondition(intersection.contains(.valid))
    let symmetric = flags.symmetricDifference(.indefinite)
    precondition(!symmetric.contains(.indefinite))
    precondition(flags.contains(.indefinite))
    flags.formUnion(.negativeInfinity)
    flags.formIntersection([.valid, .hasBeenRounded, .negativeInfinity])
    flags.formSymmetricDifference(.hasBeenRounded)
    precondition(CMTimeFlags.impliedValueFlagsMask.contains(.positiveInfinity))
    precondition(CMTimeFlags.impliedValueFlagsMask.contains(.negativeInfinity))
    precondition(CMTimeFlags.impliedValueFlagsMask.contains(.indefinite))
    _ = flags.remove(.valid)
    precondition(!flags.contains(.valid))
    let empty = CMTimeFlags()
    precondition(empty.isEmpty)
    let fromRaw = CMTimeFlags(rawValue: 1)
    precondition(fromRaw.contains(.valid))
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
    precondition(CMTimeRoundingMethod.roundTowardZero != .quickTime)
    precondition(CMTimeRoundingMethod.roundTowardZero.hashValue == CMTimeRoundingMethod.roundTowardZero.hashValue)
    var methodHasher = Hasher()
    CMTimeRoundingMethod.quickTime.hash(into: &methodHasher)
    _ = methodHasher.finalize()
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
    precondition(CFDictionaryGetCount(dict!) == 4)
    precondition(CFDictionaryGetValue(dict, unsafeBitCast(kCMTimeValueKey, to: UnsafeRawPointer.self)) != nil)
    precondition(CFDictionaryGetValue(dict, unsafeBitCast(kCMTimeScaleKey, to: UnsafeRawPointer.self)) != nil)
    precondition(CFDictionaryGetValue(dict, unsafeBitCast(kCMTimeEpochKey, to: UnsafeRawPointer.self)) != nil)
    precondition(CFDictionaryGetValue(dict, unsafeBitCast(kCMTimeFlagsKey, to: UnsafeRawPointer.self)) != nil)
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

func testCMTimeAppleOracleEpochAndInits() {
    let e1 = CMTime(value: 1, timescale: 1, flags: .valid, epoch: 1)
    let e0 = CMTime(value: 1, timescale: 1, flags: .valid, epoch: 0)
    let sum = CMTimeAdd(e1, e0)
    precondition(sum.value == 2)
    precondition(sum.timescale == 1)
    precondition(sum.epoch == 1)
    precondition(sum.flags.rawValue == 1)
    precondition(CMTimeCompare(e1, e0) == 1)
    precondition(CMTimeCompare(.negativeInfinity, .zero) < 0)
    precondition(CMTimeCompare(.zero, .indefinite) < 0)
    precondition(CMTimeCompare(.indefinite, .positiveInfinity) < 0)
    precondition(CMTimeCompare(.positiveInfinity, .invalid) < 0)

    let empty = CMTime()
    precondition(!empty.isValid)
    precondition(empty.value == 0 && empty.timescale == 0)
    let fromParts = CMTime(value: 3, timescale: 4, flags: .valid, epoch: 8)
    precondition(fromParts.value == 3 && fromParts.timescale == 4 && fromParts.epoch == 8)
    let fromValue = CMTime(value: 1, timescale: 2)
    precondition(fromValue.isNumeric && fromValue.seconds == 0.5)
    let fromSeconds = CMTime(seconds: 1.5, preferredTimescale: 2)
    precondition(fromSeconds.value == 3 && fromSeconds.timescale == 2 && fromSeconds.flags.rawValue == 1)
    let value: CMTimeValue = fromParts.value
    let scale: CMTimeScale = fromParts.timescale
    let epoch: CMTimeEpoch = fromParts.epoch
    precondition(value == 3 && scale == 4 && epoch == 8)
    let rounding = CMTimeRoundingMethod(rawValue: 4)
    precondition(rounding == .quickTime)
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
