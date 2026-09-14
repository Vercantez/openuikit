import CoreFoundation
import Foundation

@frozen
public struct CMTimeFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let valid = CMTimeFlags(rawValue: 1 << 0)
    public static let hasBeenRounded = CMTimeFlags(rawValue: 1 << 1)
    public static let positiveInfinity = CMTimeFlags(rawValue: 1 << 2)
    public static let negativeInfinity = CMTimeFlags(rawValue: 1 << 3)
    public static let indefinite = CMTimeFlags(rawValue: 1 << 4)
    public static let impliedValueFlagsMask: CMTimeFlags = [
        .positiveInfinity, .negativeInfinity, .indefinite
    ]
}

@frozen
public enum CMTimeRoundingMethod: UInt32, Sendable, Hashable {
    case roundHalfAwayFromZero = 1
    case roundTowardZero = 2
    case roundAwayFromZero = 3
    case quickTime = 4
    case roundTowardPositiveInfinity = 5
    case roundTowardNegativeInfinity = 6

    public static var `default`: CMTimeRoundingMethod { .roundHalfAwayFromZero }
}

@frozen
public struct CMTime: Sendable {
    public var value: CMTimeValue
    public var timescale: CMTimeScale
    public var flags: CMTimeFlags
    public var epoch: CMTimeEpoch

    public init() {
        self.value = 0
        self.timescale = 0
        self.flags = []
        self.epoch = 0
    }

    public init(
        value: CMTimeValue,
        timescale: CMTimeScale,
        flags: CMTimeFlags,
        epoch: CMTimeEpoch
    ) {
        self.value = value
        self.timescale = timescale
        self.flags = flags
        self.epoch = epoch
    }

    public init(value: CMTimeValue, timescale: CMTimeScale) {
        self = CMTimeMake(value: value, timescale: timescale)
    }

    public init(seconds: Double, preferredTimescale: CMTimeScale) {
        self = CMTimeMakeWithSeconds(seconds, preferredTimescale: preferredTimescale)
    }

    public static let invalid = CMTime(value: 0, timescale: 0, flags: [], epoch: 0)
    public static let indefinite = CMTime(
        value: 0, timescale: 0, flags: [.valid, .indefinite], epoch: 0
    )
    public static let positiveInfinity = CMTime(
        value: 0, timescale: 0, flags: [.valid, .positiveInfinity], epoch: 0
    )
    public static let negativeInfinity = CMTime(
        value: 0, timescale: 0, flags: [.valid, .negativeInfinity], epoch: 0
    )
    public static let zero = CMTime(value: 0, timescale: 1, flags: [.valid], epoch: 0)

    public var isValid: Bool { flags.contains(.valid) }

    public var isNumeric: Bool {
        flags.contains(.valid) && flags.intersection(.impliedValueFlagsMask).isEmpty
    }

    public var hasBeenRounded: Bool {
        isNumeric && flags.contains(.hasBeenRounded)
    }

    public var isIndefinite: Bool {
        flags.contains(.valid) && flags.contains(.indefinite)
    }

    public var isPositiveInfinity: Bool {
        flags.contains(.valid) && flags.contains(.positiveInfinity)
    }

    public var isNegativeInfinity: Bool {
        flags.contains(.valid) && flags.contains(.negativeInfinity)
    }

    public var seconds: Double { CMTimeGetSeconds(self) }

    public func convertScale(
        _ newTimescale: Int32,
        method: CMTimeRoundingMethod
    ) -> CMTime {
        CMTimeConvertScale(self, timescale: newTimescale, method: method)
    }
}

extension CMTime: Equatable {
    public static func == (time1: CMTime, time2: CMTime) -> Bool {
        CMTimeCompare(time1, time2) == 0
    }

    public static func != (time1: CMTime, time2: CMTime) -> Bool {
        CMTimeCompare(time1, time2) != 0
    }
}

extension CMTime: Comparable {
    public static func < (time1: CMTime, time2: CMTime) -> Bool {
        CMTimeCompare(time1, time2) < 0
    }

    public static func <= (time1: CMTime, time2: CMTime) -> Bool {
        CMTimeCompare(time1, time2) <= 0
    }

    public static func > (time1: CMTime, time2: CMTime) -> Bool {
        CMTimeCompare(time1, time2) > 0
    }

    public static func >= (time1: CMTime, time2: CMTime) -> Bool {
        CMTimeCompare(time1, time2) >= 0
    }
}

extension CMTime: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(CMTimeGetSeconds(self))
        hasher.combine(epoch)
        hasher.combine(isValid)
        hasher.combine(isIndefinite)
        hasher.combine(isPositiveInfinity)
        hasher.combine(isNegativeInfinity)
    }
}

extension CMTime {
    public static func + (addend1: CMTime, addend2: CMTime) -> CMTime {
        CMTimeAdd(addend1, addend2)
    }

    public static func - (minuend: CMTime, subtrahend: CMTime) -> CMTime {
        CMTimeSubtract(minuend, subtrahend)
    }
}

public func CMTimeMake(value: Int64, timescale: Int32) -> CMTime {
    CMTimeMakeWithEpoch(value: value, timescale: timescale, epoch: 0)
}

public func CMTimeMakeWithEpoch(value: Int64, timescale: Int32, epoch: Int64) -> CMTime {
    guard timescale != 0 else { return .invalid }
    return CMTime(value: value, timescale: timescale, flags: .valid, epoch: epoch)
}

public func CMTimeMakeWithSeconds(_ seconds: Float64, preferredTimescale: Int32) -> CMTime {
    if preferredTimescale <= 0 { return .invalid }
    if seconds == Float64.infinity { return .positiveInfinity }
    if seconds == -Float64.infinity { return .negativeInfinity }
    // Apple 2026-09-14: NaN @ preferredTimescale 600 is valid+hasBeenRounded zero,
    // not invalid. Int64(Double.nan) is undefined, so this path is explicit.
    if seconds.isNaN {
        return CMTime(
            value: 0,
            timescale: preferredTimescale,
            flags: [.valid, .hasBeenRounded],
            epoch: 0
        )
    }
    var timescale = preferredTimescale
    var product = seconds * Float64(timescale)
    while timescale > 1
        && (product.isInfinite || product >= Float64(Int64.max) || product <= Float64(Int64.min))
    {
        timescale /= 2
        product = seconds * Float64(timescale)
    }
    if product.isNaN || product.isInfinite
        || product >= Float64(Int64.max) || product <= Float64(Int64.min)
    {
        if seconds > 0 { return .positiveInfinity }
        if seconds < 0 { return .negativeInfinity }
        return CMTime(
            value: 0,
            timescale: timescale,
            flags: [.valid, .hasBeenRounded],
            epoch: 0
        )
    }
    // Apple 2026-09-14: 0.5 @ timescale 1 is toward-zero (0), not half-away (1).
    let rounded = Int64(product)
    var flags: CMTimeFlags = .valid
    if Float64(rounded) / Float64(timescale) != seconds {
        flags.insert(.hasBeenRounded)
    }
    return CMTime(value: rounded, timescale: timescale, flags: flags, epoch: 0)
}

public func CMTimeGetSeconds(_ time: CMTime) -> Float64 {
    if time.isPositiveInfinity { return Float64.infinity }
    if time.isNegativeInfinity { return -Float64.infinity }
    if !time.isNumeric { return Float64.nan }
    return Float64(time.value) / Float64(time.timescale)
}

public func CMTimeConvertScale(
    _ time: CMTime,
    timescale newTimescale: Int32,
    method: CMTimeRoundingMethod
) -> CMTime {
    // CMTime.h: Default == RoundHalfAwayFromZero (1). QuickTime is toward-zero
    // when shrinking the scale, away-from-zero when growing it, and never
    // rounds a negative value down to 0.
    if !time.isValid { return .invalid }
    if newTimescale == 0 { return .invalid }
    if !time.isNumeric { return time }
    if time.timescale == newTimescale { return time }
    let numer = Int128(time.value) * Int128(newTimescale)
    let denom = Int128(time.timescale)
    let (quotient, rounded) = cmDivideRounding(
        numer,
        denom,
        cmResolvedRoundingMethod(
            method,
            fromTimescale: time.timescale,
            toTimescale: newTimescale
        )
    )
    switch quotient {
    case .overflowPositive:
        return .positiveInfinity
    case .overflowNegative:
        return .negativeInfinity
    case .value(let value):
        var stored = value
        if method == .quickTime && stored == 0 && time.value < 0 {
            stored = -1
        }
        var flags: CMTimeFlags = .valid
        if rounded || stored != value { flags.insert(.hasBeenRounded) }
        return CMTime(value: stored, timescale: newTimescale, flags: flags, epoch: time.epoch)
    }
}

public func CMTimeAdd(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
    cmAddSubtract(lhs, rhs, subtracting: false)
}

public func CMTimeSubtract(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
    cmAddSubtract(lhs, rhs, subtracting: true)
}

public func CMTimeMultiply(_ time: CMTime, multiplier: Int32) -> CMTime {
    CMTimeMultiplyByRatio(time, multiplier: multiplier, divisor: 1)
}

public func CMTimeMultiplyByRatio(_ time: CMTime, multiplier: Int32, divisor: Int32) -> CMTime {
    if !time.isValid { return .invalid }
    if divisor == 0 {
        if time.isIndefinite { return .indefinite }
        if !time.isNumeric {
            if multiplier == 0 { return .invalid }
            let negative = (multiplier < 0) != time.isNegativeInfinity
            if time.isPositiveInfinity || time.isNegativeInfinity {
                return negative ? .negativeInfinity : .positiveInfinity
            }
            return .invalid
        }
        if time.value == 0 || multiplier == 0 { return .invalid }
        let negative = (time.value < 0) != (multiplier < 0)
        return negative ? .negativeInfinity : .positiveInfinity
    }
    if !time.isNumeric {
        if multiplier == 0 { return .invalid }
        if time.isIndefinite { return .indefinite }
        let negative = (multiplier < 0) != (divisor < 0)
        if time.isPositiveInfinity {
            return negative ? .negativeInfinity : .positiveInfinity
        }
        if time.isNegativeInfinity {
            return negative ? .positiveInfinity : .negativeInfinity
        }
        return .invalid
    }
    // Preserve the exact rational (value * multiplier) / (timescale * divisor)
    // when both halves fit. Apple 2026-09-14: 1/2 * 2/3 is 2/6, not a rounded
    // value at the original timescale.
    var numer = Int128(time.value) * Int128(multiplier)
    var denom = Int128(time.timescale) * Int128(divisor)
    if denom < 0 {
        numer = -numer
        denom = -denom
    }
    return cmTimeFromRational(
        numer,
        timescale: denom,
        epoch: time.epoch,
        rounded: time.hasBeenRounded
    )
}

public func CMTimeMultiplyByFloat64(_ time: CMTime, multiplier: Float64) -> CMTime {
    if !time.isValid { return .invalid }
    if multiplier.isNaN { return .invalid }
    if !time.isNumeric {
        if multiplier == 0 { return .invalid }
        if time.isIndefinite { return .indefinite }
        if time.isPositiveInfinity {
            return multiplier < 0 ? .negativeInfinity : .positiveInfinity
        }
        if time.isNegativeInfinity {
            return multiplier < 0 ? .positiveInfinity : .negativeInfinity
        }
        return .invalid
    }
    if multiplier == Float64.infinity {
        if time.value == 0 { return .invalid }
        return time.value > 0 ? .positiveInfinity : .negativeInfinity
    }
    if multiplier == -Float64.infinity {
        if time.value == 0 { return .invalid }
        return time.value > 0 ? .negativeInfinity : .positiveInfinity
    }
    let seconds = CMTimeGetSeconds(time) * multiplier
    if seconds.isNaN { return .invalid }
    if seconds == Float64.infinity { return .positiveInfinity }
    if seconds == -Float64.infinity { return .negativeInfinity }
    // CMTime.h: start at the operand timescale, then double until >= 65536.
    // Apple 2026-09-14 used timescale 1_000_000_000 for 1/2 * 1.5; tests match
    // seconds/flags and leave that Darwin scale as an oracle question.
    var timescale = time.timescale < 0 ? -time.timescale : time.timescale
    if timescale < 1 { timescale = 1 }
    while timescale < 65536 && timescale <= Int32.max / 2 {
        timescale *= 2
    }
    var result = CMTimeMakeWithSeconds(seconds, preferredTimescale: timescale)
    if result.isNumeric {
        result.epoch = time.epoch
        if time.hasBeenRounded {
            result.flags.insert(.hasBeenRounded)
        }
    }
    return result
}

public func CMTimeCompare(_ time1: CMTime, _ time2: CMTime) -> Int32 {
    if time1.epoch != time2.epoch {
        return time1.epoch < time2.epoch ? -1 : 1
    }
    if time1.isNumeric && time2.isNumeric {
        let left = Int128(time1.value) * Int128(time2.timescale)
        let right = Int128(time2.value) * Int128(time1.timescale)
        if left < right { return -1 }
        if left > right { return 1 }
        return 0
    }
    let rank1 = cmNonNumericRank(time1)
    let rank2 = cmNonNumericRank(time2)
    if rank1 < rank2 { return -1 }
    if rank1 > rank2 { return 1 }
    return 0
}

public func CMTimeMinimum(_ time1: CMTime, _ time2: CMTime) -> CMTime {
    CMTimeCompare(time1, time2) <= 0 ? time1 : time2
}

public func CMTimeMaximum(_ time1: CMTime, _ time2: CMTime) -> CMTime {
    CMTimeCompare(time1, time2) >= 0 ? time1 : time2
}

public func CMTimeAbsoluteValue(_ time: CMTime) -> CMTime {
    if time.isNegativeInfinity { return .positiveInfinity }
    if time.isNumeric && time.value < 0 {
        return CMTime(
            value: -time.value,
            timescale: time.timescale,
            flags: time.flags,
            epoch: time.epoch
        )
    }
    return time
}

public func CMTimeClampToRange(_ time: CMTime, range: CMTimeRange) -> CMTime {
    guard time.isValid, range.isValid else { return .invalid }
    if range.isEmpty { return range.start }
    let end = range.end
    if CMTimeCompare(time, range.start) < 0 { return range.start }
    if CMTimeCompare(time, end) > 0 { return end }
    return time
}

public func CMTimeMapTimeFromRangeToRange(
    _ t: CMTime,
    fromRange: CMTimeRange,
    toRange: CMTimeRange
) -> CMTime {
    guard t.isValid, fromRange.isValid, toRange.isValid else { return .invalid }
    if fromRange.isEmpty { return toRange.start }
    let offset = CMTimeSubtract(t, fromRange.start)
    let mapped = CMTimeMapDurationFromRangeToRange(
        offset, fromRange: fromRange, toRange: toRange
    )
    return CMTimeAdd(toRange.start, mapped)
}

public func CMTimeMapDurationFromRangeToRange(
    _ dur: CMTime,
    fromRange: CMTimeRange,
    toRange: CMTimeRange
) -> CMTime {
    guard dur.isValid, fromRange.isValid, toRange.isValid else { return .invalid }
    if fromRange.isEmpty { return .zero }
    let fromSeconds = CMTimeGetSeconds(fromRange.duration)
    if fromSeconds == 0 { return .zero }
    let scale = CMTimeGetSeconds(dur) / fromSeconds
    return CMTimeMultiplyByFloat64(toRange.duration, multiplier: scale)
}

public func CMTimeFoldIntoRange(_ time: CMTime, foldRange: CMTimeRange) -> CMTime {
    guard time.isNumeric, foldRange.isValid, !foldRange.isEmpty, foldRange.duration.isNumeric else {
        return .invalid
    }
    let start = foldRange.start
    let duration = foldRange.duration
    let offset = CMTimeSubtract(time, start)
    if !offset.isNumeric { return .invalid }
    let durationSeconds = CMTimeGetSeconds(duration)
    var offsetSeconds = CMTimeGetSeconds(offset)
    if durationSeconds == 0 { return .invalid }
    offsetSeconds = offsetSeconds.truncatingRemainder(dividingBy: durationSeconds)
    if offsetSeconds < 0 { offsetSeconds += durationSeconds }
    let folded = CMTimeMakeWithSeconds(offsetSeconds, preferredTimescale: duration.timescale)
    return CMTimeAdd(start, folded)
}

public func CMTIME_IS_VALID(_ time: CMTime) -> Bool { time.isValid }
public func CMTIME_IS_INVALID(_ time: CMTime) -> Bool { !time.isValid }
public func CMTIME_IS_POSITIVEINFINITY(_ time: CMTime) -> Bool { time.isPositiveInfinity }
public func CMTIME_IS_NEGATIVEINFINITY(_ time: CMTime) -> Bool { time.isNegativeInfinity }
public func CMTIME_IS_INDEFINITE(_ time: CMTime) -> Bool { time.isIndefinite }
public func CMTIME_IS_NUMERIC(_ time: CMTime) -> Bool { time.isNumeric }
public func CMTIME_HAS_BEEN_ROUNDED(_ time: CMTime) -> Bool { time.hasBeenRounded }

public func CMTimeShow(_ time: CMTime) {
    let line = cmTimeDebugDescription(time) + "\n"
    FileHandle.standardError.write(Data(line.utf8))
}

public func CMTimeCopyDescription(allocator: CFAllocator?, time: CMTime) -> CFString? {
    _ = allocator
    return cmMakeCFString(cmTimeDebugDescription(time))
}

public let kCMTimeValueKey: CFString = cmMakeCFString("value")
public let kCMTimeScaleKey: CFString = cmMakeCFString("timescale")
public let kCMTimeEpochKey: CFString = cmMakeCFString("epoch")
public let kCMTimeFlagsKey: CFString = cmMakeCFString("flags")

public func CMTimeCopyAsDictionary(_ time: CMTime, allocator: CFAllocator?) -> CFDictionary? {
    _ = allocator
    var value = time.value
    var timescale = time.timescale
    var epoch = time.epoch
    var flags = time.flags.rawValue
    guard
        let valueNumber = CFNumberCreate(kCFAllocatorDefault, .sInt64Type, &value),
        let scaleNumber = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &timescale),
        let epochNumber = CFNumberCreate(kCFAllocatorDefault, .sInt64Type, &epoch),
        let flagsNumber = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &flags)
    else {
        return nil
    }
    return cmCFDictionary([
        (kCMTimeValueKey, valueNumber),
        (kCMTimeScaleKey, scaleNumber),
        (kCMTimeEpochKey, epochNumber),
        (kCMTimeFlagsKey, flagsNumber)
    ])
}

public func CMTimeMakeFromDictionary(_ dictionaryRepresentation: CFDictionary?) -> CMTime {
    guard let dictionaryRepresentation else { return .invalid }
    func int64(for key: CFString) -> Int64? {
        guard let raw = cmCFDictionaryValue(dictionaryRepresentation, key: key) else { return nil }
        let number = unsafeBitCast(raw, to: CFNumber.self)
        var value: Int64 = 0
        guard CFNumberGetValue(number, .sInt64Type, &value) else { return nil }
        return value
    }
    func int32(for key: CFString) -> Int32? {
        guard let raw = cmCFDictionaryValue(dictionaryRepresentation, key: key) else { return nil }
        let number = unsafeBitCast(raw, to: CFNumber.self)
        var value: Int32 = 0
        guard CFNumberGetValue(number, .sInt32Type, &value) else { return nil }
        return value
    }
    guard
        let value = int64(for: kCMTimeValueKey),
        let timescale = int32(for: kCMTimeScaleKey),
        let epoch = int64(for: kCMTimeEpochKey),
        let flags = int32(for: kCMTimeFlagsKey)
    else {
        return .invalid
    }
    return CMTime(
        value: value,
        timescale: timescale,
        flags: CMTimeFlags(rawValue: UInt32(bitPattern: flags)),
        epoch: epoch
    )
}

private enum CMRoundedQuotient {
    case value(Int64)
    case overflowPositive
    case overflowNegative
}

private func cmDivideRounding(
    _ numer: Int128,
    _ denom: Int128,
    _ method: CMTimeRoundingMethod
) -> (CMRoundedQuotient, Bool) {
    if denom == 0 { return (.overflowPositive, false) }
    let quotient = numer / denom
    let remainder = numer % denom
    if remainder == 0 {
        return (cmFitInt64(quotient), false)
    }
    let towardZero = quotient
    let extra = (numer < 0) == (denom < 0) ? Int128(1) : Int128(-1)
    let awayFromZero = towardZero + extra
    let towardPos = extra > 0 ? awayFromZero : towardZero
    let towardNeg = extra < 0 ? awayFromZero : towardZero
    let absRemainder = remainder < 0 ? -remainder : remainder
    let absDenom = denom < 0 ? -denom : denom
    let half = absRemainder * 2
    let chosen: Int128
    switch method {
    case .roundTowardZero:
        chosen = towardZero
    case .roundAwayFromZero:
        chosen = awayFromZero
    case .roundTowardPositiveInfinity:
        chosen = towardPos
    case .roundTowardNegativeInfinity:
        chosen = towardNeg
    case .roundHalfAwayFromZero, .quickTime:
        if half > absDenom {
            chosen = awayFromZero
        } else if half < absDenom {
            chosen = towardZero
        } else {
            chosen = awayFromZero
        }
    }
    return (cmFitInt64(chosen), true)
}

private func cmResolvedRoundingMethod(
    _ method: CMTimeRoundingMethod,
    fromTimescale: Int32,
    toTimescale: Int32
) -> CMTimeRoundingMethod {
    guard method == .quickTime else { return method }
    let from = fromTimescale < 0 ? -fromTimescale : fromTimescale
    let to = toTimescale < 0 ? -toTimescale : toTimescale
    return to > from ? .roundAwayFromZero : .roundTowardZero
}

private func cmFitInt64(_ value: Int128) -> CMRoundedQuotient {
    if value > Int128(Int64.max) { return .overflowPositive }
    if value < Int128(Int64.min) { return .overflowNegative }
    return .value(Int64(value))
}

private func cmNonNumericRank(_ time: CMTime) -> Int {
    // CMTime.h total order used by CMTimeCompare:
    // -infinity < finite < indefinite < +infinity < invalid
    if time.isNegativeInfinity { return 0 }
    if time.isNumeric { return 1 }
    if time.isIndefinite { return 2 }
    if time.isPositiveInfinity { return 3 }
    return 4
}

private func cmAddSubtract(_ lhs: CMTime, _ rhs: CMTime, subtracting: Bool) -> CMTime {
    if !lhs.isValid || !rhs.isValid { return .invalid }
    guard let epoch = cmEpochForAddSubtract(lhs.epoch, rhs.epoch) else { return .invalid }
    let rhsAdjusted: CMTime
    if subtracting {
        if rhs.isPositiveInfinity {
            rhsAdjusted = .negativeInfinity
        } else if rhs.isNegativeInfinity {
            rhsAdjusted = .positiveInfinity
        } else if rhs.isNumeric {
            rhsAdjusted = CMTime(
                value: -rhs.value,
                timescale: rhs.timescale,
                flags: rhs.flags,
                epoch: rhs.epoch
            )
        } else {
            rhsAdjusted = rhs
        }
    } else {
        rhsAdjusted = rhs
    }
    if lhs.isIndefinite || rhsAdjusted.isIndefinite { return .indefinite }
    if lhs.isPositiveInfinity && rhsAdjusted.isNegativeInfinity { return .invalid }
    if lhs.isNegativeInfinity && rhsAdjusted.isPositiveInfinity { return .invalid }
    if lhs.isPositiveInfinity || rhsAdjusted.isPositiveInfinity { return .positiveInfinity }
    if lhs.isNegativeInfinity || rhsAdjusted.isNegativeInfinity { return .negativeInfinity }
    if lhs.timescale == rhsAdjusted.timescale {
        let sum = Int128(lhs.value) + Int128(rhsAdjusted.value)
        return cmTimeFromInt128(sum, timescale: lhs.timescale, epoch: epoch, rounded: false)
    }
    let lcm = cmLCM(Int64(lhs.timescale), Int64(rhsAdjusted.timescale))
    if lcm > Int64(Int32.max) || lcm <= 0 {
        let seconds = CMTimeGetSeconds(lhs) + CMTimeGetSeconds(rhsAdjusted)
        var result = CMTimeMakeWithSeconds(seconds, preferredTimescale: lhs.timescale)
        if result.isNumeric { result.epoch = epoch }
        if result.isNumeric { result.flags.insert(.hasBeenRounded) }
        return result
    }
    let scale = Int32(lcm)
    let left = CMTimeConvertScale(lhs, timescale: scale, method: .default)
    let right = CMTimeConvertScale(rhsAdjusted, timescale: scale, method: .default)
    if !left.isNumeric || !right.isNumeric {
        return cmAddSubtract(
            CMTime(value: left.value, timescale: left.timescale, flags: left.flags, epoch: epoch),
            CMTime(value: right.value, timescale: right.timescale, flags: right.flags, epoch: 0),
            subtracting: false
        )
    }
    let rounded = left.hasBeenRounded || right.hasBeenRounded
    let sum = Int128(left.value) + Int128(right.value)
    return cmTimeFromInt128(sum, timescale: scale, epoch: epoch, rounded: rounded)
}

private func cmEpochForAddSubtract(_ lhs: CMTimeEpoch, _ rhs: CMTimeEpoch) -> CMTimeEpoch? {
    // CMTime.h: epoch 0 is a duration and can mix with any epoch. Different
    // nonzero epochs are invalid. Same nonzero epoch yields duration epoch 0.
    // Apple 2026-09-14: (1, epoch 1) + (1, epoch 0) is (2, epoch 1).
    if lhs == 0 { return rhs }
    if rhs == 0 { return lhs }
    if lhs == rhs { return 0 }
    return nil
}

private func cmTimeFromRational(
    _ value: Int128,
    timescale: Int128,
    epoch: CMTimeEpoch,
    rounded: Bool
) -> CMTime {
    var storedValue = value
    var storedScale = timescale
    if storedScale < 0 {
        storedValue = -storedValue
        storedScale = -storedScale
    }
    if storedScale == 0 { return .invalid }
    if storedScale <= Int128(Int32.max)
        && storedValue >= Int128(Int64.min)
        && storedValue <= Int128(Int64.max)
    {
        return cmTimeFromInt128(
            storedValue,
            timescale: Int32(storedScale),
            epoch: epoch,
            rounded: rounded
        )
    }
    let divisor = cmGCDInt128(storedValue, storedScale)
    storedValue /= divisor
    storedScale /= divisor
    if storedScale <= Int128(Int32.max)
        && storedValue >= Int128(Int64.min)
        && storedValue <= Int128(Int64.max)
    {
        return cmTimeFromInt128(
            storedValue,
            timescale: Int32(storedScale),
            epoch: epoch,
            rounded: rounded
        )
    }
    var scale = storedScale
    while scale > Int128(Int32.max) && scale > 1 {
        scale /= 2
    }
    if scale > Int128(Int32.max) { scale = Int128(Int32.max) }
    if scale < 1 { scale = 1 }
    let (converted, convertedRounded) = cmDivideRounding(
        storedValue * scale,
        storedScale,
        .default
    )
    switch converted {
    case .overflowPositive:
        return .positiveInfinity
    case .overflowNegative:
        return .negativeInfinity
    case .value(let fitted):
        return cmTimeFromInt128(
            Int128(fitted),
            timescale: Int32(scale),
            epoch: epoch,
            rounded: rounded || convertedRounded
        )
    }
}

private func cmGCDInt128(_ a: Int128, _ b: Int128) -> Int128 {
    var x = a < 0 ? -a : a
    var y = b < 0 ? -b : b
    while y != 0 {
        let t = x % y
        x = y
        y = t
    }
    return x == 0 ? 1 : x
}

private func cmTimeFromInt128(
    _ value: Int128,
    timescale: CMTimeScale,
    epoch: CMTimeEpoch,
    rounded: Bool
) -> CMTime {
    switch cmFitInt64(value) {
    case .overflowPositive:
        return .positiveInfinity
    case .overflowNegative:
        return .negativeInfinity
    case .value(let stored):
        var flags: CMTimeFlags = .valid
        if rounded { flags.insert(.hasBeenRounded) }
        return CMTime(value: stored, timescale: timescale, flags: flags, epoch: epoch)
    }
}

private func cmGCD(_ a: Int64, _ b: Int64) -> Int64 {
    var x = a < 0 ? -a : a
    var y = b < 0 ? -b : b
    while y != 0 {
        let t = x % y
        x = y
        y = t
    }
    return x == 0 ? 1 : x
}

private func cmLCM(_ a: Int64, _ b: Int64) -> Int64 {
    let g = cmGCD(a, b)
    let left = a / g
    if b != 0 && left > Int64.max / (b < 0 ? -b : b) {
        return Int64.max
    }
    let product = left * b
    return product < 0 ? -product : product
}

private func cmTimeDebugDescription(_ time: CMTime) -> String {
    if !time.isValid { return "invalid" }
    if time.isPositiveInfinity { return "+inf" }
    if time.isNegativeInfinity { return "-inf" }
    if time.isIndefinite { return "indefinite" }
    return "\(time.value)/\(time.timescale)"
}
