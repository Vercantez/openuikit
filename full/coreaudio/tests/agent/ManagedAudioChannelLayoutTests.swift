import CoreAudio
import Foundation

func testManagedInitMaximumDescriptions() {
    let managed = ManagedAudioChannelLayout(maximumDescriptions: 3)
    coreAudioExpect(managed.channelDescriptions.count == 3, "capacity becomes count")
    coreAudioExpect(
        managed.tag == kAudioChannelLayoutTag_UseChannelDescriptions,
        "default tag"
    )
    coreAudioExpect(managed.sizeInBytes > 0, "sizeInBytes positive")
}

func testManagedInitChannelDescriptions() {
    let fromArray = makeManagedLayout([5, 6])
    coreAudioExpect(fromArray.channelDescriptions.count == 2, "array init count")
    coreAudioExpect(fromArray.channelDescriptions[1].mChannelLabel == 6, "array init contents")
    coreAudioExpect(fromArray.numberOfChannels == 2, "array init channel count")
    let empty = ManagedAudioChannelLayout(channelDescriptions: [])
    coreAudioExpect(empty.channelDescriptions.isEmpty, "empty array init")
}

func testManagedInitTag() {
    let tagged = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_Stereo)
    coreAudioExpect(tagged.tag == kAudioChannelLayoutTag_Stereo, "tag init")
    coreAudioExpect(tagged.numberOfChannels == 2, "stereo channel count from tag")
    coreAudioExpect(tagged.channelDescriptions.isEmpty, "tag init has no descriptions")
    let mono = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_Mono)
    coreAudioExpect(mono.numberOfChannels == 1, "mono channel count")
}

func testManagedInitFromPointerAndDeallocator() {
    let allocated = AudioChannelLayout.allocate(maximumDescriptions: 2)
    allocated[0] = AudioChannelDescription(mChannelLabel: 1, mChannelFlags: [], mCoordinates: (0, 0, 0))
    allocated[1] = AudioChannelDescription(mChannelLabel: 2, mChannelFlags: [], mCoordinates: (0, 0, 0))
    var released = false
    var managed = ManagedAudioChannelLayout(
        audioChannelLayoutPointer: AudioChannelLayout.UnsafePointer(allocated.unsafePointer),
        deallocator: { pointer in
            released = true
            UnsafeMutableRawPointer(mutating: pointer.unsafePointer).deallocate()
        }
    )
    coreAudioExpect(managed.channelDescriptions.count == 2, "wrap count")
    coreAudioExpect(managed.numberOfChannels == 2, "wrap channel count")
    managed.channelDescriptions[0] = AudioChannelDescription(
        mChannelLabel: 9,
        mChannelFlags: [],
        mCoordinates: (0, 0, 0)
    )
    coreAudioExpect(managed.channelDescriptions[0].mChannelLabel == 9, "COW mutation")
    managed = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_Mono)
    coreAudioExpect(released, "deallocator ran")
}

func testManagedTagAndBitmapAccessors() {
    var managed = ManagedAudioChannelLayout(maximumDescriptions: 1)
    managed.tag = kAudioChannelLayoutTag_UseChannelBitmap
    managed.bitmap = AudioChannelBitmap(rawValue: 0b1011)
    coreAudioExpect(managed.tag == kAudioChannelLayoutTag_UseChannelBitmap, "tag set")
    coreAudioExpect(managed.bitmap.rawValue == 0b1011, "bitmap set")
}

func testManagedSizeInBytes() {
    let managed = ManagedAudioChannelLayout(maximumDescriptions: 4)
    coreAudioExpect(
        managed.sizeInBytes == AudioChannelLayout.sizeInBytes(maximumDescriptions: 4),
        "sizeInBytes matches layout helper"
    )
}

func testManagedNumberOfChannelsForTagBitmapAndDescriptions() {
    let descriptions = makeManagedLayout([1, 2, 3])
    coreAudioExpect(descriptions.numberOfChannels == 3, "description count")
    let stereo = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_Stereo)
    coreAudioExpect(stereo.numberOfChannels == 2, "tag low 16 bits")
    coreAudioExpect(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Stereo) == 2,
        "C helper"
    )
    var bitmap = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_UseChannelBitmap)
    bitmap.bitmap = AudioChannelBitmap(rawValue: 0b1101)
    coreAudioExpect(bitmap.numberOfChannels == 3, "bitmap popcount")
    let emptyBitmap = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_UseChannelBitmap)
    coreAudioExpect(emptyBitmap.numberOfChannels == 0, "empty bitmap")
}

func testManagedSetAllToUnknown() {
    var managed = makeManagedLayout([3, 4])
    managed.setAllToUnknown()
    coreAudioExpect(
        managed.channelDescriptions[0].mChannelLabel == kAudioChannelLabel_Unknown,
        "first label"
    )
    coreAudioExpect(
        managed.channelDescriptions[1].mChannelLabel == kAudioChannelLabel_Unknown,
        "second label"
    )
}

func testManagedChannelDescriptionsGetSet() {
    var managed = makeManagedLayout([1])
    coreAudioExpect(managed.channelDescriptions[0].mChannelLabel == 1, "get")
    let replacement = makeManagedLayout([7, 8, 9]).channelDescriptions
    managed.channelDescriptions = replacement
    coreAudioExpect(managed.channelDescriptions.count == 3, "set grows")
    coreAudioExpect(managed.channelDescriptions[2].mChannelLabel == 9, "set contents")
}

func testManagedEquality() {
    let left = makeManagedLayout([5, 6])
    let right = makeManagedLayout([5, 6])
    let other = makeManagedLayout([5, 7])
    coreAudioExpect(left == right, "equal layouts")
    coreAudioExpect(!(left == other), "unequal layouts")
}

func testManagedWithUnsafePointer() {
    let managed = makeManagedLayout([2, 3])
    let count = managed.withUnsafePointer { pointer in
        Int(pointer.pointee.mNumberChannelDescriptions)
    }
    coreAudioExpect(count == 2, "withUnsafePointer body")
}

func testManagedWithUnsafeMutablePointer() {
    var managed = makeManagedLayout([2, 3])
    let count = managed.withUnsafeMutablePointer { pointer in
        pointer.pointee.mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions
        return Int(pointer.pointee.mNumberChannelDescriptions)
    }
    coreAudioExpect(count == 2, "withUnsafeMutablePointer body")
    coreAudioExpect(
        managed.tag == kAudioChannelLayoutTag_UseChannelDescriptions,
        "mutable pointer write"
    )
}

func testChannelDescriptionsCollectionBasics() {
    var managed = makeManagedLayout([10, 11, 12])
    let descriptions = managed.channelDescriptions
    coreAudioExpect(descriptions.count == 3, "count")
    coreAudioExpect(descriptions.startIndex == 0, "startIndex")
    coreAudioExpect(descriptions.endIndex == 3, "endIndex")
    coreAudioExpect(descriptions[1].mChannelLabel == 11, "subscript get")
    managed.channelDescriptions[2] = AudioChannelDescription(
        mChannelLabel: 99,
        mChannelFlags: [],
        mCoordinates: (0, 0, 0)
    )
    coreAudioExpect(managed.channelDescriptions[2].mChannelLabel == 99, "subscript set")
}

func testChannelDescriptionsEquality() {
    let left = makeManagedLayout([1, 2]).channelDescriptions
    let right = makeManagedLayout([1, 2]).channelDescriptions
    let other = makeManagedLayout([1, 3]).channelDescriptions
    coreAudioExpect(left == right, "equal descriptions")
    coreAudioExpect(!(left == other), "unequal descriptions")
}

func testChannelDescriptionsTypealiases() {
    let managed = makeManagedLayout([1, 2])
    let descriptions = managed.channelDescriptions
    let _: ManagedAudioChannelLayout.ChannelDescriptions.Element = descriptions[0]
    let _: ManagedAudioChannelLayout.ChannelDescriptions.Index = descriptions.startIndex
    let _: ManagedAudioChannelLayout.ChannelDescriptions.Indices = descriptions.indices
    let _: ManagedAudioChannelLayout.ChannelDescriptions.Iterator = descriptions.makeIterator()
    let _: ManagedAudioChannelLayout.ChannelDescriptions.SubSequence = descriptions[0..<1]
    _ = ManagedAudioChannelLayout.ChannelDescriptions.self
    _ = ManagedAudioChannelLayout.self
    coreAudioExpect(descriptions[0].mChannelLabel == 1, "Element")
}
