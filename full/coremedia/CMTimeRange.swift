import CoreFoundation
import Foundation

@frozen
public struct CMTimeRange: Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init() {
        self.start = .invalid
        self.duration = .invalid
    }

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public init(start: CMTime, end: CMTime) {
        self.start = start
        self.duration = CMTimeSubtract(end, start)
    }

    public static let invalid = CMTimeRange(start: .invalid, duration: .invalid)
    public static let zero = CMTimeRange(start: .zero, duration: .zero)

    public var isValid: Bool {
        start.isValid && duration.isValid && CMTimeCompare(duration, .zero) >= 0
    }

    public var isEmpty: Bool {
        isValid && CMTimeCompare(duration, .zero) == 0
    }

    public var isIndefinite: Bool {
        isValid && (start.isIndefinite || duration.isIndefinite)
    }

    public var end: CMTime { CMTimeRangeGetEnd(self) }

    public func containsTime(_ time: CMTime) -> Bool {
        CMTimeRangeContainsTime(self, time: time)
    }

    public func containsTimeRange(_ range: CMTimeRange) -> Bool {
        CMTimeRangeContainsTimeRange(self, otherRange: range)
    }

    public func intersection(_ otherRange: CMTimeRange) -> CMTimeRange {
        CMTimeRangeGetIntersection(self, otherRange: otherRange)
    }

    public func union(_ otherRange: CMTimeRange) -> CMTimeRange {
        CMTimeRangeGetUnion(self, otherRange: otherRange)
    }
}

extension CMTimeRange: Equatable {
    public static func == (range1: CMTimeRange, range2: CMTimeRange) -> Bool {
        CMTimeRangeEqual(range1, range2)
    }

    public static func != (range1: CMTimeRange, range2: CMTimeRange) -> Bool {
        !CMTimeRangeEqual(range1, range2)
    }
}

extension CMTimeRange: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(duration)
    }
}

public func CMTimeRangeMake(start: CMTime, duration: CMTime) -> CMTimeRange {
    CMTimeRange(start: start, duration: duration)
}

public func CMTimeRangeFromTimeToTime(start: CMTime, end: CMTime) -> CMTimeRange {
    CMTimeRange(start: start, end: end)
}

public func CMTimeRangeGetEnd(_ range: CMTimeRange) -> CMTime {
    CMTimeAdd(range.start, range.duration)
}

public func CMTimeRangeEqual(_ range1: CMTimeRange, _ range2: CMTimeRange) -> Bool {
    CMTimeCompare(range1.start, range2.start) == 0
        && CMTimeCompare(range1.duration, range2.duration) == 0
}

public func CMTimeRangeContainsTime(_ range: CMTimeRange, time: CMTime) -> Bool {
    guard range.isValid, time.isValid else { return false }
    if CMTimeCompare(time, range.start) < 0 { return false }
    if CMTimeCompare(time, range.end) >= 0 { return false }
    return true
}

public func CMTimeRangeContainsTimeRange(_ range: CMTimeRange, otherRange: CMTimeRange) -> Bool {
    guard range.isValid, otherRange.isValid else { return false }
    if CMTimeCompare(otherRange.start, range.start) < 0 { return false }
    if CMTimeCompare(otherRange.end, range.end) > 0 { return false }
    return true
}

public func CMTimeRangeGetIntersection(
    _ range: CMTimeRange,
    otherRange: CMTimeRange
) -> CMTimeRange {
    guard range.isValid, otherRange.isValid else { return .invalid }
    let start = CMTimeMaximum(range.start, otherRange.start)
    let end = CMTimeMinimum(range.end, otherRange.end)
    if CMTimeCompare(start, end) >= 0 {
        return CMTimeRange(start: start, duration: .zero)
    }
    return CMTimeRange(start: start, end: end)
}

public func CMTimeRangeGetUnion(_ range: CMTimeRange, otherRange: CMTimeRange) -> CMTimeRange {
    guard range.isValid, otherRange.isValid else { return .invalid }
    let start = CMTimeMinimum(range.start, otherRange.start)
    let end = CMTimeMaximum(range.end, otherRange.end)
    return CMTimeRange(start: start, end: end)
}

public func CMTimeRangeShow(_ range: CMTimeRange) {
    let line =
        "{\(cmTimeRangePart(range.start)), \(cmTimeRangePart(range.duration))}\n"
    FileHandle.standardError.write(Data(line.utf8))
}

public func CMTimeRangeCopyDescription(allocator: CFAllocator?, range: CMTimeRange) -> CFString? {
    _ = allocator
    return cmMakeCFString(
        "{\(cmTimeRangePart(range.start)), \(cmTimeRangePart(range.duration))}"
    )
}

public let kCMTimeRangeStartKey: CFString = cmMakeCFString("start")
public let kCMTimeRangeDurationKey: CFString = cmMakeCFString("duration")

public func CMTimeRangeCopyAsDictionary(
    _ range: CMTimeRange,
    allocator: CFAllocator?
) -> CFDictionary? {
    guard
        let start = CMTimeCopyAsDictionary(range.start, allocator: allocator),
        let duration = CMTimeCopyAsDictionary(range.duration, allocator: allocator)
    else {
        return nil
    }
    return cmCFDictionary([
        (kCMTimeRangeStartKey, start),
        (kCMTimeRangeDurationKey, duration)
    ])
}

public func CMTimeRangeMakeFromDictionary(_ dictionaryRepresentation: CFDictionary) -> CMTimeRange {
    func nested(_ key: CFString) -> CMTime {
        guard let raw = cmCFDictionaryValue(dictionaryRepresentation, key: key) else { return .invalid }
        return CMTimeMakeFromDictionary(unsafeBitCast(raw, to: CFDictionary.self))
    }
    return CMTimeRange(
        start: nested(kCMTimeRangeStartKey),
        duration: nested(kCMTimeRangeDurationKey)
    )
}

@frozen
public struct CMTimeMapping: Sendable, Equatable, Hashable {
    public var source: CMTimeRange
    public var target: CMTimeRange

    public init() {
        self.source = .invalid
        self.target = .invalid
    }

    public init(source: CMTimeRange, target: CMTimeRange) {
        self.source = source
        self.target = target
    }

    public static let invalid = CMTimeMapping(source: .invalid, target: .invalid)
}

public func CMTimeMappingMake(source: CMTimeRange, target: CMTimeRange) -> CMTimeMapping {
    CMTimeMapping(source: source, target: target)
}

public func CMTimeMappingMakeEmpty(target: CMTimeRange) -> CMTimeMapping {
    CMTimeMapping(source: .zero, target: target)
}

public func CMTimeMappingShow(_ mapping: CMTimeMapping) {
    FileHandle.standardError.write(
        Data("source=\(mapping.source.start.value) target=\(mapping.target.start.value)\n".utf8)
    )
}

public func CMTimeMappingCopyDescription(
    allocator: CFAllocator?,
    mapping: CMTimeMapping
) -> CFString? {
    _ = allocator
    return cmMakeCFString("CMTimeMapping")
}

public let kCMTimeMappingSourceKey: CFString = cmMakeCFString("source")
public let kCMTimeMappingTargetKey: CFString = cmMakeCFString("target")

public func CMTimeMappingCopyAsDictionary(
    _ mapping: CMTimeMapping,
    allocator: CFAllocator?
) -> CFDictionary? {
    guard
        let source = CMTimeRangeCopyAsDictionary(mapping.source, allocator: allocator),
        let target = CMTimeRangeCopyAsDictionary(mapping.target, allocator: allocator)
    else {
        return nil
    }
    return cmCFDictionary([
        (kCMTimeMappingSourceKey, source),
        (kCMTimeMappingTargetKey, target)
    ])
}

public func CMTimeMappingMakeFromDictionary(
    _ dictionaryRepresentation: CFDictionary
) -> CMTimeMapping {
    func nested(_ key: CFString) -> CMTimeRange {
        guard let raw = cmCFDictionaryValue(dictionaryRepresentation, key: key) else { return .invalid }
        return CMTimeRangeMakeFromDictionary(unsafeBitCast(raw, to: CFDictionary.self))
    }
    return CMTimeMapping(
        source: nested(kCMTimeMappingSourceKey),
        target: nested(kCMTimeMappingTargetKey)
    )
}

@frozen
public struct CMSampleTimingInfo: Sendable, Equatable, Hashable {
    public var duration: CMTime
    public var presentationTimeStamp: CMTime
    public var decodeTimeStamp: CMTime

    public init() {
        self.duration = .invalid
        self.presentationTimeStamp = .invalid
        self.decodeTimeStamp = .invalid
    }

    public init(duration: CMTime, presentationTimeStamp: CMTime, decodeTimeStamp: CMTime) {
        self.duration = duration
        self.presentationTimeStamp = presentationTimeStamp
        self.decodeTimeStamp = decodeTimeStamp
    }

    public static let invalid = CMSampleTimingInfo()
}

@frozen
public struct CMVideoDimensions: Sendable, Equatable, Hashable {
    public var width: Int32
    public var height: Int32

    public init() {
        self.width = 0
        self.height = 0
    }

    public init(width: Int32, height: Int32) {
        self.width = width
        self.height = height
    }
}

private func cmTimeRangePart(_ time: CMTime) -> String {
    if !time.isValid { return "invalid" }
    if time.isPositiveInfinity { return "+inf" }
    if time.isNegativeInfinity { return "-inf" }
    if time.isIndefinite { return "indefinite" }
    return "\(time.value)/\(time.timescale)"
}
