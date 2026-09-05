
import CoreFoundation

// Packet / event-list overlay: C layout plus Swift Collection views.

// MARK: - MIDIPacket (C overlay, 256-byte data slot)

public struct MIDIPacket {
    public var timeStamp: MIDITimeStamp
    public var length: UInt16
    public var data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

    public init() {
        timeStamp = 0
        length = 0
        data = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(timeStamp: MIDITimeStamp, length: UInt16, data: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) {
        self.timeStamp = timeStamp
        self.length = length
        self.data = data
    }
}

extension MIDIPacket {
    public struct ByteSequence: Sequence {
        public typealias Element = UInt8
        let base: UnsafePointer<MIDIPacket>
        public var count: Int { Int(base.pointee.length) }
        public func makeIterator() -> Iterator { Iterator(self) }
        public struct Iterator: IteratorProtocol {
            public typealias Element = UInt8
            let base: UnsafePointer<MIDIPacket>
            var index: Int
            let end: Int
            public init(_ s: ByteSequence) {
                self.base = s.base
                self.index = 0
                self.end = s.count
            }
            public mutating func next() -> UInt8? {
                guard index < end else { return nil }
                let value = withUnsafeBytes(of: base.pointee.data) { raw in
                    raw.bindMemory(to: UInt8.self)[index]
                }
                index += 1
                return value
            }
        }
    }

    public struct ByteCollection: RandomAccessCollection {
        public typealias Element = UInt8
        public typealias Index = Int
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<ByteCollection>
        public typealias Iterator = IndexingIterator<ByteCollection>
        let base: UnsafePointer<MIDIPacket>
        public init(_ p: UnsafePointer<MIDIPacket>) { self.base = p }
        public init?(_ p: UnsafePointer<MIDIPacket>?) {
            guard let p else { return nil }
            self.base = p
        }
        public var startIndex: Int { 0 }
        public var count: Int { Int(base.pointee.length) }
        public var endIndex: Int { count }
        public subscript(index: Int) -> UInt8 {
            precondition(index >= 0 && index < count)
            return withUnsafeBytes(of: base.pointee.data) { raw in
                raw.bindMemory(to: UInt8.self)[index]
            }
        }
    }

    public final class Builder {
        var storage: [UInt8]
        public var timeStamp: Int
        public let capacity: Int
        public var count: Int { storage.count }
        public init(maximumNumberMIDIBytes: Int) {
            self.capacity = max(0, maximumNumberMIDIBytes)
            self.storage = []
            self.timeStamp = 0
        }
        public func append(_ midiBytes: UInt8...) {
            let room = capacity - storage.count
            if room > 0 {
                storage.append(contentsOf: midiBytes.prefix(room))
            }
        }
        public func withUnsafePointer<Result>(_ body: (UnsafePointer<MIDIPacket>) -> Result) -> Result {
            var packet = MIDIPacket()
            packet.timeStamp = MIDITimeStamp(timeStamp)
            packet.length = UInt16(Swift.min(storage.count, 256))
            withUnsafeMutableBytes(of: &packet.data) { raw in
                let buf = raw.bindMemory(to: UInt8.self)
                for i in 0..<Int(packet.length) { buf[i] = storage[i] }
            }
            return Swift.withUnsafePointer(to: &packet, body)
        }
        public func withUnsafeMutableMIDIPacketPointer<Result>(
            _ body: (inout UnsafeMutableMIDIPacketPointer) -> Result
        ) -> Result {
            var packet = MIDIPacket()
            packet.timeStamp = MIDITimeStamp(timeStamp)
            packet.length = UInt16(Swift.min(storage.count, 256))
            withUnsafeMutableBytes(of: &packet.data) { raw in
                let buf = raw.bindMemory(to: UInt8.self)
                for i in 0..<Int(packet.length) { buf[i] = storage[i] }
            }
            return Swift.withUnsafeMutablePointer(to: &packet) { p in
                var view = UnsafeMutableMIDIPacketPointer(p)
                let result = body(&view)
                storage = (0..<view.count).map { view[$0] }
                timeStamp = view.timeStamp
                return result
            }
        }
    }
}

public struct UnsafeMutableMIDIPacketPointer: RandomAccessCollection, MutableCollection {
    public typealias Element = UInt8
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UnsafeMutableMIDIPacketPointer>
    public typealias Iterator = MIDIPacket.ByteSequence.Iterator
    public let pointer: UnsafeMutablePointer<MIDIPacket>
    public init(_ p: UnsafeMutablePointer<MIDIPacket>) { self.pointer = p }
    public init?(_ p: UnsafeMutablePointer<MIDIPacket>?) {
        guard let p else { return nil }
        self.pointer = p
    }
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    public var count: Int {
        get { Int(pointer.pointee.length) }
        nonmutating set {
            pointer.pointee.length = UInt16(Swift.min(Swift.max(0, newValue), 256))
        }
    }
    public var timeStamp: Int {
        get { Int(pointer.pointee.timeStamp) }
        nonmutating set { pointer.pointee.timeStamp = MIDITimeStamp(newValue) }
    }
    public subscript(index: Int) -> UInt8 {
        get {
            precondition(index >= 0 && index < 256)
            return withUnsafeBytes(of: pointer.pointee.data) { raw in
                raw.bindMemory(to: UInt8.self)[index]
            }
        }
        nonmutating set {
            precondition(index >= 0 && index < 256)
            withUnsafeMutableBytes(of: &pointer.pointee.data) { raw in
                raw.bindMemory(to: UInt8.self)[index] = newValue
            }
        }
    }
    public func makeIterator() -> MIDIPacket.ByteSequence.Iterator {
        MIDIPacket.ByteSequence(base: UnsafePointer(pointer)).makeIterator()
    }
}

extension UnsafePointer where Pointee == MIDIPacket {
    public func bytes() -> MIDIPacket.ByteCollection { MIDIPacket.ByteCollection(self) }
    public func sequence() -> MIDIPacket.ByteSequence { MIDIPacket.ByteSequence(base: self) }
}

// MARK: - MIDIPacketList

public struct MIDIPacketList {
    public var numPackets: UInt32
    public var packet: MIDIPacket
    public init() {
        numPackets = 0
        packet = MIDIPacket()
    }
    public init(numPackets: UInt32, packet: MIDIPacket) {
        self.numPackets = numPackets
        self.packet = packet
    }
    public static func sizeInBytes(pktList: UnsafePointer<MIDIPacketList>) -> Int {
        midiPacketListSize(pktList)
    }
}

extension MIDIPacketList {
    public struct UnsafeSequence: Sequence {
        public typealias Element = UnsafePointer<MIDIPacket>
        let base: UnsafePointer<MIDIPacketList>
        public var count: Int { Int(base.pointee.numPackets) }
        public func makeIterator() -> Iterator { Iterator(self) }
        public struct Iterator: IteratorProtocol {
            public typealias Element = UnsafePointer<MIDIPacket>
            let base: UnsafePointer<MIDIPacketList>
            var remaining: Int
            var current: UnsafePointer<MIDIPacket>?
            public init(_ s: UnsafeSequence) {
                self.base = s.base
                self.remaining = s.count
                if s.count > 0 {
                    self.current = midiPacketListFirstPacket(s.base)
                } else {
                    self.current = nil
                }
            }
            public mutating func next() -> UnsafePointer<MIDIPacket>? {
                guard remaining > 0, let current else { return nil }
                remaining -= 1
                let result = current
                if remaining > 0 {
                    self.current = UnsafePointer(MIDIPacketNext(current))
                } else {
                    self.current = nil
                }
                return result
            }
        }
    }

    public final class Builder {
        let byteSize: Int
        var storage: UnsafeMutableRawPointer
        var list: UnsafeMutablePointer<MIDIPacketList>
        var cursor: UnsafeMutablePointer<MIDIPacket>
        public init(byteSize: Int) {
            self.byteSize = max(byteSize, MemoryLayout<MIDIPacketList>.size)
            self.storage = UnsafeMutableRawPointer.allocate(byteCount: self.byteSize, alignment: 8)
            self.storage.initializeMemory(as: UInt8.self, repeating: 0, count: self.byteSize)
            self.list = storage.assumingMemoryBound(to: MIDIPacketList.self)
            self.cursor = MIDIPacketListInit(list)
        }
        deinit { storage.deallocate() }
        public var count: Int { Int(list.pointee.numPackets) }
        public func clear() { cursor = MIDIPacketListInit(list) }
        @discardableResult
        public func append(timestamp: MIDITimeStamp, data: [UInt8]) -> UnsafePointer<MIDIPacket>? {
            let before = list.pointee.numPackets
            let written = data.withUnsafeBufferPointer { buf in
                MIDIPacketListAdd(list, byteSize, cursor, timestamp, buf.count, buf.baseAddress!)
            }
            if list.pointee.numPackets == before {
                return nil
            }
            cursor = written
            return UnsafePointer(written)
        }
        public func withUnsafePointer<Result>(_ body: (UnsafePointer<MIDIPacketList>) -> Result) -> Result {
            body(UnsafePointer(list))
        }
        public func withUnsafeMutableMIDIPacketListPointer<Result>(
            _ body: (inout UnsafeMutableMIDIPacketListPointer) -> Result
        ) -> Result {
            var view = UnsafeMutableMIDIPacketListPointer(list, byteSize: byteSize)
            return body(&view)
        }
    }
}

public struct UnsafeMutableMIDIPacketListPointer: Sequence {
    public typealias Element = UnsafePointer<MIDIPacket>
    public typealias Iterator = MIDIPacketList.UnsafeSequence.Iterator
    public let pointer: UnsafeMutablePointer<MIDIPacketList>
    public let byteSize: Int
    public init(_ p: UnsafeMutablePointer<MIDIPacketList>, byteSize: Int) {
        self.pointer = p
        self.byteSize = byteSize
    }
    public init?(_ p: UnsafeMutablePointer<MIDIPacketList>?, byteSize: Int) {
        guard let p else { return nil }
        self.pointer = p
        self.byteSize = byteSize
    }
    public var count: Int { Int(pointer.pointee.numPackets) }
    public var listSizeInBytes: Int { midiPacketListSize(UnsafePointer(pointer)) }
    public var lastPacket: UnsafeMutablePointer<MIDIPacket>? {
        guard count > 0 else { return nil }
        var pkt = midiPacketListFirstPacket(UnsafePointer(pointer))
        if count == 1 { return UnsafeMutablePointer(mutating: pkt) }
        for _ in 1..<count {
            pkt = UnsafePointer(MIDIPacketNext(pkt))
        }
        return UnsafeMutablePointer(mutating: pkt)
    }
    public mutating func clear() {
        _ = MIDIPacketListInit(pointer)
    }
    @discardableResult
    public mutating func append(timestamp: MIDITimeStamp, data: [UInt8]) -> UnsafePointer<MIDIPacket>? {
        let before = pointer.pointee.numPackets
        let cur = lastPacket ?? MIDIPacketListInit(pointer)
        let next = data.withUnsafeBufferPointer { buf in
            MIDIPacketListAdd(pointer, byteSize, cur, timestamp, buf.count, buf.baseAddress!)
        }
        if pointer.pointee.numPackets == before {
            return nil
        }
        return UnsafePointer(next)
    }
    public func makeIterator() -> MIDIPacketList.UnsafeSequence.Iterator {
        MIDIPacketList.UnsafeSequence(base: UnsafePointer(pointer)).makeIterator()
    }
}

extension UnsafePointer where Pointee == MIDIPacketList {
    public func unsafeSequence() -> MIDIPacketList.UnsafeSequence {
        MIDIPacketList.UnsafeSequence(base: self)
    }
}

func midiPacketNextOffset(length: UInt16) -> Int {
    let header = MemoryLayout<MIDITimeStamp>.size + MemoryLayout<UInt16>.size
    let dataEnd = header + Int(length)
    return (dataEnd + 7) & ~7
}

func midiPacketListFirstPacket(_ pktList: UnsafePointer<MIDIPacketList>) -> UnsafePointer<MIDIPacket> {
    let offset = MemoryLayout<MIDIPacketList>.offset(of: \.packet) ?? MemoryLayout<UInt32>.stride
    return UnsafeRawPointer(pktList).advanced(by: offset).assumingMemoryBound(to: MIDIPacket.self)
}

func midiPacketListSize(_ pktList: UnsafePointer<MIDIPacketList>) -> Int {
    let count = Int(pktList.pointee.numPackets)
    var size = MemoryLayout<MIDIPacketList>.offset(of: \.packet) ?? MemoryLayout<UInt32>.stride
    if count == 0 { return size }
    var pkt = midiPacketListFirstPacket(pktList)
    for i in 0..<count {
        size += midiPacketNextOffset(length: pkt.pointee.length)
        if i + 1 < count {
            pkt = UnsafePointer(MIDIPacketNext(pkt))
        }
    }
    return size
}

public func MIDIPacketNext(_ pkt: UnsafePointer<MIDIPacket>) -> UnsafeMutablePointer<MIDIPacket> {
    let offset = midiPacketNextOffset(length: pkt.pointee.length)
    return UnsafeMutablePointer(mutating: UnsafeRawPointer(pkt).advanced(by: offset).assumingMemoryBound(to: MIDIPacket.self))
}

@discardableResult
public func MIDIPacketListInit(_ pktlist: UnsafeMutablePointer<MIDIPacketList>) -> UnsafeMutablePointer<MIDIPacket> {
    pktlist.pointee.numPackets = 0
    return UnsafeMutablePointer(mutating: midiPacketListFirstPacket(UnsafePointer(pktlist)))
}

@discardableResult
public func MIDIPacketListAdd(
    _ pktlist: UnsafeMutablePointer<MIDIPacketList>,
    _ listSize: Int,
    _ curPacket: UnsafeMutablePointer<MIDIPacket>,
    _ time: MIDITimeStamp,
    _ nData: Int,
    _ data: UnsafePointer<UInt8>
) -> UnsafeMutablePointer<MIDIPacket> {
    let needed = midiPacketNextOffset(length: UInt16(nData))
    let start = UnsafeMutableRawPointer(pktlist)
    let used = UnsafeMutableRawPointer(curPacket) - start
    if used + needed > listSize {
        return curPacket
    }
    curPacket.pointee.timeStamp = time
    curPacket.pointee.length = UInt16(Swift.min(nData, 256))
    withUnsafeMutableBytes(of: &curPacket.pointee.data) { raw in
        let buf = raw.bindMemory(to: UInt8.self)
        for i in 0..<Int(curPacket.pointee.length) {
            buf[i] = data[i]
        }
    }
    pktlist.pointee.numPackets += 1
    return MIDIPacketNext(UnsafePointer(curPacket))
}
