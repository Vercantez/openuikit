import CoreAudio
import Foundation

func testCollectionMap() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.map { $0.mNumberChannels } == [2, 1], "buffer map")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.map { $0.mChannelLabel } == [8, 9], "mutable map")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).map { $0.mChannelLabel } == [8, 9],
            "immutable map"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5]).channelDescriptions.map { $0.mChannelLabel } == [4, 5],
        "managed map"
    )
}

func testCollectionCompactMap() {
    withBufferList([2, 0, 1]) { list in
        let kept = list.compactMap { buffer -> UInt32? in
            buffer.mNumberChannels == 0 ? nil : buffer.mNumberChannels
        }
        coreAudioExpect(kept == [2, 1], "buffer compactMap")
    }
    withChannelLayout([8, 0, 9]) { layout in
        let mutableKept = layout.compactMap { $0.mChannelLabel == 0 ? nil : $0.mChannelLabel }
        coreAudioExpect(mutableKept == [8, 9], "mutable compactMap")
        let immutableKept = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
            .compactMap { $0.mChannelLabel == 0 ? nil : $0.mChannelLabel }
        coreAudioExpect(immutableKept == [8, 9], "immutable compactMap")
    }
    let managedKept = makeManagedLayout([4, 0, 5]).channelDescriptions
        .compactMap { $0.mChannelLabel == 0 ? nil : $0.mChannelLabel }
    coreAudioExpect(managedKept == [4, 5], "managed compactMap")
}

func testCollectionFlatMapSequence() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.flatMap { [$0.mNumberChannels, 0] } == [2, 0, 1, 0], "buffer flatMap")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.flatMap { [$0.mChannelLabel] } == [8, 9], "mutable flatMap")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).flatMap { [$0.mChannelLabel] } == [8, 9],
            "immutable flatMap"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4]).channelDescriptions.flatMap { [$0.mChannelLabel, $0.mChannelLabel] } == [4, 4],
        "managed flatMap"
    )
}

func testCollectionFilter() {
    withBufferList([2, 1, 2]) { list in
        coreAudioExpect(list.filter { $0.mNumberChannels == 2 }.count == 2, "buffer filter")
    }
    withChannelLayout([8, 9, 8]) { layout in
        coreAudioExpect(layout.filter { $0.mChannelLabel == 8 }.count == 2, "mutable filter")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).filter { $0.mChannelLabel == 9 }.count == 1,
            "immutable filter"
        )
    }
    coreAudioExpect(
        makeManagedLayout([4, 5, 4]).channelDescriptions.filter { $0.mChannelLabel == 4 }.count == 2,
        "managed filter"
    )
}

func testCollectionForEach() {
    var bufferSum: UInt32 = 0
    withBufferList([2, 1]) { list in
        list.forEach { bufferSum += $0.mNumberChannels }
    }
    coreAudioExpect(bufferSum == 3, "buffer forEach")
    var layoutSum: UInt32 = 0
    var immutableSum: UInt32 = 0
    withChannelLayout([8, 9]) { layout in
        layout.forEach { layoutSum += $0.mChannelLabel }
        AudioChannelLayout.UnsafePointer(layout.unsafePointer).forEach { immutableSum += $0.mChannelLabel }
    }
    coreAudioExpect(layoutSum == 17 && immutableSum == 17, "layout forEach")
    var managedSum: UInt32 = 0
    makeManagedLayout([4, 5]).channelDescriptions.forEach { managedSum += $0.mChannelLabel }
    coreAudioExpect(managedSum == 9, "managed forEach")
}

func testCollectionEnumerated() {
    withBufferList([9, 8]) { list in
        let pairs = Array(list.enumerated()).map { ($0.offset, $0.element.mNumberChannels) }
        coreAudioExpect(pairs[0].0 == 0 && pairs[0].1 == 9, "buffer enumerated")
        coreAudioExpect(pairs[1].0 == 1 && pairs[1].1 == 8, "buffer enumerated next")
    }
    withChannelLayout([1, 2]) { layout in
        coreAudioExpect(Array(layout.enumerated()).count == 2, "mutable enumerated")
        coreAudioExpect(
            Array(AudioChannelLayout.UnsafePointer(layout.unsafePointer).enumerated()).count == 2,
            "immutable enumerated"
        )
    }
    coreAudioExpect(Array(makeManagedLayout([3]).channelDescriptions.enumerated()).count == 1, "managed enumerated")
}
