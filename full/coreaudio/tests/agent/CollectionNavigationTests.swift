import CoreAudio
import Foundation

func testCollectionFirst() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.first?.mNumberChannels == 2, "buffer first")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.first?.mChannelLabel == 8, "mutable layout first")
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        coreAudioExpect(immutable.first?.mChannelLabel == 8, "immutable layout first")
    }
    coreAudioExpect(makeManagedLayout([4, 5]).channelDescriptions.first?.mChannelLabel == 4, "managed first")
    coreAudioExpect(ManagedAudioChannelLayout(channelDescriptions: []).channelDescriptions.first == nil, "empty first")
}

func testCollectionLast() {
    withBufferList([2, 1]) { list in
        coreAudioExpect(list.last?.mNumberChannels == 1, "buffer last")
    }
    withChannelLayout([8, 9]) { layout in
        coreAudioExpect(layout.last?.mChannelLabel == 9, "mutable layout last")
        let immutable = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        coreAudioExpect(immutable.last?.mChannelLabel == 9, "immutable layout last")
    }
    coreAudioExpect(makeManagedLayout([4, 5]).channelDescriptions.last?.mChannelLabel == 5, "managed last")
}

func testCollectionIsEmpty() {
    withBufferList([1]) { list in
        coreAudioExpect(!list.isEmpty, "non-empty buffers")
        list.count = 0
        coreAudioExpect(list.isEmpty, "empty buffers")
    }
    withChannelLayout([1]) { layout in
        coreAudioExpect(!layout.isEmpty, "non-empty mutable layout")
        layout.count = 0
        coreAudioExpect(layout.isEmpty, "empty mutable layout")
        let emptyView = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
        coreAudioExpect(emptyView.isEmpty, "empty immutable layout")
    }
    coreAudioExpect(makeManagedLayout([1]).channelDescriptions.isEmpty == false, "non-empty managed")
    coreAudioExpect(ManagedAudioChannelLayout(channelDescriptions: []).channelDescriptions.isEmpty, "empty managed")
}

func testCollectionMakeIterator() {
    withBufferList([3, 4]) { list in
        var iterator = list.makeIterator()
        coreAudioExpect(iterator.next()?.mNumberChannels == 3, "buffer iterator")
        coreAudioExpect(iterator.next()?.mNumberChannels == 4, "buffer iterator next")
        coreAudioExpect(iterator.next() == nil, "buffer iterator end")
    }
    withChannelLayout([1, 2]) { layout in
        var mutableIterator = layout.makeIterator()
        coreAudioExpect(mutableIterator.next()?.mChannelLabel == 1, "mutable iterator")
        var immutableIterator = AudioChannelLayout.UnsafePointer(layout.unsafePointer).makeIterator()
        coreAudioExpect(immutableIterator.next()?.mChannelLabel == 1, "immutable iterator")
    }
    var managedIterator = makeManagedLayout([9]).channelDescriptions.makeIterator()
    coreAudioExpect(managedIterator.next()?.mChannelLabel == 9, "managed iterator")
}

func testCollectionUnderestimatedCount() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(list.underestimatedCount == 3, "buffer underestimatedCount")
    }
    withChannelLayout([1, 2]) { layout in
        coreAudioExpect(layout.underestimatedCount == 2, "mutable underestimatedCount")
        coreAudioExpect(
            AudioChannelLayout.UnsafePointer(layout.unsafePointer).underestimatedCount == 2,
            "immutable underestimatedCount"
        )
    }
    coreAudioExpect(makeManagedLayout([1]).channelDescriptions.underestimatedCount == 1, "managed underestimatedCount")
}
