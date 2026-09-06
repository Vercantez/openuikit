import CoreFoundation

// MIDI 2.0 event packets and lists (UMP words).

public struct MIDIEventPacket {
    public var timeStamp: MIDITimeStamp
    public var wordCount: UInt32
    public var words: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)

    public init() {
        timeStamp = 0
        wordCount = 0
        words = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }

    public init(timeStamp: MIDITimeStamp, wordCount: UInt32, words: (UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32, UInt32)) {
        self.timeStamp = timeStamp
        self.wordCount = wordCount
        self.words = words
    }
}

extension MIDIEventPacket {
    public struct WordSequence: Sequence {
        public typealias Element = UInt32
        let base: UnsafePointer<MIDIEventPacket>
        public var count: Int { Int(base.pointee.wordCount) }
        public func makeIterator() -> Iterator { Iterator(self) }
        public struct Iterator: IteratorProtocol {
            public typealias Element = UInt32
            let base: UnsafePointer<MIDIEventPacket>
            var index: Int
            let end: Int
            public init(_ s: WordSequence) {
                self.base = s.base
                self.index = 0
                self.end = s.count
            }
            public mutating func next() -> UInt32? {
                guard index < end else { return nil }
                let value = withUnsafeBytes(of: base.pointee.words) { raw in
                    raw.bindMemory(to: UInt32.self)[index]
                }
                index += 1
                return value
            }
        }
    }

    public struct WordCollection: RandomAccessCollection {
        public typealias Element = UInt32
        public typealias Index = Int
        public typealias Indices = Range<Int>
        public typealias SubSequence = Slice<WordCollection>
        public typealias Iterator = IndexingIterator<WordCollection>
        let base: UnsafePointer<MIDIEventPacket>
        public init(_ p: UnsafePointer<MIDIEventPacket>) { self.base = p }
        public init?(_ p: UnsafePointer<MIDIEventPacket>?) {
            guard let p else { return nil }
            self.base = p
        }
        public var startIndex: Int { 0 }
        public var count: Int { Int(base.pointee.wordCount) }
        public var endIndex: Int { count }
        public subscript(index: Int) -> UInt32 {
            precondition(index >= 0 && index < count)
            return withUnsafeBytes(of: base.pointee.words) { raw in
                raw.bindMemory(to: UInt32.self)[index]
            }
        }
    }

    public final class Builder {
        var storage: [UInt32]
        public var timeStamp: Int
        public let capacity: Int
        public var count: Int { storage.count }
        public init(maximumNumberMIDIWords: Int) {
            self.capacity = max(0, maximumNumberMIDIWords)
            self.storage = []
            self.timeStamp = 0
        }
        public func append(_ midiWords: UInt32...) {
            let room = capacity - storage.count
            if room > 0 { storage.append(contentsOf: midiWords.prefix(room)) }
        }
        public func withUnsafePointer<Result>(_ body: (UnsafePointer<MIDIEventPacket>) -> Result) -> Result {
            var packet = makePacket()
            return Swift.withUnsafePointer(to: &packet, body)
        }
        public func withUnsafeMutableMIDIEventPacketPointer<Result>(
            _ body: (inout UnsafeMutableMIDIEventPacketPointer) -> Result
        ) -> Result {
            var packet = makePacket()
            return Swift.withUnsafeMutablePointer(to: &packet) { p in
                var view = UnsafeMutableMIDIEventPacketPointer(p)
                let result = body(&view)
                storage = (0..<view.count).map { view[$0] }
                timeStamp = view.timeStamp
                return result
            }
        }
        private func makePacket() -> MIDIEventPacket {
            var packet = MIDIEventPacket()
            packet.timeStamp = MIDITimeStamp(timeStamp)
            packet.wordCount = UInt32(Swift.min(storage.count, 64))
            withUnsafeMutableBytes(of: &packet.words) { raw in
                let buf = raw.bindMemory(to: UInt32.self)
                for i in 0..<Int(packet.wordCount) { buf[i] = storage[i] }
            }
            return packet
        }
    }
}

public struct UnsafeMutableMIDIEventPacketPointer: RandomAccessCollection, MutableCollection {
    public typealias Element = UInt32
    public typealias Index = Int
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UnsafeMutableMIDIEventPacketPointer>
    public typealias Iterator = MIDIEventPacket.WordSequence.Iterator
    public let pointer: UnsafeMutablePointer<MIDIEventPacket>
    public init(_ p: UnsafeMutablePointer<MIDIEventPacket>) { self.pointer = p }
    public init?(_ p: UnsafeMutablePointer<MIDIEventPacket>?) {
        guard let p else { return nil }
        self.pointer = p
    }
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }
    public var count: Int {
        get { Int(pointer.pointee.wordCount) }
        nonmutating set { pointer.pointee.wordCount = UInt32(Swift.min(Swift.max(0, newValue), 64)) }
    }
    public var timeStamp: Int {
        get { Int(pointer.pointee.timeStamp) }
        nonmutating set { pointer.pointee.timeStamp = MIDITimeStamp(newValue) }
    }
    public subscript(index: Int) -> UInt32 {
        get {
            precondition(index >= 0 && index < 64)
            return withUnsafeBytes(of: pointer.pointee.words) { raw in
                raw.bindMemory(to: UInt32.self)[index]
            }
        }
        nonmutating set {
            precondition(index >= 0 && index < 64)
            withUnsafeMutableBytes(of: &pointer.pointee.words) { raw in
                raw.bindMemory(to: UInt32.self)[index] = newValue
            }
        }
    }
    public func makeIterator() -> MIDIEventPacket.WordSequence.Iterator {
        MIDIEventPacket.WordSequence(base: UnsafePointer(pointer)).makeIterator()
    }
}

extension UnsafePointer where Pointee == MIDIEventPacket {
    public func words() -> MIDIEventPacket.WordCollection { MIDIEventPacket.WordCollection(self) }
    public func sequence() -> MIDIEventPacket.WordSequence { MIDIEventPacket.WordSequence(base: self) }
}

public struct MIDIEventList {
    public var `protocol`: MIDIProtocolID
    public var numPackets: UInt32
    public var packet: MIDIEventPacket
    public init() {
        self.`protocol` = ._1_0
        numPackets = 0
        packet = MIDIEventPacket()
    }
    public init(protocol: MIDIProtocolID, numPackets: UInt32, packet: MIDIEventPacket) {
        self.`protocol` = `protocol`
        self.numPackets = numPackets
        self.packet = packet
    }
    public static func sizeInBytes(pktList: UnsafePointer<MIDIEventList>) -> Int {
        midiEventListSize(pktList)
    }
}

extension MIDIEventList {
    public struct UnsafeSequence: Sequence {
        public typealias Element = UnsafePointer<MIDIEventPacket>
        let base: UnsafePointer<MIDIEventList>
        public var count: Int { Int(base.pointee.numPackets) }
        public func makeIterator() -> Iterator { Iterator(self) }
        public struct Iterator: IteratorProtocol {
            public typealias Element = UnsafePointer<MIDIEventPacket>
            var remaining: Int
            var current: UnsafePointer<MIDIEventPacket>?
            public init(_ s: UnsafeSequence) {
                self.remaining = s.count
                if s.count > 0 {
                    self.current = firstPacket(s.base)
                } else {
                    self.current = nil
                }
            }
            public mutating func next() -> UnsafePointer<MIDIEventPacket>? {
                guard remaining > 0, let current else { return nil }
                remaining -= 1
                let result = current
                if remaining > 0 {
                    self.current = UnsafePointer(MIDIEventPacketNext(current))
                } else {
                    self.current = nil
                }
                return result
            }
        }
    }

    public final class Builder {
        let wordSize: Int
        var storage: UnsafeMutableRawPointer
        var list: UnsafeMutablePointer<MIDIEventList>
        var cursor: UnsafeMutablePointer<MIDIEventPacket>
        public init(inProtocol: MIDIProtocolID, wordSize: Int) {
            self.wordSize = max(wordSize, 8)
            let bytes = max(MemoryLayout<MIDIEventList>.size, self.wordSize * 4 + 16)
            self.storage = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: 8)
            self.storage.initializeMemory(as: UInt8.self, repeating: 0, count: bytes)
            self.list = storage.assumingMemoryBound(to: MIDIEventList.self)
            self.cursor = MIDIEventListInit(list, inProtocol)
        }
        deinit { storage.deallocate() }
        public var count: Int { Int(list.pointee.numPackets) }
        public func clear() { cursor = MIDIEventListInit(list, list.pointee.`protocol`) }
        @discardableResult
        public func append(timestamp: MIDITimeStamp, words: [UInt32]) -> UnsafePointer<MIDIEventPacket>? {
            let bytes = MemoryLayout<MIDIEventList>.stride + wordSize * 4
            let before = list.pointee.numPackets
            let written = words.withUnsafeBufferPointer { buf in
                MIDIEventListAdd(list, bytes, cursor, timestamp, buf.count, buf.baseAddress!)
            }
            if list.pointee.numPackets == before {
                return nil
            }
            cursor = written
            return UnsafePointer(written)
        }
        public func withUnsafePointer<Result>(_ body: (UnsafePointer<MIDIEventList>) -> Result) -> Result {
            body(UnsafePointer(list))
        }
        public func withUnsafeMutableMIDIEventListPointer<Result>(
            _ body: (inout UnsafeMutableMIDIEventListPointer) -> Result
        ) -> Result {
            var view = UnsafeMutableMIDIEventListPointer(list, wordSize: wordSize, inProtocol: list.pointee.`protocol`)
            return body(&view)
        }
    }
}

func firstPacket(_ list: UnsafePointer<MIDIEventList>) -> UnsafePointer<MIDIEventPacket> {
    let offset = MemoryLayout<MIDIEventList>.offset(of: \.packet) ?? (MemoryLayout<UInt32>.stride * 2)
    return UnsafeRawPointer(list).advanced(by: offset).assumingMemoryBound(to: MIDIEventPacket.self)
}

public struct UnsafeMutableMIDIEventListPointer: Sequence {
    public typealias Element = UnsafePointer<MIDIEventPacket>
    public typealias Iterator = MIDIEventList.UnsafeSequence.Iterator
    public let pointer: UnsafeMutablePointer<MIDIEventList>
    public let wordSize: Int
    public init(_ p: UnsafeMutablePointer<MIDIEventList>, wordSize: Int, inProtocol: MIDIProtocolID) {
        self.pointer = p
        self.wordSize = wordSize
        p.pointee.`protocol` = inProtocol
    }
    public init?(_ p: UnsafeMutablePointer<MIDIEventList>?, wordSize: Int) {
        guard let p else { return nil }
        self.pointer = p
        self.wordSize = wordSize
    }
    public var count: Int { Int(pointer.pointee.numPackets) }
    public var midiProtocol: MIDIProtocolID { pointer.pointee.`protocol` }
    public var lastPacket: UnsafeMutablePointer<MIDIEventPacket>? {
        guard count > 0 else { return nil }
        var pkt = firstPacket(UnsafePointer(pointer))
        if count == 1 { return UnsafeMutablePointer(mutating: pkt) }
        for _ in 1..<count { pkt = UnsafePointer(MIDIEventPacketNext(pkt)) }
        return UnsafeMutablePointer(mutating: pkt)
    }
    public mutating func clear() {
        _ = MIDIEventListInit(pointer, pointer.pointee.`protocol`)
    }
    public func makeIterator() -> MIDIEventList.UnsafeSequence.Iterator {
        MIDIEventList.UnsafeSequence(base: UnsafePointer(pointer)).makeIterator()
    }
}

extension UnsafePointer where Pointee == MIDIEventList {
    public func unsafeSequence() -> MIDIEventList.UnsafeSequence {
        MIDIEventList.UnsafeSequence(base: self)
    }
}

func midiEventNextOffset(wordCount: UInt32) -> Int {
    let header = MemoryLayout<MIDITimeStamp>.size + MemoryLayout<UInt32>.size
    let dataEnd = header + Int(wordCount) * MemoryLayout<UInt32>.size
    return (dataEnd + 7) & ~7
}

func midiEventListSize(_ list: UnsafePointer<MIDIEventList>) -> Int {
    let count = Int(list.pointee.numPackets)
    var size = MemoryLayout<UInt32>.size + MemoryLayout<UInt32>.size
    if count == 0 { return size }
    var pkt = firstPacket(list)
    for i in 0..<count {
        size += midiEventNextOffset(wordCount: pkt.pointee.wordCount)
        if i + 1 < count { pkt = UnsafePointer(MIDIEventPacketNext(pkt)) }
    }
    return size
}

public func MIDIEventPacketNext(_ pkt: UnsafePointer<MIDIEventPacket>) -> UnsafeMutablePointer<MIDIEventPacket> {
    let offset = midiEventNextOffset(wordCount: pkt.pointee.wordCount)
    return UnsafeMutablePointer(mutating: UnsafeRawPointer(pkt).advanced(by: offset).assumingMemoryBound(to: MIDIEventPacket.self))
}

@discardableResult
public func MIDIEventListInit(
    _ evtlist: UnsafeMutablePointer<MIDIEventList>,
    _ protocol: MIDIProtocolID
) -> UnsafeMutablePointer<MIDIEventPacket> {
    evtlist.pointee.`protocol` = `protocol`
    evtlist.pointee.numPackets = 0
    return UnsafeMutablePointer(mutating: firstPacket(UnsafePointer(evtlist)))
}

@discardableResult
public func MIDIEventListAdd(
    _ evtlist: UnsafeMutablePointer<MIDIEventList>,
    _ listSize: Int,
    _ curPacket: UnsafeMutablePointer<MIDIEventPacket>,
    _ time: MIDITimeStamp,
    _ wordCount: Int,
    _ words: UnsafePointer<UInt32>
) -> UnsafeMutablePointer<MIDIEventPacket> {
    let needed = midiEventNextOffset(wordCount: UInt32(wordCount))
    let start = UnsafeMutableRawPointer(evtlist)
    let used = UnsafeMutableRawPointer(curPacket) - start
    if used + needed > listSize {
        return curPacket
    }
    curPacket.pointee.timeStamp = time
    curPacket.pointee.wordCount = UInt32(Swift.min(wordCount, 64))
    withUnsafeMutableBytes(of: &curPacket.pointee.words) { raw in
        let buf = raw.bindMemory(to: UInt32.self)
        for i in 0..<Int(curPacket.pointee.wordCount) { buf[i] = words[i] }
    }
    evtlist.pointee.numPackets += 1
    return MIDIEventPacketNext(UnsafePointer(curPacket))
}

public func MIDIEventListForEachEvent(
    _ evtlist: UnsafePointer<MIDIEventList>!,
    _ visitor: MIDIEventVisitor!,
    _ visitorContext: UnsafeMutableRawPointer!
) {
    guard let evtlist, let visitor else { return }
    for packetPtr in MIDIEventList.UnsafeSequence(base: evtlist) {
        let packet = packetPtr.pointee
        let words = withUnsafeBytes(of: packet.words) { raw -> [UInt32] in
            Array(raw.bindMemory(to: UInt32.self).prefix(Int(packet.wordCount)))
        }
        var i = 0
        while i < words.count {
            let word = words[i]
            let type = MIDIMessageTypeForUPWord(word)
            let group = UInt8((word >> 24) & 0xF)
            var message = MIDIUniversalMessage()
            message.type = type
            message.group = group
            switch type {
            case .utility:
                message.utility.status = MIDIUtilityStatus(rawValue: (word >> 20) & 0xF) ?? .NOOP
            case .system:
                message.system.status = MIDISystemStatus(rawValue: (word >> 16) & 0xFF) ?? .statusSystemReset
            case .channelVoice1:
                message.channelVoice1.status = MIDICVStatus(rawValue: (word >> 20) & 0xF) ?? .noteOn
                message.channelVoice1.channel = UInt8((word >> 16) & 0xF)
                message.channelVoice1.data1 = UInt8((word >> 8) & 0xFF)
                message.channelVoice1.data2 = UInt8(word & 0xFF)
            default:
                break
            }
            visitor(visitorContext, packet.timeStamp, message)
            i += midiWordCount(for: type)
        }
    }
}

func midiWordCount(for type: MIDIMessageType) -> Int {
    switch type {
    case .utility, .system, .channelVoice1: return 1
    case .sysEx, .channelVoice2: return 2
    case .data128, .flexData, .unknownF, .invalid: return 4
    }
}
