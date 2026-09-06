import CoreFoundation
import Dispatch
import Foundation

/// Linux overlay of Apple's `CMReadOnlyDataBlockBuffer` / `CMMutableDataBlockBuffer`.
/// Storage is an owned contiguous byte array (copy-in), matching this port's
/// `CMBlockBuffer` policy. Caller-supplied memory blocks are not retained as
/// live shared pages. `AudioBufferList` constructors stay deferred until
/// CoreAudioTypes is imported by the central build.

internal final class CMDataBlockStorage: @unchecked Sendable {
    var bytes: [UInt8]
    init(_ bytes: [UInt8] = []) {
        self.bytes = bytes
    }
}

public struct CMReadOnlyDataBlockBuffer: Sendable {
    public typealias Index = Int
    public typealias Element = UInt8
    public typealias Indices = Range<Int>
    public typealias Regions = [BlockRegion]
    public typealias Iterator = IndexingIterator<CMReadOnlyDataBlockBuffer>
    public typealias SubSequence = CMReadOnlyDataBlockBuffer

    internal var storage: CMDataBlockStorage

    public init(subBlockCapacity: Int = 0) {
        _ = subBlockCapacity
        self.storage = CMDataBlockStorage()
    }

    public init(unsafeBlockBuffer: CMBlockBuffer) {
        self.storage = CMDataBlockStorage((try? unsafeBlockBuffer.dataBytes()).map { Array($0) } ?? [])
    }

    public init(_ data: Data) {
        self.storage = CMDataBlockStorage(Array(data))
    }

    public init(_ dispatchData: DispatchData) {
        self.storage = CMDataBlockStorage(Array(dispatchData))
    }

    public init(_ source: consuming CMMutableDataBlockBuffer) {
        self.storage = source.storage
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { storage.bytes.count }
    public var count: Int { storage.bytes.count }
    public var isEmpty: Bool { storage.bytes.isEmpty }
    public var indices: Range<Int> { 0..<count }
    public var isContiguous: Bool { true }

    public subscript(position: Int) -> UInt8 {
        storage.bytes[position]
    }

    public subscript(range: Range<Int>) -> CMReadOnlyDataBlockBuffer {
        CMReadOnlyDataBlockBuffer(storage: CMDataBlockStorage(Array(storage.bytes[range])))
    }

    public var regions: [BlockRegion] {
        [BlockRegion(storage: storage, startIndex: 0, count: count)]
    }

    public func withUnsafeBlockBuffer<R>(
        _ body: (CMBlockBuffer) throws -> R
    ) rethrows -> R {
        try body(CMBlockBuffer(data: Data(storage.bytes)))
    }

    public mutating func append(referenceOf other: consuming CMMutableDataBlockBuffer, optimizeDepth: Bool = true) {
        _ = optimizeDepth
        storage.bytes.append(contentsOf: other.storage.bytes)
    }

    public mutating func append(referenceOf other: CMReadOnlyDataBlockBuffer, optimizeDepth: Bool = true) {
        _ = optimizeDepth
        storage.bytes.append(contentsOf: other.storage.bytes)
    }

    public static func + (
        a: CMReadOnlyDataBlockBuffer,
        b: consuming CMMutableDataBlockBuffer
    ) -> CMReadOnlyDataBlockBuffer {
        var copy = a
        copy.append(referenceOf: b)
        return copy
    }

    public static func + (
        a: CMReadOnlyDataBlockBuffer,
        b: CMReadOnlyDataBlockBuffer
    ) -> CMReadOnlyDataBlockBuffer {
        var copy = a
        copy.append(referenceOf: b)
        return copy
    }

    public static func += (lhs: inout CMReadOnlyDataBlockBuffer, rhs: consuming CMMutableDataBlockBuffer) {
        lhs.append(referenceOf: rhs)
    }

    public static func += (lhs: inout CMReadOnlyDataBlockBuffer, rhs: CMReadOnlyDataBlockBuffer) {
        lhs.append(referenceOf: rhs)
    }

    public func withContiguousStorageIfAvailable<R>(
        _ body: (UnsafeBufferPointer<UInt8>) throws -> R
    ) rethrows -> R? {
        try storage.bytes.withUnsafeBufferPointer { try body($0) }
    }

    internal init(storage: CMDataBlockStorage) {
        self.storage = storage
    }

    public struct BlockRegion: Sendable {
        public typealias Index = Int
        public typealias Element = UInt8
        public typealias Indices = Range<Int>
        public typealias Regions = CollectionOfOne<BlockRegion>
        public typealias Iterator = IndexingIterator<BlockRegion>
        public typealias SubSequence = Slice<BlockRegion>

        internal var storage: CMDataBlockStorage
        public let startIndex: Int
        public var count: Int
        public var endIndex: Int { startIndex + count }
        public var regions: CollectionOfOne<BlockRegion> { CollectionOfOne(self) }

        public subscript(position: Int) -> UInt8 {
            storage.bytes[position]
        }

        public func withUnsafeBytes<ResultType>(
            _ body: (UnsafeRawBufferPointer) throws -> ResultType
        ) rethrows -> ResultType {
            try storage.bytes.withUnsafeBytes { buffer in
                try body(UnsafeRawBufferPointer(rebasing: buffer[startIndex..<endIndex]))
            }
        }

        public func withContiguousStorageIfAvailable<R>(
            _ body: (UnsafeBufferPointer<UInt8>) throws -> R
        ) rethrows -> R? {
            try storage.bytes.withUnsafeBufferPointer { buffer in
                try body(UnsafeBufferPointer(rebasing: buffer[startIndex..<endIndex]))
            }
        }
    }
}

extension CMReadOnlyDataBlockBuffer: RandomAccessCollection, ContiguousBytes, DataProtocol {
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try storage.bytes.withUnsafeBytes(body)
    }
}

extension CMReadOnlyDataBlockBuffer.BlockRegion: RandomAccessCollection, ContiguousBytes, DataProtocol {}

public struct CMMutableDataBlockBuffer: @unchecked Sendable {
    public typealias Index = Int
    public typealias Indices = Range<Int>

    internal var storage: CMDataBlockStorage
    internal var blockSource: BlockSource?

    public init(subBlockCapacity: Int, blockSource: BlockSource? = nil) {
        _ = subBlockCapacity
        self.storage = CMDataBlockStorage()
        self.blockSource = blockSource
    }

    public init(unsafeBlockBuffer: CMBlockBuffer) {
        self.storage = CMDataBlockStorage((try? unsafeBlockBuffer.dataBytes()).map { Array($0) } ?? [])
    }

    public init(count: Int = 0, blockSource: BlockSource? = nil) {
        if let blockSource, count > 0 {
            let allocated = blockSource.allocate(count)
            let bytes = Array(allocated)
            blockSource.deallocate(allocated)
            self.storage = CMDataBlockStorage(bytes)
        } else {
            self.storage = CMDataBlockStorage(Array(repeating: 0, count: Swift.max(0, count)))
        }
        self.blockSource = blockSource
    }

    public var startIndex: Int { 0 }
    public var endIndex: Int { storage.bytes.count }
    public var count: Int { storage.bytes.count }
    public var isEmpty: Bool { storage.bytes.isEmpty }
    public var indices: Range<Int> { 0..<count }
    public var isContiguous: Bool { true }

    public subscript(position: Int) -> UInt8 {
        get { storage.bytes[position] }
        set { storage.bytes[position] = newValue }
    }

    public func isRangeContiguous(_ range: Range<Int>) -> Bool {
        range.lowerBound >= 0 && range.upperBound <= count
    }

    public mutating func replaceAll(with bytes: UnsafeRawBufferPointer) {
        storage.bytes = Array(bytes)
    }

    public mutating func replaceAll(with bytes: some DataProtocol) {
        storage.bytes = Array(bytes)
    }

    public mutating func replaceAll(repeating byte: UInt8) {
        for index in storage.bytes.indices {
            storage.bytes[index] = byte
        }
    }

    public mutating func replaceSubrange<C: Collection>(_ range: Range<Int>, with newElements: C) where C.Element == UInt8 {
        storage.bytes.replaceSubrange(range, with: Array(newElements))
    }

    public mutating func replaceSubrange(_ range: Range<Int>, with bytes: UnsafeRawBufferPointer) {
        storage.bytes.replaceSubrange(range, with: bytes)
    }

    public mutating func replaceSubrange(_ range: Range<Int>, with bytes: some DataProtocol) {
        storage.bytes.replaceSubrange(range, with: Array(bytes))
    }

    public mutating func replaceSubrange(_ range: Range<Int>, repeating byte: UInt8) {
        storage.bytes.replaceSubrange(range, with: Array(repeating: byte, count: range.count))
    }

    public mutating func replaceSubrange(_ range: Range<Int>, with newElements: [UInt8]) {
        storage.bytes.replaceSubrange(range, with: newElements)
    }

    public static func += (lhs: inout CMMutableDataBlockBuffer, rhs: consuming CMMutableDataBlockBuffer) {
        lhs.storage.bytes.append(contentsOf: rhs.storage.bytes)
    }

    public mutating func append(referenceOf other: consuming CMMutableDataBlockBuffer, range: Range<Int>? = nil, optimizeDepth: Bool = true) {
        _ = optimizeDepth
        let slice = range.map { Array(other.storage.bytes[$0]) } ?? other.storage.bytes
        storage.bytes.append(contentsOf: slice)
    }

    public mutating func extend(by count: Int) {
        storage.bytes.append(contentsOf: Array(repeating: 0, count: Swift.max(0, count)))
    }

    public func copyBytes<R>(
        to destination: UnsafeMutableRawBufferPointer,
        from range: R
    ) where R: RangeExpression, R.Bound == Int {
        let resolved = range.relative(to: storage.bytes)
        let count = Swift.min(destination.count, resolved.count)
        if count == 0 { return }
        storage.bytes[resolved].withUnsafeBytes { source in
            destination.baseAddress!.copyMemory(from: source.baseAddress!, byteCount: count)
        }
    }

    public func copyBytes(to destination: UnsafeMutableRawBufferPointer) {
        copyBytes(to: destination, from: 0..<count)
    }

    public func withUnsafeBlockBuffer<R>(
        _ body: (CMBlockBuffer) throws -> R
    ) rethrows -> R {
        try body(CMBlockBuffer(data: Data(storage.bytes)))
    }

    public func withUnsafeBlockRegions<R>(
        _ body: ([CMReadOnlyDataBlockBuffer.BlockRegion]) throws -> R
    ) rethrows -> R {
        let region = CMReadOnlyDataBlockBuffer.BlockRegion(
            storage: storage,
            startIndex: 0,
            count: count
        )
        return try body([region])
    }

    public mutating func withUnsafeMutableBlockRegions<R>(
        _ body: ([BlockRegion]) throws -> R
    ) rethrows -> R {
        try body([BlockRegion(storage: storage, startIndex: 0, count: count)])
    }

    public func withContiguousStorageIfAvailable<R>(
        in range: Range<Int>? = nil,
        _ body: (UnsafeRawBufferPointer) throws -> R
    ) rethrows -> R? {
        let resolved = range ?? (0..<count)
        return try storage.bytes.withUnsafeBytes { buffer in
            try body(UnsafeRawBufferPointer(rebasing: buffer[resolved]))
        }
    }

    public mutating func withContiguousMutableStorageIfAvailable<R>(
        in range: Range<Int>? = nil,
        _ body: (UnsafeMutableRawBufferPointer) throws -> R
    ) rethrows -> R? {
        let resolved = range ?? (0..<count)
        return try storage.bytes.withUnsafeMutableBytes { buffer in
            try body(UnsafeMutableRawBufferPointer(rebasing: buffer[resolved]))
        }
    }

    public struct BlockRegion {
        public typealias Index = Int
        public typealias Element = UInt8
        public typealias Indices = Range<Int>
        public typealias Regions = CollectionOfOne<BlockRegion>
        public typealias Iterator = IndexingIterator<BlockRegion>
        public typealias SubSequence = Slice<BlockRegion>

        internal var storage: CMDataBlockStorage
        public let startIndex: Int
        public var count: Int
        public var endIndex: Int { startIndex + count }
        public var regions: CollectionOfOne<BlockRegion> { CollectionOfOne(self) }

        public subscript(position: Int) -> UInt8 {
            get { storage.bytes[position] }
            set { storage.bytes[position] = newValue }
        }

        public func withUnsafeBytes<ResultType>(
            _ body: (UnsafeRawBufferPointer) throws -> ResultType
        ) rethrows -> ResultType {
            try storage.bytes.withUnsafeBytes { buffer in
                try body(UnsafeRawBufferPointer(rebasing: buffer[startIndex..<endIndex]))
            }
        }

        public func withUnsafeMutableBytes<ResultType>(
            _ body: (UnsafeMutableRawBufferPointer) throws -> ResultType
        ) rethrows -> ResultType {
            try storage.bytes.withUnsafeMutableBytes { buffer in
                try body(UnsafeMutableRawBufferPointer(rebasing: buffer[startIndex..<endIndex]))
            }
        }
    }

    public struct BlockSource {
        public var allocate: (Int) -> UnsafeMutableRawBufferPointer
        public var deallocate: (UnsafeMutableRawBufferPointer) -> Void

        public init(
            allocate: @escaping (Int) -> UnsafeMutableRawBufferPointer,
            deallocate: @escaping (UnsafeMutableRawBufferPointer) -> Void
        ) {
            self.allocate = allocate
            self.deallocate = deallocate
        }
    }

    public final class MemoryPool {
        private let ageOutDuration: TimeInterval

        public init(ageOutDuration: TimeInterval = 0.5) {
            self.ageOutDuration = ageOutDuration
        }

        public func makeBlockBuffer(count: Int) -> CMMutableDataBlockBuffer {
            _ = ageOutDuration
            return CMMutableDataBlockBuffer(count: count)
        }

        public func flush() {}
    }
}

extension CMMutableDataBlockBuffer: MutableCollection, RangeReplaceableCollection {
    public init() {
        self.init(count: 0)
    }

    public func index(after i: Int) -> Int { i + 1 }
    public func index(before i: Int) -> Int { i - 1 }
}

extension CMMutableDataBlockBuffer.BlockRegion: RandomAccessCollection, MutableCollection, ContiguousBytes, DataProtocol {}
