public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias CMTimeEpoch = Int64

public let kCMTimeMaxTimescale: CMTimeScale = .max

public struct CMTimeFlags: OptionSet, Hashable, Sendable {
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
        .positiveInfinity, .negativeInfinity, .indefinite,
    ]
}

public enum CMTimeRoundingMethod: UInt32, Sendable {
    case roundHalfAwayFromZero = 1
    case roundTowardZero = 2
    case roundAwayFromZero = 3
    case quickTime = 4
    case roundTowardPositiveInfinity = 5
    case roundTowardNegativeInfinity = 6

    public static let `default` = CMTimeRoundingMethod.roundHalfAwayFromZero
}

/// A portable rational media timestamp with the same stored representation as
/// CoreMedia's public `CMTime` structure.
public struct CMTime: Hashable, Sendable, Comparable, CustomStringConvertible {
    public var value: CMTimeValue
    public var timescale: CMTimeScale
    public var flags: CMTimeFlags
    public var epoch: CMTimeEpoch

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
        guard timescale > 0 else {
            self = .invalid
            return
        }
        self.init(value: value, timescale: timescale, flags: .valid, epoch: 0)
    }

    public init(seconds: Double, preferredTimescale: CMTimeScale) {
        self = CMTimeMakeWithSeconds(seconds, preferredTimescale: preferredTimescale)
    }

    public static let invalid = CMTime(
        value: 0, timescale: 0, flags: [], epoch: 0
    )
    public static let indefinite = CMTime(
        value: 0, timescale: 0, flags: [.valid, .indefinite], epoch: 0
    )
    public static let positiveInfinity = CMTime(
        value: 0, timescale: 0, flags: [.valid, .positiveInfinity], epoch: 0
    )
    public static let negativeInfinity = CMTime(
        value: 0, timescale: 0, flags: [.valid, .negativeInfinity], epoch: 0
    )
    public static let zero = CMTime(value: 0, timescale: 1)

    public var isValid: Bool { flags.contains(.valid) }
    public var isNumeric: Bool {
        isValid && flags.intersection(.impliedValueFlagsMask).isEmpty
            && timescale > 0
    }
    public var isIndefinite: Bool {
        isValid && flags.contains(.indefinite)
    }
    public var isPositiveInfinity: Bool {
        isValid && flags.contains(.positiveInfinity)
    }
    public var isNegativeInfinity: Bool {
        isValid && flags.contains(.negativeInfinity)
    }
    public var hasBeenRounded: Bool {
        isNumeric && flags.contains(.hasBeenRounded)
    }
    public var seconds: Double { CMTimeGetSeconds(self) }

    public static func == (lhs: CMTime, rhs: CMTime) -> Bool {
        if !lhs.isValid || !rhs.isValid { return !lhs.isValid && !rhs.isValid }
        if lhs.isIndefinite || rhs.isIndefinite {
            return lhs.isIndefinite && rhs.isIndefinite
        }
        return CMTimeCompare(lhs, rhs) == 0
    }

    public func hash(into hasher: inout Hasher) {
        guard isValid else {
            hasher.combine(UInt8(0))
            return
        }
        if isIndefinite {
            hasher.combine(UInt8(1))
            return
        }
        if isPositiveInfinity {
            hasher.combine(UInt8(2))
            return
        }
        if isNegativeInfinity {
            hasher.combine(UInt8(3))
            return
        }
        let divisor = _cmGCD(value, Int64(timescale))
        hasher.combine(UInt8(4))
        hasher.combine(value / divisor)
        hasher.combine(Int64(timescale) / divisor)
        hasher.combine(epoch)
    }

    public static func < (lhs: CMTime, rhs: CMTime) -> Bool {
        CMTimeCompare(lhs, rhs) < 0
    }

    public var description: String {
        if !isValid { return "invalid" }
        if isIndefinite { return "indefinite" }
        if isPositiveInfinity { return "+infinity" }
        if isNegativeInfinity { return "-infinity" }
        return "{\(value)/\(timescale) = \(seconds), epoch \(epoch)}"
    }
}

public let kCMTimeInvalid = CMTime.invalid
public let kCMTimeIndefinite = CMTime.indefinite
public let kCMTimePositiveInfinity = CMTime.positiveInfinity
public let kCMTimeNegativeInfinity = CMTime.negativeInfinity
public let kCMTimeZero = CMTime.zero

public func CMTimeMake(
    value: CMTimeValue,
    timescale: CMTimeScale
) -> CMTime {
    CMTime(value: value, timescale: timescale)
}

public func CMTimeMakeWithEpoch(
    value: CMTimeValue,
    timescale: CMTimeScale,
    epoch: CMTimeEpoch
) -> CMTime {
    guard timescale > 0 else { return .invalid }
    return CMTime(value: value, timescale: timescale, flags: .valid, epoch: epoch)
}

public func CMTimeMakeWithSeconds(
    _ seconds: Double,
    preferredTimescale: CMTimeScale
) -> CMTime {
    guard preferredTimescale > 0, !seconds.isNaN else { return .invalid }
    if seconds == .infinity { return .positiveInfinity }
    if seconds == -.infinity { return .negativeInfinity }

    var scale = preferredTimescale
    while scale > 1
        && abs(seconds) > Double(Int64.max) / Double(scale)
    {
        scale /= 2
    }
    guard abs(seconds) <= Double(Int64.max) / Double(scale) else {
        return seconds.sign == .minus ? .negativeInfinity : .positiveInfinity
    }

    let scaled = seconds * Double(scale)
    let value = CMTimeValue(scaled.rounded(.toNearestOrAwayFromZero))
    var flags: CMTimeFlags = .valid
    if Double(value) / Double(scale) != seconds {
        flags.insert(.hasBeenRounded)
    }
    return CMTime(value: value, timescale: scale, flags: flags, epoch: 0)
}

public func CMTimeGetSeconds(_ time: CMTime) -> Double {
    guard time.isValid else { return .nan }
    if time.isPositiveInfinity { return .infinity }
    if time.isNegativeInfinity { return -.infinity }
    guard time.isNumeric else { return .nan }
    return Double(time.value) / Double(time.timescale)
}

public func CMTimeCompare(_ time1: CMTime, _ time2: CMTime) -> Int32 {
    guard time1.isValid, time2.isValid else { return 0 }
    if time1.isNegativeInfinity { return time2.isNegativeInfinity ? 0 : -1 }
    if time2.isNegativeInfinity { return 1 }
    if time1.isPositiveInfinity { return time2.isPositiveInfinity ? 0 : 1 }
    if time2.isPositiveInfinity { return -1 }
    guard time1.isNumeric, time2.isNumeric else { return 0 }
    if time1.epoch != time2.epoch { return time1.epoch < time2.epoch ? -1 : 1 }

    let (left, leftOverflow) = time1.value.multipliedReportingOverflow(
        by: Int64(time2.timescale)
    )
    let (right, rightOverflow) = time2.value.multipliedReportingOverflow(
        by: Int64(time1.timescale)
    )
    if !leftOverflow, !rightOverflow {
        if left == right { return 0 }
        return left < right ? -1 : 1
    }
    let lhs = time1.seconds
    let rhs = time2.seconds
    if lhs == rhs { return 0 }
    return lhs < rhs ? -1 : 1
}

public func CMTimeAdd(_ addend1: CMTime, _ addend2: CMTime) -> CMTime {
    if addend1.isPositiveInfinity || addend2.isPositiveInfinity {
        if addend1.isNegativeInfinity || addend2.isNegativeInfinity { return .invalid }
        return .positiveInfinity
    }
    if addend1.isNegativeInfinity || addend2.isNegativeInfinity {
        return .negativeInfinity
    }
    guard addend1.isNumeric, addend2.isNumeric,
          addend1.epoch == addend2.epoch else { return .invalid }
    return _cmTimeFromBinaryOperation(addend1, addend2, subtract: false)
}

public func CMTimeSubtract(
    _ minuend: CMTime,
    _ subtrahend: CMTime
) -> CMTime {
    if subtrahend.isPositiveInfinity { return .negativeInfinity }
    if subtrahend.isNegativeInfinity { return .positiveInfinity }
    guard minuend.isNumeric, subtrahend.isNumeric,
          minuend.epoch == subtrahend.epoch else { return .invalid }
    return _cmTimeFromBinaryOperation(minuend, subtrahend, subtract: true)
}

private func _cmTimeFromBinaryOperation(
    _ lhs: CMTime,
    _ rhs: CMTime,
    subtract: Bool
) -> CMTime {
    let divisor = _cmGCD(Int64(lhs.timescale), Int64(rhs.timescale))
    let leftMultiplier = Int64(rhs.timescale) / divisor
    let rightMultiplier = Int64(lhs.timescale) / divisor
    let (scale64, scaleOverflow) = Int64(lhs.timescale)
        .multipliedReportingOverflow(by: leftMultiplier)
    let (left, leftOverflow) = lhs.value.multipliedReportingOverflow(
        by: leftMultiplier
    )
    let (right, rightOverflow) = rhs.value.multipliedReportingOverflow(
        by: rightMultiplier
    )
    if !scaleOverflow, scale64 <= Int64(kCMTimeMaxTimescale),
       !leftOverflow, !rightOverflow
    {
        let result = subtract
            ? left.subtractingReportingOverflow(right)
            : left.addingReportingOverflow(right)
        if !result.overflow {
            var flags: CMTimeFlags = .valid
            if lhs.hasBeenRounded || rhs.hasBeenRounded {
                flags.insert(.hasBeenRounded)
            }
            return CMTime(
                value: result.partialValue,
                timescale: CMTimeScale(scale64),
                flags: flags,
                epoch: lhs.epoch
            )
        }
    }

    let seconds = subtract
        ? lhs.seconds - rhs.seconds
        : lhs.seconds + rhs.seconds
    var result = CMTimeMakeWithSeconds(
        seconds,
        preferredTimescale: max(lhs.timescale, rhs.timescale)
    )
    result.epoch = lhs.epoch
    result.flags.insert(.hasBeenRounded)
    return result
}

public func CMTimeMultiply(_ time: CMTime, multiplier: Int32) -> CMTime {
    guard time.isNumeric else { return time }
    let (value, overflow) = time.value.multipliedReportingOverflow(
        by: Int64(multiplier)
    )
    if !overflow {
        return CMTime(
            value: value,
            timescale: time.timescale,
            flags: time.flags,
            epoch: time.epoch
        )
    }
    var result = CMTimeMakeWithSeconds(
        time.seconds * Double(multiplier),
        preferredTimescale: time.timescale
    )
    result.epoch = time.epoch
    result.flags.insert(.hasBeenRounded)
    return result
}

public func CMTimeMultiplyByRatio(
    _ time: CMTime,
    multiplier: Int32,
    divisor: Int32
) -> CMTime {
    guard divisor != 0, time.isNumeric else { return .invalid }
    var result = CMTimeMakeWithSeconds(
        time.seconds * Double(multiplier) / Double(divisor),
        preferredTimescale: time.timescale
    )
    result.epoch = time.epoch
    if time.hasBeenRounded { result.flags.insert(.hasBeenRounded) }
    return result
}

public func CMTimeConvertScale(
    _ time: CMTime,
    timescale newTimescale: CMTimeScale,
    method: CMTimeRoundingMethod
) -> CMTime {
    guard time.isNumeric, newTimescale > 0 else { return .invalid }
    let exact = time.seconds * Double(newTimescale)
    let rounded: Double
    switch method {
    case .roundTowardZero:
        rounded = exact.rounded(.towardZero)
    case .roundAwayFromZero:
        rounded = exact.rounded(exact.sign == .minus ? .down : .up)
    case .roundTowardPositiveInfinity:
        rounded = exact.rounded(.up)
    case .roundTowardNegativeInfinity:
        rounded = exact.rounded(.down)
    case .quickTime:
        rounded = exact.rounded(
            newTimescale < time.timescale
                ? .towardZero
                : (exact.sign == .minus ? .down : .up)
        )
    case .roundHalfAwayFromZero:
        rounded = exact.rounded(.toNearestOrAwayFromZero)
    }
    guard rounded <= Double(Int64.max), rounded >= Double(Int64.min) else {
        return rounded.sign == .minus ? .negativeInfinity : .positiveInfinity
    }
    var flags = time.flags
    if rounded != exact { flags.insert(.hasBeenRounded) }
    return CMTime(
        value: Int64(rounded),
        timescale: newTimescale,
        flags: flags,
        epoch: time.epoch
    )
}

private func _cmGCD(_ a: Int64, _ b: Int64) -> Int64 {
    var x = abs(a)
    var y = abs(b)
    while y != 0 {
        (x, y) = (y, x % y)
    }
    return max(1, x)
}

public struct CMTimeRange: Hashable, Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public static let zero = CMTimeRange(start: .zero, duration: .zero)
    public static let invalid = CMTimeRange(start: .invalid, duration: .invalid)

    public var isValid: Bool {
        start.isValid && duration.isValid && duration.epoch == 0
            && (!duration.isNumeric || duration.value >= 0)
    }
    public var isEmpty: Bool {
        isValid && duration.isNumeric && CMTimeCompare(duration, .zero) == 0
    }
    public var isIndefinite: Bool {
        isValid && (start.isIndefinite || duration.isIndefinite)
    }
    public var end: CMTime { CMTimeAdd(start, duration) }
    public func containsTime(_ time: CMTime) -> Bool {
        CMTimeRangeContainsTime(self, time: time)
    }
}

public let kCMTimeRangeZero = CMTimeRange.zero
public let kCMTimeRangeInvalid = CMTimeRange.invalid

public func CMTimeRangeMake(
    start: CMTime,
    duration: CMTime
) -> CMTimeRange {
    let range = CMTimeRange(start: start, duration: duration)
    return range.isValid ? range : .invalid
}

public func CMTimeRangeGetEnd(_ range: CMTimeRange) -> CMTime {
    range.isValid ? range.end : .invalid
}

public func CMTimeRangeContainsTime(
    _ range: CMTimeRange,
    time: CMTime
) -> Bool {
    guard range.isValid, time.isNumeric,
          CMTimeCompare(time, range.start) >= 0 else { return false }
    if range.duration.isPositiveInfinity { return true }
    return CMTimeCompare(time, range.end) < 0
}

public func CMTimeRangeContainsTimeRange(
    _ range: CMTimeRange,
    otherRange: CMTimeRange
) -> Bool {
    guard range.isValid, otherRange.isValid else { return false }
    return CMTimeCompare(otherRange.start, range.start) >= 0
        && CMTimeCompare(otherRange.end, range.end) <= 0
}

public func CMTimeRangeGetIntersection(
    _ range: CMTimeRange,
    otherRange: CMTimeRange
) -> CMTimeRange {
    guard range.isValid, otherRange.isValid,
          range.start.epoch == otherRange.start.epoch else { return .invalid }
    let start = max(range.start, otherRange.start)
    let end = min(range.end, otherRange.end)
    guard CMTimeCompare(end, start) >= 0 else {
        return CMTimeRange(start: start, duration: .zero)
    }
    return CMTimeRange(start: start, duration: CMTimeSubtract(end, start))
}

public func CMTimeRangeGetUnion(
    _ range: CMTimeRange,
    otherRange: CMTimeRange
) -> CMTimeRange {
    guard range.isValid, otherRange.isValid,
          range.start.epoch == otherRange.start.epoch else { return .invalid }
    let start = min(range.start, otherRange.start)
    let end = max(range.end, otherRange.end)
    return CMTimeRange(start: start, duration: CMTimeSubtract(end, start))
}
