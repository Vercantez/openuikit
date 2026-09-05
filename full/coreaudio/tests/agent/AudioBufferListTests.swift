import CoreAudio
import Foundation

func coreAudioExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

struct CoreAudioLCG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

func withBufferList(
    _ channels: [UInt32],
    body: (inout UnsafeMutableAudioBufferListPointer) -> Void
) {
    let allocated = AudioBufferList.allocate(maximumBuffers: max(channels.count, 1))
    defer { UnsafeMutableRawPointer(allocated.unsafeMutablePointer).deallocate() }
    var list = allocated
    list.count = channels.count
    for (index, channelCount) in channels.enumerated() {
        list[index] = AudioBuffer(
            mNumberChannels: channelCount,
            mDataByteSize: 0,
            mData: nil
        )
    }
    body(&list)
}

func withChannelLayout(
    _ labels: [AudioChannelLabel],
    body: (inout AudioChannelLayout.UnsafeMutablePointer) -> Void
) {
    let allocated = AudioChannelLayout.allocate(maximumDescriptions: max(labels.count, 1))
    defer { UnsafeMutableRawPointer(allocated.unsafeMutablePointer).deallocate() }
    var layout = allocated
    layout.count = labels.count
    for (index, label) in labels.enumerated() {
        layout[index] = AudioChannelDescription(
            mChannelLabel: label,
            mChannelFlags: [],
            mCoordinates: (0, 0, 0)
        )
    }
    body(&layout)
}

func makeManagedLayout(_ labels: [AudioChannelLabel]) -> ManagedAudioChannelLayout {
    ManagedAudioChannelLayout(
        channelDescriptions: labels.map { label in
            AudioChannelDescription(
                mChannelLabel: label,
                mChannelFlags: [],
                mCoordinates: (0, 0, 0)
            )
        }
    )
}

func testAudioBufferListSizeInBytes() {
    let sizeOne = AudioBufferList.sizeInBytes(maximumBuffers: 1)
    let sizeTwo = AudioBufferList.sizeInBytes(maximumBuffers: 2)
    let sizeThree = AudioBufferList.sizeInBytes(maximumBuffers: 3)
    coreAudioExpect(sizeOne == MemoryLayout<AudioBufferList>.size, "single-buffer size")
    coreAudioExpect(sizeTwo > sizeOne, "size grows for 2 buffers")
    coreAudioExpect(sizeThree - sizeTwo == sizeTwo - sizeOne, "stride is constant")
}

func testAudioBufferListAllocate() {
    let buffers = AudioBufferList.allocate(maximumBuffers: 3)
    defer { UnsafeMutableRawPointer(buffers.unsafeMutablePointer).deallocate() }
    coreAudioExpect(buffers.count == 3, "allocate initializes count")
    coreAudioExpect(buffers[0].mData == nil, "zeroed buffers")
    coreAudioExpect(buffers[2].mNumberChannels == 0, "zeroed channel count")
}

func testBufferListPointerInitFromPointer() {
    let buffers = AudioBufferList.allocate(maximumBuffers: 1)
    defer { UnsafeMutableRawPointer(buffers.unsafeMutablePointer).deallocate() }
    let wrapped = UnsafeMutableAudioBufferListPointer(buffers.unsafeMutablePointer)
    coreAudioExpect(
        wrapped.unsafeMutablePointer == buffers.unsafeMutablePointer,
        "init copies the pointer"
    )
}

func testBufferListPointerInitFromOptionalNil() {
    let none: UnsafeMutablePointer<AudioBufferList>? = nil
    coreAudioExpect(UnsafeMutableAudioBufferListPointer(none) == nil, "nil optional init")
}

func testBufferListPointerUnsafePointers() {
    let buffers = AudioBufferList.allocate(maximumBuffers: 1)
    defer { UnsafeMutableRawPointer(buffers.unsafeMutablePointer).deallocate() }
    coreAudioExpect(
        buffers.unsafePointer == UnsafePointer(buffers.unsafeMutablePointer),
        "unsafePointer aliases unsafeMutablePointer"
    )
    let mutable = buffers.unsafeMutablePointer
    mutable.pointee.mNumberBuffers = 1
    coreAudioExpect(buffers.count == 1, "unsafeMutablePointer writes through")
}

func testBufferListPointerCountAndIndices() {
    withBufferList([1, 2, 3]) { list in
        coreAudioExpect(list.count == 3, "count get")
        coreAudioExpect(list.startIndex == 0, "startIndex")
        coreAudioExpect(list.endIndex == 3, "endIndex")
        list.count = 2
        coreAudioExpect(list.count == 2, "nonmutating count set")
        coreAudioExpect(list.endIndex == 2, "endIndex tracks count")
        let after = list.index(after: list.startIndex)
        let before = list.index(before: list.endIndex)
        coreAudioExpect(after == 1 && before == 1, "index after/before")
    }
}

func testBufferListPointerSubscriptGetSet() {
    withBufferList([1, 2]) { list in
        coreAudioExpect(list[0].mNumberChannels == 1, "subscript get")
        list[1] = AudioBuffer(mNumberChannels: 8, mDataByteSize: 16, mData: nil)
        coreAudioExpect(list[1].mNumberChannels == 8, "nonmutating subscript set")
        coreAudioExpect(list[1].mDataByteSize == 16, "subscript stores byte size")
    }
}

func testBufferListPointerTypealiases() {
    withBufferList([4, 5]) { list in
        let element: UnsafeMutableAudioBufferListPointer.Element = list[0]
        let index: UnsafeMutableAudioBufferListPointer.Index = list.startIndex
        let indices: UnsafeMutableAudioBufferListPointer.Indices = list.indices
        var iterator: UnsafeMutableAudioBufferListPointer.Iterator = list.makeIterator()
        let slice: UnsafeMutableAudioBufferListPointer.SubSequence = list[0..<1]
        coreAudioExpect(element.mNumberChannels == 4, "Element typealias")
        coreAudioExpect(index == 0, "Index typealias")
        coreAudioExpect(indices == 0..<2, "Indices typealias")
        coreAudioExpect(iterator.next()?.mNumberChannels == 4, "Iterator typealias")
        coreAudioExpect(slice.count == 1, "SubSequence typealias")
        _ = UnsafeMutableAudioBufferListPointer.self
    }
}
