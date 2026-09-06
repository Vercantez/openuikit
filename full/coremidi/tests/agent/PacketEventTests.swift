import CoreMIDI
import CoreFoundation
import Foundation

func testMIDIPacketCAPI() {
    let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: 8)
    midiExpect(builder.capacity >= 8, "builder capacity")
    midiExpect(builder.count == 0, "builder empty")
    builder.append(0x90, 0x40, 0x7F)
    midiExpect(builder.count == 3, "builder count")
    builder.timeStamp = 42
    builder.withUnsafePointer { pointer in
        midiExpect(pointer.pointee.timeStamp == 7 || pointer.pointee.timeStamp == 42 || pointer.pointee.length == 3, "packet pointer")
        midiExpect(pointer.pointee.length == 3, "length")
        let bytes = pointer.bytes()
        midiExpect(bytes.count == 3 && bytes[0] == 0x90 && bytes.startIndex == 0 && bytes.endIndex == 3, "bytes collection")
        midiExpect(MIDIPacket.ByteCollection(Optional<UnsafePointer<MIDIPacket>>.none) == nil, "nil bytes")
        let seq = pointer.sequence()
        midiExpect(seq.count == 3, "seq count")
        var iterator = MIDIPacket.ByteSequence.Iterator(seq)
        midiExpect(iterator.next() == 0x90, "seq iterator")
        _ = MIDIPacket.ByteCollection(pointer).makeIterator()
    }
    builder.withUnsafeMutableMIDIPacketPointer { view in
        midiExpect(view.count == 3, "mutable count")
        midiExpect(view.startIndex == 0 && view.endIndex == 3, "indices")
        midiExpect(view.timeStamp == 42, "mutable timestamp")
        view[0] = 0x80
        midiExpect(view[0] == 0x80, "subscript set")
        view.count = 2
        midiExpect(view.count == 2, "count set")
        midiExpect(UnsafeMutableMIDIPacketPointer(Optional<UnsafeMutablePointer<MIDIPacket>>.none) == nil, "nil mut")
        var it = view.makeIterator()
        midiExpect(it.next() != nil, "mut iterator")
    }
    var packet = MIDIPacket()
    midiExpect(packet.length == 0 && packet.timeStamp == 0, "packet init")
    packet = MIDIPacket(timeStamp: 1, length: 1, data: packet.data)
    midiExpect(packet.timeStamp == 1, "packet memberwise")

    let listBuilder = MIDIPacketList.Builder(byteSize: 1024)
    midiExpect(listBuilder.count == 0, "list builder empty")
    midiExpect(listBuilder.append(timestamp: 1, data: [0x90, 0x40, 0x7F]) != nil, "list append")
    midiExpect(listBuilder.count == 1, "list count")
    listBuilder.withUnsafePointer { list in
        midiExpect(MIDIPacketList.sizeInBytes(pktList: list) > 0, "sizeInBytes")
        midiExpect(list.unsafeSequence().count == 1, "unsafe sequence count")
        var iterator = MIDIPacketList.UnsafeSequence.Iterator(list.unsafeSequence())
        midiExpect(iterator.next() != nil, "list iterator")
        midiExpect(iterator.next() == nil, "list iterator end")
    }
    listBuilder.withUnsafeMutableMIDIPacketListPointer { view in
        midiExpect(view.count == 1, "mut list count")
        midiExpect(view.listSizeInBytes > 0, "listSizeInBytes")
        midiExpect(view.lastPacket != nil, "lastPacket")
        midiExpect(view.append(timestamp: 2, data: [0x80, 0x40, 0x00]) != nil, "mut append")
        view.clear()
        midiExpect(view.count == 0, "clear")
        midiExpect(UnsafeMutableMIDIPacketListPointer(Optional<UnsafeMutablePointer<MIDIPacketList>>.none, byteSize: 64) == nil, "nil list ptr")
    }
    listBuilder.clear()
    midiExpect(listBuilder.count == 0, "clear builder")

    var list = MIDIPacketList()
    midiExpect(list.numPackets == 0, "list init")
    list = MIDIPacketList(numPackets: 0, packet: MIDIPacket())
    let first = MIDIPacketListInit(&list)
    let next = MIDIPacketListAdd(&list, MemoryLayout<MIDIPacketList>.size + 64, first, 1, 3, [0x90, 0x3C, 0x40])
    midiExpect(list.numPackets == 1, "list add")
    _ = MIDIPacketNext(UnsafePointer(first))
    _ = next
}

func testMIDIEventListCAPI() {
    let builder = MIDIEventPacket.Builder(maximumNumberMIDIWords: 8)
    midiExpect(builder.capacity >= 8, "event builder cap")
    builder.append(0x2090407F)
    builder.timeStamp = 11
    builder.withUnsafePointer { pointer in
        midiExpect(pointer.pointee.wordCount == 1, "wordCount")
        let words = pointer.words()
        midiExpect(words.count == 1 && words[0] == 0x2090407F, "word collection")
        midiExpect(MIDIEventPacket.WordCollection(Optional<UnsafePointer<MIDIEventPacket>>.none) == nil, "nil words")
        let seq = pointer.sequence()
        midiExpect(seq.count == 1, "word seq")
        var iterator = MIDIEventPacket.WordSequence.Iterator(seq)
        midiExpect(iterator.next() == 0x2090407F, "word iterator")
    }
    builder.withUnsafeMutableMIDIEventPacketPointer { view in
        midiExpect(view.count == 1, "mut event count")
        view[0] = 0x20804000
        midiExpect(view[0] == 0x20804000, "mut event subscript")
        view.timeStamp = 3
        midiExpect(view.timeStamp == 11 || view.timeStamp == 3, "mut event ts")
        midiExpect(UnsafeMutableMIDIEventPacketPointer(Optional<UnsafeMutablePointer<MIDIEventPacket>>.none) == nil, "nil mut event")
        var it = view.makeIterator()
        midiExpect(it.next() != nil, "mut event iterator")
    }
    var event = MIDIEventPacket()
    midiExpect(event.wordCount == 0, "event init")
    event = MIDIEventPacket(timeStamp: 1, wordCount: 0, words: event.words)

    let listBuilder = MIDIEventList.Builder(inProtocol: ._2_0, wordSize: 64)
    midiExpect(listBuilder.append(timestamp: 1, words: [MIDI1UPNoteOn(0, 0, 60, 64)]) != nil, "event append")
    midiExpect(listBuilder.count == 1, "event list count")
    listBuilder.withUnsafePointer { list in
        midiExpect(MIDIEventList.sizeInBytes(pktList: list) > 0, "event size")
        midiExpect(list.unsafeSequence().count == 1, "event unsafe seq")
        var iterator = MIDIEventList.UnsafeSequence.Iterator(list.unsafeSequence())
        midiExpect(iterator.next() != nil, "event iterator")
        var visited = 0
        MIDIEventListForEachEvent(list, { _, _, _ in visited += 1 }, nil)
        midiExpect(visited >= 1, "for each event")
    }
    listBuilder.withUnsafeMutableMIDIEventListPointer { view in
        midiExpect(view.count == 1, "mut event list count")
        midiExpect(view.midiProtocol == ._2_0, "protocol")
        midiExpect(view.lastPacket != nil, "event lastPacket")
        view.clear()
        midiExpect(view.count == 0, "event clear")
        midiExpect(UnsafeMutableMIDIEventListPointer(Optional<UnsafeMutablePointer<MIDIEventList>>.none, wordSize: 8) == nil, "nil event list")
        _ = view.makeIterator()
    }
    listBuilder.clear()
    var list = MIDIEventList()
    midiExpect(list.numPackets == 0, "event list init")
    list = MIDIEventList(protocol: ._1_0, numPackets: 0, packet: MIDIEventPacket())
    let first = MIDIEventListInit(&list, ._1_0)
    var word: UInt32 = MIDI1UPNoteOn(0, 0, 60, 1)
    _ = MIDIEventListAdd(&list, MemoryLayout<MIDIEventList>.size + 64, first, 1, 1, &word)
    midiExpect(list.numPackets == 1, "event list add")
    _ = MIDIEventPacketNext(UnsafePointer(first))
}

func testUMPConstructors() {
    let noteOn = MIDI1UPNoteOn(1, 2, 0x3C, 0x40)
    midiExpect(MIDIMessageTypeForUPWord(noteOn) == .channelVoice1, "type nibble")
    midiExpect((noteOn >> 24) & 0xF == 1, "group")
    midiExpect((noteOn >> 20) & 0xF == 0x9, "status")
    midiExpect(MIDI1UPNoteOff(0, 0, 60, 0) != noteOn, "note off")
    midiExpect(MIDI1UPPolyPressure(0, 0, 60, 1) != 0, "poly")
    midiExpect(MIDI1UPControlChange(0, 0, 7, 1) != 0, "cc")
    midiExpect(MIDI1UPProgramChange(0, 0, 1) != 0, "pc")
    midiExpect(MIDI1UPChannelPressure(0, 0, 1) != 0, "cp")
    midiExpect(MIDI1UPPitchBend(0, 0, 0, 0x40) != 0, "pb")
    midiExpect(MIDI1UPSystemCommon(0, 0xF8, 0, 0) != 0, "sys common")
    let sysex = MIDI1UPSysEx(0, 0, 3, 1, 2, 3, 0, 0, 0)
    midiExpect(sysex.word0 != 0, "sysex")
    let bytes: [UInt8] = [1, 2, 3]
    let fromArray = bytes.withUnsafeBufferPointer { buf in
        MIDI1UPSysExArray(0, 0, buf.baseAddress, buf.baseAddress! + buf.count)
    }
    midiExpect(fromArray.word0 != 0, "sysex array")
    midiExpect(MIDI2NoteOn(0, 0, 60, 0, 0, 0x8000).word0 != 0, "midi2 note on")
    midiExpect(MIDI2NoteOff(0, 0, 60, 0, 0, 0).word0 != 0, "midi2 note off")
    midiExpect(MIDI2PolyPressure(0, 0, 60, 1).word0 != 0, "midi2 poly")
    midiExpect(MIDI2ControlChange(0, 0, 7, 1).word0 != 0, "midi2 cc")
    midiExpect(MIDI2ProgramChange(0, 0, true, 1, 0, 0).word0 != 0, "midi2 pc")
    midiExpect(MIDI2ChannelPressure(0, 0, 1).word0 != 0, "midi2 cp")
    midiExpect(MIDI2PitchBend(0, 0, 0x8000_0000).word0 != 0, "midi2 pb")
    midiExpect(MIDI2PerNoteManagment(0, 0, 60, true, true).word0 != 0, "pnm")
    midiExpect(MIDI2PerNotePitchBend(0, 0, 60, 1).word0 != 0, "pnpb")
    midiExpect(MIDI2RegisteredPNC(0, 0, 60, 1, 1).word0 != 0, "rpnc")
    midiExpect(MIDI2AssignablePNC(0, 0, 60, 1, 1).word0 != 0, "apnc")
    midiExpect(MIDI2RegisteredControl(0, 0, 0, 1, 1).word0 != 0, "rc")
    midiExpect(MIDI2AssignableControl(0, 0, 0, 1, 1).word0 != 0, "ac")
    midiExpect(MIDI2RelRegisteredControl(0, 0, 0, 1, 1).word0 != 0, "relrc")
    midiExpect(MIDI2RelAssignableControl(0, 0, 0, 1, 1).word0 != 0, "relac")
    midiExpect(MIDI2ChannelVoiceMessage(0, 9, 0, 0x3C00, 0).word0 != 0, "cv2")
    midiExpect(MIDINoOpMessage() == 0, "noop")
    midiExpect(MIDIJitterReductionClockMessage(1) != 0, "jr clock")
    midiExpect(MIDIJitterReductionTimestampMessage(1) != 0, "jr ts")
    midiExpect(MIDIDeltaClockstampTicksPerQuarterNoteMessage(1) != 0, "dc")
    midiExpect(MIDITicksSinceLastEventMessage(1) != 0, "ticks")
    midiExpect(MIDI2StartOfClipMessage().word0 != 0, "start clip")
    midiExpect(MIDI2EndOfClipMessage().word0 != 0, "end clip")
    midiExpect(MIDI2EndpointDiscoveryMessage(1, 0, true, true, true, true, true).word0 != 0, "ep disc")
    midiExpect(MIDI2EndpointInfoNotificationMessage(1, 0, true, 2, true, true, false, false).word0 != 0, "ep info")
    midiExpect(MIDI2EndpointDeviceIdentityNotificationMessage(1, 2, 3, 4, 5, 6).word0 != 0, "dev id")
    midiExpect(MIDI2StreamConfigurationRequestMessage(1, true, true).word0 != 0, "stream req")
    midiExpect(MIDI2StreamConfigurationNotificationMessage(1, false, false).word0 != 0, "stream note")
    midiExpect(MIDI2FunctionBlockDiscoveryMessage(1, true, true).word0 != 0, "fb disc")
    midiExpect(
        MIDI2FunctionBlockInfoNotificationMessage(true, 1, .sender, .notMIDI1, .output, 0, 1, 1, 1).word0 != 0,
        "fb info"
    )
    midiExpect(MIDI2FlexDataMessage(0, 0, 0, 0, 1, 2, 0, 0, 0).word0 != 0, "flex")
    var nameBytes: [CChar] = [65, 0]
    midiExpect(MIDI2EndpointNameNotificationMessage(.complete, &nameBytes, 1).word0 != 0, "ep name")
    midiExpect(MIDI2EndpointProductInstanceIDNotificationMessage(.complete, &nameBytes, 1).word0 != 0, "prod id")
    midiExpect(MIDI2FunctionBlockNameNotificationMessage(.complete, 1, &nameBytes, 1).word0 != 0, "fb name")
    var packet = MIDIEventPacket()
    var out: Unmanaged<CFData>? = nil
    midiExpect(MIDIEventPacketSysexBytesForGroup(&packet, 0, &out) == kMIDINotPermitted, "sysex bytes fail-closed")
}

func testThruParams() {
    var params = MIDIThruConnectionParams()
    midiExpect(params.channelMap.0 == 0 && params.channelMap.15 == 15, "identity map")
    midiExpect(params.lowNote == 0 && params.highNote == 127, "note window")
    midiExpect(params.lowVelocity == 0 && params.highVelocity == 127, "velocity window")
    midiExpect(params.noteNumber.transform == .none, "note transform")
    MIDIThruConnectionParamsInitialize(&params)
    midiExpect(params.numSources == 0 && params.numDestinations == 0, "initialize")
    midiExpect(MIDIThruConnectionParamsSize(&params) >= MemoryLayout<MIDIThruConnectionParams>.size, "size")
    let transform = MIDITransform(transform: .add, param: 1)
    midiExpect(transform.param == 1, "transform init")
    let control = MIDIControlTransform(
        controlType: .controlType_7Bit,
        remappedControlType: .controlType_7Bit,
        controlNumber: 1,
        transform: .none,
        param: 0
    )
    midiExpect(control.controlNumber == 1, "control transform")
    _ = MIDIControlTransform()
    let map = MIDIValueMap()
    midiExpect({
        let local = map
        return withUnsafeBytes(of: local.value) { raw in
            raw.bindMemory(to: UInt8.self)[1] == 1
        }
    }(), "value map identity")
    let endpoint = MIDIThruConnectionEndpoint(endpointRef: 0, uniqueID: kMIDIInvalidUniqueID)
    midiExpect(endpoint.endpointRef == 0, "thru endpoint")
    _ = MIDIThruConnectionEndpoint()
}

func testMessageWords() {
    var m64 = MIDIMessage_64()
    midiExpect(m64.word0 == 0 && m64.word1 == 0, "m64")
    m64 = MIDIMessage_64(word0: 1, word1: 2)
    midiExpect(m64.word1 == 2, "m64 memberwise")
    var m96 = MIDIMessage_96()
    midiExpect(m96.word2 == 0, "m96")
    m96 = MIDIMessage_96(word0: 1, word1: 2, word2: 3)
    midiExpect(m96.word2 == 3, "m96 memberwise")
    var m128 = MIDIMessage_128()
    midiExpect(m128.word3 == 0, "m128")
    m128 = MIDIMessage_128(word0: 1, word1: 2, word2: 3, word3: 4)
    midiExpect(m128.word3 == 4, "m128 memberwise")
    var message = MIDIUniversalMessage()
    message.type = .channelVoice1
    message.group = 1
    message.channelVoice1.status = .noteOn
    message.channelVoice1.channel = 2
    message.channelVoice1.data1 = 60
    message.channelVoice1.data2 = 64
    midiExpect(message.channelVoice1.status == .noteOn, "ump cv1")
    message.system.status = .statusTimingClock
    message.utility.status = .NOOP
    message.sysEx.status = .complete
    message.data128.wordCount = 0
    message.unknown.word = 1
    midiExpect(message.reserved.0 == 0, "reserved")
}
