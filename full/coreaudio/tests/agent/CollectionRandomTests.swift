import CoreAudio
import Foundation

func testCollectionRandomElement() {
    withBufferList([2, 1]) { list in
        let value = list.randomElement()
        coreAudioExpect(value != nil, "buffer randomElement")
        coreAudioExpect([2, 1].contains(value!.mNumberChannels), "buffer randomElement member")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect([8, 9].contains(layout.randomElement()!.mChannelLabel), "mutable randomElement")
        coreAudioExpect(
            [8, 9].contains(AudioChannelLayout.UnsafePointer(layout.unsafePointer).randomElement()!.mChannelLabel),
            "immutable randomElement"
        )
    }
    coreAudioExpect(
        [4, 5].contains(makeManagedLayout([4, 5]).channelDescriptions.randomElement()!.mChannelLabel),
        "managed randomElement"
    )
}

func testCollectionRandomElementUsing() {
    var generator = CoreAudioLCG(seed: 99)
    withBufferList([2, 1, 4]) { list in
        let value = list.randomElement(using: &generator)
        coreAudioExpect([2, 1, 4].contains(value!.mNumberChannels), "buffer randomElement(using:)")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(
            [8, 9, 10].contains(layout.randomElement(using: &generator)!.mChannelLabel),
            "mutable randomElement(using:)"
        )
        coreAudioExpect(
            [8, 9, 10].contains(
                AudioChannelLayout.UnsafePointer(layout.unsafePointer).randomElement(using: &generator)!.mChannelLabel
            ),
            "immutable randomElement(using:)"
        )
    }
    coreAudioExpect(
        [4, 5].contains(makeManagedLayout([4, 5]).channelDescriptions.randomElement(using: &generator)!.mChannelLabel),
        "managed randomElement(using:)"
    )
}

func testCollectionShuffled() {
    withBufferList([1, 2, 3, 4]) { list in
        coreAudioExpect(Set(list.shuffled().map(\.mNumberChannels)) == [1, 2, 3, 4], "buffer shuffled")
    }
    withChannelLayout([8, 9, 10]) { layout in
        coreAudioExpect(Set(layout.shuffled().map(\.mChannelLabel)) == [8, 9, 10], "mutable shuffled")
        coreAudioExpect(
            Set(AudioChannelLayout.UnsafePointer(layout.unsafePointer).shuffled().map(\.mChannelLabel)) == [8, 9, 10],
            "immutable shuffled"
        )
    }
    coreAudioExpect(
        Set(makeManagedLayout([4, 5, 6]).channelDescriptions.shuffled().map(\.mChannelLabel)) == [4, 5, 6],
        "managed shuffled"
    )
}

func testCollectionShuffledUsing() {
    withBufferList([1, 2, 3, 4]) { list in
        var generator = CoreAudioLCG(seed: 3)
        coreAudioExpect(
            Set(list.shuffled(using: &generator).map(\.mNumberChannels)) == [1, 2, 3, 4],
            "buffer shuffled(using:)"
        )
    }
    withChannelLayout([8, 9, 10, 11]) { layout in
        var generator = CoreAudioLCG(seed: 5)
        coreAudioExpect(Set(layout.shuffled(using: &generator).map(\.mChannelLabel)) == [8, 9, 10, 11], "mutable shuffled(using:)")
        var other = CoreAudioLCG(seed: 5)
        coreAudioExpect(
            Set(AudioChannelLayout.UnsafePointer(layout.unsafePointer).shuffled(using: &other).map(\.mChannelLabel))
                == [8, 9, 10, 11],
            "immutable shuffled(using:)"
        )
    }
    var generator = CoreAudioLCG(seed: 9)
    coreAudioExpect(
        Set(makeManagedLayout([4, 5, 6]).channelDescriptions.shuffled(using: &generator).map(\.mChannelLabel)) == [4, 5, 6],
        "managed shuffled(using:)"
    )
}
