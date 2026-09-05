import CoreAudio
import Foundation

func testAudioChannelLayoutSizeInBytes() {
    let sizeZero = AudioChannelLayout.sizeInBytes(maximumDescriptions: 0)
    let sizeOne = AudioChannelLayout.sizeInBytes(maximumDescriptions: 1)
    let sizeThree = AudioChannelLayout.sizeInBytes(maximumDescriptions: 3)
    coreAudioExpect(sizeZero == MemoryLayout<AudioChannelLayout>.size, "0 descriptions uses struct size")
    coreAudioExpect(sizeOne == sizeZero, "1 description is the embedded slot")
    coreAudioExpect(
        sizeThree == MemoryLayout<AudioChannelLayout>.size
            + 2 * MemoryLayout<AudioChannelDescription>.stride,
        "extra descriptions add stride"
    )
}

func testAudioChannelLayoutAllocate() {
    let layout = AudioChannelLayout.allocate(maximumDescriptions: 2)
    defer { UnsafeMutableRawPointer(layout.unsafeMutablePointer).deallocate() }
    coreAudioExpect(layout.count == 2, "allocate initializes description count")
    coreAudioExpect(
        layout.unsafeMutablePointer.pointee.mChannelLayoutTag
            == kAudioChannelLayoutTag_UseChannelDescriptions,
        "allocate uses channel-description tag"
    )
}

func testLayoutUnsafePointerInitAndCollection() {
    withChannelLayout([1, 2, 3]) { layout in
        let view = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        coreAudioExpect(view.unsafePointer == layout.unsafePointer, "stores pointer")
        coreAudioExpect(view.count == 3, "count")
        coreAudioExpect(view.startIndex == 0, "startIndex")
        coreAudioExpect(view.endIndex == 3, "endIndex")
        coreAudioExpect(view[1].mChannelLabel == 2, "subscript")
        coreAudioExpect(view.index(after: 0) == 1, "index(after:)")
        coreAudioExpect(view.index(before: 3) == 2, "index(before:)")
    }
}

func testLayoutUnsafePointerOptionalNil() {
    let none: UnsafePointer<AudioChannelLayout>? = nil
    coreAudioExpect(AudioChannelLayout.UnsafePointer(none) == nil, "nil optional init")
}

func testLayoutUnsafeMutablePointerInitAndCollection() {
    withChannelLayout([9, 8]) { layout in
        coreAudioExpect(
            layout.unsafePointer == UnsafePointer(layout.unsafeMutablePointer),
            "unsafePointer alias"
        )
        coreAudioExpect(layout[0].mChannelLabel == 9, "subscript get")
        layout[1] = AudioChannelDescription(
            mChannelLabel: 4,
            mChannelFlags: [],
            mCoordinates: (1, 2, 3)
        )
        coreAudioExpect(layout[1].mChannelLabel == 4, "nonmutating subscript set")
        coreAudioExpect(layout[1].mCoordinates.2 == 3, "stores coordinates")
        coreAudioExpect(layout.startIndex == 0 && layout.endIndex == 2, "indices")
    }
}

func testLayoutUnsafeMutablePointerOptionalNil() {
    let none: UnsafeMutablePointer<AudioChannelLayout>? = nil
    coreAudioExpect(AudioChannelLayout.UnsafeMutablePointer(none) == nil, "nil optional init")
}

func testLayoutUnsafeMutablePointerCountSet() {
    withChannelLayout([1, 2, 3]) { layout in
        layout.count = 1
        coreAudioExpect(layout.count == 1, "nonmutating count set")
        coreAudioExpect(layout.endIndex == 1, "endIndex tracks count")
    }
}

func testAudioChannelDescriptionEquality() {
    let left = AudioChannelDescription(mChannelLabel: 1, mChannelFlags: [], mCoordinates: (0, 1, 0))
    let same = AudioChannelDescription(mChannelLabel: 1, mChannelFlags: [], mCoordinates: (0, 1, 0))
    let right = AudioChannelDescription(mChannelLabel: 2, mChannelFlags: [], mCoordinates: (0, 1, 0))
    coreAudioExpect(left == same, "equal descriptions")
    coreAudioExpect(!(left == right), "unequal labels")
    let moved = AudioChannelDescription(mChannelLabel: 1, mChannelFlags: [], mCoordinates: (1, 1, 0))
    coreAudioExpect(!(left == moved), "unequal coordinates")
}

func testLayoutPointerTypealiases() {
    withChannelLayout([5, 6]) { layout in
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        let _: AudioChannelLayout.UnsafePointer.Element = immutable[0]
        let _: AudioChannelLayout.UnsafePointer.Index = immutable.startIndex
        let _: AudioChannelLayout.UnsafePointer.Indices = immutable.indices
        let _: AudioChannelLayout.UnsafePointer.Iterator = immutable.makeIterator()
        let _: AudioChannelLayout.UnsafePointer.SubSequence = immutable[0..<1]
        let _: AudioChannelLayout.UnsafeMutablePointer.Element = layout[0]
        let _: AudioChannelLayout.UnsafeMutablePointer.Index = layout.startIndex
        let _: AudioChannelLayout.UnsafeMutablePointer.Indices = layout.indices
        let _: AudioChannelLayout.UnsafeMutablePointer.Iterator = layout.makeIterator()
        let _: AudioChannelLayout.UnsafeMutablePointer.SubSequence = layout[0..<1]
        _ = AudioChannelLayout.UnsafePointer.self
        _ = AudioChannelLayout.UnsafeMutablePointer.self
        coreAudioExpect(immutable[0].mChannelLabel == 5, "immutable Element")
    }
}
