import CoreMedia
import Foundation

/// Exercises Foundation's generic `sorted(using:)`, sequence-of-comparators
/// `sorted(using:)`, and `formatted(_:)` witnesses for the three byte hosts
/// (`CMReadOnlyDataBlockBuffer` and both `BlockRegion` types) and
/// `CMBufferQueue.Buffers`. The documented way to call these members is with
/// caller-supplied comparators and styles, so these test-only types pin a
/// deterministic numeric ordering and rendering without changing product API.
/// Follows the `FoundationComparatorTests` pattern used by sibling lanes.
/// Synchronous; no queues, no run loop, no waiting.

// Orders bytes numerically, honoring `order`.
struct CMByteOrderComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: UInt8, _ rhs: UInt8) -> ComparisonResult {
        let result: ComparisonResult
        if lhs < rhs {
            result = .orderedAscending
        } else if lhs > rhs {
            result = .orderedDescending
        } else {
            result = .orderedSame
        }
        guard order == .reverse, result != .orderedSame else { return result }
        return result == .orderedAscending ? .orderedDescending : .orderedAscending
    }
}

// Renders each byte host as a comma-joined value list.
struct CMReadOnlyBytesStyle: FormatStyle {
    func format(_ value: CMReadOnlyDataBlockBuffer) -> String {
        value.map(String.init).joined(separator: ",")
    }
}

struct CMReadOnlyRegionStyle: FormatStyle {
    func format(_ value: CMReadOnlyDataBlockBuffer.BlockRegion) -> String {
        value.map(String.init).joined(separator: ",")
    }
}

struct CMMutableRegionStyle: FormatStyle {
    func format(_ value: CMMutableDataBlockBuffer.BlockRegion) -> String {
        value.map(String.init).joined(separator: ",")
    }
}

// Orders queue buffers by presentation timestamp, honoring `order`.
struct CMBufferPTSComparator: SortComparator {
    var order: SortOrder = .forward

    private func stamp(of buffer: CMBuffer) -> CMTime {
        (buffer as? CMSampleBuffer)?.presentationTimeStamp ?? .invalid
    }

    func compare(_ lhs: CMBuffer, _ rhs: CMBuffer) -> ComparisonResult {
        let result: ComparisonResult
        switch CMTimeCompare(stamp(of: lhs), stamp(of: rhs)) {
        case ..<0: result = .orderedAscending
        case 1...: result = .orderedDescending
        default: result = .orderedSame
        }
        guard order == .reverse, result != .orderedSame else { return result }
        return result == .orderedAscending ? .orderedDescending : .orderedAscending
    }
}

// Renders queue buffers as their presentation-timestamp values.
struct CMBuffersPTSStyle: FormatStyle {
    func format(_ value: CMBufferQueue.Buffers) -> [Int64] {
        value.map { ($0 as? CMSampleBuffer)?.presentationTimeStamp.value ?? -1 }
    }
}

private func cmSortedBytesSample() -> (
    CMReadOnlyDataBlockBuffer,
    CMReadOnlyDataBlockBuffer.BlockRegion,
    CMMutableDataBlockBuffer.BlockRegion
) {
    let readOnly = CMReadOnlyDataBlockBuffer(Data([3, 1, 2]))
    let readRegion = readOnly.regions[0]
    var mutable = CMMutableDataBlockBuffer(count: 3)
    mutable[0] = 3
    mutable[1] = 1
    mutable[2] = 2
    let mutableRegion = mutable.withUnsafeMutableBlockRegions { $0[0] }
    return (readOnly, readRegion, mutableRegion)
}

private func cmSortedQueueSample() -> CMBufferQueue {
    let queue = CMBufferQueue(capacity: 8, handlers: .unsortedSampleBuffers)
    for pts in [14, 10, 12] as [Int64] {
        let timing = CMSampleTimingInfo(
            duration: CMTime(value: 2, timescale: 1),
            presentationTimeStamp: CMTime(value: pts, timescale: 1),
            decodeTimeStamp: .invalid
        )
        let sample = try! CMSampleBuffer(
            dataBuffer: CMBlockBuffer(data: Data(repeating: 7, count: 4)),
            formatDescription: nil,
            numSamples: 1,
            sampleTimings: [timing],
            sampleSizes: [4],
            dataReady: true
        )
        try! queue.enqueue(sample)
    }
    return queue
}

func testCMDataBlockBufferSortedUsingComparators() {
    let (readOnly, readRegion, mutableRegion) = cmSortedBytesSample()

    let sortedReadOnly = readOnly.sorted(using: CMByteOrderComparator())
    precondition(sortedReadOnly == [1, 2, 3], "read-only sorted(using:)")
    precondition(Array(readOnly) == [3, 1, 2], "sorted(using:) does not mutate")
    let sortedReadRegion = readRegion.sorted(using: CMByteOrderComparator())
    precondition(sortedReadRegion == [1, 2, 3], "read region sorted(using:)")
    let sortedMutableRegion = mutableRegion.sorted(using: CMByteOrderComparator())
    precondition(sortedMutableRegion == [1, 2, 3], "mutable region sorted(using:)")

    let reversedReadOnly = readOnly.sorted(using: CMByteOrderComparator(order: .reverse))
    precondition(reversedReadOnly == [3, 2, 1], "read-only sorted(using:) reverse")
    let reversedReadRegion = readRegion.sorted(using: CMByteOrderComparator(order: .reverse))
    precondition(reversedReadRegion == [3, 2, 1], "read region sorted(using:) reverse")
    let reversedMutableRegion = mutableRegion.sorted(using: CMByteOrderComparator(order: .reverse))
    precondition(reversedMutableRegion == [3, 2, 1], "mutable region sorted(using:) reverse")

    let seqReadOnly = readOnly.sorted(using: [CMByteOrderComparator(order: .reverse)])
    precondition(seqReadOnly == [3, 2, 1], "read-only sorted(using:) sequence")
    let seqReadRegion = readRegion.sorted(using: [CMByteOrderComparator(order: .reverse)])
    precondition(seqReadRegion == [3, 2, 1], "read region sorted(using:) sequence")
    let seqMutableRegion = mutableRegion.sorted(using: [CMByteOrderComparator(order: .reverse)])
    precondition(seqMutableRegion == [3, 2, 1], "mutable region sorted(using:) sequence")

    let unchangedReadOnly = readOnly.sorted(using: [CMByteOrderComparator]())
    precondition(unchangedReadOnly == [3, 1, 2], "empty comparator sequence preserves order")
    let unchangedReadRegion = readRegion.sorted(using: [CMByteOrderComparator]())
    precondition(unchangedReadRegion == [3, 1, 2], "read region empty sequence preserves order")
    let unchangedMutableRegion = mutableRegion.sorted(using: [CMByteOrderComparator]())
    precondition(unchangedMutableRegion == [3, 1, 2], "mutable region empty sequence preserves order")
}

func testCMDataBlockBufferFormattedStyles() {
    let (readOnly, readRegion, mutableRegion) = cmSortedBytesSample()
    precondition(readOnly.formatted(CMReadOnlyBytesStyle()) == "3,1,2", "read-only formatted")
    precondition(readRegion.formatted(CMReadOnlyRegionStyle()) == "3,1,2", "read region formatted")
    precondition(mutableRegion.formatted(CMMutableRegionStyle()) == "3,1,2", "mutable region formatted")
}

func testCMBufferQueueBuffersSortedAndFormatted() {
    let queue = cmSortedQueueSample()
    let buffers = queue.buffers

    let sorted = buffers.sorted(using: CMBufferPTSComparator())
    let sortedPTS = sorted.map { ($0 as? CMSampleBuffer)?.presentationTimeStamp.value ?? -1 }
    precondition(sortedPTS == [10, 12, 14], "buffers sorted(using:) by PTS")
    let insertionPTS = buffers.map { ($0 as? CMSampleBuffer)?.presentationTimeStamp.value ?? -1 }
    precondition(insertionPTS == [14, 10, 12], "sorted(using:) does not mutate")

    let reversed = buffers.sorted(using: [CMBufferPTSComparator(order: .reverse)])
    let reversedPTS = reversed.map { ($0 as? CMSampleBuffer)?.presentationTimeStamp.value ?? -1 }
    precondition(reversedPTS == [14, 12, 10], "buffers sorted(using:) sequence reverse")

    precondition(buffers.formatted(CMBuffersPTSStyle()) == [14, 10, 12], "buffers formatted")
}
