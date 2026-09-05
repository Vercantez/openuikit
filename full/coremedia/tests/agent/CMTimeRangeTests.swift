import CoreFoundation
import CoreMedia
import Foundation

func testCMTimeRangeMakeAndEnd() {
    let start = CMTime(value: 1, timescale: 1)
    let duration = CMTime(value: 2, timescale: 1)
    let range = CMTimeRangeMake(start: start, duration: duration)
    precondition(range.isValid)
    precondition(!range.isEmpty)
    precondition(CMTimeRangeGetEnd(range) == CMTime(value: 3, timescale: 1))
    precondition(range.end == CMTime(value: 3, timescale: 1))
    precondition(CMTimeRangeContainsTime(range, time: CMTime(value: 2, timescale: 1)))
    precondition(range.containsTime(CMTime(value: 2, timescale: 1)))
    precondition(!range.containsTime(CMTime(value: 3, timescale: 1)))
    precondition(!range.containsTime(CMTime(value: 0, timescale: 1)))
}

func testCMTimeRangeFromStartEnd() {
    let range = CMTimeRange(start: .zero, end: CMTime(value: 4, timescale: 1))
    precondition(range.duration == CMTime(value: 4, timescale: 1))
    let viaFunc = CMTimeRangeFromTimeToTime(start: .zero, end: CMTime(value: 4, timescale: 1))
    precondition(CMTimeRangeEqual(range, viaFunc))
}

func testCMTimeRangeEmptyInvalid() {
    precondition(CMTimeRange.zero.isEmpty)
    precondition(CMTimeRange.zero.isValid)
    precondition(!CMTimeRange.invalid.isValid)
    let negative = CMTimeRange(
        start: .zero,
        duration: CMTime(value: -1, timescale: 1)
    )
    precondition(!negative.isValid)
}

func testCMTimeRangeIntersectionUnion() {
    let a = CMTimeRange(start: .zero, duration: CMTime(value: 10, timescale: 1))
    let b = CMTimeRange(
        start: CMTime(value: 5, timescale: 1),
        duration: CMTime(value: 10, timescale: 1)
    )
    let inter = CMTimeRangeGetIntersection(a, otherRange: b)
    precondition(inter.start == CMTime(value: 5, timescale: 1))
    precondition(inter.duration == CMTime(value: 5, timescale: 1))
    precondition(a.intersection(b) == inter)
    let uni = CMTimeRangeGetUnion(a, otherRange: b)
    precondition(uni.start == .zero)
    precondition(uni.end == CMTime(value: 15, timescale: 1))
    precondition(a.union(b) == uni)
    precondition(CMTimeRangeContainsTimeRange(a, otherRange: inter))
    precondition(a.containsTimeRange(inter))
    precondition(!CMTimeRangeContainsTimeRange(a, otherRange: b))
    precondition(CMTimeRangeEqual(a, a))
    precondition(a != b)
}

func testCMTimeRangeDictionaryRoundTrip() {
    let range = CMTimeRange(
        start: CMTime(value: 2, timescale: 1),
        duration: CMTime(value: 3, timescale: 1)
    )
    let dict = CMTimeRangeCopyAsDictionary(range, allocator: nil)!
    let restored = CMTimeRangeMakeFromDictionary(dict)
    precondition(restored == range)
}

func testCMTimeMappingMake() {
    let source = CMTimeRange(start: .zero, duration: CMTime(value: 1, timescale: 1))
    let target = CMTimeRange(
        start: CMTime(value: 10, timescale: 1),
        duration: CMTime(value: 2, timescale: 1)
    )
    let mapping = CMTimeMappingMake(source: source, target: target)
    precondition(mapping.source == source)
    precondition(mapping.target == target)
    let empty = CMTimeMappingMakeEmpty(target: target)
    precondition(empty.source.isEmpty || empty.source == .zero)
    precondition(CMTimeMapping.invalid.source == .invalid)
    let dict = CMTimeMappingCopyAsDictionary(mapping, allocator: nil)!
    let restored = CMTimeMappingMakeFromDictionary(dict)
    precondition(restored.source == mapping.source)
    precondition(restored.target == mapping.target)
}

func testCMSampleTimingInfoFields() {
    let info = CMSampleTimingInfo(
        duration: CMTime(value: 1, timescale: 30),
        presentationTimeStamp: CMTime(value: 10, timescale: 30),
        decodeTimeStamp: .invalid
    )
    precondition(info.duration.timescale == 30)
    precondition(info.presentationTimeStamp.value == 10)
    precondition(!info.decodeTimeStamp.isValid)
    let zero = CMSampleTimingInfo()
    precondition(!zero.duration.isValid)
    precondition(!CMSampleTimingInfo.invalid.duration.isValid)
}

func testCMVideoDimensionsFields() {
    let dim = CMVideoDimensions(width: 1920, height: 1080)
    precondition(dim.width == 1920)
    precondition(dim.height == 1080)
    let empty = CMVideoDimensions()
    precondition(empty.width == 0)
    precondition(empty.height == 0)
}
