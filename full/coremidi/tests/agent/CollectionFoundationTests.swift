import CoreMIDI
import Foundation

struct MIDITestAscendingOrder<C: Comparable>: SortComparator {
    typealias Compared = C
    var order: SortOrder = .forward
    func compare(_ lhs: C, _ rhs: C) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        let ascending = lhs < rhs
        return (ascending == (order == .forward)) ? .orderedAscending : .orderedDescending
    }
}

struct MIDITestPacketPointerOrder: SortComparator {
    typealias Compared = UnsafePointer<MIDIPacket>
    var order: SortOrder = .forward
    func compare(_ lhs: UnsafePointer<MIDIPacket>, _ rhs: UnsafePointer<MIDIPacket>) -> ComparisonResult {
        let left = (lhs.pointee.timeStamp, lhs.pointee.length)
        let right = (rhs.pointee.timeStamp, rhs.pointee.length)
        if left == right { return .orderedSame }
        return ((left < right) == (order == .forward)) ? .orderedAscending : .orderedDescending
    }
}

struct MIDITestEventPacketPointerOrder: SortComparator {
    typealias Compared = UnsafePointer<MIDIEventPacket>
    var order: SortOrder = .forward
    func compare(_ lhs: UnsafePointer<MIDIEventPacket>, _ rhs: UnsafePointer<MIDIEventPacket>) -> ComparisonResult {
        let left = (lhs.pointee.timeStamp, lhs.pointee.wordCount)
        let right = (rhs.pointee.timeStamp, rhs.pointee.wordCount)
        if left == right { return .orderedSame }
        return ((left < right) == (order == .forward)) ? .orderedAscending : .orderedDescending
    }
}

struct MIDITestJoinFormat<S: Sequence>: FormatStyle {
    typealias FormatInput = S
    typealias FormatOutput = String
    func format(_ value: S) -> String {
        value.map { String(describing: $0) }.joined(separator: "|")
    }
}

func testCollectionSortedUsingComparator() {
    withByteCollection([3, 1, 2]) { c in
        midiExpect(c.sorted(using: MIDITestAscendingOrder<UInt8>()) == [1, 2, 3], "byte sorted using")
    }
    withByteSequence([5, 1, 4]) { s in
        midiExpect(s.sorted(using: MIDITestAscendingOrder<UInt8>()) == [1, 4, 5], "byte seq sorted using")
    }
    withMutableBytes([8, 2, 6]) { p in
        midiExpect(p.sorted(using: MIDITestAscendingOrder<UInt8>()) == [2, 6, 8], "mut bytes sorted using")
    }
    withWordCollection([9, 4, 7]) { c in
        midiExpect(c.sorted(using: MIDITestAscendingOrder<UInt32>()) == [4, 7, 9], "word sorted using")
    }
    withWordSequence([6, 3]) { s in
        midiExpect(s.sorted(using: MIDITestAscendingOrder<UInt32>()) == [3, 6], "word seq sorted using")
    }
    withMutableWords([9, 4, 7]) { p in
        midiExpect(p.sorted(using: MIDITestAscendingOrder<UInt32>()) == [4, 7, 9], "mut words sorted using")
    }
    let packetBuilder = MIDIPacketList.Builder(byteSize: 1024)
    midiExpect(packetBuilder.append(timestamp: 2, data: [0x80]) != nil, "packet sorted append")
    midiExpect(packetBuilder.append(timestamp: 1, data: [0x90, 0x40]) != nil, "packet sorted append2")
    packetBuilder.withUnsafePointer { list in
        let ranked = list.unsafeSequence().sorted(using: MIDITestPacketPointerOrder())
        midiExpect(ranked.count == 2, "packet seq sorted using count")
        midiExpect(ranked.map { $0.pointee.timeStamp } == [1, 2], "packet seq sorted using order")
    }
    packetBuilder.withUnsafeMutableMIDIPacketListPointer { view in
        let ranked = view.sorted(using: MIDITestPacketPointerOrder())
        midiExpect(ranked.map { $0.pointee.timeStamp } == [1, 2], "mut packet list sorted using")
    }
    let eventBuilder = MIDIEventList.Builder(inProtocol: ._1_0, wordSize: 64)
    midiExpect(eventBuilder.append(timestamp: 2, words: [0x20804040]) != nil, "event sorted append")
    midiExpect(eventBuilder.append(timestamp: 1, words: [0x20904040]) != nil, "event sorted append2")
    eventBuilder.withUnsafePointer { list in
        let ranked = list.unsafeSequence().sorted(using: MIDITestEventPacketPointerOrder())
        midiExpect(ranked.count == 2, "event seq sorted using count")
        midiExpect(ranked.map { $0.pointee.timeStamp } == [1, 2], "event seq sorted using order")
    }
    eventBuilder.withUnsafeMutableMIDIEventListPointer { view in
        let ranked = view.sorted(using: MIDITestEventPacketPointerOrder())
        midiExpect(ranked.map { $0.pointee.timeStamp } == [1, 2], "mut event list sorted using")
    }
}

func testCollectionSortUsingComparator() {
    withMutableBytes([3, 1, 2]) { p in
        p.sort(using: MIDITestAscendingOrder<UInt8>())
        midiExpect(Array(p) == [1, 2, 3], "mut bytes sort using")
    }
    withMutableWords([9, 4, 7]) { p in
        p.sort(using: MIDITestAscendingOrder<UInt32>())
        midiExpect(Array(p) == [4, 7, 9], "mut words sort using")
    }
}

func testCollectionFormattedStyle() {
    withByteCollection([1, 2]) { c in
        midiExpect(c.formatted(MIDITestJoinFormat<MIDIPacket.ByteCollection>()) == "1|2", "byte formatted")
    }
    withByteSequence([7]) { s in
        midiExpect(s.formatted(MIDITestJoinFormat<MIDIPacket.ByteSequence>()) == "7", "byte seq formatted")
    }
    withMutableBytes([9]) { p in
        midiExpect(p.formatted(MIDITestJoinFormat<UnsafeMutableMIDIPacketPointer>()) == "9", "mut bytes formatted")
    }
    withWordCollection([4, 5]) { c in
        midiExpect(c.formatted(MIDITestJoinFormat<MIDIEventPacket.WordCollection>()) == "4|5", "word formatted")
    }
    withWordSequence([6]) { s in
        midiExpect(s.formatted(MIDITestJoinFormat<MIDIEventPacket.WordSequence>()) == "6", "word seq formatted")
    }
    withMutableWords([8]) { p in
        midiExpect(p.formatted(MIDITestJoinFormat<UnsafeMutableMIDIEventPacketPointer>()) == "8", "mut words formatted")
    }
    let packetBuilder = MIDIPacketList.Builder(byteSize: 1024)
    midiExpect(packetBuilder.append(timestamp: 1, data: [0x90]) != nil, "packet formatted append")
    midiExpect(packetBuilder.append(timestamp: 2, data: [0x80]) != nil, "packet formatted append2")
    packetBuilder.withUnsafePointer { list in
        let text = list.unsafeSequence().formatted(MIDITestJoinFormat<MIDIPacketList.UnsafeSequence>())
        midiExpect(text.split(separator: "|").count == 2, "packet seq formatted")
    }
    packetBuilder.withUnsafeMutableMIDIPacketListPointer { view in
        let text = view.formatted(MIDITestJoinFormat<UnsafeMutableMIDIPacketListPointer>())
        midiExpect(text.split(separator: "|").count == 2, "mut packet list formatted")
    }
    let eventBuilder = MIDIEventList.Builder(inProtocol: ._1_0, wordSize: 64)
    midiExpect(eventBuilder.append(timestamp: 1, words: [0x20904040]) != nil, "event formatted append")
    midiExpect(eventBuilder.append(timestamp: 2, words: [0x20804040]) != nil, "event formatted append2")
    eventBuilder.withUnsafePointer { list in
        let text = list.unsafeSequence().formatted(MIDITestJoinFormat<MIDIEventList.UnsafeSequence>())
        midiExpect(text.split(separator: "|").count == 2, "event seq formatted")
    }
    eventBuilder.withUnsafeMutableMIDIEventListPointer { view in
        let text = view.formatted(MIDITestJoinFormat<UnsafeMutableMIDIEventListPointer>())
        midiExpect(text.split(separator: "|").count == 2, "mut event list formatted")
    }
}
