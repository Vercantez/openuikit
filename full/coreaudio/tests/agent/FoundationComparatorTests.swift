import CoreAudio
import Foundation

// MARK: - Custom Foundation comparators and styles
//
// The sealed overlay records Foundation's generic `sort(using:)`,
// `sorted(using:)`, and `formatted(_:)` members for the CoreAudio overlay
// collections. The documented way to exercise them is with caller-supplied
// comparators and styles, so these test-only types pin deterministic
// orderings and renderings without changing product API.

// Orders AudioBuffers by channel count, then byte size.
struct CoreAudioBufferChannelComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: AudioBuffer, _ rhs: AudioBuffer) -> ComparisonResult {
        let result: ComparisonResult
        if lhs.mNumberChannels != rhs.mNumberChannels {
            result = lhs.mNumberChannels < rhs.mNumberChannels ? .orderedAscending : .orderedDescending
        } else if lhs.mDataByteSize != rhs.mDataByteSize {
            result = lhs.mDataByteSize < rhs.mDataByteSize ? .orderedAscending : .orderedDescending
        } else {
            result = .orderedSame
        }
        guard order == .reverse, result != .orderedSame else { return result }
        return result == .orderedAscending ? .orderedDescending : .orderedAscending
    }
}

// Orders AudioChannelDescriptions by channel label.
struct CoreAudioChannelLabelComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: AudioChannelDescription, _ rhs: AudioChannelDescription) -> ComparisonResult {
        let result: ComparisonResult
        if lhs.mChannelLabel == rhs.mChannelLabel {
            result = .orderedSame
        } else if lhs.mChannelLabel < rhs.mChannelLabel {
            result = .orderedAscending
        } else {
            result = .orderedDescending
        }
        guard order == .reverse, result != .orderedSame else { return result }
        return result == .orderedAscending ? .orderedDescending : .orderedAscending
    }
}

// Renders each overlay collection as its channel counts or labels.
struct CoreAudioBufferListCountsStyle: FormatStyle {
    func format(_ value: UnsafeMutableAudioBufferListPointer) -> [UInt32] {
        value.map(\.mNumberChannels)
    }
}

struct CoreAudioMutableLayoutLabelsStyle: FormatStyle {
    func format(_ value: AudioChannelLayout.UnsafeMutablePointer) -> [AudioChannelLabel] {
        value.map(\.mChannelLabel)
    }
}

struct CoreAudioLayoutLabelsStyle: FormatStyle {
    func format(_ value: AudioChannelLayout.UnsafePointer) -> [AudioChannelLabel] {
        value.map(\.mChannelLabel)
    }
}

struct CoreAudioManagedLabelsStyle: FormatStyle {
    func format(_ value: ManagedAudioChannelLayout.ChannelDescriptions) -> [AudioChannelLabel] {
        value.map(\.mChannelLabel)
    }
}

func testSortUsingComparator() {
    withBufferList([3, 1, 2]) { list in
        list.sort(using: CoreAudioBufferChannelComparator())
        coreAudioExpect(list.map(\.mNumberChannels) == [1, 2, 3], "buffer sort(using:)")
    }
    withChannelLayout([10, 8, 9]) { layout in
        layout.sort(using: CoreAudioChannelLabelComparator())
        coreAudioExpect(layout.map(\.mChannelLabel) == [8, 9, 10], "mutable layout sort(using:)")
    }
    var managed = makeManagedLayout([6, 4, 5])
    managed.channelDescriptions.sort(using: CoreAudioChannelLabelComparator())
    coreAudioExpect(managed.channelDescriptions.map(\.mChannelLabel) == [4, 5, 6], "managed sort(using:)")
}

func testSortUsingComparatorSequence() {
    withBufferList([2, 3, 1]) { list in
        list.sort(using: [CoreAudioBufferChannelComparator(order: .reverse)])
        coreAudioExpect(list.map(\.mNumberChannels) == [3, 2, 1], "buffer sort(using:) sequence")
        let snapshot = list.map(\.mNumberChannels)
        list.sort(using: [CoreAudioBufferChannelComparator]())
        coreAudioExpect(list.map(\.mNumberChannels) == snapshot, "empty comparator sequence preserves order")
    }
    withChannelLayout([7, 9, 8]) { layout in
        layout.sort(using: [CoreAudioChannelLabelComparator(order: .reverse)])
        coreAudioExpect(layout.map(\.mChannelLabel) == [9, 8, 7], "mutable layout sort(using:) sequence")
    }
    var managed = makeManagedLayout([11, 13, 12])
    managed.channelDescriptions.sort(using: [CoreAudioChannelLabelComparator(order: .reverse)])
    coreAudioExpect(managed.channelDescriptions.map(\.mChannelLabel) == [13, 12, 11], "managed sort(using:) sequence")
}

func testSortedUsingComparator() {
    withBufferList([3, 1, 2]) { list in
        let sorted = list.sorted(using: CoreAudioBufferChannelComparator())
        coreAudioExpect(sorted.map(\.mNumberChannels) == [1, 2, 3], "buffer sorted(using:)")
        coreAudioExpect(list.map(\.mNumberChannels) == [3, 1, 2], "sorted(using:) does not mutate")
    }
    withChannelLayout([9, 7, 8]) { layout in
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        let sortedImmutable = immutable.sorted(using: CoreAudioChannelLabelComparator())
        coreAudioExpect(sortedImmutable.map(\.mChannelLabel) == [7, 8, 9], "immutable sorted(using:)")
        let sortedMutable = layout.sorted(using: CoreAudioChannelLabelComparator())
        coreAudioExpect(sortedMutable.map(\.mChannelLabel) == [7, 8, 9], "mutable sorted(using:)")
    }
    let managed = makeManagedLayout([5, 3, 4])
    let sortedManaged = managed.channelDescriptions.sorted(using: CoreAudioChannelLabelComparator())
    coreAudioExpect(sortedManaged.map(\.mChannelLabel) == [3, 4, 5], "managed sorted(using:)")
}

func testSortedUsingComparatorSequence() {
    withBufferList([1, 3, 2]) { list in
        let sorted = list.sorted(using: [CoreAudioBufferChannelComparator(order: .reverse)])
        coreAudioExpect(sorted.map(\.mNumberChannels) == [3, 2, 1], "buffer sorted(using:) sequence")
        let unchanged = list.sorted(using: [CoreAudioBufferChannelComparator]())
        coreAudioExpect(unchanged.map(\.mNumberChannels) == [1, 3, 2], "empty comparator sequence preserves order")
    }
    withChannelLayout([4, 6, 5]) { layout in
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        let sortedImmutable = immutable.sorted(using: [CoreAudioChannelLabelComparator(order: .reverse)])
        coreAudioExpect(sortedImmutable.map(\.mChannelLabel) == [6, 5, 4], "immutable sorted(using:) sequence")
        let sortedMutable = layout.sorted(using: [CoreAudioChannelLabelComparator(order: .reverse)])
        coreAudioExpect(sortedMutable.map(\.mChannelLabel) == [6, 5, 4], "mutable sorted(using:) sequence")
    }
    let managed = makeManagedLayout([2, 1, 3])
    let sortedManaged = managed.channelDescriptions.sorted(using: [CoreAudioChannelLabelComparator(order: .reverse)])
    coreAudioExpect(sortedManaged.map(\.mChannelLabel) == [3, 2, 1], "managed sorted(using:) sequence")
}

func testFormattedWithCustomStyle() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.formatted(CoreAudioBufferListCountsStyle()) == [2, 1], "buffer formatted")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(
            layout.formatted(CoreAudioMutableLayoutLabelsStyle()) == [8, 9],
            "mutable layout formatted"
        )
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        coreAudioExpect(
            immutable.formatted(CoreAudioLayoutLabelsStyle()) == [8, 9],
            "immutable layout formatted"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.formatted(CoreAudioManagedLabelsStyle()) == [4, 5],
        "managed formatted"
    )
}
