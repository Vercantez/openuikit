import CoreAudio
import Foundation

func testCollectionFormIndexAfter() {
    withBufferList([1, 2, 3]) { list in
        var index = list.startIndex
        list.formIndex(after: &index)
        coreAudioExpect(index == 1, "buffer formIndex(after:)")
    }
    withChannelLayout([8, 9]) { layout in
        var mutableIndex = layout.startIndex
        layout.formIndex(after: &mutableIndex)
        coreAudioExpect(mutableIndex == 1, "mutable formIndex(after:)")
        var immutableIndex = 0
        AudioChannelLayout.UnsafePointer(layout.unsafePointer).formIndex(after: &immutableIndex)
        coreAudioExpect(immutableIndex == 1, "immutable formIndex(after:)")
    }
    var managedIndex = 0
    makeManagedLayout([4, 5]).channelDescriptions.formIndex(after: &managedIndex)
    coreAudioExpect(managedIndex == 1, "managed formIndex(after:)")
}

func testCollectionFormIndexBefore() {
    withBufferList([1, 2, 3]) { list in
        var index = list.endIndex
        list.formIndex(before: &index)
        coreAudioExpect(index == 2, "buffer formIndex(before:)")
    }
    withChannelLayout([8, 9]) { layout in
        var mutableIndex = layout.endIndex
        layout.formIndex(before: &mutableIndex)
        coreAudioExpect(mutableIndex == 1, "mutable formIndex(before:)")
        var immutableIndex = 2
        AudioChannelLayout.UnsafePointer(layout.unsafePointer).formIndex(before: &immutableIndex)
        coreAudioExpect(immutableIndex == 1, "immutable formIndex(before:)")
    }
    var managedIndex = 2
    makeManagedLayout([4, 5]).channelDescriptions.formIndex(before: &managedIndex)
    coreAudioExpect(managedIndex == 1, "managed formIndex(before:)")
}

func testCollectionFormIndexOffsetBy() {
    withBufferList([1, 2, 3]) { list in
        var index = list.startIndex
        list.formIndex(&index, offsetBy: 2)
        coreAudioExpect(index == 2, "buffer formIndex offsetBy")
    }
    withChannelLayout([8, 9, 10]) { layout in
        var mutableIndex = layout.startIndex
        layout.formIndex(&mutableIndex, offsetBy: 2)
        coreAudioExpect(mutableIndex == 2, "mutable formIndex offsetBy")
        var immutableIndex = 0
        AudioChannelLayout.UnsafePointer(layout.unsafePointer).formIndex(&immutableIndex, offsetBy: 1)
        coreAudioExpect(immutableIndex == 1, "immutable formIndex offsetBy")
    }
    var managedIndex = 0
    makeManagedLayout([4, 5, 6]).channelDescriptions.formIndex(&managedIndex, offsetBy: 2)
    coreAudioExpect(managedIndex == 2, "managed formIndex offsetBy")
}

func testCollectionFormIndexOffsetByLimitedBy() {
    withBufferList([1, 2, 3]) { list in
        var successIndex = list.startIndex
        let success = list.formIndex(&successIndex, offsetBy: 2, limitedBy: list.endIndex)
        coreAudioExpect(success && successIndex == 2, "buffer limited success")
        var failIndex = list.startIndex
        let failed = list.formIndex(&failIndex, offsetBy: 9, limitedBy: list.endIndex)
        coreAudioExpect(!failed, "buffer limited failure")
    }
    withChannelLayout([8, 9]) { layout in
        var mutableIndex = layout.startIndex
        coreAudioExpect(
            layout.formIndex(&mutableIndex, offsetBy: 1, limitedBy: layout.endIndex),
            "mutable limited success"
        )
        var immutableIndex = 0
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        coreAudioExpect(
            immutable.formIndex(&immutableIndex, offsetBy: 1, limitedBy: immutable.endIndex),
            "immutable limited success"
        )
    }
    var managedIndex = 0
    let descriptions = makeManagedLayout([4, 5]).channelDescriptions
    coreAudioExpect(
        descriptions.formIndex(&managedIndex, offsetBy: 1, limitedBy: descriptions.endIndex),
        "managed limited success"
    )
}

func testCollectionIndexOffsetByLimitedBy() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(list.index(list.startIndex, offsetBy: 2, limitedBy: list.endIndex) == 2, "buffer index limited")
        coreAudioExpect(list.index(list.startIndex, offsetBy: 9, limitedBy: list.endIndex) == nil, "buffer index nil")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.index(0, offsetBy: 1, limitedBy: 2) == 1, "mutable index limited")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).index(0, offsetBy: 1, limitedBy: 2) == 1,
            "immutable index limited"
        )
    }
    let descriptions = makeManagedLayout([4, 5]).channelDescriptions
    coreAudioExpect(descriptions.index(0, offsetBy: 1, limitedBy: 2) == 1, "managed index limited")
}
