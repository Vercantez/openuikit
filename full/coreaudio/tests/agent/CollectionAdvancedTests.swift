import CoreAudio
import Foundation

func testCollectionLazy() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(Array(list.lazy.map(\.mNumberChannels)) == [2, 1], "buffer lazy")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(Array(layout.lazy.map(\.mChannelLabel)) == [8, 9], "mutable lazy")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).lazy.map(\.mChannelLabel)) == [8, 9],
            "immutable lazy"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5]).channelDescriptions.lazy.map(\.mChannelLabel)) == [4, 5],
        "managed lazy"
    )
}

func testCollectionIndicesWhere() {
    withBufferList([2, 1, 2]) { list in
        let ranges = list.indices(where: { $0.mNumberChannels == 2 })
        coreAudioExpect(ranges.contains(0) && ranges.contains(2) && !ranges.contains(1), "buffer indices(where:)")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.indices(where: { $0.mChannelLabel == 8 }).contains(0), "mutable indices(where:)")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).indices(where: { $0.mChannelLabel == 9 }).contains(1),
            "immutable indices(where:)"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5, 4]).channelDescriptions.indices(where: { $0.mChannelLabel == 4 }).contains(2),
        "managed indices(where:)"
    )
}

func testCollectionRemovingSubranges() {
    withBufferList([1, 2, 3]) { list in
        var ranges = RangeSet<Int>()
        ranges.insert(contentsOf: 1..<2)
        coreAudioExpect(
            list.removingSubranges(ranges).map(\.mNumberChannels) == [1, 3],
            "buffer removingSubranges"
        )
    }
    withChannelLayout([8, 9, 10]) { layout in
        var ranges = RangeSet<Int>()
        ranges.insert(contentsOf: 0..<1)
        coreAudioExpect(layout.removingSubranges(ranges).map(\.mChannelLabel) == [9, 10], "mutable removingSubranges")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).removingSubranges(ranges).map(\.mChannelLabel) == [9, 10],
            "immutable removingSubranges"
        )
    }
    var ranges = RangeSet<Int>()
    ranges.insert(contentsOf: 1..<2)
    coreAudioExpect(
        makeManagedLayout([4, 5, 6]).channelDescriptions.removingSubranges(ranges).map(\.mChannelLabel) == [4, 6],
        "managed removingSubranges"
    )
}

func testCollectionTrimmingPrefix() {
    withBufferList([1, 1, 3]) { list in
        coreAudioExpect(
            Array(list.trimmingPrefix(while: { $0.mNumberChannels == 1 })).map(\.mNumberChannels) == [3],
            "buffer trimmingPrefix"
        )
    }
    withChannelLayout([8, 8, 9]) { layout in
        coreAudioExpect(
            Array(layout.trimmingPrefix(while: { $0.mChannelLabel == 8 })).map(\.mChannelLabel) == [9],
            "mutable trimmingPrefix"
        )
        coreAudioExpect(
            Array(
                AudioChannelLayout.UnsafePointer(layout.unsafePointer).trimmingPrefix(while: { $0.mChannelLabel == 8 })
            ).map(\.mChannelLabel) == [9],
            "immutable trimmingPrefix"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 4, 5]).channelDescriptions.trimmingPrefix(while: { $0.mChannelLabel == 4 }))
            .map(\.mChannelLabel) == [5],
        "managed trimmingPrefix"
    )
}

func testCollectionWithContiguousStorage() {
    withBufferList([1, 2]) { list in
        let count = list.withContiguousStorageIfAvailable { $0.count }
        coreAudioExpect(count == 2 || count == nil, "buffer contiguous storage is nil or count")
    }
    withChannelLayout([8, 9]) { layout in
        let mutableCount = layout.withContiguousStorageIfAvailable { $0.count }
        coreAudioExpect(mutableCount == 2 || mutableCount == nil, "mutable contiguous storage")
        let immutableCount = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
            .withContiguousStorageIfAvailable { $0.count }
        coreAudioExpect(immutableCount == 2 || immutableCount == nil, "immutable contiguous storage")
    }
    let managedCount = makeManagedLayout([4, 5]).channelDescriptions.withContiguousStorageIfAvailable { $0.count }
    coreAudioExpect(managedCount == 2 || managedCount == nil, "managed contiguous storage")
}

func testMutableWithContiguousMutableStorage() {
    withBufferList([1, 2]) { list in
        let count = list.withContiguousMutableStorageIfAvailable { $0.count }
        coreAudioExpect(count == 2 || count == nil, "buffer mutable contiguous storage")
    }
    withChannelLayout([8, 9]) { layout in
        let count = layout.withContiguousMutableStorageIfAvailable { $0.count }
        coreAudioExpect(count == 2 || count == nil, "layout mutable contiguous storage")
    }
    var managed = makeManagedLayout([4, 5])
    let count = managed.channelDescriptions.withContiguousMutableStorageIfAvailable { $0.count }
    coreAudioExpect(count == 2 || count == nil, "managed mutable contiguous storage")
}
