extension AudioChannelLayout {
    /// - Returns: the size in bytes of an `AudioChannelLayout` that can hold up
    ///   to `maximumDescriptions` `AudioChannelDescription`s.
    public static func sizeInBytes(maximumDescriptions: Int) -> Int {
        precondition(maximumDescriptions >= 0, "description count must be non-negative")
        if maximumDescriptions <= 1 {
            return MemoryLayout<AudioChannelLayout>.size
        }
        return MemoryLayout<AudioChannelLayout>.size
            + (maximumDescriptions - 1) * MemoryLayout<AudioChannelDescription>.stride
    }

    /// Allocate an `AudioChannelLayout` with capacity for the specified number
    /// of `AudioChannelDescription`s.
    ///
    /// The `count` property of the new wrapper is initialized to
    /// `maximumDescriptions`. Release the allocation with
    /// `UnsafeMutableRawPointer.deallocate()`.
    public static func allocate(maximumDescriptions: Int) -> UnsafeMutablePointer {
        let byteCount = sizeInBytes(maximumDescriptions: maximumDescriptions)
        let raw = coreAudioAllocateZeroed(byteCount)
        let ptr = raw.bindMemory(to: AudioChannelLayout.self, capacity: 1)
        ptr.pointee.mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions
        ptr.pointee.mNumberChannelDescriptions = UInt32(maximumDescriptions)
        return UnsafeMutablePointer(ptr)
    }

    /// Collection view over the channel descriptions of an immutable layout.
    public struct UnsafePointer: RandomAccessCollection {
        public typealias Element = AudioChannelDescription
        public typealias Index = Int
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<UnsafePointer>
        public typealias Iterator = IndexingIterator<UnsafePointer>

        public var unsafePointer: Swift.UnsafePointer<AudioChannelLayout>

        public init(_ p: Swift.UnsafePointer<AudioChannelLayout>) {
            unsafePointer = p
        }

        public init?(_ p: Swift.UnsafePointer<AudioChannelLayout>?) {
            guard let p else { return nil }
            self.init(p)
        }

        public var count: Int { Int(unsafePointer.pointee.mNumberChannelDescriptions) }
        public var startIndex: Int { 0 }
        public var endIndex: Int { count }

        public subscript(index: Index) -> Element {
            precondition(index >= startIndex && index < endIndex, "channel description index out of range")
            return descriptionPointer(at: index).pointee
        }

        public func index(after i: Index) -> Index { i + 1 }
        public func index(before i: Index) -> Index { i - 1 }

        private func descriptionPointer(at index: Int) -> Swift.UnsafePointer<AudioChannelDescription> {
            AudioChannelLayout.descriptionPointer(base: UnsafeRawPointer(unsafePointer), index: index)
        }
    }

    /// Collection view over the channel descriptions of a mutable layout.
    public struct UnsafeMutablePointer: RandomAccessCollection, MutableCollection {
        public typealias Element = AudioChannelDescription
        public typealias Index = Int
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<UnsafeMutablePointer>
        public typealias Iterator = IndexingIterator<UnsafeMutablePointer>

        public var unsafeMutablePointer: Swift.UnsafeMutablePointer<AudioChannelLayout>

        public init(_ p: Swift.UnsafeMutablePointer<AudioChannelLayout>) {
            unsafeMutablePointer = p
        }

        public init?(_ p: Swift.UnsafeMutablePointer<AudioChannelLayout>?) {
            guard let p else { return nil }
            self.init(p)
        }

        public var unsafePointer: Swift.UnsafePointer<AudioChannelLayout> {
            Swift.UnsafePointer(unsafeMutablePointer)
        }

        public var count: Int {
            get { Int(unsafeMutablePointer.pointee.mNumberChannelDescriptions) }
            nonmutating set {
                unsafeMutablePointer.pointee.mNumberChannelDescriptions = UInt32(newValue)
            }
        }

        public var startIndex: Int { 0 }
        public var endIndex: Int { count }

        public subscript(index: Index) -> Element {
            get {
                precondition(index >= startIndex && index < endIndex, "channel description index out of range")
                return descriptionPointer(at: index).pointee
            }
            nonmutating set {
                precondition(index >= startIndex && index < endIndex, "channel description index out of range")
                descriptionPointer(at: index).pointee = newValue
            }
        }

        public func index(after i: Index) -> Index { i + 1 }
        public func index(before i: Index) -> Index { i - 1 }

        private func descriptionPointer(at index: Int) -> Swift.UnsafeMutablePointer<AudioChannelDescription> {
            AudioChannelLayout.mutableDescriptionPointer(
                base: UnsafeMutableRawPointer(unsafeMutablePointer),
                index: index
            )
        }
    }

    fileprivate static func descriptionPointer(
        base: UnsafeRawPointer,
        index: Int
    ) -> Swift.UnsafePointer<AudioChannelDescription> {
        let offset = MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)!
        return base.advanced(by: offset)
            .assumingMemoryBound(to: AudioChannelDescription.self)
            .advanced(by: index)
    }

    fileprivate static func mutableDescriptionPointer(
        base: UnsafeMutableRawPointer,
        index: Int
    ) -> Swift.UnsafeMutablePointer<AudioChannelDescription> {
        let offset = MemoryLayout<AudioChannelLayout>.offset(of: \.mChannelDescriptions)!
        return base.advanced(by: offset)
            .assumingMemoryBound(to: AudioChannelDescription.self)
            .advanced(by: index)
    }
}

/// A managed, copy-on-write wrapper around an `AudioChannelLayout`.
///
/// This structure is used to specify channel layouts in files and hardware.
public struct ManagedAudioChannelLayout: Equatable {
    fileprivate final class Storage {
        var pointer: Swift.UnsafeMutablePointer<AudioChannelLayout>
        var capacity: Int
        var deallocator: ((AudioChannelLayout.UnsafePointer) -> Void)?

        init(
            pointer: Swift.UnsafeMutablePointer<AudioChannelLayout>,
            capacity: Int,
            deallocator: ((AudioChannelLayout.UnsafePointer) -> Void)?
        ) {
            self.pointer = pointer
            self.capacity = capacity
            self.deallocator = deallocator
        }

        deinit {
            let overlay = AudioChannelLayout.UnsafePointer(Swift.UnsafePointer(pointer))
            if let deallocator {
                deallocator(overlay)
            } else {
                coreAudioDeallocate(UnsafeMutableRawPointer(pointer))
            }
        }

        func copy() -> Storage {
            let byteCount = AudioChannelLayout.sizeInBytes(maximumDescriptions: capacity)
            let raw = coreAudioAllocateZeroed(byteCount)
            raw.copyMemory(from: UnsafeRawPointer(pointer), byteCount: byteCount)
            let newPointer = raw.bindMemory(to: AudioChannelLayout.self, capacity: 1)
            return Storage(pointer: newPointer, capacity: capacity, deallocator: nil)
        }
    }

    fileprivate var storage: Storage

    /// Creates a new `ManagedAudioChannelLayout` from an existing pointer to an
    /// `AudioChannelLayout`.
    ///
    /// Any mutation on the new `ManagedAudioChannelLayout` will perform a copy of
    /// the `audioChannelLayoutPointer` values.
    public init(
        audioChannelLayoutPointer: AudioChannelLayout.UnsafePointer,
        deallocator: @escaping (AudioChannelLayout.UnsafePointer) -> Void
    ) {
        let mutable = Swift.UnsafeMutablePointer(
            mutating: audioChannelLayoutPointer.unsafePointer
        )
        storage = Storage(
            pointer: mutable,
            capacity: Int(mutable.pointee.mNumberChannelDescriptions),
            deallocator: deallocator
        )
    }

    /// Creates a new `ManagedAudioChannelLayout` that can hold up to
    /// `maximumDescriptions`.
    ///
    /// Use `ManagedAudioChannelLayout(tag:)` if no `AudioChannelDescription` are
    /// needed.
    ///
    /// - Parameter maximumDescriptions: The maximum number of
    ///   `AudioChannelDescription` this `ManagedAudioChannelLayout` can hold.
    ///   This must be greater than `0`.
    public init(maximumDescriptions: Int) {
        precondition(maximumDescriptions > 0, "maximumDescriptions must be greater than 0")
        let allocated = AudioChannelLayout.allocate(maximumDescriptions: maximumDescriptions)
        storage = Storage(
            pointer: allocated.unsafeMutablePointer,
            capacity: maximumDescriptions,
            deallocator: nil
        )
    }

    /// Creates a new `ManagedAudioChannelLayout` from an array of
    /// `AudioChannelDescription`.
    public init(channelDescriptions: [AudioChannelDescription]) {
        let count = max(channelDescriptions.count, 1)
        let allocated = AudioChannelLayout.allocate(maximumDescriptions: count)
        allocated.unsafeMutablePointer.pointee.mNumberChannelDescriptions = UInt32(channelDescriptions.count)
        for (index, description) in channelDescriptions.enumerated() {
            allocated[index] = description
        }
        storage = Storage(
            pointer: allocated.unsafeMutablePointer,
            capacity: count,
            deallocator: nil
        )
    }

    /// Creates a new `ManagedAudioChannelLayout` with a given tag.
    public init(tag: AudioChannelLayoutTag) {
        let allocated = AudioChannelLayout.allocate(maximumDescriptions: 0)
        allocated.unsafeMutablePointer.pointee.mChannelLayoutTag = tag
        allocated.unsafeMutablePointer.pointee.mNumberChannelDescriptions = 0
        storage = Storage(
            pointer: allocated.unsafeMutablePointer,
            capacity: 0,
            deallocator: nil
        )
    }

    private mutating func ensureUnique() {
        if !isKnownUniquelyReferenced(&storage) {
            storage = storage.copy()
        }
    }

    /// The `AudioChannelLayoutTag` that indicates the layout.
    public var tag: AudioChannelLayoutTag {
        get { storage.pointer.pointee.mChannelLayoutTag }
        set {
            ensureUnique()
            storage.pointer.pointee.mChannelLayoutTag = newValue
        }
    }

    /// If `tag` is set to `kAudioChannelLayoutTag_UseChannelBitmap`, this is the
    /// channel usage bitmap.
    public var bitmap: AudioChannelBitmap {
        get { storage.pointer.pointee.mChannelBitmap }
        set {
            ensureUnique()
            storage.pointer.pointee.mChannelBitmap = newValue
        }
    }

    /// The size, in bytes, of the backing `AudioChannelLayout`.
    public var sizeInBytes: Int {
        AudioChannelLayout.sizeInBytes(maximumDescriptions: max(storage.capacity, Int(storage.pointer.pointee.mNumberChannelDescriptions)))
    }

    /// The number of channels described by this `ManagedAudioChannelLayout`.
    public var numberOfChannels: Int {
        let tag = storage.pointer.pointee.mChannelLayoutTag
        if tag == kAudioChannelLayoutTag_UseChannelDescriptions {
            return Int(storage.pointer.pointee.mNumberChannelDescriptions)
        }
        if tag == kAudioChannelLayoutTag_UseChannelBitmap {
            return storage.pointer.pointee.mChannelBitmap.rawValue.nonzeroBitCount
        }
        return Int(AudioChannelLayoutTag_GetNumberOfChannels(tag))
    }

    /// Sets all `AudioChannelDescriptions` to `kAudioChannelLabel_Unknown`.
    public mutating func setAllToUnknown() {
        ensureUnique()
        let count = Int(storage.pointer.pointee.mNumberChannelDescriptions)
        for index in 0..<count {
            AudioChannelLayout.mutableDescriptionPointer(
                base: UnsafeMutableRawPointer(storage.pointer),
                index: index
            ).pointee = AudioChannelDescription(
                mChannelLabel: kAudioChannelLabel_Unknown,
                mChannelFlags: [],
                mCoordinates: (0, 0, 0)
            )
        }
    }

    public var channelDescriptions: ChannelDescriptions {
        get { ChannelDescriptions(storage: storage) }
        set {
            applyChannelDescriptions(newValue)
        }
        _modify {
            ensureUnique()
            var view = ChannelDescriptions(storage: storage)
            yield &view
            if view.storage !== storage {
                storage = view.storage
            }
        }
    }

    private mutating func applyChannelDescriptions(_ newValue: ChannelDescriptions) {
        ensureUnique()
        let newCount = newValue.count
        if newCount > storage.capacity {
            let allocated = AudioChannelLayout.allocate(maximumDescriptions: max(newCount, 1))
            allocated.unsafeMutablePointer.pointee.mChannelLayoutTag = storage.pointer.pointee.mChannelLayoutTag
            allocated.unsafeMutablePointer.pointee.mChannelBitmap = storage.pointer.pointee.mChannelBitmap
            allocated.unsafeMutablePointer.pointee.mNumberChannelDescriptions = UInt32(newCount)
            for index in 0..<newCount {
                allocated[index] = newValue[index]
            }
            storage = Storage(
                pointer: allocated.unsafeMutablePointer,
                capacity: max(newCount, 1),
                deallocator: nil
            )
            return
        }
        storage.pointer.pointee.mNumberChannelDescriptions = UInt32(newCount)
        for index in 0..<newCount {
            AudioChannelLayout.mutableDescriptionPointer(
                base: UnsafeMutableRawPointer(storage.pointer),
                index: index
            ).pointee = newValue[index]
        }
    }

    /// Calls a closure with a pointer to the backing `AudioChannelLayout`.
    public func withUnsafePointer<Result>(
        _ body: (Swift.UnsafePointer<AudioChannelLayout>) throws -> Result
    ) rethrows -> Result {
        try body(Swift.UnsafePointer(storage.pointer))
    }

    /// Calls a closure with a mutable pointer to the backing `AudioChannelLayout`.
    ///
    /// It is invalid to increase mNumberChannelDescriptions.
    public mutating func withUnsafeMutablePointer<Result>(
        _ body: (Swift.UnsafeMutablePointer<AudioChannelLayout>) throws -> Result
    ) rethrows -> Result {
        ensureUnique()
        return try body(storage.pointer)
    }

    public static func == (lhs: ManagedAudioChannelLayout, rhs: ManagedAudioChannelLayout) -> Bool {
        lhs.tag == rhs.tag
            && lhs.bitmap == rhs.bitmap
            && lhs.channelDescriptions == rhs.channelDescriptions
    }

    public struct ChannelDescriptions: RandomAccessCollection, MutableCollection, Equatable {
        public typealias Element = AudioChannelDescription
        public typealias Index = Int
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<ChannelDescriptions>
        public typealias Iterator = IndexingIterator<ChannelDescriptions>

        fileprivate var storage: Storage

        fileprivate init(storage: Storage) {
            self.storage = storage
        }

        public var count: Int { Int(storage.pointer.pointee.mNumberChannelDescriptions) }
        public var startIndex: Int { 0 }
        public var endIndex: Int { count }

        public subscript(index: Index) -> Element {
            get {
                precondition(index >= startIndex && index < endIndex, "channel description index out of range")
                return AudioChannelLayout.mutableDescriptionPointer(
                    base: UnsafeMutableRawPointer(storage.pointer),
                    index: index
                ).pointee
            }
            set {
                precondition(index >= startIndex && index < endIndex, "channel description index out of range")
                if !isKnownUniquelyReferenced(&storage) {
                    storage = storage.copy()
                }
                AudioChannelLayout.mutableDescriptionPointer(
                    base: UnsafeMutableRawPointer(storage.pointer),
                    index: index
                ).pointee = newValue
            }
        }

        public func index(after i: Index) -> Index { i + 1 }
        public func index(before i: Index) -> Index { i - 1 }

        public static func == (lhs: ChannelDescriptions, rhs: ChannelDescriptions) -> Bool {
            guard lhs.count == rhs.count else { return false }
            for index in 0..<lhs.count {
                if !(lhs[index] == rhs[index]) {
                    return false
                }
            }
            return true
        }
    }
}
