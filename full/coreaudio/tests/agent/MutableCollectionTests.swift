import CoreAudio
import Foundation

func testMutableSwapAt() {
    withBufferList([1, 2]) { list in
        list.swapAt(0, 1)
        coreAudioExpect(list.map(\.mNumberChannels) == [2, 1], "buffer swapAt")
    }
    withChannelLayout([8, 9]) { layout in
        layout.swapAt(0, 1)
        coreAudioExpect(layout.map(\.mChannelLabel) == [9, 8], "mutable layout swapAt")
    }
    var managed = makeManagedLayout([4, 5])
    managed.channelDescriptions.swapAt(0, 1)
    coreAudioExpect(managed.channelDescriptions.map(\.mChannelLabel) == [5, 4], "managed swapAt")
}

func testMutableReverse() {
    withBufferList([1, 2, 3]) { list in
        list.reverse()
        coreAudioExpect(list.map(\.mNumberChannels) == [3, 2, 1], "buffer reverse")
    }
    withChannelLayout([8, 9, 10]) { layout in
        layout.reverse()
        coreAudioExpect(layout.map(\.mChannelLabel) == [10, 9, 8], "mutable layout reverse")
    }
    var managed = makeManagedLayout([4, 5, 6])
    managed.channelDescriptions.reverse()
    coreAudioExpect(managed.channelDescriptions.map(\.mChannelLabel) == [6, 5, 4], "managed reverse")
}

func testMutableSortBy() {
    withBufferList([3, 1, 2]) { list in
        list.sort(by: { $0.mNumberChannels < $1.mNumberChannels })
        coreAudioExpect(list.map(\.mNumberChannels) == [1, 2, 3], "buffer sort(by:)")
    }
    withChannelLayout([10, 8, 9]) { layout in
        layout.sort(by: { $0.mChannelLabel < $1.mChannelLabel })
        coreAudioExpect(layout.map(\.mChannelLabel) == [8, 9, 10], "mutable layout sort(by:)")
    }
    var managed = makeManagedLayout([6, 4, 5])
    managed.channelDescriptions.sort(by: { $0.mChannelLabel < $1.mChannelLabel })
    coreAudioExpect(managed.channelDescriptions.map(\.mChannelLabel) == [4, 5, 6], "managed sort(by:)")
}

func testMutablePartition() {
    withBufferList([1, 4, 2, 5]) { list in
        let pivot = list.partition(by: { $0.mNumberChannels >= 4 })
        coreAudioExpect(pivot == 2, "buffer partition pivot")
        coreAudioExpect(list[..<pivot].allSatisfy { $0.mNumberChannels < 4 }, "buffer partition low")
        coreAudioExpect(list[pivot...].allSatisfy { $0.mNumberChannels >= 4 }, "buffer partition high")
    }
    withChannelLayout([1, 9, 2, 8]) { layout in
        let pivot = layout.partition(by: { $0.mChannelLabel >= 8 })
        coreAudioExpect(layout[..<pivot].allSatisfy { $0.mChannelLabel < 8 }, "mutable partition low")
        coreAudioExpect(layout[pivot...].allSatisfy { $0.mChannelLabel >= 8 }, "mutable partition high")
    }
    var managed = makeManagedLayout([1, 9, 2, 8])
    let pivot = managed.channelDescriptions.partition(by: { $0.mChannelLabel >= 8 })
    coreAudioExpect(
        managed.channelDescriptions[..<pivot].allSatisfy { $0.mChannelLabel < 8 },
        "managed partition low"
    )
}

func testMutableShuffleUsing() {
    withBufferList([1, 2, 3, 4]) { list in
        var generator = CoreAudioLCG(seed: 7)
        list.shuffle(using: &generator)
        coreAudioExpect(Set(list.map(\.mNumberChannels)) == [1, 2, 3, 4], "buffer shuffle(using:) preserves members")
    }
    withChannelLayout([8, 9, 10, 11]) { layout in
        var generator = CoreAudioLCG(seed: 11)
        layout.shuffle(using: &generator)
        coreAudioExpect(Set(layout.map(\.mChannelLabel)) == [8, 9, 10, 11], "layout shuffle(using:)")
    }
    var managed = makeManagedLayout([4, 5, 6, 7])
    var generator = CoreAudioLCG(seed: 13)
    managed.channelDescriptions.shuffle(using: &generator)
    coreAudioExpect(Set(managed.channelDescriptions.map(\.mChannelLabel)) == [4, 5, 6, 7], "managed shuffle(using:)")
}

func testMutableShuffle() {
    withBufferList([1, 2, 3, 4]) { list in
        list.shuffle()
        coreAudioExpect(Set(list.map(\.mNumberChannels)) == [1, 2, 3, 4], "buffer shuffle")
    }
    withChannelLayout([8, 9, 10]) { layout in
        layout.shuffle()
        coreAudioExpect(Set(layout.map(\.mChannelLabel)) == [8, 9, 10], "layout shuffle")
    }
    var managed = makeManagedLayout([4, 5, 6])
    managed.channelDescriptions.shuffle()
    coreAudioExpect(Set(managed.channelDescriptions.map(\.mChannelLabel)) == [4, 5, 6], "managed shuffle")
}

func testMutableMoveSubranges() {
    withBufferList([1, 2, 3, 4]) { list in
        var ranges = RangeSet<Int>()
        ranges.insert(contentsOf: 0..<1)
        _ = list.moveSubranges(ranges, to: 3)
        coreAudioExpect(Set(list.map(\.mNumberChannels)) == [1, 2, 3, 4], "buffer moveSubranges preserves members")
    }
    withChannelLayout([8, 9, 10, 11]) { layout in
        var ranges = RangeSet<Int>()
        ranges.insert(contentsOf: 2..<4)
        _ = layout.moveSubranges(ranges, to: 0)
        coreAudioExpect(Set(layout.map(\.mChannelLabel)) == [8, 9, 10, 11], "layout moveSubranges")
    }
    var managed = makeManagedLayout([4, 5, 6, 7])
    var ranges = RangeSet<Int>()
    ranges.insert(contentsOf: 1..<2)
    _ = managed.channelDescriptions.moveSubranges(ranges, to: 3)
    coreAudioExpect(Set(managed.channelDescriptions.map(\.mChannelLabel)) == [4, 5, 6, 7], "managed moveSubranges")
}
