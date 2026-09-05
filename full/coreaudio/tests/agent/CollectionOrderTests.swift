import CoreAudio
import Foundation

func testCollectionReversed() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.reversed()).map(\.mNumberChannels) == [3, 2, 1], "buffer reversed")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.reversed()).map(\.mChannelLabel) == [10, 9, 8], "mutable reversed")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).reversed()).map(\.mChannelLabel) == [10, 9, 8],
            "immutable reversed"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5]).channelDescriptions.reversed()).map(\.mChannelLabel) == [5, 4],
        "managed reversed"
    )
}

func testCollectionSortedBy() {
    withBufferList([3, 1, 2]) { list in
        coreAudioExpect(
            list.sorted(by: { $0.mNumberChannels < $1.mNumberChannels }).map(\.mNumberChannels) == [1, 2, 3],
            "buffer sorted(by:)"
        )
    }
    withChannelLayout([10, 8, 9]) { layout in
        coreAudioExpect(
            layout.sorted(by: { $0.mChannelLabel < $1.mChannelLabel }).map(\.mChannelLabel) == [8, 9, 10],
            "mutable sorted(by:)"
        )
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer)
                .sorted(by: { $0.mChannelLabel < $1.mChannelLabel }).map(\.mChannelLabel) == [8, 9, 10],
            "immutable sorted(by:)"
        )
    }
    coreAudioExpect(
        makeManagedLayout([6, 4, 5]).channelDescriptions
            .sorted(by: { $0.mChannelLabel < $1.mChannelLabel }).map(\.mChannelLabel) == [4, 5, 6],
        "managed sorted(by:)"
    )
}

func testCollectionDifferenceFromBy() {
    withBufferList([1, 2]) { list in
        let other = [
            AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil),
            AudioBuffer(mNumberChannels: 3, mDataByteSize: 0, mData: nil),
        ]
        let difference = list.difference(from: other, by: { $0.mNumberChannels == $1.mNumberChannels })
        coreAudioExpect(!difference.isEmpty, "buffer difference")
    }
    withChannelLayout([8, 9]) { layout in
        let other = [
            AudioChannelDescription(mChannelLabel: 8, mChannelFlags: [], mCoordinates: (0, 0, 0)),
            AudioChannelDescription(mChannelLabel: 10, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        ]
        coreAudioExpect(
            !layout.difference(from: other, by: { $0.mChannelLabel == $1.mChannelLabel }).isEmpty,
            "mutable difference"
        )
        coreAudioExpect(
            !AudioChannelLayout.UnsafePointer(layout.unsafePointer)
                .difference(from: other, by: { $0.mChannelLabel == $1.mChannelLabel }).isEmpty,
            "immutable difference"
        )
    }
    let managedOther = [
        AudioChannelDescription(mChannelLabel: 4, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        AudioChannelDescription(mChannelLabel: 9, mChannelFlags: [], mCoordinates: (0, 0, 0)),
    ]
    coreAudioExpect(
        !makeManagedLayout([4, 5]).channelDescriptions
            .difference(from: managedOther, by: { $0.mChannelLabel == $1.mChannelLabel }).isEmpty,
        "managed difference"
    )
}

func testCollectionSplit() {
    withBufferList([1, 0, 2]) { list in
        let parts = list.split(whereSeparator: { $0.mNumberChannels == 0 })
        coreAudioExpect(parts.count == 2, "buffer split")
        coreAudioExpect(parts[0].map(\.mNumberChannels) == [1], "buffer split first")
        coreAudioExpect(parts[1].map(\.mNumberChannels) == [2], "buffer split second")
    }
    withChannelLayout([8, 0, 9]) { layout in
        coreAudioExpect(layout.split(whereSeparator: { $0.mChannelLabel == 0 }).count == 2, "mutable split")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).split(whereSeparator: { $0.mChannelLabel == 0 }).count == 2,
            "immutable split"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 0, 5]).channelDescriptions.split(whereSeparator: { $0.mChannelLabel == 0 }).count == 2,
        "managed split"
    )
}

func testManagedInequality() {
    let left = makeManagedLayout([1, 2])
    let right = makeManagedLayout([1, 3])
    coreAudioExpect(left != right, "ManagedAudioChannelLayout !=")
    coreAudioExpect(!(left != makeManagedLayout([1, 2])), "ManagedAudioChannelLayout equal negation")
    coreAudioExpect(left.channelDescriptions != right.channelDescriptions, "ChannelDescriptions !=")
    coreAudioExpect(
        !(left.channelDescriptions != makeManagedLayout([1, 2]).channelDescriptions),
        "ChannelDescriptions equal negation"
    )
}
