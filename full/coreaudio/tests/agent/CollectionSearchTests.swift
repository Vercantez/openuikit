import CoreAudio
import Foundation

func testCollectionContainsWhere() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.contains(where: { $0.mNumberChannels == 1 }), "buffer contains")
        coreAudioExpect(!list.contains(where: { $0.mNumberChannels == 9 }), "buffer contains false")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.contains(where: { $0.mChannelLabel == 9 }), "mutable contains")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).contains(where: { $0.mChannelLabel == 8 }),
            "immutable contains"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.contains(where: { $0.mChannelLabel == 5 }),
        "managed contains"
    )
}

func testCollectionFirstWhere() {
    withBufferList([2, 1, 2]) { list in
        coreAudioExpect(list.first(where: { $0.mNumberChannels == 1 })?.mNumberChannels == 1, "buffer first(where:)")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.first(where: { $0.mChannelLabel == 9 })?.mChannelLabel == 9, "mutable first(where:)")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).first(where: { $0.mChannelLabel == 8 })?.mChannelLabel == 8,
            "immutable first(where:)"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.first(where: { $0.mChannelLabel == 5 })?.mChannelLabel == 5,
        "managed first(where:)"
    )
}

func testCollectionLastWhere() {
    withBufferList([2, 1, 2]) { list in
        coreAudioExpect(list.last(where: { $0.mNumberChannels == 2 })?.mNumberChannels == 2, "buffer last(where:)")
        coreAudioExpect(list.last(where: { $0.mNumberChannels == 1 })?.mNumberChannels == 1, "buffer last(where:) middle")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.last(where: { $0.mChannelLabel == 8 })?.mChannelLabel == 8, "mutable last(where:)")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).last(where: { $0.mChannelLabel == 9 })?.mChannelLabel == 9,
            "immutable last(where:)"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5, 4]).channelDescriptions.last(where: { $0.mChannelLabel == 4 })?.mChannelLabel == 4,
        "managed last(where:)"
    )
}

func testCollectionFirstIndexWhere() {
    withBufferList([2, 1, 2]) { list in
        coreAudioExpect(list.firstIndex(where: { $0.mNumberChannels == 1 }) == 1, "buffer firstIndex")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.firstIndex(where: { $0.mChannelLabel == 9 }) == 1, "mutable firstIndex")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).firstIndex(where: { $0.mChannelLabel == 8 }) == 0,
            "immutable firstIndex"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.firstIndex(where: { $0.mChannelLabel == 5 }) == 1,
        "managed firstIndex"
    )
}

func testCollectionLastIndexWhere() {
    withBufferList([2, 1, 2]) { list in
        coreAudioExpect(list.lastIndex(where: { $0.mNumberChannels == 2 }) == 2, "buffer lastIndex")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.lastIndex(where: { $0.mChannelLabel == 8 }) == 2, "mutable lastIndex")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).lastIndex(where: { $0.mChannelLabel == 9 }) == 1,
            "immutable lastIndex"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5, 4]).channelDescriptions.lastIndex(where: { $0.mChannelLabel == 4 }) == 2,
        "managed lastIndex"
    )
}

func testCollectionMinBy() {
    withBufferList([2, 1, 4]) { list in
        coreAudioExpect(list.min(by: { $0.mNumberChannels < $1.mNumberChannels })?.mNumberChannels == 1, "buffer min")
    }
    withChannelLayout([9, 8, 10]) { layout in
        coreAudioExpect(layout.min(by: { $0.mChannelLabel < $1.mChannelLabel })?.mChannelLabel == 8, "mutable min")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).min(by: { $0.mChannelLabel < $1.mChannelLabel })?.mChannelLabel == 8,
            "immutable min"
        )
    }
    coreAudioExpect(
        makeManagedLayout([5, 4]).channelDescriptions.min(by: { $0.mChannelLabel < $1.mChannelLabel })?.mChannelLabel == 4,
        "managed min"
    )
}

func testCollectionMaxBy() {
    withBufferList([2, 1, 4]) { list in
        coreAudioExpect(list.max(by: { $0.mNumberChannels < $1.mNumberChannels })?.mNumberChannels == 4, "buffer max")
    }
    withChannelLayout([9, 8, 10]) { layout in
        coreAudioExpect(layout.max(by: { $0.mChannelLabel < $1.mChannelLabel })?.mChannelLabel == 10, "mutable max")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).max(by: { $0.mChannelLabel < $1.mChannelLabel })?.mChannelLabel == 10,
            "immutable max"
        )
    }
    coreAudioExpect(
        makeManagedLayout([5, 4]).channelDescriptions.max(by: { $0.mChannelLabel < $1.mChannelLabel })?.mChannelLabel == 5,
        "managed max"
    )
}

func testCollectionStartsWithBy() {
    withBufferList([2, 1, 4]) { list in
        let prefix = [AudioBuffer(mNumberChannels: 2, mDataByteSize: 0, mData: nil)]
        coreAudioExpect(
            list.starts(with: prefix, by: { $0.mNumberChannels == $1.mNumberChannels }),
            "buffer starts(with:by:)"
        )
    }
    withChannelLayout([8, 9, 10]) { layout in
        let prefix = [AudioChannelDescription(mChannelLabel: 8, mChannelFlags: [], mCoordinates: (0, 0, 0))]
        coreAudioExpect(layout.starts(with: prefix, by: { $0.mChannelLabel == $1.mChannelLabel }), "mutable starts")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer)
                .starts(with: prefix, by: { $0.mChannelLabel == $1.mChannelLabel }),
            "immutable starts"
        )
    }
    let managedPrefix = [AudioChannelDescription(mChannelLabel: 4, mChannelFlags: [], mCoordinates: (0, 0, 0))]
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.starts(with: managedPrefix, by: { $0.mChannelLabel == $1.mChannelLabel }),
        "managed starts"
    )
}

func testCollectionElementsEqualBy() {
    withBufferList([2, 1]) { list in
        let other = [AudioBuffer(mNumberChannels: 2, mDataByteSize: 0, mData: nil), AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil)]
        coreAudioExpect(
            list.elementsEqual(other, by: { $0.mNumberChannels == $1.mNumberChannels }),
            "buffer elementsEqual"
        )
    }
    withChannelLayout([8, 9]) { layout in
        let other = [
            AudioChannelDescription(mChannelLabel: 8, mChannelFlags: [], mCoordinates: (0, 0, 0)),
            AudioChannelDescription(mChannelLabel: 9, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        ]
        coreAudioExpect(layout.elementsEqual(other, by: { $0.mChannelLabel == $1.mChannelLabel }), "mutable elementsEqual")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer)
                .elementsEqual(other, by: { $0.mChannelLabel == $1.mChannelLabel }),
            "immutable elementsEqual"
        )
    }
    let managedOther = [
        AudioChannelDescription(mChannelLabel: 4, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        AudioChannelDescription(mChannelLabel: 5, mChannelFlags: [], mCoordinates: (0, 0, 0)),
    ]
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.elementsEqual(managedOther, by: { $0.mChannelLabel == $1.mChannelLabel }),
        "managed elementsEqual"
    )
}

func testCollectionLexicographicallyPrecedes() {
    withBufferList([1, 2]) { list in
        let greater = [
            AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil),
            AudioBuffer(mNumberChannels: 3, mDataByteSize: 0, mData: nil),
        ]
        coreAudioExpect(
            list.lexicographicallyPrecedes(greater, by: { $0.mNumberChannels < $1.mNumberChannels }),
            "buffer lexicographicallyPrecedes"
        )
    }
    withChannelLayout([8, 9]) { layout in
        let greater = [
            AudioChannelDescription(mChannelLabel: 8, mChannelFlags: [], mCoordinates: (0, 0, 0)),
            AudioChannelDescription(mChannelLabel: 10, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        ]
        coreAudioExpect(
            layout.lexicographicallyPrecedes(greater, by: { $0.mChannelLabel < $1.mChannelLabel }),
            "mutable lexicographicallyPrecedes"
        )
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer)
                .lexicographicallyPrecedes(greater, by: { $0.mChannelLabel < $1.mChannelLabel }),
            "immutable lexicographicallyPrecedes"
        )
    }
    let managedGreater = [
        AudioChannelDescription(mChannelLabel: 4, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        AudioChannelDescription(mChannelLabel: 9, mChannelFlags: [], mCoordinates: (0, 0, 0)),
    ]
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions
            .lexicographicallyPrecedes(managedGreater, by: { $0.mChannelLabel < $1.mChannelLabel }),
        "managed lexicographicallyPrecedes"
    )
}
