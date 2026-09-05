import Foundation

// MARK: - CoreAudioTypes stand-ins
//
// The isolated guest compile does not link a CoreAudioTypes module, so the C
// structs that the CoreAudio Swift overlay extends are defined here with the
// layouts recorded in the CoreAudioTypes public surface. Central integration
// should drop these stand-ins and `import CoreAudioTypes` instead.

public typealias OSStatus = Int32
public typealias AudioChannelLabel = UInt32
public typealias AudioChannelLayoutTag = UInt32

public struct AudioChannelFlags: OptionSet, Sendable, Equatable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public struct AudioChannelBitmap: OptionSet, Sendable, Equatable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public struct AudioBuffer {
    public var mNumberChannels: UInt32
    public var mDataByteSize: UInt32
    public var mData: UnsafeMutableRawPointer?

    public init(
        mNumberChannels: UInt32 = 0,
        mDataByteSize: UInt32 = 0,
        mData: UnsafeMutableRawPointer? = nil
    ) {
        self.mNumberChannels = mNumberChannels
        self.mDataByteSize = mDataByteSize
        self.mData = mData
    }
}

public struct AudioBufferList {
    public var mNumberBuffers: UInt32
    public var mBuffers: AudioBuffer

    public init(
        mNumberBuffers: UInt32 = 0,
        mBuffers: AudioBuffer = AudioBuffer()
    ) {
        self.mNumberBuffers = mNumberBuffers
        self.mBuffers = mBuffers
    }
}

public struct AudioChannelDescription {
    public var mChannelLabel: AudioChannelLabel
    public var mChannelFlags: AudioChannelFlags
    public var mCoordinates: (Float32, Float32, Float32)

    public init(
        mChannelLabel: AudioChannelLabel = 0,
        mChannelFlags: AudioChannelFlags = [],
        mCoordinates: (Float32, Float32, Float32) = (0, 0, 0)
    ) {
        self.mChannelLabel = mChannelLabel
        self.mChannelFlags = mChannelFlags
        self.mCoordinates = mCoordinates
    }
}

public struct AudioChannelLayout {
    public var mChannelLayoutTag: AudioChannelLayoutTag
    public var mChannelBitmap: AudioChannelBitmap
    public var mNumberChannelDescriptions: UInt32
    public var mChannelDescriptions: AudioChannelDescription

    public init(
        mChannelLayoutTag: AudioChannelLayoutTag = 0,
        mChannelBitmap: AudioChannelBitmap = [],
        mNumberChannelDescriptions: UInt32 = 0,
        mChannelDescriptions: AudioChannelDescription = AudioChannelDescription()
    ) {
        self.mChannelLayoutTag = mChannelLayoutTag
        self.mChannelBitmap = mChannelBitmap
        self.mNumberChannelDescriptions = mNumberChannelDescriptions
        self.mChannelDescriptions = mChannelDescriptions
    }
}

/// `kAudioChannelLayoutTag_UseChannelDescriptions` from CoreAudioTypes.
public let kAudioChannelLayoutTag_UseChannelDescriptions: AudioChannelLayoutTag = 0x00000000
/// `kAudioChannelLayoutTag_UseChannelBitmap` from CoreAudioTypes.
public let kAudioChannelLayoutTag_UseChannelBitmap: AudioChannelLayoutTag = 0x00010000
/// `kAudioChannelLayoutTag_Mono` = (100 << 16) | 1
public let kAudioChannelLayoutTag_Mono: AudioChannelLayoutTag = 0x00640001
/// `kAudioChannelLayoutTag_Stereo` = (101 << 16) | 2
public let kAudioChannelLayoutTag_Stereo: AudioChannelLayoutTag = 0x00650002
/// `kAudioChannelLabel_Unknown` from CoreAudioTypes.
public let kAudioChannelLabel_Unknown: AudioChannelLabel = 0xFFFF_FFFF
/// `kAudioChannelLabel_Unused` from CoreAudioTypes.
public let kAudioChannelLabel_Unused: AudioChannelLabel = 0

public let kAudio_NoError: OSStatus = 0
public let kAudioHardwareNoError: OSStatus = 0
public let kAudioHardwareUnspecifiedError: OSStatus = OSStatus(bitPattern: 0x77686174) // 'what'
public let kAudioHardwareUnsupportedOperationError: OSStatus = OSStatus(bitPattern: 0x756E6F70) // 'unop'
public let kAudioHardwareUnknownPropertyError: OSStatus = OSStatus(bitPattern: 0x77686F3F) // 'who?'
public let kAudioHardwareNotRunningError: OSStatus = OSStatus(bitPattern: 0x73746F70) // 'stop'
public let kAudioHardwareIllegalOperationError: OSStatus = OSStatus(bitPattern: 0x6E6F7065) // 'nope'

public func AudioChannelLayoutTag_GetNumberOfChannels(
    _ inLayoutTag: AudioChannelLayoutTag
) -> UInt32 {
    inLayoutTag & 0x0000_FFFF
}

extension AudioChannelDescription {
    public static func == (lhs: AudioChannelDescription, rhs: AudioChannelDescription) -> Bool {
        lhs.mChannelLabel == rhs.mChannelLabel
            && lhs.mChannelFlags == rhs.mChannelFlags
            && lhs.mCoordinates.0 == rhs.mCoordinates.0
            && lhs.mCoordinates.1 == rhs.mCoordinates.1
            && lhs.mCoordinates.2 == rhs.mCoordinates.2
    }
}

extension AudioBuffer {
    /// Bind an existing typed buffer as an `AudioBuffer`.
    public init<Element>(
        _ typedBuffer: UnsafeMutableBufferPointer<Element>,
        numberOfChannels: Int
    ) {
        self.mNumberChannels = UInt32(numberOfChannels)
        let byteCount = typedBuffer.count * MemoryLayout<Element>.stride
        self.mDataByteSize = UInt32(byteCount)
        self.mData = UnsafeMutableRawPointer(typedBuffer.baseAddress)
    }
}

extension UnsafeBufferPointer {
    /// Initialize an `UnsafeBufferPointer<Element>` from an `AudioBuffer`.
    /// Binds the buffer's memory type to `Element`.
    public init(_ audioBuffer: AudioBuffer) {
        let count: Int
        if MemoryLayout<Element>.stride == 0 {
            count = 0
        } else {
            count = Int(audioBuffer.mDataByteSize) / MemoryLayout<Element>.stride
        }
        let start = audioBuffer.mData?.assumingMemoryBound(to: Element.self)
        self.init(start: start, count: count)
    }
}

extension UnsafeMutableBufferPointer {
    /// Initialize an `UnsafeMutableBufferPointer<Element>` from an `AudioBuffer`.
    public init(_ audioBuffer: AudioBuffer) {
        let count: Int
        if MemoryLayout<Element>.stride == 0 {
            count = 0
        } else {
            count = Int(audioBuffer.mDataByteSize) / MemoryLayout<Element>.stride
        }
        let start = audioBuffer.mData?.assumingMemoryBound(to: Element.self)
        self.init(start: start, count: count)
    }
}

func coreAudioAllocateZeroed(_ byteCount: Int) -> UnsafeMutableRawPointer {
    precondition(byteCount > 0, "allocation size must be positive")
    let alignment = max(
        MemoryLayout<AudioBufferList>.alignment,
        MemoryLayout<AudioChannelLayout>.alignment
    )
    let raw = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment)
    _ = raw.initializeMemory(as: UInt8.self, repeating: 0, count: byteCount)
    return raw
}

func coreAudioDeallocate(_ ptr: UnsafeMutableRawPointer?) {
    ptr?.deallocate()
}

// MARK: - AudioBufferList overlay

extension AudioBufferList {
    /// - Returns: the size in bytes of an `AudioBufferList` that can hold up to
    ///   `maximumBuffers` `AudioBuffer`s.
    public static func sizeInBytes(maximumBuffers: Int) -> Int {
        precondition(
            maximumBuffers >= 1,
            "AudioBufferList should contain at least one AudioBuffer"
        )
        return MemoryLayout<AudioBufferList>.size
            - MemoryLayout<AudioBuffer>.size
            + maximumBuffers * MemoryLayout<AudioBuffer>.stride
    }

    /// Allocate an `AudioBufferList` with a capacity for the specified number of
    /// `AudioBuffer`s.
    ///
    /// The `count` property of the new list is initialized to `maximumBuffers`.
    /// Release the allocation with `UnsafeMutableRawPointer.deallocate()`.
    /// Apple overlay documentation mentions `free()`; that allocator choice is still an oracle question.
    public static func allocate(maximumBuffers: Int) -> UnsafeMutableAudioBufferListPointer {
        let byteCount = sizeInBytes(maximumBuffers: maximumBuffers)
        let raw = coreAudioAllocateZeroed(byteCount)
        let ptr = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
        ptr.pointee.mNumberBuffers = UInt32(maximumBuffers)
        return UnsafeMutableAudioBufferListPointer(ptr)
    }
}

/// A wrapper for a pointer to an `AudioBufferList`.
///
/// Like `UnsafeMutablePointer`, this type provides no automated memory
/// management and the caller must allocate and free memory appropriately.
public struct UnsafeMutableAudioBufferListPointer {
    public var unsafeMutablePointer: UnsafeMutablePointer<AudioBufferList>

    public init(_ p: UnsafeMutablePointer<AudioBufferList>) {
        unsafeMutablePointer = p
    }

    public init?(_ p: UnsafeMutablePointer<AudioBufferList>?) {
        guard let p else { return nil }
        self.init(p)
    }

    public var unsafePointer: UnsafePointer<AudioBufferList> {
        UnsafePointer(unsafeMutablePointer)
    }

    public var count: Int {
        get { Int(unsafeMutablePointer.pointee.mNumberBuffers) }
        nonmutating set { unsafeMutablePointer.pointee.mNumberBuffers = UInt32(newValue) }
    }
}

extension UnsafeMutableAudioBufferListPointer: RandomAccessCollection, MutableCollection {
    public typealias Element = AudioBuffer
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UnsafeMutableAudioBufferListPointer>
    public typealias Iterator = IndexingIterator<UnsafeMutableAudioBufferListPointer>

    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public subscript(index: Index) -> Element {
        get {
            precondition(index >= startIndex && index < endIndex, "AudioBuffer index out of range")
            return audioBufferPointer(at: index).pointee
        }
        nonmutating set {
            precondition(index >= startIndex && index < endIndex, "AudioBuffer index out of range")
            audioBufferPointer(at: index).pointee = newValue
        }
    }

    public func index(after i: Index) -> Index { i + 1 }
    public func index(before i: Index) -> Index { i - 1 }

    private func audioBufferPointer(at index: Int) -> UnsafeMutablePointer<AudioBuffer> {
        let base = UnsafeMutableRawPointer(unsafeMutablePointer)
        let offset = MemoryLayout<AudioBufferList>.offset(of: \.mBuffers)!
        return base.advanced(by: offset)
            .assumingMemoryBound(to: AudioBuffer.self)
            .advanced(by: index)
    }
}
