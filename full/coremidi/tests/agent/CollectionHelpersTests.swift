import CoreMIDI
import Foundation
import Glibc

func midiExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("COREMIDI_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
        fatalError(message)
    }
}

struct MIDITestLCG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}

func withByteCollection(_ bytes: [UInt8], body: (MIDIPacket.ByteCollection) -> Void) {
    let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: Swift.max(bytes.count, 1))
    for byte in bytes { builder.append(byte) }
    builder.timeStamp = 7
    builder.withUnsafePointer { pointer in
        body(MIDIPacket.ByteCollection(pointer))
    }
}

func withMutableBytes(_ bytes: [UInt8], body: (inout UnsafeMutableMIDIPacketPointer) -> Void) {
    let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: Swift.max(bytes.count, 1))
    for byte in bytes { builder.append(byte) }
    builder.withUnsafeMutableMIDIPacketPointer { view in
        body(&view)
    }
}

func withWordCollection(_ words: [UInt32], body: (MIDIEventPacket.WordCollection) -> Void) {
    let builder = MIDIEventPacket.Builder(maximumNumberMIDIWords: Swift.max(words.count, 1))
    for word in words { builder.append(word) }
    builder.timeStamp = 9
    builder.withUnsafePointer { pointer in
        body(MIDIEventPacket.WordCollection(pointer))
    }
}

func withMutableWords(_ words: [UInt32], body: (inout UnsafeMutableMIDIEventPacketPointer) -> Void) {
    let builder = MIDIEventPacket.Builder(maximumNumberMIDIWords: Swift.max(words.count, 1))
    for word in words { builder.append(word) }
    builder.withUnsafeMutableMIDIEventPacketPointer { view in
        body(&view)
    }
}

func withByteSequence(_ bytes: [UInt8], body: (MIDIPacket.ByteSequence) -> Void) {
    let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: Swift.max(bytes.count, 1))
    for byte in bytes { builder.append(byte) }
    builder.withUnsafePointer { pointer in
        body(pointer.sequence())
    }
}

func withWordSequence(_ words: [UInt32], body: (MIDIEventPacket.WordSequence) -> Void) {
    let builder = MIDIEventPacket.Builder(maximumNumberMIDIWords: Swift.max(words.count, 1))
    for word in words { builder.append(word) }
    builder.withUnsafePointer { pointer in
        body(pointer.sequence())
    }
}

func withPacketListSequence(_ packets: [[UInt8]], body: (MIDIPacketList.UnsafeSequence) -> Void) {
    let builder = MIDIPacketList.Builder(byteSize: 4096)
    for (index, data) in packets.enumerated() {
        midiExpect(builder.append(timestamp: MIDITimeStamp(index), data: data) != nil, "packet list append")
    }
    builder.withUnsafePointer { list in
        body(list.unsafeSequence())
    }
}

func withEventListSequence(_ packets: [[UInt32]], body: (MIDIEventList.UnsafeSequence) -> Void) {
    let builder = MIDIEventList.Builder(inProtocol: ._1_0, wordSize: 256)
    for (index, words) in packets.enumerated() {
        midiExpect(builder.append(timestamp: MIDITimeStamp(index), words: words) != nil, "event list append")
    }
    builder.withUnsafePointer { list in
        body(list.unsafeSequence())
    }
}

func testCollectionHelpersSmoke() {
    withByteCollection([0x90, 0x40, 0x7F]) { bytes in
        midiExpect(Array(bytes) == [0x90, 0x40, 0x7F], "byte collection helper")
    }
    withWordCollection([0x2090407F]) { words in
        midiExpect(Array(words) == [0x2090407F], "word collection helper")
    }
}
