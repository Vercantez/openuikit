import CoreAudio
import Foundation

func testCollectionReduce() {
    withBufferList([2, 1, 4]) { list in
        coreAudioExpect(list.reduce(UInt32(0)) { $0 + $1.mNumberChannels } == 7, "buffer reduce")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.reduce(UInt32(0)) { $0 + $1.mChannelLabel } == 17, "mutable reduce")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).reduce(UInt32(0)) { $0 + $1.mChannelLabel } == 17,
            "immutable reduce"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.reduce(UInt32(0)) { $0 + $1.mChannelLabel } == 9,
        "managed reduce"
    )
}

func testCollectionReduceInto() {
    withBufferList([2, 1]) { list in
        let total = list.reduce(into: UInt32(0)) { $0 += $1.mNumberChannels }
        coreAudioExpect(total == 3, "buffer reduce(into:)")
    }
    withChannelLayout([8, 9]) { layout in
        let mutableTotal = layout.reduce(into: UInt32(0)) { $0 += $1.mChannelLabel }
        let immutableTotal = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
            .reduce(into: UInt32(0)) { $0 += $1.mChannelLabel }
        coreAudioExpect(mutableTotal == 17 && immutableTotal == 17, "layout reduce(into:)")
    }
    let managedTotal = makeManagedLayout([4, 5]).channelDescriptions
        .reduce(into: UInt32(0)) { $0 += $1.mChannelLabel }
    coreAudioExpect(managedTotal == 9, "managed reduce(into:)")
}

func testCollectionAllSatisfy() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.allSatisfy { $0.mNumberChannels > 0 }, "buffer allSatisfy true")
        coreAudioExpect(!list.allSatisfy { $0.mNumberChannels == 2 }, "buffer allSatisfy false")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.allSatisfy { $0.mChannelLabel >= 8 }, "mutable allSatisfy")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).allSatisfy { $0.mChannelLabel < 10 },
            "immutable allSatisfy"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.allSatisfy { $0.mChannelLabel > 3 },
        "managed allSatisfy"
    )
}

func testCollectionCountWhere() {
    withBufferList([2, 1, 2]) { list in
        coreAudioExpect(list.count(where: { $0.mNumberChannels == 2 }) == 2, "buffer count(where:)")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.count(where: { $0.mChannelLabel == 8 }) == 2, "mutable count(where:)")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).count(where: { $0.mChannelLabel == 9 }) == 1,
            "immutable count(where:)"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5, 4]).channelDescriptions.count(where: { $0.mChannelLabel == 4 }) == 2,
        "managed count(where:)"
    )
}
