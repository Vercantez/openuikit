import CoreAudio
import Foundation

enum CoreAudioRuntimeProbe {
    static func expect(_ condition: Bool, _ message: String) {
        if !condition {
            fputs("COREAUDIO_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
            fatalError(message)
        }
    }
}

// MARK: AudioBufferList overlay

let sizeOne = AudioBufferList.sizeInBytes(maximumBuffers: 1)
let sizeTwo = AudioBufferList.sizeInBytes(maximumBuffers: 2)
CoreAudioRuntimeProbe.expect(sizeTwo > sizeOne, "sizeInBytes must grow with buffer count")
CoreAudioRuntimeProbe.expect(
    sizeOne == MemoryLayout<AudioBufferList>.size,
    "single-buffer list size should match the imported struct"
)

let buffers = AudioBufferList.allocate(maximumBuffers: 2)
CoreAudioRuntimeProbe.expect(UnsafeMutableAudioBufferListPointer(Optional<UnsafeMutablePointer<AudioBufferList>>.none) == nil, "nil pointer init")
CoreAudioRuntimeProbe.expect(buffers.count == 2, "allocate initializes count")
CoreAudioRuntimeProbe.expect(buffers.startIndex == 0, "startIndex")
CoreAudioRuntimeProbe.expect(buffers.endIndex == 2, "endIndex")
CoreAudioRuntimeProbe.expect(buffers.unsafePointer == UnsafePointer(buffers.unsafeMutablePointer), "unsafePointer alias")

var sampleStorage = [Float](repeating: 0.25, count: 8)
let written: Int = sampleStorage.withUnsafeMutableBufferPointer { typed in
    let audioBuffer = AudioBuffer(typed, numberOfChannels: 2)
    CoreAudioRuntimeProbe.expect(audioBuffer.mNumberChannels == 2, "typed AudioBuffer channels")
    CoreAudioRuntimeProbe.expect(
        audioBuffer.mDataByteSize == UInt32(8 * MemoryLayout<Float>.stride),
        "typed AudioBuffer byte size"
    )
    buffers[0] = audioBuffer
    let roundTrip = UnsafeMutableBufferPointer<Float>(audioBuffer)
    CoreAudioRuntimeProbe.expect(roundTrip.count == 8, "mutable typed view count")
    CoreAudioRuntimeProbe.expect(roundTrip[0] == 0.25, "mutable typed view contents")
    let immutable = UnsafeBufferPointer<Float>(audioBuffer)
    CoreAudioRuntimeProbe.expect(immutable.count == 8, "immutable typed view count")
    return roundTrip.count
}
CoreAudioRuntimeProbe.expect(written == 8, "typed buffer round-trip")

buffers[1] = AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil)
CoreAudioRuntimeProbe.expect(buffers[1].mNumberChannels == 1, "nonmutating subscript set")
CoreAudioRuntimeProbe.expect(!buffers.isEmpty, "collection isEmpty")
CoreAudioRuntimeProbe.expect(buffers.first?.mNumberChannels == 2, "collection first")
CoreAudioRuntimeProbe.expect(buffers.last?.mNumberChannels == 1, "collection last")
let channelCounts = buffers.map { $0.mNumberChannels }
CoreAudioRuntimeProbe.expect(channelCounts == [2, 1], "collection map")
CoreAudioRuntimeProbe.expect(buffers.contains(where: { $0.mNumberChannels == 1 }), "contains(where:)")
_ = buffers.makeIterator()
UnsafeMutableRawPointer(buffers.unsafeMutablePointer).deallocate()

// MARK: Channel layout overlay

let layoutBytes = AudioChannelLayout.sizeInBytes(maximumDescriptions: 3)
CoreAudioRuntimeProbe.expect(
    layoutBytes > AudioChannelLayout.sizeInBytes(maximumDescriptions: 1),
    "layout sizeInBytes grows with descriptions"
)

let allocatedLayout = AudioChannelLayout.allocate(maximumDescriptions: 2)
CoreAudioRuntimeProbe.expect(allocatedLayout.count == 2, "allocate initializes description count")
CoreAudioRuntimeProbe.expect(AudioChannelLayout.UnsafeMutablePointer(Optional<UnsafeMutablePointer<AudioChannelLayout>>.none) == nil, "nil mutable layout pointer")
CoreAudioRuntimeProbe.expect(AudioChannelLayout.UnsafePointer(Optional<UnsafePointer<AudioChannelLayout>>.none) == nil, "nil layout pointer")

allocatedLayout[0] = AudioChannelDescription(mChannelLabel: 1, mChannelFlags: [], mCoordinates: (1, 0, 0))
allocatedLayout[1] = AudioChannelDescription(mChannelLabel: 2, mChannelFlags: [], mCoordinates: (0, 1, 0))
let immutableView = AudioChannelLayout.UnsafePointer(allocatedLayout.unsafePointer)
CoreAudioRuntimeProbe.expect(immutableView.count == 2, "immutable layout pointer count")
CoreAudioRuntimeProbe.expect(immutableView[0].mChannelLabel == 1, "immutable layout pointer subscript")
CoreAudioRuntimeProbe.expect(immutableView.startIndex == 0 && immutableView.endIndex == 2, "immutable indices")
CoreAudioRuntimeProbe.expect(allocatedLayout.unsafePointer == UnsafePointer(allocatedLayout.unsafeMutablePointer), "layout pointer alias")

var managedFromPointer = ManagedAudioChannelLayout(
    audioChannelLayoutPointer: immutableView,
    deallocator: { pointer in
        UnsafeMutableRawPointer(mutating: pointer.unsafePointer).deallocate()
    }
)
CoreAudioRuntimeProbe.expect(managedFromPointer.channelDescriptions.count == 2, "managed wrap count")
CoreAudioRuntimeProbe.expect(managedFromPointer.numberOfChannels == 2, "managed wrap channel count")
managedFromPointer.channelDescriptions[0] = AudioChannelDescription(
    mChannelLabel: 9,
    mChannelFlags: [],
    mCoordinates: (0, 0, 0)
)
CoreAudioRuntimeProbe.expect(managedFromPointer.channelDescriptions[0].mChannelLabel == 9, "COW mutation")

var managed = ManagedAudioChannelLayout(maximumDescriptions: 2)
CoreAudioRuntimeProbe.expect(managed.channelDescriptions.count == 2, "maximumDescriptions count")
CoreAudioRuntimeProbe.expect(managed.sizeInBytes > 0, "managed sizeInBytes")
managed.tag = kAudioChannelLayoutTag_UseChannelDescriptions
managed.bitmap = []
managed.channelDescriptions[0] = AudioChannelDescription(mChannelLabel: 3, mChannelFlags: [], mCoordinates: (0, 0, 0))
managed.channelDescriptions[1] = AudioChannelDescription(mChannelLabel: 4, mChannelFlags: [], mCoordinates: (0, 0, 0))
CoreAudioRuntimeProbe.expect(managed.tag == kAudioChannelLayoutTag_UseChannelDescriptions, "tag get/set")
managed.setAllToUnknown()
CoreAudioRuntimeProbe.expect(
    managed.channelDescriptions[0].mChannelLabel == kAudioChannelLabel_Unknown,
    "setAllToUnknown"
)
CoreAudioRuntimeProbe.expect(
    managed.channelDescriptions[1].mChannelLabel == kAudioChannelLabel_Unknown,
    "setAllToUnknown second channel"
)

let fromArray = ManagedAudioChannelLayout(
    channelDescriptions: [
        AudioChannelDescription(mChannelLabel: 5, mChannelFlags: [], mCoordinates: (0, 0, 0)),
        AudioChannelDescription(mChannelLabel: 6, mChannelFlags: [], mCoordinates: (0, 0, 0)),
    ]
)
CoreAudioRuntimeProbe.expect(fromArray.channelDescriptions.count == 2, "array init count")
CoreAudioRuntimeProbe.expect(fromArray.channelDescriptions[1].mChannelLabel == 6, "array init contents")
CoreAudioRuntimeProbe.expect(fromArray.numberOfChannels == 2, "array init channel count")

let tagged = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_Stereo)
CoreAudioRuntimeProbe.expect(tagged.tag == kAudioChannelLayoutTag_Stereo, "tag init")
CoreAudioRuntimeProbe.expect(tagged.numberOfChannels == 2, "stereo tag channel count")
CoreAudioRuntimeProbe.expect(tagged.channelDescriptions.isEmpty, "tag init has no descriptions")
CoreAudioRuntimeProbe.expect(AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Stereo) == 2, "tag channel helper")
CoreAudioRuntimeProbe.expect(AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Mono) == 1, "mono tag")

let copyA = fromArray
let copyB = fromArray
CoreAudioRuntimeProbe.expect(copyA == copyB, "managed equality")
CoreAudioRuntimeProbe.expect(copyA.channelDescriptions == copyB.channelDescriptions, "description equality")
CoreAudioRuntimeProbe.expect(
    !(AudioChannelDescription(mChannelLabel: 1, mChannelFlags: [], mCoordinates: (0, 0, 0))
        == AudioChannelDescription(mChannelLabel: 2, mChannelFlags: [], mCoordinates: (0, 0, 0))),
    "channel description inequality"
)

let pointerResult = fromArray.withUnsafePointer { pointer in
    Int(pointer.pointee.mNumberChannelDescriptions)
}
CoreAudioRuntimeProbe.expect(pointerResult == 2, "withUnsafePointer")

var mutableManaged = fromArray
let mutatedCount = mutableManaged.withUnsafeMutablePointer { pointer in
    pointer.pointee.mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions
    return Int(pointer.pointee.mNumberChannelDescriptions)
}
CoreAudioRuntimeProbe.expect(mutatedCount == 2, "withUnsafeMutablePointer")
CoreAudioRuntimeProbe.expect(mutableManaged.tag == kAudioChannelLayoutTag_UseChannelDescriptions, "mutable pointer write")

let bitmapLayout = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_UseChannelBitmap)
CoreAudioRuntimeProbe.expect(bitmapLayout.numberOfChannels == 0, "empty bitmap channel count")

// MARK: Fail-closed HAL

CoreAudioRuntimeProbe.expect(!CoreAudioHardware.isAvailable, "HAL is fail-closed")
var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices)
CoreAudioRuntimeProbe.expect(
    AudioObjectHasProperty(kAudioObjectSystemObject, &address) == false,
    "AudioObjectHasProperty is false on Linux"
)
var settable = DarwinBoolean(true)
let settableStatus = AudioObjectIsPropertySettable(kAudioObjectSystemObject, &address, &settable)
CoreAudioRuntimeProbe.expect(settableStatus == kAudioHardwareUnsupportedOperationError, "settable fail-closed")
CoreAudioRuntimeProbe.expect(settable.boolValue == false, "settable out-parameter")

var dataSize: UInt32 = 99
let sizeStatus = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &address, 0, nil, &dataSize)
CoreAudioRuntimeProbe.expect(sizeStatus == kAudioHardwareUnsupportedOperationError, "get size fail-closed")
CoreAudioRuntimeProbe.expect(dataSize == 0, "get size does not invent a payload")

var dummy: UInt32 = 0xFFFF_FFFF
var ioSize: UInt32 = 4
let getStatus = AudioObjectGetPropertyData(
    kAudioObjectSystemObject,
    &address,
    0,
    nil,
    &ioSize,
    &dummy
)
CoreAudioRuntimeProbe.expect(getStatus == kAudioHardwareUnsupportedOperationError, "get data fail-closed")
CoreAudioRuntimeProbe.expect(ioSize == 0, "get data does not invent a payload size")

let setStatus = AudioObjectSetPropertyData(
    kAudioObjectSystemObject,
    &address,
    0,
    nil,
    4,
    &dummy
)
CoreAudioRuntimeProbe.expect(setStatus == kAudioHardwareUnsupportedOperationError, "set data fail-closed")

let hostTime = AudioGetCurrentHostTime()
CoreAudioRuntimeProbe.expect(AudioConvertHostTimeToNanos(hostTime) == hostTime, "linux host time is nanoseconds")
CoreAudioRuntimeProbe.expect(AudioConvertNanosToHostTime(hostTime) == hostTime, "nanos conversion identity")
CoreAudioRuntimeProbe.expect(AudioGetHostClockFrequency() == 1_000_000_000, "linux host clock frequency")
CoreAudioRuntimeProbe.expect(AudioGetHostClockMinimumTimeDelta() == 1, "minimum host delta")

print("COREAUDIO_AGENT_RUNTIME_OK")
