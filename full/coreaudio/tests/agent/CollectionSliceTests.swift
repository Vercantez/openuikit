import CoreAudio
import Foundation

func testCollectionPrefixCount() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.prefix(2)).map(\.mNumberChannels) == [1, 2], "buffer prefix")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.prefix(1)).map(\.mChannelLabel) == [8], "mutable prefix")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).prefix(2)).map(\.mChannelLabel) == [8, 9],
            "immutable prefix"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5, 6]).channelDescriptions.prefix(2)).map(\.mChannelLabel) == [4, 5],
        "managed prefix"
    )
}

func testCollectionSuffixCount() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.suffix(2)).map(\.mNumberChannels) == [2, 3], "buffer suffix")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.suffix(1)).map(\.mChannelLabel) == [10], "mutable suffix")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).suffix(2)).map(\.mChannelLabel) == [9, 10],
            "immutable suffix"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5, 6]).channelDescriptions.suffix(1)).map(\.mChannelLabel) == [6],
        "managed suffix"
    )
}

func testCollectionDropFirst() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.dropFirst()).map(\.mNumberChannels) == [2, 3], "buffer dropFirst")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.dropFirst(2)).map(\.mChannelLabel) == [10], "mutable dropFirst")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).dropFirst()).map(\.mChannelLabel) == [9, 10],
            "immutable dropFirst"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5]).channelDescriptions.dropFirst()).map(\.mChannelLabel) == [5],
        "managed dropFirst"
    )
}

func testCollectionDropLast() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.dropLast()).map(\.mNumberChannels) == [1, 2], "buffer dropLast")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.dropLast(2)).map(\.mChannelLabel) == [8], "mutable dropLast")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).dropLast()).map(\.mChannelLabel) == [8, 9],
            "immutable dropLast"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5]).channelDescriptions.dropLast()).map(\.mChannelLabel) == [4],
        "managed dropLast"
    )
}

func testCollectionDropWhile() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(
            Array(list.drop(while: { $0.mNumberChannels < 3 })).map(\.mNumberChannels) == [3],
            "buffer drop(while:)"
        )
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(
            Array(layout.drop(while: { $0.mChannelLabel < 9 })).map(\.mChannelLabel) == [9, 10],
            "mutable drop(while:)"
        )
        coreAudioExpect(
            Array(
                AudioChannelLayout.UnsafePointer(layout.unsafePointer).drop(while: { $0.mChannelLabel < 10 })
            ).map(\.mChannelLabel) == [10],
            "immutable drop(while:)"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5, 6]).channelDescriptions.drop(while: { $0.mChannelLabel < 6 }))
            .map(\.mChannelLabel) == [6],
        "managed drop(while:)"
    )
}

func testCollectionPrefixWhile() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(
            Array(list.prefix(while: { $0.mNumberChannels < 3 })).map(\.mNumberChannels) == [1, 2],
            "buffer prefix(while:)"
        )
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(
            Array(layout.prefix(while: { $0.mChannelLabel < 10 })).map(\.mChannelLabel) == [8, 9],
            "mutable prefix(while:)"
        )
        coreAudioExpect(
            Array(
                AudioChannelLayout.UnsafePointer(layout.unsafePointer).prefix(while: { $0.mChannelLabel < 9 })
            ).map(\.mChannelLabel) == [8],
            "immutable prefix(while:)"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5, 6]).channelDescriptions.prefix(while: { $0.mChannelLabel < 6 }))
            .map(\.mChannelLabel) == [4, 5],
        "managed prefix(while:)"
    )
}

func testCollectionPrefixUpTo() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.prefix(upTo: 2)).map(\.mNumberChannels) == [1, 2], "buffer prefix(upTo:)")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.prefix(upTo: 1)).map(\.mChannelLabel) == [8], "mutable prefix(upTo:)")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).prefix(upTo: 2)).map(\.mChannelLabel) == [8, 9],
            "immutable prefix(upTo:)"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5, 6]).channelDescriptions.prefix(upTo: 1)).map(\.mChannelLabel) == [4],
        "managed prefix(upTo:)"
    )
}

func testCollectionPrefixThrough() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.prefix(through: 1)).map(\.mNumberChannels) == [1, 2], "buffer prefix(through:)")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.prefix(through: 0)).map(\.mChannelLabel) == [8], "mutable prefix(through:)")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).prefix(through: 1)).map(\.mChannelLabel) == [8, 9],
            "immutable prefix(through:)"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5]).channelDescriptions.prefix(through: 1)).map(\.mChannelLabel) == [4, 5],
        "managed prefix(through:)"
    )
}

func testCollectionSuffixFrom() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(Array(list.suffix(from: 1)).map(\.mNumberChannels) == [2, 3], "buffer suffix(from:)")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Array(layout.suffix(from: 2)).map(\.mChannelLabel) == [10], "mutable suffix(from:)")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).suffix(from: 1)).map(\.mChannelLabel) == [9, 10],
            "immutable suffix(from:)"
        )
    }
    coreAudioExpect(
        Array(makeManagedLayout([4, 5, 6]).channelDescriptions.suffix(from: 2)).map(\.mChannelLabel) == [6],
        "managed suffix(from:)"
    )
}

func testCollectionSliceSubscript() {
    withChannelLayout([8, 9, 10]) { layout in
        var mutableSlice = layout[1..<3]
        coreAudioExpect(mutableSlice.map(\.mChannelLabel) == [9, 10], "mutable slice get")
        mutableSlice[1] = AudioChannelDescription(
            mChannelLabel: 99,
            mChannelFlags: [],
            mCoordinates: (0, 0, 0)
        )
        coreAudioExpect(layout[1].mChannelLabel == 99, "mutable slice set writes through")
        let immutableSlice = AudioChannelLayout.UnsafePointer(layout.unsafePointer)[0..<2]
        coreAudioExpect(immutableSlice.map(\.mChannelLabel) == [8, 99], "immutable slice get")
    }
}
